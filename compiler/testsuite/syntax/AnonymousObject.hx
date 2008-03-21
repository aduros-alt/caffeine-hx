package syntax;

import unit.Assert;

class AnonymousObject {
	public function new() {}
	
	public function testCreateEmpty() {
		var o = Reflect.empty();
		Assert.isNotNull(o);
	}
	
	public function testCreateObject() {
		var o = { name : "Franco" };
		Assert.isNotNull(o);
	}
	
	public function testAccessField() {
		var o = { name : "Franco", lastname : "Ponticelli" };
		Assert.equals("Franco", o.name);
		Assert.equals("Ponticelli", o.lastname);
	}
	
	public function testFunctionField() {
		var o = { f : function(n){ return "Hello " + n + "!"; } };
		Assert.isNotNull(o);
		Assert.isNotNull(o.f);
		Assert.equals("Hello Franco!", o.f("Franco"));
	}
	
	public function testObjectScope() {
	    var o : Dynamic;
		o = { name : "Franco", f : function() { return "Hello " + o.name + "!"; }};
		Assert.equals("Hello Franco!", o.f());
	}	
}