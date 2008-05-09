package php;

class HString {
	private var __s : Dynamic;
	var length(default,null) : Int;
	function new(s:Dynamic) : Void {
		if(untyped __call__("is_string", s)) {
			untyped __php__("$this->__s = $s");
			length = untyped __call__("strlen", s);
		} else {
			untyped __php__("$this->__s = $s->__s");
			length =s.length;
		}
	}

	static function new1(s : Dynamic) : HString {
		return new HString(s);
	}

	function toUpperCase() : HString {
		return new1(untyped __call__("strtoupper", __s));
	}

	function toLowerCase() : HString {
		return new1(untyped __call__("strtolower", __s));
	}

	function charAt( index : Int) : HString {
		return new1(untyped __call__("substr", __s, index, 1));
	}

	function charCodeAt( index : Int) : Null<Int> {
		return untyped __php__("ord(substr($this->__s, $index, 1))");
	}

	function indexOf( value : HString, ?startIndex : Int ) : Int {
		var x = untyped __php__("strpos")(__s, value.__s, startIndex);
		if(untyped __php__("$x === false")) 
			return -1;
		else
			return x;
	}

	function lastIndexOf( value : HString, ?startIndex : Int ) : Int {
		var x = untyped __php__("strrpos")(__s, value.__s, startIndex == null ? null : length - startIndex);
		if(untyped __php__("$x === false")) 
			return -1
		else
			return x;
	}

	function split( delimiter : HString ) : Array<HString> {
		var p = untyped __call__("split", delimiter.__s, __s);
		var a = [];
		untyped __php__("foreach($p as $v) $a[] = new HString($v)");
		return a;
	}

	function substr( pos : Int, ?len : Int ) : HString {
		untyped if(__s == "") return new1("");
		if(len == null)
			return untyped new1(__call__("substr", __s, pos));
		else if(pos > 0 && pos >= len)
			return untyped new1("");
		else
			return untyped new1(__call__("substr", __s, pos, len));
	}

	function toString() : HString {
		return this;
	}

	public function __toString() : Dynamic {
		return __s;
	}

	static function fromCharCode( code : Int ) : HString {
		return new1(untyped __call__("chr", code));
	}
}