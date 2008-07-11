module haxe.Hash;

import haxe.HaxeTypes;
import haxe.Serializer;

private alias Dynamic[char[]] HaxeStringHash;

class Hash : HaxeClass {
	public HaxeType type() { return HaxeType.THash; }
	public HaxeStringHash	data;
	public char[] __classname() { return "Hash<Dynamic>"; }

	this() { isNull = false; }

	public bool exists(char[] k) {
		try {
			Dynamic p = data[k];
		}
		catch(Exception e) {
			return false;
		}
		return true;
	}

	public Dynamic get(char[] k) {
		Dynamic p;
		try {
			p = data[k];
		}
		catch(Exception e) {
			return null;
		}
		return p;
	}

	public size_t length() {
		return data.length;
	}

	public bool remove(char[] k) {
		try {
			data.remove(k);
		}
		catch(Exception e) {
			return false;
		}
		return true;
	}

	public void set(char[] k, Dynamic v) {
		if(v is null)
			data[k] = new Null();
		else
			data[k] = v;
	}

	public char[] __serialize() {
		auto s = new Serializer();
		if(data.length > 0) {
			foreach(k, v; data) {
				if(v !is null) {
					s.serializeString(k);
					s.serialize(v);
				}
			}
		}
		return "b" ~ s.toString() ~ "h";
	}

	public bool __unserialize(ref HaxeObject o) {
		return false;
	}
}