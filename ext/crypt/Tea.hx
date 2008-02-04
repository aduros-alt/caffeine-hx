/*
XXTEA Algorithm
Neko code
© 2007 Russell Weir
Adapted from Javascript implementation
© 2002-2005 Chris Veness
http://www.movable-type.co.uk/

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this library; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
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

