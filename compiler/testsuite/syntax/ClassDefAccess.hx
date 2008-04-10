package syntax;

import unit.Assert;

import syntax.util.A;

class ClassDefAccess {
  public function new(){}
  
  public function testAccess() {
    var c = A;
    Assert.isNotNull(c);
    var c = syntax.util.A;
    Assert.isNotNull(c);
  }
  
  public function testMethodAccess() {
    var c = A;
    Assert.equals("test", c.test());
  }
  
  public function testVarAccess() {
    var c = A;
    Assert.equals("test", c.s);
    c.s = "test2";
    Assert.equals("test2", c.s);
  }
}