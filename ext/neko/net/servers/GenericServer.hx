/*
* Copyright (c) 2008, Russell Weir, The haXe Project Contributors
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification, are permitted
* provided that the following conditions are met:
*
* - Redistributions of source code must retain the above copyright notice, this list of conditions
*  and the following disclaimer.
* - Redistributions in binary form must reproduce the above copyright notice, this list of conditions
*  and the following disclaimer in the documentation and/or other materials provided with the distribution.
* - Neither the name of the author nor the names of its contributors may be used to endorse or promote
*  products derived from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
* A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
* CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
* EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
* PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
* LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
* NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
* SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

package neko.net.servers;

import neko.net.Host;

private typedef ServerClient<SockType,ClientData> = {
	var sock : SockType;
	var buffer : String;
	var bufbytes : Int;
	var data : ClientData;
}

class GenericServer<SockType : (neko.net.Socket),ClientData> {

	/**
		Each client has an associated buffer. This is the initial buffer size which
		is set to 128 bytes by default.
	**/
	public static var DEFAULT_BUFSIZE = 256;
	//public static var DEFAULT_BUFSIZE = 1024;

	/**
		Each client has an associated buffer. This is the maximum buffer size which
		is set to 64K by default. When that size is reached and some data can't be processed,
		the client is disconnected.
	**/
	public static var MAX_BUFSIZE = (1 << 16);


	/**
		Each client has an output buffer, for buffering file output. This is 4K by default.
	**/
	public static var MAX_OUTBUFSIZE = (1 << 12);

	/**
		This is the value of number client requests that the server socket
		listen for. By default this number is 10 but can be increased for
		servers supporting a large number of simultaneous requests.
	**/
	public var listenCount : Int;

	/**
		Interval in seconds the poll() function will wait in a Select() call.
		Defaults to 0.
	**/
	public var pollTimeout : Float;

	public var clients : List<ClientData>;
	var rsocks : Array<SockType>;		// reading sockets
	var wsocks : Array<SockType>;		// writing sockets

	var server : SockType;
	var fSelect : Array<SockType>->Array<SockType>->Array<SockType>->Float->{ write : Array<SockType>, read : Array<SockType>, others : Array<SockType>};
	//var onConnect : SockType -> ClientData;

	/**
		Creates a server instance.
	**/
	private function new() {
		clients = new List();
		rsocks = new Array();
		wsocks = new Array();
		listenCount = 10;
		pollTimeout = 0;

		fSelect = null;
		server = null;
	}

	public function start(host : Host, port : Int) {
		if(fSelect == null)
			throw("fSelect is null");
		if(server == null)
			throw("GenServ socket null");
		server.bind(host,port);
		server.listen(listenCount);
		rsocks = [server];
	}

	public function stop() {
		server.close();
	}

	public function run(host : Host, port : Int) {
		start(host, port);
		while(true) {
			poll();
		}
		stop();
	}

	/**
		Closes the client connection and removes it from the client List.
	**/
	public function closeConnection( s : SockType ) : Bool {
		var cl : ServerClient<SockType, ClientData> = untyped s.__client;

		if( cl == null || !clients.remove(cl.data) )
			return false;
		rsocks.remove(s);
		wsocks.remove(s);
		try untyped s.close() catch( e : Dynamic ) { };
		onDisconnect(cl.data);
		return true;
	}

	private function isset( s : SockType, sa : Array<SockType>) {
		for( i in sa ) {
			if(i == s)
				return true;
		}
		return false;
	}

	public function addWriteSock( s : SockType ) : Bool {
		if( ! isset(s, wsocks) ) {
			wsocks.push(s);
			return true;
		}
		trace("Attempt to add listening socket that already exists");
		return false;
	}

	public function removeWriteSock( s : SockType ) : Void {
		wsocks.remove(s);
	}

	/**
		This method can be used instead of writing directly to the socket.
		It ensures that all the data is correctly sent. If an error occurs
		while sending the data, no exception will occur but the client will
		be gracefully disconnected.
	**/
	public function clientWrite( s : SockType, buf : String, pos : Int, len : Int ) {
		try {
			while( len > 0 ) {
				var nbytes = untyped s.output.writeBytes(buf,pos,len);
				pos += nbytes;
				len -= nbytes;
			}
		} catch( e : Dynamic ) {
			closeConnection(s);
		}
	}

	function readData( cl : ServerClient<SockType, ClientData> ) {
		var buflen = cl.buffer.length;
		// eventually double the buffer size
		if( cl.bufbytes == buflen ) {
			var nsize = buflen * 2;
			if( nsize > MAX_BUFSIZE ) {
				if( buflen == MAX_BUFSIZE )
					throw "Max buffer size reached";
				nsize = MAX_BUFSIZE;
			}
			var buf2 = neko.Lib.makeString(nsize);
			neko.Lib.copyBytes(buf2,0,cl.buffer,0,buflen);
			buflen = nsize;
			cl.buffer = buf2;
		}
		// read the available data
		var nbytes = untyped cl.sock.input.readBytes(cl.buffer,cl.bufbytes,buflen - cl.bufbytes);
		cl.bufbytes += nbytes;
	}

	function processData( cl : ServerClient<SockType, ClientData> ) {
		var pos = 0;
		while( cl.bufbytes > 0 ) {
			var nbytes = onReadable(cl.data,cl.buffer,pos,cl.bufbytes);
			if( nbytes == 0 )
				break;
			pos += nbytes;
			cl.bufbytes -= nbytes;
		}
		if( pos > 0 )
			neko.Lib.copyBytes(cl.buffer,0,cl.buffer,pos,cl.bufbytes);
	}

	/**
		Polls the server.
	**/
	public function poll() {
		var actsock = fSelect(rsocks,wsocks,null,pollTimeout);
		for( sa in actsock.write) {
			var cl : ServerClient<SockType, ClientData> = untyped sa.__client;
			if( cl == null ) {
				throw "Uninitialized client";
			}
			// read & process the data
			try {
				onWritable(cl.data);
			} catch( e : Dynamic ) {
				if( !Std.is(e,neko.io.Eof) )
					onError(e);
				closeConnection(cl.sock);
			}
		}
		for( s in actsock.read) {
			var cl : ServerClient<SockType, ClientData> = untyped s.__client;
			if( cl == null ) {
				// no associated client : it's our server socket
				var sock : SockType = untyped server.accept();
				untyped sock.setBlocking(false);
				cl = {
					sock : sock,
					data : null,
					buffer : neko.Lib.makeString(DEFAULT_BUFSIZE),
					bufbytes : 0,
				};
				// bind the client
				untyped sock.__client = cl;
				// creates the data
				try {
					cl.data = onConnect(sock);
				} catch( e : Dynamic ) {
					onError(e);
					try untyped sock.close() catch( e : Dynamic ) { };
					continue;
				}
				// adds the client to the lists
				rsocks.push(sock);
				clients.add(cl.data);
				continue;
			} else {
				// read & process the data
				try {
					readData(cl);
					processData(cl);
				} catch( e : Dynamic ) {
					if( !Std.is(e,neko.io.Eof) ) {
						onInternalError(cl.data, e);
						//trace(here.lineNumber);
						//neko.Sys.exit(1);
					}
					if(!closeConnection(cl.sock))
						throw "Error closing socket";
				}
			}
		}
	}

	/**
		The [onConnect] method should return a new instance of the
		client data class to attach to each new connection.
	**/
	public function onConnect( s : SockType) : ClientData {
		var e;
		throw "onConnect not implemented";
		return e;
	}

	/**
		This method is called after a client has been disconnected.
	**/
	public function onDisconnect( d : ClientData ) {
	}

	/**
		This method is called when some data has been read into a Client buffer.
		If the data can be handled, then you can return the number of bytes handled
		that needs to be removed from the buffer. It the data can't be handled (some
		part of the message is missing for example), returns 0.
	**/
	public function onReadable( d : ClientData, buf : String, bufpos : Int, buflen : Int ) {
		throw "onReadable not implemented";
		return 0;
	}

	/**
		This method is called when a socket can be written to.
	**/
	public function onWritable( d : ClientData ) {
		//throw "onWritable not implemented";
		return 0;
	}

	/**
		Called when an error occured. This enable you to log the error somewhere.
		By default the error is displayed using [trace].
	**/
	public function onError( e : Dynamic ) {
		trace(Std.string(e)+"\n"+haxe.Stack.toString(haxe.Stack.exceptionStack()));
	}

	/**
		Called when an error that should generate a 500 response occurs.
		By default the error is displayed using [trace].
	**/
	public function onInternalError( d : ClientData, e : Dynamic ) {
		trace(Std.string(e)+"\n"+haxe.Stack.toString(haxe.Stack.exceptionStack()));
	}
}
