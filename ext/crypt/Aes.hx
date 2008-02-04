/*
 * Copyright (c) 2008, The Caffeine-hx project contributors
 * Original author : Russell Weir
 * Contributors:
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE HAXE PROJECT CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE HAXE PROJECT CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */

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
