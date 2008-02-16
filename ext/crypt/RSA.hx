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

/**
	Full RSA encryption class. For encryption only, the base class
	RSAEncrypt can be used instead.
**/
class RSA extends RSAEncrypt {

	public function new() {
		super();
	}

	/**
		Generate a new random private key B bits long, using public expt E
	*/
	public static function generate(B:Int, E:String) : RSA {
		var rng = new SecureRandom();
		var qs : Int = B>>1;
		this.e = parseInt(E,16);
		var ee = new BigInteger(E,16);
		while(true) {
			while(true) {
				this.p = new BigInteger(B-qs,1,rng);
				if(this.p.subtract(BigInteger.ONE).gcd(ee).compareTo(BigInteger.ONE) == 0 && this.p.isProbablePrime(10)) break;
			}
			while(true) {
				this.q = new BigInteger(qs,1,rng);
				if(this.q.subtract(BigInteger.ONE).gcd(ee).compareTo(BigInteger.ONE) == 0 && this.q.isProbablePrime(10)) break;
			}
			if(this.p.compareTo(this.q) <= 0) {
				var t = this.p;
				this.p = this.q;
				this.q = t;
			}
			var p1 = this.p.subtract(BigInteger.ONE);
			var q1 = this.q.subtract(BigInteger.ONE);
			var phi = p1.multiply(q1);
			if(phi.gcd(ee).compareTo(BigInteger.ONE) == 0) {
				this.n = this.p.multiply(this.q);
				this.d = ee.modInverse(phi);
				this.dmp1 = this.d.mod(p1);
				this.dmq1 = this.d.mod(q1);
				this.coeff = this.q.modInverse(this.p);
				break;
			}
		}
	}

	/**
		Set the private key fields N, e, and d from hex strings. Throws exception
		if inputs are invalid.
	**/
	public function setPrivate(N:String,E:String,D:String) : Void {
		if(N != null && E != null && N.length > 0 && E.length > 0) {
			this.n = parseBigInt(N,16);
			this.e = parseInt(E,16);
			this.d = parseBigInt(D,16);
		}
		else
			throw("Invalid RSA private key");
	}

	/**
		Set the private key fields N, e, d and CRT params from hex strings. Throws
		exception if any input is invalid
	**/
	public function setPrivateEx(
			N:String,E:String,D:String,P:String,
			Q:String,DP:String,DQ:String,C:String) : Void
	{
		if(N != null && E != null && N.length > 0 && E.length > 0) {
			this.n = parseBigInt(N,16);
			this.e = parseInt(E,16);
			this.d = parseBigInt(D,16);
			this.p = parseBigInt(P,16);
			this.q = parseBigInt(Q,16);
			this.dmp1 = parseBigInt(DP,16);
			this.dmq1 = parseBigInt(DQ,16);
			this.coeff = parseBigInt(C,16);
		}
		else
			throw("Invalid RSA private key");
	}

	/**
		Return the PKCS#1 RSA decryption of "ctext".
		"ctext" is an even-length hex string and the output is a plain string.
	**/
	public function decrypt(ctext : String) : String {
		var c = parseBigInt(ctext, 16);
		var m = this.doPrivate(c);
		if(m == null)
			return null;
		return pkcs1unpad2(m, (this.n.bitLength()+7)>>3);
	}

	//////////////////////////////////////////////////
	//               Private                        //
	//////////////////////////////////////////////////
	/**
		Perform raw private operation on "x": return x^d (mod n)
	**/
	function doPrivate( x:BigInteger ) : BigInteger {
		if(this.p == null || this.q == null)
			return x.modPow(this.d, this.n);

		// TODO: re-calculate any missing CRT params
		var xp = x.mod(this.p).modPow(this.dmp1, this.p);
		var xq = x.mod(this.q).modPow(this.dmq1, this.q);

		while(xp.compareTo(xq) < 0)
			xp = xp.add(this.p);
		return xp.subtract(xq).multiply(this.coeff).mod(this.p).multiply(this.q).add(xq);
	}

	//////////////////////////////////////////////////
	//               Padding                        //
	//////////////////////////////////////////////////
	/**
		Undo PKCS#1 (type 2, random) padding and, if valid, return the plaintext
		TODO: can rip this out to a PadPkcs1.hx ? see also RSAEncrypt.hx
			- Probably not useful to, since the conversion from
			Array<Int> -> String -> BigInteger wastes time
	**/
	function pkcs1unpad2(d : String, n:Int) : String {
		var b : Array<Int> = ByteStringTools.stringToByteArray(d);
		var i = 0;
		while(i < b.length && b[i] == 0) ++i;
		if(b.length-i != n-1 || b[i] != 2)
			return null;
		++i;
		while(b[i] != 0)
			if(++i >= b.length)
				return null;
		var sb = new StringBuf();
		while(++i < b.length)
			sb.addChar((b[i]));
		return sb.toString();
	}
}



