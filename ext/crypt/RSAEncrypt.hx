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
class RSAEncrypt {
	// public key
	public var n : BigInteger;	// modulus
	public var e : Int;			// exponent. <2^31

	public function new() {
		this.n = null;
		this.e = 0;
	}

	/**
		Set the public key fields N and e from hex strings
	**/
	public function setPublic(N : String, E:String) : Void {
		if(N != null && E != null && N.length > 0 && E.length > 0) {
			this.n = parseBigInt(N,16);
			this.e = Std.parseInt("0x" + E);
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
		var m = pkcs1pad2(text,(n.bitLength()+7)>>3);
		if(m == null) return null;
		var c = doPublic(m);
		if(c == null) return null;
		var h = c.toRadix(16);
		if((h.length & 1) == 0) return h; else return "0" + h;
	}

	//////////////////////////////////////////////////
	//               Private                        //
	//////////////////////////////////////////////////
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
		var bv = BigInteger.nbi();
		bv.fromByteArray(ba,0,ba.length);
trace(bv.toByteArray());
		return bv;
	}

	//////////////////////////////////////////////////
	//             Convenience                      //
	//////////////////////////////////////////////////
	// convert a (hex) string to a bignum object
	function parseBigInt(str:String, r : Int) {
		return BigInteger.ofString(str,r);
	}
/*
	function linebrk(s:String, n : Int) {
		var ret = "";
		var i = 0;
		while(i + n < s.length) {
			ret += s.substr(i,i+n) + "\n";
			i += n;
		}
		return ret + s.substr(i,s.length);
	}
*/

}

