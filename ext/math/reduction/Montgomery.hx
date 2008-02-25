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

/**
	Montgomery reduction
**/
class Montgomery implements math.reduction.ModularReduction {

	private var m : BigInteger;
	private var mp : Int;
	private var mpl : Int;
	private var mph : Int;
	private var um : Int;
	private var mt2 : Int;


	public function new(x:BigInteger) {
		m = x;
		mp = m.invDigit();
		mpl = mp&0x7fff;
		mph = mp>>15;
		um = (1<<(BigInteger.DB-15))-1;
		mt2 = 2*m.t;
	}

	// xR mod m
	public function convert(x:BigInteger) {
		var r = BigInteger.nbi();
		x.abs().dlShiftTo(m.t,r);
		r.divRemTo(m,null,r);
		if(x.sign < 0 && r.compareTo(BigInteger.ZERO) > 0)
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

	// x = x/R mod m (HAC 14.32)
	public function reduce(x:BigInteger) {
		x.padTo( mt2 );	// pad x so am has enough room later
//		for(var i = 0; i < m.t; ++i) {
		for( i in 0...m.t ) {
			// faster way of calculating u0 = x[i]*mp mod DV
			var j = x.chunks[i]&0x7fff;
			var u0 = (j*mpl+(((j*mph+(x.chunks[i]>>15)*mpl)&um)<<15))&BigInteger.DM;
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
		}
		x.clamp();
		x.drShiftTo(m.t,x);
		if(x.compareTo(m) >= 0) x.subTo(m,x);
	}

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