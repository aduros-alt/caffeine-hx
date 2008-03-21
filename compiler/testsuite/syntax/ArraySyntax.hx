package syntax;

import unit.Assert;

class ArraySyntax {
	public function new() {}
	
	public function testCreateEmpty() {
		var o = [];
		Assert.isNotNull(o);
	}
	
	public function testCreateFilled() {
		var o = [ "Franco" , "Gabriel" ];
		Assert.equals(2, o.length);
	}
	
	public function testAccessElement() {
		var o = [ "Franco" , "Gabriel" ];
		Assert.equals("Franco", o[0]);
		Assert.equals("Gabriel", o[1]);
	}
	
	public function testReplaceElement() {
		var o = [ "Franco" , "Gabriel" ];
		Assert.equals("Franco", o[0]);
		o[0] = "Cristina";
		Assert.equals("Cristina", o[0]);
		Assert.equals("Gabriel", o[1]);
	}	
}