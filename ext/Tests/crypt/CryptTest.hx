import crypt.Aes;
import crypt.ModeECB;
import crypt.ModeCBC;
import crypt.IMode;
import crypt.Tea;
import crypt.RSA;
import crypt.PadPkcs1Type1;

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
	public static var msgs : Array<String> = [
		"yo\n",
		"what is there for you to do?\n",
		"0123456789abcdef",
		"ewjkhwety sdfhjsdrkj qweiruqwer iasd faif aoif aijsdfj aiojsfd iaojsdf iojaf iojas oifjaif jasdjf sdoijf osidjf oisdjf sdjfisjdfisj doifjs oidfjosidjf oisjdf oisjdoif jasiojoijjuioasjf asjf ijasjf oaijsdfi odajfioajfdio ajsdifj :#&$&#&*($&\n",
		"The quick brown fox jumped over the lazy dog. The quick brown fox jumped over the lazy dog again.",
	];
	public static var phrases : Array<String> = [
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

class TeaTestFunctions extends haxe.unit.TestCase {
	public function testOne() {
		//var s = "Whoa there nellie. Have some tea";
		var s = "Message";
		var t = new Tea("This is my passphrase");
/*
trace('');
var te = t.encryptBlock( s );
trace("Hex dump");
trace(ByteStringTools.hexDump(te));
var td = t.decryptBlock(te);
trace("Raw td");
trace(td);
trace("Hex dump");
trace(ByteStringTools.hexDump(td));
*/
		var tea = new ModeECB( t );
		var e = tea.encrypt(s);

//trace(ByteStringTools.hexDump(e));

		var d = tea.decrypt(e);

		assertTrue(s != e);
		assertEquals(s, d);
	}

	public function testEcbAll() {
		for(phrase in AesTestFunctions.phrases) {
			for(msg in AesTestFunctions.msgs) {
				assertEquals( true,
						doTestTea(phrase, msg, ECB)
				);
			}
		}
	}

	static function doTestTea(phrase, msg, mode) {
		var t = new Tea(phrase);
		var tea : IMode;
		switch(mode) {
		case CBC: tea = cast { var c = new ModeCBC(t); c.iv = ByteStringTools.nullString(16); c; }
		case ECB: tea = cast new ModeECB(t);
		}
		var enc = tea.encrypt(msg);
		var dec = tea.decrypt(enc);
		if(dec == msg)
			return true;
		return false;
	}
}

class PadFunctions extends haxe.unit.TestCase {
	function testPkcs1() {
		var msg = "Hello";
		var padWith : Int = 0xFF; // Std.ord("A")
		var pad = new PadPkcs1Type1(16);
		pad.padByte = padWith;

		var s = pad.pad("Hello");
		assertEquals(16, s.length);

		// expected result
		var sb = new StringBuf();
		sb.addChar(0);
		sb.addChar(1);
		var len = 16 - msg.length - 3;
		assertEquals(8, len);
		for(x in 0...len)
			sb.addChar(padWith & 0xFF);
		sb.addChar(0);
		sb.add(msg);
		assertEquals(16,sb.toString().length);

		assertEquals(sb.toString(), s);
		assertEquals(msg, pad.unpad(s));
	}
}

class RSAFunctions extends haxe.unit.TestCase {
	static var modulus : String = "00:bd:b1:19:66:6e:be:eb:1f:fb:9c:6a:30:4b:4f:b3:eb:05:61:d9:37:d4:97:58:2c:a3:55:b7:a3:07:e0:11:cd:81:88:c4:42:27:a2:66:b2:94:94:bc:81:ae:8c:f8:18:93:db:a4:ce:dd:4a:87:e4:72:f5:fc:2f:93:aa:f1:07:b8:98:18:8a:f9:26:bf:20:64:4f:8d:33:cd:54:af:a8:3f:59:c3:ee:d8:bd:16:32:a9:27:7e:33:29:ae:b4:60:d8:27:2b:66:f5:c7:74:05:35:41:1e:66:df:53:6a:29:c0:f6:60:2e:9a:32:f9:3b:22:a3:4a:a7:bc:9c:d2:f7";
	static var exp : String = "10001";
	static var pexp: String = "37:66:f3:39:34:9d:34:44:fa:12:db:fc:d0:f2:2d:65:36:04:37:12:14:58:43:9b:7d:f4:fa:16:76:a5:5d:ed:bc:a8:7a:51:ac:0b:c5:9c:e0:c2:74:30:18:0f:fa:22:0b:85:3a:24:65:03:70:9f:2b:68:66:c8:6a:83:a1:b3:93:71:d3:db:c8:f9:de:9d:3a:ca:b2:56:d1:cb:19:48:a3:42:2a:f7:74:57:fc:a2:9b:50:9a:a9:0f:95:b0:9f:0f:90:17:f2:c6:68:4c:19:1d:27:f8:e2:ee:7e:50:27:15:75:dd:74:4f:8a:be:57:c2:6e:69:b8:7c:de:83:41";

	function test0() {
		var r = new RSA(modulus, exp, pexp);
#if neko
		for(s in AesTestFunctions.msgs) {
#else true
		var s = AesTestFunctions.msgs[0];
#end
			var e = r.encrypt(s);
			//trace(ByteStringTools.hexDump(e));
			var u = r.decrypt(e);
			assertTrue(u == s);
#if neko
		}
#end
	}
/*
	function test1() {
		var s = "Message";
		var r = new RSA(modulus, exp, pexp);
// trace('');
// var te = t.encryptBlock( s );
// trace("Hex dump");
// trace(ByteStringTools.hexDump(te));
// var td = t.decryptBlock(te);
// trace("Raw td");
// trace(td);
// trace("Hex dump");
// trace(ByteStringTools.hexDump(td));
		var rsa = new ModeECB( r, new PadPkcs1Type1(r.blockSize) );
		for(s in AesTestFunctions.msgs) {
			var e = rsa.encrypt(s);
			var u = rsa.decrypt(e);
			assertTrue(u == s);
		}
	}
*/

/*
	function test2() {
		var msg = "Hello";
		var rsa:RSA = RSA.generate(256, "10001");
		var e = rsa.encrypt("Hello");
		var u = rsa.decrypt(e);
		assertEquals(msg,u.substr(u.length-msg.length));
	}

	// this is a 1024bit key
	function test3() {
		var rsa = new RSA();
		rsa.setPrivate(modulus, exp, pexp);

		var msg = "Hello there how are you today?";
		var e = rsa.encrypt(msg);
		var u = rsa.decrypt(e);
		assertEquals(msg,u.substr(u.length-msg.length));
	}
*/
}

class CryptTest {

	public static function main() {
#if !neko
		if(haxe.Firebug.detect()) {
			haxe.Firebug.redirectTraces();
		}
#end
#if nekogg
	//function testZGenerate() {
		var num : Int = 10;
		var bits : Int = 128;
		var exp : String = "10001";
		trace("Generating " + num +" " + bits + " bit RSA keys");
		var msg = "Hello";
		for(x in 0...num) {
			var rsa:RSA = RSA.generate(bits, exp);
			var e = rsa.encrypt("Hello");
			if(e == null)
				throw "e is null";
			var u = rsa.decrypt(e);
			if (u == null) {
				trace(e);
				trace(u);
				throw "u is null";
			}
			if(msg != u.substr(u.length-msg.length)) {
				throw "message mismatch";
			}
			//neko.Lib.print(".");
		}
		//neko.Lib.println("");
	//}
#end

		var r = new haxe.unit.TestRunner();
// 		r.add(new PadFunctions());
//
// 		r.add(new ByteStringToolsFunctions());
// 		r.add(new AesTestFunctions());
// 		r.add(new TeaTestFunctions());
		r.add(new RSAFunctions());

		r.run();
	}
}
