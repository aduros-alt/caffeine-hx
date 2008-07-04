module haxe.Hash;

import haxe.HaxeTypes;
import haxe.Serializer;
import tango.util.container.HashMap;
alias HashMap!(char[], Dynamic) HaxeStringHash;

class Hash : HaxeClass {
	public HaxeType type() { return HaxeType.THash; }
	public HaxeStringHash	data;
	public char[] __classname() { return "Hash<Dynamic>"; }

	this() { isNull = false; this.data = new HaxeStringHash(); }

	public bool exists(char[] k) {
		return( (k in data) !is null);
	}

	public Dynamic get(char[] k) {
		auto d = new Dynamic();
		data.get(k, d);
		return d;
	}

	public bool remove(char[] k) {
		return data.removeKey(k);
	}

	public void set(char[] k, Dynamic v) {
		data.add(k, v);
	}

	public void set(char[] k, String v) {
		data.add(k, new Dynamic(v));
	}

	public char[] __serialize() {
		auto s = new Serializer();
		foreach(k, v; data) {
			s.serializeString(k);
			s.serialize(v);
		}
		return "b" ~ s.toString() ~ "h";
	}

	public bool __unserialize() {
		return false;
	}
}