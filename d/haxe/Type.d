module haxe.Type;

import haxe.HaxeTypes;

class Type {
	/**
		Create a class instance
	**/
	public static Object createInstance(ClassInfo ci) {
		if(ci is null) return null;
		return ci.create();
	}

	/**
		Returns the class name, or an empty null String.
	**/
	public static String getClassName(HaxeClass c) {
		if(c is null) {
			auto s = new String("");
			s.isNull = true;
			return s;
		}
		return String(c.__classname);
	}

	/**
		Resolves a class, or returns null. Classname can be passed as a String
		or char[]
	**/
	public static ClassInfo resolveClass(T)(T className) {
		static assert(is(T == String) || is(T==char[]), "Must be a String or char[]");

		char[] name;
		static if( is(T == String) )
			name = className.value;
		else
			name = className;

		// look in HaxeClass registry
		foreach(h,d; HaxeClass.haxe2dmd) {
			if(h == name) {
				name = d;
				break;
			}
		}
		ClassInfo ci = ClassInfo.find(name);
		return ci;
	}

	public static HaxeType typeOf(Dynamic d) {
		return d.type;
	}
}