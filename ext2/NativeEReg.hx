
typedef MatchResult = {
	var position : Int;
	var matchCount : Int;
	var length : Int;
	var final : Bool;
	var sideB : Bool;
	var fatal : Bool;
};

enum ERegMatch {
	Beginning;
	MatchExact(s : String);
	MatchCharCode(c : Int);
	MatchAny;
	MatchAnyOf(ch : IntHash<Bool>);
	MatchNoneOf(ch : IntHash<Bool>);
	MatchWordBoundary;
	NotMatchWordBoundary;
	Or(a : Array<ERegMatch>, b : Array<ERegMatch>);
	Repeat(r : ERegMatch, min:Int, max:Null<Int>, notGreedy: Bool, possessive:Bool);
	Capture(r : NativeEReg);
	RangeMarker;
	End;
	Frame(srcpos : Int, r : ERegMatch, info : Dynamic);
}

/*
not done
    \A	Match only at beginning of string
    \Z	Match only at end of string, or before newline at the end
    \z	Match only at end of string
    \G	Match only at pos() (e.g. at the end-of-match position
        of prior m//g)
*/

class NativeEReg {
	inline static var NULL_MATCH	: Int = -1;
	static var alpha = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
	static var numeric = "0123456789";
	static var verticalTab = String.fromCharCode(0x0B);
	static var formFeed = String.fromCharCode(0x0C);


	var pattern : String;
	var options : String;
	var ignoreCase : Bool;
	var multiline : Bool;
	var global : Bool;

	///////////// for Grouping ///////////////////////
	var root(default, null)		: NativeEReg;
	var parent(default, null)	: NativeEReg;
	var _groupCount 			: Int; // a 'static' accessed by sub groups

	///////////// parser vars ////////////////////////
	var groupNumber : Int; // (()) () group number
	var rules : Array<ERegMatch>;
	var parsedPattern : String; // the piece that was extracted from pattern

	///////////// populate for match() ///////////////
	var inputOrig : String; // the input string to match
	var input : String; // modified input for case sensitivity
	var index : Int; // position of match
	var matches : Array<String>;
	var lastIndex: Int;
	var leftContext : String;
	var rightContext : String;

	public function new(pattern : String, opt : String, ?parent : NativeEReg = null) {
		this.pattern = pattern;
		this.options = opt.toLowerCase();
		this.ignoreCase = (options.indexOf("i") >= 0);
		this.multiline = (options.indexOf("m") >= 0);
		this.global = (options.indexOf("g") >= 0);
		this.lastIndex = 0;
		if(parent == null) {
			_groupCount = 0;
			this.root = this;
			this.parent = this;
			this.groupNumber = 0;
		} else {
// 			As NativeEReg instances are created for each group, the
// 			'global static' _groupCount is incremented and the new
// 			instance gets assigned the groupNumber.
			this.root = parent.root;
			this.parent = parent;
			this.groupNumber = ++this.root._groupCount;
		}
		this.rules = new Array();

		var rv = parse(pattern, 0, 0);
		for(r in rv.rules)
			this.rules.push(r);
		this.parsedPattern = pattern.substr(0, rv.bytes);
		if(this.root == this) {
			if(pattern.length != rv.bytes)
				throw "NativeEReg::new : Unexpected characters at position " + rv.bytes;
			trace ("Top level consumed pattern " + parsedPattern);
		} else {
			trace ("Child consumed pattern " + parsedPattern);
		}
	}


	var orChange : Bool;
	var frameStack : Array<ERegMatch>;

	public function match( s : String ) : Bool
	{
		if(s == null)
			return false;
		var me = this;
		this.inputOrig = s;
		this.input = ignoreCase ? s.toLowerCase() : s;

// 		var matchStart = false;
// 		var matchEnd = false;
trace(here.methodName + " lastIndex:" + lastIndex + " global: " + global);
		var pos = (global ? 0 : lastIndex);
		var startPos = pos;
trace(here.methodName + " pos: " + pos);

		this.index = -1;
		frameStack = new Array();
		var i = - 1;

		var updatePosition = function(mr : MatchResult) {
			if(me.index < 0)
				me.index = mr.position;
			pos = mr.position + mr.length;
		}
		var reset = function() {
			me.matches = new Array();
			me.index = -1;
			me.frameStack = new Array();
			i = -1;
		}

		reset();
		while(++i < rules.length && pos < input.length) {
			#if DEBUG_MATCH
				trace("Current index: " + this.index);
				trace("Current pos: "+pos);
			#end
			var mr = run(pos, [rules[i]]);
			#if DEBUG_MATCH
				trace("Rule : " + rules[i]);
				trace("Result: " + mr);
			#end

			if(isValidMatch(pos, mr)) {
				updatePosition(mr);
				continue;
			}
			var found = false;
			while(frameStack.length > 0) {
				var rule = frameStack.pop();
				switch(rule) {
				case Frame(srcpos, rule, _):
					pos = srcpos;
					mr = run(pos, [rule]);
					if(isValidMatch(pos, mr)) {
						updatePosition(mr);
						found = true;
						break;
					}
				default:
					throw "invalid item in frameStack";
				}
			}
			if(found)
				continue;
			pos++;
			reset();
		}

		if(this.index < 0) {
			lastIndex = 0;
			matches = new Array();
			root.matches[this.groupNumber] = null;
			return false;
		}
		lastIndex = pos;
		leftContext = inputOrig.substr(0, index);
		rightContext = inputOrig.substr(pos);
		root.matches[groupNumber] = inputOrig.substr(index, pos - index);
		return true;
	}

	function isValidMatch(pos : Int, mr : MatchResult) {
		if(mr.matchCount == 0)
			return false;
		if(pos == mr.position)
			return true;
		if(global) {
			if(this.index < 0)
				return true;
		}
		return false;
	}

	function run(pos:Int, rules:Array<ERegMatch>, ?min : Int = 1, ?max:Null<Int> = null) : MatchResult {
		trace(here.methodName + " " + rules + " group: "+groupNumber+" pos: " + pos);

		// only here and set as a Null<Int> in case there may be a reason
		// to have another default. todo: remove?
		if(max == null)
			max = 1;

		var startPos = pos;
		var count = 0;
		var fatal = false;

		var MATCH = function(count : Int) {
			var len : Int = (count == NULL_MATCH ? 0 : pos - startPos);
			return {
				position	: startPos,
				matchCount	: count,
				length		: len,
				final		: true,
				sideB		: false,
				fatal		: fatal,
			}
		}
		var NOMATCH = function() {
			var m = MATCH(0);
			m.length = 0;
			return m;
		}

		for(rule in rules) {
			switch(rule) {
			case Beginning:
				if(pos == 0)
					return MATCH(NULL_MATCH);
				return NOMATCH();
			case MatchExact(s):
				if(s.length == 0)
					return MATCH(NULL_MATCH);
				if(max == null)
					max = 1;
				while(pos + s.length < input.length && count <= max) {
					if(input.substr(pos, s.length) != s)
						break;
					count++;
					pos += s.length;
				}
				return MATCH(count * s.length);
			case MatchCharCode(cc):
				while(pos < input.length && count <= max) {
					if(input.charCodeAt(pos) != cc)
						break;
					count++;
					pos++;
				}
				return MATCH(count);
			case MatchAny:
				while(pos < input.length && count <= max) {
					if(input.substr(pos, 1) == "\n")
						break;
					count++;
					pos++;
				}
				return MATCH(count);
			case MatchAnyOf(ch):
				while(pos < input.length && count <= max) {
					var cc = input.charCodeAt(pos);
					if(!ch.exists(cc))
						break;
					count++;
					pos++;
				}
				return MATCH(count);
			case MatchNoneOf(ch):
				while(pos < input.length && count <= max) {
					var cc = input.charCodeAt(pos);
					if(ch.exists(cc))
						break;
					count++;
					pos++;
				}
				return MATCH(count);
			case MatchWordBoundary:
				throw "Not complete";
			case NotMatchWordBoundary:
				throw "Not complete";
			case Or(a, b):
	/*
				final = false;
				var lr : MatchResult = null;
				if(lastResult.position < 0) {
					lr = run(a);
					lr.sideB = false;
					if(lr.matchCount != 0) {
						count = lr.matchCount;
						copyResult(lr, lastResult);
						return rv();
					}
					pos = startPos;
				} else {
					lr = cloneResult(lastResult);
				}
				count = lr.matchCount;
				var weChanged = false;
				while(orChange) {
					var newResult : MatchResult = null;
					if(!lr.sideB) {
						var cmp = 0;
						while(cmp == 0 && !lr.final) {
							newResult = run(a);
							newResult.sideB = false;
							cmp = compareResult(newResult, lr);
							if(cmp != 0) {
								orChange = false;
								copyResult(newResult, lastResult);
								lastResult.sideB = false;
								return(lastResult);
							}
						}
						// we have the same result as last time, try sideB
						newResult = run(b);
						newResult.sideB = true;
						weChanged = true;
					} else {
					}
				}
				if(lr.matchCount == 0)
					lr = run(b);
				copyResult(lr, lastResult);
	*/
			case Repeat(e, min, max, notGreedy, possessive):
				var res = run(pos, [e], min, max);
				if(res.matchCount != 0) {
					return res;
				}
				if(min == 0)
					return MATCH(-1);
				return NOMATCH();
			case Capture(er):
				#if DEBUG_MATCH
					trace("RUNNING CAPTURE at pos: " + pos);
				#end
				er.lastIndex = pos - 1;
				if(er.match(inputOrig)) {
					var len = matches[er.groupNumber].length;
					var mr : MatchResult = {
						position : er.index,
						matchCount : len,
						length : len,
						final : true,
						sideB : false,
						fatal : false,
					}
					if(isValidMatch(pos,mr)) {
						startPos = er.index;
						pos = startPos + len;
						#if DEBUG_MATCH
							trace("CAPTURE MATCHED new pos:" + pos);
						#end
						return MATCH(len);
					}
				}
				#if DEBUG_MATCH
					trace("CAPTURE FAILED");
				#end
				return NOMATCH();
			case RangeMarker: throw "Internal error";
			case End:
				if(pos == input.length - 1)
					return MATCH(NULL_MATCH);
				if(count == 0 && multiline) {
					if(input.charAt(pos) == "\r" && input.charAt(pos+1) == "\n") {
						pos += 2;
						return MATCH(2);
					} else if(input.charAt(pos) == "\n") {
						pos ++;
						count++;
						return MATCH(1);
					}
				}
				return NOMATCH();
			case Frame(srcpos, r, info):
				if(pos != srcpos)
					throw "invalid use";
				throw "not complete";
			}
		}
		throw "Control should not arrive here.";
		return null;
	}

	/**
		Returns a matched group or throw an expection if there
		is no such group. If [n = 0], the whole matched substring
		is returned.
	**/
	public function matched( n : Int) : String {
		if(n >= matches.length || (n == 0 && matches[0].length == 0))
			throw "EReg::matched";
		return matches[n];
	}

	/**
		Returns the part of the string that was as the left of
		of the matched substring.
	**/
	public function matchedLeft() : String {
		return leftContext;
	}

	/**
		Returns the part of the string that was at the right of
		of the matched substring.
	**/
	public function matchedRight() : String {
		return rightContext;
	}

	/**
		Returns the position of the matched substring within the
		original matched string.
	**/
	public function matchedPos() : { pos : Int, len : Int } {
		return {
			pos : 0,
			len : 0,
		};
	}

	function parse(inPattern: String, pos : Int, depth: Int, ? inClass : Bool) : { bytes: Int, rules : Array<ERegMatch> } {
		var startPos = pos;
		#if DEBUG_PARSER
			trace("START PARSE depth: "+depth+" pos: " + pos);
		#end
		var rules : Array<ERegMatch> = new Array();

		var expectRangeEnd = false;

		var i = pos - 1;
		var patternLen = inPattern.length;
		var atEndMarker : Bool = false;

		var peek = function() : String {
			return inPattern.charAt(i+1);
		}
		var tok = function() : String {
			return inPattern.charAt(++i);
		}
		var msg = function(k : String, s : String, ?p : Null<Int>=null) : String {
			if(p == null)
				p = i;
			return k+" "+s+" at position " + Std.string(p);
		}
		var expected = function(s: String, ?p : Null<Int> = null) : String {
			return msg("Expected", s, p);
		}
		var unexpected = function(s: String, ?p : Null<Int> = null) : String {
			return msg("Unexpected", s, p);
		}
		var invalid = function(s: String, ?p : Null<Int> = null) : String {
			return msg("Invalid", s, p);
		}
		var unhandled = function(s: String, ?p : Null<Int> = null) : String {
			return msg("Unhandled (contact developer):", s, p);
		}
		while(i < patternLen - 1 && !atEndMarker) {
			var curchar = tok();
			#if DEBUG_PARSER
				trace("i: " + i + " curchar: " +curchar + " depth: "+depth);
			#end
			if(curchar == "\\") { // '\'
				curchar = tok();
				// handle octal
				// @todo handle backreference
				if(isNumeric(Std.ord(curchar))) {
					var sub = inPattern.substr(i, 3);
					for(x in 1...3)
						if(!isNumeric(Std.ord(inPattern.charAt(i+x))))
							throw invalid("octal sequence");
					var n = Std.parseOctal(sub);
					if(n == null)
						throw invalid("octal sequence");
					i += 2;
					rules.push(createMatchCharCode(n));
				}
				// handle hex
				else if(curchar == "x") {
					curchar = tok();
					var endPos : Int = i + 2;
					if(curchar == "{") {
						var endPos = inPattern.indexOf("}", ++i);
						if(endPos < 0)
							throw invalid("long hex sequence");
					}
					var hs = inPattern.substr(i, endPos-i);
					for(x in 0...hs.length)
						if(!isHexChar(hs.charCodeAt(x)))
							throw invalid("long hex sequence");
					var n = Std.parseInt("0x" + hs);
					if(n == null)
						throw invalid("long hex sequence");
					i = endPos;
					rules.push(createMatchCharCode(n));
				}
				else { // all other escaped chars
					var rule =
					switch(curchar) {
					case "^": // Match the beginning of the line
						MatchCharCode(0x5E);
					case ".": // Match any character (except newline)
						MatchCharCode(0x2E);
					case "$": // Match the end of the line (or before newline at the end)
						MatchCharCode(0x24);
					case "|": // Alternation
						MatchCharCode(0x7C);
					case "(": // Grouping
						MatchCharCode(0x28);
					case ")": // Grouping End
						MatchCharCode(0x29);
					case "[": // Character class
						MatchCharCode(0x5B);
					case "]": // Character class end
						MatchCharCode(0x5D);
					case "\\":
						MatchCharCode(0x5C);
					//case "0": // \033 octal char (ex ESC) (handled above)
					case "a": // \a alarm (BEL)
						MatchCharCode(0x07);
					case "b": //\b	Match a word boundary, backspace in classes
						if(inClass)
							MatchCharCode(0x08); // // http://perldoc.perl.org/perlre.html
						else
							MatchWordBoundary;
					case "B": // \B Match except at a word boundary
						if(inClass) throw invalid("escape sequence");
						NotMatchWordBoundary;
					case "c":
						//The expression \cx matches the character control-x.
						//subtract 64 from ASCII code value in decimal of
						//the uppercase letter, except DEL (127) which is Ctrl-?
						curchar = tok().toUpperCase();
						var val = Std.ord(curchar);
						if(curchar == "?")
							MatchCharCode(127);
						else if(val >= 0x40 && val < 0x5B)
							MatchCharCode(val - 64);
						else
							throw expected("control character code");
					case "d": // \d [0-9] Match a digit character
						createMatchAnyOf([numeric]);
					case "D": // \D [^\d] Match a non-digit character
						createMatchNoneOf([numeric]);
					case "e": // \e escape (ESC)
						MatchCharCode(0x1B);
					case "f": // \f form feed (FF)
						MatchCharCode(0x0C);
					case "h": // \h Horizontal whitespace
						createMatchAnyOf([" \t"]);
					case "H": // \H Not horizontal whitespace
						createMatchNoneOf([" \t"]);
					case "n": // \n newline (LF, NL)
						MatchCharCode(0x0A);
					case "r": // \r return (CR)
						MatchCharCode(0x0D);
					case "R": // \R [CR,LF,CRLF] Linebreak
						//  (?>\x0D\x0A?|[\x0A-\x0C\x85\x{2028}\x{2029}])
						if(inClass)
							MatchExact("\\R"); // http://perldoc.perl.org/perlre.html
						else
							Or([MatchExact("\r\n")], [createMatchAnyOf(["\r\n"])]);
					case "s": // \s [ \t\r\n\v\f]Match a whitespace character
						createMatchAnyOf([" \t\r\n", verticalTab, formFeed]);
					case "S": // \S [^\s] Match a non-whitespace character
						createMatchNoneOf([" \t\r\n", verticalTab, formFeed]);
					case "t": // \t	tab (HT, TAB)
						MatchCharCode(0x09);
					case "v": // \v Vertical whitespace [\r\n\v]
						createMatchAnyOf(["\r\n", verticalTab]);
					case "V": // \V Not vertical whitespace
						createMatchNoneOf(["\r\n", verticalTab]);
					case "w": // \w [A-Za-z0-9_] Match a "word" character (alphanumeric plus "_")
						createMatchAnyOf([alpha, numeric, "_"]);
					case "W": // \W [^\w] Match a non-"word" character
						createMatchNoneOf([alpha, numeric, "_"]);
					//case "x": Handled above // \x1B hex char (example: ESC)
							// \x{263a} long hex char (example: Unicode SMILEY)
					default:
						/*
							\1       Backreference to a specific group.
									'1' may actually be any positive integer.
							\g1      Backreference to a specific or previous group,
							\g{-1}   number may be negative indicating a previous buffer and may
										optionally be wrapped in curly brackets for safer parsing.
							\g{name} Named backreference
							\k<name> Named backreference
							\K       Keep the stuff left of the \K, don't include it in $&
							\l		lowercase next char (think vi)
							\u		uppercase next char (think vi)
							\L		lowercase till \E (think vi)
							\U		uppercase till \E (think vi)
							\E		end case modification (think vi)
							\Q		quote (disable) pattern metacharacters till \E
							\N{name}	named Unicode character
							\cK		control char          (example: VT)
							\pP	     Match P, named property.  Use \p{Prop} for longer names.
							\PP	     Match non-P
							\X	     Match eXtended Unicode "combining character sequence",
										equivalent to (?:\PM\pM*)
							\C	     Match a single C char (octet) even under Unicode.
									NOTE: breaks up characters into their UTF-8 bytes,
									so you may end up with malformed pieces of UTF-8.
									Unsupported in lookbehind.
						*/
						throw unhandled("escape sequence char " + curchar);
					}
					rules.push(rule);
				}
			} // end escaped portion
			else {
				switch(curchar) {
				case "^": // Match the beginning of the line
					if(inClass) {
						rules.push(MatchCharCode(0x5E));
					} else {
						if(i == 0 && depth == 0) {
							rules.push(Beginning);
							continue;
						}
						throw unexpected("^");
					}
				case ".": // Match any character (except newline)
					rules.push(MatchAny);
				case "$": // Match the end of the line (or before newline at the end)
					if(inClass) {
						rules.push(MatchCharCode(0x24));
					} else {
						if(depth == 0 && this.root == this) {
							atEndMarker = true;
							rules.push(End);
						}
						else
							throw unexpected("$");
					}
				case "|": // Alternation
					if(inClass) {
						rules.push(MatchCharCode(0x7C));
					}
					else {
						if(rules.length == 0)
							throw unexpected("|");
						var orRules = new Array<ERegMatch>();
						while(true && rules.length > 0) {
							var r = rules.pop();
							switch(r) {
							case Beginning, RangeMarker, End:
								throw unexpected("|");
							case Or(a, b):
								if(a == null || b == null)
									throw "Inconsitent Or " + Std.string(r);
								orRules.unshift(r);
							default:
								orRules.unshift(r);
							}
						}
						orRules = compactRules(orRules, ignoreCase);
						var rs = parse(inPattern, ++i, depth + 1);
						i += rs.bytes - 1;
						if(rs.rules.length == 0)
							throw expected("Or condition");
						rules.push(Or(orRules, rs.rules));
					}
				case "(": // Grouping
					if(inClass) {
						rules.push(MatchCharCode(0x28));
					} else {
						if(depth != 0)
							throw unexpected("(");
						#if DEBUG_PARSER
							trace("+++ START GROUP");
						#end
						var er = new NativeEReg(inPattern.substr(++i), this.options, this);
						rules.push(Capture(er));
						#if DEBUG_PARSER
							trace("+++ END GROUP Capture consumed "+ er.parsedPattern);
						#end
						i += er.parsedPattern.length - 1;
					}
				case ")": // Grouping End
					if(inClass) {
						rules.push(MatchCharCode(0x29));
					} else {
						if(depth > 0) {
							i--;
						}
						break;
					}
				case "[": // Character class @todo
					//If you want either "-" or "]" itself to be a member of a class,
					// put it at the start of the list (possibly after a "^"), or
					// escape it with a backslash. "-" is also taken literally when it
					// is at the end of the list, just before the closing "]".
					if(inClass) {
						rules.push(MatchCharCode(0x29));
					} else {
						var not = false;
						if(peek() == "^") {
							not = true;
							i++;
						}
						i++;
						#if DEBUG_PARSER
							trace(">>> START CLASS FROM DEPTH " + depth);
						#end
						var rs = parse(inPattern, i, depth + 1, true);
						#if DEBUG_PARSER
							trace(">>> END CLASS AT DEPTH " + depth + " class consumed " + rs.bytes + " bytes: " + inPattern.substr(i, rs.bytes) );
						#end
						i += rs.bytes - 1;
						rules.push(mergeClassRules(rs.rules, not));
					}
				case "-":
					//@todo:
					//Also, if you try to use the character classes \w , \W , \s, \S , \d ,
					// or \D  as endpoints of a range, the "-" is understood literally.
					if(inClass) {
						expectRangeEnd = true;
						rules.push(RangeMarker);
						continue;
					} else {
						rules.push(MatchCharCode(0x2D));
					}
				case "]": // Character class end
					if(inClass) {
						if(expectRangeEnd)
							throw expected("end of character range");
						if(depth > 0) {
							i--;
							break;
						}
					} else {
						rules.push(MatchCharCode(0x5D));
					}
				default:
					rules.push(createMatchCharCode(Std.ord(curchar)));
				}
			} // end unescaped char

			if(expectRangeEnd) {
				expectRangeEnd = false;
				var startCode : Int = 0;
				var endCode : Int = 0;

				var tmp = rules.pop();
				switch(tmp) {
				case MatchCharCode(cc):
					endCode = cc;
				default:
					throw unexpected("item " + Std.string(tmp));
				}
				tmp = rules.pop();
				switch(tmp) {
				case RangeMarker:
				default:
					throw unexpected("item " + Std.string(tmp));
				}
				tmp = rules.pop();
				switch(tmp) {
				case MatchCharCode(cc):
					startCode = cc;
				default:
					throw invalid("range");
				}
				rules.push(createMatchRange(startCode, endCode));
				continue;
			}

			var nextChar = peek();
			if(nextChar == "*" || nextChar == "+" || nextChar == "?" || nextChar == "{") {
				if(rules.length < 1)
					throw unexpected("quantifier");
				var lastRule : ERegMatch = rules[rules.length-1];
				i++;
				if(depth == 0 && atEndMarker)
					throw unexpected("character");
				var min : Null<Int> = 0;
				var max : Null<Int> = null;
				var qualifier : String = null;
				switch(nextChar) {
// 				*	   Match 0 or more times
// 				+	   Match 1 or more times
// 				?	   Match 1 or 0 times
// 				{n}    Match exactly n times
// 				{n,}   Match at least n times
// 				{n,m}  Match at least n but not more than m times
//
// 				the "*" quantifier is equivalent to {0,},
// 				the "+" quantifier to {1,},
// 				and the "?" quantifier to {0,1}
				case "*":
					qualifier = peek();
				case "+":
					min = 1;
					qualifier = peek();
				case "?":
					max = 1;
					qualifier = peek();
				case "{":
					var cp = inPattern.indexOf(",", i);
					var bp = inPattern.indexOf("}", i);
					if(bp < 2)
						throw expected("} to close count");
					qualifier = inPattern.charAt(bp+1);
					i++;
					var spec = StringTools.trim(inPattern.substr(i, bp - i));
					for(y in 0...spec.length) {
						var cc = spec.charCodeAt(y);
						if(!isNumeric(cc) && spec.charAt(y) != "," && !isWhite(cc))
								throw unexpected("character", i+y);
					}
					if(cp > bp) { // no comma
						min = Std.parseInt(spec);
						if(min == null)
							throw expected("number");
						max = min;
					} else {
						var parts = spec.split(",");
						if(parts.length != 2)
							throw unexpected("comma");
						for(x in 0...parts.length)
							parts[x] = StringTools.trim(parts[x]);
						min = Std.parseInt(parts[0]);
						max = Std.parseInt(parts[1]);
					}
					i += spec.length - 1;
				}
				var rv = createRepeat(lastRule, min, max, qualifier);
				if(rv.validQualifier)
					i++;
				i++;
				rules[rules.length-1] = rv.rule;
			}
		}

		rules = compactRules(rules, ignoreCase);
		#if DEBUG_PARSER
		trace("RETURNING FROM DEPTH " + depth);
		if(depth == 0)
			trace(rules);
		#end
		return {
			bytes : i + 1 - pos,
			rules : rules,
		};
	}

	/**
		Parses a set of rules, compacting multiple MatchCharCode and MatchExact
		rules to single MatchExacts.
	**/
	static function compactRules(rules : Array<ERegMatch>, ignoreCase) : Array<ERegMatch> {
		// Compacts the rules
		var newRules = new Array<ERegMatch>();
		var len = rules.length;
		var sb = new StringBuf();
		for(x in 0...len) {
			var r = rules.shift();
			switch(r) {
			case MatchCharCode(cc):
				sb.addChar(cc);
			case MatchExact(s):
				sb.add(s);
			default:
				var s = sb.toString();
				if(s.length > 0) {
					if(ignoreCase)
						s = s.toLowerCase();
					newRules.push(MatchExact(s));
					sb = new StringBuf();
				}
				newRules.push(r);
			}
		}
		if(sb.toString().length > 0) {
			var s = sb.toString();
			if(ignoreCase)
				s = s.toLowerCase();
			newRules.push(MatchExact(s));
		}
		return newRules;
	}

	static function createRepeat(rule : ERegMatch, min : Null<Int>, max : Null<Int>, qualifier : String)
		: { validQualifier: Bool, rule : ERegMatch}
	{
		var notGreedy = false;
		var possessive = false;
		var isValid = false;
		switch(qualifier) {
		case "+": possessive = true; isValid = true;
		case "?": notGreedy = true; isValid = true;
		}
		var minval : Int = 0;
		if(min != null)
			minval = min;
		return {
			validQualifier: isValid,
			rule: Repeat(rule, minval, max, notGreedy, possessive),
		};
	}

	/**
		Takes an array of strings and builds an IntHash of the
		character codes.
		@param a Array of Strings of characters to include
		@param curHash An existing set of characters
	**/
	function createMatchAnyOf(a : Array<String>, ?curHash : IntHash<Bool>) {
		var h = curHash;
		if(h == null)
			h = new IntHash();
		for(x in 0...a.length) {
			var s : String = a[x];
			if(s == null)
				continue;
			for(i in 0...s.length) {
				h.set(modifyCase(s.charCodeAt(i)), true);
			}
		}
		return MatchAnyOf(h);
	}

	function createMatchNoneOf(a : Array<String>) {
		var r = createMatchAnyOf(a);
		return switch(r) {
		case MatchAnyOf(h):
			MatchNoneOf(h);
		default:
			throw "error";
		}
	}

	/**
		Creates a MatchCharCode entry, changing case if necessary
		@param c Character code
		@return MatchCharCode instance
	**/
	function createMatchCharCode(c: Int) {
		return MatchCharCode(modifyCase(c));
	}

	/**
		Creates a MatchAnyOf with the character codes from [start] to [end] inclusive
		@param Starting
	**/
	function createMatchRange(start : Int, end:Int) {
		var h = new IntHash<Bool>();
		if(start > end) {
			var tmp = start;
			start = end;
			end = tmp;
		}
		#if debug
		if(start < 0 || end < 0)
			throw "Negative param problem";
		#end
		for(i in start...end+1) {
			h.set(modifyCase(i), true);
		}
		return MatchAnyOf(h);
	}

	/**
		Modifies any supplied character code for case sensitivity
	**/
	function modifyCase(cc : Int) : Int {
		return
			if(ignoreCase && (cc >= 65 && cc <= 90))
				32 + cc;
			else
				cc;
	}

// 	function createEscapeRule(c : String, pos : Int, inClass : Bool) {
//
// 	}

	static inline function isNumeric(c : Null<Int>) {
		return
			if(c == null)
				throw "null number";
			else
				(c >= 48 && c <= 57);
	}

	static inline function isAlpha(c : Null<Int>) {
		return
			if (c==null)
				throw "null character";
			else
				((c >= 65 && c <= 90) || (c >= 97 && c <= 122));
	}

	static inline function isAlNum(c : Null<Int>) {
		return (isNumeric(c) || isAlpha(c));
	}

	static inline function isHexChar(c : Null<Int>) {
		return
			if(c == null)
				throw "null hex char";
			else
				(isNumeric(c) || ((c >= 65 && c <= 70) || (c >= 97 && c <= 102)));
	}

	static inline function isWhite(c : Null<Int>) {
		return
			if(c == null)
				throw "null char";
			else
				(c == 32 || (c >= 9 && c <= 13));
	}

	static function newResult() : MatchResult {
		return {
			position : -1,
			matchCount : 0,
			length : 0,
			final : false,
			sideB : false,
			fatal : false,
		};
	}

	static function cloneResult(v : MatchResult) : MatchResult {
		return {
			position : v.position,
			matchCount : v.matchCount,
			length : v.length,
			final : v.final,
			sideB : v.sideB,
			fatal : v.fatal,
		};
	}

	static function copyResult(from: MatchResult, to:MatchResult) : Void {
		to.position = from.position;
		to.matchCount = from.matchCount;
		to.length = from.length;
		to.final = from.final;
		to.sideB = from.sideB;
		to.fatal = from.fatal;
	}

	static function compareResult(a, b) : Int {
		if(!a.fatal && b.fatal)
			return 1;
		if(a.fatal && !b.fatal)
			return -1;
		if(a.position > b.position)
			return 1;
		if(a.position < b.position)
			return -1;
		if(a.length > b.length)
			return 1;
		if(a.length < b.length)
			return -1;
		if(a.matchCount > b.matchCount)
			return 1;
		if(a.matchCount < b.matchCount)
			return -1;
		if(!a.final && b.final)
			return 1;
		if(a.final && !b.final)
			return -1;
		if(!a.sideB && b.sideB)
			return 1;
		if(a.sideB && !b.sideB)
			return -1;
		return 0;
	}

	function mergeClassRules(rules:Array<ERegMatch>, not:Bool) {
		var h = new IntHash<Bool>();
		for(x in 0...rules.length) {
			switch(rules[x]) {
			case Beginning, Or(_,_), Repeat(_,_,_,_,_), Capture(_), RangeMarker, End:
				throw "internal error";
			case MatchExact(s):
				if(ignoreCase)
					s = s.toLowerCase();
				for(i in 0...s.length)
					h.set(s.charCodeAt(i), true);
			case MatchCharCode(c):
				h.set(modifyCase(c), true);
			case MatchAny:
				not = !not;
				h = new IntHash<Bool>();
				h.set(0x0A, true);
			case MatchAnyOf(ch):
				for(k in ch.keys())
					h.set(modifyCase(k), true);
			case MatchNoneOf(ch):
				for(k in ch.keys())
					h.remove(modifyCase(k));
			case MatchWordBoundary, NotMatchWordBoundary, Frame(_,_,_):
				throw "internal error";
			}
		}
		if(not)
			return MatchNoneOf(h);
		else
			return MatchAnyOf(h);
	}

/*


By default, a quantified subpattern is "greedy", that is, it will match as many times as possible (given a particular starting location) while still allowing the rest of the pattern to match. If you want it to match the minimum number of times possible, follow the quantifier with a "?". Note that the meanings don't change, just the "greediness":

    *?     Match 0 or more times, not greedily
    +?     Match 1 or more times, not greedily
    ??     Match 0 or 1 time, not greedily
    {n}?   Match exactly n times, not greedily
    {n,}?  Match at least n times, not greedily
    {n,m}? Match at least n but not more than m times, not greedily

By default, when a quantified subpattern does not allow the rest of the overall pattern to match, Perl will backtrack. However, this behaviour is sometimes undesirable. Thus Perl provides the "possessive" quantifier form as well.

    *+     Match 0 or more times and give nothing back
    ++     Match 1 or more times and give nothing back
    ?+     Match 0 or 1 time and give nothing back
    {n}+   Match exactly n times and give nothing back (redundant)
    {n,}+  Match at least n times and give nothing back
    {n,m}+ Match at least n but not more than m times and give nothing back

*/

}