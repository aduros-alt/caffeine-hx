package syntax;

import unit.Assert;

class Callback {
	public function new() {}
	
	public function testCallback() {
        var n = "haXe";
        var cc = callback(f, n);
		Assert.equals("haXe", cc());
        n = "Neko";
        Assert.equals("haXe", cc());
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
        return name;
    }
}