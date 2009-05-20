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

private enum IvState {
	IV_UNINIT;
	IV_BLOCK;
	IV_STREAM_UNINIT;
	IV_STREAM_CONTINUE;
}

/**
	IV itself is not a block encryptor, and should not be called directly.
	Use a Mode that extends IV, like ModeCBC
**/
class IV {
	/** Setting the iv value only affects the next encryption process.
		The value returned from a get may not match the last set. Once
		an ecryption is complete, the next get on iv will reflect the
		changes.
	**/
	public var iv(getIV, setNextIV) 	: Bytes;
	public var cipher(default,null) 	: IBlockCipher;
	public var padding				 	: IPad;
	var prepend 	: Bool;
	var startIV		: Bytes;
	var currentIV	: Bytes;
	var curValue	: Bytes;
	var nextValue	: Bytes;
	var state		: IvState;

	public function new(bCipher: IBlockCipher, ?padMethod : IPad) {
		if(bCipher == null)
			throw "crypt.iv: null crypt";
		cipher = bCipher;
		if(padMethod == null)
			padding = new PadPkcs5(cipher.blockSize);
		else
			padding = padMethod;
		padding.blockSize = bCipher.blockSize;
		prepend = true;
		state = IV_UNINIT;
	}

	/**
		Prepending the IV to the crypted text is the default
		behaviour.
	**/
	public function setPrependMode( p : Bool ) : Void {
		prepend = p;
	}

	public function getIV() : Bytes {
		// trace(here.methodName);
		// trace("Cipher blockSize " + cipher.blockSize);
		// trace("curValue: "  + curValue);
		// trace("nextValue: " + nextValue);
		// if(nextValue != null)
		// trace(nextValue.length);
		if(curValue == null) {
			if(nextValue == null) {
				var sb = new BytesBuffer();
				for(x in 0...cipher.blockSize) {
					sb.addByte(randomByte());
				}
				nextValue = sb.getBytes();
			}
			curValue = nextValue;
			nextValue = null;
			currentIV = curValue;
		}
		return curValue;
	}

	public function setNextIV( s : Bytes ) : Bytes {
		if(s.length % cipher.blockSize != 0 || s.length == 0)
			throw("crypt.iv: invalid length. Expected "+cipher.blockSize+ " bytes.");
		var sb = new BytesBuffer();
		sb.add(s);
		nextValue = sb.getBytes().sub(0,cipher.blockSize);
		return s;
	}

	function prepareEncrypt( s : Bytes ) : Bytes {
		var buf = padding.pad(s);
		if(buf.length % cipher.blockSize != 0)
			throw "crypt.iv: padding error";
		// queues up the next iv and destroys the nextValue if it exists
		getIV();
		return buf;
	}

	/**
		In prepend mode, this will attach the IV to the
		beginning of the buffer. Destroys the current IV
		in preparation for next crypt function.
	**/
	function finishEncrypt( sb : Bytes ) : Bytes {
		var buf : BytesBuffer = new BytesBuffer();
		if(prepend)
			buf.add(getIV());
		buf.add(sb);
		// don't destroy before call to getIV!
		curValue = null;
		return buf.getBytes();
	}

	function prepareDecrypt( s : Bytes ) : Bytes {
		var buf : Bytes;

		if(prepend) {
			var biv = s.sub(0,cipher.blockSize);
			iv = biv;
			if(!BytesUtil.eq(iv, biv))
				throw "crypt.iv: invalid state";
			if(s.length - cipher.blockSize >= 0)
				buf = s.sub(cipher.blockSize, s.length - cipher.blockSize);
			else
				buf = BytesUtil.EMPTY;
		}
		else {
			buf = s;
		}
		if(buf.length % cipher.blockSize != 0)
			throw "crypt.iv: length error";
		return buf;
	}

	function finishDecrypt( s : Bytes ) : Bytes {
		var buf = padding.unpad(s);
		curValue = null;
		return buf;
	}

	private inline function randomByte() : Int {
		return Std.int(Math.random() * 256);
	}

	public function startStreamMode() : Void {
		if(state != IV_UNINIT)
			throw "Cipher in initialized state";
		state = IV_STREAM_UNINIT;
	}

	public function endStreamMode() : Void {
		state = IV_UNINIT;
	}
}
