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
 * THIS SOFTWARE IS PROVIDED BY THE CAFFEINE-HX PROJECT CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE CAFFEINE-HX PROJECT CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

/*
 * Derived from AS3 implementation Copyright (c) 2007 Henri Torgemane
 */
/**
 * PEM
 */
package formats.der;
import crypt.RSA;
import crypt.RSAEncrypt;
import math.BigInteger;
import formats.Base64;
import ByteString;

class PEM
{
	private static var RSA_PRIVATE_KEY_HEADER:String = "-----BEGIN RSA PRIVATE KEY-----";
	private static var RSA_PRIVATE_KEY_FOOTER:String = "-----END RSA PRIVATE KEY-----";
	private static var RSA_PUBLIC_KEY_HEADER:String = "-----BEGIN PUBLIC KEY-----";
	private static var RSA_PUBLIC_KEY_FOOTER:String = "-----END PUBLIC KEY-----";
	private static var CERTIFICATE_HEADER:String = "-----BEGIN CERTIFICATE-----";
	private static var CERTIFICATE_FOOTER:String = "-----END CERTIFICATE-----";

	/**
		*
		* Read a structure encoded according to
		* ftp://ftp.rsasecurity.com/pub/pkcs/ascii/pkcs-1v2.asc
		* section 11.1.2
		*
		* @param str
		* @return
		*
		*/
	public static function readRSAPrivateKey(str:String):RSA {
		var der:ByteString = extractBinary(RSA_PRIVATE_KEY_HEADER, RSA_PRIVATE_KEY_FOOTER, str);
		if (der==null) return null;
		var obj : IAsn1Type = DER.parse(der);
		if (Std.is(obj,Set) || Std.is(obj, Sequence))
		{
			var arr:Sequence = cast(obj, Sequence);
			var rsa = new RSA();
			// arr[0] is Version. should be 0. should be checked.
			rsa.setPrivateEx(
				arr.get(1).toRadix(16),		// N
				arr.get(2).toRadix(16),		// E
				arr.get(3).toRadix(16),		// D
				arr.get(4).toRadix(16),		// P
				arr.get(5).toRadix(16),		// Q
				arr.get(6).toRadix(16),		// DMP1
				arr.get(7).toRadix(16),		// DMQ1
				arr.get(8).toRadix(16)		// IQMP
			);
			return rsa;
		}
		return null;
	}


	/**
		* Read a structure encoded according to some spec somewhere
		* Also, follows some chunk from
		* ftp://ftp.rsasecurity.com/pub/pkcs/ascii/pkcs-1v2.asc
		* section 11.1
		*
		* @param str
		* @return
		*
		*/
	public static function readRSAPublicKey(str:String) : RSAEncrypt
	{
		try {
		var der:ByteString = extractBinary(RSA_PUBLIC_KEY_HEADER, RSA_PUBLIC_KEY_FOOTER, str);
		if (der==null || der.length == 0) return null;
		var obj : IAsn1Type = DER.parse(der);
		if (Std.is(obj,Set) || Std.is(obj, Sequence)) {
			var seq:Sequence = cast obj;
			// seq[0] = [ <some crap that means "rsaEncryption">, null ]; ( apparently, that's an X-509 Algorithm Identifier.
			if (seq.getContainer(0).get(0).toString() != OID.RSA_ENCRYPTION)
				return null;

			// seq[1] is a ByteString begging to be parsed as DER
			// there's a 0x00 byte up front. find out why later.
			untyped seq.get(1).position = 0;
			obj = DER.parse(seq.get(1));
			if (Std.is(obj,Set) || Std.is(obj, Sequence))
			{
				seq = cast obj;
				// seq[0] = modulus
				// seq[1] = public expt.
				return new RSAEncrypt(seq.get(0).toRadix(16), seq.get(1).toRadix(16));
			} else {
				return null;
			}
		} else {
			// dunno
			return null;
		}
		}
		catch(e:Dynamic) {
			return null;
		}
	}

	public static function readCertIntoArray(str:String):ByteString {
		var tmp:ByteString = extractBinary(CERTIFICATE_HEADER, CERTIFICATE_FOOTER, str);
		return tmp;
	}

	private static function extractBinary(header:String, footer:String, str:String) : ByteString {
		var i:Int = str.indexOf(header);
		if (i==-1) return null;
		i += header.length;
		var j:Int = str.indexOf(footer);
		if (j==-1) return null;
		return ByteString.ofString(formats.Base64.decode(str.substr(i, j-i)));
	}
}

