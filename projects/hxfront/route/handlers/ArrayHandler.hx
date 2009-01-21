package hxfront.route.handlers;

import hxfront.route.handlers.TypeHandler;

class ArrayHandler<T> implements TypeHandler<Array<T>> {
	public var itemHandler(default, null) : TypeHandler<T>;
	public var allownull(default, null) : Bool;
	public function new(allownull : Bool, itemHandler : TypeHandler<T>) {
		this.allownull = allownull;
		this.itemHandler = itemHandler;
	}

	public var handled(default, null) : Array<T>;
	public function handle(input : Input) : Bool {
		switch(input) {
			case INull:
				handled = null;
				return allownull;
			case IArray(a):
				handled = [];
				for(i in a) {
					if(!itemHandler.handle(i)) return false;
					handled.push(itemHandler.handled);
				}
				return true;
			default:
				return false;
		}
	}
}