package syntax;

import unit.Assert;
import syntax.util.T;
import syntax.util.ITest;

class InterfaceAccess {
	public function new() {}
	public function testDirect() {
		var a : ITest = new T();
		a.msg = "test";
		Assert.equals("test", a.test());
	}
	
	public function testIndirect1() {
		var a = new T();
		Assert.equals("test", indirect(a));
	}
	
	public function testIndirect2() {
		Assert.equals("test", indirect(new T()));
	}
	
	function indirect(v : ITest) {
		v.msg = "test";
		return v.test();
	}
}