/*
 * Copyright (c) 2008, The Caffeine-hx project contributors
 * Original author : Russell Weir
 * Contributors:
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
 * THIS SOFTWARE IS PROVIDED BY THE CAFFEINE-HX PROJECT CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE CAFFEINE-HX PROJECT CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

package lua;

class Lib {

	/**
		Load and return a Lua library from a lua file.
	**/
	public static function load( lib : String, prim : String, ?nargs : Int ) : Dynamic {
		var l = untyped __lua__("require(lib)");
		var desc = prim + "@" + lib;
		if(untyped l[prim] == null) throw "method "+desc+" not found";
		return staticClose(l, prim);
	}

	/**
		Retrieve a method from a lua object table.
	**/
	public static function getFunction( o : Dynamic, prim : String) : Dynamic {
		if(untyped o[prim] == null) throw "object does not have function "+prim;
		return staticClose(o, prim);
	}

	/**
		Closure to remove first variable from function call
	**/
	public static function staticClose(o:Dynamic, fname:String) : Dynamic {
		return untyped __lua__("function(...) return o[fname](select(2,...)) end");
	}
	/**
		Print the specified value on the default output.
	**/
	public static function print( v : Dynamic ) : Void {
		untyped __lua__("if v!= nil then io.stdout:write(v) end");
		//var s = Std.string(v);
		//untyped __lua__("_G.print(v)");
	}

	/**
		Print the specified value on the default output followed by a newline character.
	**/
	public static function println( v : Dynamic ) : Void {
		untyped __lua__("if v ~= nil then io.stdout:write(v..\"\\n\"); io.stdout:flush() end");
	}

	/**
		Rethrow an exception. This is useful when manually filtering an exception in order
		to keep the previous exception stack.
	**/
	public static function rethrow( e : Dynamic ) : Dynamic {
		return untyped __lua__("throw(e)");
	}

	/**
		Returns an object containing all compiled packages and classes.
	**/
	public static function getClasses() : Dynamic {
		return untyped lua.Boot.__classes;
	}

	/**
		Loads an external library
	**/
	public static function loadLib(name:String) : Dynamic {
		var l : Dynamic = untyped __lua__("require(name)");
		return l;
	}

}
