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

	
	public static function doTestAes(bits, phrase, msg, mode) {
		var a = new Aes(bits, phrase);
		a.mode = mode;
		//trace(Std.string(a) + " for msg " + StringTools.trim(msg));
		var enc: String;
		try {
			enc = a.encrypt(msg);
		}
		catch (e:Dynamic) {
			trace(a);
			throw(e);
		}
		try {
			if(a.decrypt(enc) != msg) 
				throw "Not equal";
		}
		catch(e : Dynamic) {
			trace("Error "+ e);
			trace(a);
			trace(msg);
			trace(StringTools.baseEncode(enc, Constants.DIGITS_HEXL));
			throw("Fatal");
		}
		return enc;
	}


	public static function main() {


		var b : Array<Int> = [128,192,256];
		var msgs : Array<String> = [
			"yo\n",
			"what there are for you to do?\n",
			"0123456789abcdef",
			"ewjkhwety sdfhjsdrkj qweiruqwer iasd faif aoif aijsdfj aiojsfd iaojsdf iojaf iojas oifjaif jasdjf sdoijf osidjf oisdjf sdjfisjdfisj doifjs oidfjosidjf oisjdf oisjdoif jasiojoijjuioasjf asjf ijasjf oaijsdfi odajfioajfdio ajsdifj :#&$&#&*($&\n"
		];
		var phrases : Array<String> = [
			"pass",
			"eiwe",
			"ewrkhoiuewqo etuiwehru asfdjha ewr",
			"my super secret passphrase"
		];


		// AES Test vectors
		try {
			//trace("Should be similar to 69 c4 e0 d8 6a 7b 04 30 d8 cd b7 80 70 b4 c5 5a");
			var target = "69c4e0d86a7b0430d8cdb78070b4c55a";
			var msg = [0x00,0x11,0x22,0x33,0x44,0x55,0x66,0x77,0x88,0x99,0xaa,0xbb,0xcc,0xdd,0xee,0xff];
			var key = [0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0a,0x0b,0x0c,0x0d,0x0e,0x0f];
			var a = new Aes(128, ByteStringTools.byteArrayToString(key));
			//trace("aes created");
			a.mode = ECB;
			var e = a.encrypt(ByteStringTools.byteArrayToString(msg));
			if(target != StringTools.baseEncode(e, Constants.DIGITS_HEXL).substr(0,32))
				throw "AES test vector failure on ECB";
			//trace(StringTools.baseEncode(e, Constants.DIGITS_HEXL));
			a.mode = CBC;
			if(target != StringTools.baseEncode(e, Constants.DIGITS_HEXL).substr(0,32))
				throw "AES test vector failure on CBC";
			//trace(StringTools.baseEncode(a.encrypt(ByteStringTools.int32ToString(msg)), Constants.DIGITS_HEXL));
		}
		catch(e:Dynamic) {} 
		


		for(bits in b) {
			for(phrase in phrases) {
				for(msg in msgs) {
					var e = doTestAes(bits, phrase, msg, ECB);
					var l = doTestAes(bits, phrase, msg, CBC);
					//trace(e);
					//trace(l);
					//if(e == l) {
					//	trace("ecb and cbc the same for msg length "+msg.length+" phrase length "+ phrase.length+" bits: "+bits);
					//}
				}
			}
		}

		var r = new haxe.unit.TestRunner();
		r.add(new ByteStringToolsFunctions());
#if !neko
		r.add(new TeaTestFunctions());
#end
		r.run();

	}
}
