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
class Tea extends BasePhrase {
	public function new(password) {
		super(password);
	}

	public function encrypt(plaintext : String) : String {
		if (plaintext.length == 0) return('');
		// 'escape' plaintext so chars outside ISO-8859-1
		// work in single-byte packing, but keep
		// spaces as spaces (not '%20') so encrypted
		//text doesn't grow too long (quick & dirty)
		//var asciitext = escape(plaintext).replace(/%20/g,' ');
		var asciitext = StringTools.urlEncode(plaintext);
		var er : EReg = ~/%20/g;
		asciitext = er.replace(asciitext,' ');
trace(asciitext);

		// convert to array of longs
		// algorithm doesn't work for n<2 so fudge by adding a null
		var v = Base.strToLongs(asciitext);
trace(v);
		if (v.length <= 1)
#if neko
			v[1] = neko.Int32.ofInt(0);
#else true
			v[1] = 0;
#end

		// simply convert first 16 chars of passphrase as key
		var k = Base.strToLongs(passphrase.substr(0,16));
		var n = v.length;

		var z = v[n-1], y = v[0], delta = 0x9E3779B9;
		var mx, e, q = Math.floor(6 + 52/n), sum = 0;

		// 6 + 52/n operations gives between 6 & 32 mixes
		// on each word
		while (q-- > 0) {
			sum += delta;
			e = sum>>>2 & 3;
			for(p in 0...n) {
				y = v[(p+1)%n];
				mx = (z>>>5 ^ y<<2) + (y>>>3 ^ z<<4) ^ (sum^y) + (k[p&3 ^ e] ^ z);
				z = v[p] += mx;
			}
		}

		var ciphertext = Base.longsToStr(v);

		return ciphertext;
		//return Base.escCtrlCh(ciphertext);
	}

	//
	// TEAdecrypt: Use Corrected Block TEA to decrypt ciphertext
	//
	public function decrypt(ciphertext : String) : String
	{
		if (ciphertext.length == 0) return('');
		//var v = strToLongs(unescCtrlCh(ciphertext));
		var v = Base.strToLongs(ciphertext);
		var k = Base.strToLongs(passphrase.substr(0,16));
		var n = v.length;

		var z = v[n-1], y = v[0], delta = 0x9E3779B9;
		var mx, e, q = Math.floor(6 + 52/n), sum = q*delta;

		while (sum != 0) {
			e = sum>>>2 & 3;
			var p = n - 1;
			while(p-->=0) {
			//for (var p = n-1; p >= 0; p--) {
				z = v[p>0 ? p-1 : n-1];
				mx = (z>>>5 ^ y<<2) + (y>>>3 ^ z<<4) ^ (sum^y) + (k[p&3 ^ e] ^ z);
				y = v[p] -= mx;
			}
			sum -= delta;
		}

		var plaintext = Base.longsToStr(v);

		// strip trailing null chars resulting
		//from filling 4-char blocks:
		var er : EReg = ~/\0+$/;
		plaintext = er.replace(plaintext,'');

		return StringTools.urlDecode(plaintext);
	}

}

