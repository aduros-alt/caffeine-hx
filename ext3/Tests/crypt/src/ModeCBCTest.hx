/**
 * ModeCBCTest
 *
 * A test class for ModeCBC
 * Copyright (c) 2007 Henri Torgemane
 *
 * See LICENSE.txt for full license information.
 */

import chx.crypt.Aes;
import chx.crypt.ModeCBC;
import chx.crypt.PadNone;
import chx.crypt.XXTea;

import haxe.unit.TestCase;

class ModeCBCTest extends TestCase
{

	public static function main() {
#if (FIREBUG && ! neko)
		if(haxe.Firebug.detect()) {
			haxe.Firebug.redirectTraces();
		}
#end
		var r = new haxe.unit.TestRunner();
		r.add(new ModeCBCTest());

		r.run();
	}

	/**
	* Hawt NIST Vectors: http://csrc.nist.gov/publications/nistpubs/800-38a/sp800-38a.pdf
	* Section F.2.1 and below.
	*/
	public function testCBC_AES128():Void {
		var key:Bytes = Bytes.ofHex("2b7e151628aed2a6abf7158809cf4f3c");
		var pt:Bytes = Bytes.ofHex(
			"6bc1bee22e409f96e93d7e117393172a" +
			"ae2d8a571e03ac9c9eb76fac45af8e51" +
			"30c81c46a35ce411e5fbc1191a0a52ef" +
			"f69f2445df4f9b17ad2b417be66c3710");
		var ct:Bytes = Bytes.ofHex(
			"7649abac8119b246cee98e9b12e9197d" +
			"5086cb9b507219ee95db113a917678b2" +
			"73bed6b8e3c1743b7116e69e22229516" +
			"3ff1caa1681fac09120eca307586e1a7");
		var cbc:ModeCBC = new ModeCBC(new Aes(128,key), new PadNone());
		cbc.iv = Bytes.ofHex("000102030405060708090a0b0c0d0e0f");
		cbc.setPrependMode(false);

		var src : Bytes = cbc.encrypt(pt);
		assertEquals(src.toHex(), ct.toHex());
		src = cbc.decrypt(src);
		assertEquals(src.toHex(), pt.toHex());
	}

	public function testCBC_AES192():Void {
		var key:Bytes = Bytes.ofHex("8e73b0f7da0e6452c810f32b809079e562f8ead2522c6b7b");
		var pt:Bytes = Bytes.ofHex(
			"6bc1bee22e409f96e93d7e117393172a" +
			"ae2d8a571e03ac9c9eb76fac45af8e51" +
			"30c81c46a35ce411e5fbc1191a0a52ef" +
			"f69f2445df4f9b17ad2b417be66c3710");
		var ct:Bytes = Bytes.ofHex(
			"4f021db243bc633d7178183a9fa071e8" +
			"b4d9ada9ad7dedf4e5e738763f69145a" +
			"571b242012fb7ae07fa9baac3df102e0" +
			"08b0e27988598881d920a9e64f5615cd");
		var cbc:ModeCBC = new ModeCBC(new Aes(192,key), new PadNone());
		cbc.iv = Bytes.ofHex("000102030405060708090a0b0c0d0e0f");
		cbc.setPrependMode(false);

		var src = cbc.encrypt(pt);
		assertEquals( src.toHex(), ct.toHex());
		src = cbc.decrypt(src);
		assertEquals( src.toHex(), pt.toHex());
	}

	public function testCBC_AES256():Void {
		var key:Bytes = Bytes.ofHex(
			"603deb1015ca71be2b73aef0857d7781" +
			"1f352c073b6108d72d9810a30914dff4");
		var pt:Bytes = Bytes.ofHex(
			"6bc1bee22e409f96e93d7e117393172a" +
			"ae2d8a571e03ac9c9eb76fac45af8e51" +
			"30c81c46a35ce411e5fbc1191a0a52ef" +
			"f69f2445df4f9b17ad2b417be66c3710");
		var ct:Bytes = Bytes.ofHex(
			"f58c4c04d6e5f1ba779eabfb5f7bfbd6" +
			"9cfc4e967edb808d679f777bc6702c7d" +
			"39f23369a9d9bacfa530e26304231461" +
			"b2eb05e2c39be9fcda6c19078c6a9d1b");
		var cbc:ModeCBC = new ModeCBC(new Aes(256,key), new PadNone());
		cbc.iv = Bytes.ofHex("000102030405060708090a0b0c0d0e0f");
		cbc.setPrependMode(false);

		var src = cbc.encrypt(pt);
		assertEquals( src.toHex(), ct.toHex());
		src = cbc.decrypt(src);
		assertEquals( src.toHex(), pt.toHex());
	}


	/**
		* For now the main goal is to show we can decrypt what we encrypt in this mode.
		* Eventually, this should get correlated with some well known vectors.
		*/
	public function testAES():Void {
		var keys:Array<String> = [
		"00010203050607080A0B0C0D0F101112",
		"14151617191A1B1C1E1F202123242526"];
		var cts:Array<String> = [
		"D8F532538289EF7D06B506A4FD5BE9C94894C5508A8D8E29AB600DB0261F0555A8FA287B89E65C0973F1F8283E70C72863FE1C8F1F782084CE05626E961A67B3",
		"59AB30F4D4EE6E4FF9907EF65B1FB68C96890CE217689B1BE0C93ED51CF21BB5A0101A8C30714EC4F52DBC9C6F4126067D363F67ABE58463005E679B68F0B496"];
		var pts:Array<String> = [
		"506812A45F08C889B97F5980038B8359506812A45F08C889B97F5980038B8359506812A45F08C889B97F5980038B8359",
		"5C6D71CA30DE8B8B00549984D2EC7D4B5C6D71CA30DE8B8B00549984D2EC7D4B5C6D71CA30DE8B8B00549984D2EC7D4B"];

		for (i in 0...keys.length) {
			var key:Bytes = Bytes.ofHex(keys[i]);
			var pt:Bytes = Bytes.ofHex(pts[i]);
			var aes:Aes = new Aes(key.length*8, key);
			var cbc:ModeCBC = new ModeCBC(aes);
			cbc.iv = Bytes.ofHex("00000000000000000000000000000000");
			cbc.setPrependMode(false);
			var crypted = cbc.encrypt(pt);
			var str:String = crypted.toHex().toUpperCase();
			assertEquals( cts[i], str);
			// back to pt
			var dec = cbc.decrypt(crypted);
			str = dec.toHex().toUpperCase();
			assertEquals(pts[i], str);
		}
	}

	/*
	public function testXTea():Void {
		var keys:Array<String>=[
		"00000000000000000000000000000000",
		"2b02056806144976775d0e266c287843"];
		var cts:Array<String> = [
		"2dc7e8d3695b0538d8f1640d46dca717790af2ab545e11f3b08e798eb3f17b1744299d4d20b534aa",
		"790958213819878370eb8251ffdac371081c5a457fc42502c63910306fea150be8674c3b8e675516"];
		var pts:Array<String>=[
		"0000000000000000000000000000000000000000000000000000000000000000",
		"74657374206d652e74657374206d652e74657374206d652e74657374206d652e"];

		for (i in 0...keys.length) {
			var key:Bytes = Bytes.ofHex(keys[i]);
			var pt:Bytes = Bytes.ofHex(pts[i]);
			var tea:XTea = new XTea(key);
			var cbc:ModeCBC = new ModeCBC(tea);
			cbc.iv = Bytes.ofHex("0000000000000000");
			cbc.setPrependMode(false);
			
			var str:String = cbc.encrypt(pt).toHex();
			assertEquals(cts[i], str);
			// now go back to plaintext.
			str = cbc.decrypt(Bytes.ofHex(str)).toHex();
			assertEquals(pts[i], str);
		}
	}
	*/
}