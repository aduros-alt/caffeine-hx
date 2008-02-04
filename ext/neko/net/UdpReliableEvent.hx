/*
* Copyright (c) 2008, Russell Weir, The haXe Project Contributors
* All rights reserved.
*
* Redistribution and use in source and binary forms, with or without modification, are permitted
* provided that the following conditions are met:
*
* - Redistributions of source code must retain the above copyright notice, this list of conditions
*  and the following disclaimer.
* - Redistributions in binary form must reproduce the above copyright notice, this list of conditions
*  and the following disclaimer in the documentation and/or other materials provided with the distribution.
* - Neither the name of the author nor the names of its contributors may be used to endorse or promote
*  products derived from this software without specific prior written permission.
*
* THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
* "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
* LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
* A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
* CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
* EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
* PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
* PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
* LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
* NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
* SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

package neko.net;

import neko.net.UdpReliableSocket.UdprHostPointer;

enum UdprEvent {
}

enum UdprEventType {
	NONE;
	CONNECT;
	DISCONNECT;
	RECEIVE;
}

class UdpReliableEvent {
	var __e : UdprEvent;
	public static var EVENT_TYPE_NONE		: Int = 0;
	public static var EVENT_TYPE_CONNECT	: Int = 1;
	public static var EVENT_TYPE_RECEIVE	: Int = 2;
	public static var EVENT_TYPE_DISCONNECT	: Int = 3;

	public var type(default, null) 		: UdprEventType;
	public var peer(default, null)		: UdpReliableSocket;
	public var channel(default,null)	: Int;
	public var data						: String;
	public var hndPeer(default,null)	: Int;
	public var seqno					: Int;
	public var pollflag					: Bool;

	public function toString() : String {
		var sb : StringBuf = new StringBuf();
		sb.add("{");
		sb.add("type: ");
		sb.add(type);
		sb.add(",hndPeer: ");
		sb.add(hndPeer);
		sb.add(",data: ");
		sb.add(data);
		sb.add(",seqno: ");
		sb.add(seqno);
		sb.add(",pollflag: ");
		sb.add(pollflag);
		sb.add(", channel: ");
		sb.add(channel);
		sb.add(", data: ");
		if(data.length > 20) {
			sb.add(data.substr(0,20));
			sb.add(" ...");
		}
		else
			sb.add(data);
		sb.add("}");
		return sb.toString();
	}

	public function new(?evt) {
		type = NONE;
		channel = -1;
		data = "";
		pollflag = false;

		if(evt != null) {
			__e = evt;
			hndPeer = udpr_event_peer_idx(__e);
			var t : Int = udpr_event_type(__e);
			switch(t) {
			case EVENT_TYPE_NONE:
				type = NONE;
			case EVENT_TYPE_CONNECT:
				type = CONNECT;
			case EVENT_TYPE_RECEIVE:
				type = RECEIVE;
				data = new String(udpr_event_data(__e));
				channel = udpr_event_channel(__e);
			case EVENT_TYPE_DISCONNECT:
				type = DISCONNECT;
			}
			free_enetevent(evt);
			__e = null;
		}
	}

	public function setPeer(p : UdpReliableSocket) {
		peer = p;
// debug
		if(hndPeer != p.hndPeer) {
			p.logFatalError("Peer handle not equal "+hndPeer + " vs "+p.hndPeer);
		}
// /debug
		hndPeer = p.hndPeer;
		seqno = Reflect.field(peer,"_seqno");
	}

	public static function evt_disconnect( p : UdpReliableSocket) : UdpReliableEvent {
		var e = new UdpReliableEvent(null);
		e.peer = p;
		e.hndPeer = p.hndPeer;
		e.type = DISCONNECT;
		return e;
	}

	public static function evt_none(p : UdpReliableSocket) : UdpReliableEvent {
		var e = new UdpReliableEvent(null);
		e.peer = p;
		e.hndPeer = p.hndPeer;
		e.type = NONE;
		return e;
	}

	//private static var udpr_event_get = neko.Lib.load("udprsocket","udpr_event_get",2);
	private static var udpr_event_data = neko.Lib.load("udprsocket","udpr_event_data",1);
	private static var udpr_event_type = neko.Lib.load("udprsocket","udpr_event_type",1);
	private static var udpr_event_channel = neko.Lib.load("udprsocket","udpr_event_channel",1);
	private static var udpr_event_peer_idx = neko.Lib.load("udprsocket","udpr_event_peer_idx",1);
	private static var free_enetevent = neko.Lib.load("udprsocket","free_enetevent",1);
}

