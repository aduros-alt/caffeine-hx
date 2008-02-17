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
import math.reduction.Classic;
import math.reduction.Montgomery;

class BigInteger {
	public static var DB : Int 		= 30; //dbits
	public static var DM : Int 		= ((1<<30)-1);
	public static var DV : Int 		= (1<<30);

	public static var BI_FP : Int 	= 52;
	public static var FV : Float 	= Math.pow(2,BI_FP);
	public static var F1 : Int 	= BI_FP-30;
	public static var F2 : Int 	= 2*30-BI_FP;

	public static var ZERO(getZERO,null)	: BigInteger;
	public static var ONE(getONE, null)		: BigInteger;

	// Digit conversions
	static var BI_RM : String ;
	static var BI_RC : Array<Int>;

	static function __init__() {
		BI_RM = "0123456789abcdefghijklmnopqrstuvwxyz";
		var rr : Int = "0".charCodeAt(0);
		for(vv in 0...10)
			BI_RC[rr++] = vv;
		rr = "a".charCodeAt(0);
		for(vv in 10...37)
			BI_RC[rr++] = vv;
		rr = "A".charCodeAt(0);
		for(vv in 10...37)
			BI_RC[rr++] = vv;

#if js

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
		
		DB = dbits;
		F1 = BI_FP - dbits;
		F2 = 2 * dbits - BI_FP;
#end

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
	public var chunks(default,null) : Array<Int>; // chunks

	public function new(?int : Int, ?str : String, ?radix : Int) {
		chunks = new Array<Int>();
		if(int != null)	this.fromInt(int);
		else if( str != null && radix == null) this.fromString(str,256);
	}

	/**
		Absolute value
	**/
	public function abs() {
		return (this.s<0)?this.negate():this;
	}

	/**
		This is so Montgomery Reduction can pad. Used to be (in Montgomery):
		while(x.t <= this.mt2)	// pad x so am has enough room later
			x.chunks[x.t++] = 0;
	**/
	public function padTo ( n : Int ) : Void {
		while( t < n )	chunks[ t++ ] = 0;
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
	public function modPowInt(e,m : BigInteger) {
		var z : ModularReduction;
		if(e < 256 || m.isEven()) z = new Classic(m);
		else z = new Montgomery(m);
		return this.exp(e,z);
	}

	/**
		return the number of bits in "this"
	**/
	public function bitLength() {
		if(this.t <= 0) return 0;
		return DB*(this.t-1)+nbits(chunks[this.t-1]^(this.s&DM));
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
		while(--i >= 0) if((r=chunks[i]-a.chunks[i]) != 0) return r;
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


	//////////////////////////////////////////////////////////////
	//					Private methods							//
	//////////////////////////////////////////////////////////////

	// (protected) copy this to r
	public function copyTo(r : BigInteger) {
		r.chunks = chunks.copy();
		r.t = this.t;
		r.s = this.s;
	}

	// (protected) set from integer value x, -DV <= x < DV
	function fromInt(x : Int) {
		this.t = 1;
		this.s = (x<0)?-1:0;
		if(x > 0) chunks[0] = x;
		else if(x < -1) chunks[0] = x+DV;
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
			var x = (k==8)?s.charCodeAt( i )&0xff:intAt(s,i);
			if(x < 0) {
			if(s.charAt(i) == "-") mi = true;
			continue;
			}
			mi = false;
			if(sh == 0)
			chunks[this.t++] = x;
			else if(sh+k > DB) {
			chunks[this.t-1] |= (x&((1<<(DB-sh))-1))<<sh;
			chunks[this.t++] = (x>>(DB-sh));
			}
			else
			chunks[this.t-1] |= x<<sh;
			sh += k;
			if(sh >= DB) sh -= DB;
		}
		if(k == 8 && (s.charCodeAt( 0 )&0x80) != 0) {
			this.s = -1;
			if(sh > 0) chunks[this.t-1] |= ((1<<(DB-sh))-1)<<sh;
		}
		this.clamp();
		if(mi) BigInteger.ZERO.subTo(this,this);
	}
	
	// (protected) convert from radix string
	function fromRadix(s : String, b : Int) {
	  this.fromInt(0);
	  if(b == null) b = 10;
	  var cs = Math.floor(0.6931471805599453*DB/Math.log(b));
	  var d = Std.int( Math.pow(b,cs) ), mi = false, j = 0, w = 0;
	  for(i in 0...s.length) {
	    var x = intAt(s,i);
	    if(x < 0) {
	      if(s.charAt(i) == "-" && this.s == 0) mi = true;
	      continue;
	    }
	    w = b*w+x;
	    if(++j >= cs) {
		  dMultiply( d );
	      this.dAddOffset(w,0);
	      j = 0;
	      w = 0;
	    }
	  }
	  if(j > 0) {
	    this.dMultiply(Std.int( Math.pow(b,j) ));
	    this.dAddOffset(w,0);
	  }
	  if(mi) BigInteger.ZERO.subTo(this,this);
	}
	
	// (protected) convert to radix string
	function toRadix(b) {
	  if(b == null) b = 10;
	  if(s == 0 || b < 2 || b > 36) return "0";
	  var cs = Math.floor(0.6931471805599453*DB/Math.log(b));
	  var a = Std.int(Math.pow(b,cs));
	  var d = nbv(a), y = nbi(), z = nbi(), r = "";
	  this.divRemTo(d,y,z);
	  while(y.s > 0) {
	    r = (a+z.intValue()).toString(b).substr(1) + r;
	    y.divRemTo(d,y,z);
	  }
	  return z.intValue().toString(b) + r;
	}

	function dAddOffset(n,w) {
	  while(t <= w) chunks[t++] = 0;
	  chunks[w] += n;
	  while(chunks[w] >= DV) {
	    chunks[w] -= DV;
	    if(++w >= t) chunks[t++] = 0;
	    ++chunks[w];
	  }
	}

	function dMultiply ( n : Int ) {
		chunks[ t ] = am(0,n-1,this,0,0,t);
		t++;
		clamp();
	}	
	
	function intValue() {
		if(s < 0) {
			if(t == 1) return chunks[0]-DV;
			else if(t == 0) return -1;
		}
		else if(t == 1) return chunks[0];
		else if(t == 0) return 0;
		// assumes 16 < DB < 32
		return ((chunks[1]&((1<<(32-DB))-1))<<DB)|chunks[0];
	}
	
	// (protected) clamp off excess high words
	public function clamp() {
		var c = this.s&DM;
		while(this.t > 0 && chunks[this.t-1] == c) --this.t;
	}

	// (protected) r = this << n*DB
	public function dlShiftTo(n : Int, r : BigInteger) {
		var i;
//		for(i = this.t-1; i >= 0; --i) r.chunks[i+n] = chunks[i];
//		for(i = n-1; i >= 0; --i) r.chunks[i] = 0;
		var padding = new Array<Int>();
		while( n-- > 0 ) 	padding.push( 0 );
		r.chunks = padding.concat( chunks.copy() );
		r.t = this.t+n;
		r.s = this.s;
	}

	// (protected) r = this >> n*DB
	public function drShiftTo(n : Int, r : BigInteger) {
//		for(var i = n; i < this.t; ++i) r.chunks[i-n] = chunks[i];
		r.chunks = chunks.slice( n );
		r.t = Std.int( Math.max(this.t-n,0) );
		r.s = this.s;
	}

	// (protected) r = this << n
	public function lShiftTo(n : Int, r : BigInteger) {
		var bs = n%DB;
		var cbs = DB-bs;
		var bm = (1<<cbs)-1;
		var ds = Math.floor(n/DB), c = (this.s<<bs)&DM, i;
//		for(i = this.t-1; i >= 0; --i) {
		var i = t-1;
		while( i-- > 0 ) {
			r.chunks[i+ds+1] = (chunks[i]>>cbs)|c;
			c = (chunks[i]&bm)<<bs;
		}
//		for(i = ds-1; i >= 0; --i) r.chunks[i] = 0;
		i = ds - 1;
		while( i-- > 0 ) r.chunks[i] = 0;
		r.chunks[ds] = c;
		r.t = this.t+ds+1;
		r.s = this.s;
		r.clamp();
	}

	// (protected) r = this >> n
	public function rShiftTo(n : Int, r : BigInteger) {
		r.s = this.s;
		var ds = Math.floor(n/DB);
		if(ds >= this.t) { r.t = 0; return; }
		var bs = n%DB;
		var cbs = DB-bs;
		var bm = (1<<bs)-1;
		r.chunks[0] = chunks[ds]>>bs;
//		for(var i = ds+1; i < this.t; ++i) {
		for( i in (ds + 1)...this.t ) {
			r.chunks[i-ds-1] |= (chunks[i]&bm)<<cbs;
			r.chunks[i-ds] = chunks[i]>>bs;
		}
		if(bs > 0) r.chunks[this.t-ds-1] |= (this.s&bm)<<cbs;
		r.t = this.t-ds;
		r.clamp();
	}

	// (protected) r = this - a
	public function subTo(a : BigInteger, r : BigInteger) {
		var i = 0, c = 0, m = Math.min(a.t,this.t);
		while(i < m) {
			c += chunks[i]-a.chunks[i];
			r.chunks[i++] = c&DM;
			c >>= DB;
		}
		if(a.t < this.t) {
			c -= a.s;
			while(i < this.t) {
			c += chunks[i];
			r.chunks[i++] = c&DM;
			c >>= DB;
			}
			c += this.s;
		}
		else {
			c += this.s;
			while(i < a.t) {
			c -= a.chunks[i];
			r.chunks[i++] = c&DM;
			c >>= DB;
			}
			c -= a.s;
		}
		r.s = (c<0)?-1:0;
		if(c < -1) r.chunks[i++] = DV+c;
		else if(c > 0) r.chunks[i++] = c;
		r.t = i;
		r.clamp();
	}

	// (protected) r = this * a, r != this,a (HAC 14.12)
	// "this" should be the larger one if appropriate.
	public function multiplyTo(a : BigInteger, r : BigInteger) {
		var x = this.abs(), y = a.abs();
		var i = x.t;
		r.t = i+y.t;
		while(--i >= 0) r.chunks[i] = 0;
//		for(i = 0; i < y.t; ++i) r.chunks[i+x.t] = x.am(0,y[i],r,i,0,x.t);
		for( i in 0...y.t ) 	r.chunks[i+x.t] = x.am(0,y.chunks[i],r,i,0,x.t);
		r.s = 0;
		r.clamp();
		if(this.s != a.s) BigInteger.ZERO.subTo(r,r);
	}

	// (protected) r = this^2, r != this (HAC 14.16)
	public function squareTo(r : BigInteger) {
		var x = this.abs();
		var i = r.t = 2*x.t;
		while(--i >= 0) r.chunks[i] = 0;
//		for(i = 0; i < x.t-1; ++i) {
		for(i in 0...x.t-1) {
			var c = x.am(i,x.chunks[i],r,2*i,0,1);
			if((r.chunks[i+x.t]+=x.am(i+1,2*x.chunks[i],r,2*i+1,c,x.t-i-1)) >= DV) {
			r.chunks[i+x.t] -= DV;
			r.chunks[i+x.t+1] = 1;
			}
		}
		if(r.t > 0) r.chunks[r.t-1] += x.am(i,x.chunks[i],r,2*i,0,1);
		r.s = 0;
		r.clamp();
	}

	// (protected) divide this by m, quotient and remainder to q, r (HAC 14.20)
	// r != q, this != m.  q or r may be null.
	public function divRemTo(m : BigInteger, q : BigInteger ,?r : BigInteger) {
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
		var nsh = DB-nbits(pm.chunks[pm.t-1]);	// normalize modulus
		if(nsh > 0) { pm.lShiftTo(nsh,y); pt.lShiftTo(nsh,r); }
		else { pm.copyTo(y); pt.copyTo(r); }
		var ys = y.t;
		var y0 = y.chunks[ys-1];
		if(y0 == 0) return;
		var yt = y0*(1<<F1)+((ys>1)?y.chunks[ys-2]>>F2:0);
		var d1 = FV/yt, d2 = (1<<F1)/yt, e = 1<<F2;
		var i = r.t, j = i-ys, t = (q==null)?nbi():q;
		y.dlShiftTo(j,t);
		if(r.compareTo(t) >= 0) {
			r.chunks[r.t++] = 1;
			r.subTo(t,r);
		}
		BigInteger.ONE.dlShiftTo(ys,t);
		t.subTo(y,y);	// "negative" y so we can replace sub with am later
		while(y.t < ys) y.chunks[y.t++] = 0;
		while(--j >= 0) {
			// Estimate quotient digit
			var qd = (r.chunks[--i]==y0)?DM:Math.floor(r.chunks[i]*d1+(r.chunks[i-1]+e)*d2);
			if((r.chunks[i]+=y.am(0,qd,r,j,0,ys)) < qd) {	// Try it out
			y.dlShiftTo(j,t);
			r.subTo(t,r);
			while(r.chunks[i] < --qd) r.subTo(t,r);
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
	public function invDigit() {
		if(this.t < 1) return 0;
		var x = chunks[0];
		if((x&1) == 0) return 0;
		var y = x&3;		// y == 1/x mod 2^2
		y = (y*(2-(x&0xf)*y))&0xf;	// y == 1/x mod 2^4
		y = (y*(2-(x&0xff)*y))&0xff;	// y == 1/x mod 2^8
		y = (y*(2-(((x&0xffff)*y)&0xffff)))&0xffff;	// y == 1/x mod 2^16
		// last step - calculate inverse mod DV directly;
		// assumes 16 < DB <= 32 and assumes ability to handle 48-bit ints
		y = (y*(2-x*y%DV))%DV;		// y == 1/x mod 2^dbits
		// we really want the negative inverse, and -DV < y < DV
		return (y>0)?DV-y:-y;
	}

	// (protected) true if this is even
	public function isEven() {
		return ((this.t>0)?(chunks[0]&1):this.s) == 0;
	}

	// (protected) this^e, e < 2^32, doing sqr and mul with "r" (HAC 14.79)
	function exp(e,z : ModularReduction) {
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

	function intAt(s,i) {
		var c = BI_RC[s.charCodeAt(i)];
		return (c==null)?-1:c;
	}

	function int2char(n: Int) : String {
		return BI_RM.charAt(n);
	}
	
#if !js
	public function am (i:Int,x:Int,w:BigInteger,j:Int,c:Int,n:Int) : Int {
		// same as JavaScript 'am2' variant
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

#else true
	public svar am : Int->Int->BigInteger->Int->Int->Int->Int; // am function

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
			l = xl*l + ((m&0x7fff)<<15)+w.a.chunks[j]+(c&0x3fffffff);
			c = (l>>>30)+(m>>>15)+xh*h+(c>>>30);
			w.chunks[j++] = l&0x3fffffff;
		}
		return c;
	}

	// am1: use a single mult and divide to get the high bits,
	// max digit bits should be 26 because
	// max internal value = 2*dvalue^2-2*dvalue (< 2^53)
	function am1(i:Int,x:Int,w:BigInteger,j:Int,c:Int,n:Int) : Int {
		while(--n >= 0) {
			var v = x*chunks[i++]+w[j]+c;
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
			var l = chunks[i]&0x3fff;
			var h = chunks[i++]>>14;
			var m = xh*l+h*xl;
			l = xl*l+((m&0x3fff)<<14)+w[j]+c;
			c = (l>>28)+(m>>14)+xh*h;
			w[j++] = l&0xfffffff;
		}
		return c;
	}
#end
}

