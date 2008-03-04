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
import math.BigInteger;
import com.hurlant.util.Base64;
import ByteString;
import com.hurlant.util.Hex;


class PEM
{
	private static RSA_PRIVATE_KEY_HEADER:String = "-----BEGIN RSA PRIVATE KEY-----";
	private static RSA_PRIVATE_KEY_FOOTER:String = "-----END RSA PRIVATE KEY-----";
	private static RSA_PUBLIC_KEY_HEADER:String = "-----BEGIN PUBLIC KEY-----";
	private static RSA_PUBLIC_KEY_FOOTER:String = "-----END PUBLIC KEY-----";
	private static CERTIFICATE_HEADER:String = "-----BEGIN CERTIFICATE-----";
	private static CERTIFICATE_FOOTER:String = "-----END CERTIFICATE-----";

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
		var obj:Dynamic = DER.parse(der);
		if (Std.is(obj, Sequence) || Type.getClassName(Type.getSuperClass(obj)) == "formats.der.Sequence")
		{
			var arr:Array = cast(obj, Sequence);
			// arr[0] is Version. should be 0. should be checked. shoulda woulda coulda.
			return new RSA(
				arr.get(1),				// N
				arr.get(2).valueOf(),	// E
				arr.get(3),				// D
				arr.get(4),				// P
				arr.get(5),				// Q
				arr.get(6),				// DMP1
				arr.get(7),				// DMQ1
				arr.get(8)				// IQMP
			);
		} else {
			return null;
		}
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
	public static function readRSAPublicKey(str:String):RSAEncrypt {
		var der:ByteString = extractBinary(RSA_PUBLIC_KEY_HEADER, RSA_PUBLIC_KEY_FOOTER, str);
		if (der==null) return null;
		var obj:Dynamic = DER.parse(der);
		if (obj is Array) {
			var arr:Array = obj as Array;
			// arr[0] = [ <some crap that means "rsaEncryption">, null ]; ( apparently, that's an X-509 Algorithm Identifier.
			if (arr[0][0].toString()!=OID.RSA_ENCRYPTION) {
				return null;
			}
			// arr[1] is a ByteString begging to be parsed as DER
			arr[1].position = 1; // there's a 0x00 byte up front. find out why later. like, read a spec.
			obj = DER.parse(arr[1]);
			if (obj is Array) {
				arr = obj as Array;
				// arr[0] = modulus
				// arr[1] = public expt.
				return new RSA(arr[0], arr[1]);
			} else {
				return null;
			}
		} else {
			// dunno
			return null;
		}
	}

	public static function readCertIntoArray(str:String):ByteString {
		var tmp:ByteString = extractBinary(CERTIFICATE_HEADER, CERTIFICATE_FOOTER, str);
		return tmp;
	}

	private static function extractBinary(header:String, footer:String, str:String):ByteString {
		var i:Int = str.indexOf(header);
		if (i==-1) return null;
		i += header.length;
		var j:Int = str.indexOf(footer);
		if (j==-1) return null;
		var b64:String = str.substring(i, j);
		// remove whitespaces.
		b64 = b64.replace(/\s/mg, '');
		// decode
		return Base64.decodeToByteString(b64);
	}

}