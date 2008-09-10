import crypt.Tea;
import crypt.IMode;
import crypt.ModeECB;
import crypt.ModeCBC;
// import crypt.PadPkcs1Type1;

import haxe.io.Bytes;
import haxe.io.BytesUtil;

enum CryptMode {
	CBC;
	ECB;
}

class TeaTestFunctions extends haxe.unit.TestCase {

	public function testOne() {
		//var s = "Whoa there nellie. Have some tea";
		var s = Bytes.ofString("Message");
		var t = new Tea(Bytes.ofString("This is my passphrase"));
/*
trace('');
var te = t.encryptBlock( s );
trace("Hex dump");
trace(ByteString.hexDump(te));
var td = t.decryptBlock(te);
trace("Raw td");
trace(td);
trace("Hex dump");
trace(ByteString.hexDump(td));
*/
		var tea = new ModeECB( t );
		var e = tea.encrypt(s);

//trace(ByteString.hexDump(e));

		var d = tea.decrypt(e);

		assertTrue(s != e);
		assertEquals(s, d);
	}

	public function testEcbAll() {
		for(phrase in CommonData.phrases) {
			for(msg in CommonData.msgs) {
				assertEquals( true,
						doTestTea(Bytes.ofString(phrase), Bytes.ofString(msg), ECB)
				);
			}
		}
	}

	static function doTestTea(phrase : Bytes, msg : Bytes, mode) {
		var t = new Tea(phrase);
		var tea : IMode;
		switch(mode) {
		case CBC: tea = cast { var c = new ModeCBC(t); c.iv = BytesUtil.nullBytes(16); c; }
		case ECB: tea = cast new ModeECB(t);
		}
		var enc = tea.encrypt(msg);
		var dec = tea.decrypt(enc);
		if(dec == msg)
			return true;
		return false;
	}
}

class TeaTest {

	public static function main() {
#if (FIREBUG && ! neko)
		if(haxe.Firebug.detect()) {
			haxe.Firebug.redirectTraces();
		}
#end
		var r = new haxe.unit.TestRunner();
		r.add(new TeaTestFunctions());
		r.run();
	}
}