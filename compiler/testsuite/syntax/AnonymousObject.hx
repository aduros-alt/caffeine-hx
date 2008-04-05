package syntax;

import unit.Assert;

class AnonymousObject {
	public function new() {}
	
	public function testCreateEmpty() {
		var o = Reflect.empty();
		Assert.isNotNull(o);
	}
	
	public function testCreateObject() {
		var o = { name : "haXe" };
		Assert.isNotNull(o);
	}
	
	public function testAccessField() {
		var o = { name : "haXe", lastname : "Neko" };
		Assert.equals("haXe", o.name);
		Assert.equals("Neko", o.lastname);
	}
	
	public function testFunctionField() {
		var o = { f : function(n){ return "Hello " + n + "!"; } };
		Assert.isNotNull(o);
		Assert.isNotNull(o.f);
		Assert.equals("Hello haXe!", o.f("haXe"));
	}
	
	public function testObjectScope() {
	    var o : Dynamic;
		o = { name : "haXe", f : function() { return "Hello " + o.name + "!"; }};
		Assert.equals("Hello haXe!", o.f());
	}
	
	public function testNestedObjects() {
	  var o = { name : "haXe", locations : [{ town : "Lisbon" }, { town : "Milan" }], current : { town : "Lisbon" }};
	  Assert.equals("haXe", o.name);
	  Assert.equals("Lisbon", o.current.town);
	  Assert.equals("Lisbon", o.locations[0].town);
	  Assert.equals("Milan", o.locations[1].town);
	}
	
	public function testAccessingUnexistentField() {
		var o : Dynamic = {};
		Assert.isTrue(o != null);
#if flash9
		Assert.equals(null, o.name);
#else (flash || js)
		Assert.equals(untyped undefined, o.name);
#else true
    Assert.isNull(o.name);
#end
	}
}