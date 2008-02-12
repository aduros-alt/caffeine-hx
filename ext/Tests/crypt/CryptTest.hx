import crypt.Aes;
#if !neko
import crypt.Tea;
#end
import crypt.Base;
import crypt.Base.CryptMode;

class ByteStringToolsFunctions extends haxe.unit.TestCase {
	public function testLongs() {
/*
		var testv = [0xFF,0x11,0x44,0xFF, 0xFF,0xFF,0xFF,0xFF, 0xFF,0xFF,0xFF,0xFF, 0xFF,0xFF,0xFF,0xFF, 0xFF];
		//var testv = [65, 66, 67];
		var s = ByteStringTools.int32ToString(testv);
		var longs = ByteStringTools.strToInt32(s);
trace(longs);
		var sr = ByteStringTools.int32ToString(longs);
trace(sr);
trace(sr.length);
		if(StringTools.trim(sr) != s) {
			trace("not equal");
		}
		else
			trace(" * passed");
*/
		var s = "Whoa there nellie";
		var longs = ByteStringTools.strToInt32(s);
		var sr = 
				ByteStringTools.unNullPadString(
					ByteStringTools.int32ToString(longs)
				);

		assertEquals(s, sr);
#if nekomore
		if(s.length != sr.length)
			assertEquals(0,1);
		for(x in 0...s.length) {
			if(s[x].compare(sr[x]))
				assertEquals(0,2);
		}
#end

	}
}

class AesTestFunctions extends haxe.unit.TestCase {
	static var target = "69c4e0d86a7b0430d8cdb78070b4c55a";
	static var msg = [0x00,0x11,0x22,0x33,0x44,0x55,0x66,0x77,0x88,0x99,0xaa,0xbb,0xcc,0xdd,0xee,0xff];
	static var key = [0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0a,0x0b,0x0c,0x0d,0x0e,0x0f];

	static var b : Array<Int> = [128,192,256];
	static var msgs : Array<String> = [
		"yo\n",
		"what there are for you to do?\n",
		"0123456789abcdef",
		"ewjkhwety sdfhjsdrkj qweiruqwer iasd faif aoif aijsdfj aiojsfd iaojsdf iojaf iojas oifjaif jasdjf sdoijf osidjf oisdjf sdjfisjdfisj doifjs oidfjosidjf oisjdf oisjdoif jasiojoijjuioasjf asjf ijasjf oaijsdfi odajfioajfdio ajsdifj :#&$&#&*($&\n"
	];
	static var phrases : Array<String> = [
		"pass",
		"eiwe",
		"ewrkhoiuewqo etuiwehru asfdjha ewr",
		"my super secret passphrase"
	];

	public function testEcbOne() {
		var a = new Aes(128, ByteStringTools.byteArrayToString(key));
		a.mode = ECB;
		var e = a.encrypt(ByteStringTools.byteArrayToString(msg));

		assertEquals( target,
			StringTools.baseEncode(e, Constants.DIGITS_HEXL).substr(0,32)
		);
		//trace(StringTools.baseEncode(e, Constants.DIGITS_HEXL));
			
	}

	public function testCbcOne() {
		var a = new Aes(128, ByteStringTools.byteArrayToString(key));
		a.mode = CBC;
		var e = a.encrypt(ByteStringTools.byteArrayToString(msg));
		assertEquals( target,
				StringTools.baseEncode(e, Constants.DIGITS_HEXL).substr(0,32)
		);
		//trace(StringTools.baseEncode(a.encrypt(ByteStringTools.int32ToString(msg)), Constants.DIGITS_HEXL));
	}

	public function testEcbAll() {
		for(bits in b) {
			for(phrase in phrases) {
				for(msg in msgs) {
					assertEquals( true, 
							doTestAes(bits, phrase, msg, ECB)
					);
				}
			}
		}
	}

	public function testCbcAll() {
		for(bits in b) {
			for(phrase in phrases) {
				for(msg in msgs) {
					assertEquals( true,
							doTestAes(bits, phrase, msg, CBC)
					);
				}
			}
		}
	}

	static function doTestAes(bits, phrase, msg, mode) {
		var a = new Aes(bits, phrase);
		a.mode = mode;
		var enc: String;
		try {
			enc = a.encrypt(msg);
		}
		catch (e:Dynamic) {
			//trace(a);
			throw(e);
		}
		try {
			//trace(ByteStringTools.hexDump(enc));
			var dec = a.decrypt(enc);
			if(dec != msg) {
				trace("Orig: " + msg);
				trace("Hex : " + ByteStringTools.hexDump(msg)); 
				trace("Decr: " + dec);
				trace("Hex : " + ByteStringTools.hexDump(dec));
				return false;
			}
		}
		catch(e : Dynamic) {
			trace("Error "+ e);
			trace(a);
			trace(msg);
			trace(StringTools.baseEncode(enc, Constants.DIGITS_HEXL));
			throw("Fatal");
		}
		return true;
	}

}

#if !neko
class TeaTestFunctions extends haxe.unit.TestCase {
	public function testOne() {
		var s = "Whoa there nellie. Have some tea";
		var t = new Tea("This is my passphrase");
		var enc = t.encrypt(s);
		var dec = t.decrypt(enc);

		assertTrue(s != enc);
		assertEquals(s, dec);
	}
}
#end

class CryptTest {

	public static function main() {



		var r = new haxe.unit.TestRunner();
		r.add(new ByteStringToolsFunctions());
		r.add(new AesTestFunctions());
#if !neko
		//r.add(new TeaTestFunctions());
#end
		r.run();

	}
}
