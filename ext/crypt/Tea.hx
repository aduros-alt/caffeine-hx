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

package crypt;

#if neko
import neko.Int32;

enum XXTeaKey {
}
#end

class Tea implements IBlockCipher {
#if neko
	var k : XXTeaKey;
#else true
	var k : Array<Int>; // 16 bytes of key material
#end
	public var blockSize(getBlockSize,null) : Int;

	public function new(key : String) {
#if !neko
		k = ByteString.strToInt32(
				ByteString.nullPadString(key.substr(0,16), 16)
		);
#else true
		var m = ByteString.strToInt32(
				ByteString.nullPadString(key.substr(0,16), 16)
		);
		k = xxtea_create_key(I32.mkNekoArray(m));
#end
		blockSize = 8;
	}

	public function toString() : String {
		return "xxtea";
	}

	function getBlockSize() : Int {
		return this.blockSize;
	}

	public function setBlocksize( i : Int ) : Int {
		if(i == 0 || i % 4 != 0)
			throw "xxtea: block size must be multiple of 4";
		blockSize = i;
		return i;
	}

#if neko
	public function encryptBlock(plaintext : String) : String {
		if (plaintext.length == 0) return('');
		var v : Array<neko.Int32> = ByteString.strToInt32(plaintext);
		var n = v.length;
		if (n == 1)
			v[n++] = neko.Int32.ofInt(0);
		var rv = xxtea_encrypt_block(
				I32.mkNekoArray(v),
				n,
				k);
		return new String(rv);
	}
#else true
	public function encryptBlock(plaintext : String) : String {
		if (plaintext.length == 0) return('');
		var v = ByteString.strToInt32(plaintext);
		var n = v.length;
		if (n == 1)
			v[n++] = 0;

		var delta = 0x9e3779B9;
		var e : Int;
		var mx : Int;
		var q = Std.int(6 + 52/n);
		var y = v[0];
		var z = v[n-1];
		var sum = 0;

		while (q-- > 0) {
			sum += delta;
			e = sum >>> 2 & 3;
			//for (p=0; p<n-1; p++) y = v[p+1], z = v[p] += MX;
			var p = 0;
			while(p < n-1) {
				y = v[(p+1)];
				mx = (((z>>>5)^(y<<2)) + ((y>>>3)^(z<<4))) ^ ((sum^y) + (k[(p&3)^e]^z));
				z = v[p] += mx;
				p ++;
			}
			y = v[0];
			z = v[n-1] += (z>>>5 ^ y<<2) + (y>>>3 ^ z<<4) ^ (sum^y) + (k[p&3^e]^z);
		}
		return ByteString.int32ToString(v);
	}
#end

#if neko
	public function decryptBlock(ciphertext : String) : String {
		if (ciphertext.length == 0) return('');
		var v = ByteString.strToInt32(ciphertext);
		var n = v.length;
		var rv = xxtea_decrypt_block(
				I32.mkNekoArray(v),
				n,
				k);
		return new String(rv);
	}
#else true
	public function decryptBlock(ciphertext : String) : String
	{
		if (ciphertext.length == 0) return('');
		var v = ByteString.strToInt32(ciphertext);
		var n = v.length;

		var delta = 0x9e3779B9;
		var e : Int;
		var mx : Int;
		var q = Std.int(6 + 52/n);
		var y = v[0];
		var z = v[n-1];
		var sum = q * delta;

		while (sum != 0) {
			e = sum >>> 2 & 3;
			var p = n - 1;
			while(p > 0 ) {
				z = v[p-1];
				//mx = (z>>>5 ^ y<<2) + (y>>>3 ^ z<<4) ^ (sum^y) + (k[p&3^e]^z);
				mx = (((z>>>5)^(y<<2)) + ((y>>>3)^(z<<4))) ^ ((sum^y) + (k[(p&3)^e]^z));
				y = v[p] -= mx;
				p--;
			}
			z = v[n-1];
			y = v[0] -= (z>>>5 ^ y<<2) + (y>>>3 ^ z<<4) ^ (sum^y) + (k[p&3^e]^z);
			sum -= delta;
		}
		return ByteString.int32ToString(v);
	}
#end

#if neko
	private static var xxtea_create_key = neko.Lib.load("ncrypt","xxtea_create_key",1);

	private static var xxtea_encrypt_block = neko.Lib.load("ncrypt","xxtea_encrypt_block",3);
	private static var xxtea_decrypt_block = neko.Lib.load("ncrypt","xxtea_decrypt_block",3);
#end
}

