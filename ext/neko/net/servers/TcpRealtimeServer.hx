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
import neko.net.servers.RealtimeServer;
import neko.net.servers.RealtimeServer.SocketInfos;
import neko.net.Socket;

class TcpRealtimeServer<Client> extends RealtimeServer<neko.net.Socket,Client> {

	public function new() {
		super();
		select_function = neko.net.Socket.select;
	}

	function createSock() {
		return new neko.net.Socket();
	}

	function addClient( s : neko.net.Socket ) {
		var tid = Std.random(config.threadsCount);
		var thread = threads[tid];
		if( thread == null ) {
			thread = initThread();
			threads[tid] = thread;
		}
		var sh : { private var __s : SocketHandle; } = s;
		var cinf : SocketInfos<neko.net.Socket, Client> = {
			sock : s,
			handle : sh.__s,
			client : null,
			thread : thread,
			wbuffer : neko.Lib.makeString(config.writeBufferSize),
			wbytes : 0,
			rbuffer : neko.Lib.makeString(config.minReadBufferSize),
			rbytes : 0,
		};
		s.output.writeChar = callback(writeClientChar,cinf);
		s.output.writeBytes = callback(writeClientBytes,cinf);
		s.custom = cinf;
		cinf.thread.t.sendMessage({ s : s, cnx : true });
	}

	function clientWrite( c : SocketInfos<neko.net.Socket, Client> ) : Bool {
		var pos = 0;
		while( c.wbytes > 0 )
			try {
				var len = socket_send(c.handle,untyped c.wbuffer.__s,pos,c.wbytes);
				pos += len;
				c.wbytes -= len;
			} catch( e : Dynamic ) {
				if( e != "Blocking" )
					return false;
				break;
			}
		if( c.wbytes == 0 ) {
			c.thread.wsocks.remove(c.sock);
			clientFillBuffer(c.client);
		} else
			neko.Lib.copyBytes(c.wbuffer,0,c.wbuffer,pos,c.wbytes);
		return true;
	}

	public function doRun() {
		while( !shutdown ) {
			var s = sock.accept();
			s.setBlocking(false);
			addClient(s);
		}
		sock.close();
	}
	private static var socket_send_char : SocketHandle -> Int -> Void = neko.Lib.load("std","socket_send_char",2);
	private static var socket_send : SocketHandle -> Void -> Int -> Int -> Int = neko.Lib.load("std","socket_send",4);
}
