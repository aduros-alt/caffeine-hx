
private typedef State = {
	var matches : Array<String>;
	var index : Int;
	var frameStack : Array<ERegMatch>;
}

private typedef MatchResult = {
	var ok : Bool;
	var position : Int;
	var length : Int;
	var final : Bool;
	var conditional : Bool;
};

private enum ERegMatch {
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
	Capture(e : NativeEReg);
	BackRef(n : Int);
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

/**
	There is a discrepancy between what haxe returns for match() and what
	is done in perl. In haxe, "abcdeeefghi" ~= |e*| is false, whereas
	in Perl, this matches at pos 4, len 3. To enable Perl compatible
	results, compile with -D PERL_COMPATIBLE
**/
class NativeEReg {
	inline static var NULL_MATCH	: Int = -1;
	static var alpha = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
	static var numeric = "0123456789";
	static var wordHash : IntHash<Bool>;

	inline static var BEL			= 0x07; // \a
	inline static var BS			= 0x08; // \b
	inline static var HT			= 0x09; // \t
	inline static var LF 			= 0x0A; // \n
	inline static var VT 			= 0x0B; // \v
	inline static var FF 			= 0x0C; // \f
	inline static var CR 			= 0x0D; // \r
	inline static var ESC			= 0x1B; // ESC
	inline static var SPACE		= 0x20; // " "
	inline static var DEL			= 0x7F;
	inline static var NEL			= 0x85; //
	inline static var NBSP			= 0xa0; // NBSP

	#if SUPPORT_UTF8
	inline static var UTF_OSM		= 0x1680; /* OGHAM SPACE MARK */
	inline static var UTF_MVS		= 0x180e; /* MONGOLIAN VOWEL SEPARATOR */
	inline static var UTF_ENQUAD	= 0x2000; /* EN QUAD */
	inline static var UTF_EMQUAD	= 0x2001; /* EM QUAD */
	inline static var UTF_ENSPACE	= 0x2002; /* EN SPACE */
	inline static var UTF_EMSPACE	= 0x2003; /* EM SPACE */
	inline static var UTF_3PSPACE	= 0x2004; /* THREE-PER-EM SPACE */
	inline static var UTF_4PSPACE	= 0x2005; /* FOUR-PER-EM SPACE */
	inline static var UTF_6PSPACE	= 0x2006: /* SIX-PER-EM SPACE */
	inline static var UTF_FSPACE	= 0x2007: /* FIGURE SPACE */
	inline static var UTF_PSPACE	= 0x2008: /* PUNCTUATION SPACE */
	inline static var UTF_TSPACE	= 0x2009: /* THIN SPACE */
	inline static var UTF_HSPACE	= 0x200A: /* HAIR SPACE */
	inline static var UTF_LS		= 0x2028; // LINE SEPARATOR
	inline static var UTF_PS		= 0x2029; // PARAGRAPH SEPARATOR
	inline static var UTF_NNBSPACE	= 0x202f: /* NARROW NO-BREAK SPACE */
	inline static var UTF_MMSPACE	= 0x205f: /* MEDIUM MATHEMATICAL SPACE */
	inline static var UTF_ISPACE	= 0x3000: /* IDEOGRAPHIC SPACE */
	#end


	static var sBEL			= String.fromCharCode(0x07);
	static var sBS			= String.fromCharCode(0x08);
	static var sHT			= "\t";
	static var sLF			= "\n";
	static var sVT			= String.fromCharCode(0x0B);
	static var sFF			= String.fromCharCode(0x0C);
	static var sCR 			= "\r";
	static var sSPACE		= " ";
	static var sNEL			= String.fromCharCode(0x85);

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

	var capturesOpened : Int; // count each (
	var capturesClosed : Int; // count each )

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
			this.capturesOpened = 0;
			this.capturesClosed = 0;
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
		if(isRoot()) {
			if(pattern.length != rv.bytes)
				throw "NativeEReg::new : Unexpected characters at position " + rv.bytes;
			if(capturesOpened > capturesClosed)
				throw "Unclosed capture. " + " opened: " + capturesOpened + " closed: " + capturesClosed;
			if(capturesOpened < capturesClosed)
				throw "Unexpected capture closing. " + " opened: " + capturesOpened + " closed: " + capturesClosed;
			#if DEBUG_PARSER
			trace ("Top level consumed pattern " + parsedPattern);
			#end
		}
	}


	var frameStack : Array<ERegMatch>;
	var conditional : Bool;

	public function match( s : String ) : Bool {
		return (exec(s) != null);
	}

	function isRoot() : Bool {
		return this.root == this;
	}

	/**
		Executes the regular expression on string s.
	**/
	public function exec( s : String, ?matchAnywhere : Bool = false, ?startRule : Int = 0 ) :
		{ index:Int,leftContext:String, rightContext:String, matches:Array<String> }
	{
		if(s == null)
			return null;
		this.inputOrig = s;
		this.input = ignoreCase ? s.toLowerCase() : s;
		var startPos = (global ? 0 : lastIndex);

		var me = this;
		var pos = startPos;
		var i = startRule - 1;
		var outerPos = startPos;
		resetState();
		var bestMatchState = saveState();
		var mr : MatchResult = null;
		conditional = true;

		var updatePosition = function(mr : MatchResult) {
			if(me.index < 0)
				me.index = mr.position;
			pos = mr.position + mr.length;
			me.matches[0] = me.inputOrig.substr(me.index, pos - me.index);
			me.conditional = me.conditional && mr.conditional;
		}
		var reset = function() {
			me.resetState();
			i = startRule - 1;
			mr = null;
		}

		/*
			Conditional matches are those that have 0 length possibilities.
			ie. "black" ~= |e*| 'matches conditionally' on 0 e's, since
			"black" ~= |e*lack| has to match
		*/
		while(outerPos++ < input.length && conditional) {
			reset();
			pos = outerPos - 1;
			#if DEBUG_MATCH
				trace("--- Outer loop " + pos);
			#end
			while(++i < rules.length && pos <= input.length) {
				#if DEBUG_MATCH
					trace("--- start rule " + i);
					trace("Current index: " + this.index);
					trace("Current pos: "+pos);
					trace("Rule : " + rules[i]);
				#end
				mr = run(pos, [rules[i]]);
				#if DEBUG_MATCH
					trace("Result: " + mr);
				#end

				if(isValidMatch(pos, mr)) {
					updatePosition(mr);
					continue;
				}
				var found = false;
				//trace("Match not found. Stack: " + frameStack);
				while(true) {
					if(frameStack.length == 0)
						break;
					var rule = frameStack.pop();
					switch(rule) {
					case Frame(srcpos, _, _):
						#if DEBUG_MATCH
							trace("REWINDING TO " + srcpos + " FROM " + pos);
						#end
						pos = srcpos;
						mr = run(pos, [rule]);
						if(isValidMatch(pos, mr)) {
							updatePosition(mr);
							found = true;
						}
					default: throw "invalid item in frameStack";
					}
					if(found) {
						#if DEBUG_MATCH
							trace("RERUNNING " + rules[i] + " at pos " + pos);
						#end
						mr = run(pos, [rules[i]]);
						if(isValidMatch(pos, mr)) {
							updatePosition(mr);
							break;
						} else {
							found = false;
						}
					}
				}
				if(found)
					continue;

				// at this point, the match has failed at current position.
				// move to next position, reset state, and reset to rule 0
				pos++;
				reset();
			}
			if(mr != null && mr.ok && this.index >= 0) {
				if(		bestMatchState.index < 0 ||
						bestMatchState.matches.length == 0 ||
						this.matches[0].length > bestMatchState.matches[0].length ||
						conditional == false
				) {
					bestMatchState = saveState();
					#if DEBUG_MATCH
						trace("UPDATE BEST MATCH TO " + bestMatchState);
					#end
				}
			}
			if(!matchAnywhere || !isRoot())
				break;
		}

		restoreState(bestMatchState);

		#if DEBUG_MATCH
			trace(traceName() + " Final index: " + index + " length: " +  (pos - index) + " conditional: " + conditional);
		#end
		if(this.index < 0 || this.matches.length == 0 || (matches[0].length == 0 && conditional)) {
			lastIndex = 0;
			root.matches[this.groupNumber] = "";
			matches = new Array();
			return null;
		}

		var len =  matches[0].length;
		lastIndex = index;
		// makes sure that the match in 0 is of the original string
		// not the potentially modified 'input'
		matches[0] = inputOrig.substr(index, len);
		root.matches[groupNumber] = matches[0];

		leftContext = inputOrig.substr(0, index);
		rightContext = inputOrig.substr(index + len);

		var ra = new Array<String>();
		for(i in matches)
			ra.push(new String(i));
		return {
			index: this.index,
			leftContext: new String(this.leftContext),
			rightContext: new String(this.rightContext),
			matches: ra,
		}
	}

	function isValidMatch(pos : Int, mr : MatchResult) {
		if(!mr.ok)
			return false;
		if(pos == mr.position)
			return true;
		if(global) {
			if(this.index < 0)
				return true;
		}
		return false;
	}

	function saveState() : State {
		var sm = new Array<String>();
		for(m in matches)
			sm.push(new String(m));
		var nfs = new Array<ERegMatch>();
		for(r in frameStack) {
			switch(r) {
			case Frame(srcpos, rule, info):
				nfs.push(Frame(srcpos, rule, Reflect.copy(info)));
			default:
				throw "internal error";
			}
		}
		return {
			matches : sm,
			index : index,
			frameStack : nfs,
		}
	}

	function restoreState(state : State) : Void {
		matches = state.matches;
		index = state.index;
		frameStack = state.frameStack;
	}

	function resetState() {
		matches = new Array();
		index = -1;
		frameStack = new Array();
	}

	/**
	**/
	function run(pos:Int, rules:Array<ERegMatch>, ?info:Dynamic) : MatchResult {
		#if DEBUG_MATCH
		trace(">>> " + traceName() +" "+ here.methodName + " " + rules + " group: "+groupNumber+" pos: " + pos);
		#end
		var me = this;
		var origPos = pos;
		var final = true;
		var conditional = true;

		var MATCH = function(count : Int) {
			var len : Int = (count == NULL_MATCH ? 0 : pos - origPos);
			return {
				ok			: true,
				position	: origPos,
				length		: len,
				final		: final,
				conditional : conditional,
			}
		}
		var NOMATCH = function() {
			return {
				ok			: false,
				position	: origPos,
				length		: 0,
				final		: final,
				conditional : false,
			}
		}

		for(rule in rules) {
			switch(rule) {
			case Beginning:
				conditional = false;
				if(pos != 0)
					return NOMATCH();
			case MatchExact(s):
				conditional = false;
				if(pos>=input.length || input.substr(pos, s.length) != s)
					return NOMATCH();
				pos += s.length;
			case MatchCharCode(cc):
				conditional = false;
				if(pos>=input.length ||input.charCodeAt(pos) != cc)
					return NOMATCH();
				pos++;
			case MatchAny:
				conditional = false;
				if(pos>=input.length ||input.substr(pos, 1) == "\n")
					return NOMATCH();
				pos++;
			case MatchAnyOf(ch):
				conditional = false;
				if(pos>=input.length || !ch.exists(input.charCodeAt(pos)))
					return NOMATCH();
				pos++;
			case MatchNoneOf(ch):
				conditional = false;
				var exists = ch.exists(input.charCodeAt(pos));
				if(pos<input.length && exists)
					return NOMATCH();
				if(pos < input.length)
					pos++;
			case MatchWordBoundary:
				/*	A word boundary (\b ) is a spot between two characters that has a \w  on one side of it and a \W  on the other side of it (in either order), counting the imaginary characters off the beginning and end of the string as matching a \W */
				conditional = false;
				var prevIsWord = pos == 0 ? false : isWord(input.charCodeAt(pos-1));
				var curIsWord = pos >= input.length ? false : isWord(input.charCodeAt(pos));
				if(prevIsWord == curIsWord)
					return NOMATCH();
			case NotMatchWordBoundary:
				conditional = false;
				var prevIsWord = pos == 0 ? false : isWord(input.charCodeAt(pos-1));
				var curIsWord = pos >= input.length ? false : isWord(input.charCodeAt(pos));
				if(prevIsWord != curIsWord)
					return NOMATCH();
			case Or(a, b):
				conditional = false;
				if(info == null) {
					info = {
					pos : pos,
					origPos : origPos,
					state : saveState(),
					resultA: null,
					resultB: null,
					};
				}
				restoreState(info.state);
				origPos = info.origPos;
				pos = info.pos;
				var framePos = pos;
				var ok = false;
				var origStackLen = frameStack.length;

				var doResultSide = function(rules) {
					var mr = me.run(pos, rules, null);
					var ok = false;
					if(me.isValidMatch(pos, mr)) {
						origPos = mr.position;
						pos = origPos + mr.length;
// 						me.frameStack.push(Frame(framePos, rule, info));
						ok = true;
					} else {
						while(me.frameStack.length > origStackLen) {
							mr = me.run(pos, [me.frameStack.pop()], null);
							if(!mr.ok)
								continue;
							ok = true;
							pos = mr.position + mr.length;
							break;
						}
						if(me.frameStack.length > 0 && me.frameStack.length != origStackLen)
							me.frameStack.splice(me.frameStack.length, me.frameStack.length - origStackLen);
					}
					return { ok : ok, mr : mr }
				}

				if(info.resultA == null) {
					var rv = doResultSide(a);
					info.resultA = rv.mr;
					ok = rv.ok;
				}
				if(!ok && info.resultB == null) {
					var rv = doResultSide(b);
					info.resultB = rv.mr;
					ok = rv.ok;
				}
				if(!ok) {
					final = true;
					return NOMATCH();
				}
				final =
					(info.resultA == null ? false : info.resultA.final) &&
					(info.resultB == null ? false : info.resultB.final);

				if(!final)
					frameStack.push(Frame(framePos, rule, info));
				#if DEBUG_MATCH
					trace("END Or: frameStack: " + frameStack);
				#end
			case Repeat(e, minCount, maxCount, notGreedy, possessive):
				if(info == null) {
					info = {
					pos : pos,
					origPos : origPos,
					state : saveState(),
					lastCount : 0,
					min : minCount,
					max : maxCount,
					};
				}
				restoreState(info.state);
				pos = info.pos;
				origPos = info.origPos;
				var framePos = pos;
				var ok = false;
				var origStackLen = frameStack.length;
				var min = info.min;
				var max = info.max;

				var maxTest = function(c : Null<Int>) {
					if(max == null)
						return true;
					return c < max;
				}
				var count = 0;
				var mr : MatchResult = null;
				while(pos < input.length && maxTest(count)) {
					if(notGreedy && count >= min)
						break;
					mr = run(pos, [e]);
					if(!mr.ok)
						break;
					if(mr.position != pos)
						return NOMATCH();
					if(mr.length == 0)
						pos ++;
					else
						pos += mr.length;
					count++;
				}
				info.lastCount = count;
				if(count < min) {
					final = true;
					return NOMATCH();
				}
				if(max == null) {
					if(count > 0)
						conditional = false;
					if(notGreedy && count == 0)
						conditional = false;
				}
				if(notGreedy) {
					info.min = count + 1;
					if(info.max != null && info.min > info.max)
						final = true;
					else
						final = false;
				} else {
					info.max = count - 1;
					if(info.min > info.max)
						final = true;
					else
						final = false;
				}
				if(!final) {
					#if DEBUG_MATCH
						trace("******** "+rule+" NOT FINAL. PUSHING " + info);
					#end
					frameStack.push(Frame(framePos, rule, info));
				}
			case Capture(er):
				#if DEBUG_MATCH
					trace("RUNNING CAPTURE at pos: " + pos);
				#end
				er.lastIndex = pos;
				if(!er.match(inputOrig)) {
					#if DEBUG_MATCH
						trace("CAPTURE FAILED");
					#end
					return NOMATCH();
				}
				var len = root.matches[er.groupNumber].length;
				conditional = conditional && er.conditional;
				var mr : MatchResult = {
					ok : true,
					position : er.index,
					length : len,
					final : true,
					conditional : er.conditional,
				}
				if(!isValidMatch(pos, mr))
					return NOMATCH();
				origPos = er.index;
				pos = er.index + len;
				#if DEBUG_MATCH
					trace("CAPTURE " + er.groupNumber +" MATCHED new pos:" + pos);
				#end
			case BackRef(n):
				if(root.matches.length < n)
					throw "Internal error";
				var mr = run(pos, [MatchExact(root.matches[n])]);
				if(!mr.ok)
					return NOMATCH();
				pos += mr.length;
			case RangeMarker: throw "Internal error";
			case End:
				conditional = false;
				if(pos != input.length - 1) {
					if(multiline) {
						if(input.charAt(pos) == "\r" && input.charAt(pos+1) == "\n") {
							pos += 2;
						} else if(input.charAt(pos) == "\n") {
							pos ++;
						} else {
							return NOMATCH();
						}
					} else {
						return NOMATCH();
					}
				}
			case Frame(srcpos, r, inf):
				if(pos != srcpos)
					throw "invalid use";
				return run(pos, [r], inf);
			}
		}
		return MATCH(1);
	}

	/**
		Returns a matched group or throw an expection if there
		is no such group. If [n = 0], the whole matched substring
		is returned.
	**/
	public function matched( n : Int) : String {
		if(n >= matches.length || (n == 0 && matches[0].length == 0))
			throw "EReg::matched "+ n;
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
			pos : index,
			len : matches[0].length,
		};
	}

	public function split(s : String) : Array<String> {
		var oldGlobal = global;
		var results = new Array<String>();

		global = oldGlobal;
		return results;
	}

	#if (DEBUG_PARSER || DEBUG_MATCH)
	function traceName() {
		return (groupNumber > 0 ? "capture " + Std.string(groupNumber) : "root");
	}
	#end

	function parse(inPattern: String, pos : Int, depth: Int, ? inClass : Bool) : { bytes: Int, rules : Array<ERegMatch> } {
		var startPos = pos;
		#if DEBUG_PARSER
			var me = this;
			trace("START PARSE "+ traceName() +" depth: "+depth+" pos: " + pos);
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
				if(isNumeric(Std.ord(curchar))) {
					var end = pos;
					while(end < inPattern.length &&
						isNumeric(Std.ord(inPattern.charAt(++end))))
					{}
					var num = inPattern.substr(pos, end - pos);
					if(curchar == "0") { // octal
						var n = Std.parseOctal(num);
						if(n == null)
							throw invalid("octal sequence");
						i += num.length - 1;
						rules.push(createMatchCharCode(n));
					} else { // back reference
						var n = Std.parseInt(num);
						if(n == null || n == 0 || n > capturesOpened)
							throw invalid("back reference");
						rules.push(BackRef(n));
					}
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
						MatchCharCode(BEL);
					case "b": //\b	Match a word boundary, backspace in classes
						if(inClass)
							MatchCharCode(BS); // // http://perldoc.perl.org/perlre.html
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
							MatchCharCode(DEL);
						else if(val >= 0x40 && val < 0x5B)
							MatchCharCode(val - 64);
						else
							throw expected("control character code");
					case "d": // \d [0-9] Match a digit character
						createMatchAnyOf([numeric]);
					case "D": // \D [^\d] Match a non-digit character
						createMatchNoneOf([numeric]);
					case "e": // \e escape (ESC)
						MatchCharCode(ESC);
					case "f": // \f form feed (FF)
						MatchCharCode(FF);
					case "h": // \h Horizontal whitespace
						createMatchAnyOfCharCodes([
						#if SUPPORT_UTF8
							HT,SPACE,NBSP,UTF_OSM,UTF_MVS,UTF_ENQUAD,UTF_EMQUAD,
							UTF_ENSPACE,UTF_EMSPACE,UTF_3PSPACE,UTF_4PSPACE,UTF_6PSPACE,
							UTF_FSPACE,UTF_PSPACE,UTF_TSPACE,UTF_HSPACE,UTF_NNBSPACE,
							UTF_MMSPACE,UTF_ISPACE
						#else
							HT,SPACE,NBSP
						#end
						]);
					case "H": // \H Not horizontal whitespace
						createMatchNoneOfCharCodes([
						#if SUPPORT_UTF8
							HT,SPACE,NBSP,UTF_OSM,UTF_MVS,UTF_ENQUAD,UTF_EMQUAD,
							UTF_ENSPACE,UTF_EMSPACE,UTF_3PSPACE,UTF_4PSPACE,UTF_6PSPACE,
							UTF_FSPACE,UTF_PSPACE,UTF_TSPACE,UTF_HSPACE,UTF_NNBSPACE,
							UTF_MMSPACE,UTF_ISPACE
						#else
							HT,SPACE,NBSP
						#end
						]);
					case "n": // \n newline (LF, NL)
						MatchCharCode(LF);
					case "r": // \r return (CR)
						MatchCharCode(CR);
					case "R": // \R [CR,LF,CRLF] Linebreak
						//  (?>\x0D\x0A?|[\x0A-\x0C\x85\x{2028}\x{2029}])
						if(inClass)
							MatchExact("\\R"); // http://perldoc.perl.org/perlre.html
						else
							Or(
								[MatchExact("\r\n")],
								[createMatchAnyOfCharCodes([
								#if SUPPORT_UTF8
									LF,CR,NEL,UTF_LS,UTF_PS
								#else
									LF,CR,NEL
								#end
								])]
							);
					case "s": // \s [ \t\r\n\v\f]Match a whitespace character
						createMatchAnyOf([" \t\r\n", sVT, sFF]);
					case "S": // \S [^\s] Match a non-whitespace character
						createMatchNoneOf([" \t\r\n", sVT, sFF]);
					case "t": // \t	tab (HT, TAB)
						MatchCharCode(0x09);
					case "v": // \v Vertical whitespace [\r\n\v]
						createMatchAnyOfCharCodes([
						#if SUPPORT_UTF8
							LF,VT,FF,CR,NEL,UTF_LS,UTF_PS
						#else
							LF,VT,FF,CR,NEL
						#end
						]);
					case "V": // \V Not vertical whitespace
						createMatchNoneOfCharCodes([
						#if SUPPORT_UTF8
							LF,VT,FF,CR,NEL,UTF_LS,UTF_PS
						#else
							LF,VT,FF,CR,NEL
						#end
						]);
					case "w": // \w [A-Za-z0-9_] Match a "word" character (alphanumeric plus "_")
						createMatchAnyOf([alpha, numeric, "_"]);
					case "W": // \W [^\w] Match a non-"word" character
						createMatchNoneOf([alpha, numeric, "_"]);
					//case "x": Handled above // \x1B hex char (example: ESC)
							// \x{263a} long hex char (example: Unicode SMILEY)
					default:
// 							\g1      Backreference to a specific or previous group,
// 							\g{-1}   number may be negative indicating a previous buffer and may
// 										optionally be wrapped in curly brackets for safer parsing.
// 							\g{name} Named backreference
// 							\k<name> Named backreference
// 							\K       Keep the stuff left of the \K, don't include it in $&
// 							\l		lowercase next char (think vi)
// 							\u		uppercase next char (think vi)
// 							\L		lowercase till \E (think vi)
// 							\U		uppercase till \E (think vi)
// 							\E		end case modification (think vi)
// 							\Q		quote (disable) pattern metacharacters till \E
// 							\N{name}	named Unicode character
// 							\cK		control char          (example: VT)
// 							\pP	     Match P, named property.  Use \p{Prop} for longer names.
// 							\PP	     Match non-P
// 							\X	     Match eXtended Unicode "combining character sequence",
// 										equivalent to (?:\PM\pM*)
// 							\C	     Match a single C char (octet) even under Unicode.
// 									NOTE: breaks up characters into their UTF-8 bytes,
// 									so you may end up with malformed pieces of UTF-8.
// 									Unsupported in lookbehind.
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
					if(inClass)
						rules.push(MatchCharCode(0x2E));
					else
						rules.push(MatchAny);
				case "$": // Match the end of the line (or before newline at the end)
					if(inClass) {
						rules.push(MatchCharCode(0x24));
					} else {
						if(depth == 0 && isRoot()) {
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
						this.root.capturesOpened++;
						#if DEBUG_PARSER
							trace("+++ START CAPTURE " + this.root.capturesOpened);
						#end
						var er = new NativeEReg(inPattern.substr(++i), this.options, this);
						rules.push(Capture(er));

						i += er.parsedPattern.length -1 ;
						#if DEBUG_PARSER
							trace("+++ END CAPTURE child consumed "+ er.parsedPattern + (i+1 >= inPattern.length ? " at EOL" : " next char is '" + peek() + "'") + " capturesClosed: " + this.root.capturesClosed);
						#end
					}
				case ")": // Grouping End
					if(inClass) {
						rules.push(MatchCharCode(0x29));
					} else {
						if(depth > 0) {
							i--;
							break;
						} else {
							this.root.capturesClosed++;
							atEndMarker = true;
						}
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
						var rs = parse(inPattern, i, depth, true);
						#if DEBUG_PARSER
							trace(">>> END CLASS AT DEPTH " + depth + " class consumed " + rs.bytes + " bytes: " + inPattern.substr(i, rs.bytes) );
						#end
						i += rs.bytes;
						#if DEBUG_PARSER
							trace(">>> Next is at "+(i+1)+" char: " + peek());
						#end
						rules.push(mergeClassRules(rs.rules, not));
					}
				case "]": // Character class end
					if(inClass) {
						#if DEBUG_PARSER
							trace("DETECTED Character class end at pos: "+i+" depth: " + depth);
						#end
						if(expectRangeEnd)
							throw expected("end of character range");
						atEndMarker = true;
						i--;
						break;
					} else {
						rules.push(MatchCharCode(0x5D));
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
// 				if(depth == 0 && atEndMarker) {
// 					trace(this);
// 					throw unexpected("character");
// 				}
				var min : Null<Int> = 0;
				var max : Null<Int> = null;
				var qualifier : String = null;
				switch(tok()) {
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
					i++;
					var cp = inPattern.indexOf(",", i);
					var bp = inPattern.indexOf("}", i);
					if(bp < 2)
						throw expected("} to close count");
					qualifier = inPattern.charAt(bp+1);
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
					i += spec.length;
				}
				var rv = createRepeat(lastRule, min, max, qualifier);
				if(rv.validQualifier)
					i++;
				rules[rules.length-1] = rv.rule;
			}
		} // while(i < patternLen - 1 && !atEndMarker)

		rules = compactRules(rules, ignoreCase);
		#if DEBUG_PARSER
		trace("RETURNING FROM " + traceName() + " DEPTH " + depth + (depth == 0 ? " rules: " + Std.string(rules) : ""));
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
		@return MatchAnyOf()
	**/
	function createMatchAnyOf(a : Array<String>) {
		var b = new Array<Int>();
		for(x in 0...a.length) {
			var s : String = a[x];
			if(s == null)
				continue;
			for(i in 0...s.length)
				b.push(s.charCodeAt(i));
		}
		return createMatchAnyOfCharCodes(b);
	}

	/**
		Takes an array of Ints and builds an IntHash
		@param a Array of Ints of characters to include
		@return MatchAnyOf() containing all the supplied codes
	**/
	function createMatchAnyOfCharCodes(a : Array<Int>) {
		var h = new IntHash();
		for(x in 0...a.length)
			for(i in 0...a.length)
				h.set(modifyCase(a[i]), true);
		return MatchAnyOf(h);
	}

	/**
		Takes an array of strings and builds an IntHash of the
		character codes.
		@param a Array of Strings of characters to include
		@return MatchNoneOf() containing all the supplied codes
	**/
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
		Takes an array of Ints and builds an IntHash
		@param a Array of Ints of characters to include
		@return MatchNoneOf() containing all the supplied codes
	**/
	function createMatchNoneOfCharCodes(a : Array<Int>) {
		var r = createMatchAnyOfCharCodes(a);
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

	function isWord(c : Int) {
		if(wordHash == null) {
			wordHash = new IntHash();
			var m = createMatchAnyOf([alpha,numeric,"_"]);
			switch(m) {
			case MatchAnyOf(h):
				wordHash = h;
			default: throw "internal error";
			}
		}
		return wordHash.exists(c);
	}

	static function newResult() : MatchResult {
		return {
			ok : false,
			position : -1,
			length : 0,
			final : false,
			conditional : true,
		};
	}

	static function cloneResult(v : MatchResult) : MatchResult {
		return {
			ok : v.ok,
			position : v.position,
			length : v.length,
			final : v.final,
			conditional : v.conditional,
		};
	}

	static function copyResult(from: MatchResult, to:MatchResult) : Void {
		to.ok = from.ok;
		to.position = from.position;
		to.length = from.length;
		to.final = from.final;
		to.conditional = from.conditional;
	}

	static function compareResult(a, b) : Int {
		if(a.ok && !b.ok)
			return 1;
		if(!a.ok && b.ok)
			return -1;
		if(a.position > b.position)
			return 1;
		if(a.position < b.position)
			return -1;
		if(a.length > b.length)
			return 1;
		if(a.length < b.length)
			return -1;
		if(!a.final && b.final)
			return 1;
		if(a.final && !b.final)
			return -1;
		if(!a.conditional && b.conditional)
			return 1;
		if(a.conditional && !b.conditional)
			return -1;
		return 0;
	}

	function mergeClassRules(rules:Array<ERegMatch>, not:Bool) {
		var h = new IntHash<Bool>();
		for(x in 0...rules.length) {
			switch(rules[x]) {
			case Beginning, Or(_,_), Repeat(_,_,_,_,_), Capture(_), RangeMarker, End:
				throw "internal error " + rules[x];
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
				h.set(LF, true);
			case MatchAnyOf(ch):
				for(k in ch.keys())
					h.set(modifyCase(k), true);
			case MatchNoneOf(ch):
				for(k in ch.keys())
					h.remove(modifyCase(k));
			case MatchWordBoundary, NotMatchWordBoundary, Frame(_,_,_), BackRef(_):
				throw "internal error";
			}
		}
		if(not)
			return MatchNoneOf(h);
		else
			return MatchAnyOf(h);
	}

	public function toString() : String {
		var sb = new StringBuf();
		sb.add("NativeEReg { group: ");
		sb.add((groupNumber == 0 ? "root" : Std.string(groupNumber)));
		sb.add(", ");
		sb.add("rules: ");
		sb.add(rulesToString(rules));
		sb.add(" }");
		return sb.toString();
	}

	public function ruleToString(r : ERegMatch) {
		return switch(r) {
		case MatchCharCode(c):
			"MatchCharCode(" + Std.chr(c) + ")";
		case Or(a, b):
			"Or(" + rulesToString(a) + ", " + rulesToString(b) + ")";
		case Repeat(r, min, max, notGreedy, possessive):
			"Repeat(rule:" + ruleToString(r) + ", min:"+min+", max:"+max+", notGreedy:"+notGreedy+", possessive:"+possessive+")";
		case Capture(e):
			"Capture("+e.toString()+")";
		case Frame(srcpos, r, info):
			"Frame(srcpos:"+srcpos+" rule:" + ruleToString(r) + " info:[object])";
		default: Std.string(r);
		}
	}

	public function rulesToString(a : Array<ERegMatch>) {
		var sb = new StringBuf();
		sb.add("[");
		for(i in 0...a.length) {
			sb.add(ruleToString(a[i]));
			if(i < a.length - 1) {
				sb.add(", ");
			}
		}
		sb.add("]");
		return sb.toString();
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