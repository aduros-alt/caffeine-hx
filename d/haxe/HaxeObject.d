module haxe.HaxeObject;

import haxe.HaxeTypes;
import haxe.Serializer;
import IntUtil = tango.text.convert.Integer;

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
	public char[] __serialize() {
		auto s = new Serializer();
		s.serializeFields(__fields);
		return s.toString();
	}

	public bool __unserialize(ref HaxeObject o) {
		return false;
	}

}