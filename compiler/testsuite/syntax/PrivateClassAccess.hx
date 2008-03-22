package syntax;

import unit.Assert;

class PrivateClassAccess {
	public function new() {}
	public function testInstance() {
		var v = new PrivateClass();
		Assert.equals("test", v.test());
	}
}

class PrivateClass {
	public function new() {}
	public function test() { return "test"; }
}