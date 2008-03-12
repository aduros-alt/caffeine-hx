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

class LuaString__ implements String {

	static var __name__ = ["String"];
	private static var __split : Dynamic = Lib.load("std","string_split",2);

	public var length(default,null) : Int;

	private function new(s) {
		untyped {
			this.__s = s.__tostring();
			this.length = string.len(s);
		}
	}

	public function charAt(p) {
		untyped {
			try {
				var s = string.char(__s, p);
				return new String(s);
			} catch( e : Dynamic ) {
				return "";
			}
		}
	}

	// done
	public function charCodeAt(p) {
		untyped {
			return string.byte(this.__s, p+1);
		}
	}

	public function indexOf( str : String, ?pos ) {
		if(pos == null)
			pos = 0;
		if(pos > 0)
			pos += 1;
		untyped {
			var i = string.find(this.__s, str.__s, pos, true);
			if(i == null)
				return -1;
			return i;
		}
	}

	public function lastIndexOf( str : String, ?pos ) {
		untyped {
			var last = 0;
			if( pos == null )
				pos = string.len(this.__s) + 1;
			while( true ) {
				var p = try string.find(this.__s,str.__s,last+1,true) catch( e : Dynamic ) null;
				if( p == null || p > pos )
					return last - 1;
				last = p;
			}
			return null;
		}
	}

	public function split( delim : String ) {
		untyped {
			var a = new Array<String>();
			var last = this.indexOf(delim);
			if(last == null) {
				a.push(new String(this.__s));
				return a;
			}

			var pos = 1;
			while(true) {
				var first, last = string.find(this.__s,str.__s,pos,true);
				if(first > 0) {
					a.push(new String(string.sub(this.__s,pos,first-1)));
					pos = last + 1;
				}
				else {
					a.push(string.sub(this.__s,pos));
				}
			}
			return a;
		}
	}

	public function substr( pos, ?len ) {
		if( len == 0 ) return new String("");
		var sl = length;
		if( len == null ) len = sl;

		if( pos == null ) pos = 0;
		if( pos != 0 && len < 0 ){
			return new String("");
		}

		if( pos < 0 ){
			pos = sl + pos;
			if( pos < 0 ) pos = 0;
		}
		else if( len < 0 ){
			len = sl + len - pos;
		}

		if( pos + len > sl ){
			len = sl - pos;
		}

		if( pos < 0 || len <= 0 ) return "";
		return untyped new String(string.sub(this.__s,pos+1,pos+len));
	}

	// done
	public function toLowerCase() {
		untyped {
			return new String(string.lower(this.__s));
		}
	}

	// done
	public function toUpperCase() {
		untyped {
			return new String(string.upper(this.__s));
		}
	}

	public function toString() : String {
		return this;
	}

	static function fromCharCode( c : Int ) : String {
		var s = untyped string.char(c);
		return new String(s);
	}

	/* LUA INTERNALS */

	private function __add(s) {
		return new String(untyped  __lua__("self.__s .. s.__s"));
	}



}
