package hxfront.route.handlers;

import hxfront.route.handlers.TypeHandler;

class BoolHandler implements TypeHandler<Bool> {
	public var allownull(default, null) : Bool;
	public function new(allownull : Bool) {
		this.allownull = allownull;
	}

	public var handled(default, null) : Bool;
	public function handle(input : Input) : Bool {
		switch(input) {
			case INull:
				handled = null;
				return allownull;
			case IString(v):
				v = v.toLowerCase();
				if(v == 'true' || v == '1' || v == 'on')
					handled = true;
				else if(v == 'false' || v == '0' || v == 'off' || v == '')
					handled = false;
				else
					return false;
				return true;
			default:
				return false;
		}
	}
}