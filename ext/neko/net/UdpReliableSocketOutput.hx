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
import neko.io.Error;
import neko.net.Socket;

class UdpReliableSocketOutput
	extends neko.io.Output,
	implements neko.net.SocketOutput
{
	private var __socket 	: UdpReliableSocket;
	var __s 				: SocketHandle; // not used.

	public function new(s) {
		__socket = s;
	}

	public override function writeChar( c : Int ) {
		try {
			udpr_send_char(untyped __socket.__h, untyped __socket.__p, c, 0, true);
		} catch( e : Dynamic ) {
			throw Custom(e);
		}
	}

	public override function writeBytes( buf : String, pos : Int, len : Int) : Int {
		return try {
			udpr_send(untyped __socket.__h, untyped __socket.__p, untyped buf.__s, pos, len, 0, true);
		} catch( e : Dynamic ) {
			throw Custom(e);
		}
	}

	public override function close() {
		super.close();
		if( __socket != null ) __socket.close();
	}

	private static var udpr_send = neko.Lib.load("udprsocket", "udpr_send", 6);
	private static var udpr_send_char = neko.Lib.load("udprsocket", "udpr_send_char", 4);
}
