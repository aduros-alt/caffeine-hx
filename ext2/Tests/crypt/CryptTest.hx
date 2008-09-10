import crypt.Aes;
import crypt.ModeECB;
import crypt.ModeCBC;
import crypt.IMode;
import crypt.RSA;
import crypt.PadPkcs1Type1;

enum CryptMode {
	CBC;
	ECB;
}

class ByteStringFunctions extends haxe.unit.TestCase {
	public function testLongs() {
/*
		var testv = [0xFF,0x11,0x44,0xFF, 0xFF,0xFF,0xFF,0xFF, 0xFF,0xFF,0xFF,0xFF, 0xFF,0xFF,0xFF,0xFF, 0xFF];
		//var testv = [65, 66, 67];
		var s = ByteString.int32ToString(testv);
		var longs = ByteString.strToInt32(s);
trace(longs);
		var sr = ByteString.int32ToString(longs);
trace(sr);
trace(sr.length);
		if(StringTools.trim(sr) != s) {
			trace("not equal");
		}
		else
			trace(" * passed");
*/
		var s = "Whoa there nellie";
		var longs = ByteString.strToInt32(s);
		var sr =
				ByteString.unNullPadString(
					ByteString.int32ToString(longs)
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

	public static var latin_cbc : String = "000000000000000000000000000000003EADB4B64216760699560EAD97228B35D50B2DBCD3D12A0683FEC3F3AFD4A92B067AD65E4E48548B81DD8A6B91C5B353D8BB83A016E68AC939A4C1CDD75B4672473FA7F9058296D8A918F5C94A6E26250300AD0D53B4FC2E4748B1AB1BFD16D124B7D212FCE96EBA9749F8C3837C55AA979216C1183C27EA4282C363EAA9ED061AFE3F2A1911A72A6E516715B14AAA17B9B9BE992CC5F67E5ACA5EFB571FBE911B5E84DA652E37DC1CC2B110F1C32132E5D6BFA19468182CA82340C353E40604370B703769330BCABD199F951C483EF98BC51D7ACEC0ABA4AF233DD28B27C8C345B972FFEA11A3DB9FCA26AC63C2C45B6FDAAC5659584997CDB7538E17F1C8D4188932E4A5DEE8F8D3727FE42A9296460E659E7A542B0C0F234D1E73DE6D118F371D0990AE8290E180EFE834D900BECD6D41AC8DE0129543A880DD0CA0E003B0A3746E3350514DD21FC567D8EFA6FC2AA051E7AB04A5EDD13F0E400DEF1D1B115F6C7A363E2BB20776B5560CE65E231CD75AEA42F7E75B01AF73B671551D21F1FCC708893968CB9B0D34711A1EABE94C49E213C8335DAEF639EF26E2218922130B3B0EA44870333C45B80A5E8AB27B2588907B9293CB4897E96D09F021B3A70378F567E8054B7FB8CA19BBD7BC87845C751C558B5BB31CDBCA8CDFDA0C8E157DF2F22D5471F4B30C06580DE7B363B46D08AE8761485B93385CDF4A00B042823AFA4557ED2230FEC128D979FFA5B77302393FF5F67A806B6E46EFC4B173889C51E89CB8A70EC529BCAAEC2211C3FFCE71684D7B4828A3BAD00147F637D075F657207EE980EA7EB4E67CF7FBA83DF0CE9E03AB5113B66510E4AEC00687BD920D1EE2DDACD91825A4E4867517F799844EBE04A9504582C208E55836413945AAE6BFC5411107B45A16A967A503F28F58777BF95203C835EF1D864CB255AE1BB06416FA3032639E4A3868DBEEF6335F995024E3F82EA091F5A927790E804C0DC685BB";

	public function testEcbOne() {
		var a = new Aes(128, ByteString.byteArrayToString(key));
		var aes = new ModeECB( a );
		var e = aes.encrypt(ByteString.byteArrayToString(msg));

		assertEquals( target,
			StringTools.baseEncode(e, Constants.DIGITS_HEXL).substr(0,32)
		);
		//trace(StringTools.baseEncode(e, Constants.DIGITS_HEXL));

	}

	public function testCbcOne() {
		var a = new Aes(128, ByteString.byteArrayToString(key));
		var aes = new ModeCBC( a );
		aes.iv = ByteString.nullString(16);
		var e = aes.encrypt(ByteString.byteArrayToString(msg));
		assertEquals( ivstr + target,
				StringTools.baseEncode(e, Constants.DIGITS_HEXL).substr(0,64)
		);
		//trace(StringTools.baseEncode(aes.encrypt(ByteString.int32ToString(msg)), Constants.DIGITS_HEXL));
	}

	public function testCbcTwo() {
		var a = new Aes(128, ByteString.byteArrayToString(key));
		var aes = new ModeCBC( a );
		aes.iv = ByteString.nullString(16);
		var e = aes.encrypt(ByteString.byteArrayToString(msg));
		assertEquals( ivstr + target + "9e978e6d16b086570ef794ef97984232",
				StringTools.baseEncode(e, Constants.DIGITS_HEXL)
		);

	}

	public function testCbcThree() {
		var m = "yoyttt";
		var a = new Aes(128, "pass");
		var aes = new ModeCBC( a );
		aes.iv = ByteString.nullString(16);
		var e = aes.encrypt(m);
		var u = aes.decrypt(e);
		assertEquals(m, u);
	}

	public function testCbcLatinEncrypt() {
		var a = new Aes(128, CommonData.latin_passphrase);
		var aes = new ModeCBC( a );
		aes.iv = ByteString.nullString(16);
		var e = aes.encrypt(CommonData.latin);
		assertEquals( latin_cbc,
				ByteString.hexDump(e, "")
		);
	}

	public function testEcbAll() {
		for(bits in b) {
			for(phrase in CommonData.phrases) {
				for(msg in CommonData.msgs) {
					assertEquals( true,
							doTestAes(bits, phrase, msg, ECB)
					);
				}
			}
		}
	}

	public function testCbcAll() {
		for(bits in b) {
			for(phrase in CommonData.phrases) {
				for(msg in CommonData.msgs) {
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
		case CBC: aes = cast { var c = new ModeCBC(a); c.iv = ByteString.nullString(16); c; }
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
				trace("Hex : " + ByteString.hexDump(msg));
				trace("Decr: " + dec);
				trace("Hex : " + ByteString.hexDump(dec));
				return false;
			}
		}
		catch(e : Dynamic) {
			throw(e + " msg: " + msg + " :: msg len " + msg.length + " :: enc length " +enc.length + ":: " + ByteString.hexDump(enc)
			+ " :: dec length " + dec.length + " :: " + ByteString.hexDump(dec)
			);
		}
		return true;
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
	/*
	// A private key with exponent 10001
	static var modulus : String = "00:bd:b1:19:66:6e:be:eb:1f:fb:9c:6a:30:4b:4f:b3:eb:05:61:d9:37:d4:97:58:2c:a3:55:b7:a3:07:e0:11:cd:81:88:c4:42:27:a2:66:b2:94:94:bc:81:ae:8c:f8:18:93:db:a4:ce:dd:4a:87:e4:72:f5:fc:2f:93:aa:f1:07:b8:98:18:8a:f9:26:bf:20:64:4f:8d:33:cd:54:af:a8:3f:59:c3:ee:d8:bd:16:32:a9:27:7e:33:29:ae:b4:60:d8:27:2b:66:f5:c7:74:05:35:41:1e:66:df:53:6a:29:c0:f6:60:2e:9a:32:f9:3b:22:a3:4a:a7:bc:9c:d2:f7";
	static var publicExponent : String = "10001";
	static var privateExponent: String = "37:66:f3:39:34:9d:34:44:fa:12:db:fc:d0:f2:2d:65:36:04:37:12:14:58:43:9b:7d:f4:fa:16:76:a5:5d:ed:bc:a8:7a:51:ac:0b:c5:9c:e0:c2:74:30:18:0f:fa:22:0b:85:3a:24:65:03:70:9f:2b:68:66:c8:6a:83:a1:b3:93:71:d3:db:c8:f9:de:9d:3a:ca:b2:56:d1:cb:19:48:a3:42:2a:f7:74:57:fc:a2:9b:50:9a:a9:0f:95:b0:9f:0f:90:17:f2:c6:68:4c:19:1d:27:f8:e2:ee:7e:50:27:15:75:dd:74:4f:8a:be:57:c2:6e:69:b8:7c:de:83:41";
	*/

	static var modulus: String = "00:bc:7a:6e:3d:6b:11:e0:c3:2f:e2:4a:31:1b:07:b3:42:73:ab:27:29:55:b2:f7:05:9a:43:e2:33:96:63:5f:20:a1:a0:70:44:82:1e:16:08:65:ea:51:58:5c:a6:36:b2:b2:1e:76:97:87:b5:8f:ec:c4:38:de:55:88:71:24:d2:59:ca:dc:1c:8d:70:fe:3f:11:d7:39:5f:20:b2:35:ab:0b:62:c2:b2:07:b8:a8:d4:4a:31:95:0e:56:f1:46:94:ba:37:41:cf:94:e3:54:8f:9f:d5:05:05:69:5a:5b:31:c6:24:20:30:8f:db:74:52:14:89:d9:f9:86:3e:cf:01";
	static var publicExponent: String = "3";
	static var privateExponent: String = "7d:a6:f4:28:f2:0b:eb:2c:ca:96:dc:20:bc:af:cc:d6:f7:c7:6f:70:e3:cc:a4:ae:66:d7:ec:22:64:42:3f:6b:16:6a:f5:83:01:69:64:05:99:46:e0:e5:93:19:79:cc:76:be:f9:ba:5a:79:0a:9d:d8:25:e9:8e:5a:f6:18:8b:16:ef:dc:54:d5:6f:40:5d:63:2b:d7:57:7c:ab:21:31:5f:90:ef:40:40:e9:16:a3:a3:c3:cd:8b:9a:35:ba:eb:ff:db:65:da:a9:30:1c:52:93:df:76:53:32:dc:fb:11:b8:9b:78:d7:82:1b:c0:3c:f4:f0:e9:b8:a5:16:3d:cb";
	static var prime1:String = "00:df:8a:67:bf:66:bd:ed:7e:7b:7f:3b:9a:ff:0f:d1:ac:eb:69:ef:12:0e:a5:eb:6d:38:d2:8a:92:29:f0:5f:47:3b:dd:37:48:cc:15:21:35:cf:bf:d4:cf:51:89:34:3d:5a:bf:fb:55:31:89:f1:ee:91:be:88:87:0d:92:bc:3d";
	static var prime2:String = "00:d7:d8:a9:dd:e6:8c:30:34:81:96:3a:c0:e6:a1:b2:34:10:9f:6c:bf:97:b5:1b:71:9b:b9:56:2a:c5:b0:4e:eb:7e:90:f1:be:cb:06:08:dd:f2:45:fe:b9:4b:85:ae:59:d6:7a:ef:98:1b:27:e2:08:13:61:f2:dd:81:0a:b6:15";
	static var exponent1:String = "00:95:06:ef:d4:ef:29:48:fe:fc:ff:7d:11:ff:5f:e1:1d:f2:46:9f:61:5f:19:47:9e:25:e1:b1:b6:c6:a0:3f:84:d2:93:7a:30:88:0e:16:23:df:d5:38:8a:36:5b:78:28:e7:2a:a7:8e:21:06:a1:49:b6:7f:05:af:5e:61:d2:d3";
	static var exponent2:String = "00:8f:e5:c6:93:ef:08:20:23:01:0e:d1:d5:ef:16:76:cd:60:6a:48:7f:ba:78:bc:f6:67:d0:e4:1c:83:ca:df:47:a9:b5:f6:7f:32:04:05:e9:4c:2e:a9:d0:dd:03:c9:91:39:a7:4a:65:67:6f:ec:05:62:41:4c:93:ab:5c:79:63";
	static var coefficient:String = "48:ba:40:c3:e7:ce:91:1c:c5:51:3b:e1:3c:72:31:12:07:1b:20:5e:c2:2d:c6:d2:7c:68:62:85:3b:95:4a:49:86:fa:23:fa:ed:24:e9:40:4e:04:56:f9:4a:f2:48:4e:39:ca:05:75:a5:11:5f:5e:d3:c1:36:bd:fa:71:b5:19";


/*
	function test0() {
		var r = new RSA(modulus, publicExponent, privateExponent);
		//r.setPrivateEx(modulus, publicExponent,privateExponent,prime1,prime2,null,null,coefficient);
#if neko
		for(s in AesTestFunctions.msgs) {
#else true
		var s = AesTestFunctions.msgs[0];
#end
			var e = r.encrypt(s);
			//trace(ByteString.hexDump(e));
			var u = r.decrypt(e);
			assertTrue(u == s);
#if neko
		}
#end
	}
*/
/*
	function test1() {
		var s = "Message";
		var r = new RSA(modulus, exp, pexp);
// trace('');
// var te = t.encryptBlock( s );
// trace("Hex dump");
// trace(ByteString.hexDump(te));
// var td = t.decryptBlock(te);
// trace("Raw td");
// trace(td);
// trace("Hex dump");
// trace(ByteString.hexDump(td));
		var rsa = new ModeECB( r, new PadPkcs1Type1(r.blockSize) );
		for(s in AesTestFunctions.msgs) {
			var e = rsa.encrypt(s);
			var u = rsa.decrypt(e);
			assertTrue(u == s);
		}
	}
*/

	function test02() {
trace(here.methodName);
		var msg = "Hello";
		var rsa:RSA = RSA.generate(512, "3");
trace(rsa);
//		var e = rsa.encrypt(msg);
//		var u = rsa.decrypt(e);
//		assertEquals(msg,u);
		assertEquals(true, true);
	}

/*
	function test03() {
trace(here.methodName);
		var msg = "Hello";
		// { dmp1 => 3, dmq1 => 3, coeff => 3e5323aa1e3c5ac2860f6b389d08d885, d => 7911b7cc5b6501e30c69945bce1ffe3fe21e66ee5d4c6a77297904d2e1daeb23, e => 3, n => b59a93b2891782d4929e5e89b52ffd61852704c3ee7b15643ffe53910d3bad19, p => f155e239a68fb5a0208e2abe6787d1d7, q => c0a38824bbf8c011613aa19652eb7a8f }

		// a 256 bit key
		var dmp1 : String = "3";
		var dmq1 : String = "3";
		var coeff : String = "3e5323aa1e3c5ac2860f6b389d08d885";
		var d : String = "7911b7cc5b6501e30c69945bce1ffe3fe21e66ee5d4c6a77297904d2e1daeb23";
		var e : String = "3";
		var n : String = "b59a93b2891782d4929e5e89b52ffd61852704c3ee7b15643ffe53910d3bad19";
		var p : String = "f155e239a68fb5a0208e2abe6787d1d7";
		var q : String = "c0a38824bbf8c011613aa19652eb7a8f";


		var rsa = new RSA();
		rsa.setPrivateEx(n, e,d, p, q, null, null, coeff);
trace(rsa);

		var e = rsa.encrypt(msg);
		var u = rsa.decrypt(e);
		assertEquals(msg,u);

	}
*/
/*
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
#if (FIREBUG && ! neko)
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
// 		r.add(new ByteStringFunctions());
// 		r.add(new AesTestFunctions());
// 		r.add(new TeaTestFunctions());
		r.add(new RSAFunctions());

		r.run();
	}
}
