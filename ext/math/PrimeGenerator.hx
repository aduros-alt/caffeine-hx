
package math;
import math.BigInteger;
import math.prng.Random;

enum GenState {
	S_INIT;
	S_RUNNING;
	S_SLEEPING;
	S_STOP;
	S_COMPLETE;
}

/**
	Large prime number generation can take a considerable amount of time. This class
	does this calculation in the background, in neko as a thread, and other platforms
	with a haxe.Timer.
	As the calculation proceeds, whenever the method is about to yield, the funciton
	cbIncomplete is called. This function can do nothing, or call stop() on the
	PrimeGenerator passed to it.
	Once generation is complete, the cbFinished method is called with the new
	prime BigInteger as it's param. If the generation is stopped with stop(),
	cbFinished will be called with null.
**/
class PrimeGenerator {
	var state: GenState;
	public var bits(default,null) : Int;
	public var gcdv(default,null) : BigInteger;
	var iter : Int;
	var force: Bool;
	var rng : math.prng.Random;
	var onContinue: PrimeGenerator->Void;
	var onComplete: BigInteger->Void;

#if neko
#else true
	var timer : haxe.Timer;
#end

	/**
		Generates a prime number of [bitSize] bits, optionally forced to that size with [forceLength], with a Greatest Common Denominator [gcdExp].
	**/
	public function new(bitSize:Int,forceLength:Bool,gcdExp:BigInteger,cbIncomplete:PrimeGenerator->Void, cbFinished:BigInteger->Void) {
		this.bits = bitSize;
		this.gcdv = gcdExp;
		this.force = forceLength;
		this.onContinue = cbIncomplete;
		this.onComplete = cbFinished;

		this.state = S_INIT;
		this.iter = 10;
		this.rng = new math.prng.Random();
	}

	/**
		Default number of iterations for the Miller Rabin prime test is 10.
	**/
	public function setIterations(v : Int) {
		this.iter = v;
	}

	/**
		Sets the PRNG to use.
	**/
	public function setRng(v : Random) {
		if(state == S_INIT)
			rng = v;
	}

	public function run() {
		if(state != S_INIT)
			return;
		_pos = 0;

#if neko
		var t = neko.vm.Thread.create(callback(runThread));
#else true
		timer = new haxe.Timer(40);
		timer.run = callback(runThread);
#end
	}

	public function stop() {
		state = S_STOP;
	}

	function runThread() : Void {
		#if CAFFEINE_DEBUG
		trace(here.methodName);
		#end
#if neko
		while(state != S_COMPLETE) {
			genEngine();
		}
#else true
		if(state == S_INIT || state == S_SLEEPING) {
			genEngine();
		}
#end
	}

	function stopTimer() {
		state = S_COMPLETE;
#if !neko
		timer.stop();
#end
	}

	function pauseTimer() {
		#if !neko timer.stop(); #end
	}

	function startTimer() {
		#if !neko
		timer = new haxe.Timer(1000);
		timer.run = callback(runThread);
		#end
	}

	public var _start : Float;
	public static var _endTime : Float;
	private var _pos : Int;
	private var _bi : BigInteger;
	private var _flag4 : Bool;
	private var _flag5 : Bool;
	private var _flag6 : Bool;

	private function timeCheck() : Bool {
		if(Date.now().getTime() >= _endTime) {
			state = S_SLEEPING;
			return false;
		}
		return true;
	}

	private function genEngine() : Void {
		//pauseTimer();
		#if CAFFEINE_DEBUG_FUNCTIONS
		trace(here.methodName);
		#end
		switch(state) {
		case S_INIT:
			if(rng == null)
				rng = new math.prng.Random();
			#if neko
			untyped BigInteger.seedRandom(bits, rng);
			#end
			if(iter < 1) iter = 1;
			state = S_RUNNING;
			_pos = 0;
			ipp_pos = 0;
			#if !neko mr_pos = 0; #end
		case S_SLEEPING:
			state = S_RUNNING;
		case S_RUNNING:
			return;
		case S_STOP:
			onComplete(null);
			stopTimer();
			return;
		case S_COMPLETE:
			return;
		}
		_start = Date.now().getTime();
		_endTime = _start + 4000.0;
trace("Assigned time "+ _endTime);

		while(true) {
			if(_pos == 0) {
				#if neko
					_bi = untyped BigInteger.hndToBigInt(bi_generate_prime(bits, false));
				#else true
					_bi = BigInteger.random(bits, rng);
				#end
				_pos++;
			}
			if(!timeCheck()) break;


			if(_pos == 1) {
				if(force) {
					if (!_bi.testBit(bits-1)) {
						untyped _bi.bitwiseTo(BigInteger.ONE.shl(bits-1), BigInteger.op_or, _bi);
					}
				}
				_pos++;
			}
			if(!timeCheck()) break;


			if(_pos == 2) {
				if (_bi.isEven())
					_bi.dAddOffset(1,0);
				_pos++;
			}
			if(!timeCheck()) break;


			if(_pos == 3) {
				while(_bi.bitLength()>bits) {
					_bi.subTo(BigInteger.ONE.shl(bits-1),_bi);
				}
				_pos++;
				_flag4 = false;
			}
			if(!timeCheck()) break;


			if(_pos == 4) {
				try	{
					_flag4 = isProbablePrime(1);
				}
				catch(e:Float) { gotoSleep(e); return; }
				_pos++;
				_flag5 = false;
				_flag6 = false;
				// forced yield
				gotoSleep(0.41); return;
			}

			if(_pos == 5) {
				#if CAFFEINE_DEBUG
				trace("pos:5 " + " " + _flag4 + " " + _flag5 + " " + _flag6 );
				#end
				while (!_flag4) {
					if(!_flag5) {
						if(!_flag6) {
							_bi.dAddOffset(2,0);
							_flag6 = true;
						}
						while(_bi.bitLength()>bits) {
							_bi.subTo(BigInteger.ONE.shl(bits-1),_bi);
							if(!timeCheck()) { gotoSleep(0.51); return; }
						}
						_flag5 = true;
 						//gotoSleep(0.52); return;
					}
					_flag4 = false;
					try {
						_flag4 = isProbablePrime(1);
					}
					catch(e:Float) {
						gotoSleep(e);
						return;
					};
					_flag5 = false;
					_flag6 = false;
				}
				if(!_flag4) { gotoSleep(0.54); return; };
				_pos++;
			}
			if(!timeCheck() || !_flag4) break;


			if(_pos == 6) {
				if(_bi.sub(BigInteger.ONE).gcd(gcdv).compare(BigInteger.ONE) == 0)
					_pos++;
				else // no good, try again.
					_pos = 0;
			}
			if(!timeCheck()) break;

			if(_pos == 7) {
				var ok : Bool = false;
				try ok = isProbablePrime(iter) catch(e:Float) { gotoSleep(e); return; };
				if(ok) {
					onComplete(_bi.clone());
					stopTimer();
					return;
				}
				// no good, try again.
				_pos = 0;
				gotoSleep(0.61); return;
			}
			if(!timeCheck()) break;
		}
		gotoSleep(_pos/10);
		return;
	}

	function gotoSleep(v:Float) {
		#if CAFFEINE_DEBUG
		trace("Sleeping at state : " + Std.string(v));
		#end
		onContinue(this);
		state = S_SLEEPING;
		//startTimer();
	}

	var ipp_pos : Int;
	var ipp_x : BigInteger;
	var ipp_idx : Int;
	var ipp_ipos : Int;
	var ipp_im:Int;
	var ipp_ij:Int;
	// Throws when timeout.
	function isProbablePrime(v : Int) : Bool {
		#if CAFFEINE_DEBUG_FUNCTIONS
		trace(here.methodName);
		#end
#if neko
		return bi_is_prime(untyped _bi._hnd, v, true);
#else true
		var lowprimes = BigInteger.lowprimes;
		var lplim = BigInteger.lplim;

		if(ipp_pos == 0) {
			#if CAFFEINE_DEBUG
			//trace("ipp_pos 0");
			#end
			ipp_idx = 1;
			ipp_x = _bi.abs();
			ipp_ipos = 0;
			ipp_pos++;
		}
		if(!timeCheck()) throw 1.0;

		if(ipp_pos == 1) {
			#if CAFFEINE_DEBUG
			//trace("ipp_pos 1");
			#end
			if(ipp_x.t == 1 && ipp_x.chunks[0] <= lowprimes[lowprimes.length-1]) {
				ipp_pos = 0; // we are returning. Reset for next call
				for(i in 0...lowprimes.length)
					if(ipp_x.chunks[0] == lowprimes[i]) return true;
				return false;
			}
			ipp_pos++;
		}

		if(ipp_pos == 2) {
			#if CAFFEINE_DEBUG
			//trace("ipp_pos 2");
			#end
			if(ipp_x.isEven()) { ipp_pos = 0; return false; }
			ipp_pos++;
		}
		if(!timeCheck()) throw 1.2;

		if(ipp_pos == 3) {
			#if CAFFEINE_DEBUG
			//trace("ipp_pos 3 "+ ipp_ipos);
			#end
			while(ipp_idx < lowprimes.length) {
				if(ipp_ipos == 0) {
					ipp_im = lowprimes[ipp_idx];
					ipp_ij = ipp_idx+1;
					while(ipp_ij < lowprimes.length && ipp_im < lplim) {
						ipp_im *= lowprimes[ipp_ij];
						ipp_ij++;
					}
					ipp_ipos++;
				}

				if(ipp_ipos == 1) {
					ipp_im = ipp_x.modInt(ipp_im);
					ipp_ipos++;
					//throw 1.4;
				}
				if(!timeCheck()) throw 1.4;

				if(ipp_ipos == 2) {
					var trep = new Repeat(1.5, _endTime);
					while(ipp_idx < ipp_ij) {
						if(ipp_im % lowprimes[ipp_idx] == 0) {
							ipp_ipos = 0;
							ipp_pos = 0;
							return false;
						}
						ipp_idx++;
						trep.canRepeat();
					}
					ipp_ipos++;
					//throw 1.6;
				}
				ipp_ipos = 0;
				if(!timeCheck()) throw 1.7;
			}
			ipp_pos++;
			//throw 1.8;
		}
		ipp_ipos = 0;
		var rv = millerRabin(v);
		ipp_pos = 0;
		return rv;
#end
	}

	/**
	* Reentrant Miller Rabin. mr_pos must be set to 0 before first call.
	*
	*
	**/



#if !neko
	//static var lowprimesBI : Array<BigInteger>; // could replace a.fromInt(lowprimes[i]);
	var mr_pos : Int;
	var mr_n1 : BigInteger;
	var mr_k : Int;
	var mr_r : BigInteger;
	var mr_a : BigInteger;
	var mr_idx : Int;
	var mr_y : BigInteger;
	var mr_j : Int;
	var mr_ipos : Int;
	var mr_remp : REModPow;

	function millerRabin(v:Int) : Bool {
		#if CAFFEINE_DEBUG_FUNCTIONS
		trace(here.methodName + " "+mr_pos + ":"+mr_ipos);
		#end
		var lowprimes = BigInteger.lowprimes;
		if(mr_pos == 0) {
			mr_n1 = _bi.sub(BigInteger.ONE);
			mr_k = mr_n1.getLowestSetBit();
			if(mr_k <= 0) return false;

			mr_a = BigInteger.nbi();
			mr_idx = 0;
			mr_y = null;
			mr_j = 1;

			mr_ipos = 0;
			mr_pos++;
			//throw 2.0;
		}
		if(!timeCheck()) throw 2.0;

		if(mr_pos == 1) {
			mr_r = mr_n1.shr(mr_k);
			v = (v+1)>>1;
			if(v > lowprimes.length) v = lowprimes.length;
			mr_a = BigInteger.nbi();
			mr_pos++;
			//throw 2.1;
		}
		if(!timeCheck()) throw 4.0;

		if(mr_pos == 2) {
			var trep = new Repeat(5.0,_endTime);
			while(mr_idx < v) {
				if(mr_ipos == 0) {
					mr_a.fromInt(lowprimes[mr_idx]);
					if(mr_y == null) {
						if(mr_remp == null) {
							mr_remp = new REModPow(_endTime, mr_a, mr_r, _bi);
						}
						mr_y = mr_remp.run(); //mr_a.modPow(mr_r, _bi);
						mr_remp = null;
					}
					mr_ipos++;
					//throw 2.2;
					trep.canRepeat(2.2);
				}
				if(!timeCheck()) throw 5.0;

				if(mr_ipos == 1) {
					if(mr_y.compare(BigInteger.ONE) != 0 && mr_y.compare(mr_n1) != 0)
						mr_ipos = 2;
					else mr_ipos = 4;
					//throw 2.3;
					trep.canRepeat(2.3);
				}
				if(!timeCheck()) throw 5.0;

				if(mr_ipos == 2) {
					var trep2 = new Repeat(2.4, _endTime);
					while(mr_j++ < mr_k && mr_y.compare(mr_n1) != 0) {
						mr_y = mr_y.modPowInt(2,_bi);
						if(mr_y.compare(BigInteger.ONE) == 0) {
							mr_pos = 0;
							return false;
						}
						trep2.canRepeat();
					}
					mr_ipos++;
				}
				trep.canRepeat(2.6);
				//if(!timeCheck()) throw 2.6;

				if(mr_ipos == 3) {
					if(mr_y.compare(mr_n1) != 0) {
						mr_pos = 0;
						return false;
					}
					mr_ipos++;
				}

				mr_y = null;
				mr_j = 1;
				mr_idx++;
				mr_ipos = 0;
				if(!timeCheck()) throw 2.8;
			}
			mr_pos++;
		}
		mr_pos = 0;
		return true;
	}























#end




#if neko
	private static var bi_is_prime=neko.Lib.load("openssl","bi_is_prime",3);
	private static var bi_generate_prime=neko.Lib.load("openssl","bi_generate_prime",2);
#end
}

#if !neko


class Repeat {
	var v : Float;
	var start : Float;
	var hardLimit : Float;

	var last : Float;
	var longest: Float;

	public function new(mark:Float, hLimit:Float) {
		start = Date.now().getTime();
		v = mark;
		hardLimit = hLimit;
		last = start;
		longest = 0;
	}

	public function canRepeat(?iv:Float) : Bool {
		if(iv == null)
			iv = v;
		var n = Date.now().getTime();

		var l = n - last;
		if(l > longest)
			longest = l;

		// next iter takes us over the hardLimit?
		if(longest + n > hardLimit)
			throw iv;

		// 5 second rule. ;)
		if((n - start) >= 5000.0)
			throw iv;

		return true;
	}
}


import math.reduction.ModularReduction;
import math.reduction.Classic;
import math.reduction.Barrett;
import math.reduction.Montgomery;

class REModPow {
	var _pos : Int;
	var _ipos : Int;
	var _jpos : Int;
	var timeLimit : Float;
	var DB : Int;
	var _bi : BigInteger;
	var e : BigInteger;
	var m : BigInteger;
	var i : Int;
	var k : Int;
	var r : BigInteger;
	var z : ModularReduction;
	var g : Array<BigInteger>;
	var n : Int;
	var k1 : Int;
	var km : Int;

	var j : Int;
	var w : Int;
	var is1 : Bool;
	var g2 : BigInteger;
	var r2 : BigInteger;
	var t : BigInteger;

	public function new(endT:Float, bi : BigInteger, be:BigInteger, bm:BigInteger) {
		DB = BigInteger.DB;
		_bi = bi;
		e = be;
		m = bm;
		i = e.bitLength();
		r = BigInteger.nbv(1);
		timeLimit = endT;
		_pos = 0;
	}

	function checkTime(v:Float) {
// 		if(timeLimit != PrimeGenerator._endTime) {
// 			trace( PrimeGenerator._endTime);
// 			trace(timeLimit);
// 			trace(Date.now().getTime());
// 			throw "ERROR";
// 		}
		var t = Date.now().getTime();
		if(t >= PrimeGenerator._endTime) {
			throw v;
		}
	}

	public function run() : BigInteger {
		if(_pos == 0) {
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
			g = new Array<BigInteger>();
			n = 3;
			k1 = k-1;
			km = (1<<k)-1;
			g[1] = z.convert(_bi);
			g2 = BigInteger.nbi();
			_pos++;
		}
		checkTime(10.0);

		if(_pos == 1) {
			if(k > 1) {
				z.sqrTo(g[1],g2);
				_pos = 2;
			}
			else
				_pos = 3;
		}
		checkTime(10.1);

		if(_pos == 2) {
			while(n <= km) {
				g[n] = BigInteger.nbi();
				z.mulTo(g2,g[n-2],g[n]);
				n += 2;
				checkTime(10.2);
			}
		}

		if(_pos == 3) {
			j = e.t-1;
			w = 0;
			is1 = true;
			r2 = BigInteger.nbi();
			t = null;
			i = BigInteger.nbits(e.chunks[j])-1;
			_pos++;
			_ipos = 0;
		}
		checkTime(10.3);

		if(_pos == 4) {
			while(j >= 0) {
				if(_ipos == 0) {
					if(i >= k1) w = (e.chunks[j]>>(i-k1))&km;
					else {
						w = (e.chunks[j]&((1<<(i+1))-1))<<(k1-i);
						if(j > 0) w |= e.chunks[j-1]>>(DB+i-k1);
					}
					_ipos++;
				}
				checkTime(10.40);

				if(_ipos == 1) {
					n = k;
					while((w&1) == 0) { w >>= 1; --n; }
					if((i -= n) < 0) { i += DB; --j; }
					_ipos++;
				}
				checkTime(10.41);

				if(_ipos == 2) {
					if(is1) {	// ret == 1, don't bother squaring or multiplying it
						g[w].copyTo(r);
						is1 = false;
						_ipos++; // skip ipos 3
					}
					_ipos++;
					_jpos=0;
				}
				checkTime(10.42);

				if(_ipos == 3) {
					if(_jpos == 0) {
						while(n > 1) { z.sqrTo(r,r2); z.sqrTo(r2,r); n -= 2; }
						_jpos++;
					}
					if(_jpos == 1) {
						if(n > 0) z.sqrTo(r,r2);
						else { t = r; r = r2; r2 = t; }
						_jpos++;
					}
					if(_jpos == 2) {
						z.mulTo(r2,g[w],r);
						_jpos++;
					}
					_jpos = 0;
					_ipos++;
				}
				checkTime(10.43);

				if(_ipos==4) {
					// chnk as part of the while loop creates a verify error.
					var chnk : Int = e.chunks[j];
					while(j >= 0 && (chnk&(1<<i) == 0)) {
						z.sqrTo(r,r2);
						t = r; r = r2; r2 = t;
						if(--i < 0) { i = DB-1; --j; }
						chnk = e.chunks[j];
						checkTime(10.44);
					}
				}
				_ipos = 0;
				checkTime(10.45);
			}
			_pos++;
		}
		checkTime(10.5);
		return z.revert(r);
	}
}
#end
