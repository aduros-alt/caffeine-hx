module haxe.Array;

import haxe.HaxeTypes;
import haxe.Serializer;
import IntUtil = tango.text.convert.Integer;

class Array : HaxeClass {
	public HaxeType type() { return HaxeType.TArray; }
	public Dynamic[] data;
	public char[] __classname() { return "Array<Dynamic>"; }

	this() { isNull = false; }


	public char[] toString() {
		char[] b = "[";
		if(data.length > 0) {
			bool first = true;
			size_t i = 0;
			while(i < data.length) {
				if(first) first = false;
				else b ~= ", ";
				if(data[i] is null)
					b ~= "(null)";
				else
					b ~= data[i].toString();
				i++;
			}
		}
		b ~= "]";
		return b;
	}

	public size_t length() { return data.length; }

	mixin DynamicArrayType!(typeof(this), data);

	public void push(Dynamic v) {
		if(v is null)
			data ~= new Null();
		else
			data ~= v;
	}

	public char[] __serialize() {
		auto s = new Serializer();
		auto l = data.length;
		int ucount = 0;

		for(int x = 0; x < l; x++) {
			if(data[x] is null || cast(Null) data[x])
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

	public bool __unserialize(HaxeObject* o) {
		return false;
	}

}