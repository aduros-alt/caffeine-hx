module haxe.HaxeObject;

import haxe.HaxeTypes;
import haxe.Serializer;
import IntUtil = tango.text.convert.Integer;

/**
	Types that can be accessed as hashes of Dynamic
**/
package template DynamicHashType(T, alias F) {
	T opIndex(char[] key) {
		auto v = (key in F);
		if(v) return *v;
		return new Null();
	}

	T opIndexAssign(T v, char[] key) {
		if(v is null)
			v = new Dynamic();
		F[key] = v;
		return v;
	}

	int opApply(int delegate(ref T) dg) {
		int res;
		foreach(char[] k, ref T v; F) {
			if((res = dg(v)) != 0) break;
		}
		return res;
	}

	int opApply(int delegate(ref char[] key, ref T val) dg)
	{
		int res;
		foreach(char[] k, ref T v; F) {
			if((res = dg(k, v)) != 0) break;
		}
		return res;
	}
}

class HaxeObject : Dynamic, HaxeSerializable {
	public HaxeType type() { return HaxeType.TObject; }
	public Dynamic[char[]] __fields;
	public char[] __classname() { return "Object"; }

	this() { isNull = false; }

	mixin DynamicHashType!(Dynamic, __fields);

	public char[] toString() {
		char[] b = "{";
		bool first = true;
		foreach(k, v; __fields) {
			if(first) first = false;
			else b ~= ", ";
			b ~= k;
			b ~= ": ";
			b ~= v.toString();
		}
		b ~= "}";
		return b;
	}

	/**
		Only serializes the fields of the object.
	**/
	public void __serialize(ref Serializer s) {
		s.serializeFields(__fields);
	}

	public bool __unserialize(ref HaxeObject o) {
		foreach(k, v; o.__fields) {
			__fields[k] = v;
		}
		return true;
	}
}