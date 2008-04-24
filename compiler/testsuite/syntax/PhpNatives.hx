package syntax;

import unit.Assert;

class PhpNatives {
	public function new() {}

	private var st : String;
	private var dy : Dynamic;
	private var ar : Array<Int>;
	
	public function testDString() {
/*
		var d : Dynamic = "string";
		dy = "string";
		Assert.equals("s", d.substr(0, 1));
		Assert.equals("s", dy.substr(0, 1));
*/
	}
	
	public function testDDString() {
/*
		var d1 : Dynamic = "string";
		var d2 : Dynamic = "string";
		var d3 : Dynamic = "String";
		st = "String";
		dy = "string";
		Assert.isTrue(d1 == d2);
		Assert.isTrue(d1 != d3);
		Assert.isTrue(d1 != st);
		Assert.isTrue(d3 == st);
		Assert.isTrue(d3 != dy);
		Assert.isTrue(d1 == dy);
*/
	}
	
	public function testDStringConcatenation() {
/*
		var d : Dynamic = "s";
		dy = "s";
		Assert.equals("st", d + "t");
		Assert.equals("st", dy + "t");
*/
	}
	
	public function testDStringRef() {
/*
		var s = "s";
		var d = dref(s);
		dy = dref(s);
		Assert.equals("s", d);
		Assert.equals("s", dy);
		Assert.equals("s", dref("s"));
*/
	}
	
	public function testDStringArg() {
/*
		var s = "s";
		var ds : Dynamic = "s";
		var d = darg(s);
		dy = darg(s);
		Assert.equals("s", d);
		Assert.equals("s", dy);
		Assert.equals("s", darg("s"));
		Assert.equals("s", darg(ds));
*/
	}
	
	public function testDTString() {
/*
		var s = "s";
		var d = dtarg(s);
		dy = dtarg(s);
		Assert.equals("s", d);
		Assert.equals("s", dy);
		Assert.equals("s", dtarg("s"));
*/
	}
	
	public function testDArray() {
/*
		var a : Dynamic = [1, 2];
		ar = [1, 2];
		Assert.equals(2, a.length);
		Assert.equals(1, a[0]);
		Assert.equals(2, ar.length);
		Assert.equals(1, ar[0]);
*/
	}
	
	public function testDArrayRef() {
/*
		var a = [1, 2];
		ar = [1, 2];
		var d = adref(a);
		dy = adref(ar);
		Assert.equals(2, d.length);
		Assert.equals(2, dy.length);
		Assert.equals(2, adref([1, 2]).length);
*/
	}
	
	public function testDArrayArg() {
/*
		var a = [1, 2];
		ar = [1, 2];
		var d = adarg(a);
		dy = adarg(ar);
		Assert.equals(2, d.length);
		Assert.equals(2, dy.length);
		Assert.equals(2, adarg([1, 2]).length);
*/
	}
	
	public function testDoubleBox() {
/*
		var d1 : Dynamic = "s";
		var d2 : Dynamic = d1; // this must not be boxed
		Assert.equals("s", d2);
*/
	}
	
	public function testUntypedCast() {
/*
		var d1 : Dynamic = "s";
		var s : String = cast d1;
		Assert.equals(1, s.length);
		Assert.equals(1, d1.length);
		d1 = [1];
		var a : Array<Int> = cast d1;
		Assert.equals(1, a.length);
		Assert.equals(1, d1.length);
*/
	}
	
	public function testCast() {
/*
		var d1 : Dynamic = "s";
		var s : String = cast(d1, String);
		Assert.equals(1, s.length);
		Assert.equals(1, d1.length);
		d1 = [1];
		var a : Array<Dynamic> = cast(d1, Array<Dynamic>);
		Assert.equals(1, a.length);
		Assert.equals(1, d1.length);
*/
	}
	
	public function testEnum() {
/*
		var a1 = arr([1]);
		var a2 = darr([1]);
		var s1 = str("s");
		var s2 = dstr("s");
		enumAssert(a1, [1]);
		enumAssert(a2, [1]);
		enumAssert(s1, "s");
		enumAssert(s2, "s");
*/
	}
	
	static function enumAssert(e : NativesEnum, ?aeq : Array<Int>, ?seq : String) {
		switch(e) {
			case arr(a):
				Assert.equals(aeq.length, a.length);
				Assert.equals(aeq[0], a[0]);
			case darr(a):
				Assert.equals(aeq.length, a.length);
				Assert.equals(aeq[0], a[0]);
			case str(s):
				Assert.equals(seq.length, s.length);
				Assert.equals(seq, s);
			case dstr(s):
				Assert.equals(seq.length, s.length);
				Assert.equals(seq, s);
			default:
				Assert.fail();
		}
	}
	
	static function dref(s : String) : Dynamic {
		return s;
	}
	
	static function darg(d : Dynamic) : Dynamic {
		return d;
	}
	
	static function dtarg(d : Dynamic) : String {
		return d;
	}
	
	static function adref(a : Array<Int>) : Dynamic {
		return a;
	}
	
	static function adarg(a : Dynamic) : Array<Int> {
		return a;
	}
}

enum NativesEnum {
	arr(a : Array<Int>);
	darr(a : Dynamic);
	str(s : String);
	dstr(s : Dynamic);
}