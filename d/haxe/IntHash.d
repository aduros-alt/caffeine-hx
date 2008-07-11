module haxe.IntHash;

import haxe.HaxeTypes;
import haxe.Serializer;
import IntUtil = tango.text.convert.Integer;

private alias Dynamic[int] HaxeIntHash;

class IntHash : HaxeClass {
	public HaxeType type() { return HaxeType.TIntHash; }
	public HaxeIntHash	data;
	public char[] __classname() { return "IntHash"; }

	this() { isNull = false; }

	public bool exists(int k) {
		try {
			Dynamic p = data[k];
		}
		catch(Exception e) {
			return false;
		}
		return true;
	}

	public Dynamic get(int k) {
		Dynamic p;
		try {
			p = data[k];
		}
		catch(Exception e) {
			return null;
		}
		return p;
	}

	public bool remove(int k) {
		try {
			data.remove(k);
		}
		catch(Exception e) {
			return false;
		}
		return true;
	}

	public void set(int k, Dynamic v) {
		if(v is null)
			data[k] = new Null();
		else
			data[k] = v;
	}

	public char[] __serialize() {
		auto s = new Serializer();
		s.buf ~= "q";
		foreach(k, v; data) {
			s.buf ~= ":";
			s.buf ~= IntUtil.toString(k);
			s.serialize(v);
		}
		s.buf ~= "h";
		return s.buf;
	}

	public bool __unserialize(ref HaxeObject o) {
		return false;
	}
}