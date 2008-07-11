module haxe.Array;

import haxe.HaxeTypes;
import haxe.Serializer;
import IntUtil = tango.text.convert.Integer;
// import tango.io.Console;

/**
	Types that can be accessed as integer arrays of Dynamic
**/
package template dataField(char[] type) {
	const char[] dataField = "public "~type~" data;";
} // mixin(dataField!("Dynamic[]"));
package template DynamicArrayType(T, alias F) {
	this() { isNull = false; }
	this(T[] v) {
		this();
		F = v;
	}

	public HaxeType type() { return HaxeType.TArray; }
	public size_t length() { return F.length; }

	T opIndex(size_t i) {
		T v = F[i];
		if(v.isNull)
			return null;
		return v;
	}

	T opIndexAssign(T v, size_t i) {
		static if( is(T == Dynamic) ) {
			if(v is null)
				v = new Null();
		}
		else {
			if(v is null) {
				v = new T();
				v.isNull = true;
			}
		}
		if(i >= F.length) {
			auto olen = F.length;
			F.length = i + 1;
			while(olen < F.length) {
				static if( is(T == Dynamic) )
					F[olen++] = new Null();
				else {
					T d = new T();
					d.isNull = true;
					F[olen++] = d;
				}
			}
		}
		F[i] = v;

		// trim the size down
		size_t l = F.length;
		size_t x = l;
		do {
			x--;
			if(F[x] !is null)
				break;
			l--;
		}
		while(x > 0);
		F.length = l;
		return v;
	}

	int opApply(int delegate(ref T) dg) {
		int res = 0;
		for (int i = 0; i < F.length; i++) {
			res = dg(F[i]);
			if(res) break;
		}
		return res;
	}

	synchronized public T pop() {
		if(F.length == 0)
			return null;
		T v = F[F.length-1];
		F.length = F.length - 1;
		return (v.isNull ? null : v);
	}

	public void push(T v) {
		if(v is null)
			static if(is (T == Dynamic))
				F ~= new Null();
			else {
				T d = new T();
				d.isNull = true;
				F ~= d;
			}
		else
			F ~= v;
	}

	public char[] toString() {
		char[] b = "[";
		if(F.length > 0) {
			bool first = true;
			size_t i = 0;
			while(i < F.length) {
				if(first) first = false;
				else b ~= ", ";
				if(F[i] is null || F[i].isNull)
					b ~= "(null)";
				else
					b ~= F[i].toString();
				i++;
			}
		}
		b ~= "]";
		return b;
	}

}

template ArraySerialize(T, alias F) {
	public char[] __serialize() {
		auto s = new Serializer();
		auto l = F.length;
		int ucount = 0;

		for(int x = 0; x < l; x++) {
			if(F[x] is null || F[x].isNull) {
				ucount++;
			}
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
				s.serialize(F[x]);
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
	public bool __unserialize(ref HaxeObject o) {
		return false;
	}
}

class Array : HaxeClass {
	public Dynamic[] data;
	public char[] __classname() { return "Array"; }
	mixin DynamicArrayType!(Dynamic, data);
	mixin ArraySerialize!(Dynamic, data);
}

/**
	Common enough to have as a subclass
**/
class StringArray : HaxeClass {
	String[] data;
	public char[] __classname() { return "Array"; }
	mixin DynamicArrayType!(String, data);
	mixin ArraySerialize!(String, data);
}
/**
	Common enough to have as a subclass
**/
class IntArray : HaxeClass {
	Int[] data;
	public char[] __classname() { return "Array"; }
	mixin DynamicArrayType!(Int, data);
	mixin ArraySerialize!(Int, data);
}

class ArrayCast(T) : HaxeClass {
	T[] data;
	public char[] __classname() { return "Array"; }
	mixin DynamicArrayType!(T, data);
	mixin ArraySerialize!(T, data);
}