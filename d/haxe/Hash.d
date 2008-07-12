module haxe.Hash;

import haxe.HaxeTypes;
import haxe.Serializer;

private alias Dynamic[char[]] HaxeStringHash;

interface IHash {
	bool exists(char[] k);
	Dynamic get(char[] k);
	size_t length();
	bool remove(char[] k);
	void set(char[] k, Dynamic v);
}

class Hash : HaxeClass, IHash {
	public HaxeType type() { return HaxeType.THash; }
	public HaxeStringHash	data;
	public char[] __classname() { return "Hash"; }

	this() { isNull = false; }

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

}
