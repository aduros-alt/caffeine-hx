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

//http://www.irchelp.org/irchelp/rfc/rfc.html
//http://www.faqs.org/rfcs/rfc2812.html
class Connection {
	public static var client : String = "hAxe/IRC";
	public static var version : String = "0.1 <> http://caffeine-hx.googlecode.com/";

	public var connected(default,null) : Bool;
	public var loggedIn(default,null) : Bool;
	public var nickname(default, setNickName) : String;
	public var autoReconnect : Bool;

	var host : String;
	var port : Int;
	var username : String;
	var email : String;
	var sock : neko.net.Socket;

	var writer : neko.vm.Thread;
	var reader : neko.vm.Thread;
	var minReadBufferSize : Int;
	var maxReadBufferSize : Int;

	var connectedChannels : Hash<Bool>;

	public function new(host:String, port : Int, username :String, email : String, nickname : String) {
		this.host = host;
		this.port = port;
		this.username = username;
		this.email = email;
		this.nickname = nickname;

		minReadBufferSize = 1 << 10;
		maxReadBufferSize = 1 << 16;
		autoReconnect = true;
		connectedChannels = new Hash();
	}

	/**
		Takes an array of nicks with possible @ (ops) and + (voice) characters, returning
		clean nicknames with 'type' set to "normal", "op" or "voice".
	**/
	public function cleanNicks(nicks:Array<String>) : Array<{type: String, name:String}>
	{
		var rv = new Array();
		for(i in nicks) {
			if(i.charAt(0) == "@")
				rv.push({type:"op", name:i.substr(1)});
			else if(i.charAt(0) == "+")
				rv.push({type:"voice", name:i.substr(1)});
			else
				rv.push({type:"normal", name:i});
		}
		return rv;
	}
	/**
		Connect to server.
	**/
	public function connect() {
		if(connected)
			throw "already connected";
		sock = new neko.net.Socket();
		sock.setTimeout(8);
		try {
			sock.connect(new neko.net.Host(host), port);
			sock.setBlocking(true);
			sock.setTimeout(null);
		}
		catch (e : Dynamic) {
			throw "could not connect: " + Std.string(e);
		}
		connected = true;
		reader = neko.vm.Thread.create(callback(readThread, sock));
		writer = neko.vm.Thread.create(callback(writeThread, sock));

		send("USER " + username + " host ip :" + email);
		setNickName(nickname);
	}

	/**
		Disconnect from the server. The optional msg will send a disconnection
		message. [sendEvent] if true will cause an onDisconnect() event to fire.
	**/
	public function disconnect(?msg : String, ?sendEvent:Bool) {
		if(msg == null)
			msg = "I don't know why.";
		if(connected) {
			send ( "QUIT :" + msg);
			try {sock.shutdown(true,true);} catch(e:Dynamic) {}
			try { sock.close(); } catch(e:Dynamic) {}
		}
		connected = false;
		loggedIn = false;
		if(sendEvent)
			onDisconnect();
		if(autoReconnect) {
			neko.Sys.sleep(1);
			connect();
		}
	}

	/**
		Write a message to a channel using NOTICE
	**/
	public function channelNotice(channel : String, text : String) {
		send("NOTICE "+channel+" :"+text);
	}

	/**
		Set the mode on a channel.<br />
		Parameters: <channel> {[+|-]|o|p|s|i|t|n|b|v} [<limit>] [<user>] [<ban mask>]<br />
		o - give/take channel operator privileges;<br />
		p - private channel flag;<br />
		s - secret channel flag;<br />
		i - invite-only channel flag;<br />
		t - topic settable by channel operator only flag;<br />
		n - no messages to channel from clients on the outside;<br />
		m - moderated channel;<br />
		l - set the user limit to channel;<br />
		b - set a ban mask to keep users out;<br />
		v - give/take the ability to speak on a moderated channel;<br />
		k - set a channel key (password).
	**/
	public function channelMode(channel : String, mode : String, ?extraData:String) {
		if(extraData != null)
			extraData = " " + extraData;
		else
			extraData = "";
		send("MODE "+ channel + " " + mode + extraData);
	}

	/**
		Write a message to a channel
	**/
	public function channelWrite(channel : String, text : String) {
		send("PRIVMSG "+channel+" :"+text);
	}

	/**
		Return current nickname in use.
	**/
	public function getNickName() : String {
		return nickname;
	}

	/**
		Give user ops in channel
	**/
	public function giveOps(channel : String, username : String) {
		channelMode(channel, "+o", username);
	}

	/**
		Give user voice in channel
	**/
	public function giveVoice(channel : String, username : String) {
		channelMode(channel, "+v", username);
	}

	/**
		Join a channel.
	**/
	public function join(channel:String) {
		if(connected) {
			send("JOIN "+channel);
			connectedChannels.set(channel, true);
		}
	}

	public function kick(channel : String, username : String, reason: String) {
		send("KICK "+ channel + " "+username + " :" + reason);
	}

	/**
		Remove user ops in channel
	**/
	public function removeOps(channel : String, username : String) {
		channelMode(channel, "-o", username);
	}

	/**
		Remove user voice in channel
	**/
	public function removeVoice(channel : String, username : String) {
		channelMode(channel, "-v", username);
	}

	/**
		Send raw text to server, not a message. Will add carriage return/linefeed.
	**/
	public function send(msg: String) {
		writer.sendMessage({ text : msg + "\r\n"});
	}

	/**
		Send raw text to server without appending \r\n
	**/
	public function sendRaw(msg: String) {
		writer.sendMessage({ text : msg });
	}

	/**
		Change nick. On success, onNickOk() is called. Failed attempts generate onNickFailed() event.
	**/
	public function setNickName(v:String) : String {
		if(connected)
			send("NICK " + v);
		this.nickname = v;
		return v;
	}

	/**
		Set channel topic
	**/
	public function setTopic(channel:String, topic:String) {
		send("TOPIC " + channel + " :"+topic);
	}

	/**
		Private message a user using NOTICE
	**/
	public function userNotice(username : String, text : String) {
		send("NOTICE "+username+" :"+text);
	}

	/**
		Private message a user.
	**/
	public function userWrite(username : String, text : String) {
		send("PRIVMSG "+username+" :"+text);
	}


	///////////////////////////////////////////////
	//              Callbacks                    //
	///////////////////////////////////////////////

	/** User 'performed' action **/
	public dynamic function onAction(channel:String, user:String, host:String, msg:String) {}
	/** **/
	public dynamic function onAuthNick(nick:String, auth:String) {}
	/** Channel notice **/
	public dynamic function onChannelNotice(channel:String,name:String,host:String, text:String) {}
	/** successful connection and login **/
	public dynamic function onConnect() {}
	/** ctcp, not including VERSION or ACTION **/
	public dynamic function onCtcp(user:String, host:String, msg:String) {}
	/** Lost connection **/
	public dynamic function onDisconnect() {}
	/** Invited to channel **/
	public dynamic function onInvited(channel:String, byNick:String,host:String) {}
	/**	Someone has joined channel **/
	public dynamic function onJoin(channel:String, nick:String, host:String) {}
	/** attempt to join channel has failed **/
	public dynamic function onJoinFailed(channel:String, reason:String) {}
	/** user was kicked from channel (could be any user) **/
	public dynamic function onKicked(channel:String, user:String, host:String, reason:String) {}
	/** Channel mode has changed **/
	public dynamic function onMode(channel:String, user:String, host:String, mode:String, extra:String) {}
	/** User changed their nick **/
	public dynamic function onNickChanged(oldNick:String, newNick:String) {}
	/** Change to nickname failed. Can occur before onConnect() **/
	public dynamic function onNickFailed() {}
	/** Change to nickname accepted. Can occur before onConnect() **/
	public dynamic function onNickOk() {}
	/** Attempt to perform an Op command on channel without op privileges **/
	public dynamic function onNoOpPrivileges(chanel:String, msg:String) {}
	/** Private notice **/
	public dynamic function onNotice(name:String,host:String, text:String) {}
	/**	Someone left a channel	**/
	public dynamic function onPart(channel:String, nick:String, host:String, partMessage:String) {}
	/** regular text in channel **/
	public dynamic function onText(channel:String, user:String, host:String, msg:String) {}
	/** topic was changed **/
	public dynamic function onTopicChanged(channel:String, user:String, host:String, newTopic:String) {}
	/** Fired when a channel is joined **/
	public dynamic function onUsernames(chan:String, userNames:Array<String>) {}
	/** End of list of names for channel. **/
	public dynamic function onUsernamesEnd(channel:String) {}
	/** response to whois, ip info part **/
	public dynamic function onWhoisInfo(nick:String,ipInfo:String) { } // 311
	/** response to whois, what server they are connected to **/
	public dynamic function onWhoisServer(nick : String, serverinfo:String) { } // 312
	/** response to whois, idle and signon times **/
	public dynamic function onWhoisIdle(nick:String, idle:Int, signonTime:Float) { } // 317
	/** end of whois for nick **/
	public dynamic function onWhoisEnd(nick:String) { } // 318
	/** response to whois, channels user is connected to **/
	public dynamic function onWhoisChannels(nick:String, channels:String) { } // 319
	/** user has quit **/
	public dynamic function onQuit(user:String, host:String, quitMsg:String) {}

	///////////////////////////////////////////////
	//           Internals                       //
	///////////////////////////////////////////////
	function writeThread(s:neko.net.Socket) {
		while(true) {
			var msg = neko.vm.Thread.readMessage(true);
			if(sock == null || !connected) {
				trace("*** irc write thread shutdown");
				disconnect();
				return;
			}
			if(msg.text == null) {
				if(msg.shutdown == true) {
					trace("*** irc write thread shutdown");
					return;
				}
				trace("writeThread got null text in : " + Std.string(msg));
				continue;
			}
			try {
				s.write(msg.text);
			}
			catch(e:Dynamic) {
				trace(here.methodName + " " + Std.string(e));
				disconnect();
				return;
			}
		}
	}

	function readThread(s:neko.net.Socket) {
		var buffer =  neko.Lib.makeString(minReadBufferSize);
		var bytes : Int = 0;
		var lastPos : Int = 0;
		while(true) {
			//trace(here.methodName+ " bytes: " + bytes + " lastPos: "+ lastPos);
			var available = buffer.length - bytes;
			if( available == 0 ) {
				var newsize = buffer.length * 2;
				if( newsize > maxReadBufferSize ) {
					newsize = maxReadBufferSize;
					if( buffer.length >= maxReadBufferSize ) {
						disconnect();
						throw "Max buffer size reached";
					}
				}
				var newbuf = neko.Lib.makeString(newsize);
				neko.Lib.copyBytes(newbuf, 0, buffer, 0, bytes);
				buffer = newbuf;
				available = newsize - bytes;
			}
			try {
				bytes += s.input.readBytes(buffer, bytes, available);
			}
			catch( e : Dynamic ) {
				//trace(here.methodName + " " + Std.string(e));
				if( Std.is(e, neko.io.Eof) || Std.is(e,neko.io.Error)) {
					disconnect("lost connection", true);
					try {writer.sendMessage({text:null, shutdown:true});}
					catch(e:Dynamic) {}
					trace("*** irc read thread shutdown");
					return;
				}
				trace(e);
				continue;
			}

			var pos = 0;
			var found = false;
			while(bytes > 0) {
				pos = buffer.indexOf("\n", lastPos);
				if(pos == -1 || pos >= lastPos + bytes)
					break;

				found = true;
				var len = pos - lastPos + 1;
				var trim = 1;
				if(buffer.charCodeAt(lastPos + len - 2) == 0x13)
					trim ++;

				if(len - trim > 0) {
					var rv : String = neko.Lib.makeString(len - trim);
					neko.Lib.copyBytes(rv, 0, buffer, lastPos, len - trim);
					try {
						handleMessage(rv);
					}
					catch(e:Dynamic) {
						trace("error in irc handleMessage : " + Std.string(e));
						for(i in haxe.Stack.exceptionStack()) {
							trace("Called from: " + i);
						}
					}
				}
				pos++;
				bytes -= len;
				lastPos = pos;
			}

			if(!found)
				continue;
			if(pos > 0)
				neko.Lib.copyBytes(buffer, 0, buffer, pos, bytes);
			pos = 0;
			lastPos = 0;
		}
	}


	public function handleMessage( msg : String ) : Void {
		//trace(here.methodName + " " + msg);
		if(msg == null) {
			return;
		}
		var parsed = MsgParser.parse(msg);
		if(msg.substr(0,4) == "PING") {
			sendRaw("PONG isAClassicGame\n");
			return;
		}
		var handled = true;
		switch(parsed.getCode()) {
		case null, 0:
			handled = false;
		////////////////////
		//  WHOIS/WHOWAS  //
		////////////////////
		case 311, 314: // RPL_WHOISUSER "<nick> <user> <host> * :<real name>"
					   // RPL_WHOWASUSER "<nick> <user> <host> * :<real name>"
			var ht = MsgParser.split(parsed.msgParts[3]);
			onWhoisInfo(ht.head, ht.tail);
		case 312: // RPL_WHOISSERVER "<nick> <server> :<server info>"
			var ht = MsgParser.split(parsed.msgParts[3]);
			onWhoisServer(ht.head, ht.tail);
		case 317: // RPL_WHOISIDLE "<nick> <integer> :seconds idle"
			var ht = MsgParser.split(parsed.msgParts[3]);
			// UserNick [2086 1212415055 :seconds idle, signon time]
			var nick = ht.head;
			ht = MsgParser.split(ht.tail);
			var idle = Std.parseInt(ht.head);
			ht = MsgParser.split(ht.tail);
			onWhoisIdle(nick, idle, Std.parseFloat(ht.head));
		case 318: // RPL_ENDOFWHOIS "<nick> :End of /WHOIS list"
			var ht = MsgParser.split(parsed.msgParts[3]);
			onWhoisEnd(ht.head);
		case 319: // RPL_WHOISCHANNELS "<nick> :{[@|+]<channel><space>}"
			var ht = MsgParser.split(parsed.msgParts[3]);
			onWhoisChannels(ht.head, ht.tail);

		////////////////////
		//   User NAMES   //
		////////////////////
		case 353: // RPL_NAMREPLY "<channel> :[[@|+]<nick> [[@|+]<nick> [...]]]"
			var ht = MsgParser.split(parsed.msgParts[3]);
			ht = MsgParser.split(ht.tail);
			var chan = ht.head;
			var users = ht.tail.substr(1).split(' ');
			onUsernames(chan, users);
		case 366: // RPL_ENDOFNAMES "<channel> :End of /NAMES list"
			var ht = MsgParser.split(parsed.msgParts[3]);
			onUsernamesEnd(ht.head);
		////////////////////
		//  Connect/MOTD  //
		////////////////////
		//case 372: // motd line
		//case 375: // start motd
		case 376: // end of motd
			loggedIn = true;
			onConnect();

		////////////////////
		// NICK / AUTHNICK//
		////////////////////
		case 330: // auth
			var ht = MsgParser.split(parsed.msgParts[3]);
			var ht2 = MsgParser.split(ht.tail);
			onAuthNick(ht.head, ht2.head);
		case 433: // nick failed
			onNickFailed();

		////////////////////
		////////////////////
		case 404: // Cannot send to channel (no external messages)
		case 473: // failed attempt at channel join
			var ht = MsgParser.split( parsed.msgParts[3]);
			connectedChannels.remove(ht.head);
			onJoinFailed(ht.head, MsgParser.asText(ht.tail));
		case 482: // Failed, chanops required for command
			var ht = MsgParser.split( parsed.msgParts[3]);
			onNoOpPrivileges(ht.head, MsgParser.asText(ht.tail));
		default:
			return;
		}
		if(handled)
			return;

		switch(parsed.getCommand()) {
		case "PRIVMSG":
			var nh = parsed.getNickAndHost();
			var soh = Std.chr(1);
			var text = parsed.msgParts[3];
			if(text == null) {
				trace("PRIVMSG null text from: "+ msg);
				return;
			}
			if(text.indexOf(soh + "ACTION") >= 0) {
				var ht = MsgParser.split(parsed.msgParts[3]);
				onAction(parsed.getChannel(), nh.nick, nh.host, ht.tail);
			}
			else if(text.indexOf(soh + "VERSION") >= 0) {
				var n = parsed.getName();
				if(n != "") {
					send("NOTICE " + n + " :" + Std.chr(1) + Connection.client + " " + Connection.version);
					return;
				}
				else {
					trace("Unhandled " + parsed);
				}
			}
			else if(text.indexOf(soh) >= 0) {
				if(parsed.getChannel() != getNickName()) {
					text = text.substr(text.indexOf(soh) + 1);
					onCtcp(nh.nick, nh.host, text);
				}
				else {
					trace("Unhandled " + parsed);
				}
			}
			else {
				onText(parsed.getChannel(), nh.nick, nh.host, parsed.getText());
			}
		case "INVITE":
			var nh = parsed.getNickAndHost();
			onInvited(parsed.getText(), nh.nick, nh.host);
		case "NICK":
			var nh = parsed.getNickAndHost();
			if(nh.nick == getNickName())
				onNickOk();
			else
				onNickChanged(nh.nick, parsed.msgParts[2]);
		case "PART":
			onPart(parsed.getChannel(), parsed.getName(), parsed.getHost(), parsed.getText());
		case "JOIN":
			var nh = parsed.getNickAndHost();
			var chan = parsed.getChannel();
			if(chan.charAt(0) == ":")
				chan = chan.substr(1);
			onJoin(chan, nh.nick, nh.host);
		case "QUIT":
			var nh = parsed.getNickAndHost();
			onQuit(nh.nick, nh.host, parsed.getText());
		case "NOTICE":
			var nh = parsed.getNickAndHost();
			if(parsed.getChannel() == getNickName())
				onNotice(nh.nick, nh.host, parsed.getText());
			else
				onChannelNotice(parsed.getChannel(), nh.nick, nh.host, parsed.getText());
		case "KICK":
			var nh = parsed.getNickAndHost();
			var ht = MsgParser.split(parsed.msgParts[3]);
			onKicked(parsed.getChannel(), nh.nick, nh.host, MsgParser.asText(ht.tail));
		case "MODE":
			var nh = parsed.getNickAndHost();
			var ht = MsgParser.split(parsed.msgParts[3]);
			onMode(parsed.getChannel(), nh.nick, nh.host,ht.head, ht.tail);
		case "TOPIC":
			var nh = parsed.getNickAndHost();
			onTopicChanged(parsed.getChannel(), nh.nick, nh.host, parsed.getText());
		}
		return;
	}

}
