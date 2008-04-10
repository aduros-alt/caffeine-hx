package php;

class Boot {
	public static function __trace(v,i : haxe.PosInfos) {
		var msg = if( i != null ) i.fileName+":"+i.lineNumber+": " else "";
		untyped __call__("echo", msg+v+"<br/>"); // TODO: __unhtml
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
		untyped __php__("php_Boot::$__scopes[$n] = array('scope' => array('__this' => null), 'locals' => $locals)");
		var f : String = untyped __call__(
			"create_function", 
			params, 
			"extract(php_Boot::$__scopes['"+n+"']['locals']);\nextract(php_Boot::$__scopes['"+n+"']['scope']);\n"+body);
		var nl = "__"+f.substr(1, 100000)+"__"; // TODO: correct me: substr ($v, 1, null) != substr ($v, 1)
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
			if( !swap )
				break;
			i += 1;
		}	
	}

	static public function __array_insert<T>(arr : Array<T>,  pos : Int, x : T) : Void {
		untyped __php__("$arr =& $arr[0]");
		untyped __php__("array_splice")(arr, pos, 0, x);
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
	
	static public function __substr(s : String, pos : Int, ?offset : Int) {
		if(s == "") return "";
			if(offset == null)
				return untyped __php__("substr")(s, pos);
			else if(pos > 0 && offset < 0 && pos >= offset)
		  return "";
		else
		return untyped __php__("substr")(s, pos, offset);
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
		var msg = errmsg + " in " + filename + " at line #" + linenum;
		var e = new php.HException(msg, errmsg, errno);
		e.setFile(filename);
		e.setLine(linenum);
		untyped __php__("throw $e");
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
  
	static function __init__() untyped {
		__php__("set_error_handler(array('php_Boot', '__error_handler'), E_ALL)");
		__php__("set_exception_handler(array('php_Boot', '__exception_handler'))");
		__php__("//error_reporting(0)");
		__php__("

class Anonymous extends stdClass{
	public function __call($m, $a) {
		if(property_exists($this, $m) && is_callable($this->$m))
			return call_user_func_array($this->$m, $a);
		else
			throw new php_HException('NotAFunction', 'Unable to call '.$m);
	}
	
	public function __set($n, $v) {
		if(is_string($v) && substr($v, 0, 8) == chr(0).'lambda_') {
			$nl = '__'.substr($v, 1, 100000).'__'; // TODO: correct me: substr ($v, 1, null) != substr ($v, 1)
			php_Boot::$__scopes[$nl]['scope']['__this'] =& $this;
		}
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
}

class _typedef {
	public $__tname__;
	public $__qname__;  
	public function __construct($cn, $qn) {
		$this->__tname__ = $cn;
		$this->__qname__ = $qn;
	}
	
	public function toString()   { return $this->__toString(); }
	public function __toString() { return $this->__qname__; }
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
	public function toString() { return $this->__toString(); }
	public function __toString() {
		return $this->tag . (is_array($this->params) > 0 ? '('.join(',',$this->params).')' : '');
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
	/*
	private static function __string_rec(o,s) {
		if( o == null )
			return "null";
		if( s.length >= 5 )
			return "<...>"; // too much deep recursion
		
		var t = Reflect.getClass(o);
		switch(t) {
			case "Array":
				var l = o.length;
				var i;
				var str = "[";
				s += "\t";
				for( i in 0...l )
					str += (if (i > 0) "," else "")+__string_rec(o[i],s);
				str += "]";
				return str;
			case "String":
				return '"'+v.replace('"', '\"')+'"';
			case "Bool":
				return v ? "true" : "false";
			case "Int":
				return v;
			case "Float":
				return v;
			default: // Object
				if(Std.is(o, untyped enum)) {
				
				} else if(Std.is(o, untyped Anonymous) {
				
				} else {
					try {
						return o.toString();
					} catch( e : Dynamic ) {
						return "[" + t + "]";
					}
				}
		}
			
			
		var t = __js__("typeof(o)");
		if( t == "function" && (o.__name__ != null || o.__ename__ != null) )
			t = "object";
		switch( t ) {
		case "object":
			if( __js__("o instanceof Array") ) {
				if( o.__enum__ != null ) {
					if( o.length == 2 )
						return o[0];
					var str = o[0]+"(";
					s += "\t";
					for( i in 2...o.length ) {
						if( i != 2 )
							str += "," + __string_rec(o[i],s);
						else
							str += __string_rec(o[i],s);
					}
					return str + ")";
				}

			}
			var tostr;
			try {
				tostr = untyped o.toString;
			} catch( e : Dynamic ) {
				// strange error on IE
				return "???";
			}
			if( tostr != null && tostr != __js__("Object.toString") ) {
				var s2 = o.toString();
				if( s2 != "[object Object]")
					return s2;
			}
			var k : String;
			var str = "{\n";
			s += "\t";
			var hasp = (o.hasOwnProperty != null);
			__js__("for( var k in o ) { ");
				if( hasp && !o.hasOwnProperty(k) )
					__js__("continue");
				if( k == "prototype" || k == "__class__" || k == "__super__" || k == "__interfaces__" )
					__js__("continue");
				if( str.length != 2 )
					str += ", \n";
				str += s + k + " : "+__string_rec(o[k],s);
			__js__("}");
			s = s.substring(1);
			str += "\n" + s + "}";
			return str;
		case "function":
			return "<function>";
		case "string":
			return '"' + o . '"';
		default:
			return o;
		}
	}
	*/
	// TODO: improve, see js.Boot.__string_rec
	
	static public function __string_rec(o : Dynamic) {
		var r = null;
		untyped __php__(
"	if(is_array($o)) {
	  $c = 0;
	  $r = '[ ';
	  foreach($o as $v) {
		  if($c > 0) $r .= ', ';
		  $r .= self::__string_rec($v);
		  $c++;
	  }
	  $r .= ' ]';
	} else if(is_object($o)) { 
	  if(is_callable(array($o, 'toString')))
	    $r = call_user_func(array($o, 'toString'));
	  else if(is_callable(array($o, '__toString')))
	    $r = call_user_func(array($o, '__toString'));
	  else {
	    $vars = get_object_vars($o);
		$r = '{ ';
		$i=0;
		foreach($vars as $n => $v) {
		  if($i++ > 0) $r.=', ';
		  $r .= $n.' : '.php_Boot::__string_rec($v);
		}
		$r .= ' }';
	  }
	} else if($o === null) {
	  $r = 'null';
	} else if(is_string($o)) {
      if(substr($o, 0, 8) == '?lambda_')
		$r = 'function()';
	  else
	    $r = $o;
	} else 
	  $r = $o;");
		return r;
	}	

	static public var skip_constructor = false;
}