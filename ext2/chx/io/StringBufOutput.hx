/*
 * Copyright (c) 2009, The Caffeine-hx project contributors
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

package chx.io;

import chx.lang.OverflowException;

/**
	Writes to a string, formatting numbers into string format.
**/
class StringBufOutput extends Output {
	var b : StringBuf;

	public function new() {
		b = new StringBuf();
	}

	public override function writeByte( c : Int )  {
		b.addChar(c);
	}

	public override function  writeBytes( bb : Bytes, pos : Int, len : Int ) : Int {
		var s = bb.toString();
		b.addSub(s, pos, len);
		return len;
	}

	public override function writeFloat( x : Float ) : Void {
		// translates the float to the same precision as any
		// other output would have
		var bo = new BytesOutput();
		bo.bigEndian = this.bigEndian;
		#if (neko || cpp)
		bo.write(untyped new Bytes(4,_float_bytes(x,bigEndian)));
		#elseif php
		bo.write(untyped Bytes.ofString(__call__('pack', 'f', x)));
		#elseif flash9
		bo.writeFloat(x);
		#else
		bo.write(math.IEEE754.floatToBytes(x, bigEndian));
		#end
		var bi = new BytesInput(bo.getBytes());
		bi.bigEndian = this.bigEndian;
		var v = bi.readFloat();
		b.add(v);
	}

	public override function writeDouble( x : Float ) : Void {
		b.add(x);
	}

	public override function writeInt8( x : Int ) : Void {
		if( x < -0x80 || x >= 0x80 )
			throw new OverflowException();
		b.add(x);
	}

	public override function writeInt16( x : Int ) : Void  {
		if( x < -0x8000 || x >= 0x8000 ) throw new OverflowException();
		b.add(x);
	}

	public override function writeUInt16( x : Int ) : Void  {
		if( x < 0 || x >= 0x10000 ) throw new OverflowException();
		b.add(x);
	}

	public override function writeInt24( x : Int ) : Void  {
		if( x < -0x800000 || x >= 0x800000 ) throw new OverflowException();
		b.add(x);
	}

	public override function writeUInt24( x : Int ) : Void  {
		if( x < 0 || x >= 0x1000000 ) throw new OverflowException();
		b.add(x);
	}

	public override function writeInt31( x : Int ) : Void  {
		#if !neko
		if( x < -0x40000000 || x >= 0x40000000 ) throw new OverflowException();
		#end
		b.add(x);
	}

	public override function writeUInt30( x : Int ) : Void  {
		if( x < 0 #if !neko || x >= 0x40000000 #end ) throw new OverflowException();
		b.add(x);
	}

	/**
		Neko does not toString() int32s correctly.
	**/
	public override function writeInt32( x : haxe.Int32 ) : Void  {
		b.add(x);
	}

	/**
		Unlike other outputs, this will not prepend the string length.
	**/
	public override function writeUTF( s : String ) : Void {
		b.add(s);
	}

	public override function writeString(s : String) : Void {
		b.add(s);
	}

	public function toString() {
		return b.toString();
	}

#if neko
	static var _float_bytes = neko.Lib.load("std","float_bytes",2);
	static var _double_bytes = neko.Lib.load("std","double_bytes",2);
	static function __init__() untyped {
		StringBufOutput.prototype.bigEndian = true;
	}
#end
}
