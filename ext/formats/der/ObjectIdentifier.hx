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
 * ObjectIdentifier
 *
 * An ASN1 type for an ObjectIdentifier
 */
package formats.der;

class ObjectIdentifier implements IAsn1Type
{
	private var type:Int;
	private var len:Int;
	private var oid:Array<Int>;

	public function new(type:Int, length:Int, b:Dynamic) {
		this.type = type;
		this.len = length;
		if (Std.is(b, ByteString)) {
			parse(cast b);
		} else if (Std.is(b, String)) {
			generate(cast b);
		} else {
			throw "Invalid call to new ObjectIdentifier";
		}
	}

	private function generate(s:String):Void {
		var p = s.split(".");
		oid = new Array();
		for(i in p) {
			oid.push(Std.parseInt(i));
		}
	}

	private function parse(b:ByteString):Void {
		// parse stuff
		// first byte = 40*value1 + value2
		var o:Int = b.readUnsignedByte();
		var a:Array<Int> = [];
		a.push(Std.int(o/40));
		a.push(Std.int(o%40));
		var v:Int = 0;
		while (b.bytesAvailable>0) {
			o = b.readUnsignedByte();
			var last:Bool = (o&0x80)==0;
			o &= 0x7f;
			v = v*128 + o;
			if (last) {
				a.push(v);
				v = 0;
			}
		}
		oid = a;
	}

	public function getLength():Int
	{
		return len;
	}

	public function getType():Int
	{
		return type;
	}

	public function toDER():ByteString {
		var tmp:Array<Int> = [];
		tmp[0] = oid[0]*40 + oid[1];
		for(i in 2 ... oid.length) {
			var v:Int = oid[i];
			if (v<128) {
				tmp.push(v);
			} else if (v<128*128) {
				tmp.push( (v>>7)|0x80 );
				tmp.push( v&0x7f );
			} else if (v<128*128*128) {
				tmp.push( (v>>14)|0x80 );
				tmp.push( (v>>7)&0x7f | 0x80 );
				tmp.push( v&0x7f);
			} else if (v<128*128*128*128) {
				tmp.push( (v>>21)|0x80 );
				tmp.push( (v>>14) & 0x7f | 0x80 );
				tmp.push( (v>>7) & 0x7f | 0x80 );
				tmp.push( v & 0x7f );
			} else {
				throw "OID element to large.";
			}
		}
		len = tmp.length;
		if (type==0) {
			type = 6;
		}
		tmp.unshift(len); // assume length is small enough to fit here.
		tmp.unshift(type);
		var b:ByteString = new ByteString();
		var l = tmp.length;
		for(i in 0...l)
			b.set(i, tmp[i]);
		return b;
	}

	public function toString():String {
		return DER.indent+oid.join(".");
	}

	public function dump():String {
		return "OID["+type+"]["+len+"]["+toString()+"]";
	}
}
