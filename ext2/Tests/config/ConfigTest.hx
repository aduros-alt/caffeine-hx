import config.DotConfig;

class DotConfigFunctions extends haxe.unit.TestCase {
	function testDotAccess() {
		var dc = new DotConfig();
		dc.loadFile("SampleDotConfig.txt");

		assertEquals(
			"10.0.0.103",
			dc.section("Hive").section("Master").get("Host")
		);

		assertEquals(
			"5656",
			dc.section("Hive").section("Master").get("Port")
		);
		assertEquals(
			"my secret passphrase",
			dc.section("RecordServer").section("1").get("Password")
		);
	}
}

class ConfigTest {
	static function main() 
	{
		var r = new haxe.unit.TestRunner();
		r.add(new DotConfigFunctions());
		r.run();
		/*
		var dc = new DotConfig();
		dc.loadFile("SampleDotConfig.txt");
		trace(dc);
		*/
	}
}
