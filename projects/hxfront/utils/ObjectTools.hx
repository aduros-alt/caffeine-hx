package hxfront.utils;

class ObjectTools {
	public static function merge(objs : Iterable<Dynamic>, ?r : Dynamic) : Dynamic {
		if(null == r) r = {};
		for(ob in objs)
			for( f in Reflect.fields(ob))
				Reflect.setField(r, f, Reflect.field(ob,f));
		return r;
	}
}