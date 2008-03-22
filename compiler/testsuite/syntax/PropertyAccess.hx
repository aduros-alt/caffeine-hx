package syntax;

import unit.Assert;

import syntax.util.PropertyClass;

class PropertyAccess {
	public function new() {}
	
	public function testReadonly() {
		var o = new PropertyClass();
		Assert.equals("readonly", o.readonly);
		o.setReadonly("test");
		Assert.equals("test", o.readonly);
	}
	
	public function testWriteonly() {
		var o = new PropertyClass();
		Assert.equals("writeonly", o.getWriteonly());
		o.writeonly = "test";
		Assert.equals("test", o.getWriteonly());
	}
	
	public function testExcessive() {
		var o = new PropertyClass();
		Assert.equals("excessive", o.excessive);
		o.excessive = "test";
		Assert.equals("test", o.excessive);
	}
	
	public function testNopoint() {
		var o = new PropertyClass();
		Assert.equals("nopoint", o.getNopoint());
		o.setNopoint("test");
		Assert.equals("test", o.getNopoint());
	}
	
	public function testGetterReadonly() {
		var o = new PropertyClass();
		Assert.equals("value", o.getterReadonly);
	}
	
	public function testSetterReadonly() {
		var o = new PropertyClass();
		o.setterReadonly = "test";
		Assert.equals("test", o.getterReadonly);
	}
	
	public function testSetter() {
		var o = new PropertyClass();
		Assert.equals("setter", o.getSetterValue());
		o.setter = "test";
		Assert.equals("test", o.getSetterValue());
	}
	
	public function testBoth() {
		var o = new PropertyClass();
		Assert.equals("value", o.both);
		o.both = "test";
		Assert.equals("test", o.both);
	}
	/*
	public function testGetterDynamic() { }
	public function testSetterDynamic() { }
	*/
}