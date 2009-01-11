package chx;

/**
	A replacement for haxe.Log.trace which formats objects in a fashion which is easier to read.
**/
class Log {
	static var useFirebug : Bool = false;
	static var haxeLogTrace : Dynamic = haxe.Log.trace;

	public static function clear() : Void {
		haxe.Log.clear();
	}

	#if flash
	public static dynamic function setColor( rgb : Int ) {
		haxe.Log.setColor(rgb);
	}
	#end

	/**
		To initialize chx.Log as the default tracer. In js and flash, the optional
		[useFirebug] will redirect formatted traces through Firebug, if it is detected.
	**/
	public static function redirectTraces(?useFirebug : Bool = false) {
		#if (flash || flash9 || js)
			if(haxe.Firebug.detect())
				Log.useFirebug = true;
			else
				Log.useFirebug = false;
		#end
		haxe.Log.trace = trace;
	}

	public static function trace(v : Dynamic, ?inf : haxe.PosInfos ) {
		var s = prettyFormat(v, "");
		#if (flash || flash9 || js)
			if(Log.useFirebug) {
				haxe.Firebug.trace(s, inf);
				return;
			}
		#end
		haxeLogTrace(s, inf);
	}

	/**
		@todo Enums and classes
	**/
	public static function prettyFormat(v : Dynamic, ?indent : String =  "") : String {
		var buf = new StringBuf();
		switch( Type.typeof(v) ) {
		case TClass(c):
			if(c == String)
				buf.add("'" + v + "'");
			else
				switch( c ) {
				case cast Array:
					#if flash9
					var v : Array<Dynamic> = v;
					#end
					var l = #if (neko || flash9 || php) v.length #else v[untyped "length"] #end;
					var first = true;
					if(l > 0)
						buf.add(iterFmtLinear("[","]",indent, v.iterator()));
					else
						buf.add("[]");
				case cast List:
					if(v.length > 0)
						buf.add(iterFmtLinear("{","}",indent, v.iterator()));
					else
						buf.add("{}");
				case cast Hash:
					buf.add(
						iterFmtAssoc("{", "}", " => ", indent, v.keys(), v.get)
					);
				case cast IntHash:
					buf.add(
						iterFmtAssoc("{", "}", " => ", indent, v.keys(), v.get)
					);
				default:
					buf.add(Std.string(v));
				}
		case TObject:
			buf.add(
				iterFmtAssoc("{", "}", " : ", indent, Reflect.fields(v).iterator(), callback(Reflect.field, v))
			);
		case TEnum(e):
			buf.add(Std.string(v));
		default:
// trace("default: " + Type.typeof(v));
			buf.add(Std.string(v));
		}
		return buf.toString();
	}



	/**
		Will format arrays and lists.
	**/
	static function iterFmtLinear<T>(open:String, close:String, indent : String, iter : Iterator<T>) {
		var buf = new StringBuf();
		buf.add(open);
		buf.add("\n");
		var ni = indent + "  ";
		var first = true;
		while(iter.hasNext()) {
			var i = iter.next();
			if(!first)
				buf.add(",\n");
			buf.add(ni);
			buf.add(prettyFormat(i, indent + "  "));
			first = false;
		}
		buf.add("\n");
		buf.add(indent);
		buf.add(close);
		return buf.toString();
	}

	/**
		@param separator The string to place between keys and values.
		@param valueRetriever A method to return the value for a given key.
	**/
	static function iterFmtAssoc<T>(open:String, close:String, separator:String, indent : String, keysIter : Iterator<T>, valueRetriever : T->Dynamic) {
		var buf = new StringBuf();
		if(!keysIter.hasNext()) {
			buf.add(open);
			buf.add(close);
			return buf.toString();
		}
		buf.add(open);
		buf.add("\n");

		var ni= indent + "  ";
		var first = true;

		while(keysIter.hasNext()) {
			var key = keysIter.next();
			var value = valueRetriever(key);
			if(!first)
				buf.add(",\n");
			buf.add(ni);

			buf.add(key);
			buf.add(separator);

			buf.add(prettyFormat(value, ni));
			first = false;
		}
		buf.add("\n");
		buf.add(indent);
		buf.add(close);
		return buf.toString();
	}
}