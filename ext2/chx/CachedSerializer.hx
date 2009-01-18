/*
 * Copyright (c) 2008-2009, The Caffeine-hx project contributors
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

package chx;

import haxe.Serializer;

/**
	This is a haxe compatible serializer optimized for serializing objects with lots
	of circular references. To do this, a special field "__serializeHash" should exist
	on the objects and classes, which is either a function Void->String or just a String.
	The String returned should be unique to the class or object instance, not to the
	class or object. If the field "__serializeHash" does not exist, it will be created.

	Also, this version of haxe serialization does not throw errors on Function fields,
	they are detected and ignored.

	Developed for ChxDoc, which was taking 5:36 to serialize configuration data under
	haxe.Serializer, reduced to 0:58 using this technique.
**/

class CachedSerializer extends Serializer {
	var keyCache : Hash<Array<{obj: Dynamic, idx : Int }>>;

	public function new() {
		super();
		keyCache = new Hash();
		useCache = true;
	}

	override function serializeRef(v) {
		var key : String = null;

		try {
			switch(Type.typeof(v)) {
			case TEnum(e):
				// In flash9, can not add a field to the enums
				key = "__ENUM__" + Type.enumConstructor(v);
			default:
				if(!Reflect.hasField(v, "__serializeHash"))
					throw "no key";
				try {
					// Don't use Reflect.callMethod, which fails in neko when f() is a callback
					key = untyped v.__serializeHash();
				} catch(e : Dynamic) {
					key = cast v.__serializeHash;
					if(key == null)
						throw "bad key";
				}
			}
		} catch(e : Dynamic) {
			var fields = Reflect.fields(v);
			for(i in fields) {
				key += i;
				var val = Reflect.field(v, i);
				switch(Type.typeof(val)) {
				case TInt:
					key += Std.string(val);
				case TBool:
					key += Std.string(val);
				case TClass(c):
					if( c == String )
						key += Std.string(val.length);
				default:
				}
			}
			Reflect.setField(v, "__serializeHash", key);
		}

		if(keyCache.exists(key)) {
			#if js
			var vt = untyped __js__("typeof")(v);
			#end
			var types = keyCache.get(key);
			for(i in types) {
				#if js
				var ci = i.obj;
				if( untyped __js__("typeof")(ci) == vt && ci == v ) {
				#else
				if(i.obj == v) {
				#end
					buf.add("r");
					buf.add(i.idx);
					return true;
				}
			}
			types.push({ obj : v, idx : cache.length });
		} else {
			keyCache.set(key, [{ obj : v, idx : cache.length}]);
		}
		cache.push(v);
		return false;
	}

	#if flash9
	override function serializeClassFields(v,c) {
		var xml : flash.xml.XML = untyped __global__["flash.utils.describeType"](c);
		var vars = xml.factory[0].child("variable");
		for( i in 0...vars.length() ) {
			var f = vars[i].attribute("name").toString();
			if(f == "__serializeHash")
				continue;
			switch(Type.typeof(Reflect.field(v, f))) {
			case TFunction: // ignore
			default:
				if( !v.hasOwnProperty(f) )
					continue;
				serializeString(f);
				serialize(Reflect.field(v,f));
			}
		}
		buf.add("g");
	}
	#end

	override function serializeFields(v) {
		for( f in Reflect.fields(v) ) {
			if(f == "__serializeHash")
				continue;
			switch(Type.typeof(Reflect.field(v, f))) {
			case TFunction: // ignore
			default:
			serializeString(f);
			serialize(Reflect.field(v,f));
			}
		}
		buf.add("g");
	}

	/**
		Serialize a single value and return the string.
	**/
	public static function run( v : Dynamic ) {
		var s = new CachedSerializer();
		s.serialize(v);
		return s.toString();
	}

}