package syntax;

import unit.Assert;

class UnusualConstructs {
	public function new(){}
	
	var value: Int;

	public function testAssignReturn() {
#if !hllua
		var v = setValue(10);
		Assert.equals(10, v);
#end
	}

	public function testBooleanReturn() {
#if !hllua
		var v = boolCheck();
		Assert.equals(true, v);
#end
	}

	public function testBooleanReturn2() {
		var v = boolCheck2();
		Assert.equals(true, v);
	}

#if !hllua
	private function setValue(v) {
		return value = v;
	}

	private function boolCheck() {
		var a: Int;
		return ((a = 10) == 10);
	}
#end

	private function boolCheck2() {
		var a = 10;
		return (a  == 10);
	}
}
