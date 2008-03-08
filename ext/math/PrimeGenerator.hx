
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
		timer = new haxe.Timer(1000);
		timer.run = callback(genEngine);
#end
	}

	public function stop() {
		state = S_STOP;
	}

#if neko
	function runThread() : Void {
		while(state != S_COMPLETE) {
			genEngine();
		}
	}
#end

	function stopTimer() {
		state = S_COMPLETE;
#if !neko
		timer.stop();
#end
	}

	private var _start : Float;
	private var _pos : Int;
	private var _bi : BigInteger;

	private function timeCheck() {
		if(Date.now().getTime() >= _start + 5000) {
			state = S_SLEEPING;
			return false;
		}
		return true;
	}

	private function genEngine() : Void {
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
			mr_pos = 0;
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
			}
			if(!timeCheck()) break;


			if(_pos == 4) {
				var ok : Bool = false;
				try	ok = isProbablePrime(1) catch(e:Int) break;
				while (!ok) {
					_bi.dAddOffset(2,0);
					while(_bi.bitLength()>bits) _bi.subTo(BigInteger.ONE.shl(bits-1),_bi);
					if(!timeCheck()) break;
					ok = false;
					try ok = _bi.isProbablePrime(1) catch(e:Int) break;
				}
				if(!ok) break;
				_pos++;
			}
			if(!timeCheck()) break;


			if(_pos == 5) {
				if(_bi.sub(BigInteger.ONE).gcd(gcdv).compare(BigInteger.ONE) == 0)
					_pos++;
				else // no good, try again.
					_pos = 0;
			}
			if(!timeCheck()) break;

			if(_pos == 6) {
				var ok : Bool = false;
				try ok = isProbablePrime(iter) catch(e:Int) break;
				if(ok) {
					onComplete(_bi.clone());
					stopTimer();
					return;
				}
				// no good, try again.
				_pos = 0;
			}
		}
		onContinue(this);
		return;
	}



	var ipp_pos : Int;
	var ipp_x : BigInteger;
	var ipp_idx : Int;
	// Throws when timeout.
	function isProbablePrime(v : Int) : Bool {
#if neko
		return bi_is_prime(untyped _bi._hnd, v, true);
#else true
		var lowprimes = BigInteger.lowprimes;
		var lplim = BigInteger.lplim;

		if(ipp_pos == 0) {
			ipp_idx = 1;
			ipp_x = _bi.abs();
			ipp_pos++;
		}
		if(!timeCheck()) throw 1;

		if(ipp_pos == 1) {
			if(ipp_x.t == 1 && ipp_x.chunks[0] <= lowprimes[lowprimes.length-1]) {
				ipp_pos = 0; // we are returning. Reset for next call
				for(i in 0...lowprimes.length)
					if(ipp_x.chunks[0] == lowprimes[i]) return true;
				return false;
			}
			ipp_pos++;
		}

		if(ipp_pos == 2) {
			if(ipp_x.isEven()) { ipp_pos = 0; return false; }
			ipp_pos++;
		}
		if(!timeCheck()) throw 2;

		if(ipp_pos == 3) {
			while(ipp_idx < lowprimes.length) {
				var m:Int = lowprimes[ipp_idx];
				var j:Int = ipp_idx+1;
				while(j < lowprimes.length && m < lplim) {m *= lowprimes[j]; j++;}
				m = ipp_x.modInt(m);
				while(ipp_idx < j) {
					if(m%lowprimes[ipp_idx] == 0) { ipp_pos = 0; return false; }
					ipp_idx++;
				}
				if(!timeCheck()) throw 3;
			}
			ipp_pos++;
		}

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

	//static var lowprimesBI : Array<BigInteger>; // could replace a.fromInt(lowprimes[i]);
	var mr_pos : Int;
	var mr_n1 : BigInteger;
	var mr_k : Int;
	var mr_r : BigInteger;
	var mr_a : BigInteger;
	var mr_idx : Int;
	var mr_y : BigInteger;
	var mr_j : Int;

#if !neko
	function millerRabin(v:Int) : Bool {
		var lowprimes = BigInteger.lowprimes;
		if(mr_pos == 0) {
			mr_n1 = _bi.sub(BigInteger.ONE);
			mr_k = mr_n1.getLowestSetBit();
			if(mr_k <= 0) return false;

			mr_a = BigInteger.nbi();
			mr_idx = 0;
			mr_y = null;
			mr_j = 1;
			mr_pos++;
		}

		if(mr_pos == 1) {
			mr_r = mr_n1.shr(mr_k);
			v = (v+1)>>1;
			if(v > lowprimes.length) v = lowprimes.length;
			mr_a = BigInteger.nbi();
			mr_pos++;
		}
		if(!timeCheck()) throw 4;

		if(mr_pos == 2) {
			while(mr_idx < v) {
				mr_a.fromInt(lowprimes[mr_idx]);
				if(mr_y == null)
					mr_y = mr_a.modPow(mr_r, _bi);
				if(!timeCheck()) throw 5;

				if(mr_y.compare(BigInteger.ONE) != 0 && mr_y.compare(mr_n1) != 0) {
					while(mr_j++ < mr_k && mr_y.compare(mr_n1) != 0) {
						mr_y = mr_y.modPowInt(2,_bi);
						if(mr_y.compare(BigInteger.ONE) == 0) {
							mr_pos = 0;
							return false;
						}
						if(!timeCheck()) throw 6;
					}
					if(mr_y.compare(mr_n1) != 0) {
						mr_pos = 0;
						return false;
					}
				}
				mr_y = null;
				mr_j = 1;
				mr_idx++;
				if(!timeCheck()) throw 7;
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

