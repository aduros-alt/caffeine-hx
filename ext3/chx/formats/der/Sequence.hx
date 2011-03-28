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

package chx.formats.der;

/**
 * Sequence
 *
 * An ASN1 type for a Sequence, implemented as an Array
 */
class Sequence implements IAsn1Type, implements IContainer
{
	public var length(default,null):Int;
	var type:Int;
	var _buf : Array<Dynamic>;
	var _hash : Hash<Dynamic>;

	public function new(iType:Int=0x30, length:Int=0) {
		type = iType;
		this.length = length;
		_buf = new Array();
		_hash = new Hash();
	}

	public function getLength():Int
	{
		return length;
	}

	public function getType():Int
	{
		return type;
	}

	public function toDER():Bytes {
		var tmp:BytesBuffer = new BytesBuffer();
		for ( i in 0 ... length) {
			var e:IAsn1Type = _buf[i];
			if (e == null) { // XXX Arguably, I could have a der.Null class instead
				tmp.addByte(0x05);
				tmp.addByte(0x00);
			} else {
				tmp.add(e.toDER());
			}
		}
		return DER.wrapDER(type, tmp.getBytes());
	}

	public function toString():String {
		var s:String = DER.indent;
		DER.indent += "    ";
		var t:String = "";
		for(i in 0..._buf.length) {
			if (_buf[i]==null) continue;
			var found:Bool = false;
			for(key in _hash.keys()) {
				if ( (Std.string(i) != key) && _buf[i] == _hash.get(key)) {
					t += DER.indent + key+": "+_buf[i]+"\n";
					found = true;
					break;
				}
			}
			if (!found) t+=Std.string(_buf[i])+"\n";
		}
		DER.indent= s;
		return DER.indent+"Sequence["+type+"]["+length+"][\n"+t+"\n"+s+"]";
	}

	/////////

	public function findAttributeValue(oid:String):IAsn1Type {
		for(set in _buf) {
			if ( Std.is(set, Set) ) {
				var child:IAsn1Type = set.get(0);
				if ( Std.is(child, Sequence)) {
					var sc:Sequence = cast child;
					var tmp:IAsn1Type = sc.get(0);
					if ( Std.is(tmp, ObjectIdentifier)) {
						var id:ObjectIdentifier = cast tmp;
						if (id.toString()==oid) {
							return sc.get(1);
						}
					}
				}
			}
		}
		return null;
	}

	public function push(v:Dynamic) : Void {
		_buf.push(v);
	}

	public function get(i : Int) : Dynamic {
		return _buf[i];
	}

	public function set(i : Int, v:Dynamic) : Void {
		_buf[i] = v;
	}

	public function getContainer(i : Int ) : IContainer {
		return cast _buf[i];
	}

	public function setKey(k:String, v:Dynamic) : Void {
		_hash.set(k, v);
	}

	public function getKey(k:String) : Dynamic {
		return _hash.get(k);
	}

}
