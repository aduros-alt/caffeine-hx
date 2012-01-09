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

	public function new(nHex:String,eHex:String) {
		init();
		if(nHex != null)
			setPublic(nHex, eHex);
	}

	private function init() {
		this.n = null;
		this.e = 0;
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

		var biv:BigInteger = BigInteger.ofBytes(block, true);
// 		trace("BI of Block: " + biv.toHex());
// 		trace("e: " + StringTools.hex(e));
// 		trace("n: " + n.toHex());
// 		trace(n.bitLength());
		var biRes = doPublic(biv).toBytesUnsigned();
// 		trace("result: " + biRes.toHex());
// 		trace(ba);

		var l = biRes.length;
		var i = 0;
		while(l > bsize) {
			if(biRes.get(i) != 0) {
				//trace(BytesUtil.hexDump(BytesUtil.ofIntArray(ba)));
				throw new chx.lang.FatalException("encoded length was "+biRes.length);
			}
			i++; l--;
		}
		if(i != 0) {
			biRes = biRes.sub(i, l);
		}

		if(biRes.length < bsize) {
			var bb = new BytesBuffer();
			l = bsize - biRes.length;
			for(i in 0...l)
				bb.addByte(0);
			bb.addBytes(biRes, 0, biRes.length);
			biRes = bb.getBytes();
		}
		return biRes;
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
		init();
		if(nHex == null || nHex.length == 0)
			throw new chx.lang.NullPointerException("nHex not set: " + nHex);
		if(eHex == null || eHex.length == 0)
			throw new chx.lang.NullPointerException("eHex not set: " + eHex);
		//try {
			var s : String = BytesUtil.cleanHexFormat(nHex);
			n = BigInteger.ofString(s, 16);
			if(n == null) throw 2;
			var ie : Null<Int> = Std.parseInt("0x" +  BytesUtil.cleanHexFormat(eHex));
			if(ie == null || ie == 0) throw 3;
			e = ie;
		//}
		//catch(e:Dynamic)
		//	throw("Invalid RSA public key: " + e);
	}

	/**
	* Verify a signature
	*
	* @todo http://www.imc.org/ietf-openpgp/mail-archive/msg14307.html
	* @todo verify implementation
	**/
	public function verify( data : Bytes ) : Bytes {
		return doBufferDecrypt(data, doPublic, new PadPkcs1Type1(blockSize));
	}


	//////////////////////////////////////////////////
	//               Private                        //
	//////////////////////////////////////////////////
	/**
	* Encrypts a bytes buffer
	*
	* @param src Input bytes
	* @param f Callback for encryption
	* @param pf Padding method
	**/
	private function doBufferEncrypt(src:Bytes, f : BigInteger->BigInteger, pf : IPad) : Bytes
	{
		//trace("source: " + src.toHex());
		var bs = blockSize;
		var ts : Int = bs - 11;
		#if CAFFEINE_DEBUG
		trace(">>>> Encrypting. Blocksize is "+bs + " src length:"+src.length + "["+src.toHex()+"]");
		#end
		var idx : Int = 0;
		var msg = new BytesBuffer();
		while(idx < src.length) {
			if(idx + ts > src.length)
				ts = src.length - idx;
			var m:BigInteger = BigInteger.ofBytes(pf.pad(src.sub(idx,ts)), true);
			var c:BigInteger = f(m);

			#if CAFFEINE_DEBUG
			var d = m.toBytesUnsigned();
			var e = c.toBytesUnsigned();
			trace("m (padded) len " + d.length + " "+d.toHex(":"));
			trace("c (crypted) len " + e.length + " "+e.toHex(":"));
			#end

			var h = c.toBytesUnsigned();
			//var
			if((h.length & 1) != 0)
				msg.addByte( 0 );

			#if CAFFEINE_DEBUG
			trace(">>>> crypted ("+h.length+"): " + h.toHex());
			#end

			msg.add(h);
			idx += ts;
		}
		return msg.getBytes();
	}

	private function doBufferDecrypt(src: Bytes, f : BigInteger->BigInteger, pf : IPad) : Bytes
	{
		//trace("source: " + src.toHex());
		var bs = blockSize;
		//bs *= 2; // hex string, 2 bytes per char
		var ts : Int = bs - 11;
		#if CAFFEINE_DEBUG
		trace(">>>> Decrypting. Blocksize is "+ bs + " src length:"+src.length + "["+src.toHex()+"]");
		#end
		var idx : Int = 0;
		var msg = new BytesBuffer();
		while(idx < src.length) {
			if(idx + bs > src.length)
				bs = src.length - idx;
			var c : BigInteger = BigInteger.ofBytes(src.sub(idx,bs), true);
			var m = f(c);
			if(m == null)
				return null;

			#if CAFFEINE_DEBUG
			var d = m.toBytesUnsigned();
			var e = c.toBytesUnsigned();
			trace("c (crypted) len " + e.length + " "+e.toHex(":"));
			trace("m (padded) len " + d.length + " "+d.toHex(":"));
			#end

			var up : Bytes = pf.unpad(m.toBytesUnsigned());
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
		sb.add("N:\t" + n.toHex() + "\n");
		sb.add("E:\t" + BigInteger.ofInt(e).toHex() + "\n");
		return sb.toString();
	}
}

