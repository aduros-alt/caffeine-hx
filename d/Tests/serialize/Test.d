module Test;

import haxe.HaxeTypes;
import haxe.Serializer;
import haxe.Unserializer;
import haxe.Templates;
import tango.io.Console;

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
	auto c = new MyClass();
	Cout(Serializer.run(c)).newline;
}