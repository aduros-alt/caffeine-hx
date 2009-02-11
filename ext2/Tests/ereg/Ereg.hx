import chx.RegEx;

class HaxeEregTest  extends haxe.unit.TestCase {
	static var doTests :Array<String> = [];

	static var dog = "a dog went a runnin after the ball";
	static var pool = "Go swim in the pool after school";
	static var email = "me@there.com";
	static var http = "http://www.google.com";
	static var pipe = "|";

	static var rn : EReg;
	static var rh : RegEx;

	static var pattern : String;
	static var opts : String = "ig";
	static var source : String;

	static function runTest(name:String) {
		if(doTests.length == 0)
			return true;
		for(i in doTests)
			if(i == name)
				return true;
		return false;
	}

	function testDeepNoMatch() {
		if(!runTest(here.methodName)) {
			assertTrue(true);
			return;
		}
		pattern = "((a{0,5}){0,5})*[c]";
		opts = "i";
		source = "aaaaaaaaaaaa";
		trace("--------------------- " + here.methodName + " ---- " +pattern+ " ----- " +source+ " -----------------");

		assertVersionsFalse();
	}

	function testStar() {
		if(!runTest(here.methodName)) {
			assertTrue(true);
			return;
		}

		pattern = "[^e]*e*";
		opts = "ig";
		source = "abcdeeeeefghi";
		trace("--------------------- " + here.methodName + " ---- " +pattern+ " ----- " +source+ " -----------------");

		assertVersions();
		assertMatch(0, "abcdeeeee");
		assertPosLen(0,9);
		assertLeft("");
		assertRight("fghi");

	}

	function testStarNotGreedy() {
		if(!runTest(here.methodName)) {
			assertTrue(true);
			return;
		}

		pattern = "[^e]*e*?";
		opts = "i";
		source = "abcdeeeeefghi";
		trace("--------------------- " + here.methodName + " ---- " +pattern+ " ----- " +source+ " -----------------");

		assertVersions();
		assertMatch(0, "abcd");
		assertPosLen(0,4);
		assertLeft("");
		assertRight("eeeeefghi");

		pattern = "[^e]*e*?f";
		opts = "i";
		source = "abcdeeeeefghi";
		trace("--------------------- " + here.methodName + " ---- " +pattern+ " ----- " +source+ " -----------------");

		assertVersions();
		assertMatch(0, "abcdeeeeef");
		assertPosLen(0,10);
		assertLeft("");
		assertRight("ghi");
	}

	function testOrMatch() {
		if(!runTest(here.methodName)) {
			assertTrue(true);
			return;
		}

		pattern = "(fee|fie|foe)";
		opts = "i";
		source = "foe fum";

		trace("--------------------- " + here.methodName + " ---- " +pattern+ " ----- " +source+ " -----------------");
		assertVersions();
		assertMatch(0, "foe");

		pattern = "c(a|at)b$";
		source = "catb";

		trace("--------------------- " + here.methodName + " ---- " +pattern+ " ----- " +source+ " -----------------");
		assertVersions();
		assertMatch(0, "catb");
		assertMatch(1, "at");
	}

	function testAnyMatch() {
		if(!runTest(here.methodName)) {
			assertTrue(true);
			return;
		}

		pattern = ".";
		opts = "i";
		source = "cat";

		trace("--------------------- " + here.methodName + " ---- " +pattern+ " ----- " +source+ " -----------------");

		assertVersions();
		assertMatch(0, "c");
	}


	function testOne() {
		if(!runTest(here.methodName)) {
			assertTrue(true);
			return;
		}

		pattern = "c";
		opts = "i";
		source = "abcde";
		trace("--------------------- " + here.methodName + " ---- " +pattern+ " ----- " +source+ " -----------------");

		assertVersions();
		assertMatch(0, "c");
		assertLeft("ab");
		assertRight("de");
	}

	function testTwo() {
		if(!runTest(here.methodName)) {
			assertTrue(true);
			return;
		}

		pattern = "http://(www)";
		opts = "i";
		source = "http://www.Google.com";
		trace("--------------------- " + here.methodName + " ---- " +pattern+ " ----- " +source+ " -----------------");

		assertVersions();

		assertMatch(0, "http://www");
		assertMatch(1, "www");
		assertLeft("");
		assertRight(".Google.com");
	}

	function testThree() {
		if(!runTest(here.methodName)) {
			assertTrue(true);
			return;
		}

		pattern = "^a d(.{1,2}) ";
		opts = "i";
		source = dog;
		trace("--------------------- " + here.methodName + " ---- " +pattern+ " ----- " +source+ " -----------------");

		assertVersions();
		assertMatch(0, "a dog ");
		assertMatch(1, "og");
		assertLeft("");

		pattern = "^a d([.]{1,2}) ";
		assertVersionsFalse();
		source = "a d.. ";

		assertVersions();
		assertMatch(0, "a d.. ");
		assertMatch(1, "..");
	}

	function testFour() {
		if(!runTest(here.methodName)) {
			assertTrue(true);
			return;
		}

		pattern = "(bc+d$|ef*g.|h?i(j|k))";
		opts = "i";
		source = "ij";
		trace("--------------------- " + here.methodName + " ---- " +pattern+ " ----- " +source+ " -----------------");

		assertVersions();
		assertMatch(0, "ij");
		assertMatch(1, "ij");
		assertMatch(2, "j");
		assertLeft("");
		assertRight("");
	}

	function testFive() {
		if(!runTest(here.methodName)) {
			assertTrue(true);
			return;
		}

		pattern = "(bc+d$|ef*g.|h?i(j|k))";
		opts = "i";
		source = "effgz";
		trace("--------------------- " + here.methodName + " ---- " +pattern+ " ----- " +source+ " -----------------");

		assertVersions();
		assertMatch(0, "effgz");
		assertMatch(1, "effgz");
		//assertMatch(2, "j");
		assertLeft("");
		assertRight("");
	}

	function testSix() {
		if(!runTest(here.methodName)) {
			assertTrue(true);
			return;
		}

		pattern = "a[b-]";
		opts = "i";
		source = "A-";
		trace("--------------------- " + here.methodName + " ---- " +pattern+ " ----- " +source+ " -----------------");

		assertVersions();
		assertMatch(0, "A-");
		assertLeft("");
		assertRight("");
	}

	function testSeven() {
		if(!runTest(here.methodName)) {
			assertTrue(true);
			return;
		}

		pattern = "\\xff";
		opts = "i";
		source = String.fromCharCode(0xFF);
		trace("--------------------- " + here.methodName + " ---- " +pattern+ " ----- " +source+ " -----------------");

		assertVersions();
		assertMatch(0, String.fromCharCode(0xFF));
		assertLeft("");
		assertRight("");
	}

	function testEight() {
		if(!runTest(here.methodName)) {
			assertTrue(true);
			return;
		}

		pattern = "^*";
		opts = "i";
		source = "qweriu";
		trace("--------------------- " + here.methodName + " ---- " +pattern+ " ----- " +source+ " -----------------");

		assertTrue(isSyntaxError());
	}


	function testNine() {
		if(!runTest(here.methodName)) {
			assertTrue(true);
			return;
		}

		pattern = "(([a-z]+):)?([a-z]+)$";
		opts = "i";
		source = "smil";
		trace("--------------------- " + here.methodName + " ---- " +pattern+ " ----- " +source+ " -----------------");

		assertVersions();
		assertMatch(0, "smil");
		assertMatch(3, "smil");
	}

	function testTen() {
		if(!runTest(here.methodName)) {
			assertTrue(true);
			return;
		}

		pattern = "(?i)([a-c]*)\\1";
		opts = "";
		source = "ABCABC";
		trace("--------------------- " + here.methodName + " ---- " +pattern+ " ----- " +source+ " -----------------");

		assertVersions();
		assertMatch(0, "ABCABC");
		assertMatch(1, "ABC");
	}

	function testEleven() {
		if(!runTest(here.methodName)) {
			assertTrue(true);
			return;
		}

		pattern = "(x?)?";
		opts = "";
		source = "x";
		trace("--------------------- " + here.methodName + " ---- " +pattern+ " ----- " +source+ " -----------------");

		assertVersions();
		assertMatch(0, "x");
		assertMatch(1, "x");
	}

	function testTwelve() {
		if(!runTest(here.methodName)) {
			assertTrue(true);
			return;
		}

		pattern = "a*";
		opts = "";
		source = "";
		trace("--------------------- " + here.methodName + " ---- " +pattern+ " ----- " +source+ " -----------------");

		assertVersions();
		assertMatch(0, "");
	}


	function testThirteen() {
		if(!runTest(here.methodName)) {
			assertTrue(true);
			return;
		}

		pattern = "(?P<foo_123>a)";
		opts = "";
		source = "a";
		trace("--------------------- " + here.methodName + " ---- " +pattern+ " ----- " +source+ " -----------------");

		assertVersions();
		assertMatch(0, "a");
	}

	function testFourteen() {
		if(!runTest(here.methodName)) {
			assertTrue(true);
			return;
		}

		pattern = "(a+|b)*";
		opts = "";
		source = "ab";
		trace("--------------------- " + here.methodName + " ---- " +pattern+ " ----- " +source+ " -----------------");

		assertVersions();
		assertMatch(0, "ab");
		assertMatch(1, "b");
	}

	function testFifteen() {
		if(!runTest(here.methodName)) {
			assertTrue(true);
			return;
		}

		pattern = "a(?!b).";
		opts = "";
		source = "abad";
		trace("--------------------- " + here.methodName + " ---- " +pattern+ " ----- " +source+ " -----------------");

		assertVersions();
		assertMatch(0, "ad");
	}

	function testSixteen() {
		if(!runTest(here.methodName)) {
			assertTrue(true);
			return;
		}

		pattern = "(?m)abc$";
		opts = "";
		source = "jkl\nxyzabc\n123";
		trace("--------------------- " + here.methodName + " ---- " +pattern+ " ----- " +source+ " -----------------");

		assertVersions();
		assertMatch(0, "abc");
	}

	function testWhitespace() {
		if(!runTest(here.methodName)) {
			assertTrue(true);
			return;
		}

		pattern = "(?x)w# comment 1\n        x y\n        # comment 2\n        z";
		opts = "";
		source = "wxyz";
		trace("--------------------- " + here.methodName + " ---- " +pattern+ " ----- " +source+ " -----------------");

		assertVersions();
		assertMatch(0, "wxyz");
	}

	function testSingleOr() {
		if(!runTest(here.methodName)) {
			assertTrue(true);
			return;
		}

		pattern = "a|b";
		opts = "ig";
		source = "boy";
		trace("--------------------- " + here.methodName + " ---- " +pattern+ " ----- " +source+ " -----------------");

		assertVersions();
		assertMatch(0, "b");
		assertRight("oy");
	}

	function testDoubleOr() {
		if(!runTest(here.methodName)) {
			assertTrue(true);
			return;
		}

		pattern = "a|b|c";
		opts = "ig";
		source = "cat";
		trace("--------------------- " + here.methodName + " ---- " +pattern+ " ----- " +source+ " -----------------");

		assertVersions();
		assertMatch(0, "c");
		assertRight("at");
		assertPosLen(0, 1);

		pattern = "a|b|c";
		opts = "ig";
		source = "ercr";
		trace("--------------------- " + here.methodName + " ---- " +pattern+ " ----- " +source+ " -----------------");

		assertVersions();
		assertMatch(0, "c");
		assertRight("r");
		assertPosLen(2, 1);

	}

	function testDoubleOr2() {
		if(!runTest(here.methodName)) {
			assertTrue(true);
			return;
		}

		pattern = "(a|b|c)at";
		opts = "ig";
		source = "  cat";
		trace("--------------------- " + here.methodName + " ---- " +pattern+ " ----- " +source+ " -----------------");

		assertVersions();
		assertMatch(0, "cat");
		assertLeft("  ");
		assertRight("");
		assertPosLen(2, 3);
	}

	function testNot() {
		if(!runTest(here.methodName)) {
			assertTrue(true);
			return;
		}

		pattern = "^[^a]";
		opts = "ig";
		source = dog;
		trace("--------------------- " + here.methodName + " ---- " +pattern+ " ----- " +source+ " -----------------");

		assertVersionsFalse();
	}

	function testWwwHaxeOrg() {
		if(!runTest(here.methodName)) {
			assertTrue(true);
			return;
		}

		pattern = "^(([^:\\/?#]+):)?(\\/\\/([^\\/?#]*))?([^?#]*)(\\?([^#]*))?(#(.*))?";
		opts = "ig";
		source = "http://www.haxe.org";
		trace("--------------------- " + here.methodName + " ---- " +pattern+ " ----- " +source+ " -----------------");

		assertTrue(nativeVersion());
		assertVersions();
		assertMatch(0, "http://www.haxe.org");

	}

	function testMailto() {
		if(!runTest(here.methodName)) {
			assertTrue(true);
			return;
		}

		pattern = "^(([^:\\/?#]+):)?(\\/\\/([^\\/?#]*))?([^?#]*)(\\?([^#]*))?(#(.*))?";
		opts = "ig";
		source = "mailto:me@there.com";
		trace("--------------------- " + here.methodName + " ---- " +pattern+ " ----- " +source+ " -----------------");

		assertTrue(nativeVersion());
		assertVersions();
		assertMatch(0, "mailto:me@there.com");

	}

	function testFileUri() {
		if(!runTest(here.methodName)) {
			assertTrue(true);
			return;
		}

		pattern = "^(([^:\\/?#]+):)?(\\/\\/([^\\/?#]*))?([^?#]*)(\\?([^#]*))?(#(.*))?";
		opts = "ig";
		source = "/usr/bin/haxe";
		trace("--------------------- " + here.methodName + " ---- " +pattern+ " ----- " +source+ " -----------------");

		assertTrue(nativeVersion());
		assertVersions();
		assertMatch(0, "/usr/bin/haxe");

	}
/*
	public static function doTraces() {
		var e = ~/^^a/;
		nativeVersion("^^a", dog);
		nativeVersion("^[^a]", dog);

		nativeVersion("^^a", pool);
		nativeVersion("^[^ag]", pool);


		trace("-- next --");
		haxeVersion("[.]{1,2}", dog);

		trace("-- next --");
		haxeVersion("http:(//([^/?#]*))?", http);

		trace("-- next --");
		haxeVersion("aA", dog);

		trace("-- Pipe test native --");
		nativeVersion("|", pipe);

		trace("-- Pipe test haxe --");
		haxeVersion("|", pipe);


	}
*/

	static function nativeVersion() : Bool {
		rn = new EReg(pattern, opts);
		return rn.match(source);
	}


	static function haxeVersion() : Bool {
		rh = new RegEx(pattern, opts);
		return rh.match(source);
	}


	static function traceIt<T>(re : T) {
		var i = 0;
		while(true) {
			try {
				trace("match("+i+"): " + untyped re.matched(i++));
			} catch(e:Dynamic) {
				break;
			}
		}
	}

	function isSyntaxError() {
		try {
			haxeVersion();
			return false;
		} catch(e:Dynamic) {}
		try {
			nativeVersion();
			return false;
		} catch(e:Dynamic) {}
		return true;
	}

	function assertVersions() {
		assertTrue(nativeVersion());
		assertTrue(haxeVersion());
	}

	function assertVersionsFalse() {
		assertFalse(haxeVersion());
		assertFalse(nativeVersion());
	}

	function assertMatch(n:Int, v : String) {
		assertEquals(v, rn.matched(n));
		assertEquals(v, rh.matched(n));
	}

	function assertLeft(v : String) {
		assertEquals(v, rn.matchedLeft());
		assertEquals(v, rh.matchedLeft());
	}

	function assertRight(v : String) {
		assertEquals(v, rn.matchedRight());
		assertEquals(v, rh.matchedRight());
	}

	function assertPosLen(pos : Int, len : Int) {
		var rv = rn.matchedPos();
		assertEquals(pos, rv.pos);
		assertEquals(len, rv.len);
		rv = rh.matchedPos();
		assertEquals(pos, rv.pos);
		assertEquals(len, rv.len);
	}

}


class Ereg {
        static function main()
        {
		#if !neko
                if(haxe.Firebug.detect()) {
                        haxe.Firebug.redirectTraces();
               	}
		#end

		#if neko
			HaxeEregTest.doTests = neko.Sys.args();
		#end

                var r = new haxe.unit.TestRunner();
                r.add(new HaxeEregTest());

                r.run();
        }
}

