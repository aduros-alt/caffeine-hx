
class StringFunctions extends haxe.unit.TestCase {
	function testHelloWorld() {
		assertEquals(
			"@@ -1,1 +1,1 @@\n-Hello world\n+Hello world\n\\ No newline at end of file\n",
			xdiff.Tools.diff("Hello world\n","Hello world")
		);
	}

	function testNull() {
		assertEquals(
			"", 
			xdiff.Tools.diff("","")
		);
	}

}

class XdiffTest {
	static function main() 
	{
		var r = new haxe.unit.TestRunner();
		r.add(new StringFunctions());
		r.run();

		/*
		var hw = xdiff.Tools.diff("Hello world\n","Hello world");
		trace(hw);
		trace(ByteStringTools.hexDump(hw));

		trace("\n\nnull test");
		var nt = xdiff.Tools.diff("","");
		trace(ByteStringTools.hexDump(nt));
		*/
	}
}
