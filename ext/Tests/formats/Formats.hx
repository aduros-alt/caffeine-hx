import formats.der.PEM;
import crypt.RSA;

class TestPEM extends haxe.unit.TestCase {
	function test01() {
		var rsap = PEM.readRSAPublicKey(Formats.RsaPrivKeyPem);
		// it is a private, not a public key PEM
		assertEquals(null, rsap);
		rsap = PEM.readRSAPrivateKey(Formats.RsaPrivKeyPem);
	}

	function test02() {
		var rsap = PEM.readRSAPublicKey(Formats.RsaPubKeyPem);
		assertTrue(rsap != null);
	}

	function test03() {
		var rsapriv = PEM.readRSAPrivateKey(Formats.RsaPrivKeyPem);
		var rsapub = PEM.readRSAPublicKey(Formats.RsaPubKeyPem);
		var msg = "Hello";
		var enc = rsapub.encrypt(msg);
		var dec = rsapriv.decrypt(enc);
		assertEquals(msg, dec);
	}
}


class Formats {
	static function main()
	{
#if (FIREBUG && !neko)
		if(haxe.Firebug.detect()) {
			haxe.Firebug.redirectTraces();
		}
#end
		var r = new haxe.unit.TestRunner();
		r.add(new TestPEM());
		r.run();
	}


	static public var RsaPrivKeyPem : String =
"-----BEGIN RSA PRIVATE KEY-----
MIICWwIBAAKBgQC8em49axHgwy/iSjEbB7NCc6snKVWy9wWaQ+IzlmNfIKGgcESC
HhYIZepRWFymNrKyHnaXh7WP7MQ43lWIcSTSWcrcHI1w/j8R1zlfILI1qwtiwrIH
uKjUSjGVDlbxRpS6N0HPlONUj5/VBQVpWlsxxiQgMI/bdFIUidn5hj7PAQIBAwKB
gH2m9CjyC+ssypbcILyvzNb3x29w48ykrmbX7CJkQj9rFmr1gwFpZAWZRuDlkxl5
zHa++bpaeQqd2CXpjlr2GIsW79xU1W9AXWMr11d8qyExX5DvQEDpFqOjw82LmjW6
6//bZdqpMBxSk992UzLc+xG4m3jXghvAPPTw6bilFj3LAkEA34pnv2a97X57fzua
/w/RrOtp7xIOpettONKKkinwX0c73TdIzBUhNc+/1M9RiTQ9Wr/7VTGJ8e6RvoiH
DZK8PQJBANfYqd3mjDA0gZY6wOahsjQQn2y/l7UbcZu5VirFsE7rfpDxvssGCN3y
Rf65S4WuWdZ675gbJ+IIE2Hy3YEKthUCQQCVBu/U7ylI/vz/fRH/X+Ed8kafYV8Z
R54l4bG2xqA/hNKTejCIDhYj39U4ijZbeCjnKqeOIQahSbZ/Ba9eYdLTAkEAj+XG
k+8IICMBDtHV7xZ2zWBqSH+6eLz2Z9DkHIPK30eptfZ/MgQF6UwuqdDdA8mROadK
ZWdv7AViQUyTq1x5YwJASLpAw+fOkRzFUTvhPHIxEgcbIF7CLcbSfGhihTuVSkmG
+iP67STpQE4EVvlK8khOOcoFdaURX17TwTa9+nG1GQ==
-----END RSA PRIVATE KEY-----";

	static public var RsaPubKeyPem : String =
"-----BEGIN PUBLIC KEY-----
MIGdMA0GCSqGSIb3DQEBAQUAA4GLADCBhwKBgQC8em49axHgwy/iSjEbB7NCc6sn
KVWy9wWaQ+IzlmNfIKGgcESCHhYIZepRWFymNrKyHnaXh7WP7MQ43lWIcSTSWcrc
HI1w/j8R1zlfILI1qwtiwrIHuKjUSjGVDlbxRpS6N0HPlONUj5/VBQVpWlsxxiQg
MI/bdFIUidn5hj7PAQIBAw==
-----END PUBLIC KEY-----";

}


