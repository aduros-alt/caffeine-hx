module haxe.IntHash;

import haxe.HaxeTypes;
import haxe.Serializer;
import tango.util.container.HashMap;
alias HashMap!(int, Dynamic) HaxeIntHash;

class IntHash : HaxeClass {
	public HaxeType type() { return HaxeType.TIntHash; }
	public HaxeIntHash	data;
	public char[] __classname() { return "IntHash<Dynamic>"; }

	this() { isNull = false; this.data = new HaxeIntHash(); }

	public bool exists(int k) {
		return( (k in data) !is null);
	}

	public Dynamic get(int k) {
		auto d = new Dynamic();
		data.get(k, d);
		return d;
	}

	public bool remove(int k) {
		return data.removeKey(k);
	}

	public void set(int k, Dynamic v) {
		data.add(k, v);
	}

	public void set(int k, String v) {
		data.add(k, new Dynamic(v));
	}

	public char[] __serialize() {
		auto s = new Serializer();
		char buf[];
		buf ~= "q";
		foreach(k, v; data) {
			buf ~= ":";
			s.serialize(k);
			s.serialize(v);
		}
		buf ~= "h";
		return buf;
	}

	public bool __unserialize() {
		return false;
	}
}