package crypt;
import crypt.Base.CryptMode;

class Aes extends crypt.BaseKeylenPhrase {
	public function new(keylen : Int, passphrase:String) {
		super(keylen, passphrase);
	}

	override function setKeylen(len : Int) {
		if(len != 128 && len != 192 && len != 256)
			keyLengthError();
		keylen = len;
		return len;
	}

	override public function encrypt(msg : String) {
		var rv;
		switch(mode) {
		case ECB:
#if neko
			rv = new String(naes_ecb_encrypt(untyped passphrase.__s, untyped msg.__s, keylen));
#else true
#end
		case CBC:
#if neko
			rv = new String(naes_cbc_encrypt(untyped passphrase.__s, untyped msg.__s, keylen));
#else true
#end
		default:
			modeError();
		}
		if(rv == null)
			return "";
		return rv;
	}

	override public function decrypt(msg : String) {
		var rv;
		switch(mode) {
		case ECB:
#if neko
			rv = new String(naes_ecb_decrypt(untyped passphrase.__s, untyped msg.__s, keylen));
#else true
#end
		case CBC:
#if neko
			rv = new String(naes_cbc_decrypt(untyped passphrase.__s, untyped msg.__s, keylen));
#else true
#end
		default:
			modeError();
		}
		if(rv == null)
			return "";
		return rv;
	}

	//public static function ecb_encrypt(pass:String, msg : String, key_len : Int, mode : CryptMode) {
	//}

#if neko
	//value pass, value msg, value key_len
	private static var naes_ecb_encrypt = neko.Lib.load("ncrypt","naes_ecb_encrypt",3);
	private static var naes_ecb_decrypt = neko.Lib.load("ncrypt","naes_ecb_decrypt",3);
	private static var naes_cbc_encrypt = neko.Lib.load("ncrypt","naes_cbc_encrypt",3);
	private static var naes_cbc_decrypt = neko.Lib.load("ncrypt","naes_cbc_decrypt",3);
#end
}
