/*
 * Copyright (c) 2005, The haXe Project Contributors
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE HAXE PROJECT CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE HAXE PROJECT CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */

/**
	The Std class provides standard methods for manipulating basic types.
**/
class Std {

	/**
		Tells if a value v is of the type t.
	**/
	public static function is( v : Dynamic, t : Dynamic ) : Bool {
		return untyped
		#if flash
		flash.Boot.__instanceof(v,t);
		#elseif neko
		neko.Boot.__instanceof(v,t);
		#elseif js
		js.Boot.__instanceof(v,t);
		#elseif php
		untyped __call__("_hx_instanceof", v,t);
		#else
		false;
		#end
	}

	/**
		Convert any value to a String
	**/
	public static function string( s : Dynamic ) : String {
		return untyped
		#if flash
		flash.Boot.__string_rec(s,"");
		#elseif neko
		new String(__dollar__string(s));
		#elseif js
		js.Boot.__string_rec(s,"");
		#elseif php
		__call__("_hx_string_rec", s, '');
		#else
		"";
		#end
	}

	/**
		Convert a Float to an Int, rounded down.
	**/
	public #if (flash9 || php) inline #end static function int( x : Float ) : Int {
		#if flash9
		return untyped __int__(x);
		#elseif php
		return untyped __php__("intval")(x);
		#else
		if( x < 0 ) return Math.ceil(x);
		return Math.floor(x);
		#end
	}

	/**
		Convert a character code into the corresponding single-char String.
	**/
	public static function chr( x : Int ) : String {
		return String.fromCharCode(x);
	}

	/**
		Return the character code of the first character of the String, or null if the String is empty.
	**/
	public static function ord( x : String ) : Null<Int> {
		#if (flash || php)
		if( x == "" )
			return null;
		else
			return x.charCodeAt(0);
		#elseif neko
		untyped {
			var s = __dollar__ssize(x.__s);
			if( s == 0 )
				return null;
			else
				return __dollar__sget(x.__s,0);
		}
		#elseif js
		if( x == "" )
			return null;
		else
			return x.charCodeAt(0);
		#else true
		return null;
		#end
	}

//BEGINPR/rw01/2008-02-28//Russell Weir/Changed docs and base handling for flash 8,9 and neko. This is to make parseInt actually work the same on all 3 platforms. Removes any potential Octal processing and ensures + and - prefixes work on all platforms.
	/**
		Convert a String to an Int, parsing different possible representations.
		Strings beginning with 0x will be interpreted as hex, those starting with
		0 will be interpreted as Decimal, not Octal (see parseOctal). Returns [null] if could not be parsed.
	**/
	public static function parseInt( x : String ) : Null<Int> {
		// remove leading 0s
		var preParse = function(ns:String) : { neg:Bool, str: String}
		{
			var neg = false;
			var s = StringTools.ltrim(ns);
			if(s.charAt(0) == "-") {
				neg = true;
				s = s.substr(1);
			}
			else if(s.charAt(0) == "+")
				s = s.substr(1);
			if(!StringTools.isNum(s, 0))
				return {str:null, neg:false};

			if(!StringTools.startsWith(s,"0x")) {
				var l = s.length;
				var p : Int = -1;
				var c : Null<Int> = 0;
				while(c == 0 && p < l-1) {
					p++;
					c = StringTools.num(s, p);
					if(c == null)
						return null;
				}
				s = s.substr(p);
			}
			return {str: s, neg:neg };
		}

		untyped {
		#if flash9
		var v = __global__["parseInt"](x);
		if( __global__["isNaN"](v) )
			return null;
		return v;
		#elseif flash
		var res = preParse(x);
		if(res.str == null) return null;
		var v = _global["parseInt"](res.str);
		if( Math.isNaN(v) )
			return null;
		if(res.neg)
			return 0-v;
		return v;
		#elseif neko
		var t = __dollar__typeof(x);
		if( t == __dollar__tint )
			return x;
		if( t == __dollar__tfloat )
			return __dollar__int(x);
		if( t != __dollar__tobject )
			return null;
		var res = preParse(x);
		if(res.str == null) return null;
		var v = __dollar__int(res.str.__s);
		if(res.neg)
			return 0-v;
		return v;
		#elseif js
		var res = preParse(x);
		var v = __js__("parseInt")(res.str);
		if( Math.isNaN(v) )
			return null;
		if(res.neg)
			return 0-v;
		return v;
		#elseif php
		if(!__php__("is_numeric")(x)) return null;
		return x.substr(0, 2).toLowerCase() == "0x" ? __php__("intval(substr($x, 2), 16)") : __php__("intval($x)");
		#else
		return 0;
		#end
		}
	}

	/**
		Convert an Octal String to an Int. Will return null if it can not be parsed.
	**/
	public static function parseOctal( x : String ) : Null<Int> {
		#if flash9
		untyped {
		var v = __global__["parseInt"](x, 8);
		if( __global__["isNaN"](v) )
			return null;
		return v;
		}
		#else
		var neg = false;
		var n : Int = 0;
		var s = StringTools.ltrim(x);
		var accum : Int = 0;
		var l = s.length;

		if(!StringTools.isNum(s,0)) {
			if(s.charAt(0) == "-")
				neg = true;
			else if(s.charAt(0) == "+")
				neg = false;
			else
				return null;
			n ++;
			if(n == s.length || !StringTools.isNum(s,n))
				return null;
		}

		while(n < l) {
			var c : Null<Int> = StringTools.num(s, n);
			if( c == null )
				break;
			if( c > 7 )
				return null;
			accum <<= 3;
			accum += c;
			n++;
		}
		if(neg)
			return 0-accum;
		return accum;
		#end
	}
//ENDPR/rw01///

	/**
		Convert a String to a Float, parsing different possible reprensations.
	**/
	public static function parseFloat( x : String ) : Float {
		#if flash9
		return untyped __global__["parseFloat"](x);
		#elseif flash
		return untyped _global["parseFloat"](x);
		#elseif neko
		untyped {
			var t = __dollar__typeof(x);
			if( t == __dollar__tint )
				return x * 1.0;
			if( t == __dollar__tfloat )
				return x;
			if( t != __dollar__tobject )
				return Math.NaN;
			return __dollar__float(x.__s);
		}
		#elseif js
		return untyped __js__("parseFloat")(x);
		#elseif php
		return untyped __php__("is_numeric($x) ? floatval($x) : acos(1.01)");
		#else
		return untyped 0;
		#end
	}

	/**
		Return a random integer between 0 included and x excluded.
	**/
	public static function random( x : Int ) : Int {
		return untyped
		#if flash9
		Math.floor(Math.random()*x);
		#elseif flash
		__random__(x);
		#elseif neko
		Math._rand_int(Math.__rnd,x);
		#elseif js
		Math.floor(Math.random()*x);
		#elseif php
		__call__("rand", 0, x-1);
		#else
		0;
		#end
	}

	/**
		Initialization the things needed for reflection
	**/
	static function __init__() untyped {
		#if js
			String.prototype.__class__ = String;
			String.__name__ = ["String"];
			Array.prototype.__class__ = Array;
			Array.__name__ = ["Array"];
			Int = { __name__ : ["Int"] };
			Dynamic = { __name__ : ["Dynamic"] };
			Float = __js__("Number");
			Float.__name__ = ["Float"];
			Bool = { __ename__ : ["Bool"] };
			Class = { __name__ : ["Class"] };
			Enum = {};
			Void = { __ename__ : ["Void"] };
		#elseif as3gen
			null;
		#elseif flash9
			Bool = __global__["Boolean"];
			Int = __global__["int"];
			Float = __global__["Number"];
		#elseif flash
			var g : Dynamic = _global;
			g["Int"] = { __name__ : ["Int"] };
			g["Bool"] = { __ename__ : ["Bool"] };
			g.Dynamic = { __name__ : [__unprotect__("Dynamic")] };
			g.Class = { __name__ : [__unprotect__("Class")] };
			g.Enum = {};
			g.Void = { __ename__ : [__unprotect__("Void")] };
			g["Float"] = _global["Number"];
			g["Float"][__unprotect__("__name__")] = ["Float"];
			Array.prototype[__unprotect__("__class__")] = Array;
			Array[__unprotect__("__name__")] = ["Array"];
			String.prototype[__unprotect__("__class__")] = String;
			String[__unprotect__("__name__")] = ["String"];
			g["ASSetPropFlags"](Array.prototype,null,7);
		#elseif neko
			Int = { __name__ : ["Int"] };
			Float = { __name__ : ["Float"] };
			Bool = { __ename__ : ["Bool"] };
			Dynamic = { __name__ : ["Dynamic"] };
			Class = { __name__ : ["Class"] };
			Enum = {};
			Void = { __ename__ : ["Void"] };
			var cl = neko.Boot.__classes;
			cl.String = String;
			cl.Array = Array;
			cl.Int = Int;
			cl.Float = Float;
			cl.Bool = Bool;
			cl.Dynamic = Dynamic;
			cl.Class = Class;
			cl.Enum = Enum;
			cl.Void = Void;
		#end
	}

}
