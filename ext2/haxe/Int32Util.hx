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

package haxe;

import haxe.Int32;
import haxe.io.BytesBuffer;
import haxe.io.Bytes;

class Int32Util {
	public static var ZERO : Int32	= Int32.ofInt(0);
	public static var ONE : Int32	= Int32.ofInt(1);

	/**
		Absolute value
	**/
	public static inline function abs(i : Int32) : Int32 {
		return if(Int32.compare(ZERO, i) > 0)
			Int32.neg(i);
			else i;
	}

	/**
		Returns lowest byte of Int32
	**/
	public static inline function B0(i : Int32) : Int32 {
		return
		haxe.Int32.and(
			i,
			haxe.Int32.ofInt(0xFF)
		);
	}

	/**
		Returns second lowest byte of Int32
	**/
	public static inline function B1(i : Int32) : Int32 {
		//return ((i>>8) & 255);
		return
		haxe.Int32.and(
			haxe.Int32.ushr(i, 8),
			haxe.Int32.ofInt(0xFF)
		);
	}

	/**
		Returns second highest byte of Int32
	**/
	public static inline function B2(i : Int32) : Int32 {
		//return ((i>>16) & 255);
		return
		haxe.Int32.and(
			haxe.Int32.ushr(i, 16),
			haxe.Int32.ofInt(0xFF)
		);
	}

	/**
		Returns highest byte of Int32
	**/
	public static inline function B3(i : Int32) : Int32 {
		//return ((i>>24) & 255);
		return
		haxe.Int32.and(
			haxe.Int32.ushr(i, 24),
			haxe.Int32.ofInt(0xFF)
		);
	}

	/**
		Encode an Int32 to a little endian string. Lowest byte is first in string so
		0xA0B0C0D0 encodes to [D0,C0,B0,A0]
	**/
	public static function encodeLE(i : Int32) : BytesBuffer
	{
		var sb = new BytesBuffer();
		sb.addByte( Int32.toInt(B0(i)) );
		sb.addByte( Int32.toInt(B1(i)) );
		sb.addByte( Int32.toInt(B2(i)) );
		sb.addByte( Int32.toInt(B3(i)) );
		return sb;
	}

	/**
		Returns true if a == b
	**/
	public static inline function eq(a:Int32, b:Int32) {
		return(Int32.compare(a,b) == 0) ? true : false;
	}

	/**
		Decode a 4 byte string to a 32 bit integer.
	**/
	public static function decodeLE( s : Bytes, ?pos : Int ) : Int32
	{
		if(pos == null)
			pos = 0;
		var b0 = haxe.Int32.ofInt(s.get(pos));
		var b1 = haxe.Int32.ofInt(s.get(pos+1));
		var b2 = haxe.Int32.ofInt(s.get(pos+2));
		var b3 = haxe.Int32.ofInt(s.get(pos+3));
		b1 = haxe.Int32.shl(b1, 8);
		b2 = haxe.Int32.shl(b2, 16);
		b3 = haxe.Int32.shl(b3, 24);
		var a = haxe.Int32.add(b0, b1);
		a = haxe.Int32.add(a, b2);
		a = haxe.Int32.add(a, b3);
		return a;
	}

	/**
		Encode an Int32 to a big endian string.
	**/
	public static function encodeBE(i : Int32) : BytesBuffer
	{
		var sb = new BytesBuffer();
		sb.addByte( Int32.toInt(B3(i)) );
		sb.addByte( Int32.toInt(B2(i)) );
		sb.addByte( Int32.toInt(B1(i)) );
		sb.addByte( Int32.toInt(B0(i)) );
		return sb;
	}

	/**
		Decode a 4 byte string to a 32 bit integer.
	**/
	public static function decodeBE( s : Bytes, ?pos : Int ) : Int32
	{
		if(pos == null)
			pos = 0;
		var b0 = haxe.Int32.ofInt(s.get(pos+3));
		var b1 = haxe.Int32.ofInt(s.get(pos+2));
		var b2 = haxe.Int32.ofInt(s.get(pos+1));
		var b3 = haxe.Int32.ofInt(s.get(pos));
		b1 = haxe.Int32.shl(b1, 8);
		b2 = haxe.Int32.shl(b2, 16);
		b3 = haxe.Int32.shl(b3, 24);
		var a = haxe.Int32.add(b0, b1);
		a = haxe.Int32.add(a, b2);
		a = haxe.Int32.add(a, b3);
		return a;
	}

	/**
		Returns true if a < b
	**/
	public static inline function lt(a:Int32, b:Int32) {
		return(Int32.compare(a,b) < 0) ? true : false;
	}

	/**
		Returns true if a <= b
	**/
	public static inline function lteq(a:Int32, b:Int32) {
		return(Int32.compare(a,b) <= 0) ? true : false;
	}

	/**
		Make an Int32 from a high int and low int, the high integer
		is shifted left 16 bits.
	**/
	public static function make( high : Int, low : Int ) : Int32 {
		return Int32.add(
			Int32.shl(Int32.ofInt(high),16),
			Int32.and(Int32.ofInt(0xFFFF), Int32.ofInt(low)));
	}

	/**
		Returns true if a > b
	**/
	public static inline function gt(a:Int32, b:Int32) {
		return(Int32.compare(a,b) > 0) ? true : false;
	}

	/**
		Returns true if a >= b
	**/
	public static inline function gteq(a:Int32, b:Int32) {
		return(Int32.compare(a,b) >= 0) ? true : false;
	}

	/**
		Convert an array of 32bit integers to a little endian string<br />
	**/
	public static function packLE(l : Array<Int32>) : BytesBuffer
	{
		var sb = new BytesBuffer();
		for(i in 0...l.length) {
			sb.addByte( Int32.toInt(B0(l[i])) );
			sb.addByte( Int32.toInt(B1(l[i])) );
			sb.addByte( Int32.toInt(B2(l[i])) );
			sb.addByte( Int32.toInt(B3(l[i])) );
		}
		return sb;
	}

	/**
		Convert an array of 32bit integers to a big endian string<br />
	**/
	public static function packBE(l : Array<Int32>) : BytesBuffer
	{
		var sb = new BytesBuffer();
		for(i in 0...l.length) {
			sb.addByte( Int32.toInt(B3(l[i])) );
			sb.addByte( Int32.toInt(B2(l[i])) );
			sb.addByte( Int32.toInt(B1(l[i])) );
			sb.addByte( Int32.toInt(B0(l[i])) );
		}
		return sb;
	}

	/**
		Convert a string containing 32bit integers to an array of ints<br />
		If the string length is not a multiple of 4, an exception is thrown
	**/
	public static function unpackLE(s : Bytes) : Array<Int32>
	{
		if(s == null || s.length == 0)
			return new Array();
		if(s.length % 4 != 0)
			throw "Buffer not multiple of 4 bytes";

		var a = new Array<Int32>();
		var pos = 0;
		var i = 0;
		var len = s.length;
		while(pos < len) {
			a[i] = decodeLE( s, pos );
			pos += 4;
			i++;
		}
		return a;
	}

	/**
		Convert a string containing 32bit integers to an array of ints<br />
		If the string length is not a multiple of 4, an exception is thrown
	**/
	public static function unpackBE(s : Bytes) : Array<Int32>
	{
		if(s == null || s.length == 0)
			return new Array();
		if(s.length % 4 != 0)
			throw "Buffer not multiple of 4 bytes";

		var a = new Array();
		var pos = 0;
		var i = 0;
		while(pos < s.length) {
			a[i] = decodeBE( s, pos );
			pos += 4;
			i++;
		}
		return a;
	}

	/**
		Encode a 32 bit int to String in base 'radix'.
	**/
	public static function baseEncode(vi : Int32, radix : Int) : String
	{
		if(radix < 2 || radix > 36)
			throw "radix out of range";
		var sb = "";
		var av : Int32 = abs(vi);
		var radix32 = Int32.ofInt(radix);
		while(true) {
			var r32 = haxe.Int32.mod(av, radix32);
			sb = Constants.DIGITS_BN.charAt(Int32.toInt(r32)) + sb;
			av = Int32.div(Int32.sub(av,r32),radix32);
			if(eq(av, ZERO))
				break;
		}
		if(lt(vi, ZERO))
			return "-" + sb;
		return sb;
	}
}
