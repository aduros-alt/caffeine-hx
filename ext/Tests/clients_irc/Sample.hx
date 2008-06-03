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

import clients.irc.Connection;

class Sample {
	static var ircHost:String = "irc.freenode.net";
	//static var ircHost:String = "localhost";
	static var ircPort : Int = 6667;
	static var ircNicks : Array<String> = ["Madrok_HaxeIRC", "_Madrok_HaxeIRC", "__Madrok_HaxeIRC"];
	public static function main() {
		var s = new Sample();
	}

	var irc : Connection;
	public function new() {
		irc = new Connection(ircHost, ircPort, "hxirc", "email@some.host", ircNicks[0]);

		irc.onConnect = onConnect;
		irc.onNickFailed = onNickFailed;
		irc.onJoinFailed = onJoinFailed;
		irc.onText = onText;
		irc.onNotice = onNotice;
		irc.onChannelNotice = onChannelNotice;
		irc.onAction = onAction;

		irc.connect();
		while(irc.connected) {}
		trace("EXIT");
	}

	public function onConnect() {
		trace("Connected as " + irc.nickname);
		irc.join("#haxe");
	}

	public function onNickFailed() {
		if(irc.connected && !irc.loggedIn) {
			if(ircNicks.length == 0) {
				irc.disconnect(null, false);
				throw "Exhausted nicknames, can't connect. Edit source code! ;)";
			}
			irc.nickname = ircNicks.shift();
		}
	}

	public function onJoinFailed(chan, reason) {
		neko.Lib.println("Unable to join "+chan + " : " + reason);
	}

	public function onText(channel, user, host, msg) {
		neko.Lib.println(channel + " "+user+"["+host+"]> " + msg);
	}

	public function onNotice(nick, host,text) {
		trace(here.methodName);
		trace(nick + " " + host + " " + text);
		irc.channelWrite("#haxe", "I've been noticed by "+nick);
	}

	public function onChannelNotice(channel, nick, host, text) {
		trace(here.methodName);
		trace(channel + " " + nick + " " + host + " " + text);
	}

	function onAction(chan,nick,host,text) {
		trace("ACTION: " +nick + " " + text + " in "+chan);
	}
}
