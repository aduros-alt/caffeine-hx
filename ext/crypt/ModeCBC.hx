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

package crypt;

class ModeCBC extends IV, implements IMode {
	public function new(symcrypt: ISymetrical, ?pad : IPad) {
		super(symcrypt, pad);
	}

	public function toString() {
		if(cipher != null)
			return Std.string(cipher) + "-cbc";
		return "???-???-cbc";
	}

	public function encrypt( s : String ) : String {
		var buf = prepareEncrypt( s );
		var bsize = cipher.blockSize;
		var numBlocks = Std.int(buf.length/bsize);
		var offset : Int = 0;
		var sb = new StringBuf();

		var curIV = iv;
		for (i in 0...numBlocks) {
			var sb2 = new StringBuf();
			for(x in 0...cipher.blockSize) {
				var bc : Int = buf.charCodeAt(offset + x);
				var ic : Int = curIV.charCodeAt(x);
				sb2.addChar( bc ^ ic );
			}
			var outBuffer = cipher.encryptBlock(sb2.toString());
			sb.add(outBuffer);
			curIV = outBuffer;
			offset += cipher.blockSize;
		}
		return finishEncrypt(sb);
	}

	public function decrypt( s : String ) : String {
		var buf = prepareDecrypt( s );
		var bsize = cipher.blockSize;
		if(buf.length % bsize != 0)
			throw "Invalid buffer length";
		var numBlocks = Std.int(buf.length/bsize);
		var offset : Int = 0;
		var sb = new StringBuf();

		for (i in 0...numBlocks) {
			var rv = cipher.decryptBlock(buf.substr(offset, bsize));
			var sb2 = new StringBuf();
			for(x in 0...cipher.blockSize) {
				sb2.addChar( rv.charCodeAt(x) ^ currentIV.charCodeAt(x));
			}
			sb.add(sb2.toString());
			currentIV = buf.substr(offset, cipher.blockSize);
			offset += bsize;
		}
		return finishDecrypt(sb.toString());
	}
}
