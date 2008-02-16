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

/**
	Keyed Hash Message Authentication Codes<br />
	<a href='http://en.wikipedia.org/wiki/Hmac'>Wikipedia entry</a>
**/
class HMAC {
	var hash : IHash;
	var bytes : Int;

	public function new(hashMethod : IHash, ?bytes : Int) {
		this.hash = hashMethod;
		var hb = hashMethod.getLengthBytes();
		if(bytes == null) {
			bytes = hb;
		}
		else if(bytes > hb){
			bytes = hb;
		}
		else if(bytes <= 0) {
			throw "Invalid HMAC length";
		}
	}

	public function toString() : String {
		return "hmac-" + Std.string(bytes*8) + Std.string(hash);
	}

	public function calculate(key : String, msg : String ) {
		var B = hash.getBlockSizeBytes();
		var K : String = key;

		if(K.length > B) {
			K = hash.calculate(K);
		}
		K = ByteStringTools.nullPadString(K, B).substr(0, B);

		var Ki = new StringBuf();
		var Ko = new StringBuf();
		for (i in 0...K.length) {
			Ki.addChar(K.charCodeAt(i) ^ 0x36);
			Ko.addChar(K.charCodeAt(i) ^ 0x5c);
		}
		// hash(Ko + hash(Ki + message))
		Ki.add(msg);
		Ko.add(hash.calculate(Ki.toString()));
		return hash.calculate(Ko.toString());
	}

}