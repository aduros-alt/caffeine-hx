/*
 * Copyright (c) 2008-2009, The Caffeine-hx project contributors
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

package chx;

private typedef State = {
	var matches : Array<String>;
	var index : Int;
	var frameStack : Array<ERegMatch>;
	var parentState : State;
}

private typedef MatchResult = {
	var ok : Bool;
	var position : Int;
	var length : Int;
	var final : Bool;
	var conditional : Bool;
};

private typedef ExecState = {
	var restoring		: Bool;
	var matchAnywhere	: Bool;
	var startPos		: Int;
	var outerPos		: Int;
	var iRuleIdx		: Int;
	var iPos			: Int;
	var conditional		: Bool;
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
	Capture(e : RegEx);
	BackRef(n : Int);
	RangeMarker;
	End;
	Frame(id:Int, srcpos:Int, r:ERegMatch, info:Dynamic);
	ChildFrame(frameId:Int, e:RegEx, eExecState:ExecState, pExecState:ExecState);
}

// @todo
private enum ChildType {
	Capture;
	Comment; // (?#text)
	//PatMatchModifier(?) (?pimsx-imsx)
	NoBackref; // (?:pattern) Matches without creating backref
	//BranchReset; // (?|pattern) not sure how to do this one yet
	LookAhead; // (?=pattern) /\w+(?=\t)/ matches a word followed by a tab, without including the tab in $&
	NegLookAhead; //(?!pattern)
	LookBehind; // (?<=pattern) /(?<=\t)\w+/ matches a word that follows a tab, without including the tab in $&
	NegLookBehind; //(?<!pattern) /(?<!bar)foo/ matches any occurrence of "foo" that does not follow "bar". Works only for fixed-width look-behind.
	//Named; # (?'NAME'pattern) # (?<NAME>pattern) A regular capture, just named. Just register in root

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
class RegEx {
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
	var root(default, null)		: RegEx;
	var parent(default, null)	: RegEx;
	var depth					: Int;
	var namedGroups				: Hash<RegEx>;
	var _groupCount 			: Int; // a 'static' accessed by sub groups
	var _frameIdx				: Int; // a 'static' Frame index number

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

	public function new(pattern : String, opt : String, ?parent : RegEx = null) {
		this.pattern = pattern;
		this.options = opt.toLowerCase();
		this.ignoreCase = (options.indexOf("i") >= 0);
		this.multiline = (options.indexOf("m") >= 0);
		this.global = (options.indexOf("g") >= 0);
		this.lastIndex = 0;
		if(parent == null) {
			_groupCount = 0;
			_frameIdx = 0;
			this.root = this;
			this.parent = this;
			this.groupNumber = 0;
			this.capturesOpened = 0;
			this.capturesClosed = 0;
			this.depth = 0;
			this.namedGroups = new Hash();
		} else {
// 			As RegEx instances are created for each group, the
// 			'global static' _groupCount is incremented and the new
// 			instance gets assigned the groupNumber.
			this.root = parent.root;
			this.parent = parent;
			this.groupNumber = ++this.root._groupCount;
			this.depth = parent.depth + 1;
		}
		this.rules = new Array();

		var rv = parse(pattern, 0, 0);
		for(r in rv.rules)
			this.rules.push(r);
		this.parsedPattern = pattern.substr(0, rv.bytes);
		if(isRoot()) {
			if(pattern.length != rv.bytes)
				throw "RegEx::new : Unexpected characters at position " + rv.bytes;
			if(capturesOpened > capturesClosed)
				throw "Unclosed capture. " + " opened: " + capturesOpened + " closed: " + capturesClosed;
			if(capturesOpened < capturesClosed)
				throw "Unexpected capture closing. " + " opened: " + capturesOpened + " closed: " + capturesClosed;
			#if DEBUG_PARSER
			trace ("Top level consumed pattern " + parsedPattern);
			#end
		}
	}

	public function match( s : String ) : Bool {
		return (exec(s) != null);
	}

	function isRoot() : Bool {
		return this.root == this;
	}

	var frameStack : Array<ERegMatch>;
	var es : ExecState;

	/**
		Executes the regular expression on string s.
		@return null if no match
	**/
	public function exec( s : String, ?matchAnywhere : Bool = false, ?lastExecState : ExecState ) :
		{ index:Int,leftContext:String, rightContext:String, matches:Array<String> }
	{
		if(s == null)
			return null;
		var me = this;
		this.inputOrig = s;
		this.input = ignoreCase ? s.toLowerCase() : s;

		var reEnterLoop = false;
		if(lastExecState == null) {
			es = {
				restoring	: false,
				matchAnywhere : matchAnywhere,
				startPos 	: (global ? lastIndex : 0),
				outerPos 	: (global ? lastIndex : 0),
				iRuleIdx 	: -1,
				iPos		: (global ? lastIndex : 0),
				conditional : true,
			}
			resetState();
		} else {
			es = lastExecState;
			reEnterLoop = true;
			es.restoring = true; // just to be sure
			es.outerPos--;
			es.iRuleIdx--;
			root.matches[groupNumber] = null;
			// no reset of match state, since it should exist.
		}

		var bestMatchState = saveState();
		var mr : MatchResult = null;

		var updatePosition = function(mr : MatchResult) {
			if(me.index < 0)
				me.index = mr.position;
			me.es.iPos = mr.position + mr.length;
			me.matches[0] = me.inputOrig.substr(me.index, me.es.iPos - me.index);
			me.es.conditional = me.es.conditional && mr.conditional;
		}
		var reset = function() {
			me.resetState();
			me.es.iRuleIdx = - 1;
			mr = null;
		}

		/*
			Conditional matches are those that have 0 length possibilities.
			ie. "black" ~= |e*| 'matches conditionally' on 0 e's, since
			"black" ~= |e*lack| has to match
		*/
		while(es.outerPos++ < input.length && (es.conditional || reEnterLoop)) {
			if(!reEnterLoop) {
				reset();
				es.iPos = es.outerPos - 1;
			}
			else
				reEnterLoop = false;
			#if DEBUG_MATCH
				trace(traceName() + " --- Outer loop " + es.iPos);
			#end

			while(++es.iRuleIdx < rules.length && es.iPos <= input.length) {
				#if DEBUG_MATCH
					trace(traceName() + " --- start rule " + es.iRuleIdx);
					trace(traceName() + " Current index: " + this.index);
					trace(traceName() + " Current pos: "+es.iPos);
					trace(traceName() + " Rule : " + rules[es.iRuleIdx]);
				#end
				if(!es.restoring) {
					mr = run(es.iPos, [rules[es.iRuleIdx]]);
					#if DEBUG_MATCH trace(traceName() + " Result: " + mr);	#end
				} else {
					mr == null;
					es.restoring = false;
					var cr : ERegMatch = popFrame();
					if(cr == null)
						throw "internal error";
					#if DEBUG_MATCH trace(traceName() + " Restoring at rule #"+es.iRuleIdx + " " + ruleToString(cr)); #end
					mr = run(es.iPos, [cr]);
				}

				if(isValidMatch(es.iPos, mr)) {
					updatePosition(mr);
					continue;
				}
				var found = false;

				#if DEBUG_MATCH
				trace(traceName() + " +++++++++++++++++++++ Match not found. Stack: " + frameStack);
				#end
				while(true) {
					var isChild = false;
					var rule = popFrame();
					if(rule == null)
						break;
					switch(rule) {
					case Frame(_, srcpos, _, _):
						#if DEBUG_MATCH
							trace(traceName() + " REWINDING TO " + srcpos + " FROM " + es.iPos);
						#end
						es.iPos = srcpos;
						isChild = false;
					case ChildFrame(_, e, eExecState, pExecState):
						restoreExecState(pExecState);
						es.iRuleIdx++;
						isChild = true;
					default: throw "invalid item in frameStack";
					}
					mr = run(es.iPos, [rule]);
					if(isValidMatch(es.iPos, mr)) {
						updatePosition(mr);
						found = true;
					}
					if(found) {
						#if DEBUG_MATCH
							trace(traceName() + " RERUNNING " + rules[es.iRuleIdx] + " at pos " + es.iPos);
						#end
						mr = run(es.iPos, [rules[es.iRuleIdx]]);
						if(isValidMatch(es.iPos, mr)) {
							updatePosition(mr);
							if(isChild)
								es.iRuleIdx++;
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
				es.iPos++;
				reset();
			}
			if(mr != null && mr.ok && this.index >= 0) {
				if(		bestMatchState.index < 0 ||
						bestMatchState.matches.length == 0 ||
						this.matches[0].length > bestMatchState.matches[0].length ||
						es.conditional == false
				) {
					bestMatchState = saveState();
					#if DEBUG_MATCH
						trace(traceName() + " UPDATE BEST MATCH TO " + matches[0]/*+ bestMatchState*/);
					#end
				}
			}
			if(!matchAnywhere || !isRoot())
				break;
		}

		restoreState(bestMatchState);

		#if DEBUG_MATCH
			trace(traceName() + " Final index: " + index + " length: " +  (es.iPos - index) + " conditional: " + es.conditional);
		#end
		if(this.index < 0 || this.matches.length == 0 || (matches[0].length == 0 && es.conditional)) {
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
		if(mr == null || !mr.ok)
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
			case Frame(id,srcpos, rule, info):
				nfs.push(Frame(id,srcpos, rule, Reflect.copy(info)));
			case ChildFrame(id, e, eExecState, pExecState):
				nfs.push(ChildFrame(id, e, eExecState, pExecState));
			default:
				throw "internal error";
			}
		}

		var ps : State = parent != this ? parent.saveState() : null;

		return {
			matches : sm,
			index : index,
			frameStack : nfs,
			parentState : ps,
		}
	}

	function restoreState(state : State) : Void {
		matches = state.matches;
		index = state.index;
		frameStack = state.frameStack;
		if(state.parentState != null)
			parent.restoreState(state.parentState);
	}

	function resetState() {
		matches = new Array();
		index = -1;
		frameStack = new Array();
	}

	static function copyExecState(v : ExecState) : ExecState {
		return {
			restoring	: v.restoring,
			matchAnywhere : v.matchAnywhere,
			startPos 	: v.startPos,
			outerPos 	: v.outerPos,
			iRuleIdx 	: v.iRuleIdx,
			iPos		: v.iPos,
			conditional : v.conditional,
		}
	}

	function restoreExecState(v : ExecState) : Void {
		es = v;
		es.restoring = false;
	}

	/**
		http:/
	**/
	function run(pos:Int, rules:Array<ERegMatch>, ?info:Dynamic) : MatchResult {
		#if DEBUG_MATCH
		trace(">>> " + traceName() +" "+ here.methodName + " " + rulesToString(rules) + " group: "+groupNumber+" pos: " + pos);
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
				var exists = input.charCodeAt(pos) == null || ch.exists(input.charCodeAt(pos));
				if(exists)
					return NOMATCH();
				pos++;
				/* Past EOL version
				if(pos<input.length && exists)
					return NOMATCH();
				if(pos < input.length)
					pos++;
				else
					conditional = true;
				*/
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
						ok = true;
					} else {
						while(me.frameStack.length > origStackLen) {
							mr = me.run(pos, [me.popFrame()], null);
							if(!mr.ok)
								continue;
							ok = true;
							pos = mr.position + mr.length;
							break;
						}
						me.rewindStackLength(origStackLen);
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
					pushFrame(framePos, rule, info);
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
						//trace("******** "+rule+" NOT FINAL. PUSHING " + info);
					#end
					pushFrame(framePos, rule, info);
				}
			case Capture(er):
				#if DEBUG_MATCH
					trace(traceName() + " RUNNING CAPTURE "+ er.groupNumber+" at pos: " + pos);
				#end
				er.lastIndex = pos;
				er.global = true;
				if(!er.match(inputOrig)) {
					#if DEBUG_MATCH
						trace(traceName() + " CAPTURE FAILED");
					#end
					return NOMATCH();
				}
				var len = root.matches[er.groupNumber].length;
				conditional = conditional && er.es.conditional;
				var mr : MatchResult = {
					ok : true,
					position : er.index,
					length : len,
					final : true,
					conditional : er.es.conditional,
				}
				if(!isValidMatch(pos, mr))
					return NOMATCH();
				origPos = er.index;
				pos = er.index + len;
				#if DEBUG_MATCH
					trace(traceName() + " CAPTURE " + er.groupNumber +" MATCHED new pos:" + pos);
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
				if(pos != input.length) {
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
			case Frame(_, srcpos, r, inf):
				if(pos != srcpos)
					throw "invalid use";
				return run(pos, [r], inf);
			case ChildFrame(_, er, eExecState, _):
				var res = er.exec(inputOrig, es.matchAnywhere, eExecState);
				//trace(res);
				if(res == null)
					return NOMATCH();
				var len = root.matches[er.groupNumber].length;
				conditional = conditional && er.es.conditional;
				var mr : MatchResult = {
					ok : true,
					position : er.index,
					length : len,
					final : true,
					conditional : er.es.conditional,
				}
				if(!isValidMatch(pos, mr))
					return NOMATCH();
				origPos = er.index;
				pos = er.index + len;
				#if DEBUG_MATCH
					trace("CAPTURE " + er.groupNumber +" MATCHED new pos:" + pos);
				#end
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

	/**
		@todo Not implemented yet.
	**/
	public function split(s : String) : Array<String> {
		var oldGlobal = global;
		var results = new Array<String>();
		throw "not implemented";
		global = oldGlobal;
		return results;
	}

	#if (DEBUG_PARSER || DEBUG_MATCH)
	function traceName() {
		return (groupNumber > 0 ? "capture " + Std.string(groupNumber) : "root");
	}
	#end

	function parse(inPattern: String, pos : Int, orLevel: Int, ? inClass : Bool = false) : { bytes: Int, rules : Array<ERegMatch> } {
		var me = this;
		var startPos = pos;
		#if DEBUG_PARSER
			trace("START PARSE "+ traceName() +" orLevel: "+orLevel+" pos: " + pos + (inClass ? " in CLASS" : ""));
		#end

		var curchar : String = null;
		var rules : Array<ERegMatch> = new Array();
		var expectRangeEnd = false;
		var patternLen = inPattern.length;
		var atEndMarker : Bool = false;

		var msg = function(k : String, s : String, ?p : Null<Int>=null) : String {
			if(p == null)
				p = pos;
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
		var error = function(s: String, ?p : Null<Int> = null) : String {
			return msg("Parse error:", s, p);
		}
		var backrefNotDefined = function(n:Dynamic, ?p : Null<Int> = null) : String {
			return msg("Backreference " + Std.string(n), "is not a defined group yet", p);
		}
		var peek = function() : String {
			return inPattern.charAt(pos+1);
		}
		var tok = function() : String {
			return curchar = inPattern.charAt(++pos);
		}
		var untok = function() : String {
			return curchar = inPattern.charAt(--pos);
		}
		var consumeAlNum = function(allowUnderscore : Bool, reqAlphaStart:Bool) : String {
			curchar = tok();
			if(reqAlphaStart && !isAlpha(Std.ord(curchar)))
				throw invalid("string must begin with alpha character");
			var s : String = curchar;
			curchar = tok();
			while(pos < inPattern.length && (isAlNum(Std.ord(curchar)) || curchar == "_") ) {
				s += curchar;
				curchar = tok();
			}
			curchar = untok();
			return s;
		}
		var consumeNumeric = function(?max:Int=-1) {
			var s = "";
			var count = 0;
			curchar = tok();
			while(pos < inPattern.length &&
					isNumeric(Std.ord(curchar)) &&
					(max < 0 || count++ <= max))
			{
				s += curchar;
				curchar = tok();
			}
			curchar = untok();
			return s;
		}
		var assert = function(v : Bool, ?msg : String = "") {
			#if debug
			if(!v)
				throw error("Assertion "+msg+(msg.length > 0 ? " ":"") + "failed");
			#end
		}
		var assertCallback = function(f : Void -> Bool, ?msg : String = "") {
			#if debug
			var res : Bool = f();
			if(!res) {
				throw error("Assertion "+msg+(msg.length > 0 ? " ":"") + "failed");
			}
			#end
		}
		var isValidBackreference = function(n : Int) {
			return n <= me.root._groupCount;
		}
		var hasQuantifier = function() {
			var nextChar = peek();
			if(!inClass && (nextChar == "*" || nextChar == "+" || nextChar == "?" || nextChar == "{"))
				return true;
			return false;
		}
		var checkQuantifier = function() {
			var nextChar = peek();
			if(!inClass && (nextChar == "*" || nextChar == "+" || nextChar == "?" || nextChar == "{")) {
				if(rules.length < 1)
					throw unexpected("quantifier");
				var lastRule : ERegMatch = rules[rules.length-1];
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
					pos++;
					var cp = inPattern.indexOf(",", pos);
					var bp = inPattern.indexOf("}", pos);
					if(bp < 2)
						throw expected("} to close count");
					qualifier = inPattern.charAt(bp+1);
					var spec = StringTools.trim(inPattern.substr(pos, bp - pos));
					for(y in 0...spec.length) {
						var cc = spec.charCodeAt(y);
						if(!isNumeric(cc) && spec.charAt(y) != "," && !isWhite(cc))
								throw unexpected("character", pos+y);
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
					pos += spec.length;
				}
				var rv = createRepeat(lastRule, min, max, qualifier);
				if(rv.validQualifier)
					pos++;
				rules[rules.length-1] = rv.rule;
			}
		}

		pos--;
		while(pos < patternLen - 1 && !atEndMarker) {
			curchar = tok();
			#if DEBUG_PARSER
				trace(traceName() + " pos: " + pos + " curchar: " +curchar + " orLevel: "+orLevel + " nextChar: " + peek());
			#end
			if(curchar == "\\") { // '\'
				curchar = tok();
				// handle octal
				if(isNumeric(Std.ord(curchar))) {
					var numStr = curchar + consumeNumeric(2);
					var doOctal = function() {
						var len = 0;
						while(len < numStr.length) {
							 if(!isOctalDigitChar(numStr.charCodeAt(len)))
								break;
							len++;
						}
						if(len == 0) {
							if(!inClass)
								throw backrefNotDefined(numStr);
							else
								throw invalid("octal sequence in character class");
						}
						// in case we have pulled invalid octal digits \329
						// where 9 is not a valid digit
						pos = pos - numStr.length + len - 1;
						curchar = tok();
						numStr = numStr.substr(0, len);

						if(numStr.charAt(0) != "0" || numStr.length == 1)
							numStr = "0" + numStr;
						var n = Std.parseOctal(numStr);
						if(n == null)
							throw invalid("octal sequence");
						rules.push(me.createMatchCharCode(n));
					}
					if(inClass) { // no backreferences, must be octal
						doOctal();
					}
					else if(numStr.length == 1) {
						//\1 through \9 are always interpreted as backreferences
						if(numStr == "0")
							doOctal();
						else {
							var n = Std.parseInt(numStr);
							if(n == null)
								throw "internal error";
							if(!isValidBackreference(n))
								throw backrefNotDefined(numStr);
							rules.push(BackRef(n));
						}
					}
					else {
						//\10 as a backreference only if at least 10 left parentheses have opened
						// why do programmers make things difficult? Just for fun?
						if(numStr.charAt(0) == "0") {
							doOctal();
						}
						else {
							var brs = numStr.substr(0);
							var found = false;
							var n : Int = 0;
							while(brs != null && brs.length > 0) {
								n = Std.parseInt(brs);
								if(n == null) throw "internal error";
								if(isValidBackreference(n)) {
									rules.push(BackRef(n));
									pos = pos - numStr.length + brs.length - 1;
									curchar = tok();
									found = true;
									break;
								}
								brs = brs.substr(0, brs.length - 1);
							}
							if(!found) {
								if(!isOctalDigitChar(Std.ord(numStr)))
									throw backrefNotDefined(numStr);
								else
									doOctal();
							}
						}
					}
					assertCallback(callback(isNumericChar,curchar), " curchar is " + curchar);
				}
				// handle hex
				else if(curchar == "x") {
					curchar = tok();
					var endPos : Int = pos + 2;
					if(curchar == "{") {
						var endPos = inPattern.indexOf("}", ++pos);
						if(endPos < 0)
							throw invalid("long hex sequence");
					}
					var hs = inPattern.substr(pos, endPos-pos);
					for(x in 0...hs.length)
						if(!isHexChar(hs.charCodeAt(x)))
							throw invalid("long hex sequence");
					var n = Std.parseInt("0x" + hs);
					if(n == null)
						throw invalid("long hex sequence");
					pos = endPos;
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
					case "/":
						MatchCharCode(0x2F);
					case "?":
						MatchCharCode(0x3F);
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
						var ctrlChar = peek();
						var val = Std.ord(ctrlChar);
						if(val != null && ((val >= 0x40 && val < 0x5B) || val == 0x3F)) {
							curchar = tok(); // consume it
							if(val == 0x3F)
								MatchCharCode(DEL);
							else
								MatchCharCode(val - 64);
						}
						else
							MatchCharCode(0x63); // 'c'
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
//							Perl 5.10
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
// 						throw unhandled("escape sequence char " + curchar);
						createMatchCharCode(Std.ord(curchar));
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
						if(pos == 0 && orLevel == 0) {
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
						if(orLevel == 0 && isRoot()) {
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
						var rs = parse(inPattern, ++pos, orLevel + 1);
						pos += rs.bytes - 1;
						if(rs.rules.length == 0)
							throw expected("Or condition");
						rules.push(Or(orRules, rs.rules));
					}
				case "(": // Grouping
					if(inClass) {
						rules.push(MatchCharCode(0x28));
					} else {
						if(orLevel != 0)
							throw unexpected("(");
						this.root.capturesOpened++;
						#if DEBUG_PARSER
							trace("+++ START CAPTURE " + this.root.capturesOpened);
						#end
						var er = new RegEx(inPattern.substr(++pos), this.options, this);
						rules.push(Capture(er));
						pos += er.parsedPattern.length -1 ;
						checkQuantifier();
						#if DEBUG_PARSER
							trace("+++ END CAPTURE " + er.groupNumber + " child consumed "+ er.parsedPattern + (pos+1 >= inPattern.length ? " at EOL" : " next char is '" + peek() + "'") + " capturesClosed: " + this.root.capturesClosed + " capture: " + ruleToString(rules[rules.length-1]));
						#end
					}
				case ")": // Grouping End
					if(inClass) {
						rules.push(MatchCharCode(0x29));
					} else {
						if(orLevel > 0) {
							pos--;
							break;
						}
						this.root.capturesClosed++;
						if(!isRoot()) {
							atEndMarker = true;
							break;
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
							tok();
						}
						var extras = new Array<ERegMatch>();
						while(true) {
							switch(peek()) {
							case "-", "]":
								extras.push(MatchCharCode(Std.ord(tok())));
							default: break;
							}
						}
						tok();
						#if DEBUG_PARSER
							var sp = pos;
							trace(">>> "+traceName()+" START CLASS FROM orLevel " + orLevel);
						#end

						var rs = parse(inPattern, pos, orLevel, true);
						pos += rs.bytes - 1;

						#if DEBUG_PARSER
							trace(">>> Next char is at "+(pos+1)+" char: " + peek());
						#end

						for(r in extras)
							rs.rules.push(r);
						rules.push(mergeClassRules(rs.rules, not));
						checkQuantifier();

						#if DEBUG_PARSER
							trace(">>> "+traceName()+" END CLASS AT orLevel " + orLevel + " class consumed " + rs.bytes + " bytes: " + inPattern.substr(sp, rs.bytes) + " current rules: " + rulesToString(rules));
						#end
					}
				case "]": // Character class end
					if(!inClass) {
						rules.push(MatchCharCode(0x5D));
					} else {
						#if DEBUG_PARSER_V
							trace("reached character class end at pos: "+pos+" orLevel: " + orLevel);
						#end
						if(expectRangeEnd)
							throw expected("end of character range");
						atEndMarker = true;
						if(orLevel > 0) {
							pos--;
							break;
						}
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
				case "?":
					if(!inClass && !isRoot() && pos == 0) {
						var c : String = tok();
						switch(c) {
						case "P": // named pattern
							c = tok();
							switch(c) {
							case "=":
								var name = consumeAlNum(true, true);
								try {
									var er = findNamedGroup(name);
									rules.push(BackRef(er.groupNumber));
								} catch(e:Dynamic) {
									throw error(Std.string(e));
								}
							case "<":
								var name = consumeAlNum(true, true);
								c = tok();
								if(c == null || c != ">")
									throw expected("> to terminate named group");
								try {
									registerNamedGroup(this, name);
								} catch(e : Dynamic) {
									throw error(e);
								}
							default:
								throw unexpected("extended pattern identifier " + c);
							}
						}
					} else {
						rules.push(createMatchCharCode(Std.ord(curchar)));
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

			checkQuantifier();

		} // while(pos < patternLen - 1 && !atEndMarker)

		rules = compactRules(rules, ignoreCase);
		#if DEBUG_PARSER
		var msg =
			orLevel > 0 ?
				"RETURNING from orLevel " + Std.string(orLevel) + " @" + traceName():
				inClass ?
					"RETURNING from class parser in " + traceName() :
					"RETURNING FROM " + traceName();
		trace(msg + (orLevel > 0 ? "" : " rules: " + rulesToString(rules) + " captures opened:" + root.capturesOpened + " closed:" + root.capturesClosed));
		#end
		return {
			bytes : pos - startPos + 1,
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

	static inline function isNumericChar(s : String) {
		return
			if(s == null || s.length == 0)
				throw "null number";
			else {
				var c = Std.ord(s);
				(c >= 48 && c <= 57);
			}
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

	static inline function isOctalDigitChar(c : Null<Int>) : Bool {
		return
			if(c == null)
				throw "null octal char";
			else
				(c >= 0x30 && c <= 0x37);
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
			case Frame(_,_,_,_), ChildFrame(_,_,_,_):
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
			case MatchWordBoundary, NotMatchWordBoundary, BackRef(_):
				throw "internal error";
			}
		}
		if(not)
			return MatchNoneOf(h);
		else
			return MatchAnyOf(h);
	}


	function traceFrames() {
	#if DEBUG_MATCH_V
		var eregs = new Array<RegEx>();
		var p = this;
		while(p != root) {
			eregs.push(p);
			p = p.parent;
		}
		if(!isRoot())
			eregs.push(root);
		eregs.reverse();
		for(e in eregs)	{
			neko.Lib.println(e.traceName());
			for(i in e.frameStack)
				neko.Lib.println("\t" + ruleToString(i));
		}
	#end
	}

	/**
		Called from a child to add a ChildFrame marker to the stack
	**/
	function addChildFrame( id:Int, r : RegEx, childEs : ExecState) {
		// todo
		// check if it would actually be a valid match at our position?
		var curEs = copyExecState(es);
		frameStack.push( ChildFrame(id, r, childEs, curEs) );
		if(!isRoot())
			parent.addChildFrame(id, this, curEs);
	}

	function pushFrame(pos : Int, rule : ERegMatch, info:Dynamic) : Void {
		var id = root._frameIdx++;
		frameStack.push(Frame(id, pos, rule, info));
		if(!isRoot())
			parent.addChildFrame(id, this, copyExecState(es));
		#if DEBUG_MATCH_V
		neko.Lib.println("pushFrame frame dump:");
		traceFrames();
		#end
	}


	function popFrame() : ERegMatch {
		if(frameStack.length == 0)
			return null;
		var rv = frameStack.pop();
		if(!isRoot()) {
			var id : Int = 0;
			switch(rv) {
			case Frame(iid,_,_,_), ChildFrame(iid,_,_,_):
				id = iid;
			default: throw "internal error";
			}
			parent.removeFrame(id);
		}
		return rv;
	}

	function removeFrame(id : Int) {
		if(!isRoot())
			parent.removeFrame(id);
		// start from end since most likely to be near end of stack
		var i = frameStack.length - 1;
		while(i >= 0) {
			var found = false;
			switch(frameStack[i]) {
			case Frame(iid,_,_,_), ChildFrame(iid,_,_,_):
				if(iid == id)
					found = true;
			default: throw "internal error";
			}
			if(found) {
				frameStack.splice(i,1);
				break;
			}
			i--;
		}
	}

	function rewindStackLength(len: Int) {
		while(frameStack.length > len)
			popFrame();
	}

	/**
		Registers a named group [(?P<name>)]. Groups must start with
		an alpha char, followed by [a-z0-9_]*
		@throws String if group already registered
	**/
	function registerNamedGroup(e : RegEx, name : String) {
		if(root.namedGroups.exists(name))
			throw "group with name " + name + " already exists";
		root.namedGroups.set(name, e);
	}

	function findNamedGroup(name : String) : RegEx {
		if(!root.namedGroups.exists(name))
			throw "group with name " + name + " does not exist";
		return root.namedGroups.get(name);
	}

// 	function findNamedGroupMatch(name : String) {
// 		var e = findNamedGroup(name);
// 		if(root.matches[e.groupNumber] == null)
// 			throw "group " + name + " (id: "+e.groupNumber+") has no match registered";
// 		return root.matches[e.groupNumber];
// 	}

	public function toString() : String {
		var sb = new StringBuf();
		sb.add("RegEx { group: ");
		sb.add((groupNumber == 0 ? "root" : Std.string(groupNumber)));
		sb.add(", ");
		sb.add("depth: ");
		sb.add(depth);
		sb.add(" rules: ");
		sb.add(rulesToString(rules));
		sb.add(" }");
		return sb.toString();
	}

	public function ruleToString(r : ERegMatch) {
		var ofToString = function(h : IntHash<Bool>) : String {
			var sb = new StringBuf();
			for(i in h.keys())
				sb.addChar(i);
			return sb.toString();
		}
		return switch(r) {
		case MatchCharCode(c):
			"MatchCharCode(" + Std.chr(c) + ")";
		case Or(a, b):
			"Or(" + rulesToString(a) + ", " + rulesToString(b) + ")";
		case Repeat(r, min, max, notGreedy, possessive):
			if(notGreedy)
				"Repeat(min:"+min+", max:"+max+" " + ruleToString(r) + ")";
			else
				"RepeatGreedy(min:"+min+", max:"+max+" " + ruleToString(r) + ")";
		case Capture(e):
			"Capture("+e.toString()+")";
		case Frame(id,srcpos, r, info):
			"Frame(id:"+id+" srcpos:"+srcpos+" rule:" + ruleToString(r) + " info:[object])";
		case ChildFrame(id, e, eExecState, pExecState):
			"ChildFrame(id:"+id+", group:"+e.groupNumber+", groupPos: "+eExecState.iPos+", myPos:"+pExecState.iPos+")";
		case MatchAnyOf(h):
			"MatchAnyOf(" + ofToString(h) + ")";
		case MatchNoneOf(h):
			"MatchNoneOf(" + ofToString(h) + ")";
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