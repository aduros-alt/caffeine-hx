package syntax;

import unit.Assert;

class UnusualConstructs {
	public function new(){}
	
	var value: Int;

	public function testAssignReturn() {
		var v = setValue(10);
		Assert.equals(10, v);
	}

	public function testBooleanReturn() {
		var v = boolCheck();
		Assert.equals(true, v);
	}

	public function testBooleanReturn2() {
		var v = boolCheck2();
		Assert.equals(true, v);
	}

	private function setValue(v) {
		return value = v;
	}

	private function boolCheck() {
		var a: Int;
		return ((a = 10) == 10);
	}

	private function boolCheck2() {
		var a = 10;
		return (a  == 10);
	}
}