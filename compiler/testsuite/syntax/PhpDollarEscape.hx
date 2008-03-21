package syntax;

import unit.Assert;

class PhpDollarEscape {
  public function new() {}
  
  public function testDollar() {
	var dollar = "$a";
	Assert.equals("$" + "a", dollar);
  }
}