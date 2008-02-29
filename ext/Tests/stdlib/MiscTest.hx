
class StdParseInt extends haxe.unit.TestCase {
	function testDecimal() {
		assertEquals(12, Std.parseInt("+12"));
		assertEquals(12, Std.parseInt("12"));
		assertEquals(-12, Std.parseInt("-12"));
	}

	// neko fails on all octal
	function testOctal() {
		assertEquals(-11, Std.parseInt("-013"));
		assertEquals(11, Std.parseInt("+013")); // F9=13
		assertEquals(11, Std.parseInt("013"));  
	}

	function testHex() {
		assertEquals(16, Std.parseInt("0x10"));
		assertEquals(-16, Std.parseInt("-0x10")); // neko 0 // F8 = null
	}
}


class MiscTest {
	static function main()
	{
#if !neko
		if(haxe.Firebug.detect()) {
			haxe.Firebug.redirectTraces();
		}
#end
		var r = new haxe.unit.TestRunner();
		r.add(new StdParseInt());
		r.run();
	}
}


