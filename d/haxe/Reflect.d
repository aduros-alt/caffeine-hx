module haxe.Reflect;

import haxe.HaxeTypes;

class Reflect {
	public static void setField(Dynamic o, char[] field, Dynamic value) {
		auto obj = cast(HaxeObject) o;
		if(!obj)
			throw new Exception("not an object");
		obj[field] = value;
	}
}