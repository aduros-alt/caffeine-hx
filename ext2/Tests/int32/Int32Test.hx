import haxe.Int32;
import haxe.Int32Util;

class Basics extends haxe.unit.TestCase {
	function test01() {
		var one = Int32.ofInt(1);
		var negOne = Int32.ofInt(-1);
		var shouldBeOne = Int32Util.abs(negOne);
		assertEquals(0, Int32.compare(one, shouldBeOne));
	}
}

class Int32Test {
	static function main()
	{
#if !neko
		if(haxe.Firebug.detect()) {
			haxe.Firebug.redirectTraces();
		}
#end
		var r = new haxe.unit.TestRunner();
 		r.add(new Basics());
 		r.run();
	}
}


