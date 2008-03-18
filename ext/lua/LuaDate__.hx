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

class LuaDate__
{
	private var __t : Dynamic;

	public function new(year : Int, month : Int, day : Int, hour : Int, min : Int, sec : Int ) {
		__t = Reflect.empty();
		untyped __t['year'] = year;
		untyped __t['year'] = year;
		untyped	__t['month'] = month + 1;
		untyped	__t['day'] = day;
		untyped	__t['hour'] = hour;
		untyped	__t['min'] = min;
		untyped	__t['sec'] = sec;
	}

	public function getTime() : Float {
		return 1.0;
	}

	public function getFullYear() : Int {
		return untyped __lua__("__t['year']");
	}

	public function getMonth() : Int {
		return untyped __lua__("__t['month'] - 1");
	}

	public function getDate() : Int {
		return untyped __lua__("__t['day']");
	}

	public function getHours() : Int {
		return untyped __lua__("__t['hour']");
	}

	public function getMinutes() : Int {
		return untyped __lua__("__t['min']");
	}

	public function getSeconds() : Int {
		return untyped __lua__("__t['sec']");
	}

	public function getDay() : Int {
		return untyped __lua__("__t['wday'] - 1");
	}

	public function toString():String {
		return new String(untyped date_format(__t,null));
	}

	private static function now() {
		var n = untyped __lua__("os.time()");
		return create(n);
	}

	private static function fromTime( t : Float ){
		t /= 1000;
		var i1 = untyped __dollar__int((t%65536));
		var i2 = untyped __dollar__int(t/65536);
		var i = untyped int32_add(i1,int32_shl(i2,16));
		return create(i);
	}

	private static function fromString( s : String ) {
		return create(untyped date_new(untyped s));
	}

	private static function create(t) {
		var d = new LuaDate__(2008,1,1,0,0,0);
		d.__t = t;
		return d;
	}
}
