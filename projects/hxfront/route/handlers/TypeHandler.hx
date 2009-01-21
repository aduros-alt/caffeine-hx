package hxfront.route.handlers;

interface TypeHandler<T> {
	function handle(input : Input) : Bool;
	var handled(default, null) : T;
}

enum Input {
	INull;
	IString(s : String);
	IArray(a : Array<Input>);
	IDynamic(o : Dynamic<Input>);
}

class InputTools {
	public static function ofVar(v : Dynamic) {
		if(v == null) return INull;
		if(Std.is(v, String)) {
			v = StringTools.trim(v);
			if(v == '') return INull;
			return IString(v);
		}
		if(Std.is(v, Array)) {
			var a = [];
			var it : Array<Dynamic> = v;
			for(e in it)
				a.push(ofVar(e));
			return IArray(a);
		}
		if(Reflect.isObject(v)) {
			var o : Dynamic<Input> = cast {};
			for(field in Reflect.fields(v)) {
				Reflect.setField(o, field, ofVar(Reflect.field(v, field)));
			}
			return IDynamic(o);
		}
		return throw "Invalid input value: " + Std.string(v);
	}
}