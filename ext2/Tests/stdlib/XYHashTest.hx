
class XYHashTest extends haxe.unit.TestCase {

	function dump(h:XYHash<String>) {
		for(x in h.keys()) {
			trace("X[" + Std.string(x)+"]");
			var a = h.getRow(x);
			for(y in a.keys()) {
				var b = h.get(x,y);
				trace("  Y["+ Std.string(y) +"] :" + b);
			}
		}
	}

	function testOne() {
		var h = new XYHash<String>();

		h.set(0,0, "Hello world");
		h.set(1,0, "Hi");
		h.set(1,1, "There");
		assertEquals("Hi", h.get(1,0));
		trace("");
		dump(h);
		h.remove(1,0);
		trace("");
		dump(h);
		h.remove(1,1);
		trace("");
		dump(h);
		h.compact();
		trace("--compacted--");
		dump(h);
	}
}