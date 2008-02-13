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
	Functions for manipulating binary data to and from Strings
**/
class ByteStringTools {
	/**
		Return the character code from a string at the given position.
		If pos is past the end of the string, 0 (null) is returned.
	**/
	public static function charCodeAt(s, pos) {
		if(pos >= s.length)
			return 0;
		return Std.ord(s.substr(pos,1));
	}

	/**
		Takes a string of hex bytes and converts it to a binary string.
		Input should resemble "a42fffee" and the length must be a
		multiple of 2
	**/
	public static function hexBytesToBinary( s : String) : String {
		if(s.length % 2 != 0)
			throw "Length must be multiple of 2";
		var sb = new StringBuf();
		var max : Int = Math.floor(s.length/2) + 1;
		for(x in 0...max) {
			var l = s.substr(Std.int(x*2),2);
			var r = StringTools.baseDecode(
						l,
						Constants.DIGITS_HEXL
					);
			sb.add( r );
		}
		return sb.toString();
	}

	/**
		Transform an array of integers x where 0xFF >= x >= 0 to
		a string of binary data, optionally padded to a multiple of
		padToBytes
	**/
	public static function byteArrayToString(a: Array<Int>, ?padToBytes:Int) :String  {
		var sb = new StringBuf();
		for(i in a) {
			if(i > 0xFF || i < 0)
				throw "Value out of range";
			sb.add(Std.chr(i));
		}
		if(padToBytes > 0) {
			return nullPadString(sb.toString(), padToBytes);
		}
		return sb.toString();
	}

	/**
		Convert an array of 32bit integers to a little endian string<br />
	**/
#if neko
	public static function int32ToString(l : Array<Int32>) : String
#else true
	public static function int32ToString(l : Array<Int>) : String
#end
	{
		return I32.packLE(l);
	}

	/**
		Convert a string containing 32bit integers to an array of ints<br />
		If the string length is not a multiple of 4, it will be NULL padded
		at the end.
	**/
#if neko
	public static function strToInt32(s : String) : Array<neko.Int32>
#else true
	public static function strToInt32(s : String) : Array<Int>
#end
	{
		return I32.unpackLE(nullPadString(s,4));
	}

	/**
		Create a string initialized to nulls of length len
	**/
	public static function nullString( len : Int ) : String {
		var sb = new StringBuf();
		for(i in 0...len)
			sb.addChar(0);
		return sb.toString();
	}

	/**
		Pad a string with NULLs to the specified chunk length. Note
		that 0 length strings passed to this will not be padded. See also
		nullString()
	**/
	public static function nullPadString(s : String, chunkLen: Int) {
		var r = chunkLen - (s.length % chunkLen);
		if(r == chunkLen)
			return s;
		var sb = new StringBuf();
		sb.add(s);
		for(x in 0...r) {
			sb.add(Std.chr(0));
		}
		return sb.toString();
	}

	/**
		Remove nulls at the end of a string
	**/
	public static function unNullPadString(s : String) {
		var er : EReg = ~/\0+$/;
		return er.replace(s, '');
	}

	/*
	public static function intsToPaddedString(a : Array<Int>, ?padTo : Int) {
		var sb = new StringBuf();
		if(padTo > 0) {
			var r = padTo - (a.length % padTo);
			for(i in 0...r) {
				sb.add(Std.chr(0));
			}
		}
		return sb.toString();
	}
	*/

	/**
		Dump a string into hex bytes
	**/
	public static function hexDump(data : String) {
		var sb = new StringBuf();
		for(i in 0...data.length) {
			sb.add(StringTools.hex(data.charCodeAt(i),2));
			sb.add(" ");
		}
		return StringTools.rtrim(sb.toString());
	}
}