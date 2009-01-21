package hxfront.route.handlers;

import hxfront.route.handlers.TypeHandler;

class IntHandler implements TypeHandler<Int> {
	public var allownull(default, null) : Bool;
	public function new(allownull : Bool) {
		this.allownull = allownull;
	}

	public var handled(default, null) : Int;
	public function handle(input : Input) : Bool {
		switch(input) {
			case INull:
				handled = null;
				return allownull;
			case IString(v):
				handled = Std.parseInt(v);
				return handled != null;
			default:
				return false;
		}
	}
}