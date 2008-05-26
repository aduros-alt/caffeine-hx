/*
 * Copyright (c) 2008, The Caffeine-hx project contributors
 * Original author : Ritchie Turner, Copyright (c) 2007 ritchie@blackdog-haxe.com
 * Contributors: Russell Weir
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
/*
* The Software shall be used for Good, not Evil.
*
* Updated for haxe by ritchie turner
* Copyright (c) 2007 ritchie@blackdog-haxe.com
*
* There are control character things I didn't bother with.
*/


package formats.json;

/**
	JSON format encoding and decoding.
**/
class JSON {
	/**
		Encode an object to JSON
	**/
	public static function encode(v:Dynamic) : String {
		var e = new Encode(v);
		return e.getString();
	}

	/**
		Decode a string to an Object
	**/
	public static function decode(v:String) : Dynamic	{
		var d = new Decode(v);
		return d.getObject();
	}
}

private class Encode {

	var jsonString:String;

	public function new(value:Dynamic ) {
		jsonString = convertToString( value );
	}

	public function getString():String {
		return jsonString;
	}

	function convertToString(value:Dynamic):String {

		if (Std.is(value,String)) {
			return escapeString(Std.string(value));

		} else if (Std.is(value,Float)) {
			return Math.isFinite(value) ? Std.string(value) : "null";

		} else if (Std.is(value,Bool)) {
			return value ? "true" : "false";

		} else if (Std.is(value,Array)) {
			return arrayToString(value);

		}  else if (Std.is(value,List)) {
	trace("process a list");
			return listToString(value);
		} else if (value != null && Reflect.isObject(value)) {
			return objectToString( value );

		}

		return "null";
	}

	function escapeString( str:String ):String {
		var s = new StringBuf();
		var ch:String;
		var i = 0;
		while ((ch = str.charAt( i )) != ""){
			switch ( ch ) {
				case '"':	// quotation mark
					s.add('\\"');
				case '\\':	// reverse solidus
					s.add("\\\\");
				case '\\b':	// backspace
					s.add("\\b");
				case '\\f':	// form feed
					s.add("\\f");
				case '\\n':	// newline
					s.add("\\n");
				case '\\r':	// carriage return
					s.add("\\r");
				case '\\t':	// horizontal tab
					s.add("\\t");
				default: // skipped encoding control chars here
					s.add(ch);
			}
			i++;
		}	// end for loop

		return "\"" + s.toString() + "\"";
	}

	function arrayToString( a:Array<Dynamic> ):String {

		var s = new StringBuf();

		var i:Int= 0;

		while(i < a.length) {

			s.add(convertToString( a[i] ));
			s.add(",");
			i++;
		}
		return "[" + s.toString().substr(0,-1) + "]";
	}

	function objectToString( o:Dynamic):String {
		var s = new StringBuf();
		if ( Reflect.isObject(o)) {
			if (Reflect.hasField(o,"__cache__")) {
				// TODO, probably needs revisiting
				// hack for spod object ....
				o = Reflect.field(o,"__cache__");
			}
			var value:Dynamic;
			var sortedFields = Reflect.fields(o);
			sortedFields.sort(function(k1, k2) { if (k1 == k2) return 0; if (k1 < k2) return -1; return 1;});
			for (key in sortedFields) {
				value = Reflect.field(o,key);

				if (Reflect.isFunction(value))
					continue;

				s.add(escapeString( key ) + ":" + convertToString( value ));
				s.add(",");
			}
		}  else {

			for(v in Reflect.fields(o)) {
				s.add(escapeString(v) + ":" + convertToString( Reflect.field(o,v) ));
				s.add(",");
			}
			var sortedFields = Reflect.fields(o);
			sortedFields.sort(function(k1, k2) { if (k1 == k2) return 0; if (k1 < k2) return -1; return 1;});

			for(v in sortedFields) {
				s.add(escapeString(v) + ":" + convertToString( Reflect.field(o,v)));
				s.add(",");
			}
		}
		return "{" + s.toString().substr(0,-1) + "}";
	}

	function listToString( l: List<Dynamic>) :  String {
		var s:StringBuf = new StringBuf();
		var i:Int= 0;

		for(v in l) {
		s.add(convertToString( v ));
		s.add(",");
		}

		return "[" + s.toString().substr(0,-1) + "]";
	}
}

private class Decode {

	var at:Int;
	var ch:String;
	var text:String ;

	var parsedObj:Dynamic;

	public function new(t:String) {
		parsedObj = parse(t);
	}

	public function getObject():Dynamic {
		return parsedObj;
	}

	public function parse(text:String):Dynamic {
		if(text == null || text == "")
			return {};
		try {
			at = 0 ;
			ch = '';
			this.text = text ;
			return value();
		}
		catch(e : JsonException) {
			throw(e);
		}
		catch (e : Dynamic) {
			throw(new JsonException("unhandled error"));
		}
		return {};
	}

	function error(m):Void {
		throw new JsonException(m, at-1, text);
	}

	function next() {
		ch = text.charAt(at);
		at += 1;
		if (ch == '') return ch = '0';
		return ch;
	}

	function white() {
		while (Std.bool(ch)) {
			if (ch <= ' ') {
				next();
			} else if (ch == '/') {
				switch (next()) {
					case '/':
						while (Std.bool(next()) && ch != '\n' && ch != '\r') {}
						break;
					case '*':
						next();
						while (true) {
							if (Std.bool(ch)) {
								if (ch == '*') {
									if (next() == '/') {
										next();
										break;
									}
								} else {
									next();
								}
							} else {
								error("Unterminated comment");
							}
						}
						break;
					default:
						error("Syntax error");
				}
			} else {
				break;
			}
		}
	}

	function str():String {
		var i, s = '', t, u;
		var outer:Bool = false;

		if (ch == '"') {
			while (Std.bool(next())) {
				if (ch == '"') {
					next();
					return s;
				} else if (ch == '\\') {
					switch (next()) {


				/*	case 'b':
						s += "\\b";
						break;

					case 'f':
						s += '\f';
						break;
*/
					case 'n':
						s += '\n';
					case 'r':
						s += '\r';
					case 't':
						s += '\t';
					case 'u':			// unicode
						u = 0;
						for (i in 0...4) {
							t = Std.parseInt(next());
							if (!Math.isFinite(t)) {
								outer = true;
								break;
							}
							u = u * 16 + t;
						}
						if(outer) {
							outer = false;
							break;
						}
						s += String.fromCharCode(u);
					default:
						s += ch;
					}
				} else {
					s += ch;
				}
			}
		} else {
			error("ok this should be a quote");
		}
		error("Bad string");
		return s;
	}

	function arr():Array<Dynamic> {
		var a = [];

		if (ch == '[') {
			next();
			white();
			if (ch == ']') {
				next();
				return a;
			}
			while (Std.bool(ch)) {
				var v:Dynamic;
				v = value();
				a.push(v);
				white();
				if (ch == ']') {
					next();
					return a;
				} else if (ch != ',') {
					break;
				}
				next();
				white();
			}
		}
		error("Bad array");
		return []; // never get here
	}

	function obj():Dynamic {
		var k;
		var o = Reflect.empty();

		if (ch == '{') {
			next();
			white();
			if (ch == '}') {
				next();
				return o;
			}
			while (Std.bool(ch)) {
				k = str();
				white();
				if (ch != ':') {
					break;
				}
				next();
				var v:Dynamic;
				v = value();
				Reflect.setField(o,k,v);

				white();
				if (ch == '}') {
					next();
					return o;
				} else if (ch != ',') {
					break;
				}
				next();
				white();
			}
		}
		error("Bad object");
		return o;
	}

	function num():Float {
		var n = '';
		var v:Float;

		if (ch == '-') {
			n = '-';
			next();
		}
		while (ch >= '0' && ch <= '9') {
			n += ch;
			next();
		}
		if (ch == '.') {
			n += '.';
			next();
			while (ch >= '0' && ch <= '9') {
				n += ch;
				next();
			}
		}
		if (ch == 'e' || ch == 'E') {
			n += ch;
			next();
			if (ch == '-' || ch == '+') {
				n += ch;
				next();
			}
			while (ch >= '0' && ch <= '9') {
				n += ch;
				next();
			}
		}
		v = Std.parseFloat(n);
		if (!Math.isFinite(v)) {
			error("Bad number");
		}
		return v;
	}

	function word():Null<Bool> {
		switch (ch) {
			case 't':
				if (next() == 'r' && next() == 'u' &&
						next() == 'e') {
					next();
					return true;
				}
			case 'f':
				if (next() == 'a' && next() == 'l' &&
						next() == 's' && next() == 'e') {
					next();
					return false;
				}
			case 'n':
				if (next() == 'u' && next() == 'l' &&
						next() == 'l') {
					next();
					return null;
				}
		}
		error("Syntax error");
		return false; // never get here
	}

	function value():Dynamic {
		white();
		var v:Dynamic;
		switch (ch) {
			case '{':
				v = obj() ;
			case '[':
				v = arr();
			case '"':
				v = str();
			case '-':
				v = num();
			default:
				if (ch >= '0' && ch <= '9'){
					v = num();
				}else {
					v = word() ;
				}
		}
		return v;
	}

}

