package hxfront.route.handlers;

import hxfront.route.handlers.TypeHandler;

class StringHandler implements TypeHandler<String> {
	public var allownull(default, null) : Bool;
	public function new(allownull : Bool) {
		this.allownull = allownull;
	}

	public var handled(default, null) : String;
	public function handle(input : Input) : Bool {
		switch(input) {
			case INull:
				handled = null;
				return allownull;
			case IString(v):
				handled = StringTools.urlDecode(v);
				return true;
			default:
				return false;
		}
	}
}