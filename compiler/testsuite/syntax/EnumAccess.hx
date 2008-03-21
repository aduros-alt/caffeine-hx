package syntax;

import unit.Assert;

enum BasicEnum {
	EOne;
	ETwo;
	EThree;
}

enum TypeEnum {
	TInt(a:Int);
	TFloat(f:Float);
	TString(s:String);
	TBool(b:Bool);
	TType(te:TypeEnum);
}

class EnumAccess {
	public function new() {}

    public function testBasicField() {
		var e = EOne;
		Assert.equals(EOne, e);
		e = ETwo;
		Assert.equals(ETwo, e);
		e = EThree;
		Assert.equals(EThree, e);
    }

	public function testIntType() {
		var e = TInt(5);
		var re = recoverValue(e);
		Assert.equals(5, re);
		var f = TFloat(5.0);
		var rf = recoverValue(f);
		Assert.equals(5.0, rf);
		Assert.equals(re, rf);
	}

	public function testStringType() {
		var s = TString("Hello");
		Assert.equals("Hello", recoverValue(s));
	}

	public function testWrapped() {
		var s = TType(TString("Hello"));
		Assert.equals("Hello", recoverValue(s));
	}


	static function recoverValue(e:TypeEnum) {
		var r : Dynamic;
		switch(e) {
		case TInt(v): r = v;
		case TFloat(v): r = v;
		case TString(v): r = v;
		case TBool(v): r = v;
		case TType(te): r = recoverValue(te);
		}
		return r;
	}

}
