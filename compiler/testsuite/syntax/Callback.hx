package syntax;

import unit.Assert;

class Callback {
	var counter : Int;
	public function new() {}

	public function testCallback() {
		counter = 0;
        var n = "haXe";
        var cc = callback(f, n);
		Assert.equals("haXe", cc());
		Assert.equals(1,counter);
        n = "Neko";
        Assert.equals("haXe", cc());
		Assert.equals(2,counter);
    }

	// for comparison
	public function testClosure() {
        var n = "haXe";
        var cc = function() { return n; };
		Assert.equals("haXe", cc());
        n = "Neko";
        Assert.equals("Neko", cc());
    }

    public function f(name:String) {
		counter ++;
        return name;
    }
}