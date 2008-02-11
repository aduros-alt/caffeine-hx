/*
 * Copyright (c) 2008, The Caffeine-hx project contributors
 * Original author : Russell Weir
 * Based on RealtimeServer by Nicolas Cannasse
 * Contributors:
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE CAFFEINE-HX PROJECT CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE CAFFEINE-HX PROJECT CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

package servers.http.hive;

import neko.net.Socket;

private typedef PSThreadInfo<Client> = {
	var id : Int;
	var thread : neko.vm.Thread;
	var sock : neko.net.Socket;
	var handle : SocketHandle;
	var poll : neko.net.Poll;
	var rbuffer : String;
	var rbytes : Int;
	var wbuffer : String;
	var wbytes : Int;
	var client : Client;
}

private enum PSWorkerMessage {
	ThreadDone(tid: Int);
	Function(f:Void->Void);
}

private enum ConnError {
	CloseConnection;
}

/**
	ThreadPollServer is a highly responsive, limited connection server.
	It preallocates threads for each handled connection, so the practical
	limit for connections is about 1000 under Linux.<br />
	When the server has exhausted its threads, the method onServerFull
	will be called, allowing you to send a message to the client if
	need be.
**/
class ThreadPollServer<Client> {
	public var config : {
		listenValue : Int,
		connectLag : Float,
		minReadBufferSize : Int,
		maxReadBufferSize : Int,
		writeBufferSize : Int,
		blockingBytes : Int,
		messageHeaderSize : Int,
		timeoutWrite : Float,
		timeoutRead : Float,
	};
	var threads : Array<PSThreadInfo<Client>>;
	var freethreads : List<Int>;
	var worker : neko.vm.Thread;

	public function new() {
		config = {
			listenValue : 10,
			connectLag : 0.05,
			minReadBufferSize : 1 << 10, // 1 KB
			maxReadBufferSize : 1 << 16, // 64 KB
			writeBufferSize : 1 << 18, // 256 KB
			blockingBytes : 1 << 17, // 128 KB
			messageHeaderSize : 1,
			timeoutRead : -1.0,
			timeoutWrite : 20.0,
		};
	}

	public function run( host : String, port : Int ) {
		threads = new Array();
		freethreads = new List();
		var h = new neko.net.Host(host);
		var sock = new neko.net.Socket();
		sock.bind(h,port);
		sock.listen(config.listenValue);

		worker = neko.vm.Thread.create(runWorker);
		for( i in 0...config.listenValue ) {
			var t = {
				id : i,
				thread : null,
				sock : null,
				handle : null,
				poll : new neko.net.Poll(2),
				rbuffer : null,
				rbytes : 0,
				wbuffer : null,
				wbytes : 0,
				client : null,
			};
			threads.push(t);
			t.thread = neko.vm.Thread.create(callback(threadRun,t));
			workerThreadDone(t.id);
		}

		while( true ) {
			try {
				var s = sock.accept();
				s.setBlocking(false);
				addSocket(s);
			} catch( e : Dynamic ) {
				logError(e);
			}
		}
	}

	function addSocket( s : neko.net.Socket ) {
		if(freethreads.length == 0) {
			onServerFull(s);
			try {
				s.shutdown(true,true);
				s.close();
			}
			catch(e:Dynamic) {}
			return;
		}
		var idx = freethreads.pop();
		var t = threads[idx];
		var sh : { private var __s : SocketHandle; } = s;
		t.sock = s;
		t.handle = sh.__s;
		s.output.writeChar = callback(writeClientChar,t);
		s.output.writeBytes = callback(writeClientBytes,t);
		s.custom = t;
		t.client = clientConnected(s);
		t.thread.sendMessage({ cnx : true });
	}

	function getInfo( s : neko.net.Socket ) : PSThreadInfo<Client> {
		return s.custom;
	}

	////////////////////////////////////////////////////////
	//                Thread functions                    //
	////////////////////////////////////////////////////////
	function threadRun( t : PSThreadInfo<Client> ) {
		while( true ) {
			try {
				threadLoop(t);
			}
			catch( e : ConnError ) { }
			catch( e : Dynamic ) {
				logError(e);
			}
			action(ThreadDone(t.id));
		}
	}

	function threadLoop( t : PSThreadInfo<Client>) {
		var msg = neko.vm.Thread.readMessage(true);
		while(true) {
			var checkWrite = false;
			var r = [t.sock];
			var w = new Array<neko.net.Socket>();
			var timeout : Float = Math.min(config.timeoutRead, config.timeoutWrite);
			if( t.wbytes > 0) {
				w.push(t.sock);
				timeout = Math.max(config.timeoutRead, config.timeoutWrite);
				checkWrite = true;
			}
			t.poll.prepare(r,w);
			t.poll.events(timeout);
			if(t.poll.readIndexes[0] == 0) {
				var ok = try threadRead( t )
				catch( e : Dynamic ) { logError(e); false; };
				if(!ok) {
					threadClose( t );
					break;
				}
			}
			if(t.wbytes > 0 && t.poll.writeIndexes[0] == 0) {
				if(!threadWrite( t )) {
					threadClose( t );
					break;
				}
			}
			if(t.poll.readIndexes[0] != 0 && t.poll.writeIndexes[0] != 0) {
				var close = false;
				if(checkWrite) {
					if(t.poll.writeIndexes[0] != 0)
						close = true;
				}
				if(t.poll.readIndexes[0] != 0) {
					if(!(checkWrite && close == false))
						close = true;
				}
				if(close) {
					logInfo("Client timeout");
					throw CloseConnection;
				}
			}
		}
	}

	function threadRead( t : PSThreadInfo<Client> ) {
		var available = t.rbuffer.length - t.rbytes;
		if( available == 0 ) {
			var newsize = t.rbuffer.length * 2;
			if( newsize > config.maxReadBufferSize ) {
				newsize = config.maxReadBufferSize;
				if( t.rbuffer.length == config.maxReadBufferSize )
					throw "Max buffer size reached";
			}
			var newbuf = neko.Lib.makeString(newsize);
			neko.Lib.copyBytes(newbuf,0,t.rbuffer,0,t.rbytes);
			t.rbuffer = newbuf;
			available = newsize - t.rbytes;
		}
		try {
			t.rbytes += t.sock.input.readBytes(t.rbuffer,t.rbytes,available);
		} catch( e : Dynamic ) {
			if( !Std.is(e,neko.io.Eof) && !Std.is(e,neko.io.Error) )
				neko.Lib.rethrow(e);
			return false;
		}
		var pos = 0;
		while( t.rbytes >= config.messageHeaderSize ) {
			var m = readClientMessage(t.client,t.rbuffer,pos,t.rbytes);
			if( m == null )
				break;
			pos += m;
			t.rbytes -= m;
		}
		if( pos > 0 )
			neko.Lib.copyBytes(t.rbuffer,0,t.rbuffer,pos,t.rbytes);
		return true;
	}

	function threadWrite( t : PSThreadInfo<Client> ) {
		var pos = 0;
		while( t.wbytes > 0 )
			try {
				var len = socket_send(t.handle,untyped t.wbuffer.__s, pos, t.wbytes);
				pos += len;
				t.wbytes -= len;
			} catch( e : Dynamic ) {
				if( e != "Blocking" )
					return false;
				break;
			}
		if( t.wbytes == 0 ) {
			clientFillBuffer(t.client);
		} else
			neko.Lib.copyBytes(t.wbuffer,0,t.wbuffer,pos,t.wbytes);
		return true;
	}

	function threadClose( t : PSThreadInfo<Client> ) {
		try t.sock.close() catch( e : Dynamic ) { };
		try {
			clientDisconnected(t.client);
		} catch( e : Dynamic ) {
			logError(e);
		}
	}

	/* *************************
		Worker functions
	* **************************/
	function runWorker() {
		while( true ) {
			var a = neko.vm.Thread.readMessage(true);
			switch(a) {
			case ThreadDone( tid ):
				workerThreadDone( tid );
			case Function(f):
				try {
					f();
				} catch( e : Dynamic ) {
					logError(e);
				}
			}
		}
	}

	public function action(a : PSWorkerMessage) {
		worker.sendMessage(a);
	}

	/**
		Call when a thread has completed handling a connection
	**/
	function workerThreadDone(tid : Int) {
		var t = threads[tid];
		try t.sock.close() catch( e : Dynamic ) { };
		t.sock = null;
		t.handle = null;
		t.wbuffer = neko.Lib.makeString(config.writeBufferSize);
		t.wbytes = 0;
		t.rbuffer = neko.Lib.makeString(config.minReadBufferSize);
		t.rbytes = 0;
		freethreads.add(t.id);
	}

	///////////////////////////////////////////////////
	//				Output callbacks				 //
	///////////////////////////////////////////////////
	function writeClientChar( t : PSThreadInfo<Client>, ch : Int ) {
		untyped __dollar__sset(t.wbuffer.__s, t.wbytes, ch);
		t.wbytes += 1;
	}

	function writeClientBytes( t : PSThreadInfo<Client>, buf : String, pos : Int, len : Int ) {
		if( len == 0 )
			return 0;
		neko.Lib.copyBytes(t.wbuffer,t.wbytes,buf,pos,len);
		t.wbytes += len;
		return len;
	}

	///////////////////////////////////////////////////
	//				API								 //
	///////////////////////////////////////////////////
	/**
		Override to return a new instance of the Client
	**/
	public function clientConnected( s : neko.net.Socket ) : Client {
		return null;
	}

	/**
		Data available from client. Return the number of bytes
		consumed from the input buffer.
	**/
	public function readClientMessage( c : Client, buf : String, pos : Int, len : Int ) : Int {
		return null;
	}

	/**
		called when client disconnects
	**/
	public function clientDisconnected( c : Client ) {
	}

	/**
		client can accept more data.
	**/
	public function clientFillBuffer( c : Client ) {
	}

	/**
		check if client's output buffer is too full
	**/
	public function isBlocking( s : neko.net.Socket ) {
		return getInfo(s).wbytes > config.blockingBytes;
	}

	/**
		Called just before a client is disconnected due
		to thread pool being exhausted.
	**/
	public function onServerFull(s:neko.net.Socket) {
		//logError("Server full");
		neko.Lib.println("Server full");
	}

	/**
		Log an error. This can be called from any thread,
		so when overriding make sure your logging is thread
		safe.
	**/
	public function logError( e : Dynamic ) {
		var stack = haxe.Stack.exceptionStack();
		var str = "["+Date.now().toString()+"] "+(try Std.string(e) catch( e : Dynamic ) "???");
		neko.Lib.print(str+"\n"+haxe.Stack.toString(stack));
	}

	public function logInfo( e : Dynamic) {
		var str = "["+Date.now().toString()+"] "+(try Std.string(e) catch( e : Dynamic ) "???");
		neko.Lib.print(str+"\n");
	}

	public function stopClient( s : Dynamic ) {
		throw CloseConnection;
	}

	private static var socket_send_char : SocketHandle -> Int -> Void = neko.Lib.load("std","socket_send_char",2);
	private static var socket_send : SocketHandle -> Void -> Int -> Int -> Int = neko.Lib.load("std","socket_send",4);
}