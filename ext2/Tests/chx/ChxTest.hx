import config.DotConfig;


enum Num {
	ONE;
	TWO;
	NUM(n : Num);
}

typedef Ctx = {
	var s : String;
	var ctx : Ctx;
	var num : Num;
}

class ChxTests extends haxe.unit.TestCase {
	function testCachedSerializer() {
		var a : Ctx = {
			s: "This is a",
			ctx : null,
			num : ONE,
		}
		var b : Ctx = {
			s: "This is b",
			ctx : a,
			num : NUM(TWO),
		}
		a.ctx = b;

		var ctxArray = [a, b];

		var ser = chx.CachedSerializer.run(ctxArray);
		//trace(ser);
		ctxArray = haxe.Unserializer.run(ser);

		//trace(ctxArray);
		assertEquals(ctxArray[0].s, "This is a");
		assertEquals(ctxArray[0].ctx.s, "This is b");
		assertEquals(ctxArray[1].s, "This is b");
		assertEquals(ctxArray[1].ctx.s, "This is a");

		switch(ctxArray[0].ctx.num) {
		case ONE: assertEquals(true, false);
		case TWO: assertEquals(true, false);
		case NUM(n): 
			switch(n) {
			case ONE: assertEquals(true, false);
			case TWO:
			case NUM(f): assertEquals(true, false);
			}
		}
	}
}

class ChxTest {
	static function main() 
	{
		chx.Log.redirectTraces(false);
		var r = new haxe.unit.TestRunner();
		r.add(new ChxTests());
		r.run();
	}
}
