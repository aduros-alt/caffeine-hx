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

package chx.hash;

/**
	Keyed Hash Message Authentication Codes<br />
	<a href='http://en.wikipedia.org/wiki/Hmac'>Wikipedia entry</a>
**/
class HMAC {
	var hash : IHash;
	var bits : Int;

	public function new(hashMethod : IHash, bits : Null<Int>=0) {
		this.hash = hashMethod;
		var hb = hashMethod.getLengthBits();
		if(bits == 0) {
			bits = hb;
		}
		else if(bits > hb){
			bits = hb;
		}
		else if(bits <= 0) {
			throw "Invalid HMAC length";
		}
	}

	public function toString() : String {
		return "hmac-" + Std.string(bits) + Std.string(hash);
	}

	public function calculate(key : Bytes, msg : Bytes ) : Bytes {
		var B = hash.getBlockSizeBytes();
		var K : Bytes = key;

		if(K.length > B) {
			K = hash.calcBin(K);
		}
		K = BytesUtil.nullPad(K, B).sub(0, B);

		var Ki = new BytesBuffer();
		var Ko = new BytesBuffer();
		for (i in 0...K.length) {
			Ki.addByte(K.get(i) ^ 0x36);
			Ko.addByte(K.get(i) ^ 0x5c);
		}
		// hash(Ko + hash(Ki + message))
		Ki.add(msg);
		Ko.add(hash.calcBin(Ki.getBytes()));
		return hash.calcBin(Ko.getBytes());
	}

}