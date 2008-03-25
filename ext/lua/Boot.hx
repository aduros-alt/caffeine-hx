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
package lua;

class Boot {

	private static function __trace(v,i : haxe.PosInfos) {
		untyped {
			var msg = if( i != null ) i.fileName+":"+i.lineNumber+": " else "";
			msg += __tostring__(v);
			untyped __lua__("print(msg)");
		}
	}

	private static function __closure(o,f) {
		untyped {
			var m = o[f];
			if( m == null )
				return null;
			var f = function() { return m.apply(o,arguments); };
// 			f.scope = o;
// 			f.method = m;
			return f;
		}
	}

	public static function __string_rec( v : Dynamic, indent : String ) {
		if(v == null) return "null";
		if(indent == null) indent = "";
		if( indent.length >= 5 ) return "<...>"; // deep recursion check
		var cname = untyped __global__["Haxe.getQualifiedClassName"](v);
		switch( cname ) {
		case "Object":
			if(untyped v.__enum__ != null) {
				var k : Array<String> = untyped __keys__(v);
				if(k.length == 2) return k[0];
				var s = k[0]+"(";
				indent += "\t";
				for(i in 2...k.length) {
					if( i != 2)
						s = s + ",";
					s = s + __string_rec(v[i-1], indent);
				}
				return s + ")";
			}
			var k : Array<String> = untyped __keys__(v);
			var s = "{";
			var first = true;
			for( i in 0...k.length ) {
				var key = k[i];
				if( first )
					first = false;
				else
					s += ",";
				s += " "+key+" : "+__string_rec(v[untyped key-1],indent);
			}
			if( !first )
				s += " ";
			s += "}";
			return s;
		case "Array":
			var s = "[";
			var i;
			var first = true;
			for( i in 0...v.length ) {
				if( first )
					first = false;
				else
					s += ",";
				s += __string_rec(v[i],indent);
			}
			return s+"]";
		case "String":
			return v;
		default:
			switch( untyped __typeof__(v) ) {
			case "function": return "<function>";
			}
		}
		return untyped __tostring__(v);
	}

	private static function __interfLoop(cc : Dynamic,cl : Dynamic) {
		if( cc == null )
			return false;
		if( cc == cl )
			return true;
		var intf : Dynamic = cc.__interfaces__;
		if( intf != null )
			for( i in 0...intf.length ) {
				var i : Dynamic = intf[i];
				if( i == cl || __interfLoop(i,cl) )
					return true;
			}
		return __interfLoop(cc.__super__,cl);
	}

	private static function __instanceof(o : Dynamic,cl) {
		untyped {
			if(cl == null || o == null) {
				return false;
			}
			if(__typeof__(o) == "table" && o.__enum__ != null) {
				return false;
			}
			try {
				if( __lua__("Haxe.instanceof(o, cl)") )
					return true;
				if( __interfLoop(o.__class__,cl) )
					return true;
			} catch( e : Dynamic ) {}
			switch( cl ) {
			case Int:
				return (__typeof__(o) == "number" && Math.ceil(o) === o) && Math.isFinite(o);
			case Float:
				return __typeof__(o) == "number";
			case Bool:
				return (__typeof__(o) == "boolean" && (o === true || o === false));
			case String:
				return __typeof__(o) == "string";
			case Dynamic:
				return true;
			default:
				if( o != null && __typeof__(o) == "table" && o.__enum__ == cl )
					return true;
				return false;
			}
		}
	}

	private static function __init__() {
		untyped {
		/* For some reason, try's following multiple failed if/then/end
			blocks just throw for now apparent reason. The noop() function
			prevents this
		*/
			__mkglobal__("noop","function() end");
			//String = LuaString__;
			__mkglobal__("Int", "{}");
			//Data = LuaDate__;
			__mkglobal__("String", "string");
			__mkglobal__("Dynamic", "{}");
			__mkglobal__("Math", "math");
			__mkglobal__("Float", "{}");
			__mkglobal__("Bool","{}");
			__mkglobal__("Bool['true']", "true");
			__mkglobal__("Bool['false']", "false");
			__mkglobal__("closure", "lua.Boot.__closure");
			__mkglobal__("string.__add", "function(a,b) return(a .. b); end");
		}
	}

}
