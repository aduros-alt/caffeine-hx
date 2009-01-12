package syntax;

import unit.Assert;

import syntax.util.A;
import syntax.util.B;

class ClassInheritance {
	public function new() {}
	public function testSuperAccess() {
	  var a = new A();
	  Assert.equals("test", a.msg());
	  var b = new B();
	  Assert.equals("testtest", b.msg());
	}
}