module haxe.HaxeClass;

import haxe.HaxeTypes;
import haxe.Serializer;

abstract class HaxeClass : HaxeObject
{
	public static char[][char[]] haxe2dmd;

	public char[] __classname() {
		ClassInfo fci = this.classinfo;
		return fci.name;
	}

	/**
		Calling this super constructor is necessary to ensure that
		the class is registered properly for haxe<->dmd translation.
		If the class is embedded in another, you will have to create
		the proper mapping instead.
	**/
	this() {
		auto n = __classname();
		auto h = moduleToPackage(n);
		haxe2dmd[h] = n;
	}

	public HaxeType type() { return HaxeType.TClass; }
	public char[] toString() { return __classname(); }
}