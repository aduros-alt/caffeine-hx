module haxe.Hash;

import haxe.HaxeTypes;
import haxe.Serializer;

interface IHash {
	bool exists(char[] k);
	Dynamic get(char[] k);
	size_t length();
	bool remove(char[] k);
	void set(char[] k, Dynamic v);
}

class Hash : HaxeClass, IHash {
	public HaxeType type() { return HaxeType.THash; }
	public Dynamic[char[]]	data;
	public char[] __classname() { return "Hash"; }

	this() { isNull = false; }
	this(Dynamic[char[]] v) {
		this();
		data = v;
	}

	public bool exists(char[] k) {
		return (k in data) == null ? false : true;
	}

	public Dynamic get(char[] k) {
		auto v = (k in data);
		if(v) return *v;
		return null;
	}

	public size_t length() {
		return data.length;
	}

	public bool remove(char[] k) {
		try
			data.remove(k);
		catch(Exception e)
			return false;
		return true;
	}

	public void set(char[] k, Dynamic v) {
		if(v is null)
			data[k] = new Null();
		else
			data[k] = v;
	}

	public char[] toString() {
		char[] b = "{ ";
		bool first = true;
		if(data.length > 0)
		foreach(char[] k, Dynamic v; data) {
			if(first) first = false;
			else b ~= ", ";
			b ~= k;
			b ~= ": ";
			b ~= v.toString();
		}
		b ~= " }";
		return b;
	}
	mixin(CanCast!("Hash"));
}
