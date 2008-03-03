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
 */

package crypt;

import math.BigInteger;

/**
	Full RSA encryption class. For encryption only, the base class
	RSAEncrypt can be used instead.
**/
class RSA extends RSAEncrypt, implements IBlockCipher {
	// private key
	public var d : BigInteger;
	public var p : BigInteger;		// prime 1
	public var q : BigInteger;		// prime 2
	public var dmp1 : BigInteger;
	public var dmq1 : BigInteger;
	public var coeff: BigInteger;

	public function new(?N:String,?E:String,?D:String) {
		super(null,null);
		this.d = null;		// private exponent
		this.p = null;		// prime 1
		this.q = null;		// prime 2
		this.dmp1 = null;	// d % (p-1)
		this.dmq1 = null;	// d % (q -1)
		this.coeff = null;
		if(N != null)
			setPrivate(N,E,D);
	}

	/**
		Generate a new random private key B bits long, using public expt E.
		Generating keys over 512 bits in neko, or 256 bit on other platforms
		is just not practical. If you need large keys, generate them with
		openssl and load them into RSA.<br />
		<b>openssl genrsa -des3 -out user.key 1024</b><br />
		<b>openssl genrsa -3 -out user.key 1024</b> no password, 3 as exponent<br />
		will generate a 1024 bit key, which can be displayed with<br />
		<b>openssl rsa -in user.key -noout -text</b>
	*/
	public static function generate(B:Int, E:String) : RSA {
		var rng = new math.prng.Random();
		var key:RSA = new RSA(); // new RSA(null,0,null);
		var qs : Int = B>>1;
		key.e = Std.parseInt("0x" + E);
		//var ee : BigInteger = BigInteger.ofString(E,16);
		var ee : BigInteger = BigInteger.ofInt(key.e);
		while(true) {
			key.p = BigInteger.randomPrime(B-qs, ee, 10, true, rng);
			key.q = BigInteger.randomPrime(qs, ee, 10, true, rng);
			if(key.p.compare(key.q) <= 0) {
				var t = key.p;
				key.p = key.q;
				key.q = t;
			}
			var p1 = key.p.sub(BigInteger.ONE);
			var q1 = key.q.sub(BigInteger.ONE);
			var phi = p1.mul(q1);
			if(phi.gcd(ee).compare(BigInteger.ONE) == 0) {
				key.n = key.p.mul(key.q);
				key.d = ee.modInverse(phi);
				key.dmp1 = key.d.mod(p1);
				key.dmq1 = key.d.mod(q1);
				key.coeff = key.q.modInverse(key.p);
				break;
			}
		}
		return key;
	}

	/**
		Set the private key fields N (modulus), E (public exponent)
		and D (private exponent) from hex strings.
		Throws exception if inputs are invalid.
	**/
	public function setPrivate(N:String,E:String,D:String) : Void {
		super.setPublic(N, E);
		if(D != null && D.length > 0) {
			var s = cleanFormat(D);
			d = BigInteger.ofString(s, 16);
		}
		else
			throw("Invalid RSA private key");
	}

	/**
		Set the private key fields N, E, D and CRT params from
		hex strings. Throws exception if any input is invalid
	**/
	public function setPrivateEx(
			N:String,E:String,D:String,P:String,
			Q:String,DP:String,DQ:String,C:String) : Void
	{
trace(here.methodName);
		setPrivate(N, E, D);
		if(P != null && Q != null && C != null &&
			P.length > 0 && Q.length > 0 && C.length > 0)
		{
trace(here.lineNumber);
			var s : String = cleanFormat(P);
			p = BigInteger.ofString(s, 16);
			s = cleanFormat(Q);
			q = BigInteger.ofString(s,16);
			if(DP == null) {
trace(here.lineNumber);
				var one = BigInteger.ONE;
				var pm1 : BigInteger = p.sub(one);
				dmp1 = d.mod(pm1);
trace(dmp1);
			}
			else {
				s = cleanFormat(DP);
				dmp1 = BigInteger.ofString(s,16);
			}
trace(here.lineNumber);
			if(DQ == null) {
				var pq1 = q.sub(BigInteger.ONE);
				dmq1 = d.mod(pq1);
trace(dmq1);
			}
			else {
				s = cleanFormat(DQ);
				dmq1 = BigInteger.ofString(s,16);
			}
			s = cleanFormat(C);
			coeff = BigInteger.ofString(s,16);
		}
		else
			throw("Invalid RSA private key ex");
	}

	/**
		Return the PKCS#1 RSA decryption of "ctext".
		"ctext" is an even-length hex string and the output
		is a plain string.
	**/
	public function decrypt(ctext : String) : String {
		return doDecrypt(ctext, doPrivate, 0x02);
	}

	override public function decryptBlock( enc : String ) : String {
		var c : BigInteger = BigInteger.ofString(enc, 256);
		var m : BigInteger = doPrivate(c);
		if(m == null) {
			throw "doPrivate error";
			return null;
		}
		// the encrypted block is a BigInteger, so any leading
		// 0's will have been truncated. Push them back in.
		var ba = m.toByteArray();
		while(ba.length < blockSize)
			ba.unshift(0);
		while(ba.length > blockSize) {
			var i = ba.shift();
			if(i != 0)
				throw "decryptBlock length error";
		}
		return ByteString.ofIntArray(ba).toString();
	}

	//////////////////////////////////////////////////
	//               Private                        //
	//////////////////////////////////////////////////
	function doDecrypt(src: String, f : BigInteger->BigInteger, padType : Int)
	{
		var bs = blockSize;
		var pf : IPad;
		if(padType == 0x02)
			pf = new PadPkcs1Type2(bs);
		else
			pf = new PadPkcs1Type1(bs);
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

	/**
		Perform raw private operation on "x": return x^d (mod n)
	**/
	function doPrivate( x:BigInteger ) : BigInteger {
		if(this.p == null || this.q == null) {
			return x.modPow(this.d, this.n);
		}

		/* CRT where p > q
		dP = (1/e) mod (p-1)
		dQ = (1/e) mod (q-1)
		qInv = (1/q) mod p

		m1 = c^dP mod p
		m2 = c^dQ mod q
		h = qInv(m1 - m2) mod p
		m = m2 + hq
		*/
		// TODO: re-calculate any missing CRT params
		var xp = x.mod(this.p).modPow(this.dmp1, this.p);
		var xq = x.mod(this.q).modPow(this.dmq1, this.q);

		while(xp.compare(xq) < 0)
			xp = xp.add(this.p);
		return xp.sub(xq).mul(this.coeff).mod(this.p).mul(this.q).add(xq);
	}
}

