package syntax;

import unit.Assert;

class MagicMethods {
	public function new() {}
	
	public function testSet() {
		var o = new MagicSet();
		o.name = "haXe";
		Assert.equals("namehaXe", o.setfieldcalled);
		Assert.equals("haXe", o.name);
	}
	
	public function testResolve() {
		var o = new MagicResolve();
		Assert.equals("fhaXe", o.f("haXe"));
	}
}

class MagicSet implements Dynamic {
	private var h : Hash<String>;
	public function new() {
		h = new Hash();
	}
	public var setfieldcalled : String;
	private function __setfield(n, v) {
		setfieldcalled = Std.string(n) + Std.string(v);
		this.h.set(n, v);
	}
	
	private function __resolve(n) {
		if(h.exists(n))
			return h.get(n);
		else
			return null;
	}
}

class MagicResolve implements Dynamic {
	public function new() {	}
	
	private function __resolve(n) {
		return Reflect.makeVarArgs(function(args) {
			return n + Std.string(args[0]); // Std.string since untyped + untyped does not create a string concatenation
			                                // this will be probably fixed in future with __box/__unbox
		});
	}
}