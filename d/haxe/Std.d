module haxe.Std;

import haxe.HaxeTypes;
import IntUtil = tango.text.convert.Integer;
import tango.core.Traits;

class Std {
	public static long parseInt(String v) {
// 		if(cast(String) v) {
// 			return IntUtil.parse((cast(String) v).value);
// 		}
// 		return 0;
		return IntUtil.parse( v.value);
	}

	public static long parseInt(char[] v) {
		return IntUtil.parse(v);
	}

// 	public static bool isA(T)(Dynamic v, T type) {
//
// 	}

	public static String string(T)(T v) {
		static if(is(X == bool)) {
			return v ? String("true") : String("false");
		}
		else static if( isIntegerType!(T) ) {
			return String(Int(v).toString());
		}
		else {
			static assert(0, "Can't convert type " ~ v.stringof);
		}
	}
}