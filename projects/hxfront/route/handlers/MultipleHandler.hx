package hxfront.route.handlers;

import hxfront.route.handlers.TypeHandler;

class MultipleHandler implements TypeHandler<Dynamic> {
	var types : Hash<{ inst : TypeHandler<Dynamic>, instantiator : Void->TypeHandler<Dynamic>}>;
	public var type(default, null) : String;
	public function new() {
		types = new Hash();
	}

	public function canHandleType(type : String) {
		if(types.exists(type)) {
			this.type = type;
			return true;
		}
		return false;
	}

	public function registerType(type : String, cls : Class<Dynamic>, ?args : Array<Dynamic>) {
		if(args == null) args = [];
		registerInstantiator(type, function() {
			return Type.createInstance(cls, args);
		});
	}

	public function registerInstantiator(type : String, f : Void->TypeHandler<Dynamic>) {
		types.set(type, { inst : null, instantiator : f });
	}

	public function register(type : String, handler : TypeHandler<Dynamic>) {
		types.set(type, { inst : handler, instantiator : null });
	}

	public function getHandler(type : String) {
		var pair = types.get(type);
		if(pair == null) return null;
		if(pair.inst == null) {
			pair.inst = pair.instantiator();
			pair.instantiator = null;
		}
		return pair.inst;
	}

	public function handledTypes() : Iterator<String> {
		return types.keys();
	}

	public function handle(input : Input) : Bool {
		var handler = getHandler(type);
		if(handler.handle(input)) {
			handled = handler.handled;
			return true;
		}
		return false;
	}
	public var handled(default, null) : Dynamic;
}