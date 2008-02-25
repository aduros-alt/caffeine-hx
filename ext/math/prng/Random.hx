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

/**
	Random number generator - requires a Prng backend, e.g. ArcFour
**/
package math.prng;

class Random {
	var state : IPrng;
	var pool : Array<Int>;
	var pptr : Int;
	var initialized: Bool;

	public function new(?backend: IPrng) {
		createState(backend);
		initialized = false;
	}

	/**
		Get one random byte value
	**/
	public function getByte() : Int {
		if(initialized == false) {
			createState();
			state.init(pool);
			for(i in 0...pool.length)
				pool[i] = 0;
			pptr = 0;
			pool = new Array();
			initialized = true;
		}
		return state.next();
	}

	/**
		Fill the provided ByteString with random bytes
	**/
	public function nextBytes(ba : ByteString) : Void {
		var i;
		for(i in 0...ba.length)
			ba.set(i, getByte());
	}

	/**
		Fill the provided Array with random bytes
	**/
	public function nextBytesArray(ba : Array<Int>) : Void {
		var i;
		for(i in 0...ba.length)
			ba[i] = getByte();
	}

	/**
		Mix in a 32-bit integer into the pool
	**/
	function seedInt(x : Int) {
		pool[pptr++] ^= x & 255;
		pool[pptr++] ^= (x >> 8) & 255;
		pool[pptr++] ^= (x >> 16) & 255;
		pool[pptr++] ^= (x >> 24) & 255;
		if(pptr >= state.size)
			pptr -= state.size;
	}

	// Mix in the current time (w/milliseconds) into the pool
	function seedTime() {
		var dt = Date.now().getTime();
		var m = Std.int(dt * 1000);
		seedInt(m);
	}

	function createState(?backend: IPrng) {
		if(backend == null)
			state = new ArcFour();
		else
			state = backend;
		if(pool == null) {
			pool = new Array();
			pptr = 0;
			var t;
/*
			// TODO:
			if(navigator.appName == "Netscape" && navigator.appVersion < "5" && window.crypto) {
				// Extract entropy (256 bits) from NS4 RNG if available
				var z = window.crypto.random(32);
				for(t = 0; t < z.length; ++t)
				pool[pptr++] = z.charCodeAt(t) & 255;
			}
*/
			while(pptr < state.size) {  // extract some randomness from Math.random()
				t = Math.floor(65536 * Math.random());
				pool[pptr++] = t >>> 8;
				pool[pptr++] = t & 255;
			}
			pptr = 0;
			seedTime();
		}
	}

}

