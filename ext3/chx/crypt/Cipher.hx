/*
 * Copyright (c) 2012, The Caffeine-hx project contributors
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
import chx.crypt.padding.PadPkcs5;
import chx.io.Output;

/**
 * To encrypt or decrypt in multiple steps, use the update followed by the final
 * method. To encrypt or decrypt in a single step, the 'final' method can be used
 * without a preceding 'update'.
 **/
class Cipher {
	public var params(default,null) : CipherParams;
	var direction : CipherDirection;
	var algo : IBlockCipher;
	var mode : IMode;
	var pad : IPad;
	var buf : Bytes;
	var ptr : Int;
	var blockSize : Int;

	var modeUpdate : Bytes->Output->Int;
	var modeFinal : Bytes->Output->Int;

	/**
	 * Create a cipher from a decryption algorithm, a mode and a padding method.
	 **/
	public function new(algo:IBlockCipher, mode:IMode, pad:IPad) {
		
		this.algo = algo;
		this.mode = mode;
		this.pad = pad;

		if(pad == null)
			this.pad = new PadPkcs5();
		else
			this.pad = pad;
	}

	/**
	 * Initialize the Cipher for encryption or decryption.
	 * @param direction For encrypt or decrypt, overrides direction setting in params
	 * @param params
	 **/
	public function init(direction:CipherDirection, params : CipherParams=null) : Void {
		this.direction = direction;
		switch(direction) {
		case ENCRYPT:
			modeUpdate = mode.updateEncrypt;
			modeFinal = mode.finalEncrypt;
		case DECRYPT:
			modeUpdate = mode.updateDecrypt;
			modeFinal = mode.finalDecrypt;
		}
		if(params == null)
			this.params = new CipherParams();
		else
			this.params = params.clone();
		this.params.direction = direction;

		mode.cipher = algo;
		mode.padding = pad;

		// streaming modes will have blocksizes less than that of the
		// underlying crypt
		this.blockSize = mode.blockSize;
		buf = Bytes.alloc(this.blockSize);
		ptr = 0;
		
		//algo.init(params);
		mode.init(params);
		//pad.init();
	}

	/**
	 * Update the cipher with any number of bytes.
	 * @param input Bytes object with bytes to encrypt or decrypt
	 * @param inputOffset Offset into 'input' to read from
	 * @param inputLen Number of bytes to read from 'input'
	 * @param out An Output stream of any kind
	 **/
	public function update(input:Bytes, inputOffset:Int, inputLen:Int, out:Output) : Int {
		if(inputLen <= 0)
			return 0;
		var rv = 0;
		while(true) {
			var num = Std.int(Math.min(blockSize-ptr, inputLen - rv));
			if(num <= 0) break;
			for(i in 0...num) {
				Assert.isTrue(ptr + i < blockSize);
				buf.set(i+ptr, input.get(i + inputOffset));
			}
			inputOffset += num;
			ptr += num;
			Assert.isTrue(ptr <= blockSize);
			if(ptr == blockSize) {
				var written = modeUpdate(buf, out);
				Assert.isTrue(written == blockSize);
				ptr = 0;
			}
			rv += num;
		}
		return rv;
	}

	/**
	 * Update and finalize the cipher with any number of bytes.
	 * @param input Bytes object with bytes to encrypt or decrypt
	 * @param inputOffset Offset into 'input' to read from
	 * @param inputLen Number of bytes to read from 'input'
	 * @param out An Output stream of any kind
	 **/
	public function final(input:Bytes, inputOffset:Int, inputLen:Int, out:Output) : Int {
		var rv : Int = 0;
		var read : Int = 1;
		while(read > 0) {
			read = update(input,inputOffset,inputLen,out);
			rv += read;
			inputOffset += read;
			inputLen -= read;
		}
		var rem : Bytes = buf.sub(0,ptr);
		rv += modeFinal(rem, out);
		return rv;
	}

}
