/*
 * Copyright (c) 2008, The Caffeine-hx project contributors
 * Original author : Russell Weir, neko implementation by Lee McColl Sylvester
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

/*
 * Copyright (c) 2005, The haXe Project Contributors
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
 * THIS SOFTWARE IS PROVIDED BY THE HAXE PROJECT CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE HAXE PROJECT CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 *
 * Contributor: Lee McColl Sylvester
 */

package net;

import haxe.io.Error;
#if flash9
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.ProgressEvent;
	import flash.events.SecurityErrorEvent;
	import flash.errors.IOError;
//  missing from stdlib
// 	import flash.errors.SecurityError;
#end



class TcpSocket implements Socket {
	public var __handle(default, null) : Dynamic;
	public var bigEndian(default,setEndian) : Bool;
	public var input(default,null) : haxe.io.Input;
	public var output(default,null) : haxe.io.Output;
	public var custom : Dynamic;
	var listeners : Array<IEventDrivenSocketListener>;
	#if !neko
	var remote_host : { host : Host, port : Int };
	#end

	public function new( ?s ) {
		listeners = new Array();
		__handle =
			if( s == null ) {
				#if neko
					socket_new(false);
				#elseif flash9
					new flash.net.Socket();
				#else
				#error
				#end
			}
			else s;
		input = new TcpSocketInput(__handle);
		output = new TcpSocketOutput(__handle);
		bigEndian = true;

		#if flash9
			__handle.addEventListener(Event.CONNECT, onSocketConnect,false,0,true);
			__handle.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onSocketConnectFail,false,0,true);
			__handle.addEventListener(Event.CLOSE, onSocketClose,false,0,true);
			__handle.addEventListener(ProgressEvent.SOCKET_DATA, onSocketData,false,0,true);
			__handle.addEventListener(IOErrorEvent.IO_ERROR, onSocketError,false,0,true);
		#end
		#if !neko
			remote_host = {
				host : new Host("localhost"),
				port : 0
			};
		#end
	}

	public function accept() : Socket {
		#if neko
			return new TcpSocket(socket_accept(__handle));
		#elseif flash9
			throw "not implemented";
			return null;
		#end
	}

	/** For event driven architectures like Flash, sets the listener class **/
	public function addEventListener( l : IEventDrivenSocketListener ) : Void {
		listeners.remove(l);
		listeners.push(l);
	}

	public function bind(host : String, port : Int) {
		var h = new Host(host);
		#if neko
			socket_bind(__handle, h.ip, port);
		#elseif flash9
			throw "not implemented";
		#end
	}

	public function close() : Void {
		#if neko
			socket_close(__handle);
		#elseif flash9
			try __handle.close() catch(e:Dynamic) {}
		#end
		untyped {
			input.__handle = null;
			output.__handle = null;
		}
		input.close();
		output.close();
	}

	public function connect(host : String, port : Int) {
		var h = new Host(host);
		var failMsg = function(msg:String) {
			var r = h.toString();
			try { r = h.reverse(); } catch(e:Dynamic) {}
			var s = "Failed to connect on "+ r +":"+port;
			if(msg != null)
				s += " : " + msg;
			return s;
		}
		#if neko
			try {
				socket_connect(__handle, h.ip, port);
			} catch( s : String ) {
				if( s == "std@socket_connect" )
					throw failMsg(s);
				else
					neko.Lib.rethrow(s);
			}
		#elseif flash9
			try {
				__handle.connect(host, port);
			}
			catch( e : IOError ) {
				throw failMsg( e.message );
			}
			catch( e : flash.Error ) {
				throw failMsg( Std.string(e.message) );
			}
			remote_host = {
				host: h,
				port : port
			};
		#end
	}

	public function host() : { host : Host, port : Int } {
		#if neko
			var a : Dynamic = socket_host(__handle);
			var h = new Host("127.0.0.1");
			untyped h.ip = a[0];
			return { host : h, port : a[1] };
		#elseif flash9
			return {
				host : new Host("localhost"),
				port : 0
			};
		#end
	}

	public function listen(connections : Int) {
		#if neko
			socket_listen(__handle, connections);
		#elseif flash9
			throw "not implemented";
		#end
	}

	public function peer() : { host : Host, port : Int } {
		#if neko
			var a : Dynamic = socket_peer(__handle);
			var h = new Host("127.0.0.1");
			untyped h.ip = a[0];
			return { host : h, port : a[1] };
		#elseif flash9
			return remote_host;
		#end
	}

	public function read() : Bytes {
		#if neko
			return Bytes.ofData(socket_read(__handle));
		#elseif flash9
			var ba = new flash.utils.ByteArray();
			__handle.readBytes(ba, 0, 0);
			return Bytes.ofData(ba);
		#end
	}

	/** For event driven architectures like Flash, sets the listener class **/
	public function removeEventListener( l : IEventDrivenSocketListener ) : Void {
		while(listeners.remove(l)) {};
	}

	public function selectFunction() {
		return untyped TcpSocket.select;
	}

	public function setBlocking( b : Bool ) {
		#if neko
			socket_set_blocking(__handle,b);
		#elseif flash9
			if(b)
				throw "flash will not block on sockets";
		#end
	}

	public function setEndian(bigEndian : Bool) : Bool {
		this.bigEndian = bigEndian;
		input.bigEndian = bigEndian;
		output.bigEndian = bigEndian;
		#if flash9
			__handle.endian = bigEndian ? flash.utils.Endian.BIG_ENDIAN : flash.utils.Endian.LITTLE_ENDIAN;
		#end
		return bigEndian;
	}

	public function setTimeout( timeout : Float ) {
		#if neko
			socket_set_timeout(__handle, timeout);
		#end
	}

	public function shutdown( read : Bool, write : Bool ) {
		#if neko
			socket_shutdown(__handle,read,write);
		#else
			throw "not implemented";
		#end
	}

	public function waitForRead() {
		select([this],null,null,0.0);
	}

	public function write( content : haxe.io.Bytes ) {
		#if neko
			try {
				socket_write(__handle, content.getData());
			}
			catch(e : String) {
				if(e == "Blocking")
					throw Blocked;
			}
			catch(e : Dynamic ) {
				throw Custom(Std.string(e));
			}
		#elseif flash9
			try {
				__handle.writeBytes(content, 0, content.length);
			}
			catch(e:IOError) {
				throw Custom(e.message);
			}
		#end
	}

	// STATICS
	public static function select(read : Array<TcpSocket>, write : Array<TcpSocket>, others : Array<TcpSocket>, timeout : Float) : {read: Array<TcpSocket>,write: Array<TcpSocket>,others: Array<TcpSocket>} {
		#if neko
			var c = untyped __dollar__hnew( 1 );
			var f = function( a : Array<TcpSocket> ){
				if( a == null ) return null;
				untyped {
					var r = __dollar__amake(a.length);
					var i = 0;
					while( i < a.length ){
						r[i] = a[i].__handle;
						__dollar__hadd(c,a[i].__handle,a[i]);
						i += 1;
					}
					return r;
				}
			}
			var neko_array = socket_select(f(read),f(write),f(others), timeout);

			var g = function( a ) : Array<TcpSocket> {
				if( a == null ) return null;

				var r = new Array();
				var i = 0;
				while( i < untyped __dollar__asize(a) ){
					var t = untyped __dollar__hget(c,a[i],null);
					if( t == null ) throw "Socket object not found.";
					r[i] = t;
					i += 1;
				}
				return r;
			}

			return {
				read: g(neko_array[0]),
				write: g(neko_array[1]),
				others: g(neko_array[2])
			};
		#elseif flash9
			var ra = new Array();
			var wa = new Array();
			var oa = new Array();

			for(s in read) {
				if(s.__handle.bytesAvailable != 0)
					ra.push(s);
			}
			for(s in write) {
				if(s.__handle.connected)
					wa.push(s);
			}
			for(s in others) {
				if(!s.__handle.connected)
					oa.push(s);
			}
			return {
				read: ra,
				write: wa,
				others: oa
			};
		#end
	}

#if flash9
	function onSocketConnect( e : Event ) {
		for(h in listeners) {
			h.onSocketConnect(this, e);
		}
	}

	function onSocketConnectFail( e : SecurityErrorEvent ) {
		for(h in listeners) {
			h.onSocketConnectFail(this, e);
		}
	}

	function onSocketClose( e : Event ) {
		for(h in listeners) {
			h.onSocketClose(this, e);
		}
	}

	function onSocketData( e : ProgressEvent ) {
		for(h in listeners) {
			h.onSocketData(this, e);
		}
	}

	function onSocketError( e : IOErrorEvent ) {
		for(h in listeners) {
			h.onSocketError(this, e);
		}
	}
#end

#if neko
	private static var socket_new = neko.Lib.load("std","socket_new",1);
	private static var socket_close = neko.Lib.load("std","socket_close",1);
	private static var socket_write = neko.Lib.load("std","socket_write",2);
	private static var socket_read = neko.Lib.load("std","socket_read",1);
	private static var socket_connect = neko.Lib.load("std","socket_connect",3);
	private static var socket_listen = neko.Lib.load("std","socket_listen",2);
	private static var socket_select = neko.Lib.load("std","socket_select",4);
	private static var socket_bind = neko.Lib.load("std","socket_bind",3);
	private static var socket_accept = neko.Lib.load("std","socket_accept",1);
	private static var socket_peer = neko.Lib.load("std","socket_peer",1);
	private static var socket_host = neko.Lib.load("std","socket_host",1);
	private static var socket_set_timeout = neko.Lib.load("std","socket_set_timeout",2);
	private static var socket_shutdown = neko.Lib.load("std","socket_shutdown",3);
	private static var socket_set_blocking = neko.Lib.load("std","socket_set_blocking",2);

/*
        private static var socket_send_char : SocketHandle -> Int -> Void = neko.Lib.load("std","socket_send_char",2);
        private static var socket_send : SocketHandle -> Void -> Int -> Int -> Int = neko.Lib.load("std","socket_send",4);
*/
#end

}
