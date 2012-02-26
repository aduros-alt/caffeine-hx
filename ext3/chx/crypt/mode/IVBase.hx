/*
 * Copyright (c) 20082012, The Caffeine-hx project contributors
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

package chx.crypt.mode;

import chx.crypt.CipherDirection;
import math.prng.IPrng;

/**
* IV is an abstract base class.
**/
class IVBase extends ModeBase {
	/**
	 * Beware that this value changes with each crypt operation.
	 * For the original value, consult params.iv
	 **/
	public var iv(getIV, setIV) : Bytes;
	var currentIV : Bytes;

	override public function init(params : CipherParams) : Void {
		super.init(params);
		if(params.prng == null)
			params.prng = new math.prng.Random();

		if(params.iv == null) {
			if(params.direction == DECRYPT)
				throw "IV must be set before decryption";
			var sb = new BytesBuffer();
			for(x in 0...cipher.blockSize)
				sb.addByte(params.prng.next());
			params.iv = sb.getBytes();
		}
		currentIV = params.iv.sub(0);
	}

	public function getIV() : Bytes {
		return currentIV;
	}

	public function setIV( s : Bytes ) : Bytes {
		// here we use cipher.blockSize, as it may be different
		// than out mode blockSize
		if(s.length % cipher.blockSize != 0 || s.length == 0)
			throw("crypt.iv: invalid length. Expected "+cipher.blockSize+ " bytes.");
		for(i in 0...cipher.blockSize)
			currentIV.set(i, s.get(i));
		return s;
	}

}
