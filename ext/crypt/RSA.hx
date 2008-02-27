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
class RSA extends RSAEncrypt {
	// private key
	public var d : BigInteger;
	public var p : BigInteger;
	public var q : BigInteger;
	public var dmp1 : BigInteger;
	public var dmq1 : BigInteger;
	public var coeff: BigInteger;

	public function new(?N:String,?E:String,?D:String) {
		super(null,null);
		this.d = null; // private exponent
		this.p = null;
		this.q = null;
		this.dmp1 = null;
		this.dmq1 = null;
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
		will generate a 1024 bit key, which can be displayed with<br />
		<b>openssl rsa -in user.key -noout -text</b>
	*/
	public static function generate(B:Int, E:String) : RSA {
		var rng = new math.prng.Random();
		var key:RSA = new RSA(); // new RSA(null,0,null);
		var qs : Int = B>>1;
		key.e = Std.parseInt("0x" + E);
		var ee : BigInteger = BigInteger.ofString(E,16);
		while(true) {
			while(true) {
				key.p = genRandom(B-qs,rng);
				if(key.p.sub(BigInteger.ONE).gcd(ee).compare(BigInteger.ONE) == 0 && key.p.isProbablePrime(10)) break;
			}
			while(true) {
				key.q = genRandom(qs,rng);
				if(key.q.sub(BigInteger.ONE).gcd(ee).compare(BigInteger.ONE) == 0 && key.q.isProbablePrime(10)) break;
			}
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

	static function genRandom(bits:Int, rng:math.prng.Random) : BigInteger {
		var i = BigInteger.ofRandom(bits, rng);
		i.primify(bits, 1);
		return i;
	}

	/**
		Set the private key fields N (modulus), E (public exponent)
		and D (private exponent) from hex strings.
		Throws exception if inputs are invalid.
	**/
	public function setPrivate(N:String,E:String,D:String) : Void {
		super.setPublic(N, E);
		if(D != null && D.length > 0) {
			this.d = parseBigInt(cleanFormat(D),16);
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
		setPrivate(N, E, D);
		if(P != null && Q != null && DP != null && DQ != null && C != null &&
			P.length > 0 && Q.length > 0 && DP.length > 0 && DQ.length > 0 && C.length > 0)
		{
			this.p = parseBigInt(cleanFormat(P),16);
			this.q = parseBigInt(cleanFormat(Q),16);
			this.dmp1 = parseBigInt(cleanFormat(DP),16);
			this.dmq1 = parseBigInt(cleanFormat(DQ),16);
			this.coeff = parseBigInt(cleanFormat(C),16);
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
		var c = parseBigInt(ctext, 16);
		var m = doPrivate(c);
		if(m == null) {
			throw "doPrivate error";
			return null;
		}
		return pkcs1unpad2(m, (n.bitLength()+7)>>3);
	}

	override public function decryptBlock( enc : String ) : String {
		var c = parseBigInt(enc, 256);
		var m = doPrivate(c);
		if(m == null) {
			throw "doPrivate error";
			return null;
		}
		// the encrypted block is a BigInteger, so any leading
		// 0's will have been truncated. Push them back in.
		var ba = m.toByteArray();
		while(ba.length < blockSize)
			ba.unshift(0);
		return ByteString.ofIntArray(ba).toString();
	}

	//////////////////////////////////////////////////
	//               Private                        //
	//////////////////////////////////////////////////
	/**
		Perform raw private operation on "x": return x^d (mod n)
	**/
	function doPrivate( x:BigInteger ) : BigInteger {
trace(this.d);
trace(this.n);
		if(this.p == null || this.q == null)
			return x.modPow(this.d, this.n);

		// TODO: re-calculate any missing CRT params
		var xp = x.mod(this.p).modPow(this.dmp1, this.p);
		var xq = x.mod(this.q).modPow(this.dmq1, this.q);

		while(xp.compare(xq) < 0)
			xp = xp.add(this.p);
		return xp.sub(xq).mul(this.coeff).mod(this.p).mul(this.q).add(xq);
	}

	//////////////////////////////////////////////////
	//               Padding                        //
	//////////////////////////////////////////////////
	/**
		Undo PKCS#1 (type 2, random) padding and, if valid, return the plaintext
	**/
	function pkcs1unpad2(d : BigInteger, n:Int) : String {
		var b : Array<Int> = d.toByteArray();
		var i = 0;
trace(b.length);
		while(i < b.length && b[i] == 0) ++i;
		if(b.length-i != n-1 || b[i] != 2) {
			throw("Length error b.length: "+b.length+" i:"+i+" n:"+n+" b:"+Std.string(b));
			return null;
		}
		++i;
		var sb = new StringBuf();
		while(++i < b.length) {
			try	sb.addChar((b[i])) catch(e:Dynamic) return null;
		}
		return sb.toString();
	}
}



