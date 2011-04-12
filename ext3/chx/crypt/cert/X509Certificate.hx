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

package chx.crypt.cert;

import chx.hash.IHash;
import chx.hash.Md2;
import chx.hash.Md5;
import chx.hash.Sha1;
import chx.crypt.RSA;
import chx.crypt.RSAEncrypt;
import chx.formats.Base64;
import chx.formats.der.DER;
import chx.formats.der.ExtractedBytes;
import chx.formats.der.IAsn1Type;
import chx.formats.der.IContainer;
import chx.formats.der.OctetString;
import chx.formats.der.OID;
import chx.formats.der.ObjectIdentifier;
import chx.formats.der.PEM;
import chx.formats.der.PrintableString;
import chx.formats.der.Sequence;
import chx.formats.der.Types;
import chx.formats.der.UTCTime;

/**
 * X509Certificate
 *
 **/
class X509Certificate {

	private var _loaded:Bool;
	private var _param:Dynamic;
	private var _obj:IContainer;

	public function new(p:Dynamic) {
		_loaded = false;
		_param = p;
		// avoid unnecessary parsing of every builtin CA at start-up.
		if(!Std.is(_param, String) && !Std.is(_param, Bytes))
			throw new chx.lang.UnsupportedException("Must be a string or bytes");
	}

	/**
		Check if a certificate is signed by an authority in an X509CertificateCollection.
	**/
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
		if (!(parentIsAuthoritative && parent.isSelfSigned()) &&
			!parent.isSigned(store, CAs, time)) {
			return false;
		}
		var key:RSAEncrypt = parent.getPublicKey();
		return verifyCertificate(key);
	}

	/**
		Check if this certificate is self-signed.
	**/
	public function isSelfSigned():Bool {
		load();
		var key:RSAEncrypt = getPublicKey();
		return verifyCertificate(key);
	}

	/**
		Directly verify a certificate with a public key. Use this when you
		have a public key from a specific CA. To verify from a collection
		of CA's, use isSigned()
	**/
	public function verifyCertificate(key:RSAEncrypt):Bool {
		load();
		var algo:String = getAlgorithmIdentifier();
		var fHash:IHash;
		var oid:String;
		switch (algo) {
		case OID.SHA1_WITH_RSA_ENCRYPTION:
			fHash = new Sha1();
			oid = OID.SHA1_ALGORITHM;
		case OID.MD2_WITH_RSA_ENCRYPTION:
			fHash = new Md2();
			oid = OID.MD2_ALGORITHM;
		case OID.MD5_WITH_RSA_ENCRYPTION:
			fHash = new Md5();
			oid = OID.MD5_ALGORITHM;
		default:
			return false;
		}
		var data:Bytes = cast(_obj.get("signedCertificate_bin"), ExtractedBytes).toDER();
		var bs : Bytes = cast _obj.get("encrypted");
		var rv = key.verify(bs);//.toHex());
		var buf:Bytes = rv;// = Byte.ofString(rv);
		//buf.position=0;
		data = fHash.calcBin(data);
		var obj:IContainer = cast DER.read(buf, Types.RSA_SIGNATURE);
		if (untyped obj.get("algorithm").get("algorithmId").toString() != oid) {
			return false; // wrong algorithm
		}
		//if (!ByteString.eq(obj.getKey("hash"), data))
		if(data.compare(cast obj.get("hash")) != 0)
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
	* @todo test
	*/
	private function signCertificate(key:RSA, algo:String):Bytes {
		var fHash:IHash;
		var oid:String;
		switch (algo) {
		case OID.SHA1_WITH_RSA_ENCRYPTION:
			fHash = new Sha1();
			oid = OID.SHA1_ALGORITHM;
		case OID.MD2_WITH_RSA_ENCRYPTION:
			fHash = new Md2();
			oid = OID.MD2_ALGORITHM;
		case OID.MD5_WITH_RSA_ENCRYPTION:
			fHash = new Md5();
			oid = OID.MD5_ALGORITHM;
		default:
			return null;
		}
		var data:Bytes = cast(_obj.get("signedCertificate_bin"),ExtractedBytes).toDER() ;
		data = fHash.calcBin(data);
		var seq2:Sequence = new Sequence();
		seq2.set(0, new ObjectIdentifier(oid));
		seq2.set(1, null);
		var dbs = new OctetString(data);
		var seq1:Sequence = new Sequence();
		seq1.set(0, seq2);
		seq1.set(1, dbs);
		return key.sign(seq1.toDER());
	}

	/**
		Returns the RSA public key from the certificate.
	**/
	public function getPublicKey():RSAEncrypt {
		load();
		var o = untyped _obj.get("signedCertificate").get("subjectPublicKeyInfo").get("subjectPublicKey");
		var pk:OctetString = cast o;
		var rsaKey:IContainer = cast DER.read(pk, cast [{name:"N"},{name:"E"}]);
		var n : String = untyped rsaKey.get("N").toHex();
		var e : String = untyped rsaKey.get("E").toHex();
		return new RSAEncrypt(n, e);
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
		var eb:ExtractedBytes = cast untyped _obj.get("signedCertificate").get("subject_bin");
		return Base64.encode(eb.toDER());
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
		var eb:ExtractedBytes = cast untyped _obj.get("signedCertificate").get("issuer_bin");
		return Base64.encode(eb.toDER());
	}

	public function getAlgorithmIdentifier():String {
		load();
		return untyped _obj.get("algorithmIdentifier").get("algorithmId").toString();
	}

	/**
		Returns the starting date for a cert.
	**/
	public function getNotBefore():Date {
		load();
		var d : UTCTime = cast untyped _obj.get("signedCertificate").get("validity").get("notBefore").get("date");
		return d.getDate();
	}

	/**
		Returns the expiry date of a cert.
	**/
	public function getNotAfter():Date {
		load();
		var d : UTCTime = cast untyped _obj.get("signedCertificate").get("validity").get("notAfter").get("date");
		return d.getDate();
	}

	public function getCommonName():String {
		load();
		var subject:Sequence = cast untyped _obj.get("signedCertificate").get("subject");
		if(subject == null) throw "No subject";
		var ps : PrintableString = null;
		//try {
			ps = cast subject.findAttributeValue(OID.COMMON_NAME);
		//} catch(e:Dynamic) {}
		if(ps == null)
			return null;
		return ps.getString();
	}

	////////////////////////////////////////////////////////
	//               Private methods                      //
	////////////////////////////////////////////////////////
	private function load():Void {
		if (_loaded) return;
		var b:Bytes = null;
		if (Std.is(_param, String))
			b = PEM.readCertIntoBytes(cast _param);
		else if ( Std.is(_param, Bytes))
			b = cast _param;

		if (b != null) {
			_obj = cast DER.read(b, Types.TLS_CERT);
			#if CAFFEINE_DEBUG
				trace(_obj);
			#end
			_loaded = true;
		}
		else {
			throw "Invalid x509 Certificate parameter: "+_param;
		}
	}
}
