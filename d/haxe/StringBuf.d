module haxe.StringBuf;

import haxe.HaxeTypes;

class StringBuf {
	char[] buf;
	this() {
	}

	public void add(T)(T v) {
		static if( is(T:char[]) ) {
			buf ~= v;
		}
		else static if( is(T:Dynamic) ) {
			buf ~= v.toString();
		}
		else {
			static assert(0, "Can't add type " ~v.stringof);
		}
	}

	public char[] toString() {
		return buf;
	}
}