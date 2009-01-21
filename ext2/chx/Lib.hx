/*
 * Copyright (c) 2009, The Caffeine-hx project contributors
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

package chx;

/**
	Common library functions.
**/
class Lib {

	/**
		Load a dynamic library.
		@todo Flash: url loader to swf libs
		@todo JS: how would we load dynamic js code?
	**/
	public static function load( lib : String, prim : String, nargs : Int ) : Dynamic {
		#if (neko || cpp)
		return untyped __dollar__loader.loadprim((lib+"@"+prim).__s,nargs);
		#else
		return null;
		#end
	}

	/**
		Print the specified value on the default output.
	**/
	public static function print( v : Dynamic ) : Void {
		#if (neko || cpp)
		untyped __dollar__print(v);
		#elseif php
		untyped __call__("echo", Std.string(v));
		#else
		trace(v);
		#end
	}

	/**
		Print the specified value on the default output followed by a newline character.
	**/
	public static function println( v : Dynamic ) : Void {
		#if (neko || cpp)
		untyped __dollar__print(v,"\n");
		#elseif php
		untyped __call__("echo", Std.string(v) + "\n");
		#else
		trace(v);
		#end
	}
}