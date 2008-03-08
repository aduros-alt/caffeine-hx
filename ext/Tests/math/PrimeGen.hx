import math.PrimeGenerator;
import math.BigInteger;

class PrimeGen {
	static var complete : Bool = false;
	public function new() {
		var pg = new PrimeGenerator(640, true, BigInteger.ofInt(3),waiting,done);
		pg.run();
#if neko
		while(!complete) {}
#end
	}

	function waiting(v : PrimeGenerator) : Void {
		var i:Int = untyped v._pos;
		trace("waiting..."+ i);
	}

	function done(i:BigInteger) : Void {
		trace("Have BigInteger");
		trace(i.toString());
		complete = true;
	}

	public static function main() {
#if !neko
		if(haxe.Firebug.detect())
			haxe.Firebug.redirectTraces();
#end

		var i = new PrimeGen();
	}
}
