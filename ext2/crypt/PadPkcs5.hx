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

class PadPkcs5 implements IPad {
	public var blockSize(default,setBlockSize) : Int;
	public var textSize(default,null) : Int;

	public function new( blockLen : Int ) {
		setBlockSize(blockLen);
	}

	public function pad( s : Bytes ) : Bytes {
		var sb = new BytesBuffer();
		sb.add ( s );
		var chr : Int = blockSize - (s.length % blockSize);
		if(s.length == blockSize)
			chr = blockSize;
		for( i in 0...chr) {
			sb.addByte( chr );
		}
		return sb.getBytes();
	}

	public function unpad( s : Bytes ) : Bytes {
		if( s.length % blockSize != 0)
			throw "crypt.padpkcs5 unpad: buffer length "+s.length+" not multiple of block size " + blockSize;
		var c = s.get(s.length-1);
		var i = c;
		var pos = s.length - 1;
		while(i > 0) {
			var n = s.get(pos);
			if (c != n)
				throw "crypt.padpkcs5 unpad: invalid byte";
			pos--;
			i--;
		}
		return s.sub(0, s.length - c);
	}

	function setBlockSize(len : Int) : Int {
		blockSize = len;
		textSize = len;
		return len;
	}

	public function calcNumBlocks(len : Int) : Int {
		var n : Int = Math.ceil(len/blockSize);
		if(len % blockSize == 0)
			n++;
		return n;
	}

	/** pads by block? **/
	public function isBlockPad() : Bool { return false; }

	/** number of bytes padding needs per block **/
	public function blockOverhead() : Int { return 0; }
}
