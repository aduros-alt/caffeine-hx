
class StdParseInt extends haxe.unit.TestCase {
	function testDecimal() {
		assertEquals(12, Std.parseInt("+12"));
		assertEquals(12, Std.parseInt("12"));
		assertEquals(-12, Std.parseInt("-12"));
	}

	function testNotOctal() {
		assertEquals(-13, Std.parseInt("-013"));
		assertEquals(13, Std.parseInt("+013")); // F9=13
		assertEquals(13, Std.parseInt("013"));  
	}

	function testOctal() {
		assertEquals(-11, Std.parseOctal("-013"));
		assertEquals(11, Std.parseOctal("+013")); // F9=13
		assertEquals(11, Std.parseOctal("013"));  
	}

	function testHex() {
		assertEquals(16, Std.parseInt("0x10"));
		assertEquals(-16, Std.parseInt("-0x10")); // neko 0 // F8 = null
	}
}


class MiscTest {
	static function main()
	{
#if js	// JS Only, cause of sandbox violations for local flash files...
		if(haxe.Firebug.detect()) {
			haxe.Firebug.redirectTraces();
		}
#end
		// Before any other tests, make sure isFunction actually works
		try {
			var t = new ReflectTest();
			t.currentTest = new haxe.unit.TestStatus();
			t.test_isFunction();
		}
		catch(e:Dynamic) {
			trace("Reflect.isFunction failed and threw exception: "+e);
			for(f in Reflect.fields(e)) trace(f +': '+ Reflect.field(e,f) );
		}
		
		var r = new haxe.unit.TestRunner();
		r.add(new StdParseInt());
		r.add(new ReflectTest());
		r.add(new TestReflect());
		r.add(new TypeTest());
		r.run();
	}
}


