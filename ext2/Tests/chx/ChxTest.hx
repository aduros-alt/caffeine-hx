import config.DotConfig;


enum Num {
	ONE;
	TWO;
	NUM(n : Num);
}

typedef Ctx = {
	var s : String;
	var ctx : Ctx;
	var num : Num;
}

import chx.io.StringBufOutput;

class ChxTests extends haxe.unit.TestCase {
/*
	function testSerializer() {
		var a : Ctx = {
			s: "This is a",
			ctx : null,
			num : ONE,
		}
		var b : Ctx = {
			s: "This is b",
			ctx : a,
			num : NUM(TWO),
		}
		a.ctx = b;

		var ctxArray = [a, b];

		var ser = chx.Serializer.run(ctxArray);
		//trace(ser);
		ctxArray = haxe.Unserializer.run(ser);

		//trace(ctxArray);
		assertEquals(ctxArray[0].s, "This is a");
		assertEquals(ctxArray[0].ctx.s, "This is b");
		assertEquals(ctxArray[1].s, "This is b");
		assertEquals(ctxArray[1].ctx.s, "This is a");

		switch(ctxArray[0].ctx.num) {
		case ONE: assertEquals(true, false);
		case TWO: assertEquals(true, false);
		case NUM(n): 
			switch(n) {
			case ONE: assertEquals(true, false);
			case TWO:
			case NUM(f): assertEquals(true, false);
			}
		}
	}
*/
	function testStringOutput() {
		var o = new StringBufOutput();
		o.writeByte(65);
		assertEquals("A", o.toString());

		o = new StringBufOutput();
		o.writeFloat(1.23);
		assertEquals("1.23", o.toString().substr(0,4));

		o = new StringBufOutput();
		o.writeInt16(-32768);
		assertEquals("-32768", o.toString());

		o = new StringBufOutput();
		o.writeUInt16(65535);
		assertEquals("65535", o.toString());

		var i32 = haxe.Int32.ofInt(123456789);
		var ten = haxe.Int32.ofInt(10);

		o = new StringBufOutput();
		i32 = haxe.Int32.ofInt(-123456789);
		o.writeInt32(i32);
		assertEquals("-123456789", o.toString());

		o = new StringBufOutput();
		i32 = haxe.Int32.ofInt(-123456789);
		i32 = haxe.Int32.mul(i32, ten);
		o.writeInt32(i32);
		assertEquals("-1234567890", o.toString());

		o = new StringBufOutput();
		o.writeString("Hi there");
		assertEquals("Hi there", o.toString());

		o = new StringBufOutput();
		o.writeUTF("Hi there");
		assertEquals("Hi there", o.toString());
	}
}

class ChxTest {
	static function main() 
	{
		//chx.Log.redirectTraces(false);
		var r = new haxe.unit.TestRunner();
		r.add(new ChxTests());
		r.run();
	}
}
