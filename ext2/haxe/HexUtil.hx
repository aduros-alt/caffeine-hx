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

import I32;

class HexUtil {
	public static function intToHex(j:Int)
	{
		var sb = new StringBuf();
		var i : Int = 8;
		while(i-- > 0) {
			var v : Int = (j>>>(i*4)) & 0xf;
			sb.add(StringTools.hex(v).toLowerCase());
		}
		return sb.toString();
	}

	public static function int32ToHex(j:Int32)
	{
		var sb = new StringBuf();
		var i : Int = 8;
		var f = Int32.ofInt(0xf);
		while(i-- > 0) {
			var v : Int = Int32.toInt(Int32.and(Int32.ushr(j,(i*4)), f));
			sb.add(StringTools.hex(v).toLowerCase());
		}
		return sb.toString();
	}

	public static function bytesToHex(b : Bytes) : String {
		var l = b.length;
		var i = 0;
		var sb = new StringBuf();
		while(i < l) {
			var v = b.get(i);
			sb.addChar(Constants.DIGITS_HEXL.charCodeAt((v >>> 4) & 0xf));
			sb.addChar(Constants.DIGITS_HEXL.charCodeAt(v & 0xf));
			i++;
		}
		return sb.toString();
	}
}