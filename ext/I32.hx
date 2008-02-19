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

#if neko
import neko.Int32;
#end

/**
	Functions for manipulating binary int32 data to and from Strings and
	Byte values. Abstracts some of the differences in integer sizes
	between flash, js and neko.
**/
class I32 {
	/**
		Abstraction of Std.chr(). Return the character code
		of the low byte of an int32
	**/
#if neko
	// inline
	public static function chr( i : Int32 ) : String {
		return String.fromCharCode( neko.Int32.toInt(B0(i)) );
	}
#else true
	// inline
	public static function chr( i : Int ) : String {
		return String.fromCharCode( i );
	}
#end

	/**
		Bytes of Int32. B0 is low byte, B3 High byte
	**/
#if !neko
	public static function B0(i : Int) : Int { return (i & 255); }
	public static function B1(i : Int) : Int { return ((i>>>8) & 255); }
	public static function B2(i : Int) : Int { return ((i>>>16) & 255); }
	public static function B3(i : Int) : Int { return ((i>>>24) & 255); }
#else true
	public static function B0(i : Int32) : Int32 {
		return
		neko.Int32.and(
			i,
			neko.Int32.ofInt(0xFF)
		);
	}
	public static function B1(i : Int32) : Int32 {
		//return ((i>>8) & 255);
		return
		neko.Int32.and(
			neko.Int32.ushr(i, 8),
			neko.Int32.ofInt(0xFF)
		);
	}
	public static function B2(i : Int32) : Int32 {
		//return ((i>>16) & 255);
		return
		neko.Int32.and(
			neko.Int32.ushr(i, 16),
			neko.Int32.ofInt(0xFF)
		);
	}
	public static function B3(i : Int32) : Int32 {
		//return ((i>>24) & 255);
		return
		neko.Int32.and(
			neko.Int32.ushr(i, 24),
			neko.Int32.ofInt(0xFF)
		);
	}
#end

	/**
		Encode an Int32 to a little endian string. Lowest byte is first in string so
		0xA0B0C0D0 encodes to [D0,C0,B0,A0]
	**/
#if neko
	public static function encodeLE(i : Int32) : String
#else true
	public static function encodeLE(i : Int) : String
#end
	{
		var sb = new StringBuf();
		sb.add( chr(B0(i)) );
		sb.add( chr(B1(i)) );
		sb.add( chr(B2(i)) );
		sb.add( chr(B3(i)) );
		return sb.toString();
	}

	/**
		Decode a 4 byte string to a 32 bit integer.
	**/
#if neko
	public static function decodeLE( s : String, ?pos : Int ) : Int32
#else true
	public static function decodeLE( s : String, ?pos : Int ) : Int
#end
	{
		if(pos == null)
			pos = 0;
#if neko
		var b0 = neko.Int32.ofInt(charCodeAt(s, pos));
		var b1 = neko.Int32.ofInt(charCodeAt(s, pos+1));
		var b2 = neko.Int32.ofInt(charCodeAt(s, pos+2));
		var b3 = neko.Int32.ofInt(charCodeAt(s, pos+3));
		b1 = neko.Int32.shl(b1, 8);
		b2 = neko.Int32.shl(b2, 16);
		b3 = neko.Int32.shl(b3, 24);
		var a = neko.Int32.add(b0, b1);
		a = neko.Int32.add(a, b2);
		a = neko.Int32.add(a, b3);
		return a;
#else true
		return
			 s.charCodeAt(pos) |
			(s.charCodeAt(pos+1)<< 8) |
			(s.charCodeAt(pos+2)<<16) |
			(s.charCodeAt(pos+3)<<24);
#end
	}

	/**
		Encode an Int32 to a big endian string.
	**/
#if neko
	public static function encodeBE(i : Int32) : String
#else true
	public static function encodeBE(i : Int) : String
#end
	{
		var sb = new StringBuf();
		sb.add( chr(B3(i)) );
		sb.add( chr(B2(i)) );
		sb.add( chr(B1(i)) );
		sb.add( chr(B0(i)) );
		return sb.toString();
	}

	/**
		Decode a 4 byte string to a 32 bit integer.
	**/
#if neko
	public static function decodeBE( s : String, ?pos : Int ) : Int32
#else true
	public static function decodeBE( s : String, ?pos : Int ) : Int
#end
	{
		if(pos == null)
			pos = 0;
#if neko
		var b0 = neko.Int32.ofInt(charCodeAt(s, pos+3));
		var b1 = neko.Int32.ofInt(charCodeAt(s, pos+2));
		var b2 = neko.Int32.ofInt(charCodeAt(s, pos+1));
		var b3 = neko.Int32.ofInt(charCodeAt(s, pos));
		b1 = neko.Int32.shl(b1, 8);
		b2 = neko.Int32.shl(b2, 16);
		b3 = neko.Int32.shl(b3, 24);
		var a = neko.Int32.add(b0, b1);
		a = neko.Int32.add(a, b2);
		a = neko.Int32.add(a, b3);
		return a;
#else true
		return
			 s.charCodeAt(pos+3) |
			(s.charCodeAt(pos+2)<< 8) |
			(s.charCodeAt(pos+1)<<16) |
			(s.charCodeAt(pos)  <<24);
#end
	}

	/**
		Convert an array of 32bit integers to a little endian string<br />
	**/
#if neko
	public static function packLE(l : Array<Int32>) : String
#else true
	public static function packLE(l : Array<Int>) : String
#end
	{
		var sb = new StringBuf();
		for(i in 0...l.length) {
			sb.add( chr(B0(l[i])) );
			sb.add( chr(B1(l[i])) );
			sb.add( chr(B2(l[i])) );
			sb.add( chr(B3(l[i])) );
		}
		return sb.toString();
	}

	/**
		Convert an array of 32bit integers to a big endian string<br />
	**/
#if neko
	public static function packBE(l : Array<Int32>) : String
#else true
	public static function packBE(l : Array<Int>) : String
#end
	{
		var sb = new StringBuf();
		for(i in 0...l.length) {
			sb.add( chr(B3(l[i])) );
			sb.add( chr(B2(l[i])) );
			sb.add( chr(B1(l[i])) );
			sb.add( chr(B0(l[i])) );
		}
		return sb.toString();
	}

	/**
		Convert a string containing 32bit integers to an array of ints<br />
		If the string length is not a multiple of 4, an exception is thrown
	**/
#if neko
	public static function unpackLE(s : String) : Array<neko.Int32>
#else true
	public static function unpackLE(s : String) : Array<Int>
#end
	{
		if(s == null || s.length == 0)
			return new Array();
		if(s.length % 4 != 0)
			throw "Buffer not multiple of 4 bytes";

		var a = new Array();
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
#if neko
	public static function unpackBE(s : String) : Array<neko.Int32>
#else true
	public static function unpackBE(s : String) : Array<Int>
#end
	{
		if(s == null || s.length == 0)
			return new Array();
		if(s.length % 4 != 0)
			throw "Buffer not multiple of 4 bytes";

		var a = new Array();
		var pos = 0;
		var i = 0;
		while(pos < s.length) {
			a[i] = decodeBE( s.substr(pos, 4) );
			pos += 4;
			i++;
		}
		return a;
	}

	/**
		Return the character code from a string at the given position.
		If pos is past the end of the string, 0 (null) is returned.
	**/
	static function charCodeAt(s, pos) {
		if(pos >= s.length)
			return 0;
		return Std.ord(s.substr(pos,1));
	}

#if neko
	/**
		Create a neko array of Int32
	**/
	public static function mkNekoArray( a : Array<neko.Int32> ) {
		if( a == null )
			return null;
		untyped {
			var r = __dollar__amake(a.length);
			var i = 0;
			while( i < a.length ) {
				r[i] = a[i];
				i += 1;
			}
			return r;
		}
	}
#end

	/**
		Encode a 31 bit int to string in base 'radix'.
	**/
	public static function baseEncode31(vi : Int, radix : Int) : String {
		if(radix < 2 || radix > 36)
			throw "radix out of range";
		var sb = "";
		var av = Std.int(Math.abs(vi));
		while(true) {
			var r = av % radix;
			sb = Constants.DIGITS_BN.charAt(r) + sb;
			av = Std.int((av-r)/radix);
			if(av == 0)
				break;
		}
		if(vi < 0)
			return "-" + sb;
		return sb;
	}

	/**
		Encode a 32 bit int to string in base 'radix'.
	**/
#if neko
	public static function baseEncode32(vi : Int32, radix : Int) : String
#else true
	public static function baseEncode32(vi : Int, radix : Int) : String
#end
	{
#if !neko
		return baseEncode31(vi, radix);
#else true
		if(radix < 2 || radix > 36)
			throw "radix out of range";
		var sb = "";
		var av : Int32 = Int32.abs(vi);
		var radix32 = Int32.ofInt(radix);
		while(true) {
			var r32 = neko.Int32.mod(av, radix32);
			sb = Constants.DIGITS_BN.charAt(Int32.toInt(r32)) + sb;
			av = Int32.div(Int32.sub(av,r32),radix32);
			if(Int32.eq(av, Int32.ZERO))
				break;
		}
		if(Int32.lt(vi, Int32.ZERO))
			return "-" + sb;
		return sb;
#end
	}
}

