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

package haxe.io;

import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.Int32;
import haxe.Int32Util;

class BytesUtil {
	/** static 0 length Bytes object **/
	public static var EMPTY : Bytes;

	/////////////////////////////////////////////////////
	//            Public Static methods                //
	/////////////////////////////////////////////////////
	/**
		Return a hex representation of the byte b. If
		b > 255 only the lowest 8 bits are used.
	**/
	public static function byteToHex(b : Int) {
		b = b & 0xFF;
		return StringTools.hex(b,2).toLowerCase();
	}

	/**
		Return a hex representation of the byte b. If
		b > 255 only the lowest 8 bits are used.
	**/
	public static function byte32ToHex(b : Int32) {
		var bs : Int = Int32.toInt(Int32.and(b, Int32.ofInt(0xFF)));
		return StringTools.hex(bs,2).toLowerCase();
	}

	/**
		Convert a string containing little endian encoded 32bit integers to an array of int32s<br />
		If the string length is not a multiple of 4, it will be 0 padded
		at the end.
	**/
	public static function bytesToInt32LE(s : Bytes) : Array<Int32>
	{
		return Int32Util.unpackLE(nullPad(s,4));
	}

	/**
		Tests if two Bytes objects are equal.
	**/
	public static function eq(a:Bytes, b:Bytes) : Bool {
		if (a.length != b.length)
			return false;
		var l = a.length;
		for( i in 0...l)
			if (a.get(i) != b.get(i))
				return false;
		return true;
	}

	/**
		Dump a string to hex bytes. By default, will be seperated with
		spaces. To have no seperation, use the empty string as a seperator.
	**/
	public static function hexDump(b : Bytes, ?seperator:Dynamic) : String {
		if(seperator == null)
			seperator = " ";
		var sb = new StringBuf();
		var l = b.length;
		for(i in 0...l) {
			sb.add(StringTools.hex(b.get(i),2).toLowerCase());
			sb.add(seperator);
		}
		return StringTools.rtrim(sb.toString());
	}

	/*
		Convert an array of 32bit integers to a little endian Bytes<br />
	**/
	public static inline function int32ToBytesLE(l : Array<Int32>) : Bytes
	{
		return Int32Util.packLE(l);
	}

	/**
		Transform an array of integers x where 0xFF >= x >= 0 to
		a string of binary data, optionally padded to a multiple of
		padToBytes. 0 length input returns 0 length output, not
		padded.
	**/
	public static function int32ArrayToBytes(a: Array<Int32>, ?padToBytes:Int) : Bytes  {
		var sb = new BytesBuffer();
		for(v in a) {
			var i = Int32.toInt(v);
			if(i > 0xFF || i < 0)
				throw "Value out of range";
			sb.addByte(i);
		}
		if(padToBytes != null && padToBytes > 0) {
			return nullPad(sb.getBytes(), padToBytes);
		}
		return sb.getBytes();
	}

	/**
		Transform an array of integers x where 0xFF >= x >= 0 to
		a string of binary data, optionally padded to a multiple of
		padToBytes. 0 length input returns 0 length output, not
		padded.
	**/
	public static function intArrayToBytes(a: Array<Int>, ?padToBytes:Int) : Bytes  {
		var sb = new BytesBuffer();
		for(i in a) {
			if(i > 0xFF || i < 0)
				throw "Value out of range";
			sb.addByte(i);
		}
		if(padToBytes != null && padToBytes > 0) {
			return nullPad(sb.getBytes(), padToBytes);
		}
		return sb.getBytes();
	}

	/**
		Create a string initialized to nulls of length len
	**/
	public static function nullBytes( len : Int ) : Bytes {
		var sb = Bytes.alloc(len);
		for(i in 0...len)
			sb.set(i, 0);
		return sb;
	}

	/**
		Pad with NULLs to the specified chunk length. Note
		that 0 length buffer passed to this will not be padded. See also
		nullBytes()
	**/
	public static function nullPad(s : Bytes, chunkLen: Int) : Bytes {
		var r = chunkLen - (s.length % chunkLen);
		if(r == chunkLen)
			return s;
		var sb = new BytesBuffer();
		sb.add(s);
		for(x in 0...r)
			sb.addByte(0);
		return sb.getBytes();
	}

	public static function ofIntArray(a : Array<Int>) : Bytes {
		var b = new BytesBuffer();
		for(i in 0... a.length) {
			b.addByte(cleanValue(a[i]));
		}
		return b.getBytes();
	}

	/**
		Parse a hex string into a Bytes. The hex string
		may start with 0x, may contain spaces, and may contain
		: delimiters.
	**/
	public static function ofHex(hs : String) : Bytes {
		var s : String = StringTools.stripWhite(hs);
		s = StringTools.replaceRecurse(s, "|", "").toLowerCase();
		if(StringTools.startsWith(s, "0x"))
			s = s.substr(2);
		if (s.length&1==1) s="0"+s;

		var b = new BytesBuffer();
		var l = Std.int(s.length/2);
		for(x in 0...l) {
			var ch = s.substr(x * 2, 2);
			var v = Std.parseInt("0x"+ch);
			if(v > 0xff)
				throw "error";
			b.addByte(v);
		}
		return b.getBytes();
	}

// 	/**
// 		Transform  a string into an array of integers x where
// 		0xFF >= x >= 0, optionally padded to a multiple of
// 		padToBytes. 0 length input returns 0 length output, not
// 		padded.
// 	**/
// 	public static function stringToByteArray( s : String, ?padToBytes:Int) : Array<Int> {
// 		var a = new Array();
// 		var len = s.length;
// 		for(x in 0...s.length) {
// 			a.push(s.charCodeAt(x));
// 		}
// 		if(padToBytes != null && padToBytes > 0) {
// 			var r = padToBytes - (a.length % padToBytes);
// 			if(r != padToBytes) {
// 				for(x in 0...r) {
// 					a.push(0);
// 				}
// 			}
// 		}
// 		return a;
// 	}

	/**
		Remove nulls at the end of a Bytes.
	**/
	public static function unNullPad(s : Bytes) : Bytes {
		var p = s.length - 1;
		while(p-- > 0)
			if(s.get(p) != 0)
				break;
		if(p == 0 && s.get(0) == 0) {
			var bb = new BytesBuffer();
			return bb.getBytes();
		}
		p++;
		var b = Bytes.alloc(p);
		b.blit(0, s, 0, p);
		return b;
	}

	/////////////////////////////////////////////////////
	//                Private methods                  //
	/////////////////////////////////////////////////////
	private static function cleanValue(v : Int) : Int {
		var neg = false;
		if(v < 0) {
			if(v < -128)
				throw "not a byte";
			neg = true;
			v = (v & 0xff) | 0x80;
		}
		if(v > 0xff)
			throw "not a byte";
		return v;
	}

	static function __init__() {
		var bb = new BytesBuffer();
		EMPTY = bb.getBytes();
	}
}
