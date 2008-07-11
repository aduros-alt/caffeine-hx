module haxe.Std;

import haxe.HaxeTypes;
import IntUtil = tango.text.convert.Integer;

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
}