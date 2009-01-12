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

	/**
		Creator which takes a variadic list of char[] name, * value, ...
	**/
	public static HaxeObject create(...) {
		auto o = new HaxeObject();
		for (int i = 0; i < _arguments.length; i+=2) {
			char[] key = *cast(char[] *)_argptr;
			_argptr += key.length;
			Dynamic v;
			if (_arguments[i+1] == typeid(Dynamic)) {
				v = *cast(Dynamic *)_argptr;
				_argptr += v.sizeof;
			}
			else if (_arguments[i+1] == typeid(long)) {
				long val = *cast(long *)_argptr;
				_argptr += val.sizeof;
				v = new Int(val);
			}
			else if (_arguments[i+1] == typeid(real)) {
				real val = *cast(real *)_argptr;
				_argptr += val.sizeof;
				v = new Float(val);
			}
			else if (_arguments[i+1] == typeid(char [])) {
				char[] val = *cast(char[] *)_argptr;
				_argptr += val.sizeof;
				v = new String(val);
			}
			else if(v is null) {
				v = new Dynamic();
				_argptr += v.sizeof;
			}
			else
				assert(0);
			o.__fields[key] = v;
		}
	}

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