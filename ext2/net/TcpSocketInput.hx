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

package net;

import haxe.io.Error;

#if neko
class TcpSocketInput extends haxe.io.BufferedInput {

	var __handle : Void;

	public function new(s) {
		super();
		__handle = s;
	}

	public override function close() {
		super.close();
		if( __handle != null ) socket_close(__handle);
	}

	public override function readByte() {
		return try {
			socket_recv_char(__handle);
		} catch( e : Dynamic ) {
			if( e == "Blocking" )
				throw Blocked;
			else if( __handle == null )
				throw Custom(e);
			else
				throw new haxe.io.Eof();
		}
	}

	public override function readBytes( buf : haxe.io.Bytes, pos : Int, len : Int ) : Int {
		var r;
		try {
			r = socket_recv(__handle,buf.getData(),pos,len);
		} catch( e : Dynamic ) {
			if( e == "Blocking" )
				throw Blocked;
			else
				throw Custom(e);
		}
		if( r == 0 )
			throw new haxe.io.Eof();
		return r;
	}

	private static var socket_recv = neko.Lib.load("std","socket_recv",4);
	private static var socket_recv_char = neko.Lib.load("std","socket_recv_char",1);
	private static var socket_close = neko.Lib.load("std","socket_close",1);
}

#elseif flash9

class TcpSocketInput extends haxe.io.BufferedInput {
	var __handle : flash.net.Socket;

	public function new(s : flash.net.Socket) {
		super();
		__handle = s;
	}

	public override function close() {
		super.close();
		if( __handle != null ) __handle.close();
	}

	override function setEndian(b) {
		bigEndian = b;
		__handle.endian = b ? flash.utils.Endian.BIG_ENDIAN : flash.utils.Endian.LITTLE_ENDIAN;
		return b;
	}

	public override function readByte() {
		return try {
			__handle.readByte();
		}
		catch( e : flash.errors.EOFError ) {
			throw Blocked;
		}
		catch( e : flash.errors.IOError ) {
			throw new haxe.io.Eof();
		}
		catch( e : Dynamic ) {
			throw Custom(e);
		}
	}

	public override function readBytes(s : Bytes, pos : Int, len : Int ) : Int {
		if( pos < 0 || len < 0 || pos + len > s.length )
			throw Error.OutsideBounds;
		var b = s.getData();
		var op = b.position;
 		try {
			__handle.readBytes(b, pos, len);
			return b.position - op;
		}
		catch( e : flash.errors.EOFError ) {
			throw Blocked;
		}
		catch( e : flash.errors.IOError ) {
			throw new haxe.io.Eof();
		}
		catch( e : Dynamic ) {
			throw Custom(e);
		}
	}

	public override function readDouble() : Float {
		return try {
			__handle.readDouble();
		}
		catch( e : flash.errors.EOFError ) {
			throw Blocked;
		}
		catch( e : flash.errors.IOError ) {
			throw new haxe.io.Eof();
		}
		catch( e : Dynamic ) {
			throw Custom(e);
		}
	}

	public override function readFloat() : Float {
		return try {
			__handle.readFloat();
		}
		catch( e : flash.errors.EOFError ) {
			throw Blocked;
		}
		catch( e : flash.errors.IOError ) {
			throw new haxe.io.Eof();
		}
		catch( e : Dynamic ) {
			throw Custom(e);
		}
	}

	public override function readInt16() : Int {
		return try {
			__handle.readShort();
		}
		catch( e : flash.errors.EOFError ) {
			throw Blocked;
		}
		catch( e : flash.errors.IOError ) {
			throw new haxe.io.Eof();
		}
		catch( e : Dynamic ) {
			throw Custom(e);
		}
	}

	public override function readUInt16() : Int {
		return try {
			__handle.readUnsignedShort();
		}
		catch( e : flash.errors.EOFError ) {
			throw Blocked;
		}
		catch( e : flash.errors.IOError ) {
			throw new haxe.io.Eof();
		}
		catch( e : Dynamic ) {
			throw Custom(e);
		}
	}

	public override function readInt31() : Int {
		var v = try {
			__handle.readInt();
		}
		catch( e : flash.errors.EOFError ) {
			throw Blocked;
		}
		catch( e : flash.errors.IOError ) {
			throw new haxe.io.Eof();
		}
		catch( e : Dynamic ) {
			throw Custom(e);
		}
		if( ((v & 0x800000) == 0) != ((v & 0x400000) == 0) ) throw Error.Overflow;
		return v;
	}

	public override function readInt32() : haxe.Int32 {
		return try {
			cast __handle.readInt();
		}
		catch( e : flash.errors.EOFError ) {
			throw Blocked;
		}
		catch( e : flash.errors.IOError ) {
			throw new haxe.io.Eof();
		}
		catch( e : Dynamic ) {
			throw Custom(e);
		}
	}
}

#else
#error
#end
