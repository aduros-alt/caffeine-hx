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

	static var __classes : Dynamic;

	private static function __trace(v,i : haxe.PosInfos) {
		untyped {
			var msg = if( i != null ) i.fileName+":"+i.lineNumber+": " else "";

			__lua__print(msg);
		}
	}

	private static function __clear_trace() {
		untyped {
			var d = document.getElementById("haxe:trace");
			if( d != null )
				d.innerHTML = "";
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
/*
	private static function __string_rec(o,s) {
		untyped {
			if( o == null )
			    return "null";
			if( s.length >= 5 )
				return "<...>"; // too much deep recursion
			var t = __lua__("type(o)");
			if( t == "function" && (o.__name__ != null || o.__ename__ != null) )
				t = "object";
			switch( t ) {
			case "object":
				if( __lua__("o instanceof Array") ) {
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
					var l = o.length;
					var i;
					var str = "[";
					s += "\t";
					for( i in 0...l )
						str += (if (i > 0) "," else "")+__string_rec(o[i],s);
					str += "]";
					return str;
				}
				var tostr;
				try {
					tostr = untyped o.toString;
				} catch( e : Dynamic ) {
					// strange error on IE
					return "???";
				}
				if( tostr != null && tostr != __lua__("Object.toString") ) {
					var s2 = o.toString();
					if( s2 != "[object Object]")
						return s2;
				}
				var k : String;
				var str = "{\n";
				s += "\t";
				var hasp = (o.hasOwnProperty != null);
				__lua__("for( var k in o ) { ");
					if( hasp && !o.hasOwnProperty(k) )
						__lua__("continue");
					if( k == "prototype" || k == "__class__" || k == "__super__" || k == "__interfaces__" )
						__lua__("continue");
					if( str.length != 2 )
						str += ", \n";
					str += s + k + " : "+__string_rec(o[k],s);
				__lua__("}");
				s = s.substring(1);
				str += "\n" + s + "}";
				return str;
			case "function":
				return "<function>";
			case "string":
				return o;
			default:
				return String(o);
			}
		}
	}
*/

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
			try {
				if( __lua__("instanceof(o, cl)") ) {
					if( cl == Array )
						return (o.__enum__ == null);
					return true;
				}
				if( __interfLoop(o.__class__,cl) )
					return true;
			} catch( e : Dynamic ) {
				if( cl == null )
					return false;
			}
			switch( cl ) {
			case Int:
				return (Math.ceil(o) === o) && isFinite(o);
			case Float:
				return __lua__("type(o)") == "number";
			case Bool:
				return (o === true || o === false);
			case String:
				return __lua__("type(o)") == "string";
			case Dynamic:
				return true;
			default:
				if( o != null && o.__enum__ == cl )
					return true;
				return false;
			}
		}
	}

	private static function __init() {
		untyped {
			__lua__("string__add = function(r,w) return(r..w) end");
			__lua__("smt = getmetatable(\"\"); smt.__add = string__add");
			__lua__("smt.length = string.len");
			__lua__("
			smt['haxe_charAt'] = function(s,p)
				return string.char(s,p+1);
			end
			smt['haxe_charCodeAt'] = function(s,p)
				return string.byte(s,p+1);
			end
			smt['haxe_indexOf'] = function(s,str,pos)
				if(pos == nil) then pos = 0; end;
				pos = pos + 1;
				local i = string.find(s, str, pos, true);
				if(i==nil) then do return -1 end end
				return i - 1;
			end
			smt['haxe_lastIndexOf'] = function(s,str,pos)
				local last = 0;
				local r = -1;
				if(pos == nil) then pos = string.len(s) + 1	end
				while(true) do
					try
						r = string.find(s,str,last+1,true);
						if(r== nil or r > pos) then
							do return last end
						end
						last = r;
					catch err do
						do
							return last-1;
						end
					end
				end
				return r-1;
			end
			smt['haxe_split'] = function(s,delim)
				local a = Array:new()
				local last = s.indexOf(delim,nil)
				if(last == nil) then
					do
						a:push(s);
						return a;
					end
				end
				local pos = 1;
				while(true) do
					do
						local first,last = string.find(s,delim,pos,true);
						if(first) then
							a:push(string.sub(s,pos,first - 1));
							pos = last + 1;
						else
							a:push(string.sub(s,pos));
							break;
						end
					end
				end
				return a;
			end

			smt['haxe_substr'] = function(s,pos,len)
				if(len == nil) then len = string.len(s) end;
				if(len == 0) then return \"\"; end;
				if(pos == nil) then pos = 0; end;
				if(pos >= 0) then pos = pos + 1; end;
				return string.sub(s,pos,len);
			end

			smt['haxe_toLowerCase'] = function(s)
				return string.lower(s);
			end

			smt['haxe_toUpperCase'] = function(s)
				return string.upper(s)
			end

			smt['haxe_toString'] = function(s)
				return s
			end

			smt['fromCharCode'] = function(c)
				return string.char(c);
			end


			getmetatable (\"\").__index =
			function (s, n)
			if type (n) == \"number\" then
				return sub (s, n, n)
			elseif type (oldmeta) == \"function\" then
				return smt (s, n)
			else
				return smt[n]
			end
			end

			");
			lua.Boot.__classes = __lua__("{}");
			String = LuaString__;
			lua.Boot.__classes.String = String;
			Array = LuaArray__;
			lua.Boot.__classes.Array = Array;
			Int = __lua__("{}");
			Data = LuaDate__;
			Dynamic = __lua__("{}");
			Math = __lua__("math");
			Float = __lua__("{}");
			Bool = __lua__("{}");
			Bool["true"] = true;
			Bool["false"] = false;
			__lua__("closure = lua.Boot.__closure");
			__lua__("string.__add = function(a,b) return(a .. b); end");
			//__lua__("do local smt = getmetatable(\"\"); smt.__add = string__add; end;");
		}
	}

}
