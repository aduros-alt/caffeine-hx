package php;

class HArray<T> implements ArrayAccess<T> {
	var length(default,null) : Int;
	private var __a : Dynamic;
	public function new() : Void {
		untyped __php__("$this->__a =  array()");
		length = 0;
	}

	// creates an array from a native PHP array
	static function new1<T>(a : Dynamic) : HArray<T> {
		var n = new HArray();
		untyped __php__("$n->__a = $a");
		untyped n.length = __call__("count", a);
		return n;
	}

	public function concat( a : HArray<T> ) : HArray<T> {
		return new1(untyped __call__("array_merge", __a, a.__a));
	}

	public function join( sep : String ) : String {
		var s : Dynamic;
		untyped __php__("foreach($this->__a as $v) $s.=$v");
		return new String(s);
	}

	public function pop() : Null<T> {
		if(length > 0) length--;
		return untyped __call__("array_pop", __a);
	}

	public function push(x : T) : Int {
		untyped __php__("$this->__a[] = $x");
		return ++length;
	}

	public function reverse() : Void {
		untyped __call__("rsort", __a);
	}

	public function shift() : Null<T> {
		if(length > 0) length--;
		return untyped __call__("array_shift", __a);
	}

	public function slice( pos : Int, ?end : Int ) : HArray<T> {
		var s;
		if(end == null)
			s = untyped __call__("array_slice", __a, pos);
		else
			s = untyped __call__("array_slice", __a, pos, end-pos);
		return new1(s);
	}

	public function sort( f : T -> T -> Int ) : Void {
		var i = 0;
		var l = __a.length;
		while( i < l ) {
			var swap = false;
			var j = 0;
			var max = l - i - 1;
			while( j < max ) {
				if( f(__a[j],__a[j+1]) > 0 ) {
					var tmp = __a[j+1];
					__a[j+1] = __a[j];
					__a[j] = tmp;
					swap = true;
				}
				j += 1;
			}
			if( !swap )
				break;
			i += 1;
		}	
	}

	public function splice( pos : Int, len : Int ) : HArray<T> {
		if(len < 0) len = 0;
		var s = untyped __call__("array_splice", __a, pos, len);
		length = untyped __call__("count", __a);
		return new1(s);
	}

	public function toString() : String {
		return "["+join(", ")+"]";
	}

	public function unshift( x : T ) : Void {
		untyped __call__("array_unshift", __a, x);
		length++;
	}

	public function insert( pos : Int, x : T ) : Void {
		untyped __call__("array_splice", __a, pos, 0, x);
	}

	public function remove( x : T ) : Bool {
		for(i in 0...__a.length)
		if(untyped __a[i] == x) {
			untyped __call__("unset", __a[i]);
			untyped __php__("$this->__a = array_values($this->__a)");
			__a.length--;
			return true;
		}
		return false;
	}

	public function copy() : HArray<T> {
		return new1(__a);
	}
	
	public function offsetExists(offset : Int) : Bool {
		return untyped __call__("array_key_exists", offset, __a);
	}

	public function offsetGet(offset : Int) : Dynamic {
		return untyped __a[offset];
	}

	public function offsetSet(offset : Int, value : Dynamic) : Dynamic {
		var l = length;
		if(l < offset) {
			untyped __call__("array_splice", __a, l, 0, __call__("array_fill", l, offset-l, null)); 
		}
		untyped __a[offset] = value;
		length == untyped __call__("count", __a);
	return value;
	}

	public function offsetUnset(offset : Int) : Void {
		untyped __call__("inset", __a[offset]);
		length--;
	}

	private var i : Int;
	function iterator() : Iterator<Null<T>> {
		i = 0;
		return this;
	}

	public function next() {
		return untyped __a[i++];
	}

	public function hasNext() {
		return untyped i < length;
	}  
}