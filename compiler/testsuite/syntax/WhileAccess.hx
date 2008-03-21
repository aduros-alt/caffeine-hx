package syntax;

import unit.Assert;

class WhileAccess {
	public function new() {}
	
	public function testWhile() {
	  var x = 0;
	  while(x < 3) {
		x++;
	  }
	  Assert.equals(3, x);
	}
	
	public function testBreak() {
	  var x = 0;
	  while(x < 3) {
		x++;
		break;
	  }
	  Assert.equals(1, x);
	}
	
	public function testContinue() {
	  var x = 0;
	  while(x < 3) {
		x++;
		continue;
		Assert.isTrue(false); // this must not be executed
	  }
	  Assert.equals(3, x);
	}
}