/*
 * Copyright (c) 2008, The Caffeine-hx project contributors
 * Original author : Russell Weir
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
package neko.net.servers;
import neko.net.servers.RealtimeServer;
import neko.net.servers.RealtimeServer.SocketInfos;
import neko.net.Socket;

class TcpRealtimeServer<Client> extends RealtimeServer<neko.net.Socket,Client> {

	public function new() {
		super();
		select_function = neko.net.Socket.select;
	}

	override function createSock() {
		return new neko.net.Socket();
	}

	override function addClient( s : neko.net.Socket ) {
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

	override function clientWrite( c : SocketInfos<neko.net.Socket, Client> ) : Bool {
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

	public function run() {
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
