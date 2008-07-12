module haxe.Reflect;

import haxe.HaxeTypes;

import tango.io.Console;
class Reflect {
	public static Dynamic field(Dynamic obj, char[] field) {
		HaxeObject o = cast(HaxeObject) obj;
		if(!o) return null;
		auto p = (field in o.__fields);
		if(!p) return null;
		return *p;
	}

	public static bool deleteField(Dynamic obj, char[] field) {
		HaxeObject o = cast(HaxeObject) obj;
		if(!o) return false;
		auto p = (field in o.__fields);
		if(!p) return false;
		try	o.__fields.remove(field); catch(Exception e) {}
		return true;
	}

	/**
		Deletes and returns a field if it exists. Returns null otherwise.
	**/
	synchronized public static Dynamic popField(Dynamic obj, char[] key) {
		HaxeObject o = cast(HaxeObject) obj;
		if(!o) return null;
		auto p = (key in o.__fields);
		if(!p) return null;
		try o.__fields.remove(key); catch(Exception e) {}
		return *p;
	}

	// TODO: to really be compatible here, the class prototype
	// methods must be ignored
	public static bool hasField(Dynamic obj, char[] field) {
		HaxeObject o = cast(HaxeObject) obj;
		if(!o) return false;
		auto p = (field in o.__fields);
		if(!p) return false;
		return true;
	}

	public static void setField(Dynamic obj, char[] field, Dynamic value) {
		HaxeObject o = cast(HaxeObject) obj;
		if(!o) throw new Exception("not an object");
		o[field] = value;
	}
}