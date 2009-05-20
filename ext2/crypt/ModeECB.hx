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
	public var cipher(default,null)	: IBlockCipher;
	public var padding				: IPad;

	public function new(bCipher: IBlockCipher, ?padMethod : IPad) {
		if(bCipher == null)
			throw "null crypt";
		cipher = bCipher;
		if(padMethod == null)
			padding = new PadPkcs5(bCipher.blockSize);
		else
			padding = padMethod;
		padding.blockSize = bCipher.blockSize;
	}

	public function toString() {
		if(cipher != null)
			return Std.string(cipher) + "-ecb";
		return "???-???-ecb";
	}

	public function encrypt( s : Bytes ) : Bytes {
		var buf : Bytes = null;
		var padBlocks : Bool = padding.isBlockPad();
		var tsize = padding.textSize;
		var bsize = padding.blockSize;
		var numBlocks = padding.calcNumBlocks(s.length);
		var offset : Int = 0;
// trace(s);
// trace(padBlocks);
// trace(tsize);
// trace(bsize);
// trace(numBlocks);
		var sb = new BytesBuffer();
 		if(!padBlocks)
			buf = padding.pad(s);
		for (i in 0...numBlocks) {
			var rv : Bytes;
			if(padBlocks) {
// trace(s.substr(offset, tsize));
				rv = padding.pad(s.sub(offset, tsize));
				offset += tsize;
			}
			else {
				rv = buf.sub(offset, tsize);
				offset += bsize;
			}

// trace(rv.length);
// trace(BytesUtil.hexDump(rv, ""));
			var enc = cipher.encryptBlock(rv);
// trace(BytesUtil.hexDump(cipher.decryptBlock(enc),false));
// trace(BytesUtil.hexDump(enc,""));
			if(enc.length != bsize)
				throw("block encryption to wrong block size");
			sb.add(enc);
// trace(sb.toString().length);
		}
// trace(ByteStringTools.hexDump(sb.toString()));

		return sb.getBytes();
	}

	public function decrypt( s : Bytes ) : Bytes {
		var padBlocks : Bool = padding.isBlockPad();
		var bsize = padding.blockSize;
		if(s.length % bsize != 0)
			throw "Invalid message length " + s.length;
		var numBlocks = Std.int(s.length/bsize);
		var offset : Int = 0;
		var sb = new BytesBuffer();
		for (i in 0...numBlocks) {
			var rv : Bytes = cipher.decryptBlock(s.sub(offset, bsize));
// trace(BytesUtil.hexDump(rv));
			if(!padBlocks)
				sb.add(rv);
			else
				sb.add(padding.unpad(rv));
			offset += bsize;
		}
		if(!padBlocks)
			return padding.unpad(sb.getBytes());
		return sb.getBytes();
	}

	// These have no effect when using ECB mode.
	public function startStreamMode() : Void {}
	public function endStreamMode() : Void {}
}