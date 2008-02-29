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

package math.reduction;

import math.BigInteger;
#if neko
import neko.Int32;
#end

#if !neko
/**
	Montgomery reduction
**/
class Montgomery implements math.reduction.ModularReduction {
	private var m : BigInteger;
	private var mt2 : Int;
#if neko
	private var mp : Int32;
	private var mpl : Int32;
	private var mph : Int32;
	private var um : Int32;
	private var DM : Int32;
#else true
	private var mp : Int;
	private var mpl : Int;
	private var mph : Int;
	private var um : Int;
	private var DM : Int;
	//private static var bi_am3 = neko.Lib.load("math","bi_am3",3);
#end


#if neko
	public function new(x:BigInteger) {
		m = x;
		mp = Int32.ofInt(m.invDigit());
		mpl = Int32.and(mp, Int32.ofInt(0x7fff));
		mph = Int32.shr(mp, 15);
		um = Int32.ofInt((1<<BigInteger.DB-15)-1);
		mt2 = 2 *m.t;
		DM = Int32.ofInt(BigInteger.DM);
	}
#else true
	public function new(x:BigInteger) {
		m = x;
		mp = m.invDigit();
		mpl = mp&0x7fff;
		mph = mp>>15;
		um = (1<<(BigInteger.DB-15))-1;
		mt2 = 2*m.t;
		DM = BigInteger.DM;
	}
#end

	// xR mod m
	public function convert(x:BigInteger) {
		var r = BigInteger.nbi();
		x.abs().dlShiftTo(m.t,r);
		r.divRemTo(m,null,r);
		if(x.sign < 0 && r.compare(BigInteger.ZERO) > 0)
			m.subTo(r,r);
		return r;
	}

	// x/R mod m
	public function revert(x:BigInteger) {
		var r = BigInteger.nbi();
		x.copyTo(r);
		reduce(r);
		return r;
	}

#if neko
	// x = x/R mod m (HAC 14.32)
	public function reduce(x:BigInteger) {
		x.padTo( mt2 );	// pad x so am has enough room later
//		for(var i = 0; i < m.t; ++i) {
		var i = 0;
		while( i < m.t) {
			var j : Int32  = Int32.and(Int32.ofInt(x.chunks[i]), (Int32.ofInt(0x7fff)));
			var u1 : Int32 = Int32.ofInt(x.chunks[i]>>15);
			var u2 : Int32 = Int32.mul(j, mph);
			var u3 : Int32 = Int32.mul(u1, mpl);
			var u4 : Int32 = Int32.add(u2, u3);
			var u5 : Int32 = Int32.and(u4, um);
			var u6 : Int32 = Int32.shl(u4, 15);
			var u7 : Int32 = Int32.mul(j, mpl);
			var u8 : Int32 = Int32.add(u7, u6);
			var u0 : Int32 = Int32.and(u8, DM);
			var sj = i+m.t;
			x.chunks[sj] += m.amNeko(Int32.ofInt(0),u0,x,Int32.ofInt(i),Int32.ofInt(0),Int32.ofInt(m.t));
			// propagate carry
			while(x.chunks[sj] >= BigInteger.DV) {
				x.chunks[sj] -= BigInteger.DV;
				if(x.chunks.length < sj+2)
					x.chunks[sj+1] = 0;
				x.chunks[++sj]++;
			}
			i++;
		}
		x.clamp();
		x.drShiftTo(m.t,x);
		if(x.compare(m) >= 0) x.subTo(m,x);
	}
#else true
	// x = x/R mod m (HAC 14.32)
	public function reduce(x:BigInteger) {
		x.padTo( mt2 );	// pad x so am has enough room later
//		for(var i = 0; i < m.t; ++i) {
		var i = 0;
		while( i < m.t) {
			// faster way of calculating u0 = x[i]*mp mod DV
			var j : Int = x.chunks[i]&0x7fff;
			//(j*mpl+(((j*mph+(x.chunks[i]>>15)*mpl)&um)<<15))&BigInteger.DM;
		    // (u7 )   (          u6                        )
			var u1 : Int = (x.chunks[i]>>15);
			var u2 : Int = j*mph;
			var u3 : Int = u1*mpl;
			var u4 : Int = u2+u3;
			var u5 : Int = u4 & um;
			var u6 : Int = u4<<15;
			var u7 : Int = j*mpl;
			var u8 : Int = u7+u6;
			var u0 : Int = u8 & BigInteger.DM;
			// use am to combine the multiply-shift-add into one call
			j = i+m.t;
			x.chunks[j] += m.am(0,u0,x,i,0,m.t);
			// propagate carry
			while(x.chunks[j] >= BigInteger.DV) {
				x.chunks[j] -= BigInteger.DV;
				if(x.chunks.length < j+2)
					x.chunks[j+1] = 0;
				x.chunks[++j]++;
			}
			i++;
		}
		x.clamp();
		x.drShiftTo(m.t,x);
		if(x.compare(m) >= 0) x.subTo(m,x);
	}
#end

	// r = "xy/R mod m"; x,y != r
	public function mulTo(x:BigInteger,y:BigInteger,r:BigInteger) {
		x.multiplyTo(y,r);
		reduce(r);
	}

	// r = "x^2/R mod m"; x != r
	public function sqrTo(x:BigInteger, r:BigInteger) {
		x.squareTo(r);
		reduce(r);
	}

}
#end

