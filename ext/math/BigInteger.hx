/*
 * Copyright (c) 2008, The Caffeine-hx project contributors
 * Original author : Russell Weir
 * Contributors: Mark Winterhalder
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
package math;

import math.reduction.ModularReduction;
import math.reduction.Barrett;
import math.reduction.Classic;
import math.reduction.Montgomery;
#if neko
private enum HndBI {
}
import neko.Int32;
#end

class BigInteger {

	/** number of chunks **/
	public var t(default,null) : Int;
	/** sign **/
	public var sign(default,null) : Int;
	/** data chunks **/
	public var chunks(default,null) : Array<Int>; // chunks
	public var am : Int->Int->BigInteger->Int->Int->Int->Int; // am function

	public function new(?byInt : Int, ?str : String, ?radix : Int) {
		if(BI_RC == null || BI_RC.length == 0)
			initBiRc();
		if(BI_RM.length == 0)
			throw("BI_RM not initialized");
		am = switch(defaultAm) {
		case 1: am1;
		case 2: am2;
		case 3: am3;
		default: { throw "am error"; null;}
		}
		chunks = new Array<Int>();
		if(byInt != null)	fromInt(byInt);
		else if( str != null && radix == null) fromString(str,256);
	}

	/**
		This is so Montgomery Reduction can pad. Used to be (in Montgomery):<br />
		<code>
		while(x.t <= this.mt2)	// pad x so am has enough room later
			x.chunks[x.t++] = 0;
		</code>
	**/
	public function padTo ( n : Int ) : Void {
		while( t < n )	chunks[ t++ ] = 0;
	}

	/**
		return the number of bits in "this"
	**/
	public function bitLength() {
		if(t <= 0) return 0;
		return DB*(t-1)+nbits(chunks[t-1]^(sign&DM));
	}

	//////////////////////////////////////////////////////////////
	//                 Conversion methods                       //
	//////////////////////////////////////////////////////////////
	/**
		Set from an integer value. If x is less than -DV, the integer will
		be parsed through fromString.
	**/
	public function fromInt(x : Int) {
		t = 0;
		var nb = nbits(x);
		sign = (x<0)?-1:0;
		if(x > 0) {
			if(nb > DB) {
				var v = x;
				chunks[0] = v & DM;
				chunks[1] = v >>> DB;
				t = 2;
			}
			else {
				chunks[0] = x;
				t = 1;
			}
		}
		else if(x < -1) {
			if(nb > DB) {
				var abs = Std.int(Math.abs(x));
				var s = StringTools.hex(abs);
				fromString("-" + s, 16);
				return;
			}
			chunks[0] = x+DV;
			t = 1;
		}
	}

	/**
		Will return the integer value. If the number of bits in the native
		int does not support the bitlength of this BigInteger, unpredictable
		values will occur.
	**/
	public function toInt() : Int {
		if(sign < 0) {
			if(t == 1) return chunks[0]-DV;
			else if(t == 0) return -1;
		}
		else if(t == 1) return chunks[0];
		else if(t == 0) return 0;
		// assumes 16 < DB < 32
		return ((chunks[1]&((1<<(32-DB))-1))<<DB)|chunks[0];
	}

	/**
		Generate a random BigInteger of 'bits' length
	**/
	public function fromRandom(bits:Int, b:math.prng.Random) {
		if(bits < 2) {
			fromInt(1);
			return;
		}
		var x = new ByteString();
		var t : Int = bits&7;
		x.setLength((bits>>3)+1);
		b.nextBytes(x);
		if(t > 0) {
			var v = x.get(0);
			v &= ((1<<t)-1);
			x.set(0, v);
		}
		else x.set(0, 0);
		fromString(x.toString(),256);
	}


	//////////////////////////////////////////////////////////////
	//            String conversion methods                     //
	//////////////////////////////////////////////////////////////
	/**
		Return a base 10 string
	**/
	public function toString() : String {
		return toRadixExt(10);
	}
	/**
		return string representation in given radix.
		This function handles radix values 2,4,8,16 and 32. If the
		given radix is not one of those, toRadixExt is called, so you
		may call toRadixExt directly to save time.
	**/
	public function toRadix(b : Int) : String {
		if(sign < 0) return "-"+neg().toRadix(b);
		var k;
		if(b == 16) k = 4;
		else if(b == 8) k = 3;
		else if(b == 2) k = 1;
		else if(b == 32) k = 5;
		else if(b == 4) k = 2;
		else return toRadixExt(b);
		var km = (1<<k)-1, d, m = false, r = "", i = t;
		var p = DB-(i*DB)%k;
		if(i-- > 0) {
			if(p < DB && (d = chunks[i]>>p) > 0) { m = true; r = int2char(d); }
			while(i >= 0) {
			if(p < k) {
				d = (chunks[i]&((1<<p)-1))<<(k-p);
				d |= chunks[--i]>>(p+=DB-k);
			}
			else {
				d = (chunks[i]>>(p-=k))&km;
				if(p <= 0) { p += DB; --i; }
			}
			if(d > 0) m = true;
			if(m) r += int2char(d);
			}
		}
		return m?r:"0";
	}

	/**
		convert to radix string, handles any base
	**/
	public function toRadixExt(?b : Int) : String {
		if(b == null) b = 10;
		if(b < 2 || b > 36) return "0";
		var cs: Int = Math.floor(0.6931471805599453*DB/Math.log(b));
		var a:Int = Std.int(Math.pow(b,cs));
		var d:BigInteger = nbv(a);
		var y:BigInteger = nbi();
		var z:BigInteger = nbi();
		var r:String = "";
		divRemTo(d,y,z);
		while(y.sigNum() > 0) {
			r = I32.baseEncode31(a + z.toInt(), b).substr(1) + r;
			y.divRemTo(d,y,z);
		}
		return I32.baseEncode31(z.toInt(), b) + r;
	}

	/**
		set from string and radix. Bases != [2,4,8,16,32,256] are
		handled through fromStringExt
	**/
	public function fromString(s : String, b : Int) : Void {
		var k;
		if(b == 16) k = 4;
		else if(b == 8) k = 3;
		else if(b == 256) k = 8; // byte array
		else if(b == 2) k = 1;
		else if(b == 32) k = 5;
		else if(b == 4) k = 2;
		else { fromStringExt(s,b); return; }
		t = 0;
		sign = 0;
		var i = s.length, mi = false, sh = 0;
		while(--i >= 0) {
			var x = (k==8)?s.charCodeAt( i )&0xff:intAt(s,i);
			if(x < 0) {
				if(s.charAt(i) == "-") mi = true;
				continue;
			}
			mi = false;
			if(sh == 0)
				chunks[t++] = x;
			else if(sh+k > DB) {
				chunks[t-1] |= (x&((1<<(DB-sh))-1))<<sh;
				chunks[t++] = (x>>(DB-sh));
			}
			else
				chunks[t-1] |= x<<sh;
			sh += k;
			if(sh >= DB) sh -= DB;
		}
		if(k == 8 && (s.charCodeAt( 0 )&0x80) != 0) {
			sign = -1;
			if(sh > 0) chunks[t-1] |= ((1<<(DB-sh))-1)<<sh;
		}
		clamp();
		if(mi) ZERO.subTo(this,this);
	}

	/**
		convert from radix string
	**/
	function fromStringExt(s : String, ?b : Int) : Void {
		fromInt(0);
		if(b == null) b = 10;
		var cs:Int = Math.floor(0.6931471805599453*DB/Math.log(b));
		var d:Int = Std.int( Math.pow(b,cs) );
		var mi:Bool = false;
		var j:Int = 0;
		var w:Int = 0;
		for(i in 0...s.length) {
			var x = intAt(s,i);
			if(x < 0) {
				if(s.charAt(i) == "-" && sign == 0) mi = true;
				continue;
			}
			w = b*w+x;
			if(++j >= cs) {
				dMultiply( d );
				dAddOffset(w,0);
				j = 0;
				w = 0;
			}
		}
		if(j > 0) {
			dMultiply(Std.int( Math.pow(b,j) ));
			dAddOffset(w,0);
		}
		if(mi) ZERO.subTo(this,this);
	}


	//////////////////////////////////////////////////////////////
	//                    Math methods                          //
	//////////////////////////////////////////////////////////////
	/** Absolute value **/
	public function abs() {
		return (sign<0)?neg():this;
	}

	/** this + a **/
	public function add(a) : BigInteger
	{ var r = nbi(); addTo(a,r); return r; }

	/**
		<pre>return + if this > a, - if this < a, 0 if equal</pre>
	**/
	public function compareTo(a : BigInteger) : Int {
		var r = sign-a.sign;
		if(r != 0) return r;
		var i:Int = t;
		r = i-a.t;
		if(r != 0) return r;
		while(--i >= 0) {
			r=chunks[i]-a.chunks[i];
			if(r != 0) return r;
		}
		return 0;
	}

	/** this / a **/
	public function div(a) : BigInteger
	{ var r = nbi(); divRemTo(a,r,null); return r; }

	/** <pre>[this/a,this%a]</pre> **/
	public function divideAndRemainder(a) : Array<BigInteger> {
		var q = nbi();
		var r = nbi();
		divRemTo(a,q,r);
		return [q,r];
	}

	/** this == a **/
	public function eq(a) : Bool {
		return compareTo(a) == 0;
	}

	/**	Return the biggest of this and a **/
	public function max(a:BigInteger) : BigInteger {
		return (compareTo(a)>0)?this:a;
	}

	/**	Return the smallest of this and a **/
	public function min(a:BigInteger) : BigInteger {
		return (compareTo(a)<0)?this:a;
	}

	/** Modulus division bn % bn **/
	public function mod(a) : BigInteger {
		var r = nbi();
		abs().divRemTo(a,null,r);
		if(sign < 0 && r.compareTo(ZERO) > 0) a.subTo(r,r);
		return r;
	}

	/** <pre>this % n, n < 2^26</pre> **/
	public function modInt(n : Int) : Int {
		if(n <= 0) return 0;
		var d:Int = DV%n;
		var r:Int = (sign<0)?n-1:0;
		if(t > 0)
			if(d == 0) r = chunks[0]%n;
			else {
				var i = t-1;
				while( i >= 0) {
					r = (d*r+chunks[i])%n;
					--i;
				}
			}
		return r;
	}

	/** <pre>this^e % m (HAC 14.85)</pre> **/
	public function modPow(e : BigInteger, m:BigInteger) : BigInteger {
		var i:Int = e.bitLength();
		var k : Int;
		var r : BigInteger = nbv(1);
		var z : ModularReduction;
		if(i <= 0) return r;
		else if(i < 18) k = 1;
		else if(i < 48) k = 3;
		else if(i < 144) k = 4;
		else if(i < 768) k = 5;
		else k = 6;
		if(i < 8)
			z = new Classic(m);
		else if(m.isEven())
			z = new Barrett(m);
		else
			z = new Montgomery(m);

		// precomputation
		var g : Array<BigInteger> = new Array();
		var n : Int = 3;
		var k1 : Int = k-1;
		var km : Int = (1<<k)-1;
		g[1] = z.convert(this);
		if(k > 1) {
			var g2 : BigInteger = nbi();
			z.sqrTo(g[1],g2);
			while(n <= km) {
				g[n] = nbi();
				z.mulTo(g2,g[n-2],g[n]);
				n += 2;
			}
		}

		var j : Int = e.t-1;
		var w : Int;
		var is1 : Bool = true;
		var r2 : BigInteger = nbi();
		var t : BigInteger;
		i = nbits(e.chunks[j])-1;
		while(j >= 0) {
			if(i >= k1) w = (e.chunks[j]>>(i-k1))&km;
			else {
				w = (e.chunks[j]&((1<<(i+1))-1))<<(k1-i);
				if(j > 0) w |= e.chunks[j-1]>>(DB+i-k1);
			}

			n = k;
			while((w&1) == 0) { w >>= 1; --n; }
			if((i -= n) < 0) { i += DB; --j; }
			if(is1) {	// ret == 1, don't bother squaring or multiplying it
				g[w].copyTo(r);
				is1 = false;
			}
			else {
				while(n > 1) { z.sqrTo(r,r2); z.sqrTo(r2,r); n -= 2; }
				if(n > 0) z.sqrTo(r,r2);
				else { t = r; r = r2; r2 = t; }
				z.mulTo(r2,g[w],r);
			}

			while(j >= 0 && (e.chunks[j]&(1<<i)) == 0) {
				z.sqrTo(r,r2); t = r; r = r2; r2 = t;
				if(--i < 0) { i = DB-1; --j; }
			}
		}
		return z.revert(r);
	}

	/**
		<pre>this^e % m, 0 <= e < 2^32</pre>
	**/
	public function modPowInt(e : Int, m : BigInteger) : BigInteger {
		var z : ModularReduction;
		if(e < 256 || m.isEven()) z = new Classic(m);
		else z = new Montgomery(m);
		return exp(e,z);
	}

	/** this * a **/
	public function mul(a) : BigInteger
	{ var r = nbi(); multiplyTo(a,r); return r; }

	/**
		-this
	**/
	public function neg() {
		var r = nbi();
		ZERO.subTo(this,r);
		return r;
	}

	/** this^e **/
	public function pow(e : Int) : BigInteger {
		return exp(e,new math.reduction.Null());
	}

	/** this % a **/
	public function remainder(a) : BigInteger
	{ var r = nbi(); divRemTo(a,null,r); return r; }

	/** this - a **/
	public function sub(a:BigInteger) : BigInteger
	{ var r = nbi(); subTo(a,r); return r; }


	//////////////////////////////////////////////////////////////
	//                  Bitwise Operators                       //
	//////////////////////////////////////////////////////////////
	/** this &amp; a **/
	public function and(a) { var r = nbi(); bitwiseTo(a,op_and,r); return r; }

	/** this &amp; ~a **/
	public function andNot(a) { var r = nbi(); bitwiseTo(a,op_andnot,r); return r; }

	/** alias for not() **/
	public function complement() : BigInteger { return not(); }

	/** ~this **/
	public function not() : BigInteger {
		var r = nbi();
#if !neko
		for(i in 0...t) r.chunks[i] = DM&~chunks[i];
		r.t = t;
		r.sign = ~sign;
#else true
		for(i in 0...t) {
			r.chunks[i] =
				Int32.toInt(
				Int32.and(
					Int32.ofInt(DM),
					Int32.complement(Int32.ofInt(chunks[i]))
				));
		}
		r.t = t;
		r.sign = Int32.toInt(Int32.complement(Int32.ofInt(sign)));
#end
		return r;
	}

	/** this | a **/
	public function or(a) { var r = nbi(); bitwiseTo(a,op_or,r); return r; }

	/**
		<pre>this << n</pre>
	**/
	public function shl(n : Int) : BigInteger {
		var r = nbi();
		if(n < 0) rShiftTo(-n,r); else lShiftTo(n,r);
		return r;
	}

	/**
		<pre>this >> n</pre>
	**/
	public function shr(n : Int) : BigInteger {
		var r = nbi();
		if(n < 0) lShiftTo(-n,r); else rShiftTo(n,r);
		return r;
	}

	/** this ^ a **/
	public function xor(a) { var r = nbi(); bitwiseTo(a,op_xor,r); return r; }


	//////////////////////////////////////////////////////////////
	//             'Result To' Math methods                     //
	// These methods take 'this', perform math function with    //
	// 'a', and store the result in 'r'                         //
	//////////////////////////////////////////////////////////////
	/** r = this + a **/
	public function addTo(a:BigInteger,r:BigInteger) : Void {
		var i:Int = 0;
		var c:Int = 0;
		var m:Int = Std.int(Math.min(a.t,t));
		while(i < m) {
			c += chunks[i]+a.chunks[i];
			r.chunks[i++] = c&DM;
			c >>= DB;
		}
		if(a.t < t) {
			c += a.sign;
			while(i < t) {
				c += chunks[i];
				r.chunks[i++] = c&DM;
				c >>= DB;
			}
			c += sign;
		}
		else {
			c += sign;
			while(i < a.t) {
				c += a.chunks[i];
				r.chunks[i++] = c&DM;
				c >>= DB;
			}
			c += a.sign;
		}
		r.sign = (c<0)?-1:0;
		if(c > 0) r.chunks[i++] = c;
		else if(c < -1) r.chunks[i++] = DV+c;
		r.t = i;
		r.clamp();
	}

	/** copy this to r **/
	public function copyTo(r : BigInteger) {
		r.chunks = chunks.copy();
		r.t = t;
		r.sign = sign;
	}
	/**
		divide this by m, quotient and remainder to q, r (HAC 14.20)
		<pre>r != q, this != m.  q or r may be null.</pre>
	**/
	public function divRemTo(m : BigInteger, q : BigInteger ,?r : BigInteger) {
		var pm : BigInteger = m.abs();
		if(pm.t <= 0) return;
		var pt : BigInteger = abs();
		if(pt.t < pm.t) {
			trace(true);
			if(q != null) q.fromInt(0);
			if(r != null) copyTo(r);
			return;
		}
		if(r == null) r = nbi();
		var y:BigInteger = nbi();
		var ts:Int = sign;
		var ms:Int = m.sign;

		var nsh: Int = DB-nbits(pm.chunks[pm.t-1]);	// normalize modulus

		if(nsh > 0) {
			pt.lShiftTo(nsh,r);
			pm.lShiftTo(nsh,y);
		}
		else {
			pt.copyTo(r);
			pm.copyTo(y);
		}
		var ys: Int = y.t;
		var y0: Int = y.chunks[ys-1];
		if(y0 == 0) return;
		// TODO: neko nastiness in Int to Float casting
		//var yt:Float = y0*(1<<F1)+((ys>1)?y.chunks[ys-2]>>F2:0);
		var yt : Float = Std.parseFloat(Std.string(y0));
		{
			//var h : Float = Std.parseFloat(Std.string(1<<F1));
			var h : Float = (1<<F1);
			var u : Float = 0.0;
			if(ys > 1)
				u = Std.parseFloat(Std.string(y.chunks[ys-2]>>F2));
			yt = yt * h + u;
		}
		var d1:Float = FV/yt;
		var d2:Float = (1<<F1)/yt;
		var e:Float = (1<<F2);
		var i:Int = r.t;
		var j:Int = i-ys;
		var t:BigInteger = (q==null)?nbi():q;
		/** <pre> t = this << n*DB </pre> **/
		y.dlShiftTo(j,t);
		if(r.compareTo(t) >= 0) {
			trace(true);
			r.chunks[r.t++] = 1;
			r.subTo(t,r);
		}
		ONE.dlShiftTo(ys,t);
		t.subTo(y,y);	// "negative" y so we can replace sub with am later
		while(y.t < ys) y.chunks[y.t++] = 0;
		while(--j >= 0) {
			// Estimate quotient digit
			//var qd:Int = (r.chunks[--i]==y0)?DM:Math.floor(r.chunks[i]*d1+(r.chunks[i-1]+e)*d2);
			var qd : Int;
			if(r.chunks[--i]==y0) {
				qd = DM;
			}
			else {
				var o : Float = r.chunks[i];
				var p : Float = r.chunks[i-1]+e;
				qd = Math.floor(o * d1 + p *d2);
			}

			//if((r.chunks[i]+=y.am(0,qd,r,j,0,ys)) < qd) {
			var amv =  y.am(0,qd,r,j,0,ys);
			r.chunks[i] += amv;
			if(r.chunks[i] < qd) {	// Try it out
				y.dlShiftTo(j,t);
				r.subTo(t,r);
				while(r.chunks[i] < --qd) { r.subTo(t,r); }
			}
		}
		if(q != null) {
			r.drShiftTo(ys,q);
			if(ts != ms) ZERO.subTo(q,q);
		}
		r.t = ys;
		r.clamp();
		if(nsh > 0) r.rShiftTo(nsh,r);	// Denormalize remainder
		if(ts < 0) ZERO.subTo(r,r);
	}

	/**
		(protected) r = lower n words of "this * a", <pre>a.t <= n</pre>
		"this" should be the larger one if appropriate.
	**/
	public function multiplyLowerTo(a:BigInteger,n : Int,r:BigInteger) : Void {
		var i : Int = Std.int(Math.min(t+a.t,n));
		r.sign = 0; // assumes a,this >= 0
		r.t = i;
		while(i > 0) r.chunks[--i] = 0;
		var j : Int = r.t - t;
		//for (j=r.t-t;i<j;++i) {
		while(i < j) {
			r.chunks[i+t] = am(0,a.chunks[i],r,i,0,t);
			++i;
		}
		//for (j=Math.min(a.t,n);i<j;++i) {
		j = Std.int(Math.min(a.t,n));
		while(i < j) {
			am(0,a.chunks[i],r,i,0,n-i);
			++i;
		}
		r.clamp();
	}

	/**
		<pre>r = this * a, r != this,a (HAC 14.12)</pre>
		"this" should be the larger one if appropriate.
	**/
	public function multiplyTo(a : BigInteger, r : BigInteger) {
		var x = abs(), y = a.abs();
		var i:Int = x.t;
		r.t = i+y.t;
		while(--i >= 0) r.chunks[i] = 0;
//		for(i = 0; i < y.t; ++i) r.chunks[i+x.t] = x.am(0,y[i],r,i,0,x.t);
		for( i in 0...y.t ) r.chunks[i+x.t] = x.am(0,y.chunks[i],r,i,0,x.t);
		r.sign = 0;
		r.clamp();
		if(sign != a.sign) ZERO.subTo(r,r);
	}

	/**
		(protected) r = "this * a" without lower n words, <pre>n > 0</pre>
		"this" should be the larger one if appropriate.
	**/
	public function multiplyUpperTo(a:BigInteger,n:Int,r:BigInteger) : Void {
		--n;
		var i : Int = r.t = t+a.t-n;
		r.sign = 0; // assumes a,this >= 0
		while(--i >= 0)
			r.chunks[i] = 0;
		i = Std.int(Math.max(n-t,0));
		for(x in i...a.t)
			r.chunks[t+x-n] = am(n-x,a.chunks[x],r,0,0,t+x-n);
		r.clamp();
		r.drShiftTo(1,r);
	}

	/** <pre>r = this^2, r != this (HAC 14.16)</pre> **/
	// TODO: able to square where r==this
	public function squareTo(r : BigInteger) {
		var x = abs();
		var i:Int = r.t = 2*x.t;
		while(--i >= 0) r.chunks[i] = 0;
		i = 0;
		while(i < x.t - 1) {
			var c:Int = x.am(i,x.chunks[i],r,2*i,0,1);
			if((r.chunks[i+x.t]+=x.am(i+1,2*x.chunks[i],r,2*i+1,c,x.t-i-1)) >= DV) {
				r.chunks[i+x.t] -= DV;
				r.chunks[i+x.t+1] = 1;
			}
			i++;
		}
		if(r.t > 0) {
			var rv = x.am(i,x.chunks[i],r,2*i,0,1);
			r.chunks[r.t-1] += rv;
		}
		r.sign = 0;
		r.clamp();
	}

	/** <pre>r = this - a</pre> **/
	public function subTo(a : BigInteger, r : BigInteger) : Void {
#if !neko
		var i: Int = 0;
		var c: Int = 0;
		var m: Int = Std.int(Math.min(a.t,t));
		while(i < m) {
			c += chunks[i]-a.chunks[i];
			r.chunks[i++] = c&DM;
			c >>= DB;
		}
		if(a.t < t) {
			c -= a.sign;
			while(i < t) {
				c += chunks[i];
				r.chunks[i++] = c&DM;
				c >>= DB;
			}
			c += sign;
		}
		else {
			c += sign;
			while(i < a.t) {
				c -= a.chunks[i];
				r.chunks[i++] = c&DM;
				c >>= DB;
			}
			c -= a.sign;
		}
		r.sign = (c<0)?-1:0;
		if(c < -1) r.chunks[i++] = DV+c;
		else if(c > 0) r.chunks[i++] = c;
		r.t = i;
#else true
		var biA : Dynamic = mkBigInt(this);
		var biB : HndBI = mkBigInt(a);
		var res : HndBI = bi_sub_to(biA,biB);
		popFromHandle(res, r);
#end
		r.clamp();
	}

	//////////////////////////////////////////////////////////////
	//             'Result To' Bitwise methods                  //
	// These methods take 'this', perform bitwise function with //
	// 'a', and store the result in 'r'                         //
	//////////////////////////////////////////////////////////////
	/** <pre>r = this << n </pre> **/
	public function lShiftTo(n : Int, r : BigInteger) {
		var bs: Int = n%DB;
		var cbs:Int = DB-bs;
		var bm:Int = (1<<cbs)-1;
		var ds:Int = Math.floor(n/DB), c:Int = (sign<<bs)&DM, i : Int;
//		for(i = t-1; i >= 0; --i) {
		var i = t-1;
		while( i >= 0 ) {
			r.chunks[i+ds+1] = (chunks[i]>>cbs)|c;
			c = (chunks[i]&bm)<<bs;
			i--;
		}
//		for(i = ds-1; i >= 0; --i) r.chunks[i] = 0;
		i = ds - 1;
		while( i >= 0 ) { r.chunks[i] = 0; i--; }
		r.chunks[ds] = c;
		r.t = t+ds+1;
		r.sign = sign;
		r.clamp();
	}

	/** <pre>r = this >> n</pre> **/
	public function rShiftTo(n : Int, r : BigInteger) {
		r.sign = sign;
		var ds:Int = Math.floor(n/DB);
		if(ds >= t) { r.t = 0; return; }
		var bs:Int = n%DB;
		var cbs:Int = DB-bs;
		var bm:Int = (1<<bs)-1;
		r.chunks[0] = chunks[ds]>>bs;
//		for(var i = ds+1; i < t; ++i) {
		for( i in (ds + 1)...t ) {
			r.chunks[i-ds-1] |= (chunks[i]&bm)<<cbs;
			r.chunks[i-ds] = chunks[i]>>bs;
		}
		if(bs > 0) r.chunks[t-ds-1] |= (sign&bm)<<cbs;
		r.t = t-ds;
		r.clamp();
	}

	//////////////////////////////////////////////////////////////
	//                    Misc methods                          //
	//////////////////////////////////////////////////////////////
	/** clamp off excess high words **/
	public function clamp() {
		var c = sign&DM;
		while(t > 0 && chunks[t-1] == c) --t;
	}

	/** Clone a BigInteger **/
	public function clone() {
		var r = nbi();
		copyTo(r);
		return r;
	}

	// (public) gcd(this,a) (HAC 14.54)
	public function gcd(a:BigInteger) : BigInteger {
		var x = (sign<0)?neg():clone();
		var y = (a.sign<0)?a.neg():a.clone();
		if(x.compareTo(y) < 0) { var t:BigInteger = x; x = y; y = t; }
		var i:Int = x.getLowestSetBit(), g:Int = y.getLowestSetBit();
		if(g < 0) return x;
		if(i < g) g = i;
		if(g > 0) {
			x.rShiftTo(g,x);
			y.rShiftTo(g,y);
		}
		while(x.sigNum() > 0) {
			if((i = x.getLowestSetBit()) > 0) x.rShiftTo(i,x);
			if((i = y.getLowestSetBit()) > 0) y.rShiftTo(i,y);
			if(x.compareTo(y) >= 0) {
				x.subTo(y,x);
				x.rShiftTo(1,x);
			}
			else {
				y.subTo(x,y);
				y.rShiftTo(1,y);
			}
		}
		if(g > 0) y.lShiftTo(g,y);
		return y;
	}

	/** true if this is even **/
	public function isEven() {
		return ((t>0)?(chunks[0]&1):sign) == 0;
	}

	/** return value as short (assumes DB &gt;= 16) **/
	public function shortValue() {
		return (t==0)?sign:(chunks[0]<<16)>>16;
	}

	/** <pre>0 if this == 0, 1 if this > 0</pre>**/
	public function sigNum() {
		if(sign < 0) return -1;
		else if(t <= 0 || (t == 1 && chunks[0] <= 0)) return 0;
		else return 1;
	}

	/**
		convert to bigendian byte array
	**/
	public function toByteArray() : Array<Int> {
		var i:Int = t;
		var r = new Array();
		r[0] = sign;
		var p:Int = DB-(i*DB)%8;
		var d:Int;
		var k:Int = 0;
		if(i-- > 0) {
			if(p < DB && (d = chunks[i]>>p) != (sign&DM)>>p)
			r[k++] = d|(sign<<(DB-p));
			while(i >= 0) {
				if(p < 8) {
					d = (chunks[i]&((1<<p)-1))<<(8-p);
					d |= chunks[--i]>>(p+=DB-8);
				}
				else {
					d = (chunks[i]>>(p-=8))&0xff;
					if(p <= 0) { p += DB; --i; }
				}
				if((d&0x80) != 0) d |= -256;
				if(k == 0 && (sign&0x80) != (d&0x80)) ++k;
				if(k > 0 || d != sign) r[k++] = d;
			}
		}
		return r;
	}


	//////////////////////////////////////////////////////////////
	//        Reduction public methods (move to private)        //
	//////////////////////////////////////////////////////////////
	/**
		<pre>this += n << w words, this >= 0</pre>
	**/
	public function dAddOffset(n : Int, w : Int) :Void {
	  while(t <= w) chunks[t++] = 0;
	  chunks[w] += n;
	  while(chunks[w] >= DV) {
	    chunks[w] -= DV;
	    if(++w >= t) chunks[t++] = 0;
	    ++chunks[w];
	  }
	}

	/** <pre> r = this << n*DB </pre> **/
	public function dlShiftTo(n : Int, r : BigInteger) {
		var i = t-1;
		while(i >= 0) {
			r.chunks[i+n] = chunks[i];
			i--;
		}
		i = n-1;
		while(i >= 0) {
			r.chunks[i] = 0;
			i--;
		}
		r.t = t+n;
		r.sign = sign;
	}

	/** <pre>r = this >> n*DB</pre> **/
	public function drShiftTo(n : Int, r : BigInteger) {
		var i:Int = n;
		while(i < t) {
			r.chunks[i-n] = chunks[i];
			i++;
		}
		r.t = Std.int( Math.max(t-n,0) );
		r.sign = sign;
	}

	/**
		<pre>return "-1/this % 2^DB"; useful for Mont. reduction</pre>
	**/
	// justification:
	//         xy == 1 (mod m)
	//         xy =  1+km
	//   xy(2-xy) = (1+km)(1-km)
	// x[y(2-xy)] = 1-k^2m^2
	// x[y(2-xy)] == 1 (mod m^2)
	// if y is 1/x mod m, then y(2-xy) is 1/x mod m^2
	// should reduce x and y(2-xy) by m^2 at each step to keep size bounded.
	// JS multiply "overflows" differently from C/C++, so care is needed here.
	public function invDigit() {
		if(t < 1) return 0;
		var x:Int = chunks[0];
		if((x&1) == 0) return 0;
		var y:Int = x&3;		// y == 1/x mod 2^2
		y = (y*(2-(x&0xf)*y))&0xf;	// y == 1/x mod 2^4
		y = (y*(2-(x&0xff)*y))&0xff;	// y == 1/x mod 2^8
		y = (y*(2-(((x&0xffff)*y)&0xffff)))&0xffff;	// y == 1/x mod 2^16
		// last step - calculate inverse mod DV directly;
		// assumes 16 < DB <= 32 and assumes ability to handle 48-bit ints
		y = (y*(2-x*y%DV))%DV;		// y == 1/x mod 2^dbits
		// we really want the negative inverse, and -DV < y < DV
		return (y>0)?DV-y:-y;
	}

	/** <pre>test primality with certainty >= 1-.5^t</pre> **/
	public function isProbablePrime(t : Int) : Bool {
		var i:Int;
		var x = abs();
		if(x.t == 1 && x.chunks[0] <= lowprimes[lowprimes.length-1]) {
			for(i in 0...lowprimes.length)
				if(x.chunks[0] == lowprimes[i]) return true;
			return false;
		}
		if(x.isEven()) return false;
		i = 1;
		while(i < lowprimes.length) {
			var m:Int = lowprimes[i];
			var j:Int = i+1;
			while(j < lowprimes.length && m < lplim) m *= lowprimes[j++];
			m = x.modInt(m);
			while(i < j) if(m%lowprimes[i++] == 0) return false;
		}
		return x.millerRabin(t);
	}

	//////////////////////////////////////////////////////////////
	//					Private methods							//
	//////////////////////////////////////////////////////////////


/*
	// (protected) alternate constructor
	function fromNumber(a,b,c) {
		if("number" == typeof b) {
			// new BigInteger(int,int,RNG)
			if(a < 2) fromInt(1);
			else {
				fromNumber(a,c);
				if(!testBit(a-1))	// force MSB set
					bitwiseTo(ONE.shl(a-1),op_or,this);
				if(isEven()) dAddOffset(1,0); // force odd
				while(!isProbablePrime(b)) {
					dAddOffset(2,0);
					if(bitLength() > a) 	subTo(ONE.shl(a-1),this);
				}
			}
		}

	}
*/

	/** return number of set bits **/
	function bitCount() : Int {
		var r = 0, x = sign&DM;
		for(i in 0...t) r += cbit(chunks[i]^x);
		return r;
	}

	// (protected) r = this op a (bitwise)
	function bitwiseTo(a : BigInteger, op:Int->Int->Int, r:BigInteger) {
		var f : Int;
		var m : Int = Std.int(Math.min(a.t,t));
		for(i in 0...m) r.chunks[i] = op(chunks[i],a.chunks[i]);
		if(a.t < t) {
			f = a.sign & DM;
			for(i in m...t) r.chunks[i] = op(chunks[i],f);
			r.t = t;
		}
		else {
			f = sign&DM;
			for(i in m...a.t) r.chunks[i] = op(f,a.chunks[i]);
			r.t = a.t;
		}
		r.sign = op(sign,a.sign);
		r.clamp();
	}

	/** return value as byte **/
	function byteValue() { return (t==0)?sign:(chunks[0]<<24)>>24; }

	/** this op (1<<n) 	**/
	function changeBit(n,op) {
		var r = ONE.shl(n);
		bitwiseTo(r,op,r);
		return r;
	}

	/** <pre>return x s.t. r^x < DV</pre> **/
	function chunkSize(r) {
		return Math.floor(0.6931471805599453*DB/Math.log(r));
	}

	/** <pre>this & ~(1<<n)</pre> **/
	function clearBit(n) { return changeBit(n,op_andnot); }


	/**
		(protected) <pre>this *= n, this >= 0, 1 < n < DV</pre>
	**/
	function dMultiply ( n : Int ) {
		chunks[ t ] = am(0,n-1,this,0,0,t);
		t++;
		clamp();
	}

	/** <pre>this^e, e < 2^32, doing sqr and mul with "r" (HAC 14.79)</pre> **/
	function exp(e : Int, z : ModularReduction) : BigInteger {
#if !neko
		if(e > 0xffffffff || e < 1) return ONE;
#else true
		if(e < 1) return ONE;
#end
		var r = nbi(), r2 = nbi();
		var g = z.convert(this);
		var i:Int = nbits(e)-1;
		g.copyTo(r);
		while(--i >= 0) {
			z.sqrTo(r,r2);
			if((e&(1<<i)) > 0) z.mulTo(r2,g,r);
			else { var t = r; r = r2; r2 = t; }
		}
		return z.revert(r);
	}

	/** <pre>this ^ (1<<n)</pre> **/
	function flipBit(n) { return changeBit(n,op_xor); }

	/** returns index of lowest 1-bit (or -1 if none) **/
	function getLowestSetBit() : Int {
		for(i in 0...t)
			if(chunks[i] != 0) return i*DB+lbit(chunks[i]);
		if(sign < 0) return t*DB;
		return -1;
	}

	/** <pre>this | (1<<n)</pre> **/
	function setBit(n) { return changeBit(n,op_or); }

	/** <pre>true iff nth bit is set</pre> **/
	function testBit(n:Int) : Bool {
		var j = Math.floor(n/DB);
		if(j >= t) return(sign!=0);
		return((chunks[j]&(1<<(n%DB)))!=0);
	}

/*
// (public) 1/this % m (HAC 14.61)
public function modInverse(m) {
  var ac = m.isEven();
  if((isEven() && ac) || m.signignum() == 0) return ZERO;
  var u = m.clone(), v = clone();
  var a = nbv(1), b = nbv(0), c = nbv(0), d = nbv(1);
  while(u.sigNum() != 0) {
    while(u.isEven()) {
      u.rShiftTo(1,u);
      if(ac) {
        if(!a.isEven() || !b.isEven()) { a.addTo(this,a); b.subTo(m,b); }
        a.rShiftTo(1,a);
      }
      else if(!b.isEven()) b.subTo(m,b);
      b.rShiftTo(1,b);
    }
    while(v.isEven()) {
      v.rShiftTo(1,v);
      if(ac) {
        if(!c.isEven() || !d.isEven()) { c.addTo(this,c); d.subTo(m,d); }
        c.rShiftTo(1,c);
      }
      else if(!d.isEven()) d.subTo(m,d);
      d.rShiftTo(1,d);
    }
    if(u.compareTo(v) >= 0) {
      u.subTo(v,u);
      if(ac) a.subTo(c,a);
      b.subTo(d,b);
    }
    else {
      v.subTo(u,v);
      if(ac) c.subTo(a,c);
      d.subTo(b,d);
    }
  }
  if(v.compareTo(ONE) != 0) return ZERO;
  if(d.compareTo(m) >= 0) return d.subtract(m);
  if(d.sigNum() < 0) d.addTo(m,d); else return d;
  if(d.sigNum() < 0) return d.add(m); else return d;
}
*/

	/** (protected) true if probably prime (HAC 4.24, Miller-Rabin) **/
	function millerRabin(t:Int) : Bool {
		var n1:BigInteger = sub(ONE);
		var k:Int = n1.getLowestSetBit();
		if(k <= 0) return false;
		var r:BigInteger = n1.shr(k);
		t = (t+1)>>1;
		if(t > lowprimes.length) t = lowprimes.length;
		var a = nbi();
		for(i in 0...t) {
			a.fromInt(lowprimes[i]);
			var y:BigInteger = a.modPow(r,this);
			if(y.compareTo(ONE) != 0 && y.compareTo(n1) != 0) {
				var j:Int = 1;
				while(j++ < k && y.compareTo(n1) != 0) {
					y = y.modPowInt(2,this);
					if(y.compareTo(ONE) == 0) return false;
				}
				if(y.compareTo(n1) != 0) return false;
			}
		}
		return true;
	}

	// am1: use a single mult and divide to get the high bits,
	// max digit bits should be 26 because
	// max internal value = 2*dvalue^2-2*dvalue (< 2^53)
	function am1(i:Int,x:Int,w:BigInteger,j:Int,c:Int,n:Int) : Int {
		while(--n >= 0) {
			var v : Int = x*chunks[i++]+w.chunks[j]+c;
			c = Math.floor(v/0x4000000);
			w.chunks[j++] = v&0x3ffffff;
		}
		return c;
	}

	// am: Compute w_j += (x*this_i), propagate carries,
	// c is initial carry, returns final carry.
	// c < 3*dvalue, x < 2*dvalue, this_i < dvalue
	//
	// am2 avoids a big mult-and-extract completely.
	// Max digit bits should be <= 30 because we do bitwise ops
	// on values up to 2*hdvalue^2-hdvalue-1 (< 2^31)
	function am2(i:Int,x:Int,w:BigInteger,j:Int,c:Int,n:Int) : Int {
		var xl:Int = x&0x7fff;
		var xh:Int = x>>15;
		while(--n >= 0) {
			var l : Int = chunks[i]&0x7fff;
			var h : Int = chunks[i++]>>15;
			var m : Int = xh*l + h*xl;
			l = xl*l + ((m&0x7fff)<<15)+w.chunks[j]+(c&0x3fffffff);
			c = (l>>>30)+(m>>>15)+xh*h+(c>>>30);
			w.chunks[j++] = l&0x3fffffff;
		}
		return c;
	}

	// Alternately, set max digit bits to 28 since some
	// browsers slow down when dealing with 32-bit numbers.
	function am3(i:Int,x:Int,w:BigInteger,j:Int,c:Int,n:Int) : Int {
		var xl = x&0x3fff, xh = x>>14;
		while(--n >= 0) {
			var l = chunks[i]&0x3fff;
			var h = chunks[i++]>>14;
			var m = xh*l+h*xl;
			l = xl*l+((m&0x3fff)<<14)+w.chunks[j]+c;
			c = (l>>28)+(m>>14)+xh*h;
			w.chunks[j++] = l&0xfffffff;
		}
		return c;
	}


	//////////////////////////////////////////////////////////////
	//                  Static variables                        //
	//////////////////////////////////////////////////////////////

	public static var MAX_RADIX : Int = 36;
	public static var MIN_RADIX : Int = 2;

	//dbits (DB) TODO: assumed to be 16 < DB < 32
	public static var DB : Int; // bits per chunk.
	public static var DM : Int; // bit mask
	public static var DV : Int; // max value in bitsize

	public static var BI_FP : Int;
	public static var FV : Float;
	public static var F1 : Int;
	public static var F2 : Int;

	public static var ZERO(getZERO,null)	: BigInteger;
	public static var ONE(getONE, null)		: BigInteger;

	// Digit conversions
	static var BI_RM : String;
	static var BI_RC : Array<Int>;

	public static var lowprimes : Array<Int>;
	static var lplim : Int;
	static var defaultAm : Int; // am function

	//////////////////////////////////////////////////////////////
	//                   Static methods                         //
	//////////////////////////////////////////////////////////////

	static function __init__() {
		// Bits per digit
		var dbits; //This is th DB static
#if neko
		dbits = 28;
		defaultAm = 3;
#else js
		// JavaScript engine analysis
		var j_lm : Bool;
		untyped {
			var canary : Int = 0xdeadbeefcafe;
			j_lm = ((canary&0xffffff)==0xefcafe);
		}

		var browser: String = untyped window.navigator.appName;
		if(j_lm && (browser == "Microsoft Internet Explorer")) {
			defaultAm = 2;
			dbits = 30;
		}
		else if(j_lm && (browser != "Netscape")) {
			defaultAm = 1;
			dbits = 26;
		}
		else { // Mozilla/Netscape seems to prefer
			defaultAm = 3;
			dbits = 28;
		}
#else flash
		dbits = 28;
		defaultAm =3;
#else true
		dbits = 30;
		defaultAm = 2;
#end
		DB = dbits;
		DM = ((1<<DB)-1);
		DV = (1<<DB);
		BI_FP = 52;
		FV = Math.pow(2,BI_FP);
		F1 = BI_FP-DB;
		F2 = 2*DB-BI_FP;
		// TODO: for some reason on flash8, BI_RC was not initializing here
		// properly, so it is double checked in the constructor.
		initBiRc();
		BI_RM = "0123456789abcdefghijklmnopqrstuvwxyz";


		lowprimes = [2,3,5,7,11,13,17,19,23,29,31,37,41,43,47,53,59,61,67,71,73,79,83,89,97,101,103,107,109,113,127,131,137,139,149,151,157,163,167,173,179,181,191,193,197,199,211,223,227,229,233,239,241,251,257,263,269,271,277,281,283,293,307,311,313,317,331,337,347,349,353,359,367,373,379,383,389,397,401,409,419,421,431,433,439,443,449,457,461,463,467,479,487,491,499,503,509];
		lplim = Std.int((1<<26)/lowprimes[lowprimes.length-1]);

	}

	static function initBiRc() : Void {
		BI_RC = new Array<Int>();
		var rr : Int = Std.ord("0"); //.charCodeAt(0);
		for(vv in 0...10)
			BI_RC[rr++] = vv;
		rr = Std.ord("a");//.charCodeAt(0);
		for(vv in 10...37)
			BI_RC[rr++] = vv;
		rr = Std.ord("A");//.charCodeAt(0);
		for(vv in 10...37)
			BI_RC[rr++] = vv;
	}

	/**
		Getter function for static var ZERO
	**/
	static function getZERO() : BigInteger {
		return nbv(0);
	}

	/**
		Getter funtion for static var ONE
	**/
	static function getONE() : BigInteger {
		return nbv(1);
	}

	//////////////////////////////////////////////////////////////
	//                     Constructors                         //
	//////////////////////////////////////////////////////////////
	/**
		Create a new big integer from the int value i
	**/
	public static function nbv(i : Int) : BigInteger {
		var r = nbi();
		r.fromInt(i);
		return r;
	}

	/**
		return new, unset BigInteger
	**/
	public static function nbi() : BigInteger {
		return new BigInteger(null);
	}

	/**
		Construct a BigInteger from a string in a given base
	**/
	public static function ofString(s : String, base : Int)
	{
		var i = nbi();
		i.fromString(s, base);
		return i;
	}

	/**
		Construct a BigInteger from an integer value
	**/
	public static function ofInt(x : Int) {
		var i = nbi();
		i.fromInt(x);
		return i;
	}

	/**
		Construct from random number source
	**/
	public static function ofRandom(a:Int, b:math.prng.Random) : BigInteger {
		var i = nbi();
		i.fromRandom(a, b);
		return i;
	}

	//////////////////////////////////////////////////////////////
	//                  Operator functions                      //
	//////////////////////////////////////////////////////////////
	public static function op_and(x:Int, y:Int) { return x&y; }
	public static function op_or(x:Int, y:Int) { return x|y; }
	public static function op_xor(x:Int, y:Int) { return x^y; }
#if !neko
	public static function op_andnot(x:Int, y:Int) { return x&~y; }
#else true
	public static function op_andnot(x:Int, y:Int) {
		return Int32.toInt(
			Int32.and(
				Int32.ofInt(x),
				Int32.complement(Int32.ofInt(y))
			)
		);
	}
#end

	//////////////////////////////////////////////////////////////
	//                Misc Static functions                     //
	//////////////////////////////////////////////////////////////
	/** returns bit length of the integer x **/
	public static function nbits( x : Int ) : Int {
		var r : Int = 1;
		var t : Int;
		if((t=x>>>16) != 0) { x = t; r += 16; }
		if((t=x>>8) != 0) { x = t; r += 8; }
		if((t=x>>4) != 0) { x = t; r += 4; }
		if((t=x>>2) != 0) { x = t; r += 2; }
		if((t=x>>1) != 0) { x = t; r += 1; }
		return r;
	}

	/** return number of 1 bits in x **/
	public static function cbit(x : Int) : Int {
		var r = 0;
		while(x != 0) { x &= x-1; ++r; }
		return r;
	}

	static function intAt(s : String, i: Int) : Int {
		var c : Null<Int> = BI_RC[s.charCodeAt(i)];
		return (c==null)?-1:c;
	}

	static function int2char(n: Int) : String {
		return BI_RM.charAt(n);
	}

	/** <pre>return index of lowest 1-bit in x, x < 2^31</pre> **/
	static function lbit(x : Int) : Int {
		if(x == 0) return -1;
		var r = 0;
		if((x&0xffff) == 0) { x >>= 16; r += 16; }
		if((x&0xff) == 0) { x >>= 8; r += 8; }
		if((x&0xf) == 0) { x >>= 4; r += 4; }
		if((x&3) == 0) { x >>= 2; r += 2; }
		if((x&1) == 0) ++r;
		return r;
	}

#if neko
	static function mkBigInt(a:BigInteger) : HndBI {
		return bi_create(DB, a.t, a.sign, I32.mkNekoArray31(a.chunks));
	}

	static function mkFromHandle(r : HndBI) : BigInteger {
		var a = bi_to_array(r);
		var rv = BigInteger.nbi();
		untyped	{
			rv.t = a[0];
			rv.sign = a[1];
			for(x in 0...rv.t) {
				rv.chunks[x] = a[x+2];
			}
		}
		return rv;
	}

	static function popFromHandle(h : HndBI, r : BigInteger) {
		var a = mkFromHandle(h);
		r.t = a.t;
		r.sign = a.sign;
		r.chunks = a.chunks.copy();
	}

	private static var bi_create = neko.Lib.load("math","bi_create",4);
	private static var bi_free = neko.Lib.load("math","bi_free",1);
	private static var bi_sub_to = neko.Lib.load("math","bi_sub_to",2);
	private static var bi_to_array = neko.Lib.load("math","bi_to_array",1);
#end
}

