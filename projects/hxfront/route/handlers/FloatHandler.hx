package hxfront.route.handlers;

import hxfront.route.handlers.TypeHandler;

class FloatHandler implements TypeHandler<Float> {
	public var allownull(default, null) : Bool;
	public function new(allownull : Bool) {
		this.allownull = allownull;
	}

	public var handled(default, null) : Float;
	public function handle(input : Input) : Bool {
		switch(input) {
			case INull:
				handled = null;
				return allownull;
			case IString(v):
				handled = Std.parseFloat(v);
				return !Math.isNaN(handled);
			default:
				return false;
		}
	}
}