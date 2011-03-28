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

/*
 * Derived from javascript implementation Copyright (c) 2005 Tom Wu
 *
 */

package chx.crypt;

import math.BigInteger;
import math.prng.Random;

/**
	RSAEncrypt encrypts using a provided public key. If decryption is
	required, use the derived class RSADecrypt which can encypt and decrypt.
**/
class RSAEncrypt implements IBlockCipher {
	// public key
	/** modulus **/
	public var n : BigInteger;
	/** exponent. <2^31 **/
	public var e : Int;
	public var blockSize(__getBlockSize,null) : Int;

	public function new(?nHex:String,?eHex:String) {
		this.n = null;
		this.e = 0;
		if(nHex != null)
			setPublic(nHex, eHex);
	}

	/**
	* Decrypts a pre-padded buffer.
	*
	* @param block Block of encrypted data that must be exactly blockSize long
	* @return blockSize buffer with decrypted data.
	**/
	public function decryptBlock( enc : Bytes ) : Bytes {
		throw("Not a private key");
		return null;
	}

	/**
	* Return the PKCS#1 RSA encryption of [buf]
	*
	* @param buf plaintext buffer
	* TODO: Return Binary string, not text. Use padding etc...
	**/
	public function encrypt( buf : Bytes ) : Bytes {
		return doBufferEncrypt(buf, doPublic, new PadPkcs1Type2(blockSize));
	}

	/**
	* Encrypt a pre-padded buffer.
	*
	* @param block Block of plaintext that must be exactly blockSize long
	* @return blockSize buffer with crypted data.
	**/
	public function encryptBlock( block : Bytes ) : Bytes {
		var bsize : Int = blockSize;
		if(block.length != bsize)
			throw("bad block size");

		var biv:BigInteger = BigInteger.ofBytes(block);
// 		trace("BI of Block: " + biv.toRadix(16));
// 		trace("e: " + StringTools.hex(e));
// 		trace("n: " + n.toRadix(16));
// 		trace(n.bitLength());
		var biRes = doPublic(biv);
// 		trace("result: " + biRes.toRadix(16));
		var ba = biRes.toIntArray();
// 		trace(ba);

		while(ba.length > bsize) {
			if(ba[0] == 0)
				ba.shift();
			else {
				trace(BytesUtil.hexDump(BytesUtil.ofIntArray(ba)));
				throw("encoded length was "+ba.length);
			}
		}
		while(ba.length < bsize)
			ba.unshift(0); // = Std.chr(0) + buf;

		var rv = BytesUtil.ofIntArray(ba);
		trace(BytesUtil.hexDump(rv));
		return rv;
	}

	/**
	* Return the PKCS#1 RSA encryption of "text" as an hex string, with [:] as
	* a separator character.
	*
	* @param text Text to encrypt.
	* @param separator character to put between hex values in output
	**/
	public function encyptText( text : String, separator:String = ":") : String {
		return BytesUtil.toHex(
				encrypt( Bytes.ofString(text) ),
				":");
	}

	/**
	* Set the public key fields N (modulus) and E (public exponent)
	* from hex strings.
	**/
	public function setPublic(nHex : String, eHex:String) : Void {
		try {
			if(nHex == null || eHex == null || nHex.length == 0 || eHex.length == 0)
				throw 1;
			var s : String = BytesUtil.cleanHexFormat(nHex);
			n = BigInteger.ofString(s, 16);
			if(n == null) throw 2;
			var ie : Null<Int> = Std.parseInt("0x" +  BytesUtil.cleanHexFormat(eHex));
			if(ie == null || ie == 0) throw 3;
			e = ie;
		}
		catch(e:Dynamic)
			throw("Invalid RSA public key: " + e);
	}

	/**
	* Verify a signature
	*
	* @todo http://www.imc.org/ietf-openpgp/mail-archive/msg14307.html
	* @todo verify implementation
	**/
	public function verify( text : Bytes ) : Bytes {
		return doBufferDecrypt(text, doPublic, new PadPkcs1Type1(blockSize));
	}


	//////////////////////////////////////////////////
	//               Private                        //
	//////////////////////////////////////////////////
	/**
	* Encrypts a hex string to a hex string
	*
	* @param src Input hex string
	* @param f Callback for encryption
	* @param pf Padding method
	**/
	private function doBufferEncrypt(src:Bytes, f : BigInteger->BigInteger, pf : IPad) : Bytes
	{
		//trace("source: " + src);
		var bs = blockSize;
		var ts : Int = bs - 11;
		var idx : Int = 0;
		var msg = new BytesBuffer();
		while(idx < src.length) {
			if(idx + ts > src.length)
				ts = src.length - idx;
			var m:BigInteger = BigInteger.ofBytes(pf.pad(src.sub(idx,ts)) );
			//trace("padded: " + m.toRadix(16).toString());
			if(m == null) return null;
			var c:BigInteger = f(m);
			if(c == null) return null;
			var h = c.toRadix(256);
			if((h.length & 1) != 0)
				msg.addByte( 0 );
			//trace("crypted: " + h.toString());
			msg.add(h);
			idx += ts;
		}
		return msg.getBytes();
	}

	private function doBufferDecrypt(src: Bytes, f : BigInteger->BigInteger, pf : IPad) : Bytes
	{
		var bs = blockSize;
		bs *= 2; // hex string, 2 bytes per char
		var ts : Int = bs - 11;
		var idx : Int = 0;
		var msg = new BytesBuffer();
		while(idx < src.length) {
			if(idx + bs > src.length)
				bs = src.length - idx;
			var c : BigInteger = BigInteger.ofBytes(src.sub(idx,bs));
			var m = f(c);
			if(m == null)
				return null;
			var up : Bytes = pf.unpad(m.toRadix(256));
			if(up.length > ts)
				throw "block text length error";
			msg.add(up);
			idx += bs;
		}
		return msg.getBytes();
	}

	// Perform raw public operation on "x": return x^e (mod n)
	function doPublic(x : BigInteger) : BigInteger {
		return x.modPowInt(this.e, this.n);
	}

	//////////////////////////////////////////////////
	//             getters/setters                  //
	//////////////////////////////////////////////////
	function __getBlockSize() : Int {
		if(n == null)
			return 0;
		return (n.bitLength()+7)>>3;
	}

	//////////////////////////////////////////////////
	//               Convenience                    //
	//////////////////////////////////////////////////


	public function toString() {
		var sb = new StringBuf();
		sb.add("Public:\n");
		sb.add("N:\t" + n.toRadix(16).toString() + "\n");
		sb.add("E:\t" + BigInteger.ofInt(e).toRadix(16).toString() + "\n");
		return sb.toString();
	}
}

