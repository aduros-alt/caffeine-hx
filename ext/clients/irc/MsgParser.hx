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

package clients.irc;

class MsgParser {
	public var msgParts : Array<String>;
	public var numParts : Int;

	public function new() {
		msgParts = new Array();
		numParts = 0;
	}

	public static function parse(str : String) : MsgParser {
		var n = new MsgParser();
		var curPos = 0;
		n.numParts = 3;
		str = StringTools.rtrim(str);
		for(i in 0...3) {
			if( curPos >= str.length)
				return n;
			var pos = str.indexOf(' ', curPos);
			if(pos == 0 || pos == -1)
				pos = str.length;
			n.msgParts[i] = str.substr(curPos, pos-curPos);
			curPos = pos + 1;
		}
		if(curPos < str.length) {
			n.msgParts[3] = str.substr(curPos);
			n.numParts = 4;
		}
		return n;
	}

	public function getCode() : Null<Int> {
		return Std.parseInt(msgParts[1].substr(0,3));
	}

	// :Madrok!damon@10.0.0.30 PRIVMSG #channel :hey ther
	// :Madrok!damon@10.0.0.30 PRIVMSG user :hi
	public function getNickAndHost() : {nick:String, host:String} {
		var p = msgParts[0].substr(1).split("!");
		return { nick:p[0], host:p[1] }
	}

	public function getName() {
		return getNickAndHost().nick;
	}

	public function getHost() {
		return getNickAndHost().host;
	}

	public function getCommand() {
		return msgParts[1];
	}

	public function getText() {
		if(numParts < 4)
			return "";
		return
			if(msgParts[3].charCodeAt(0) == 0x3A)
				msgParts[3].substr(1);
			else
				msgParts[3];
	}

	public function getChannel() {
		return msgParts[2];
	}

	/**
		Split a section of text on the first space character
	**/
	public static function split(s:String,?pos :Int) : {head:String, tail:String} {
		if(pos == null)
			pos = 0;
		var i = s.indexOf(' ', pos);
		if(i == -1)
			return {head:s, tail:null};
		if(i == 0)
			return {head:"", tail: s.substr(1)};
		return {head:s.substr(0,i), tail:s.substr(i+1)};
	}

	/**
		Strips the leading : from text
	**/
	inline public static function asText(s :String) {
		if(s.charAt(0) == ":") s = s.substr(1);
		return s;
	}
}