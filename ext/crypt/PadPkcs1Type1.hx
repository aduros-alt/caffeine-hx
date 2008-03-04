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

/**
	Pads string with 0xFF bytes
**/
class PadPkcs1Type1 implements IPad {
	public var blockSize(default,setBlockSize) : Int;
	public var textSize(default,null) : Int;
	/** only for Type1, the byte to pad with, default 0xFF **/
	public var padByte(getPadByte,setPadByte) : Int;
	var padCount : Int;
	var typeByte : Int;

	public function new(size:Int) {
		Reflect.setField(this,"blockSize",size);
		setPadCount(8);
		typeByte = 1;
		padByte = 0xFF;
	}

	public function pad( s : String ) : String {
		if(s.length > textSize)
			throw "Unable to pad block";
		var sb = new StringBuf();
		sb.addChar(0);
		sb.addChar(typeByte);
		var n = blockSize - s.length - 3; //padCount + (textSize - s.length);
		while(n-- > 0) {
			sb.addChar(getPadByte());
		}
		sb.addChar(0);
		sb.add(s);

		return sb.toString();
	}

	public function unpad( s : String ) : String {
		// src string may be shorter than block size. This happens when
		// converting to BigIntegers then to padded string before calling
		// unpad.
		var i : Int = 0;
trace(ByteStringTools.hexDump(s));
		var sb = new StringBuf();
		while(i < s.length) {
			while( i < s.length && s.charCodeAt(i) == 0) ++i;
			if(s.length-i-3-padCount < 0) {
				throw("Unexpected short message");
			}
			if(s.charCodeAt(i) != typeByte)
				throw("Expected marker "+ typeByte + " at position "+i + " [" + ByteStringTools.hexDump(s) + "]");
			if(++i >= s.length)
				return sb.toString();
			while(i < s.length && s.charCodeAt(i) != 0) ++i;
			i++;
			var n : Int = 0;
			while(i < s.length && n++ < textSize )
				sb.addChar(s.charCodeAt(i++));
		}
		return sb.toString();
	}

	public function calcNumBlocks(len : Int) : Int {
		return Math.ceil(len/blockSize);
	}

	/** pads by block? **/
	public function isBlockPad() : Bool { return true; }

	/** number of bytes padding needs per block **/
	public function blockOverhead() : Int { return 3 + padCount; }

	/**
		PKCS1 has a 3 + padCount byte overhead per block. For RSA
		padCount should be the default 8, for a total of 11 bytes
		overhead per block.
	**/
	public function setPadCount(x : Int) : Int {
		if(x + 3 >= blockSize)
			throw("Internal padding size exceeds crypt block size");
		padCount = x;
		textSize = blockSize - 3 - padCount;
		return x;
	}

	private function setBlockSize( x : Int ) : Int {
		this.blockSize = x;
		this.textSize = x - 3 - padCount;
		if(textSize <= 0)
			throw "Block size " + x + " to small for Pkcs1 with padCount "+padCount;
		return x;
	}

	#if as3gen public #end function getPadByte() : Int {
		return this.padByte;
	}

	private function setPadByte(x : Int) : Int {
		this.padByte = x & 0xFF;
		return x;
	}
}
