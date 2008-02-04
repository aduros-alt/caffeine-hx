/*
Haxe Crypt Base
© 2007 Russell Weir
© 2002-2005 Chris Veness

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

enum CryptMode {
	CBC;
	ECB;
}

class Base {
	public static var HEXU : String = "0123456789ABCDEF";
	public static var HEXL : String = "0123456789abcdef";

	public var mode(default,setMode) : CryptMode;

	public function new() {
		mode = ECB;
	}

	public function encrypt(msg : String) : String {
		throw "override";
		return "";
	}

	public function decrypt(msg : String) : String {
		throw "override";
		return "";
	}

	function setMode(m : CryptMode) : CryptMode {
		mode = m;
		return m;
	}

	function modeError() {
		throw "Mode not supported";
	}

	public static function charCodeAt(s, pos) {
		if(pos >= s.length)
			return 0;
		return Std.ord(s.substr(pos,1));
	}

	// perform NULL padding with padToBytes
	public static function intArrayToString(a: Array<Int>, ?padToBytes:Int) {
		var sb = new StringBuf();
		for(i in a)
			sb.add(Std.chr(i));
		if(padToBytes > 0) {
			var r = padToBytes - (a.length % padToBytes);
			for(i in 0...r) {
				sb.add(Std.chr(0));
			}
		}
		return sb.toString();
	}


	// convert string to array of longs, each containing 4 chars
	// note chars must be within ISO-8859-1
	// (with Unicode code-point < 256) to fit 4/long
#if neko
	public static function strToLongs(s : String) : Array<neko.Int32>
#else true
	public static function strToLongs(s : String) : Array<Int>
#end
	{
		var len = Math.ceil(s.length/4);
		var a = new Array();

		for(i in 0...len) {
			// note little-endian encoding - endianness is irrelevant
			//as long as it is the same in longsToStr()
#if neko
			var j = neko.Int32.ofInt(charCodeAt(s,i*4));
			var k = neko.Int32.ofInt(charCodeAt(s,i*4+1)<<8);
			var l = neko.Int32.ofInt(charCodeAt(s,i*4+2)<<16);
			var m = neko.Int32.ofInt(charCodeAt(s,i*4+3));
			m = neko.Int32.shl(m,24);
			a[i] = neko.Int32.add(j,k);
			a[i] = neko.Int32.add(a[i],l);
			a[i] = neko.Int32.add(a[i],m);
#else true
			a[i] = charCodeAt(s,i*4) + (charCodeAt(s,i*4+1)<<8) +
			(charCodeAt(s,i*4+2)<<16) + (charCodeAt(s,i*4+3)<<24);
#end
		}
		// note running off the end of the string generates nulls since
		// bitwise operators treat NaN as 0
		return a;
	}

	// convert array of longs back to string
#if neko
	public static function longsToStr(l : Array<neko.Int32>) {
#else true
	public static function longsToStr(l : Array<Int>) {
#end
		var a = new Array<String>();
		for(i in 0...l.length) {
			var sb = new StringBuf();

#if neko
			sb.add(Std.chr(
				neko.Int32.toInt(
					neko.Int32.and(
						l[i],
						neko.Int32.ofInt(0xFF)
					)
				)
			));
			sb.add(Std.chr(
				neko.Int32.toInt(
					neko.Int32.and(
						neko.Int32.ushr(l[i],8),
						neko.Int32.ofInt(0xFF)
					)
				)
			));
			sb.add(Std.chr(
				neko.Int32.toInt(
					neko.Int32.and(
						neko.Int32.ushr(l[i],16),
						neko.Int32.ofInt(0xFF)
					)
				)
			));
			sb.add(Std.chr(
				neko.Int32.toInt(
					neko.Int32.and(
						neko.Int32.ushr(l[i],24),
						neko.Int32.ofInt(0xFF)
					)
				)
			));
#else true
			sb.add(Std.chr(l[i] & 0xFF));
			sb.add(Std.chr(l[i]>>>8 & 0xFF));
			sb.add(Std.chr(l[i]>>>16 & 0xFF));
			sb.add(Std.chr(l[i]>>>24 & 0xFF));
#end
			a[i] = sb.toString();
		}
		return a.join('');
	}

/*
	// escape control chars etc which might cause problems with encrypted texts
	public static function escCtrlCh(str) {
		var er : EReg = ~/[\0\t\n\v\f\r\xa0'"!]/g;
		return er.replace(str,
			function(c) {
				return '!' + Base.charCodeAt(c,0) + '!';
			}
		);
	}

	// unescape potentially problematic nulls and control characters
	public static function unescCtrlCh(str) {
		var er : EReg = ~/!\d\d?\d?!/g;
		return er.replace(str, function(c) { return Std.chr(c.substr(1,-1)); });
	}
*/
}
