package syntax;

import unit.Assert;

import syntax.util.Quantity;

class EnumSyntax {
	public function new() {}
	
	public function testEmptyInstance() {
	  var e = None;
	  Assert.isNotNull(e);
	}
	
	public function testParamInstance() {
	  var e = One(1);
	  Assert.isNotNull(e);
	}
	
	public function testParamsInstance() {
	  var e = Two(1, 2);
	  Assert.isNotNull(e);
	}
}