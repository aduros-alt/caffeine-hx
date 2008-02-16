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
package math;

import math.reduction.Classic
import math.reduction.Montgomery;

class BigInteger {
	public static var DB : Int 		= 30; //dbits
	public static var DM : Int 		= ((1<<30)-1);
	public static var DV : Int 		= (1<<30);

	public static var BI_FP : Int 	= 52;
	public static var FV : Float 	= Math.pow(2,BI_FP);
	public static var F1 : Float 	= BI_FP-dbits;
	public static var F2 : Float 	= 2*dbits-BI_FP;

	public static var ZERO(getZERO,null)	: BigInteger;
	public static var ONE(getONE, null)		: BigInteger;

	// Digit conversions
	static var BI_RM : String ;
	static var BI_RC : Array<Int>;


	static function __init__() {

		DB = 30; // dbits .. see notes in constructor and the am? functions
		DM = ((1<<DB)-1);
		DV = (1<<DB);

		BI_FP = 52;
		FV = Math.pow(2,BI_FP);
		F1 = BI_FP - DB;
		F2 = 2 * DB - BI_FP;

		BI_RM = "0123456789abcdefghijklmnopqrstuvwxyz";
		var rr : Int = "0".charCodeAt(0);
		for(vv = 0; vv <= 9; ++vv)
			BI_RC[rr++] = vv;
		rr = "a".charCodeAt(0);
		for(vv = 10; vv < 36; ++vv)
			BI_RC[rr++] = vv;
		rr = "A".charCodeAt(0);
		for(vv = 10; vv < 36; ++vv)
			BI_RC[rr++] = vv;
	}

	public static function getZERO() : BigInteger {
		return nbv(0);
	}

	public static function getONE() : BigInteger {
		return nbv(1);
	}

	/**
		Create a new big integer from the int value i
		TODO: function name
	**/
	public static function nbv(i : Int) {
		var r = nbi();
		r.fromInt(i);
		return r;
	}

	/**
		// return new, unset BigInteger
		TODO: function name
	**/
	public static function nbi() {
		return new BigInteger(null);
	}

	public var t(default,null) : Int; // number of chunks.
	public var s(default,null) : Int; //sign
	public var a(default,null) : Array; // chunks
	var am : Int->Int->BigInteger->Int->Int->Int->Int; // am function

	public function new(a, b, c) {
		if(a != null)
			if("number" == typeof a) this.fromNumber(a,b,c);
			else if(b == null && "string" != typeof a) this.fromString(a,256);
			else this.fromString(a,b);
		am = am2;
#if js
		/*

		There should be a static var populated at __init__ that
		chooses the am function type, then on new() it can be applied.

		// Bits per digit
		var dbits; This is th DB static

		// JavaScript engine analysis
		var canary = 0xdeadbeefcafe;
		var j_lm = ((canary&0xffffff)==0xefcafe);

		if(j_lm && (navigator.appName == "Microsoft Internet Explorer")) {
		BigInteger.prototype.am = am2;
		dbits = 30;
		}
		else if(j_lm && (navigator.appName != "Netscape")) {
		BigInteger.prototype.am = am1;
		dbits = 26;
		}
		else { // Mozilla/Netscape seems to prefer
		BigInteger.prototype.am = am3;
		dbits = 28;
		}
		*/
#end
	}

	/**
		Absolute value
	**/
	public function abs() {
		return (this.s<0)?this.negate():this;
	}


	/**
		Modulus division bn % bn
	**/
	public function mod(a) {
		var r = nbi();
		this.abs().divRemTo(a,null,r);
		if(this.s < 0 && r.compareTo(BigInteger.ZERO) > 0) a.subTo(r,r);
		return r;
	}

	/**
		this^e % m, 0 <= e < 2^32
	**/
	public function modPowInt(e,m) {
		var z;
		if(e < 256 || m.isEven()) z = new Classic(m);
		else z = new Montgomery(m);
		return this.exp(e,z);
	}

	/**
		return the number of bits in "this"
	**/
	public function bitLength() {
		if(this.t <= 0) return 0;
		return this.DB*(this.t-1)+nbits(this[this.t-1]^(this.s&this.DM));
	}

	/**
		return + if this > a, - if this < a, 0 if equal
	**/
	public function compareTo(a) {
		var r = this.s-a.s;
		if(r != 0) return r;
		var i = this.t;
		r = i-a.t;
		if(r != 0) return r;
		while(--i >= 0) if((r=this[i]-a[i]) != 0) return r;
		return 0;
	}

	/**
		-this
	**/
	public function negate() {
		var r = nbi();
		BigInteger.ZERO.subTo(this,r);
		return r;
	}


	/**
		return string representation in given radix
		TODO: rename function. Conflict with toString()
	**/
	public function toString(b) {
		if(this.s < 0) return "-"+this.negate().toString(b);
		var k;
		if(b == 16) k = 4;
		else if(b == 8) k = 3;
		else if(b == 2) k = 1;
		else if(b == 32) k = 5;
		else if(b == 4) k = 2;
		else return this.toRadix(b);
		var km = (1<<k)-1, d, m = false, r = "", i = this.t;
		var p = this.DB-(i*this.DB)%k;
		if(i-- > 0) {
			if(p < this.DB && (d = this[i]>>p) > 0) { m = true; r = int2char(d); }
			while(i >= 0) {
			if(p < k) {
				d = (this[i]&((1<<p)-1))<<(k-p);
				d |= this[--i]>>(p+=this.DB-k);
			}
			else {
				d = (this[i]>>(p-=k))&km;
				if(p <= 0) { p += this.DB; --i; }
			}
			if(d > 0) m = true;
			if(m) r += int2char(d);
			}
		}
		return m?r:"0";
	}


	//////////////////////////////////////////////////////////////
	//					Private methods							//
	//////////////////////////////////////////////////////////////

	// (protected) copy this to r
	function copyTo(r) {
		for(var i = this.t-1; i >= 0; --i)
			r[i] = this[i];
		r.t = this.t;
		r.s = this.s;
	}

	// (protected) set from integer value x, -DV <= x < DV
	function fromInt(x : Int) {
		this.t = 1;
		this.s = (x<0)?-1:0;
		if(x > 0) this[0] = x;
		else if(x < -1) this[0] = x+DV;
		else this.t = 0;
	}

	// (protected) set from string and radix
	function fromString(s : String, b : Int) {
		var k;
		if(b == 16) k = 4;
		else if(b == 8) k = 3;
		else if(b == 256) k = 8; // byte array
		else if(b == 2) k = 1;
		else if(b == 32) k = 5;
		else if(b == 4) k = 2;
		else { this.fromRadix(s,b); return; }
		this.t = 0;
		this.s = 0;
		var i = s.length, mi = false, sh = 0;
		while(--i >= 0) {
			var x = (k==8)?s[i]&0xff:intAt(s,i);
			if(x < 0) {
			if(s.charAt(i) == "-") mi = true;
			continue;
			}
			mi = false;
			if(sh == 0)
			this[this.t++] = x;
			else if(sh+k > this.DB) {
			this[this.t-1] |= (x&((1<<(this.DB-sh))-1))<<sh;
			this[this.t++] = (x>>(this.DB-sh));
			}
			else
			this[this.t-1] |= x<<sh;
			sh += k;
			if(sh >= this.DB) sh -= this.DB;
		}
		if(k == 8 && (s[0]&0x80) != 0) {
			this.s = -1;
			if(sh > 0) this[this.t-1] |= ((1<<(this.DB-sh))-1)<<sh;
		}
		this.clamp();
		if(mi) BigInteger.ZERO.subTo(this,this);
	}

	// (protected) clamp off excess high words
	function bnpClamp() {
		var c = this.s&this.DM;
		while(this.t > 0 && this[this.t-1] == c) --this.t;
	}

	// (protected) r = this << n*DB
	function dlShiftTo(n,r) {
		var i;
		for(i = this.t-1; i >= 0; --i) r[i+n] = this[i];
		for(i = n-1; i >= 0; --i) r[i] = 0;
		r.t = this.t+n;
		r.s = this.s;
	}

	// (protected) r = this >> n*DB
	function drShiftTo(n,r) {
		for(var i = n; i < this.t; ++i) r[i-n] = this[i];
		r.t = Math.max(this.t-n,0);
		r.s = this.s;
	}

	// (protected) r = this << n
	function lShiftTo(n,r) {
		var bs = n%this.DB;
		var cbs = this.DB-bs;
		var bm = (1<<cbs)-1;
		var ds = Math.floor(n/this.DB), c = (this.s<<bs)&this.DM, i;
		for(i = this.t-1; i >= 0; --i) {
			r[i+ds+1] = (this[i]>>cbs)|c;
			c = (this[i]&bm)<<bs;
		}
		for(i = ds-1; i >= 0; --i) r[i] = 0;
		r[ds] = c;
		r.t = this.t+ds+1;
		r.s = this.s;
		r.clamp();
	}

	// (protected) r = this >> n
	function rShiftTo(n,r) {
		r.s = this.s;
		var ds = Math.floor(n/this.DB);
		if(ds >= this.t) { r.t = 0; return; }
		var bs = n%this.DB;
		var cbs = this.DB-bs;
		var bm = (1<<bs)-1;
		r[0] = this[ds]>>bs;
		for(var i = ds+1; i < this.t; ++i) {
			r[i-ds-1] |= (this[i]&bm)<<cbs;
			r[i-ds] = this[i]>>bs;
		}
		if(bs > 0) r[this.t-ds-1] |= (this.s&bm)<<cbs;
		r.t = this.t-ds;
		r.clamp();
	}

	// (protected) r = this - a
	function subTo(a,r) {
		var i = 0, c = 0, m = Math.min(a.t,this.t);
		while(i < m) {
			c += this[i]-a[i];
			r[i++] = c&this.DM;
			c >>= this.DB;
		}
		if(a.t < this.t) {
			c -= a.s;
			while(i < this.t) {
			c += this[i];
			r[i++] = c&this.DM;
			c >>= this.DB;
			}
			c += this.s;
		}
		else {
			c += this.s;
			while(i < a.t) {
			c -= a[i];
			r[i++] = c&this.DM;
			c >>= this.DB;
			}
			c -= a.s;
		}
		r.s = (c<0)?-1:0;
		if(c < -1) r[i++] = this.DV+c;
		else if(c > 0) r[i++] = c;
		r.t = i;
		r.clamp();
	}

	// (protected) r = this * a, r != this,a (HAC 14.12)
	// "this" should be the larger one if appropriate.
	function multiplyTo(a,r) {
		var x = this.abs(), y = a.abs();
		var i = x.t;
		r.t = i+y.t;
		while(--i >= 0) r[i] = 0;
		for(i = 0; i < y.t; ++i) r[i+x.t] = x.am(0,y[i],r,i,0,x.t);
		r.s = 0;
		r.clamp();
		if(this.s != a.s) BigInteger.ZERO.subTo(r,r);
	}

	// (protected) r = this^2, r != this (HAC 14.16)
	function squareTo(r) {
		var x = this.abs();
		var i = r.t = 2*x.t;
		while(--i >= 0) r[i] = 0;
		for(i = 0; i < x.t-1; ++i) {
			var c = x.am(i,x[i],r,2*i,0,1);
			if((r[i+x.t]+=x.am(i+1,2*x[i],r,2*i+1,c,x.t-i-1)) >= x.DV) {
			r[i+x.t] -= x.DV;
			r[i+x.t+1] = 1;
			}
		}
		if(r.t > 0) r[r.t-1] += x.am(i,x[i],r,2*i,0,1);
		r.s = 0;
		r.clamp();
	}

	// (protected) divide this by m, quotient and remainder to q, r (HAC 14.20)
	// r != q, this != m.  q or r may be null.
	function divRemTo(m,q,r) {
		var pm = m.abs();
		if(pm.t <= 0) return;
		var pt = this.abs();
		if(pt.t < pm.t) {
			if(q != null) q.fromInt(0);
			if(r != null) this.copyTo(r);
			return;
		}
		if(r == null) r = nbi();
		var y = nbi(), ts = this.s, ms = m.s;
		var nsh = this.DB-nbits(pm[pm.t-1]);	// normalize modulus
		if(nsh > 0) { pm.lShiftTo(nsh,y); pt.lShiftTo(nsh,r); }
		else { pm.copyTo(y); pt.copyTo(r); }
		var ys = y.t;
		var y0 = y[ys-1];
		if(y0 == 0) return;
		var yt = y0*(1<<this.F1)+((ys>1)?y[ys-2]>>this.F2:0);
		var d1 = this.FV/yt, d2 = (1<<this.F1)/yt, e = 1<<this.F2;
		var i = r.t, j = i-ys, t = (q==null)?nbi():q;
		y.dlShiftTo(j,t);
		if(r.compareTo(t) >= 0) {
			r[r.t++] = 1;
			r.subTo(t,r);
		}
		BigInteger.ONE.dlShiftTo(ys,t);
		t.subTo(y,y);	// "negative" y so we can replace sub with am later
		while(y.t < ys) y[y.t++] = 0;
		while(--j >= 0) {
			// Estimate quotient digit
			var qd = (r[--i]==y0)?this.DM:Math.floor(r[i]*d1+(r[i-1]+e)*d2);
			if((r[i]+=y.am(0,qd,r,j,0,ys)) < qd) {	// Try it out
			y.dlShiftTo(j,t);
			r.subTo(t,r);
			while(r[i] < --qd) r.subTo(t,r);
			}
		}
		if(q != null) {
			r.drShiftTo(ys,q);
			if(ts != ms) BigInteger.ZERO.subTo(q,q);
		}
		r.t = ys;
		r.clamp();
		if(nsh > 0) r.rShiftTo(nsh,r);	// Denormalize remainder
		if(ts < 0) BigInteger.ZERO.subTo(r,r);
	}

	// (protected) return "-1/this % 2^DB"; useful for Mont. reduction
	// justification:
	//         xy == 1 (mod m)
	//         xy =  1+km
	//   xy(2-xy) = (1+km)(1-km)
	// x[y(2-xy)] = 1-k^2m^2
	// x[y(2-xy)] == 1 (mod m^2)
	// if y is 1/x mod m, then y(2-xy) is 1/x mod m^2
	// should reduce x and y(2-xy) by m^2 at each step to keep size bounded.
	// JS multiply "overflows" differently from C/C++, so care is needed here.
	function invDigit() {
		if(this.t < 1) return 0;
		var x = this[0];
		if((x&1) == 0) return 0;
		var y = x&3;		// y == 1/x mod 2^2
		y = (y*(2-(x&0xf)*y))&0xf;	// y == 1/x mod 2^4
		y = (y*(2-(x&0xff)*y))&0xff;	// y == 1/x mod 2^8
		y = (y*(2-(((x&0xffff)*y)&0xffff)))&0xffff;	// y == 1/x mod 2^16
		// last step - calculate inverse mod DV directly;
		// assumes 16 < DB <= 32 and assumes ability to handle 48-bit ints
		y = (y*(2-x*y%this.DV))%this.DV;		// y == 1/x mod 2^dbits
		// we really want the negative inverse, and -DV < y < DV
		return (y>0)?this.DV-y:-y;
	}

	// (protected) true if this is even
	function isEven() {
		return ((this.t>0)?(this[0]&1):this.s) == 0;
	}

	// (protected) this^e, e < 2^32, doing sqr and mul with "r" (HAC 14.79)
	function exp(e,z) {
		if(e > 0xffffffff || e < 1) return BigInteger.ONE;
		var r = nbi(), r2 = nbi(), g = z.convert(this), i = nbits(e)-1;
		g.copyTo(r);
		while(--i >= 0) {
			z.sqrTo(r,r2);
			if((e&(1<<i)) > 0) z.mulTo(r2,g,r);
			else { var t = r; r = r2; r2 = t; }
		}
		return z.revert(r);
	}

	// returns bit length of the integer x
	function nbits( x : Int ) {
		var r : Int = 1;
		var t : Int;
		if((t=x>>>16) != 0) { x = t; r += 16; }
		if((t=x>>8) != 0) { x = t; r += 8; }
		if((t=x>>4) != 0) { x = t; r += 4; }
		if((t=x>>2) != 0) { x = t; r += 2; }
		if((t=x>>1) != 0) { x = t; r += 1; }
		return r;
	}

	// am: Compute w_j += (x*this_i), propagate carries,
	// c is initial carry, returns final carry.
	// c < 3*dvalue, x < 2*dvalue, this_i < dvalue
	// TODO Javascript:
	// We need to select the fastest one that works in this environment.
	//
	// am2 avoids a big mult-and-extract completely.
	// Max digit bits should be <= 30 because we do bitwise ops
	// on values up to 2*hdvalue^2-hdvalue-1 (< 2^31)
	function am2(i:Int,x:Int,w:BigInteger,j:Int,c:Int,n:Int) : Int {
		var xl:int = x&0x7fff;
		var xh:int = x>>15;
		while(--n >= 0) {
			var l : Int = a[i]&0x7fff;
			var h : Int = a[i++]>>15;
			var m : Int = xh*l + h*xl;
			l = xl*l + ((m&0x7fff)<<15)+w.a[j]+(c&0x3fffffff);
			c = (l>>>30)+(m>>>15)+xh*h+(c>>>30);
			w.a[j++] = l&0x3fffffff;
		}
		return c;
	}

	// am1: use a single mult and divide to get the high bits,
	// max digit bits should be 26 because
	// max internal value = 2*dvalue^2-2*dvalue (< 2^53)
	function am1(i:Int,x:Int,w:BigInteger,j:Int,c:Int,n:Int) : Int {
		while(--n >= 0) {
			var v = x*this[i++]+w[j]+c;
			c = Math.floor(v/0x4000000);
			w[j++] = v&0x3ffffff;
		}
		return c;
	}

	// Alternately, set max digit bits to 28 since some
	// browsers slow down when dealing with 32-bit numbers.
	function am3(i:Int,x:Int,w:BigInteger,j:Int,c:Int,n:Int) : Int {
		var xl = x&0x3fff, xh = x>>14;
		while(--n >= 0) {
			var l = this[i]&0x3fff;
			var h = this[i++]>>14;
			var m = xh*l+h*xl;
			l = xl*l+((m&0x3fff)<<14)+w[j]+c;
			c = (l>>28)+(m>>14)+xh*h;
			w[j++] = l&0xfffffff;
		}
		return c;
	}

	function intAt(s,i) {
		var c = BI_RC[s.charCodeAt(i)];
		return (c==null)?-1:c;
	}

	function int2char(n: Int) : String {
		return BI_RM.charAt(n);
	}
}

