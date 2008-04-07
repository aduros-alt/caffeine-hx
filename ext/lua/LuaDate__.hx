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
	//private var __t : Dynamic;
	private var __ts : Float; // timestamp

	public function new(year : Int, month : Int, day : Int, hour : Int, min : Int, sec : Int ) {
		var ts :Dynamic = Reflect.empty();
		ts.year = year;			// LUA		HAXE
		ts.month = month + 1;	// 1-12		0-11
		ts.day = day;			// 1-31		"
		ts.hour = hour;			// 0-23		"
		ts.min = min;			// 0-59		"
		ts.sec = sec;			// 0-61		"
		// weekday				1-7 Sun		0-6 Sun
		// getTime				milliseconds from epoch
		__ts = adjust(ts);
	}

	public function getTime() : Float {
		return __ts * 1000;
	}

	public function getFullYear() : Int {
		return untyped __lua__("_G.tonumber(os.date('%Y', self.__ts))");
	}

	public function getMonth() : Int {
		return untyped __lua__("_G.tonumber(os.date('%m', self.__ts))-1");
	}

	public function getDate() : Int {
		return untyped __lua__("_G.tonumber(os.date('%d', self.__ts))");
	}

	public function getHours() : Int {
		return untyped __lua__("_G.tonumber(os.date('%H', self.__ts))");
	}

	public function getMinutes() : Int {
		return untyped __lua__("_G.tonumber(os.date('%M', self.__ts))");
	}

	public function getSeconds() : Int {
		return untyped __lua__("_G.tonumber(os.date('%S', self.__ts))");
	}

	public function getDay() : Int {
		return untyped __lua__("_G.tonumber(os.date('%w', self.__ts))");
	}

	public function toString():String {
		return untyped __global__["os.date"]("%Y-%m-%d %H:%M:%S",__ts);
	}

	private static function now() {
		var ts = untyped __lua__("_G.tonumber(os.date('%s'))");
		return create(ts);
	}

	private static function fromTime( t : Float ) {
		return create(t / 1000);
	}

	private static function fromString( s : String ) {
		var nd = new LuaDate__(2008,1,1,0,0,0);
		nd.__ts = untyped parse(s);
		return nd;
	}

	/**
		Returns the seconds
	**/
// 	private static function timestamp(t) : Float {
// 		return untyped __global__["os.time"](t);
// 	}

	private static function adjust(t:Dynamic) : Float {
		//return untyped __lua__("_G.tonumber(os.date('!%s',os.time(t)))");
		return untyped __lua__("_G.tonumber(os.date('%s',os.time(t)))");
	}

	private static function adjustUTC(t:Dynamic) : Float {
		return untyped __lua__("_G.tonumber(os.date('!%s',os.time(t)))");
	}

	private static function toints(t) {
		untyped {
			t.year = _G.tonumber(t.year);
			t.month = _G.tonumber(t.month);
			t.day = _G.tonumber(t.day);
			t.hour = _G.tonumber(t.hour);
			t.min = _G.tonumber(t.min);
			t.sec = _G.tonumber(t.sec);
			t.wday = _G.tonumber(t.wday);
			t.yday = _G.tonumber(t.yday);
			t.idst = _G.tonumber(t.idst);
		}
		return t;
	}

	private static function create(ts) {
		var d = new LuaDate__(2008,1,1,0,0,0);
		d.__ts = ts;
		return d;
	}

	/**
		Return a time table from a string. All returned values are ints
	**/
	private static function parse(s:String) : Float {
		var rv : Float;
		var d = untyped _G.os.date("*t");
		d.hour = 0;
		d.min = 0;
		d.sec = 0;
		switch(s.length) {
		case 8: // HH:MM:SS
			var e = ~/^(\d{2}):(\d{2}):(\d{2})$/;
			if(!e.match(s)) throw "unsupported date format";
			d.hour = untyped __global__["tonumber"](e.matched(1));
			d.min = untyped __global__["tonumber"](e.matched(2));
			d.sec = untyped __global__["tonumber"](e.matched(3));
			rv = adjust(d);
		case 10: // YYYY-MM-DD
			var e = ~/^(\d{4})-([01]\d{1})-([0-3]\d{1})$/;
			if(!e.match(s)) throw "unsupported date format";
			d.year = untyped __global__["tonumber"](e.matched(1));
			d.month = untyped __global__["tonumber"](e.matched(2));
			d.day = untyped __global__["tonumber"](e.matched(3));
			rv = adjustUTC(d);
		case 19: // YYYY-MM-DD HH:MM:SS
			var e = ~/^(\d{4})-([01]\d{1})-([0-3]\d{1}) (\d{2}):(\d{2}):(\d{2})$/;
			if(!e.match(s)) throw "unsupported date format";
			d.year = untyped __global__["tonumber"](e.matched(1));
			d.month = untyped __global__["tonumber"](e.matched(2));
			d.day = untyped __global__["tonumber"](e.matched(3));
			d.hour = untyped __global__["tonumber"](e.matched(4));
			d.min = untyped __global__["tonumber"](e.matched(5));
			d.sec = untyped __global__["tonumber"](e.matched(6));
			rv = adjust(d);
		default:
			throw "unsupported date format";
		}
		return rv;
	}
}
