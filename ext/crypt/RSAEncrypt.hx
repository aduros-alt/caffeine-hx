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

package crypt;

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
	public var blockSize(getBlockSize,null) : Int;

	public function new(?nHex:String,?eHex:String) {
		this.n = null;
		this.e = 0;
		if(nHex != null)
			setPublic(nHex, eHex);
	}

	/**
		Set the public key fields N (modulus) and E (public exponent)
		from hex strings.
	**/
	public function setPublic(nHex : String, eHex:String) : Void {
		try {
			if(nHex == null || eHex == null || nHex.length == 0 || eHex.length == 0)
				throw 1;
			var s : String = cleanFormat(nHex);
			n = BigInteger.ofString(s, 16);
			if(n == null) throw 2;
			var ie : Null<Int> = Std.parseInt("0x" + cleanFormat(eHex));
			if(ie == null || ie == 0) throw 3;
			e = ie;
		}
		catch(e:Dynamic)
			throw("Invalid RSA public key: " + e);
	}

	/**
		Return the PKCS#1 RSA encryption of "text" as an
		even-length hex string
		TODO: Return Binary string, not text. Use padding etc...
	**/
	public function encrypt( text : String ) : String {
		return doEncrypt(text, doPublic, new PadPkcs1Type2(blockSize));
	}

	public function verify( text : String ) : String {
		return doDecrypt(text, doPublic, new PadPkcs1Type1(blockSize));
	}

	public function encryptBlock( block : String ) : String {
		var bsize : Int = blockSize;
		if(block.length != bsize)
			throw("bad block size");

		var biv:BigInteger = BigInteger.ofString(block, 256);
trace("BI of Block: " + biv.toRadix(16));
trace("e: " + StringTools.hex(e));
trace("n: " + n.toRadix(16));
trace(n.bitLength());
		var biRes = doPublic(biv);
trace("result: " + biRes.toRadix(16));
		var ba = biRes.toByteArray();
trace(ba);

		while(ba.length > bsize) {
			if(ba[0] == 0)
				ba.shift();
			else {
				trace(ByteString.hexDump(ByteString.ofIntArray(ba).toString()));
				throw("encoded length was "+ba.length);
			}
		}
		while(ba.length < bsize)
			ba.unshift(0); // = Std.chr(0) + buf;

		var rv = ByteString.ofIntArray(ba).toString();
		trace(ByteString.hexDump(rv));
		return rv;
	}

	public function decryptBlock( enc : String ) : String {
		throw("Not a private key");
		return "";
	}
/*
	http://www.imc.org/ietf-openpgp/mail-archive/msg14307.html
	public function verify( text : String ) : String {
		return doDecrypt(text, doPublic, 0x01);
	}
*/

	//////////////////////////////////////////////////
	//               Private                        //
	//////////////////////////////////////////////////
	function doEncrypt(src:String, f : BigInteger->BigInteger, pf : IPad) : String
	{
trace("source: " + src);
		var bs = blockSize;
		var ts : Int = bs - 11;
		var idx : Int = 0;
		var msg = new StringBuf();
		while(idx < src.length) {
			var m:BigInteger = BigInteger.ofString(pf.pad(src.substr(idx,ts)),256);
trace("padded: " + m.toRadix(16));
			if(m == null) return null;
			var c:BigInteger = f(m);
			if(c == null) return null;
			var h = c.toRadix(16);
			if((h.length & 1) != 0)
				msg.add( "0" );
trace("crypted: " + h);
			msg.add(h);
			idx += ts;
		}
		return msg.toString();
	}

	function doDecrypt(src: String, f : BigInteger->BigInteger, pf : IPad) : String
	{
		var bs = blockSize;
		bs *= 2; // hex string, 2 bytes per char
		var ts : Int = bs - 11;
		var idx : Int = 0;
		var msg = new StringBuf();
		while(idx < src.length) {
			var s : String = src.substr(idx,bs);
			var c : BigInteger= BigInteger.ofString(s, 16);
			var m = f(c);
			if(m == null)
				return null;
			var up:String = pf.unpad(m.toRadix(256));
			if(up.length > ts)
				throw "block text length error";
			msg.add(up);
			idx += bs;
		}
		return msg.toString();
	}


	// Perform raw public operation on "x": return x^e (mod n)
	function doPublic(x : BigInteger) : BigInteger {
		return x.modPowInt(this.e, this.n);
	}

	//////////////////////////////////////////////////
	//             getters/setters                  //
	//////////////////////////////////////////////////
	function getBlockSize() : Int {
		if(n == null)
			return 0;
		return (n.bitLength()+7)>>3;
	}

	//////////////////////////////////////////////////
	//               Convenience                    //
	//////////////////////////////////////////////////
	/**
		Cleans out all carriage returns and colons
		from input hex strings
	**/
	function cleanFormat(s : String) : String {
		var e : String = StringTools.replace(s, ":", "");
#if (neko || flash9 || js)
		var ereg : EReg = ~/([\s]*)/g;
		e = ereg.replace(e, "");
#else true
		var ol : Int = 0;
		var nl : Int = e.length;
		while(nl != ol) {
			ol = nl;
			e = StringTools.replace(e, "\r", "");
			e = StringTools.replace(e, "\n", "");
			e = StringTools.replace(e, "\t", "");
			e = StringTools.replace(e, " ", "");
			nl = e.length;
		}
#end
		return e;
	}

	public function toString() {
		var sb = new StringBuf();
		sb.add("Public:\n");
		sb.add("N:\t" + n.toRadix(16) + "\n");
		sb.add("E:\t" + BigInteger.ofInt(e).toRadix(16) + "\n");
		return sb.toString();
	}
}

