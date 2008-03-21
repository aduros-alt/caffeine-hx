package syntax;

import unit.Assert;

class CodeBlocks {
	public function new() {}
	
	public function testAssign() {
	  var x = 1;
	  x = {
	    var y = 1;
		y + x;
	  }
	  Assert.equals(2, x);
	}
	
	public function nestedBlock() {
	  var x = 1;
	  x = {
	    var y = 1;
		x = { 
		  var z = 1;
		  z + x; 
		}
		x + y;
	  }
	  Assert.equals(3, x);
	}
}