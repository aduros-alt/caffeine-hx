module Test;

import haxe.HaxeTypes;
import haxe.Serializer;
import haxe.Unserializer;
import tango.io.Console;

class MyEnum : Enum {
	static this() {
		Enum.haxe2dmd["MyEnum"] = "Test.MyEnum";
	}

	public char[][] tags() {
		return ["Nada", "Zero", "One", "Two", "Three"];
	}

	public int[] argCounts() {
		return [0, 0, 1, 2, 1];
	}

	public static MyEnum Nada() {
		auto e = new MyEnum();
		e.initialize("Nada", new Array());
		return e;
	}
	public static MyEnum Zero() {
		auto e = new MyEnum();
		e.initialize("Zero", null);
		return e;
	}
	public static MyEnum One(int a) {
		auto e = new MyEnum();
		Array ar = new Array();
		ar[0] = Int(a);
		e.initialize("One", ar);
		return e;
	}
}

class MyClass : HaxeClass {
	Int a;
	Int b;
	Array c;
	String d;
	Float ni;
	Float pi;
	Float nn;

	static this() {
		HaxeClass.haxe2dmd["MyClass"] = "Test.MyClass";
	}

	this() {
		a = Int(5); // Int is callable
		b = new Int(null);
		c = new Array();
		c[0] = String("Hello");
		d = String("Uncle"); // String is callable
		ni = Float.NEGATIVE_INFINITY;
		pi = Float.POSITIVE_INFINITY;
		nn = Float.NaN;
	}

	char[] __serialize() {
		Dynamic[char[]] fields;
		fields["a"] = a;
		fields["b"] = b;
		fields["c"] = c;
		fields["d"] = d;
		fields["ni"]= ni;
		fields["pi"]= pi;
		fields["nn"]= nn;
		auto s = new Serializer();
		s.serializeFields(fields);
		return s.toString();
	}

	bool __unserialize(ref HaxeObject o) {
		if(!getInt(o,"a",a)) return false;
		if(!getString(o,"d",d)) return false;
		if(!getFloat(o,"ni",ni)) return false;
		// ... etc

		/**
			This just shows that the same functions can
			be called to unserialize to D fields.
		**/
		int bob;
		float isyour;
		char[] uncle;
		if(!getInt(o,"a",bob)) return false;
		if(!getFloat(o,"ni",isyour)) return false;
		if(!getString(o,"d",uncle)) return false;
		return true;
	}

}


void main() {
	Cout("---- D -----").newline;
	auto c = new MyClass();
	Cout(Serializer.run(c)).newline;

	auto e = MyEnum.Nada;
	Cout(Serializer.run(e)).newline;

	e = MyEnum.One(456);
	Cout(Serializer.run(e)).newline;

	Serializer.USE_ENUM_INDEX = true;
	Cout(Serializer.run(e)).newline;

	Enum r = cast(Enum)Unserializer.run(Serializer.run(e));
	Cout(r).newline;
	Cout(r[0]).newline;
}