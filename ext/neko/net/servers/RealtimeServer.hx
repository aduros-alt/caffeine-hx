/* ************************************************************************ */
/*																			*/
/*  haXe Video 																*/
/*  Copyright (c)2007 Nicolas Cannasse										*/
/*																			*/
/* This library is free software; you can redistribute it and/or			*/
/* modify it under the terms of the GNU Lesser General Public				*/
/* License as published by the Free Software Foundation; either				*/
/* version 2.1 of the License, or (at your option) any later version.		*/
/*																			*/
/* This library is distributed in the hope that it will be useful,			*/
/* but WITHOUT ANY WARRANTY; without even the implied warranty of			*/
/* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU		*/
/* Lesser General Public License or the LICENSE file for more details.		*/
/*																			*/
/* ************************************************************************ */
package neko.net.servers;
import neko.net.Socket;
//import neko.net.UdpReliableSocket;

private typedef ThreadInfos<SockType> = {
	var t : neko.vm.Thread;
	var socks : Array<SockType>;
	var wsocks : Array<SockType>;
	var sleeps : Array<{ s : SockType, time : Float }>;
}

typedef SocketInfos<SockType,Client> = {
	var sock : SockType;
	var handle : SocketHandle;
	var client : Client;
	var thread : ThreadInfos<SockType>;
	var wbuffer : String;
	var wbytes : Int;
	var rbuffer : String;
	var rbytes : Int;
}

class RealtimeServer<SockType : neko.net.Socket, Client> {

	public var config : {
		listenValue : Int,
		connectLag : Float,
		minReadBufferSize : Int,
		maxReadBufferSize : Int,
		writeBufferSize : Int,
		blockingBytes : Int,
		messageHeaderSize : Int,
		threadsCount : Int,
	};
	public var shutdown : Bool;
	var sock : SockType;
	var threads : Array<ThreadInfos<SockType>>;
	var select_function : Dynamic;

	public function new() {
		threads = new Array();
		config = {
			listenValue : 10,
			connectLag : 0.05,
			minReadBufferSize : 1 << 10, // 1 KB
			maxReadBufferSize : 1 << 16, // 64 KB
			writeBufferSize : 1 << 18, // 256 KB
			blockingBytes : 1 << 17, // 128 KB
			messageHeaderSize : 1,
			threadsCount : 10,
		};
		shutdown = false;
	}

	function createSock() : SockType {
		throw "createSock must be implemented";
		return null;
	}

	public function doBind( host : neko.net.Host, port : Int ) {
		//var h = new neko.net.Host(host);
		sock = createSock();
		sock.bind(host,port);
		sock.listen(config.listenValue);
	}

	//public function doRun() {
		//while( !shutdown ) {
			//var s = sock.accept();
			//s.setBlocking(false);
			//addClient(s);
		//}
		//sock.close();
	//}

	function logError( e : Dynamic ) {
		var stack = haxe.Stack.exceptionStack();
		var str = "["+Date.now().toString()+"] "+(try Std.string(e) catch( e : Dynamic ) "???");
		neko.Lib.print(str+"\n"+haxe.Stack.toString(stack));
	}

	function cleanup( t : ThreadInfos<SockType>, s : SockType ) {
		if( !t.socks.remove(s) )
			return;
		try s.close() catch( e : Dynamic ) { };
		t.wsocks.remove(s);
		var i = 0;
		while( i < t.sleeps.length )
			if( t.sleeps[i].s == s )
				t.sleeps.splice(i,1);
			else
				i++;
		try {
			clientDisconnected(getInfos(s).client);
		} catch( e : Dynamic ) {
			logError(e);
		}
	}

	function readWriteThread( t : ThreadInfos<SockType> ) {
		var socks : { write : Array<SockType>, read : Array<SockType>, others : Array<SockType>};
		socks = select_function(t.socks,t.wsocks,null,config.connectLag);
		for( s in socks.read ) {
			var ok = try clientRead(getInfos(s)) catch( e : Dynamic ) { logError(e); false; };
			if( !ok ) {
				socks.write.remove(s);
				cleanup(t,s);
			}
		}
		for( s in socks.write ) {
			var ok = try clientWrite(getInfos(s)) catch( e : Dynamic ) { logError(e); false; };
			if( !ok )
				cleanup(t,s);
		}
	}

	function loopThread( t : ThreadInfos<SockType> ) {
		var now = neko.Sys.time();
		var i = 0;
		while( i < t.sleeps.length ) {
			var s = t.sleeps[i];
			if( s.time <= now ) {
				t.sleeps.splice(i,1);
				clientWakeUp(getInfos(s.s).client);
			} else
				i++;
		}
		if( t.socks.length > 0 )
			readWriteThread(t);
		while( true ) {
			var m : { s : SockType, cnx : Bool } = neko.vm.Thread.readMessage(t.socks.length == 0);
			if( m == null )
				break;
			if( m.cnx ) {
				t.socks.push(m.s);
				var inf = getInfos(m.s);
				inf.client = clientConnected(m.s);
				if( t.socks.length >= 64 ) {
					serverFull(inf.client);
					logError("Max clients per thread reached");
					cleanup(t,m.s);
				}
			} else {
				cleanup(t,m.s);
			}
		}
	}

	function runThread( t ) {
		while( true ) {
			try loopThread(t) catch( e : Dynamic ) logError(e);
		}
	}

	function initThread() {
		var t : ThreadInfos<SockType> = {
			t : null,
			socks : new Array(),
			wsocks : new Array(),
			sleeps : new Array(),
		};
		t.t = neko.vm.Thread.create(callback(runThread,t));
		return t;
	}

	function writeClientChar( c : SocketInfos<SockType,Client>, ch : Int ) {
		if( c.wbytes == 0 )
			c.thread.wsocks.push(c.sock);
		untyped __dollar__sset(c.wbuffer.__s,c.wbytes,ch);
		c.wbytes += 1;
	}

	function writeClientBytes( c : SocketInfos<SockType,Client>, buf : String, pos : Int, len : Int ) {
		if( len == 0 )
			return 0;
		if( c.wbytes == 0 )
			c.thread.wsocks.push(c.sock);
		neko.Lib.copyBytes(c.wbuffer,c.wbytes,buf,pos,len);
		c.wbytes += len;
		return len;
	}

	function addClient( s : SockType ) {
		throw "not implemented";
	}

	function getInfos( s : SockType ) : SocketInfos<SockType,Client> {
		return s.custom;
	}

	function clientWrite( c : SocketInfos<SockType,Client> ) : Bool {
		throw "not implemented";
		return false;
	}

	function clientRead( c : SocketInfos<SockType,Client> ) {
		var available = c.rbuffer.length - c.rbytes;
		if( available == 0 ) {
			var newsize = c.rbuffer.length * 2;
			if( newsize > config.maxReadBufferSize ) {
				newsize = config.maxReadBufferSize;
				if( c.rbuffer.length == config.maxReadBufferSize )
					throw "Max buffer size reached";
			}
			var newbuf = neko.Lib.makeString(newsize);
			neko.Lib.copyBytes(newbuf,0,c.rbuffer,0,c.rbytes);
			c.rbuffer = newbuf;
			available = newsize - c.rbytes;
		}
		try {
			c.rbytes += c.sock.input.readBytes(c.rbuffer,c.rbytes,available);
		} catch( e : Dynamic ) {
			if( !Std.is(e,neko.io.Eof) && !Std.is(e,neko.io.Error) )
				neko.Lib.rethrow(e);
			return false;
		}
		var pos = 0;
		while( c.rbytes >= config.messageHeaderSize ) {
			var m = readClientMessage(c.client,c.rbuffer,pos,c.rbytes);
			if( m == null )
				break;
			pos += m;
			c.rbytes -= m;
		}
		if( pos > 0 )
			neko.Lib.copyBytes(c.rbuffer,0,c.rbuffer,pos,c.rbytes);
		return true;
	}

	// ---------- API ----------------

	public function clientConnected( s : SockType ) : Client {
		return null;
	}

	public function readClientMessage( c : Client, buf : String, pos : Int, len : Int ) : Int {
		return null;
	}

	public function clientDisconnected( c : Client ) {
	}

	public function clientFillBuffer( c : Client ) {
	}

	public function clientWakeUp( c : Client ) {
	}

	public function isBlocking( s : SockType ) {
		return getInfos(s).wbytes > config.blockingBytes;
	}

	public function wakeUp( s : SockType, delay : Float ) {
		var inf = getInfos(s);
		var time = neko.Sys.time() + delay;
		var sl = inf.thread.sleeps;
		for( i in 0...sl.length )
			if( sl[i].time > time ) {
				sl.insert(i,{ s : s, time : time });
				return;
			}
		sl.push({ s : s, time : time });
	}

	/**
		Disconnect a client
	**/
	public function stopClient( s : SockType ) {
		var inf = getInfos(s);
		try s.shutdown(true,true) catch( e : Dynamic ) { };
		inf.thread.t.sendMessage({ s : s, cnx : false });
	}

	/**
		Called when the max number of clients per thread is reached,
		before the client is disconnected.
	**/
	public function serverFull( c : Client ) {
	}
}
