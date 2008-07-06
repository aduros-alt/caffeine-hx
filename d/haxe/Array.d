module haxe.Array;

import haxe.HaxeTypes;
import haxe.Serializer;
import IntUtil = tango.text.convert.Integer;

class Array : HaxeClass {
	public HaxeType type() { return HaxeType.TArray; }
	public Dynamic[] data;
	public char[] __classname() { return "Array<Dynamic>"; }

	this() { isNull = false; }

	public size_t length() { return data.length; }

	mixin DynamicArrayType!(typeof(this), data);

	public char[] __serialize() {
		auto s = new Serializer();
		auto l = data.length;
		int ucount = 0;

		for(int x = 0; x < l; x++) {
			if(data[x] is null)
				ucount++;
			else {
				if(ucount > 0) {
					if(ucount == 1)
						s.buf ~= "n";
					else {
						s.buf ~= "u";
						s.buf ~= IntUtil.toString(ucount);
					}
					ucount = 0;
				}
				s.serialize(data[x]);
			}
		}
		if(ucount > 0) {
			if(ucount == 1)
				s.buf ~= "n";
			else {
				s.buf ~= "u";
				s.buf ~= IntUtil.toString(ucount);
			}
		}
		return "a" ~ s.toString() ~ "h";
	}

	public bool __unserialize() {
		return false;
	}

}