import crypt.Aes;
import crypt.ModeECB;
import crypt.ModeCBC;
import crypt.IMode;

enum CryptMode {
	CBC;
	ECB;
}

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
	static var ivstr = "00000000000000000000000000000000";

	static var b : Array<Int> = [128,192,256];
	static var msgs : Array<String> = [
		"yo\n",
		"what is there for you to do?\n",
		"0123456789abcdef",
		"ewjkhwety sdfhjsdrkj qweiruqwer iasd faif aoif aijsdfj aiojsfd iaojsdf iojaf iojas oifjaif jasdjf sdoijf osidjf oisdjf sdjfisjdfisj doifjs oidfjosidjf oisjdf oisjdoif jasiojoijjuioasjf asjf ijasjf oaijsdfi odajfioajfdio ajsdifj :#&$&#&*($&\n",
		"The quick brown fox jumped over the lazy dog. The quick brown fox jumped over the lazy dog again.",
	];
	static var phrases : Array<String> = [
		"pass",
		"eiwe",
		"ewrkhoiuewqo etuiwehru asfdjha ewr",
		"my super secret passphrase"
	];

	public static var latin_passphrase : String = "my passphrase";
	public static var latin : String = "Haec dum oriens diu perferret, caeli reserato tepore Constantius consulatu suo septies et Caesaris ter egressus Arelate Valentiam petit, in Gundomadum et Vadomarium fratres Alamannorum reges arma moturus, quorum crebris excursibus vastabantur confines limitibus terrae Gallorum.\nQuam quidem partem accusationis admiratus sum et moleste tuli potissimum esse Atratino datam. Neque enim decebat neque aetas illa postulabat neque, id quod animadvertere poteratis, pudor patiebatur optimi adulescentis in tali illum oratione versari. Vellem aliquis ex vobis robustioribus hunc male dicendi locum suscepisset; aliquanto liberius et fortius et magis more nostro refutaremus istam male dicendi licentiam.";
	public static var latin_cbc : String = "000000000000000000000000000000003EADB4B64216760699560EAD97228B35D50B2DBCD3D12A0683FEC3F3AFD4A92B067AD65E4E48548B81DD8A6B91C5B353D8BB83A016E68AC939A4C1CDD75B4672473FA7F9058296D8A918F5C94A6E26250300AD0D53B4FC2E4748B1AB1BFD16D124B7D212FCE96EBA9749F8C3837C55AA979216C1183C27EA4282C363EAA9ED061AFE3F2A1911A72A6E516715B14AAA17B9B9BE992CC5F67E5ACA5EFB571FBE911B5E84DA652E37DC1CC2B110F1C32132E5D6BFA19468182CA82340C353E40604370B703769330BCABD199F951C483EF98BC51D7ACEC0ABA4AF233DD28B27C8C345B972FFEA11A3DB9FCA26AC63C2C45B6FDAAC5659584997CDB7538E17F1C8D4188932E4A5DEE8F8D3727FE42A9296460E659E7A542B0C0F234D1E73DE6D118F371D0990AE8290E180EFE834D900BECD6D41AC8DE0129543A880DD0CA0E003B0A3746E3350514DD21FC567D8EFA6FC2AA051E7AB04A5EDD13F0E400DEF1D1B115F6C7A363E2BB20776B5560CE65E231CD75AEA42F7E75B01AF73B671551D21F1FCC708893968CB9B0D34711A1EABE94C49E213C8335DAEF639EF26E2218922130B3B0EA44870333C45B80A5E8AB27B2588907B9293CB4897E96D09F021B3A70378F567E8054B7FB8CA19BBD7BC87845C751C558B5BB31CDBCA8CDFDA0C8E157DF2F22D5471F4B30C06580DE7B363B46D08AE8761485B93385CDF4A00B042823AFA4557ED2230FEC128D979FFA5B77302393FF5F67A806B6E46EFC4B173889C51E89CB8A70EC529BCAAEC2211C3FFCE71684D7B4828A3BAD00147F637D075F657207EE980EA7EB4E67CF7FBA83DF0CE9E03AB5113B66510E4AEC00687BD920D1EE2DDACD91825A4E4867517F799844EBE04A9504582C208E55836413945AAE6BFC5411107B45A16A967A503F28F58777BF95203C835EF1D864CB255AE1BB06416FA3032639E4A3868DBEEF6335F995024E3F82EA091F5A927790E804C0DC685BB";

	public function testEcbOne() {
		var a = new Aes(128, ByteStringTools.byteArrayToString(key));
		var aes = new ModeECB( a );
		var e = aes.encrypt(ByteStringTools.byteArrayToString(msg));

		assertEquals( target,
			StringTools.baseEncode(e, Constants.DIGITS_HEXL).substr(0,32)
		);
		//trace(StringTools.baseEncode(e, Constants.DIGITS_HEXL));

	}

	public function testCbcOne() {
		var a = new Aes(128, ByteStringTools.byteArrayToString(key));
		var aes = new ModeCBC( a );
		aes.iv = ByteStringTools.nullString(16);
		var e = aes.encrypt(ByteStringTools.byteArrayToString(msg));
		assertEquals( ivstr + target,
				StringTools.baseEncode(e, Constants.DIGITS_HEXL).substr(0,64)
		);
		//trace(StringTools.baseEncode(aes.encrypt(ByteStringTools.int32ToString(msg)), Constants.DIGITS_HEXL));
	}

	public function testCbcTwo() {
		var a = new Aes(128, ByteStringTools.byteArrayToString(key));
		var aes = new ModeCBC( a );
		aes.iv = ByteStringTools.nullString(16);
		var e = aes.encrypt(ByteStringTools.byteArrayToString(msg));
		assertEquals( ivstr + target + "9e978e6d16b086570ef794ef97984232",
				StringTools.baseEncode(e, Constants.DIGITS_HEXL)
		);

	}

	public function testCbcThree() {
		var m = "yoyttt";
		var a = new Aes(128, "pass");
		var aes = new ModeCBC( a );
		aes.iv = ByteStringTools.nullString(16);
		var e = aes.encrypt(m);
		var u = aes.decrypt(e);
		assertEquals(m, u);
	}

	public function testCbcLatinEncrypt() {
		var a = new Aes(128, latin_passphrase);
		var aes = new ModeCBC( a );
		aes.iv = ByteStringTools.nullString(16);
		var e = aes.encrypt(latin);
		assertEquals( latin_cbc,
				ByteStringTools.hexDump(e, true)
		);
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
		var aes : IMode; // =
		switch(mode) {
		case CBC: aes = cast { var c = new ModeCBC(a); c.iv = ByteStringTools.nullString(16); c; }
		case ECB: aes = cast new ModeECB(a);
		}
		var enc: String;
		try {
			enc = aes.encrypt(msg);
		}
		catch (e:Dynamic) {
			//trace(a);
			throw(e);
		}
		var dec : String = "";
		try {
			dec = aes.decrypt(enc);
			if(dec != msg) {
				trace("Orig: " + msg);
				trace("Hex : " + ByteStringTools.hexDump(msg));
				trace("Decr: " + dec);
				trace("Hex : " + ByteStringTools.hexDump(dec));
				return false;
			}
		}
		catch(e : Dynamic) {
			throw(e + " msg: " + msg + " :: msg len " + msg.length + " :: enc length " +enc.length + ":: " + ByteStringTools.hexDump(enc)
			+ " :: dec length " + dec.length + " :: " + ByteStringTools.hexDump(dec)
			);
		}
		return true;
	}

}

#if havesometea
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
#if !neko
		if(haxe.Firebug.detect()) {
			haxe.Firebug.redirectTraces();
		}
#end

		var r = new haxe.unit.TestRunner();
		r.add(new ByteStringToolsFunctions());
		r.add(new AesTestFunctions());
#if havesometea
		r.add(new TeaTestFunctions());
#end
		r.run();

	}
}
