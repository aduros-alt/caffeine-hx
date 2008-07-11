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

	public HaxeType type() { return HaxeType.TClass; }
	public char[] toString() { return __classname(); }
}