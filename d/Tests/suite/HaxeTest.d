module haxeTest;

import haxe.HaxeTypes;
import haxe.Serializer;
import haxe.Unserializer;
import haxe.Type;
import tango.io.Console;
import FloatUtil = tango.text.convert.Float;
import IntegerUtil = tango.text.convert.Integer;

import tango.util.container.HashMap;
private alias HashMap!(int, Dynamic) IntCharHash;

void startTest(char [] name) {
	Cout("").newline;
	Cout("---------- " ~name~" ----------").newline;
}

/**
	The scope of string mixins seems to be in it's own block,
	so the scope(success) executes too soon.
**/
template BeginTest(char[] Name) {
	const char[] BeginTest =
		"Cout(\"\").newline; " ~
		"Cout(\"---------- "~Name~" ----------\").newline; " ~
		"scope(success) { Cout(\"passed.\").newline; }";
}

void dynamicTest() {
	startTest("dynamicTest");
/+
	auto ich = new IntCharHash();
	ich.add(1, new String("hi"));
	ich.add(2, new String("there"));
	auto rr = new String();
	ich.get(1, rr);
+/
	//Cout(rr.toString).newline;
}

void intTest() {
	startTest("intTest"); scope(success) { Cout("passed.").newline; }
	auto s = Int(5);
	Cout("5: ")(s.toString).newline;
	assert(s.toString == "5");
	s += 1;
	assert(s.toString == "6");
	assert((s + 2).toString == "8");
	assert((s++).toString == "7");
}

void floatTest() {
	startTest("floatTest"); scope(success) { Cout("passed.").newline; }
	assert(Float.NaN().isNull == false);
	assert(Float.POSITIVE_INFINITY().isNull == false);
	assert(Float.NEGATIVE_INFINITY().isNull == false);

	assert(Float.POSITIVE_INFINITY() != Float.NEGATIVE_INFINITY());
	assert(Float.POSITIVE_INFINITY() == Float.POSITIVE_INFINITY());
	assert(Float.POSITIVE_INFINITY() != Float.NaN());
}


void stringTest() {
	startTest("stringTest"); scope(success) { Cout("passed.").newline; }
	//mixin(BeginTest!("stringTest"));
	auto s = new String("Hello, how are you? & how about your friend?");
	auto ser = Serializer.run(s);
	//Cout(ser).newline;
	String unser = cast(String) Unserializer.run(ser);
	//Cout(unser).newline;
	assert(s == unser);
	char[] n = cast(char[]) s;
	assert(n == "Hello, how are you? & how about your friend?");

	s = new String("hi|there");
	auto parts = s.split("|");
 	//Cout(parts.toString).newline;
	assert(parts.toString == "[hi, there]");
}

void hashTest() {
	startTest("hashTest"); scope(success) { Cout("passed.").newline; }
	auto sh = new Hash();
	sh.set("fred", new String("jones"));
	assert(sh.exists("fred"));
	assert(sh.get("fred") == String("jones"));
	sh.set("fred", null);
	assert(sh.exists("fred"));
	assert(sh.length == 1);
	sh.remove("fred");
	assert(sh.length == 0);
	assert(sh.exists("fred") == false);

	sh.set("fred", new String("jones"));
	sh.set("james", String("Brown"));
	auto ser = Serializer.run(sh);
	//Cout(ser).newline;
	Hash unser = cast(Hash) Unserializer.run(ser);
	assert(Serializer.run(unser) == ser);
	assert(Type.getClassName(sh) == String("Hash"));
	assert(Type.getClassName(unser) == String("Hash"));
}

void intHashTest() {
	startTest("intHashTest"); scope(success) { Cout("passed.").newline; }
	auto ih = new IntHash();
	ih.set(1, new String("you"));
	ih.set(1, new String("replaced"));
	assert(ih.get(1).toString == "replaced");
	auto ser = Serializer.run(ih);
	assert(ser == "q:1y8:replacedh");
	IntHash unser = cast(IntHash) Unserializer.run(ser);
	assert(unser.get(1).toString == "replaced");
	assert(unser.length == 1);
	assert(Serializer.run(unser) == ser);
}

void arrayTest() {
	startTest("arrayTest"); scope(success) { Cout("passed.").newline; }
	auto a = new Array();

	a[2] = new Int(5);
	a[3] = new String("HI");
	assert(a.length == 4);
	//Cout("Array length is ")(IntegerUtil.toString(a.length)).newline;

	a[2] = null;
	assert(a.length == 4);
	Cout(a.toString).newline;
	//Cout("Array length is ")(IntegerUtil.toString(a.length)).newline;
	auto ser = Serializer.run(a);
	Cout(ser).newline;
	auto b = Unserializer.run(ser);
	//Cout(Serializer.run(b)).newline;
	assert(Serializer.run(b) == ser);
	//Cout(b.toString).newline;
	Cout("Iterated >").newline;
	foreach(Dynamic d; a) {
		Cout(d.toString)(", ");
	}
	Cout("").newline;
}

void listTest() {
	startTest("listTest"); scope(success) { Cout("passed.").newline; }
	auto l = new List();
	l.add(new String("there"));
	l.push(new String("Hi"));
	l.add(new String("Russell"));
	//Cout(l.toString).newline;
	l.remove(new String("Russell"));
	//Cout(l.toString).newline;
	auto ser = Serializer.run(l);
	//Cout(ser).newline;
	List unser = cast(List) Unserializer.run(ser);
	assert(Serializer.run(unser) == ser);
}

void objectTest() {
	startTest("objectTest");
	auto o = new HaxeObject();
	o["intfield"] = Int(5);
	o["myfield"] = String("mystringval");
	Dynamic d = o["dontexist"];
	if(d is null)
		Cout("d is NULL which is good.").newline;
	else
		Cout("!!!! d is not null.").newline;
	Cout(o.toString).newline;
	auto ser = new Serializer();
	ser.serialize(o);
	Cout(ser.toString).newline;
	ser.serialize(o);
	Cout(ser.toString).newline;
}

void dateTest() {
	startTest("dateTest"); scope(success) { Cout("passed.").newline; }
	auto dt = HaxeDate.fromString("07:57:01");
	Cout("07:57:01 from UTC: ")(dt.toString()).newline;
	dt = HaxeDate.now();
	Cout("Now: ")(dt.toString()).newline;
	dt = HaxeDate.fromString("2008-01-01");
	//Cout("Jan 1/08: ")(dt.toString()).newline;
	assert(dt.toString == "2008-01-01 00:00:00");

	auto ser = Serializer.run(dt);
	Cout(ser).newline;
	auto unser = Unserializer.run(ser);
	assert(unser.toString == "2008-01-01 00:00:00");

}

void classTest() {
	startTest("classTest"); scope(success) { Cout("passed.").newline; }
	auto c = new testClass();
	c.m_value = 12;
	c["otherval"] = String("Hey");
	auto ser = Serializer.run(c);
	Cout("classTest serialized>> ")(ser).newline;
	testClass tc = cast(testClass) Unserializer.run(ser);
	//testClass tc = cast(testClass) unser;
	if(!tc) {
		Cout("classTest failed.").newline;
		return;
	}
	assert(tc.m_value == 12);
	//Cout(tc["otherval"]).newline;
	assert(tc["otherval"] == String("Hey"));

// 	Cout("Userialized value: ")(IntegerUtil.toString(tc.m_value)).newline;

	testClass2 tc2 = cast(testClass2)Unserializer.run("cy19:haxeTest.testClass2y7:m_valuei3g");
	assert(tc2 !is null);
	assert(tc2.m_value == 3);

	// same thing with haxe package naming
	tc2 = cast(testClass2)Unserializer.run("cy10:testClass2y7:m_valuei3g");
	assert(tc2 !is null);
	assert(tc2.m_value == 3);
}

void circularReferenceTest() {
	startTest("circularReferenceTest"); scope(success) { Cout("passed.").newline; }
	auto c = new testClass();
	c.m_value = 111;
	auto c2 = new testClass2();
	c2.m_value = 222;
	c["class2"] = c2;
	auto ser = Serializer.run(c);
	Cout(ser).newline;

	c2["class1"] = c;
	ser = Serializer.run(c);
	Cout(ser).newline;
	Unserializer.run(ser);
}

void main() {
	intTest();
	floatTest();
	stringTest();
	arrayTest();
	listTest();
	dateTest();
	hashTest();
	intHashTest();
	classTest();
	circularReferenceTest();
}

import haxe.Reflect;
class testClass : HaxeClass{
	public int m_value;
	this() {
		super();
		//Cout("Created testClass instance").newline;
		m_value = 7;
	}

	public void __serialize(ref Serializer s) {
		super.__serialize(s);
		s.serializeField("m_value", Int(m_value));
	}

	bool __unserialize(ref HaxeObject o) {
// 		Cout("__unserialize called").newline;
		auto d = Reflect.popField(o, "m_value");
		if(d !is null)
			m_value = cast(int)cast(Int)d;
		foreach(field, v; o.__fields) {
// 			Cout("Object has field: ")(field)(" value: ")(v.toString).newline;
		}
 		super.__unserialize(o);
		return true;
	}
}

class testClass2 : HaxeClass {
	public int m_value;
	this() {
		super();
		//Cout("Created testClass instance").newline;
		m_value = 7;
	}

	void __serialize(ref Serializer s) {
		super.__serialize(s);
		s.serializeField("m_value", Int(m_value));
	}

	bool __unserialize(ref HaxeObject o) {
		auto d = Reflect.popField(o, "m_value");
		if(d !is null)
			m_value = cast(int)cast(Int)d;
		foreach(field, v; o.__fields) {
			//Cout("field: ")(field)(" value: ")(v.toString).newline;
		}
		return true;
	}
}
