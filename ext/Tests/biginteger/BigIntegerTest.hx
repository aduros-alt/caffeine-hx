import math.BigInteger;

class Functions extends haxe.unit.TestCase {

	public static function decVal(i:BigInteger) {
		return i.toRadix(10);
	}

	public static function hexVal(i:BigInteger) {
		return i.toRadix(16);
	}

	public function test0() {
		var i = BigInteger.ONE.add(BigInteger.ofInt(9));
		var b = BigInteger.nbi();
		b.fromString("10",10);
		i.eq(b);
		assertEquals(true,true);
		b.toRadix(10);
	}

	public function test1() {
		var i = BigInteger.ONE.add(BigInteger.ofInt(9));
		//trace(i.chunks);
		var b = BigInteger.nbi();
		b.fromString("10",10);
		//trace(b.chunks);
		assertEquals(true, i.eq(b));
		assertEquals("10",decVal(b));
	}

// 		Lest shifts one diplaying binary up to 60 lsh.
// 		Right shifts back tracing Hexadecimal
	public function testRshLsh() {
		var i = BigInteger.ONE;
		trace(i.toRadix(2));
		for(x in 0...60) {
			i = i.shl(1);
			trace(Std.string(x) + " " + i.toRadix(2));
		}
		assertEquals("1000000000000000", i.toRadix(16));
		//trace(i.toRadix(16));
		for(x in 0...60) {
			i = i.shr(1);
			trace(Std.string(x) + " " + i.toRadix(2));
			//trace(i.toRadix(16));
		}
		assertEquals(true,i.eq(BigInteger.ONE));
	}

	public function testDlRshLsh() {
		var i = BigInteger.ONE;
		//trace(i.toRadix(2));
		for(x in 0...60) {
			i.lShiftTo(1,i);
		}
		assertEquals("1000000000000000", i.toRadix(16));
		//trace(i.toRadix(16));
		for(x in 0...60) {
			i.rShiftTo(1,i);
		}
		assertEquals(true,i.eq(BigInteger.ONE));
	}

	public function testLsh36ToRadix() {
		var i = BigInteger.ONE;
		i = i.shl(36);
		assertEquals("1000000000", i.toRadix(16)); // 68,719,476,736
		//trace(i.toRadix(16));
		//trace(i.toRadix(2));
		//trace(i.toRadix(10));
		assertEquals(true, true);
	}

	public function testAbs() {
		var n = BigInteger.ofInt(45);
		//assertEquals("-2d", n.toRadix(16));
		assertEquals("2d", n.toRadix(16));
		n = n.shl(32);
		assertEquals(n.toRadix(16), n.abs().toRadix(16));
	}

	public function testSub() {
		var n = BigInteger.ofInt(10000);
		n = n.sub(BigInteger.ofInt(1000));
		assertEquals(n.chunks[0], 9000);
		for(x in 0...9) {
			n = n.sub(BigInteger.ofInt(1000));
		}
		assertEquals("0", n.toRadix(16));
	}

	public function testSquare() {
		var n = BigInteger.ofInt(5);
		var i = BigInteger.ONE;
		n.squareTo(i);
		assertEquals("19", i.toRadix(16));
	}

	public function testZDiv1() {
		var i = BigInteger.ofInt(2000);
		var m = BigInteger.ofInt(4);
		var q = BigInteger.nbi();
		var r = BigInteger.nbi();

		assertEquals("2000", decVal(i));
		assertEquals("4", decVal(m));
		var rv = i.div(m);
		assertEquals("500",decVal(rv));
	}

	public function testZDiv2() {
		var i = BigInteger.nbi();
		i.fromString("FFFFFFF0", 16);
		var m = BigInteger.ofInt(80);
		var q = BigInteger.nbi();
		var r = BigInteger.nbi();
		var rv = i.div(m);
		assertEquals("3333333", rv.toRadix(16));
	}

	public function testZDivRemTo2() {
		var i = BigInteger.ofInt(65);
		var m = BigInteger.ofInt(4);
		var q = BigInteger.nbi();
		var r = BigInteger.nbi();

		assertEquals("65", decVal(i));
		assertEquals("4", decVal(m));
		i.divRemTo(m,q,r);
		assertEquals("1",decVal(r));
		assertEquals("16",decVal(q));

	}

	public function testSubOne() {
		var i = BigInteger.nbv(1000000000);
		var b = i.sub(BigInteger.ONE);
		assertEquals("3b9ac9ff", b.toRadix(16));
		assertEquals( "999999999",
			b.toString()
		);
	}

	public function testTwo() {
		var i = BigInteger.nbi();
		i.fromString("10000000000",10); // 10 tril 34 bit
		//trace(here.lineNumber);
		trace(i.chunks);
		//assertEquals("10000000000", i.toString());
		assertEquals(true,true);
	}

	public function testIntValue() {
		var i = BigInteger.ofString("3FFFFFFF", 16);
		assertEquals(0x3fffffff, i.toInt());
	}

}


class BigIntegerTest {
	static function main()
	{
#if !neko
		if(haxe.Firebug.detect()) {
			haxe.Firebug.redirectTraces();
		}
#end
		trace("default am function: am"+Std.string(untyped BigInteger.defaultAm));
		trace("Significant bits: "+Std.string(BigInteger.DB));
/*
		var i = BigInteger.nbv(10);
		trace(i.sub(BigInteger.ONE).chunks);
		var i = BigInteger.ONE;
		trace(i.chunks);
		var b = BigInteger.nbi();
		i.lShiftTo(1, b);
		trace(b.chunks);
*/
		var r = new haxe.unit.TestRunner();
		r.add(new Functions());
		r.run();
	}
}


