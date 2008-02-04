/* ************************************************************************ */
/*																			*/
/*  From haXe Video 														*/
/*  Copyright (c)2007 Nicolas Cannasse										*/
/*	Modifified for UDPR by Russell Weir										*/
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
import neko.net.UdpReliableSocket;

class UdprRealtimeServer<Client> extends RealtimeServer<neko.net.UdpReliableSocket,Client> {

	public function new() {
		super();
		select_function = neko.net.UdpReliableSocket.select;
	}

	function createSock() {
		return new neko.net.UdpReliableSocket();
	}

	function addClient( s : neko.net.UdpReliableSocket ) {
		var tid = Std.random(config.threadsCount);
		var thread = threads[tid];
		if( thread == null ) {
			thread = initThread();
			threads[tid] = thread;
		}
		//var sh : { private var __s : SocketHandle; } = s;
		var cinf : SocketInfos<neko.net.UdpReliableSocket,Client> = {
			sock : s,
			handle : null, //sh.__s,
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

	function clientWrite( c : SocketInfos<neko.net.UdpReliableSocket, Client> ) : Bool {
		var pos = 0;
		while( c.wbytes > 0 )
			try {
				c.sock.writeChannel(c.wbuffer.substr(pos, c.wbytes), 0);
				pos += c.wbytes;
				c.wbytes = 0;
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


}
