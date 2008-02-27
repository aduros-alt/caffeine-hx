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

	public function new(?N:String,?E:String) {
		this.n = null;
		this.e = 0;
		if(N != null)
			setPublic(N, E);
	}

	/**
		Set the public key fields N (modulus) and E (public exponent)
		from hex strings.
	**/
	public function setPublic(N : String, E:String) : Void {
		if(N != null && E != null && N.length > 0 && E.length > 0) {
			this.n = parseBigInt(cleanFormat(N),16);
			this.e = Std.parseInt("0x" + cleanFormat(E));
		}
		else
			throw("Invalid RSA public key");
	}

	/**
		Return the PKCS#1 RSA encryption of "text" as an
		even-length hex string
		TODO: Return Binary string, not text. Use padding etc...
	**/
	public function encrypt( text : String ) : String {
		return doEncrypt(text, doPublic, 0x02);
	}

	public function encryptBlock( block : String ) : String {
		var bsize : Int = blockSize;
		if(block.length != bsize)
			throw("bad block size");

		var biv = BigInteger.nbi();
		biv.fromString(block, 256);
trace("BI of Block: " + biv.toRadix(16));
trace("e: " + StringTools.hex(e));
trace("n: " + n.toRadix(16));
var biRes = doPublic(biv);
trace("result: " + biRes.toRadix(16));
		var ba = doPublic(biv).toByteArray();

		while(ba.length > bsize) {
			if(ba[0] == 0)
				ba.shift();
			else {
				trace(ByteStringTools.hexDump(ByteString.ofIntArray(ba).toString()));
				throw("encoded length was "+ba.length);
			}
		}
		while(ba.length < bsize)
			ba.unshift(0); // = Std.chr(0) + buf;

		var rv = ByteString.ofIntArray(ba).toString();
		trace(ByteStringTools.hexDump(rv));
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

	function doEncrypt(src:String, f : BigInteger->BigInteger, padType : Int)
	{
trace(src);
trace(src.length);
		var bs = blockSize;
		var ts : Int = bs - 11;
trace("Blocksize : "+bs);
		var idx : Int = 0;
		var msg = new StringBuf();
		while(idx < src.length) {
			var m = pkcs1pad2(src.substr(idx,ts), bs);
trace(m.bitCount());
			if(m == null) return null;
			var c = f(m);
//trace(c.chunks);
			if(c == null) return null;
			var h = c.toRadix(16);
trace(h.length);
			msg.add(if((h.length & 1) == 0) h; else "0" + h);
			idx += ts;
		}
trace(msg.toString().length);
		return msg.toString();
	}

	// Perform raw public operation on "x": return x^e (mod n)
	function doPublic(x : BigInteger) : BigInteger {
		return x.modPowInt(this.e, this.n);
	}

	//////////////////////////////////////////////////
	//               Padding                        //
	//////////////////////////////////////////////////
	/**
		PKCS#1 (type 2, random) pad input string s to n bytes,
		and return a bigint
	**/
	function pkcs1pad2(s : String, n : Int) : BigInteger {
		if(n < s.length + 11) {
			throw("Message too long for RSA");
			return null;
		}
		var ba = new Array<Int>();
		var i = s.length - 1;
		while(i >= 0 && n > 0)
			ba[--n] = s.charCodeAt(i--);
		ba[--n] = 0;
		var rng = new Random();
		var x = new Array<Int>();
		while(n > 2) { // random non-zero pad
			x[0] = 0;
			while(x[0] == 0) rng.nextBytesArray(x);
			ba[--n] = x[0];
		}
		ba[--n] = 2;
		ba[--n] = 0;
trace(ba);
trace(ba.length);
		var bv = BigInteger.nbi();
		bv.fromByteArray(ba,0,ba.length);
trace(bv.toByteArray());
trace(bv.toByteArray().length);
		return bv;
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
	// convert a (hex) string to a bignum object
	function parseBigInt(str:String, r : Int) : BigInteger {
		var bi = BigInteger.nbi();
		bi.fromString(str,r);
		return bi;
	}

	/**
		Cleans out all carriage returns and colons
		from input hex strings
	**/
	function cleanFormat(s : String) : String {
#if (neko || flash9 || js)
		var e = StringTools.replace(s, ":", "");

		var ereg : EReg = ~/([\s]*)/g;
		e = ereg.replace(e, "");
#else true
		var e = s;
		var ol : Int = 0;
		var nl : Int = s.length;
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

}

