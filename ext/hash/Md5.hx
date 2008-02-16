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

package hash;

class Md5 implements IHash {

	public function new() {
	}

	public function toString() : String {
		return "md5";
	}

	public function calculate( msg:String ) : String {
		return encode(msg, false);
	}

	public function getLengthBytes() : Int {
		return 16;
	}

	public function getLengthBits() : Int {
		return 128;
	}

	public function getBlockSizeBytes() : Int {
		return 64;
	}

	public function getBlockSizeBits() : Int {
		return 512;
	}

	public static function encode(msg : String, ?binary:Bool) : String {
		var s = haxe.Md5.encode(msg);
		if(binary) {
			s = ByteStringTools.hexBytesToBinary( s );
		}
		return s;
	}

#if neko
	/**
		Encode any dynamic value, classes, objects etc.
	**/
	public static function objEncode( o : Dynamic, ?binary : Bool ) : String {
		var s : String;
		if(Std.is(o, String)) {
			if(binary)
				s = new String(make_md5(untyped o.__s));
			else
				untyped s = new String(
					base_encode(make_md5(s.__s),
					Constants.DIGITS_HEXL.__s)
				);
		}
		else {
			s = new String(make_md5(o));
			if(!binary)
				s = new String(
					base_encode(untyped s.__s, untyped Constants.DIGITS_HEXL.__s));
		}
		return s;
	}

	static var base_encode = neko.Lib.load("std","base_encode",2);
	static var make_md5 = neko.Lib.load("std","make_md5",1);
#end


}