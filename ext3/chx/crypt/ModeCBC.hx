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

package chx.crypt;

class ModeCBC extends IV, implements IMode {
	public function new(bCipher: IBlockCipher, ?pad : IPad) {
		super(bCipher, pad);
	}

	public function toString() {
		if(cipher != null)
			return Std.string(cipher) + "-cbc";
		return "???-???-cbc";
	}

	/**
	 * @TODO proper block padding, refer to ModeECB
	 **/
	public function encrypt( s : Bytes ) : Bytes {
		var buf = prepareEncrypt( s );
		var bsize = cipher.blockSize;
		var numBlocks = Std.int(buf.length/bsize);
		var offset : Int = 0;
		var sb = new BytesBuffer();

		var curIV = iv;
		//trace("Starting IV: " + curIV.toHex());
		for (i in 0...numBlocks) {
			var tb = Bytes.alloc(cipher.blockSize);
			for(x in 0...cipher.blockSize) {
				var bc : Int = buf.get(offset + x);
				var ic : Int = curIV.get(x);
				tb.set(x, bc ^ ic );
			}
			var crypted = cipher.encryptBlock(tb);
			sb.add(crypted);
			curIV = crypted;
			offset += cipher.blockSize;
		}
		return finishEncrypt(sb.getBytes());
	}

	public function decrypt( s : Bytes ) : Bytes {
		var buf = prepareDecrypt( s );
		var bsize = cipher.blockSize;
		if(buf.length % bsize != 0)
			throw "Invalid buffer length";
		var numBlocks = Std.int(buf.length/bsize);
		var offset : Int = 0;
		var sb = new BytesBuffer();

		for (i in 0...numBlocks) {
			var rv = cipher.decryptBlock(buf.sub(offset, bsize));
			var tb = Bytes.alloc(bsize);
			for(x in 0...cipher.blockSize) {
				tb.set(x, rv.get(x) ^ currentIV.get(x));
			}
			sb.add(tb);
			currentIV = buf.sub(offset, cipher.blockSize);
			offset += bsize;
		}
		return finishDecrypt(sb.getBytes());
	}
}
