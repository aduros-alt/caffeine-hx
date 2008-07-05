module haxe.Array;

import haxe.HaxeTypes;
import haxe.Serializer;
import IntUtil = tango.text.convert.Integer;

class Array : HaxeClass {
	public HaxeType type() { return HaxeType.TArray; }
	public Dynamic[] data;
	public char[] __classname() { return "Array<Dynamic>"; }

	this() { isNull = false; }

	Dynamic opIndex(size_t i) {
		if(i >= data.length || data[i] == null)
			return new Dynamic(new Null);
		return data[i];
	}

	Dynamic opIndexAssign(HaxeValue value, size_t i) {
		Dynamic v = null;
		if(value !is null) {
			if(value.type != HaxeType.TDynamic)
				v = new Dynamic(value);
			else
				v = cast (Dynamic) value;
		}
		if(i >= data.length) {
			data.length = i + 1;
		}
		data[i] = v;

		// trim the size down
		size_t l = data.length;
		size_t x = l;
		do {
			x--;
			if(data[x] !is null)
				break;
			l--;
		}
		while(x > 0);
		data.length = l;
		return v;
	}

	public size_t length() { return data.length; }

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