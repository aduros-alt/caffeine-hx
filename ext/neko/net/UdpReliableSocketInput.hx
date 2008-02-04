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

package neko.net;
import neko.net.UdpReliableSocket;
import neko.net.UdpReliableSocket.UdprSocketType;
import neko.io.Error;
import neko.net.Socket;

class UdpReliableSocketInput
	extends neko.io.Input,
	implements neko.net.SocketInput
{
	private var __socket 	: UdpReliableSocket;
	var __s 				: SocketHandle; // not used.
	private var idx			: Int;
	private var len			: Int;
	private var data		: String;
	private var initialized : Bool;

	public function new(s) {
		__socket = s;
		idx = 0;
		len = 0;
		data = null;
		initialized = false;
	}

	private function readInit() {
		var p : UdpReliableSocket;
		switch(__socket.getType()) {
		case UNKNOWN:
			throw Closed;
		case CLIENT:
			__socket = __socket.getPeer();
		case SERVER:
		case PEER:
			//__socket = __socket;
		}
		if(__socket == null) {
			// trace(here.methodName + " SOCKET NULL");
			throw Closed;
		}
		initialized = true;
	}

	/**
		Throws Error.Closed (from UdprReliableSocket.read) if connection has closed
		Throws neko.io.Eof when there is no more data to read.
	*/
	public override function readChar() {
		while(data == null || len == 0) {
			idx = 0;
			len = 0;
			data = null;
			//trace(here.methodName);
			try {
				data = __socket.read();
				//trace(here.methodName);
				//trace(data);
			}
			catch(e:Dynamic) {
				//trace(e);
				if(e == Error.Blocked)
					throw new neko.io.Eof();
				neko.Lib.rethrow(e);
			}
			len = data.length;
			//trace(len);
		}
        var c = untyped __dollar__sget(data.__s,idx);
        idx += 1;
        len -= 1;
        //trace(here.methodName + " returning " + Std.chr(c) + " code "+c);
        if(len <= 0) {
        	len = 0;
        	data = null;
        	idx = 0;
        }
        //trace(Std.chr(c));
        return c;
	}

	// TODO:
	// speed this up, since the full strings are in UdprSocket:Read()
	/**
		Throws neko.io.Eof() when connection is closed.
		gracefully handles Eof() from readChar()
	**/
	public override function readBytes( s : String, p : Int, len : Int ) : Int {
		var k = len;
		var i = 0;
		//trace(here.methodName);
        while( k > 0 ) {
        	try {
				var c = readChar();
				//trace(Std.chr(c));
				untyped __dollar__sset(s.__s,p,c);
				p += 1;
				k -= 1;
				i += 1;
			}
			catch(e : neko.io.Eof) {
				return i;
			}
			catch(e : Dynamic) {
				if(e == Error.Closed) {
					if(i > 0)
						return i;
					throw new neko.io.Eof();
				}
				neko.Lib.rethrow(e);
			}
		}
		return len;
	}

	/**
		Throws Eof when connection is closed
	**/
	public override function readAll( ?bufsize : Int ) : String {
		//trace(here.methodName);

		if( bufsize == null )
				bufsize = (1 << 14); // 16 Ko
		var buf = neko.Lib.makeString(bufsize);
		var total = new StringBuf();
		var oldBlock = __socket.getBlocking();
		__socket.setBlocking(false);
		try {
				while( true ) {
						var len = readBytes(buf,0,bufsize);
						if( len == 0 )
								return total.toString();
						total.addSub(buf,0,len);
				}
		} catch(e: Dynamic) {
			__socket.setBlocking(oldBlock);
			neko.Lib.rethrow(e);
		}
		__socket.setBlocking(oldBlock);
		return total.toString();
	}

	public function hasData() : Bool {
		if((data != null && len != 0))// || __socket.eventCount() > 0)
			return true;
		return false;
	}

	public function getData() : String {
		return data;
	}
}
