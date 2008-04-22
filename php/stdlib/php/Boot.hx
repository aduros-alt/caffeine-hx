package php;

class Boot {
	public static function __trace(v,i : haxe.PosInfos) {
		var msg = if( i != null ) i.fileName+":"+i.lineNumber+": " else "";
		untyped __call__("echo", msg+ __string_rec(v)+"<br/>"); // TODO: __unhtml
	}
	
	static public function __anonymous(?p : Dynamic) : Dynamic {
		untyped __php__("$o = new Anonymous();
		if(is_array($p)) {
			foreach($p as $k => $v) {
				$o->$k = $v;
			}
		}
		return $o");
	}
	
	static private var __cid = 0;
	static public var __scopes = [];
	static public function __closure(locals, params, body) : String {
		var cid = __cid++;
		var n = "__closure__"+cid+"__";
		if(locals == null) locals = [];
		untyped __php__("php_Boot::$__scopes[$n] = array('scope' => null, 'locals' => $locals)");
		var f : String = untyped __call__(
			"create_function", 
			params, 
			"$__this =& php_Boot::$__scopes['"+n+"']['scope'];\nforeach(array_keys(php_Boot::$__scopes['"+n+"']['locals']) as ${'%k'}) ${${'%k'}} =& php_Boot::$__scopes['"+n+"']['locals'][${'%k'}];\n"+body);
		var nl = "__"+f.substr(1)+"__";
		untyped __php__("php_Boot::$__scopes[$nl] =& php_Boot::$__scopes[$n]");
		return f;
	}
	
	static public function __array_iterator<T>(arr : Dynamic) : Iterator<T> {
		return untyped __php__("new HArrayIterator($arr)");
	}
	
	static public function __array_sort<T>(arr : Array<T>, f : T -> T -> Int) : Void {
		untyped __php__("$arr =& $arr[0]");
		var i = 0;
		var l = arr.length;
		while( i < l ) {
			var swap = false;
			var j = 0;
			var max = l - i - 1;
			while( j < max ) {
				if( f(arr[j],arr[j+1]) > 0 ) {
					var tmp = arr[j+1];
					arr[j+1] = arr[j];
					arr[j] = tmp;
					swap = true;
				}
				j += 1;
			}
			if(!swap) break;
			i += 1;
		}	
	}

	static public function __array_insert<T>(arr : Array<T>,  pos : Int, x : T) : Void {
		untyped __php__("$arr =& $arr[0]");
		untyped __php__("array_splice")(arr, pos, 0, __call__("array", x));
	}
	
	static public function __array_remove<T>(arr : Array<T>, x : T) : Bool {
		untyped __php__("$arr =& $arr[0]");
		for(i in 0...arr.length)
			if(arr[i] == x) {
				untyped __call__("unset", arr[i]);
				arr = untyped __call__("array_values", arr);
				return true;
			}
		return false;
	}
	
	static public function __array_remove_at(arr : Array<Dynamic>, pos : Int) : Bool {
		untyped __php__("$arr =& $arr[0]");
		if(untyped __php__("array_key_exists")(pos, arr)) {
			untyped __php__("unset")(arr[pos]);
			return true;
		} else return false;
	}
	
	static public function __array_splice(arr : Array<Dynamic>, pos : Int, len : Int) : Bool {
		untyped __php__("$arr =& $arr[0]");
		if(len < 0) len = 0;
		return untyped __php__("array_splice")(arr, pos, len);
	}
	
	static public function __array_slice(arr : Array<Dynamic>, pos : Int, ?end : Int) : Bool {
		untyped __php__("$arr =& $arr[0]");
		if(end == null)
			return untyped __php__("array_slice")(arr, pos);
		else
			return untyped __php__("array_slice")(arr, pos, end-pos);
	}
  
	static public function __array_set<T>(arr : Array<Dynamic>, pos : Int, v : T) : T untyped {
		__php__("$arr =& $arr[0]");
		if(__call__("is_int", pos)) {
			var l = __call__("count", arr);
			if(l < pos) {
			__call__("array_splice", arr, l, 0, __call__("array_fill", l, pos-l, null)); 
			}
		}
		__php__("$arr[$pos] = $v");
		return v;
	}
	
	static public function __substr(s : String, pos : Int, ?len : Int) {
		if( pos != null && pos != 0 && len != null && len < 0 ) return '';
		if( len == null ) len = s.length;
		if( pos < 0 ) {
			pos = s.length + pos;
			if( pos < 0 ) pos = 0;
		} else if( len < 0 )
			len = s.length + len - pos;
		var s : Bool = untyped __php__("substr")(s, pos, len);
		if(s === false) return "" else return untyped s;
	}

	static public function __index_of(s : String, value : String, ?startIndex : Int) {
		var x = untyped __php__("strpos")(s, value, startIndex);
		if(untyped __php__("$x === false")) 
			return -1;
		else
			return x;
	}
	
	static public function __last_index_of(s : String, value : String, ?startIndex : Int) {
		var x = untyped __php__("strrpos")(s, value, startIndex == null ? null : s.length - startIndex);
		if(untyped __php__("$x === false")) 
			return -1
		else
			return x;
	}
	
	static public function __instanceof(v : Dynamic, t : Dynamic) {
		if(t == null) return false;
		switch(t.__tname__) {
			case "Array":
				return untyped __php__("is_array")(v);
			case "String":
				return untyped __php__("is_string")(v);
			case "Bool":
				return untyped __php__("is_bool")(v);
			case "Int":
				return untyped __php__("is_int")(v);
			case "Float":
				return untyped __php__("is_float")(v) || __php__("is_int")(v);
			default:
				return untyped __php__("is_a")(v, t.__tname__);
		}
	}
	
	static public function __shift_right(v : Int, n : Int) {
		untyped __php__("$z = 0x80000000;  
		if ($z & $v) { 
			$v = ($v>>1);
			$v &= (~$z);
			$v |= 0x40000000;
			$v = ($v>>($n-1));
		} else $v = ($v>>$n)");
		return v;
	}
	
	static public function __error_handler(errno : Int, errmsg : String, filename : String, linenum : Int, vars : Dynamic) {
		var msg = errmsg + " (errno: " + errno + ") in " + filename + " at line #" + linenum;
		var e = new php.HException(msg, errmsg, errno);
		e.setFile(filename);
		e.setLine(linenum);
		untyped __php__("throw $e");
		return null;
	}
	
	static public function __exception_handler(e : Dynamic) {
		var msg = "<pre>Uncaught exception: <b>"+e.getMessage()+"</b>\nin file: <b>"+e.getFile()+"</b> line <b>"+e.getLine()+"</b>\n\n"+e.getTraceAsString()+"</pre>";
		untyped __php__("die($msg)");
	}
  
	static public function __equal(x : Dynamic, y : Dynamic) untyped {
		if(__call__("is_null", x)) {
			return __call__("is_null", y);
		} else if(__call__("is_null", y)) {
			return false;
		} else {
		if((__call__("is_float", x) || __call__("is_int", x)) && (__call__("is_float", y) || __call__("is_int", y))) {
			return __php__("$x == $y");
		} else {
			return __php__("$x === $y");
		}
		}
	}

	static private var __qtypes;
	static private var __ttypes;
	static public function __register_type(t) {
		untyped __qtypes[t.__qname__] = t;
		untyped __ttypes[t.__tname__] = t;
	}

	static public function __qtype(n) untyped {
		if(__call__("isset", __qtypes[n]))
			return __qtypes[n];
		else 
			return null;
	}

	static public function __ttype(n) untyped {
		if(__call__("isset", __ttypes[n]))
			return __ttypes[n];
		else 
			return null;
	}
	
	static public function __deref(byref__o : Dynamic) {
		return byref__o;
	}
	
	static public function __byref__array_get(byref__o : Dynamic, index : Dynamic) {
		return untyped byref__o[index];
	}
	
	static private var __resources = [];
	static public function __res(n : String) : String untyped {
		if(! __php__("isset(self::$__resources[$n])")) {
			var file = __php__("dirname(__FILE__).'/../../res/'.$n");
			if(!__call__("file_exists", file))
				throw "Invalid Resource name: " + n;
			__php__("self::$__resources[$n] = file_get_contents($file)");
		}
		return __php__("self::$__resources[$n]");
	}
  
	static function __init__() untyped {
		__php__("//error_reporting(0);
set_error_handler(array('php_Boot', '__error_handler'), E_ALL);
set_exception_handler(array('php_Boot', '__exception_handler'));

class Anonymous extends stdClass{
	public function __call($m, $a) {
		$v = $this->$m;
		if(is_string($v) && substr($v, 0, 8) == chr(0).'lambda_') {
			$nl = '__'.substr($v, 1).'__';
			php_Boot::$__scopes[$nl]['scope'] =& $this;
		}
		try {
			return call_user_func_array($v, $a);
		} catch(Exception $e) {
			throw new php_HException('Unable to call «'.$m.'»');
		}
	}
	
	public function __set($n, $v) {
		$this->$n = $v;
	}
	
	public function &__get($n) {
		if(isset($this->$n))
			return $this->$n;
		$null = null;
		return $null;
	}
	
	public function __isset($n) {
		return isset($this->$n);
	}
	
	public function __unset($n) {
		unset($this->$n);
	}
	
	public function __toString() {
		return php_Boot::__string_rec($this, null);
	}
}

class _typedef {
	public $__tname__;
	public $__qname__;  
	public function __construct($cn, $qn) {
		$this->__tname__ = $cn;
		$this->__qname__ = $qn;
	}
	
	public function toString()   { return $this->__toString(); }
	
	public function __toString() {
		return $this->__qname__;
	}
}

class _classdef extends _typedef { }

class _enumdef extends _typedef {
	public $__rfl__;
	public function __construct($cn, $qn) {
		parent::__construct($cn, $qn);
		$this->__rfl__ = new ReflectionClass($cn);
	}

	public function __call($n, $a) {
		return call_user_func_array(array($this->__tname__, $n), $a);
	}

	public function __get($n) {
		if($this->__rfl__->hasProperty($n))
			return $this->__rfl__->getStaticPropertyValue($n);
		else if($this->__rfl__->hasMethod($n))
			return array($this->__tname__, $n);
		else
			return null;
	}

	public function __set($n, $v) {
		return $this->__rfl__->setStaticPropertyValue($n, $v);
	}

	public function __isset($n) {
		return $this->__rfl__->hasProperty($n) || $this->__rfl__->hasMethod($n);
	}	
}

class _interfacedef extends _typedef { }

class _rclassdef extends _classdef {
	public $__rfl__;
	public function __construct($cn, $qn) {
		parent::__construct($cn, $qn);
		$this->__rfl__ = new ReflectionClass($cn);
	}

	public function __call($n, $a) {
		return call_user_func_array(array($this->__tname__, $n), $a);
	}

	public function __get($n) {
		if($this->__rfl__->hasProperty($n))
			return $this->__rfl__->getStaticPropertyValue($n);
		else if($this->__rfl__->hasMethod($n))
			return array($this->__tname__, $n);
		else
			return null;
	}

	public function __set($n, $v) {
		return $this->__rfl__->setStaticPropertyValue($n, $v);
	}

	public function __isset($n) {
		return $this->__rfl__->hasProperty($n) || $this->__rfl__->hasMethod($n);
	}
}

class HArrayIterator {
	private $a;
	private $i;
	public function __construct($a) {
		$this->a = $a;
		$this->i = 0;
	}
	
	public function next() {
		return $this->a[$this->i++];
	}
	
	public function hasNext() {
		return $this->i < count($this->a);
	}
}

class php_HException extends Exception {
	public function __construct($e, $message = null, $code = null, $p = null) { if( !php_Boot::$skip_constructor ) {
		parent::__construct($message,$code);
		$this->e = $e;
		$this->p = $p;
	}}
	public $e;
	public $p;
	public function setLine($l) {
		$this->line = $l;
	}
	public function setFile($f) {
		$this->file = $f;
	}
}

class enum {
	public function __construct($tag, $index, $params = null) { $this->tag = $tag; $this->index = $index; $this->params = $params; }
	public $tag;
	public $index;
	public $params;

	public function __toString() {
		return $this->tag;
	}
}

php_Boot::$__qtypes = array();
php_Boot::$__ttypes = array();
");
	__php__('php_Boot::__register_type(new _classdef("String",  "String"))');
	__php__('php_Boot::__register_type(new _classdef("Array",   "Array"))');
	__php__('php_Boot::__register_type(new _classdef("Int",     "Int"))');
	__php__('php_Boot::__register_type(new _classdef("Float",   "Float"))');
	__php__('php_Boot::__register_type(new _classdef("Bool",    "Bool"))');
	__php__('php_Boot::__register_type(new _classdef("Dynamic", "Dynamic"))');
	}
	
	static public function __string_rec(o : Dynamic, ?s : String) {
		if( o == null )
			return "null";
		if( s.length >= 5 )
			return "<...>"; // too much deep recursion
		
		if(untyped __call__("is_int", o) || __call__("is_float", o))
			return o;
			
		if(untyped __call__("is_bool", o))
			return o ? "true" : "false";
			
		if(untyped __call__("is_object", o)) {
			var c = untyped __call__("get_class", o);
			if(untyped __php__("$o instanceof enum")) {
				var b : String = o.tag;
				if(!untyped __call__("empty", o.params)) {
					s += "\t";
					b += '(';
					for( i in 0...untyped __call__("count", o.params) ) {
						if(i > 0) 
							b += ',' + __string_rec(o.params[i],s);
						else
							b += __string_rec(o.params[i],s);
					}
					b += ')';
				}
				return b;
			} else if(untyped __php__("$o instanceof Anonymous")) {
				var rfl = untyped __php__("new ReflectionObject($o)");
				var b = "{\n";
				s += "\t";
				var properties : Array<Dynamic> = rfl.getProperties();
				for(prop in properties) {
					var f : String = prop.getName();
					if(b.length != 2)
						b += ", \n";
					b += s + f + " : " + __string_rec(prop.getValue(o), s);
				}
				s = s.substr(1);
				b += "\n" + s + "}";
				return b;
			} else if(untyped __php__("$o instanceof _typedef")) {
				return untyped __qtype(o.__qname__);
			} else {
				if(untyped __call__("is_callable", [o, "toString"]))
					return o.toString();
				else if(untyped __call__("is_callable", [o, "__toString"]))
					return o.__toString();
				else
					return "[" + __ttype(c) + "]";
			}
		}
			
		if(untyped __call__("is_callable", o))
			return "«function»";
			
		if(untyped __call__("is_string", o))
			if(s != null)
				return '"'+untyped __call__("str_replace", '"', '\"', o)+'"';
			else
				return o;
			
			
		if(untyped __call__("is_array", o)) {
			var str = "[";
			s += "\t";
			for( i in 0...untyped __call__("count", o) )
				str += (if (i > 0) "," else "")+__string_rec(untyped o[i],s);
			str += "]";
			return str;
		}
		
		return '';
	}
	static public var skip_constructor = false;
}