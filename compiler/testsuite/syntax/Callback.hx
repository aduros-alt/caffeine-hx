package syntax;

import unit.Assert;

class CallbackOther {
	var counter : Int;
	public function new() { counter = 25; }

	public function cboMember(v:Int) {
		counter += v;
		return counter;
	}

	public static function cboStatic(v:Int) {
		return v;
	}
}

class Callback {
	var counter : Int;
	public function new() {}

	public function testCallback() {
#if !php
		counter = 0;
        var n = "haXe";
        var cc = callback(f, n);
		Assert.equals("haXe", cc());
		Assert.equals(1,counter);
        n = "Neko";
        Assert.equals("haXe", cc());
		Assert.equals(2,counter);
#end
    }

	// for comparison
	public function testClosure() {
        var n = "haXe";
        var cc = function() { return n; };
		Assert.equals("haXe", cc());
        n = "Neko";
        Assert.equals("Neko", cc());
    }

	public function testCallbackOther() {
#if !php
		var c = new CallbackOther();
		var cc = callback(c.cboMember);
		Assert.equals(27, cc(2));
#end
	}

	public function testCallbackOther2() {
#if !php
		var c = new CallbackOther();
		var cc = callback(c.cboMember,5);
		Assert.equals(30, cc());
#end
	}

	public function testCallbackOtherStatic() {
#if !php
		var cc = callback(CallbackOther.cboStatic,5);
		Assert.equals(5, cc());
#end
	}

    public function f(name:String) {
		counter ++;
        return name;
    }
}