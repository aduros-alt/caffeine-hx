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
 * X509Certificate
 *
 **/
package crypto.cert;

import hash.IHash;
import hash.MD5;
import hash.SHA1;
import crypt.RSA;
import formats.Base64;
import formats.der.DERByteString;
import formats.der.DER;
import formats.der.OID;
import formats.der.ObjectIdentifier;
import formats.der.PEM;
import formats.der.PrintableString;
import formats.der.Sequence;
import formats.der.Type;

class X509Certificate {

	private var _loaded:Bool;
	private var _param:Dynamic;
	private var _obj:IAsn1Type;

	public function new(p:Dynamic) {
		_loaded = false;
		_param = p;
		// avoid unnecessary parsing of every builtin CA at start-up.
	}

	private function load():Void {
		if (_loaded) return;
		var p:Dynamic = _param;
		var b:ByteString;
		if (Std.is(p, String))
			b = PEM.readCertIntoArray(cast p);
		else if ( Std.is(p, ByteString))
			b = p;

		if (b != null) {
			_obj = DER.parse(b, Type.TLS_CERT);
			_loaded = true;
		}
		else {
			throw "Invalid x509 Certificate parameter: "+p;
		}
	}

	public function isSigned(store:X509CertificateCollection, CAs:X509CertificateCollection, ?time:Date):Bool
	{
		load();
		// check timestamps first. cheapest.
		if (time==null) {
			time = Date.now();
		}
		var notBefore:Date = getNotBefore();
		var notAfter:Date = getNotAfter();
		if (time.getTime()<notBefore.getTime()) return false; // cert isn't born yet.
		if (time.getTime()>notAfter.getTime()) return false;  // cert died of old age.
		// check signature.
		var subject:String = getIssuerPrincipal();
		// try from CA first, since they're treated better.
		var parent:X509Certificate = CAs.getCertificate(subject);
		var parentIsAuthoritative:Bool = false;
		if (parent == null) {
			parent = store.getCertificate(subject);
			if (parent == null) {
				return false; // issuer not found
			}
		} else {
			parentIsAuthoritative = true;
		}
		if (parent == this) { // pathological case. aVoid infinite loop
			return false; // isSigned() returns false if we're self-signed.
		}
		if (!(parentIsAuthoritative&&parent.isSelfSigned(time)) &&
			!parent.isSigned(store, CAs, time)) {
			return false;
		}
		var key:RSAEncrypt = parent.getPublicKey();
		return verifyCertificate(key);
	}

	public function isSelfSigned(time:Date):Bool {
		load();

		var key:RSAEncrypt = getPublicKey();
		return verifyCertificate(key);
	}

	private function verifyCertificate(key:RSAEncrypt):Bool {
		var algo:String = getAlgorithmIdentifier();
		var hash:IHash;
		var oid:String;
		switch (algo) {
		case OID.SHA1_WITH_RSA_ENCRYPTION:
			hash = new SHA1;
			oid = OID.SHA1_ALGORITHM;
		case OID.MD2_WITH_RSA_ENCRYPTION:
			throw "can not verify md2";
			//hash = new MD2;
			//oid = OID.MD2_ALGORITHM;
		case OID.MD5_WITH_RSA_ENCRYPTION:
			hash = new MD5;
			oid = OID.MD5_ALGORITHM;
		default:
			return false;
		}
		var data:ByteString = _obj.signedCertificate_bin;
		var buf:ByteString = new ByteString();
		key.verify(_obj.encrypted, buf, _obj.encrypted.length);
		buf.position=0;
		data = ByteString.ofString(hash.calculate(data, true));
		var obj:Object = DER.parse(buf, Type.RSA_SIGNATURE);
		if (obj.algorithm.algorithmId.toString() != oid) {
			return false; // wrong algorithm
		}
		if (!ByteString.eq(obj.hash, data))
			return false; // hashes don't match
		return true;
	}

	/**
	* This isn't used anywhere so far.
	* It would become useful if we started to offer facilities
	* to generate and sign X509 certificates.
	*
	* @param key
	* @param algo
	* @return
	*
	*/
	private function signCertificate(key:RSAKey, algo:String):ByteString {
		var hash:IHash;
		var oid:String;
		switch (algo) {
		case OID.SHA1_WITH_RSA_ENCRYPTION:
			hash = new SHA1;
			oid = OID.SHA1_ALGORITHM;
		case OID.MD2_WITH_RSA_ENCRYPTION:
			throw "Can not parse MD2";
// 				hash = new MD2;
// 				oid = OID.MD2_ALGORITHM;
		case OID.MD5_WITH_RSA_ENCRYPTION:
			hash = new MD5;
			oid = OID.MD5_ALGORITHM;
		default:
			return null
		}
		var data:ByteString = _obj.signedCertificate_bin;
		data = ByteString.ofString(hash.calculate(data, true));
		var seq1:Sequence = new Sequence;
		seq1[0] = new Sequence;
		seq1[0][0] = new ObjectIdentifier(0,0, oid);
		seq1[0][1] = null;
		seq1[1] = new DERByteString();
		seq1[1].writeBytes(data);
		data = seq1.toDER();
		var buf:ByteString = new ByteString();
		key.sign(data, buf, data.length);
		return buf;
	}

	public function getPublicKey():RSAEncrypt {
		load();
		var pk:ByteString = _obj.signedCertificate.subjectPublicKeyInfo.subjectPublicKey as ByteString;
		pk.position = 0;
		var rsaKey:Object = DER.parse(pk, [{name:"N"},{name:"E"}]);
		return new RSAEncrypt(rsaKey.N, rsaKey.E.valueOf());
	}

	/**
	* Returns a subject principal, as an opaque base64 string.
	* This is only used as a hash key for known certificates.
	*
	* Note that this assumes X509 DER-encoded certificates are uniquely encoded,
	* as we look for exact matches between Issuer and Subject fields.
	*
	*/
	public function getSubjectPrincipal():String {
		load();
		return Base64.encodeByteString(_obj.signedCertificate.subject_bin);
	}

	/**
	* Returns an issuer principal, as an opaque base64 string.
	* This is only used to quickly find matching parent certificates.
	*
	* Note that this assumes X509 DER-encoded certificates are uniquely encoded,
	* as we look for exact matches between Issuer and Subject fields.
	*
	*/
	public function getIssuerPrincipal():String {
		load();
		return Base64.encodeByteString(_obj.signedCertificate.issuer_bin);
	}

	public function getAlgorithmIdentifier():String {
		return _obj.algorithmIdentifier.algorithmId.toString();
	}

	public function getNotBefore():Date {
		return _obj.signedCertificate.validity.notBefore.date;
	}

	public function getNotAfter():Date {
		return _obj.signedCertificate.validity.notAfter.date;
	}

	public function getCommonName():String {
		var subject:Sequence = _obj.signedCertificate.subject;
		var ps : PrintableString = cast subject.findAttributeValue(OID.COMMON_NAME);
		return ps.getString();
	}
}
