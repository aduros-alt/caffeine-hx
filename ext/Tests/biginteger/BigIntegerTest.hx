import math.BigInteger;
import crypt.RSAEncrypt;

class DecimalConversion extends haxe.unit.TestCase {
	function test01() {
		var one = BigInteger.ONE;
		assertEquals(true, true);
	}

	function test02() {
		var one = BigInteger.ONE;
		assertEquals("1", one.toRadix(10));
	}

	function test03() {
		var b = BigInteger.ofString("10",10);
		assertEquals("10", b.toRadix(10));
	}

	function test04() {
		var b = BigInteger.ofInt(78);
		assertEquals("78", b.toRadix(10));
	}

	function test05() {
		var b = BigInteger.ofInt(-45);
#if !neko
		assertEquals(-1, b.sign);
#end
		assertEquals("-45", b.toRadix(10));
	}

	function test06() {
		var b = BigInteger.ofInt(-2358);
		b.fromInt(-1);
		assertEquals("-1", b.toRadix(10));
	}
}

class Shifts extends haxe.unit.TestCase {
	public function test03_Lsh36ToRadix() {
		var i = BigInteger.ONE;
		i = i.shl(36);
		assertEquals("1000000000", i.toRadix(16)); // 68,719,476,736
		//trace(i.toRadix(16));
		//trace(i.toRadix(2));
		//trace(i.toRadix(10));
		assertEquals(true, true);
	}

	// 		Lest shifts one diplaying binary up to 60 lsh.
	// 		Right shifts back tracing Hexadecimal
	public function test05_RshLsh() {
		var i = BigInteger.ONE;
		//trace(i.toRadix(2));
		for(x in 0...60) {
			i = i.shl(1);
			//trace(Std.string(x) + " " + i.toRadix(2));
		}
		assertEquals("1000000000000000", i.toRadix(16));
		//trace(i.toRadix(16));
		for(x in 0...60) {
			i = i.shr(1);
			//trace(Std.string(x) + " " + i.toRadix(2));
			//trace(i.toRadix(16));
		}
		assertEquals(true,i.eq(BigInteger.ONE));
	}

	public function test06_DlRshLsh() {
		var i = BigInteger.ONE;
		//trace(i.toRadix(2));
		for(x in 0...60) {
			i = i.shl(1);
		}
		assertEquals("1000000000000000", i.toRadix(16));
		//trace(i.toRadix(16));
		for(x in 0...60) {
			i = i.shr(1);
		}
		assertEquals(true,i.eq(BigInteger.ONE));
	}
}

class MathFuncs extends haxe.unit.TestCase {
	function test01() {
		var n = BigInteger.ofInt(-61);
		assertEquals(61, n.abs().toInt());
	}

	function test02() {
		var n = BigInteger.ofInt(46);
		//assertEquals("-2e", n.toRadix(16));
		assertEquals("2e", n.toRadix(16));
		n = n.shl(32);
		assertEquals(n.toRadix(16), n.abs().toRadix(16));
	}
}

class Functions extends haxe.unit.TestCase {

	public static function decVal(i:BigInteger) {
		return i.toRadix(10);
	}

	public static function hexVal(i:BigInteger) {
		return i.toRadix(16);
	}

	public function test00() {
		var i = BigInteger.ONE.add(BigInteger.ofInt(9));
		var b = BigInteger.nbi();
		//trace("fromString>>");
		b.fromString("10",10);
#if !neko
		assertEquals(10, b.chunks[0]);
#end
		//trace("toRadix>>");
		//i.eq(b);
		b.toRadix(10);
		//trace(b.chunks);
		//trace("toString>>");
		assertEquals("10",b.toString());
	}

	public function test01() {
		var i = BigInteger.ONE.add(BigInteger.ofInt(9));
		//trace(i.chunks);
		var b = BigInteger.nbi();
		b.fromString("10",10);
		//trace(b.chunks);
		assertEquals(true, i.eq(b));
		assertEquals("10",decVal(b));
	}



	public function test02_Sub() {
		var n = BigInteger.ofInt(10000);
		n = n.sub(BigInteger.ofInt(1000));
#if !neko
		assertEquals(n.chunks[0], 9000);
#end
		for(x in 0...9) {
			n = n.sub(BigInteger.ofInt(1000));
		}
		assertEquals("0", n.toRadix(16));
	}

	public function test03_Square() {
		var n = BigInteger.ofInt(5);
		var i = BigInteger.ONE;
		n.squareTo(i);
		assertEquals("19", i.toRadix(16));
	}

	public function test04_ZDiv1() {
		var i = BigInteger.ofInt(2000);
		var m = BigInteger.ofInt(4);
		var q = BigInteger.nbi();
		var r = BigInteger.nbi();

		assertEquals("2000", decVal(i));
		assertEquals("4", decVal(m));
		var rv = i.div(m);
		assertEquals("500",decVal(rv));
	}

	public function test05_ZDiv2() {
		var i = BigInteger.nbi();
		i.fromString("FFFFFFF0", 16);
		var m = BigInteger.ofInt(80);
		var q = BigInteger.nbi();
		var r = BigInteger.nbi();
		var rv = i.div(m);
		assertEquals("3333333", rv.toRadix(16));
	}

	public function test06_ZDivRemTo2() {
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


	public function test07_SubOne() {
		var i = BigInteger.nbv(1000000000);
		var b = i.sub(BigInteger.ONE);
		assertEquals("3b9ac9ff", b.toRadix(16));
		assertEquals( "999999999",
			b.toString()
		);
	}

	public function test08_Two() {
		var i = BigInteger.nbi();
		i.fromString("10000000000",10); // 10 tril 34 bit
		//trace(here.lineNumber);
		//trace(i.chunks);
		//assertEquals("10000000000", i.toString());
		assertEquals(true,true);
	}

	public function test09_IntValue() {
		var i = BigInteger.ofString("3FFFFFFF", 16);
		assertEquals(0x3fffffff, i.toInt());
	}

	public function test10_RsaValues() {
		var bufh = "1ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff007768617420697320746865726520666f7220796f7520746f20646f3f0a";
		var nh = "00bdb119666ebeeb1ffb9c6a304b4fb3eb0561d937d497582ca355b7a307e011cd8188c44227a266b29494bc81ae8cf81893dba4cedd4a87e472f5fc2f93aaf107b898188af926bf20644f8d33cd54afa83f59c3eed8bd1632a9277e3329aeb460d8272b66f5c7740535411e66df536a29c0f6602e9a32f93b22a34aa7bc9cd2f7";
		var eh = "10001";
		var dh = "3766f339349d3444fa12dbfcd0f22d65360437121458439b7df4fa1676a55dedbca87a51ac0bc59ce0c27430180ffa220b853a246503709f2b6866c86a83a1b39371d3dbc8f9de9d3acab256d1cb1948a3422af77457fca29b509aa90f95b09f0f9017f2c6684c191d27f8e2ee7e50271575dd744f8abe57c26e69b87cde8341";

		// decimal
		var bufd="5486124068793688683255936251187209270074392635932332070112001988456197381759672947165175699536362793613284725337872111744958183862744647903224103718245670299614498700710006264535590197791934024641512541262359795191593953928908168988529130661834890119808421928375322532610062173667761649741182297885851402";
		var ns ="133206107616895911276282727458046455337534161820979721604463773929767597935110313612434319656737520333563650320168048948419157669249224322246963682268636718066281017378115140153780820244916784506341314670358249484991778427045142432656380287775830843493866516086622740226068785889970179364509001398348947444471";
		var es ="65537";
		var ds ="38904711932114754073871670755061525575106297075169337187101043636261678015105154536454297763852676758239495716592712893810993743184756744314343528728870332441157167932063579798572669191654345408121447731582483604244177916892485661185682880305905225746393455753230438758165141419790363062170096731044844569409";



		var biPriv = BigInteger.ofString(dh, 16);
		assertEquals(ds, biPriv.toString());
		var biPriv2 = BigInteger.nbi();
		biPriv2.fromString(dh, 16);
		assertEquals(ds, biPriv2.toString());

		var rsa = new RSAEncrypt(nh, eh);
		assertEquals(ns, rsa.n.toString());


		var biBuf = BigInteger.ofString(bufh,16);
		var biExp = BigInteger.ofString(eh, 16);
		var biMod = BigInteger.ofString(nh, 16);

		assertEquals(bufd, biBuf.toString());
		assertEquals(es, biExp.toString());
		assertEquals(ns, biMod.toString());

		// Verified
// 		 trace(biBuf.mul(biMod));
// 		 trace(biBuf.mod(biMod));
// 		 trace(biBuf.mul(biBuf));
// 		 trace(biBuf.div(biExp));

		var target="b2ffd8b2cabdce4c08b6aa358d27f3f8652ffbe0ffb5824bd0c598da85d53f9cf30dd5cd5fb537b3ccfc4499a5abdfd2ef0ad3c135fb4557073543bb90026bf6f848998e48dd1ea24ae6026cffd96c3558791d431fb0fa1557333478b43e08aef8afca3f708e4840c82555c64c00076ed0f4d0f135965ebd150ada191afd8b0d";

		var res = biBuf.modPowInt(65537, biMod);
		assertEquals(target, res.toRadix(16));
// 		trace("");
// 		for(x in 0...100) {

//#if neko
// 			neko.Lib.print(".");
//#end
// 			biBuf = BigInteger.ofString(bufh,16);
// 			biMod = BigInteger.ofString(nh, 16);
// 			biExp = BigInteger.ofString(eh, 16);
// 		}
//trace(res.toRadix(16));

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
		//trace("default am function: am"+Std.string(untyped BigInteger.defaultAm));
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
		r.add(new DecimalConversion());
		r.add(new Shifts());
		r.add(new MathFuncs());
		r.add(new Functions());
		r.run();
	}
}


