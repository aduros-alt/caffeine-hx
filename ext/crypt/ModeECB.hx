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

class ModeECB implements IMode {
	public var cipher(default,null)	: ISymetrical;
	public var padding				: IPad;

	public function new(symcrypt: ISymetrical, ?padMethod : IPad) {
		if(symcrypt == null)
			throw "null crypt";
		cipher = symcrypt;
		if(padMethod == null)
			padding = new PadPkcs5(symcrypt.blockSize);
		else
			padding = padMethod;
		padding.blockSize = symcrypt.blockSize;
	}

	public function toString() {
		if(cipher != null)
			return Std.string(cipher) + "-ecb";
		return "???-???-ecb";
	}

	public function encrypt( s : String ) : String {
		var buf = padding.pad(s);
		var bsize = cipher.blockSize;
		var numBlocks = Std.int(buf.length/bsize);
		var offset : Int = 0;
		var sb = new StringBuf();
		for (i in 0...numBlocks) {
			var rv = cipher.encryptBlock(buf.substr(offset, bsize));
			offset += bsize;
			sb.add(rv);
		}
		return sb.toString();
	}

	public function decrypt( s : String ) : String {
		var buf = s;
		var bsize = cipher.blockSize;
		if(buf.length % bsize != 0)
			throw "Invalid buffer length";
		var numBlocks = Std.int(buf.length/bsize);
		var offset : Int = 0;
		var sb = new StringBuf();
		for (i in 0...numBlocks) {
			var rv = cipher.decryptBlock(buf.substr(offset, bsize));
			offset += bsize;
			sb.add(rv);
		}
		return padding.unpad(sb.toString());
	}

	// These have no effect when using ECB mode.
	public function startStreamMode() : Void {}
	public function endStreamMode() : Void {}
}