package tests;
import crypt.Aes;
import crypt.Sha;
#if !neko
import crypt.Tea;
#end
import crypt.Base;
import crypt.Base.CryptMode;

class CryptTest {
	public static function testLongs() {
		trace(here.methodName);
		var testv = [0xFF, 0x11, 0x44, 0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF,0xFF];
		//var testv = [65, 66, 67];
		var s = Base.intArrayToString(testv, 4);
		var longs = Base.strToLongs(s);
trace(longs);
		var sr = Base.longsToStr(longs);
trace(sr);
trace(sr.length);
		if(StringTools.trim(sr) != s) {
			trace("not equal");
		}
		else
			trace(" * passed");

		s = "Whoa there nellie";
		longs = Base.strToLongs(s);
		sr = Base.longsToStr(longs);
		var er : EReg = ~/\0+$/;
		sr = er.replace(sr, '');
		if(sr != s) {
			trace("not equal");
			trace(s);
			trace(sr);
		}
		else
			trace(" * passed");

		trace("** complete\n");
	}

#if !neko
	public static function TeaTest() {
		trace("*** TeaTest");
		var s = "Whoa there nellie";
		var t = new Tea("This is my passphrase");
		var enc = t.encrypt(s);
trace(enc);
		var dec = t.decrypt(enc);
		if(s != dec) {
			trace("Failure");
			trace(s);
			trace(dec);
		}
		trace("*** complete\n");
	}
#end
	
	public static function doTestAes(bits, phrase, msg, mode) {
		var a = new Aes(bits, phrase);
		a.mode = mode;
//		trace(Std.string(a) + " for msg " + StringTools.trim(msg));
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
			trace(StringTools.baseEncode(enc, crypt.Base.HEXL));
			throw("Fatal");
		}
		return enc;
	}

	public static function doSha(msg) {
		trace(StringTools.trim(msg) + " SHA1 DIGEST: " + Sha.calcSha1(msg));
	}

	public static function main() {
		testLongs();
#if !neko
		TeaTest();
#end

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

		var tv = "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq";
		if(Sha.calcSha1(tv) != "84983e441c3bd26ebaae4aa1f95129e5e54670f1") {
			trace("test vector failed");
			trace(Sha.calcSha1(tv));
		}
		tv = "abc";
		if(Sha.calcSha1(tv) != "a9993e364706816aba3e25717850c26c9cd0d89d") {
			trace("test vector failed");
			trace(Sha.calcSha1(tv));
		}

		for(msg in msgs) {
			doSha(msg);
		}

		// AES Test vectors
		try {
			//trace("Should be similar to 69 c4 e0 d8 6a 7b 04 30 d8 cd b7 80 70 b4 c5 5a");
			var target = "69c4e0d86a7b0430d8cdb78070b4c55a";
			var msg = [0x00,0x11,0x22,0x33,0x44,0x55,0x66,0x77,0x88,0x99,0xaa,0xbb,0xcc,0xdd,0xee,0xff];
			var key = [0x00,0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,0x09,0x0a,0x0b,0x0c,0x0d,0x0e,0x0f];
			var a = new Aes(128, Base.intArrayToString(key));
			//trace("aes created");
			a.mode = ECB;
			var e = a.encrypt(Base.intArrayToString(msg));
			if(target != StringTools.baseEncode(e, crypt.Base.HEXL).substr(0,32))
				throw "AES test vector failure on ECB";
			//trace(StringTools.baseEncode(e, crypt.Base.HEXL));
			a.mode = CBC;
			if(target != StringTools.baseEncode(e, crypt.Base.HEXL).substr(0,32))
				throw "AES test vector failure on CBC";
			//trace(StringTools.baseEncode(a.encrypt(Base.intArrayToString(msg)), crypt.Base.HEXL));
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
	}
}
