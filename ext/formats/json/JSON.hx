/*
 * Copyright (c) 2008, The Caffeine-hx project contributors
 * Original author : Ritchie Turner, Copyright (c) 2007 ritchie@blackdog-haxe.com
 * Contributors: Russell Weir, Danny Wilson
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

/*
 * Danny: added control character support based on: http://www.json.org/json2.js
 */

package formats.json;

/**
	JSON format encoding and decoding.
**/
class JSON {
	/**
		Encode an object to JSON
	**/
	public static inline function encode(v:Dynamic) : String {
		return Encode.convertToString(v);
	}

	/**
		Decode a string to an Object
	**/
	public static inline function decode(v:String) : Dynamic {
		return new Decode(v).getObject();
	}
}

private class Encode {

	public static function convertToString(value:Dynamic):String {
		if (value == null)					return "null";
		if (Std.is(value,String))			return escapeString(Std.string(value));
		else if (Std.is(value,Float))		return Math.isFinite(value) ? Std.string(value) : "null";
		else if (Std.is(value,Bool))		return value ? "true" : "false";
		else if (Std.is(value,Array))		return arrayToString(value);
		else if (Std.is(value,List))		return listToString(value);
		else if (Reflect.isObject(value))	return objectToString( value );
		
		throw new JsonException("JSON.encode() failed");
	}

	private static function escapeString( str:String ):String {
		var ch:Int;
		var s = new StringBuf();
		var addChar = s.addChar;
		
		for (i in 0 ... str.length){
			#if neko 
				ch = neko.Utf8.charCodeAt(str, i);
			#else true
				ch = str.charCodeAt(i);
			#end
			switch ( ch ) {
				case 34:	s.add('\\"');	// quotation mark	"
				case 92:	s.add("\\\\");	// reverse solidus	\
				case 8:		s.add("\\b");	// backspace		\b
				case 12:	s.add("\\f");	// form feed		\f
				case 10:	s.add("\\n");	// newline			\n
				case 13:	s.add("\\r");	// carriage return	\r
				case 9:		s.add("\\t");	// horizontal tab	\t
				default:
					if( (ch >= 0 && ch <= 31)			/* \x00-\x1f */
					 || (ch >= 127 && ch <= 159)		/* \x7f-\x9f */
					 ||  ch == 173						/* \u00ad */
					 ||  ch >= 1536 && 					// -- Breaks the if sooner :-)
						(    ch <= 1540					/* \u0600-\u0604 */
						||  ch == 1807					/* \u070f */
						||  ch == 6068					/* \u17b4 */
						||  ch == 6069					/* \u17b5 */
						|| (ch >= 8204 && ch <= 8207)	/* \u200c-\u200f */
						|| (ch >= 8232 && ch <= 8239)	/* \u2028-\u202f */
						|| (ch >= 8288 && ch <= 8303)	/* \u2060-\u206f */
						||  ch == 65279					/* \ufeff */
						|| (ch >= 65520 && ch <= 65535)	/* \ufff0-\uffff */
						)
					) s.add("\\u" + StringTools.hex(ch, 4));
					
					addChar(ch);
			}
			
		}

		return "\"" + s.toString() + "\"";
	}

	private static function arrayToString( a:Array<Dynamic> ):String {
		var s = new StringBuf();
		for(i in 0 ... a.length) {
			s.add(convertToString( a[i] ));
			s.add(",");
		}
		return "[" + s.toString().substr(0,-1) + "]";
	}

	private static function objectToString( o:Dynamic):String {
		var s = new StringBuf();
		if ( Reflect.isObject(o)) {
			if (Reflect.hasField(o,"__cache__")) {
				// TODO, probably needs revisiting
				// hack for spod object ....
				o = Reflect.field(o,"__cache__");
			}
			var value:Dynamic;
			var sortedFields = Reflect.fields(o);
			sortedFields.sort(function(k1, k2) { return (k1 == k2) ? 0 : (k1 < k2) ? -1 : 1; });
			for (key in sortedFields) {
				value = Reflect.field(o,key);
				
				if (Reflect.isFunction(value))
					continue;
				
				s.add(escapeString( key ) + ":" + convertToString( value ));
				s.add(",");
			}
		}
		else {
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

	private static function listToString( l: List<Dynamic>) :  String {
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
	/*	catch (e : Dynamic) {
			throw(new JsonException("unhandled error "+Std.string(e)));
		}
	*/	return {};
	}

	function error(m):Void {
		throw new JsonException(m, at-1, text);
	}

	function next() {
		ch = text.charAt(at);
		at += 1;
		if (ch == '') return ch = null;
		return ch;
	}

	function white() {
		while (ch != null) {
			if (ch <= ' ') {
				next();
			} else if (ch == '/') {
				switch (next()) {
					case '/':
						while (next() != null && ch != '\n' && ch != '\r') {}
						break;
					case '*':
						next();
						while (true) {
							if (ch == null)
								error("Unterminated comment");
							
							if (ch == '*' && next() == '/') {
								next();
								break;
							} else {
								next();
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
		var s = new StringBuf(), t:Int, u:Int;
		var outer:Bool = false;

		if (ch != '"') {
			error("This should be a quote");
			return '';
		}
		
		while (next() != null) {
			if (ch == '"') {
				next();
				return s.toString();
			} else if (ch == '\\') {
				switch (next()) {
				case 'n': s.addChar(10);	// += '\n';
				case 'r': s.addChar(13);	// += '\r';
				case 't': s.addChar(9);		// += '\t';
				case 'u': // unicode
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
					#if neko 
						var utf = new neko.Utf8(4); utf.addChar(u);
						s.add(utf.toString());
					#else true
						s.addChar(u);
					#end
				default:
					s.add(ch);
				}
			} else {
				s.add(ch);
			}
		}
		error("Bad string");
		return s.toString();
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
			while (ch != null) {
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
			while (ch != null) {
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
			case '{':	v = obj();
			case '[':	v = arr();
			case '"':	v = str();
			case '-':	v = num();
			default:
				if (ch >= '0' && ch <= '9')
					v = num();
				else
					v = word();
		}
		return v;
	}

}
