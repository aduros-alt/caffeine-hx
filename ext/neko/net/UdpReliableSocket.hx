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
import neko.net.UdpReliableEvent.UdprEventType;
import neko.net.Socket.SocketHandle;
import neko.io.Error;

enum UdprHostPointer {
}

enum UdprPeerPointer {
}

enum UdprSocketType {
	UNKNOWN;
	CLIENT;
	SERVER;
	PEER;
}

enum UdprSocketState {
	DISCONNECTED;
	CONNECTING;
	CONNECTED;
	DISCONNECTING;
	ZOMBIE;
}
//switch(s._state) {
//case DISCONNECTED:
//case CONNECTING:
//case CONNECTED:
//case DISCONNECTING:
//case ZOMBIE:
//}
private typedef ThreadInfo = {
	var thread : neko.vm.Thread;
	var host : UdpReliableSocket;
}
private typedef ExpiredSocket = {
	var timeout: Float;
	var socket: UdpReliableSocket;
}

private enum ThreadMsgType {
	// sent by clients reading or select()ing
	//MSG_CONNECT;
	MSG_SCONNECT;
	//MSG_CONNECT_CALLBACK;
	MSG_READ;
	MSG_READ_BLOCK;
	MSG_WRITE;
	MSG_SELECT_BLOCK;
	MSG_SELECT_WAIT;
	MSG_ACCEPT;
	MSG_ACCEPT_BLOCK;
	MSG_DISCONNECT_WAIT;
	MSG_DISCONNECT_NOW;
	// sent back by worker
	MSG_EVENT_RECEIVED;
	MSG_EVENT_TIMEOUT;
	MSG_ERROR;
	// sent by manager thread
	MSG_SHUTDOWN;
}
	//case MSG_CONNECT:
	//case MSG_CONNECT_CALLBACK:
	//case MSG_READ:
	//case MSG_READ_BLOCK:
	//case MSG_WRITE:
	//case MSG_SELECT_BLOCK:
	//case MSG_SELECT_WAIT:
	//case MSG_ACCEPT:
	//case MSG_ACCEPT_BLOCK:
	//case MSG_DISCONNECT_WAIT:
	//case MSG_DISCONNECT_NOW:
	//// sent back by worker
	//case MSG_EVENT_RECEIVED:
	//case MSG_EVENT_TIMEOUT:
	//case MSG_ERROR:
	//// sent by manager thread
	//case MSG_SHUTDOWN:

private class ThreadMsg {
	public var thread: neko.vm.Thread;
	public var type: ThreadMsgType;
	public var peers: Array<UdpReliableSocket>;
	public var timeout: Float;
	public var event: UdpReliableEvent;
	// for read and write
	public var channel : Int;
	// for writes
	public var data : String;
	// for connects
	public var host: neko.net.Host;
	public var port : Int;
	public var channels : Int;
	public var onConnect : UdpReliableSocket -> Void;	// notify callback for success. Called before select() returns the socket
	public var onFailed : UdpReliableSocket -> Void;	// notify callback on connection failed
	public var custom : Dynamic; 						// will be transferred to the socket

	public function new( thread : neko.vm.Thread,
			type : ThreadMsgType,
			peers : Array<UdpReliableSocket>,
			timeout : Float,
			event : UdpReliableEvent
		)
	{
		this.thread = thread;
		this.type = type;
		this.peers = peers;
		this.timeout = Date.now().getTime() + (timeout * 1000);
		this.event = event;
		this.channel = -1; // read/write any channel
	}

	public function getPeer() : UdpReliableSocket {
		if(peers == null || peers.length != 1)
			logFatalError(here.methodName);
		return peers[0];
	}

    public function logFatalError(e : Dynamic) {
    	//trace(here.methodName);
		var stack = haxe.Stack.exceptionStack();
		if(stack == null || stack.length == 0)
			stack = haxe.Stack.callStack();
		var estr = try Std.string(e) catch( e2 : Dynamic ) "???" + try "["+Std.string(e2)+"]" catch( e : Dynamic ) "";
        neko.io.File.stderr().write( estr + "\n" + haxe.Stack.toString(stack) );
        neko.io.File.stderr().write(Std.string(this));
        neko.io.File.stderr().flush();
        neko.Sys.exit(1);
    }

    public function toString() : String {
		var s : String = "ThreadMsg {";
		//s = s + "type: " + type + ", timeout: "+timeout+", event: "+event+", peers: "+peers+"}";
		s = s + "type: " + type + ", timeout: "+timeout+", event: "+event+"}";
		return s;
	}
	public function dump() : String {
		var s : String = "ThreadMsg {";
		s = s + "type: " + type + ", timeout: "+timeout+", event: "+event+", peers:";
		for(p in peers) {
			s = s + " " + Reflect.field(p, "_state");
			s = s + " " + Reflect.field(p, "_events");
		}
		s = s + "}";
		return s;
	}
	public static function error(?e) : ThreadMsg {
		var msg = new ThreadMsg(neko.vm.Thread.current(), MSG_ERROR, null, 0.0, null);
		msg.custom = e;
		return msg;
	}
	public static function received(event : UdpReliableEvent) : ThreadMsg {
		return new ThreadMsg(neko.vm.Thread.current(), MSG_EVENT_RECEIVED, null, 0.0, event);
	}
	public static function timeout() : ThreadMsg {
		return new ThreadMsg(neko.vm.Thread.current(), MSG_EVENT_TIMEOUT, null, 0.0, null);
	}

}

class UdpReliableSocket implements neko.net.Socket {
	private var __s							: SocketHandle; // not used, satisy implements

	private var __h 						: UdprHostPointer; // SERVER, CLIENT
	public var __p(default, null)			: UdprPeerPointer; // PEER
	var _udprsHost							: UdpReliableSocket; // PEER
	public var seqno(default,null)			: Int;

	private var _type						: UdprSocketType;
	private var _host						: neko.net.Host;
	private var _port						: Int;
    private var _connections				: Int;
	private var _state						: UdprSocketState;
	private var _blocking					: Bool;

    private var _events						: List<UdpReliableEvent>;
    private var _messages					: List<ThreadMsg>;

	public var channels(default,setChannels)			: Int;
	public var defaultChannel(default,setDefaultChannel): Int;
	public var maxBpsIn(default, null)					: Int;
	public var maxBpsOut(default, null)					: Int;
    public var input(default,null)						: SocketInput;
    public var output(default,null)						: SocketOutput;
    private var timeout									: Float;

    public var custom 									: Dynamic;

	var worker											: neko.vm.Thread;
	public var peers									: Array<UdpReliableSocket>;
	var hostLock										: neko.vm.Lock;
	public var hndPeer(default,null)					: Int;

	public function toString() : String {
		var sb : String = "UdpReliableSocket {";
		sb = sb + "seqno: " + seqno + ", ";
		sb = sb + "hndPeer: " + hndPeer + ", ";
		sb = sb + "_type: " + _type + ", ";
		sb = sb + "_state: " + _state + ", ";
		sb = sb + "_blocking: " + _blocking + ", ";
		sb = sb + "_connections: " + _connections + ", ";
		sb = sb + "_events: " + _events + ", ";
		sb = sb + "_messages: " + _messages;
		if(_type == SERVER || _type == CLIENT) {
			sb = sb + ", peers: ";
			for(i in 0..._connections) {
				if(peers[i] != null) {
					sb = sb + "peer["+i+"] :";
					sb = sb + peers[i];
				}
			}
		}
		sb = sb + "}";
		return sb;
	}

	public function dumpMsgQueue(?s : String) {
		neko.Lib.print("*** dumpMsgQueue\n");
		if(s != null)
			neko.Lib.println(s);
		neko.Lib.println("*** queue");
		var x : Int = 1;
		for(msg in _messages) {
			neko.Lib.print("Msg # "+ x + ": " + msg);
			x++;
		}
		neko.Lib.println("***");
	}

	// initialize ndll
	public static function __init__() {
		udpr_init();
	}

	public function new() {
		hostLock = new neko.vm.Lock();
		hostLock.release();
	    initialize();
	    seqno = 0;
	}

	function initialize() {
		//trace(here.methodName);
		//logError("INITIALIZE CALLED");
		reinitialize(true);
		_type = UNKNOWN;
		_connections = updr_max_peers();
		_blocking = true;
		channels = 1;
		defaultChannel = 0;
		maxBpsIn = 0;
		maxBpsOut = 0;
		input = new UdpReliableSocketInput(this);
		output = new UdpReliableSocketOutput(this);
		timeout = 5.0;
		hndPeer = -1;
		__h = null;
		__p = null;
		_udprsHost = null;
	}

	function reinitialize(?tr:Bool) {
		if(!tr)
			logError("RE-INITIALIZE CALLED ON "+_type+" hnd: "+hndPeer);
		if(_type == SERVER || _type == CLIENT) {
			if(worker != null) {
				for(i in peers) {
					if(i != null)
						i.close();
				}
				workerStop();
			}
			worker = null;
			__h = null;
		}
		_host = new neko.net.Host("localhost");
		_port = 0;
		_events = new List();
		_messages = new List();
		getHostLock();
		setState(DISCONNECTED);
		releaseHostLock();
		peers = new Array();
	}

	//////////////////////////////////////////////////////////////
	//  Lock functions
	//////////////////////////////////////////////////////////////
	function lock(idx : Int) {
		if(idx < 0) {
			hostLock.wait();
		}
		else {
			peers[idx].hostLock.wait();
		}
	}
	function unlock(idx : Int) {
		if(idx < 0) {
			hostLock.release();
		}
		else {
			peers[idx].hostLock.release();
		}
	}
	function getHostLock(?timeout) : Bool {
		return hostLock.wait(timeout);
	}
	function releaseHostLock() : Void {
		hostLock.release();
	}

	//////////////////////////////////////////////////////////////
	//  Worker thread functions. Services socket read and write //
	//////////////////////////////////////////////////////////////
	function workerStart() {
		if(worker != null)
			workerStop();
		var h = this;
		var i : ThreadInfo = {
			thread: neko.vm.Thread.current(),
			host: h
		}
		worker = neko.vm.Thread.create(callback(workerLoop, i));
		worker.sendMessage("go");
	}

	function workerStop() {
		var m  = {
			thread : neko.vm.Thread.current(),
			hndPeer : null,
			type : MSG_SHUTDOWN,
			idxPeers : null,
			timeout : 0.0,
			event : null
		}
		try {
			worker.sendMessage(m);
			do {
				m = neko.vm.Thread.readMessage(true);
			} while(m.type != MSG_SHUTDOWN);
		}
		catch(e:Dynamic) {
			logFatalError(e);
		}
	}

	// worker posts messages back to main thread
	// consisting of peer handles and unconnected
	// UdpReliableEvents.
	function workerLoop(t : ThreadInfo) {
		var expiredSockets : List<ExpiredSocket> = new List();
		var selectQueue : List<ThreadMsg> = new List();
		var connectEventList : List<UdpReliableEvent> = new List();
		var acceptMsgQueue : List<ThreadMsg> = new List();
		var outConnects : List<{ sock : UdpReliableSocket, msg : ThreadMsg }> = new List();
		//var expiringMsgCount : Int = 0;
		var doSelect : Bool = false;

		// wait for start msg.
		neko.vm.Thread.readMessage(true);
		//trace("Worker has started");

		var socketEqual = function(a : UdpReliableSocket, b : UdpReliableSocket) {
			if(a.seqno == b.seqno) {
				if(a.hndPeer != b.hndPeer)
					t.host.logFatalError("Peer handles not equal");
				return true;
			}
			return false;
		}
		var respond = function(sourceMsg : ThreadMsg, responseMsg : ThreadMsg) {
			try {
				sourceMsg.thread.sendMessage(responseMsg);
			}
			catch(e:Dynamic) {
				t.host.logError(e);
			}
		}

		var doResponseAccept = function(msg : ThreadMsg) {
			if(msg == null) // debug
				t.host.logFatalError("doResponseAccept null message");
			for(e in connectEventList) {
				//if(e.pollflag) {
					//trace("doResponseAccept");
					if(!connectEventList.remove(e))
						t.host.logFatalError("doResponseAccept");
					var rm = ThreadMsg.received(e);
					respond(msg, rm);
					return true;
				//}
			}
			return false;
		}

		var doConnectOut = function(host:neko.net.Host, port : Int, channels : Int ) : Int {
			var hndPeer : Int;
			if(channels == null || channels < 2)
				channels = 2;
			try {
				var p : UdprPeerPointer = udpr_connect_out(t.host.__h, host.ip, port, channels, t.host.timeoutMilliseconds());
				if(p == null)
					throw Custom("Failed to connect on "+(try host.reverse() catch( e : Dynamic ) host.toString())+":"+port);
				hndPeer = udpr_get_peer_handle(t.host.__h, p);
				//getHostLock();
				//if(peers[0] != null)
					//throw "Bad error";
				//peers[0] = UdpReliableSocket.createPeer(this, udpr_get_peer_pointer(__h, 0), hndPeer);
				//releaseHostLock();
			} catch( s : Dynamic ) {
					if( s == "udprsocket@udpr_connect_out" )
							throw Custom("Failed to connect on "+(try host.reverse() catch( e : Dynamic ) host.toString())+":"+port);
					else
							neko.Lib.rethrow(s);
			}
			return hndPeer;
		}

		/**
			Check incoming thread msg. If invalid, sends an error to calling thread,
			then returns null. If disconnect, notifies calling thread or receipt.
			Returns false if message is not dispatched
		**/
		var handleIncomingMsg = function(msg : ThreadMsg, doQueue : Bool) : Bool {
			//if(doQueue) trace("handleIncomingMsg: " + msg);
			switch(msg.type) {
			/**
				Returns a socket handle (integer) that will be used when the connection completes.
				Starts in state DISCONNECTED, moves to either CONNECTED or ZOMBIE.
				If they exist, the methods onConnect and onFail will be used to notify the
				calling process the status of the connection attempt, and the actual UdpReliableSocket
				class that will be returned on the next select(). These functions should be thread
				safe and very quick, since they will interrupt the worker thread.
			**/
			case MSG_SCONNECT:
				var hnd : Int;
				try {
					hnd = doConnectOut(msg.host, msg.port, msg.channels);
					//trace("Received outgoing handle " + hnd);
				}
				catch(e : Dynamic) {
					t.host.logError(e);
					respond(msg, ThreadMsg.error(e));
					return true;
				}
				var u = new UdpReliableSocket();
				u.hndPeer = hnd;
				u._host = msg.host;
				u._port = msg.port;
				u.custom = msg.custom;
				u._type = PEER;
				u._udprsHost = t.host; // tie it back to host instance
				t.host.seqno++;
				u.seqno = t.host.seqno;
				//if(s._type == CLIENT)
				//	p.setBlocking(s._blocking);
				outConnects.add({sock: u, msg : msg});
				// this msg is the only place where we use NONE. Stores the unbound socket
				respond(msg, ThreadMsg.received(UdpReliableEvent.evt_none(u)));
				return true;
			case MSG_READ:
				if(msg.peers.length != 1) {
					t.host.logError(msg);
					respond(msg, ThreadMsg.error());
					return true;
				}
				//msg.peers[0].dumpMsgQueue(here.methodName + " MSG_READ");
				//trace(msg.peers[0]._events);
				//if(doQueue) {
				//	msg.peers[0].messageAdd(msg);
				//	return true;
				//}
				for(e in msg.peers[0]._events) {
					switch(e.type) {
					case NONE:
					case CONNECT:
					case DISCONNECT:
						respond(msg, ThreadMsg.error());
						return true;
					case RECEIVE:
						if(msg.channel == -1 || e.channel == msg.channel) {
							msg.peers[0]._events.remove(e);
							respond(msg, ThreadMsg.received(e));
							return true;
						}
					}
				}
				respond(msg, ThreadMsg.timeout());
				return true;
			case MSG_READ_BLOCK:
				if(msg.peers.length != 1) {
					t.host.logError(msg);
					respond(msg, ThreadMsg.error());
					return true;
				}
//				trace(here.lineNumber);
//				trace(msg.peers[0]._messages);
//				trace(msg.peers[0]._events);
				for(e in msg.peers[0]._events) {
					switch(e.type) {
					case NONE:
					case CONNECT:
					case DISCONNECT:
						if(!doQueue) {
							//trace(here.lineNumber);
							//msg.peers[0]._events.remove(e);
							respond(msg, ThreadMsg.error());
							return true;
						}
					case RECEIVE:
						//if(doQueue) trace(here.lineNumber);
						if(msg.channel == -1 || e.channel == msg.channel) {
							msg.peers[0]._events.remove(e);
							respond(msg, ThreadMsg.received(e));
							return true;
						}
						else {
							//trace(e.channel);
							//trace(msg.channel);
						}
					}
				}
				if(doQueue) {
					msg.peers[0].messageAdd(msg);
					//msg.peers[0].dumpMsgQueue(here.methodName + " MSG_READ_BLOCK");
					return true;
				}
				//trace(here.lineNumber);
				//trace(msg.peers[0]._events);
				return false;
			case MSG_WRITE:
				if(msg.peers.length != 1) {
					t.host.logError(msg);
					respond(msg, ThreadMsg.error());
					return true;
				}
				switch(msg.peers[0]._state) {
				case DISCONNECTED:
					if(doQueue)
						msg.peers[0].messageAdd(msg);
					return true;
				case CONNECTING:
					if(doQueue)
						msg.peers[0].messageAdd(msg);
					return true;
				case CONNECTED:
					try {
						udpr_write(msg.peers[0].__p, untyped msg.data.__s, msg.channel, true);
						respond(msg, ThreadMsg.received(null));
					} catch(e : Dynamic) {
						t.host.logError(msg);
						respond(msg, ThreadMsg.error());
					}
					//if(msg.data != "Boo" && t.host._type == SERVER && msg.data.length > 3)
						//neko.Sys.exit(2);
					return true;
				case DISCONNECTING:
				case ZOMBIE:
				}
				respond(msg, ThreadMsg.error());
				return true;
			case MSG_SELECT_BLOCK:
				if(!doQueue)
					t.host.logFatalError("MSG_SELECT_BLOCK in client queue");
				//trace(msg);
				//trace(expiredSockets);
				//trace(selectQueue);
				if(msg.peers != null) {
					if(msg.peers.length == 0) {
						msg.type = MSG_SELECT_WAIT;
						msg.timeout = Date.now().getTime();
					}
					//trace(msg.dump());
					selectQueue.add(msg);
				}
				else {
					t.host.logFatalError(msg);
					respond(msg, ThreadMsg.error());
				}
				return true;
			case MSG_SELECT_WAIT:
				if(!doQueue)
					t.host.logFatalError("MSG_SELECT_WAIT in client queue");
				if(msg.peers != null) {
					if(msg.peers.length == 0) {
						//trace("MSG_SELECT_WAIT no peers");
						msg.type = MSG_SELECT_WAIT;
						msg.timeout = Date.now().getTime();
					}
					selectQueue.add(msg);
					//trace(selectQueue);
					//trace(t.host.peers[0]);
				}
				else {
					t.host.logFatalError(msg);
					respond(msg, ThreadMsg.error());
				}
				return true;
			case MSG_ACCEPT:
				if(!doQueue)
					t.host.logFatalError("MSG_ACCEPT in client queue");
				else {
					if(!doResponseAccept(msg))
						acceptMsgQueue.add(msg);
				}
				return true;
			case MSG_ACCEPT_BLOCK:
				if(!doQueue)
					t.host.logFatalError("MSG_ACCEPT_BLOCK in client queue");
				else {

					if(!doResponseAccept(msg))
						acceptMsgQueue.add(msg);
				}
				return true;
			case MSG_DISCONNECT_WAIT:
//NOTE TO SELF::
//When you send a disconnect, no further reading or
//writing is possible, so clear out those events from
//the socket. (handleMsg)
//Also, since the programmer sent a disconnect, it's safe to say
//there won't be any need to keep the socket in the expired list
//after the disconnect event happens. (handleEvent)
				if(doQueue) {
					if(msg.peers.length != 1 || msg.peers[0]._type != PEER) {
						t.host.logError(msg);
						respond(msg, ThreadMsg.error());
						//trace(here.lineNumber);
						neko.Sys.exit(0);
						return true;
					}
					msg.peers[0].getHostLock();
					if(msg.peers[0]._state != DISCONNECTING && msg.peers[0]._state != ZOMBIE) {
						udpr_close_graceful(msg.peers[0].__p);
					}
					else {
						// debug
						trace(msg.peers[0]);
						neko.Sys.exit(10);
					}
					if(msg.peers[0]._state != ZOMBIE) {
						msg.peers[0].setState(DISCONNECTING);
					}
					msg.peers[0].releaseHostLock();
					//for(e in msg.peers[0]._events)
					//	e.pollflag = true;
					msg.peers[0].messageAdd(msg);
					//trace(msg.peers[0]._messages);
					return true;
				}
				for(e in msg.peers[0]._events) {
					switch(e.type) {
					case NONE:
					case CONNECT:
					case DISCONNECT:
						respond(msg, ThreadMsg.received(e));
						return true;
					case RECEIVE:
					}
				}
				return false;
			case MSG_DISCONNECT_NOW:
				if(doQueue) {
					if(msg.peers.length != 1 || msg.peers[0]._type != PEER) {
						t.host.logError(msg);
						respond(msg, ThreadMsg.error());
						return true;
					}

					msg.peers[0].getHostLock();
					if(msg.peers[0]._state != DISCONNECTING && msg.peers[0]._state != ZOMBIE)
						udpr_close_graceful(msg.peers[0].__p);
					if(msg.peers[0]._state != ZOMBIE)
						msg.peers[0].setState(DISCONNECTING);
					msg.peers[0].releaseHostLock();
					//for(e in msg.peers[0]._events)
					//	e.pollflag = true;
					respond(msg, ThreadMsg.timeout());
					return true;
				}
				return false;
			// sent back by worker... these should not arrive here.
			case MSG_EVENT_RECEIVED:
				t.host.logFatalError("MSG_EVENT_RECEIVED");
			case MSG_EVENT_TIMEOUT:
				t.host.logFatalError("MSG_EVENT_TIMEOUT");
			case MSG_ERROR:
				t.host.logFatalError("MSG_EVENT_TIMEOUT");
			// sent by manager thread
			case MSG_SHUTDOWN:
					//trace("*** WORKER SHUTDOWN");
					respond(msg, new ThreadMsg (
						null,
						MSG_SHUTDOWN,
						null,
						0.0,
						null
					));
					return false;
			}
			return false;
		}


		/**
			Checks to see if incoming event can be immediately serviced, returning
			true if so. If not, returns false and event should be queued
		**/
		var handleIncomingEvent = function(e : UdpReliableEvent, cb : UdpReliableEvent->Bool) : Bool {
			//trace("INCOMING EVENT: "+ e.type + " "+ e);
			switch(e.type) {
			case NONE:
				return true;
			case CONNECT:
				t.host.getHostLock();
				if(t.host.peers[e.hndPeer] != null) {
					if(t.host.peers[e.hndPeer]._events.last().type != DISCONNECT) {
						// process disconnect for anything listening to old socket
						//trace("Connect on unexpected state");
						//t.host.peers[e.hndPeer].eventAdd(UdpReliableEvent.evt_disconnect( t.host.peers[e.hndPeer] ));
						cb(UdpReliableEvent.evt_disconnect( t.host.peers[e.hndPeer] ));
						neko.Sys.exit(0);
					}
					t.host.peers[e.hndPeer].getHostLock();
					t.host.peers[e.hndPeer].setState(ZOMBIE);
					t.host.peers[e.hndPeer].releaseHostLock();
					expiredSockets.add({ timeout: Date.now().getTime() + (10.0 * 1000), socket: t.host.peers[e.hndPeer] });
				}
				var found = false;
				// check outgoing connection list
				//trace(outConnects);
				for(p in outConnects) {
					if(p.sock.hndPeer == e.hndPeer) {
						p.sock.__p = udpr_get_peer_pointer(t.host.__h, e.hndPeer);
						t.host.peers[e.hndPeer] = p.sock;
						t.host.peers[e.hndPeer].getHostLock();
						t.host.peers[e.hndPeer].setState(CONNECTING);
						t.host.peers[e.hndPeer]._blocking = t.host._blocking;
						t.host.peers[e.hndPeer].releaseHostLock();
						if(p.msg.onConnect != null)
							p.msg.onConnect(t.host.peers[e.hndPeer]);
						outConnects.remove(p);
						found = true;
						break;
					}
				}
				if(!found) {
					t.host.peers[e.hndPeer] = UdpReliableSocket.createPeer(t.host, udpr_get_peer_pointer(t.host.__h, e.hndPeer), e.hndPeer);
					t.host.peers[e.hndPeer].getHostLock();
					t.host.peers[e.hndPeer].setState(CONNECTING);
					t.host.peers[e.hndPeer]._blocking = t.host._blocking;
					t.host.peers[e.hndPeer].releaseHostLock();
				}
				t.host.releaseHostLock();
				e.setPeer(t.host.peers[e.hndPeer]);
				connectEventList.add(e);
				//trace(connectEventList);
				doSelect = true;
				return true; // don't queue the connect
			case DISCONNECT:
				// check if it's a failed connect
				//trace(outConnects);
				for(p in outConnects) {
					if(p.sock.hndPeer == e.hndPeer) {
						p.sock.__p = null;
						p.sock.getHostLock();
						p.sock.setState(ZOMBIE);
						p.sock.releaseHostLock();
						if(p.msg.onFailed != null)
							p.msg.onFailed(p.sock);
						if(t.host.peers[e.hndPeer] != null) {
							t.host.logFatalError("Outgoing connection handle not null");
						}
						outConnects.remove(p);
						doSelect = false;
						return true;
					}
				}

				var peer = t.host.peers[e.hndPeer];
				if(peer == null)
					t.host.logFatalError(here.lineNumber + " on DISCONNECT " + e);
				e.setPeer(peer);

				var origState = peer._state;
				// Don't notify select()s if client initiated this disconnect
				// this happens when the server receives an error on a write
				// then closes the socket.
				if(peer._state == DISCONNECTING || peer._state == ZOMBIE)
						e.pollflag = true;
				if(peer._type == PEER && peer._udprsHost._type == CLIENT) {
					peer._udprsHost.getHostLock();
					peer.getHostLock();
					peer._udprsHost.setState(ZOMBIE);
					peer.setState(ZOMBIE);
					peer.releaseHostLock();
					peer._udprsHost.releaseHostLock();
				}
				else {
					peer.getHostLock();
					peer.setState(ZOMBIE);
					peer.releaseHostLock();
				}

				//if(origState == DISCONNECTING) {
					//for(msg in peer._messages) {
						//if(msg.type == MSG_DISCONNECT_WAIT)
							//respond(msg, ThreadMsg.received(e));
					//}
				//}
				// move to Zombie list
				t.host.getHostLock();
				//if(origState != DISCONNECTING) {
					expiredSockets.add({ timeout: Date.now().getTime() + (5.0 * 1000), socket: peer });
				//}
				t.host.peers[e.hndPeer] = null;
				t.host.releaseHostLock();

				doSelect = true;
				return false;

			case RECEIVE:
				var peer = t.host.peers[e.hndPeer];
				if(peer == null)
					t.host.logFatalError(here.lineNumber + " on DISCONNECT " + e);
				e.setPeer(peer);

				var msg = peer.messagePeek();
				//trace(msg);
				if(msg != null) {
					var sm : ThreadMsg = null;
					switch(msg.type) {
					case MSG_SCONNECT: t.host.logFatalError(peer.dumpMsgQueue(here.lineNumber + " on RECEIVE"));
					case MSG_READ:
						if(msg.channel == -1 || msg.channel == e.channel)
							sm = ThreadMsg.received(e);
					case MSG_READ_BLOCK:
						if(msg.channel == -1 || msg.channel == e.channel)
							sm = ThreadMsg.received(e);
					case MSG_WRITE:
					case MSG_SELECT_BLOCK:
					case MSG_SELECT_WAIT:
					case MSG_ACCEPT:
					case MSG_ACCEPT_BLOCK:
					case MSG_DISCONNECT_WAIT:
					case MSG_DISCONNECT_NOW:
					// ignore
					case MSG_EVENT_RECEIVED:
					case MSG_EVENT_TIMEOUT:
					case MSG_ERROR:
					case MSG_SHUTDOWN:
					}
					if(sm != null) {
						var send : Bool = false;
						switch(peer._state) {
						case DISCONNECTED:
						case CONNECTING:
						case CONNECTED: send = true;
						case DISCONNECTING: send = true;
						case ZOMBIE: send = true; t.host.logError(peer.dumpMsgQueue(here.lineNumber + " on RECEIVE ZOMBIE"));
						}
						if(send) {
							respond(msg, sm);
							peer.messagePop();
							//trace(here.lineNumber);
							//if(!peer._messages.remove(msg)) {
							//	t.host.logFatalError("Can't remove item from msgQueue",10);
							//}
							doSelect = false;
							return true;
						}
					}
				}
				doSelect = true;
				return false;
			}
			return false; // event not yet handled
		}
		var postEvent = function(e : UdpReliableEvent) : Bool {
			return handleIncomingEvent(e, null);
		}

		/// ////////////////////////////////////////////////////////////
		///            Main Thread Loop                               //
		/// ////////////////////////////////////////////////////////////
		while(true) {
			try {
				var msg : ThreadMsg;
				var evt = udpr_poll(t.host.__h, 0.001);

				// event has occurred.
				doSelect = true;
				if(evt != null) {
					var e = new UdpReliableEvent(evt);
					if(!handleIncomingEvent(e, postEvent)) {
						if(e.type != NONE)
							e.peer.eventAdd(e);
						// debug
						if(false && e.type == DISCONNECT) {
							//trace(e.peer._state);
							//trace(e.peer._events);
							//trace(e.peer._messages);
						}

					}
					else {
						// handled receive events are already sent to thread
						if(e.type == RECEIVE) {
							evt = null;
							//continue;
						}
					}
				}

				while ((msg = neko.vm.Thread.readMessage(false)) != null) {
					//trace("readMessage: " + msg.type);
					//trace(t.host.peers[0]);
					if(!handleIncomingMsg(msg, true)) {
						if(msg.type == MSG_SHUTDOWN) {
							// debug
							//trace(t.host.peers);
							//trace(expiredSockets);
							for(i in t.host.peers) {
								if(i == null) continue;
								if(i._state == DISCONNECTING && i._events.length > 1)
									neko.Sys.exit(0);
							}
							return;
						}
						t.host.logFatalError("Unreachable after handleIncomingMsg()");
					}
				}
//trace(t.host.peers);
				// debug
				/*
				if(false && t.host.peers[0] != null && t.host._type == CLIENT) {
					if(t.host.peers[0]._events.length > 0) {
						trace(here.lineNumber);
						trace(t.host.peers[0]._events);
						trace(t.host.peers[0]._messages);
						trace(here.lineNumber);
						//neko.Sys.exit(9);
					}
				}
				*/

//trace("after msg read");
				var now = Date.now().getTime();

				// Notify all matching connections and ACCEPT messages
				while(connectEventList.length > 0 &&  acceptMsgQueue.length > 0) {
					var m = acceptMsgQueue.pop();
					if(!doResponseAccept(m)) {
						acceptMsgQueue.push(m);
						break;
					}
				}



				// check selects
				if(selectQueue.length > 0) {
					//trace("checking selects " + selectQueue.length);
					var rsm = new ThreadMsg(
						null,
						MSG_EVENT_RECEIVED,
						new Array<UdpReliableSocket>(),
						0.0,
						null
					);
					for(msg in selectQueue) {
						var sSocket : UdpReliableSocket = null;

						//if(doSelect) {
							for(peer in msg.peers) {
								if(peer.hndPeer == -1) {
									sSocket = peer;
									//trace(here.lineNumber);
									continue;
								}
								for(e in peer._events) {
									if(!e.pollflag) {
										e.pollflag = true;
										rsm.peers.push(peer);
										break;
									}
								}
							}
							// server socket needs connection events
							if(sSocket != null) {
								for(m in connectEventList) {
									if(!m.pollflag) {
										m.pollflag = true;
										rsm.peers.push(sSocket);
										break;
									}
								}
							}
						//}

						//trace(connectEventList);
						//trace(rsm.peers);
						if(rsm.peers.length > 0) {
							respond(msg, rsm);
							if(!selectQueue.remove(msg))
								t.host.logFatalError("Unable to remove select msg");
							break;
						}
						else { // expire selects
							if(msg.type == MSG_SELECT_WAIT && msg.timeout < now) {
								respond(msg, ThreadMsg.timeout());
								if(!selectQueue.remove(msg))
									t.host.logFatalError("Unable to remove select msg");
							}
						}
					}
				} // end select processing

				// check Active connections
				for(i in t.host.peers) {
					if(i == null)
						continue;
					//if(i._messages.length > 0 && i._events.length > 0) {
						//trace("");
						//trace(i._messages);
						//trace(i._events);
					//}
					for(msg in i._messages) {
						if(handleIncomingMsg(msg, false)) {
							if(msg.type == MSG_DISCONNECT_WAIT) {
								//trace(here.lineNumber);
								throw("Unexpected message");
							}
							if(!i._messages.remove(msg))
								logFatalError("Unable to remove queued msg");
						}
					}
				}

//trace("Check Zombie " + expiredSockets.length);
				// check Zombies
				for(i in expiredSockets) {
					for(msg in i.socket._messages) {
						//trace(msg);
						if(handleIncomingMsg(msg, false))
							if(!i.socket._messages.remove(msg))
								logFatalError("Unable to remove queued msg");
					}
					if(i.timeout < now) {
						// debug
						/*
						if(i.socket._messages.length > 0) {
							trace(i.socket);
							neko.Sys.exit(9);
						}
						*/
						for(msg in i.socket._messages) {
							var sm : ThreadMsg = null;
							switch(msg.type) {
							case MSG_SCONNECT: t.host.logFatalError(i.socket.dumpMsgQueue(here.lineNumber + " on DISCONNECT"));
							case MSG_READ: sm = ThreadMsg.error();
							case MSG_READ_BLOCK: sm = ThreadMsg.error();
							case MSG_WRITE: sm = ThreadMsg.timeout();
							case MSG_SELECT_BLOCK: t.host.logFatalError(i.socket.dumpMsgQueue(here.lineNumber + " on DISCONNECT"));
							case MSG_SELECT_WAIT: t.host.logFatalError(i.socket.dumpMsgQueue(here.lineNumber + " on DISCONNECT"));
							case MSG_ACCEPT: t.host.logFatalError(i.socket.dumpMsgQueue(here.lineNumber + " on DISCONNECT")); sm = ThreadMsg.timeout();
							case MSG_ACCEPT_BLOCK: t.host.logFatalError(i.socket.dumpMsgQueue(here.lineNumber + " on DISCONNECT")); sm = ThreadMsg.timeout();
							case MSG_DISCONNECT_WAIT: t.host.logFatalError(i.socket.dumpMsgQueue(here.lineNumber + " on DISCONNECT")); sm = ThreadMsg.timeout();
							case MSG_DISCONNECT_NOW: sm = ThreadMsg.timeout();
							// aren't in queue
							case MSG_EVENT_RECEIVED:
							case MSG_EVENT_TIMEOUT:
							case MSG_ERROR:
							case MSG_SHUTDOWN:
							}

							if(sm != null) {
								respond(msg, sm);
								//trace(i.socket._messages);
								if(!i.socket._messages.remove(msg)) {
									//trace(i.socket._messages);
									t.host.logFatalError("Can't remove item from msgQueue: " + msg);
								}
							}
						}
						expiredSockets.remove(i);
					}
				}
			}
			catch(err : Dynamic) {
				t.host.logFatalError(err);
			}

		}
	} // end of workerLoop()

	//////////////////////////////////////////////////////////////
	// End of workerLoop()                                      //
	//////////////////////////////////////////////////////////////





	/**
		Specify the host and port to bind to. If host is null,
		then all bound addresses (localhost, all IPs) will be
		used. This function does not immediately bind the requested
		port, unlike normal sockets, actual binding occurs during
		listen()
	**/
	public function bind(host : Host, port : Int) : Void {
		if(_type != UNKNOWN)
			throw "std@socket_bind";
		_type = SERVER;
		_host = host;
		_port = port;
		_udprsHost = this;
	}

	/**
		Unlike regular sockets, binding does not occur in UDPR until the listen
		is called. This function will throw if that binding can not occur.
	**/
	public function listen(connections : Int) : Void {
		if(_type != SERVER)
			throw("socket not bound");

		var mp : Int = updr_max_peers();
		_connections = if(connections > mp) mp else connections;
		if(_connections < 0) _connections = 1;
		if(__h != null)
			throw("Socket already created");

		getHostLock();
		try {
			if(_host == null)
				__h = udpr_bind(null, _port, _connections, maxBpsIn, maxBpsOut);
			else
				__h = udpr_bind(_host.ip, _port, _connections, maxBpsIn, maxBpsOut);
		}
		catch(e : Dynamic) {
			releaseHostLock();
			throw "std@socket_bind";
		}
		releaseHostLock();
		if(__h == null)
			throw "std@socket_bind";
        initPeers();
        workerStart();
    }

    /**
    	Set the maximum input and output rates
    **/
    public function limits(maxBpsIn : Int, maxBpsOut : Int) : Void {
		this.maxBpsIn = if(maxBpsIn < 0) 0 else maxBpsIn;
		this.maxBpsOut = if(maxBpsOut < 0) 0 else maxBpsOut;
		if(__h != null) {
			_udprsHost.getHostLock();
			udpr_setrate(__h, this.maxBpsIn, this.maxBpsOut);
			_udprsHost.releaseHostLock();
		}
	}

	public function setChannels(c : Int) : Int {
		if(c == null || c < 1)
			c = 1;
		if(c > udpr_max_channels())
			c = udpr_max_channels() - 1;
		channels = c;
		return c;
	}

	public function setDefaultChannel(c : Int) : Int {
		if(c > channels)
			throw("Default channel out of range");
		if(c < 0)
			c = 0;
		defaultChannel = c;
		return c;
	}

	public function connectChannels(host: Host, port : Int, channels : Int) {
		this.channels = channels;
		connect(host, port);
	}

	public function connect(host : Host, port : Int) : Void {
		if(_type == SERVER)
			throw("Socket already bound");
		if(_type == PEER)
			throw("Peer sockets can not connect");
		if(peers[0] != null)
			throw("State invalid");

		reinitialize();
		_type = CLIENT;
		_connections = 1;
		_udprsHost = this;

		// create the enet_host
		__h = udpr_client_create(1, maxBpsIn, maxBpsOut);
		initPeers();

		if(__h == null)
			throw Custom("connect: unable to create host struct");

		try {
			var p = udpr_connect(__h, host.ip, port, channels, timeoutMilliseconds());
			if(p == null)
				throw Custom("Failed to connect on "+(try host.reverse() catch( e : Dynamic ) host.toString())+":"+port);

			peers[0] = UdpReliableSocket.createPeer(this, udpr_get_peer_pointer(__h, 0), 0);
		} catch( s : String ) {
				if( s == "udprsocket@udpr_connect" )
						throw Custom("Failed to connect on "+(try host.reverse() catch( e : Dynamic ) host.toString())+":"+port);
				else
						neko.Lib.rethrow(s);
		}
		getHostLock();
		setState(CONNECTED);
		peers[0].getHostLock();
		peers[0].setState(CONNECTED);
		peers[0].setBlocking(_blocking);
		peers[0].releaseHostLock();
		releaseHostLock();
		workerStart();
		//peers[0].worker = worker;
	}

	/**
		Connect out to another UPDR socket server from an existing UDPR server.
		Using this type of connection, the source port as read on the remote is
		the same as the bound port on the local machine
	**/
	public function connectOut(
			host : Host, port : Int, channels : Int,
			?onConnect : UdpReliableSocket->Void, ?onFailed : UdpReliableSocket->Void,
			?custom:Dynamic) : UdpReliableSocket {
		if(_type != SERVER)
			throw here.methodName + " not server";
		if(worker == null)
			throw here.methodName + " no worker";
		if(_type != SERVER || worker == null || __h == null)
			throw("Must be a bound server socket to connect out");

		var m = new ThreadMsg(
			neko.vm.Thread.current(),
			MSG_SCONNECT,
			[],
			0.0,
			null
		);

		m.host = host;
		m.port = port;
		m.channels = channels;
		m.onConnect = onConnect;
		m.onFailed = onFailed;
		m.custom = custom;

		//trace(here.methodName + " data: " + s);
		_udprsHost.worker.sendMessage(m);
		m = neko.vm.Thread.readMessage(true);

		if(m.type == MSG_ERROR) {
			if(m.custom != null)
				throw m.custom;
			throw "unable to connect";
		}
		// debug
		if(m.type != MSG_EVENT_RECEIVED)
			logFatalError(m.type, 10);

		return m.event.peer;
		/*
		var hndPeer : Int;
		try {
			var p : UdprPeerPointer = udpr_connect_out(__h, host.ip, port, channels, timeoutMilliseconds());
			if(p == null)
				throw Custom("Failed to connect on "+(try host.reverse() catch( e : Dynamic ) host.toString())+":"+port);
			hndPeer = udpr_get_peer_handle(__h, p);
			//getHostLock();
			//if(peers[0] != null)
				//throw "Bad error";
			//peers[0] = UdpReliableSocket.createPeer(this, udpr_get_peer_pointer(__h, 0), hndPeer);
			//releaseHostLock();
		} catch( s : String ) {
				if( s == "udprsocket@udpr_connect_out" )
						throw Custom("Failed to connect on "+(try host.reverse() catch( e : Dynamic ) host.toString())+":"+port);
				else
						neko.Lib.rethrow(s);
		}
		return hndPeer; */
	}

	/**
		Close a socket. Any further reading or writing on this socket
		will not be possible.
	**/
	public function close() : Void {
		switch(_type) {
		case UNKNOWN:
			reinitialize();
		case CLIENT:
			//for(i in peers) {
				//i.close();
			//}
			reinitialize();
		case SERVER:
			for(i in peers) {
				if(i != null)
					i.close();
			}
			reinitialize();
		case PEER:
			var flag = MSG_DISCONNECT_WAIT;
			if(_udprsHost._type == SERVER) {
				flag = MSG_DISCONNECT_NOW;
			}
			//trace(hndPeer);
			var m = new ThreadMsg(
				neko.vm.Thread.current(),
				flag,
				[this],
				10.0,
				null
			);
			//trace(here.lineNumber);
			try {
				_udprsHost.worker.sendMessage(m);
				//trace(here.lineNumber);
				//trace(m.type);
				m = neko.vm.Thread.readMessage(true);
				//trace(here.lineNumber);
			}
			catch(e:Dynamic) {
				logError(e);
			}
		}
    }

	/**
		Read a complete packet from a socket.
		Throws Error.Blocked when there are no packets queued
		Throws Error.Closed when connection is closed.
		Throws Error.Custom for any other problems
	**/
	public function read() : String {
		return readChannel(-1);
	}

	/**
		Read a complete packet from a socket on a specific channel.
		Throws Error.Blocked when there are no packets queued
		Throws Error.Closed when connection is closed.
		Throws Error.Custom for any other problems
	**/
	public function readChannel(chan : Int) : String {
		switch(_type) {
		case UNKNOWN:
			throw Error.Blocked;
		case CLIENT:
			if(_state == DISCONNECTED || _state == DISCONNECTING || _state == ZOMBIE)
				throw Error.Closed;
			if(peers.length > 0)
				return peers[0].read();
			throw Error.Blocked;
		case SERVER:
			throw Error.Custom("Server sockets can't be read from");
		case PEER:
			var t = this;
			var m = new ThreadMsg(
				neko.vm.Thread.current(),
				if(_blocking) MSG_READ_BLOCK else MSG_READ,
				[t],
				0,
				null
			);
			m.channel = chan;

			try {
				_udprsHost.worker.sendMessage(m);
				m = neko.vm.Thread.readMessage(true);
			}
			catch(e:Dynamic) {
				logFatalError(e);
			}

			if(m.type == MSG_ERROR)
				throw Error.Closed;
			if(m.type == MSG_EVENT_TIMEOUT)
				throw Error.Blocked;
			// debug
			if(m.type != MSG_EVENT_RECEIVED)
				logFatalError(m.type, 10);
			var e : UdpReliableEvent = m.event;

			if(e == null)
				logFatalError("event null",10);
			switch(e.type) {
			case NONE:
			case CONNECT:
				trace(here.methodName + " PEER RECEIVED CONNECT??");
			case DISCONNECT:
				throw Error.Closed;
			case RECEIVE:
				if(e.data.length > 0) {
					return e.data;
				}
			}
			//throw Error.Blocked;
		}
		throw Error.Custom("Unreach");
		return null;
	}

	/**
		Write to a socket. Data is flushed to socket when select()
		is run, or by calling flush()
	**/
	public function write(s : String) : Void {
		writeChannel(s, 0);
	}

	public function writeDefaultChannel(s : String) : Void {
		writeChannel(s, defaultChannel);
	}

	/**
		Write to a specific channel
	**/
	public function writeChannel(s : String, channel : Int) : Void {
		if(channel > 255 || channel < 0)
			channel = 0;
		switch(_type) {
		case UNKNOWN:
			throw Error.Closed;
		case CLIENT:
			if(_state == DISCONNECTED || _state == DISCONNECTING || _state == ZOMBIE)
				throw Error.Closed;
			if(peers.length > 0) {
				peers[0].writeChannel(s, channel);
				return;
			}
			throw Error.Custom("Client write: no peer");
		case SERVER:
			// umm, writing to yourself?
			throw Custom("Writing to bound socket not possible");
		case PEER:
			var m = new ThreadMsg(
				neko.vm.Thread.current(),
				MSG_WRITE,
				[this],
				0.0,
				null
			);
			//trace(here.methodName + " data: " + s);
			m.data = s;
			m.channel = channel;
			try {
				_udprsHost.worker.sendMessage(m);
				m = neko.vm.Thread.readMessage(true);
			}
			catch(e:Dynamic) {
				logFatalError(e);
			}

			if(m.type == MSG_ERROR)
				throw Error.Closed;
			if(m.type == MSG_EVENT_TIMEOUT)
				throw Error.Blocked;
			// debug
			if(m.type != MSG_EVENT_RECEIVED)
				logFatalError(m.type, 10);
		}
	}

	public function writeOOB(host : neko.net.Host, port : Int, data : String) {
		udpr_send_oob(__h, host.ip, port, untyped data.__s);
	}

	/**
		Blocking is on by default. If set to false, reads and writes
		to socket will return immediately, often throwing Error.Blocked
	**/
	public function setBlocking( b : Bool ) {
		_blocking = b;
		if(_type == CLIENT)
			for(i in peers)
				i.setBlocking(b);
	}
	public function getBlocking( ) : Bool {
		return _blocking;
	}

	public function accept() : UdpReliableSocket {
		//trace(here.methodName);
		if(_type != SERVER)
			throw Error.Custom("Not server socket");

		var m = new ThreadMsg(
			neko.vm.Thread.current(),
			if(_blocking) MSG_ACCEPT_BLOCK else MSG_ACCEPT,
			[],
			0.0,
			null
		);
		//trace(here.lineNumber);
		try {
			worker.sendMessage(m);
			//trace(here.lineNumber);
			//trace(m);
			m = neko.vm.Thread.readMessage(true);
		}
		catch(e:Dynamic) {
			logFatalError(e);
		}
		if(m == null) {
			throw("Null thread message");
		}
		//trace("accept got response");
		if(m.type == MSG_EVENT_TIMEOUT) {
			//trace("accept blocked");
			throw Error.Blocked;
		}
		else if(m.type == MSG_EVENT_RECEIVED) {
			//trace("accepting " + m.hndPeer +" peer previous state: "+ Std.string(m.event.peer._state));
			//trace(m);
			if(m.event.peer == null) {
				throw("Event peer is null");
			}
			m.event.peer.getHostLock();
			if(m.event.peer._state != CONNECTING)
				logError(here.lineNumber + ": "+Std.string(m.event.peer._state));
			else
				m.event.peer.setState(CONNECTED);
			m.event.peer.releaseHostLock();
			return m.event.peer;
		}
		throw Error.Closed;
	}

	/**
		Currently, any packet that comes in that has no host socket in the read array is discarded. Therefore
		ensure that all current sockets are in the read array. Also, all the passed write array will be returned.
		timeout: In seconds, like neko.net.Socet
	**/
	public static function select(read : Array<UdpReliableSocket>, write : Array<UdpReliableSocket>, others : Array<UdpReliableSocket>, timeout : Float) :
		{read: Array<UdpReliableSocket>,write: Array<UdpReliableSocket>, others: Array<UdpReliableSocket>}
	{
		var ra = new Array<UdpReliableSocket>();
		var wa : Array<UdpReliableSocket> = write;
		var oa = new Array<UdpReliableSocket>();

		var sSocket : UdpReliableSocket = null;
		var wThread : neko.vm.Thread = null;

		if(read.length == 0)
			return { read:ra, write:wa, others:oa };

		for(i in read) {
			if(i.hndPeer == -1)
				sSocket = i;
			wThread = i._udprsHost.worker;
		}

		var m = new ThreadMsg(
			neko.vm.Thread.current(),
			MSG_SELECT_BLOCK,
			read,
			timeout,
			null
		);
		if(timeout > 0) {
			m.type = MSG_SELECT_WAIT;
			m.timeout = timeout;
		}
		//trace(here.lineNumber);
		try {
			wThread.sendMessage(m);
			//trace(here.lineNumber);
			//trace(m);
			m = neko.vm.Thread.readMessage(true);
		}
		catch(e:Dynamic) {
			read[0].logFatalError(e);
		}


		if(m.type == MSG_ERROR)
			throw Custom("Worker msg error");
		if(m.type == MSG_EVENT_TIMEOUT)
			return { read:ra, write:wa, others:oa };
		// debug if this happens
		if(m.type != MSG_EVENT_RECEIVED)
			read[0].logFatalError(m.type, 10);
		ra = m.peers;
		/*
		var e = m.event;

		if(e == null)
			read[0].logFatalError("event null",10);
		switch(e.type) {
		case NONE:
		case CONNECT:
			//trace("pushing "+sSocket.hndPeer);
			ra.push(sSocket);
		case DISCONNECT:
			ra.push(e.peer);
		case RECEIVE:
			ra.push(e.peer);
		}
		*/
		return { read:ra, write:wa, others:oa };
	}

	public function setTimeout(timeout : Float) : Void {
		this.timeout = timeout;
	}

	public function timeoutMilliseconds() : Int {
		return Math.floor(timeout * 1000);
	}

	// from neko.net.ThreadServer
	public function logError(e : Dynamic) {
		var stack = haxe.Stack.exceptionStack();
		var estr = try Std.string(e) catch( e2 : Dynamic ) "???" + try "["+Std.string(e2)+"]" catch( e : Dynamic ) "";
        neko.io.File.stderr().write( estr + "\n" + haxe.Stack.toString(stack) );
        neko.io.File.stderr().flush();
    }
    public function logFatalError(e : Dynamic, ?errCode : Int) {
    	//trace(here.methodName);
		var stack = haxe.Stack.exceptionStack();
		if(stack == null || stack.length == 0)
			stack = haxe.Stack.callStack();
		var estr = try Std.string(e) catch( e2 : Dynamic ) "???" + try "["+Std.string(e2)+"]" catch( e : Dynamic ) "";
        neko.io.File.stderr().write( estr + "\n" + haxe.Stack.toString(stack) );
        neko.io.File.stderr().flush();
        neko.Sys.exit(10);
    }

	/***** UNFINISHED **********/
	public function host() : { host : Host, port : Int } {
		var a : Dynamic;
		getHostLock();
		switch(_type) {
		case UNKNOWN:
			throw("udprsocket@udpr_host_address");
		case CLIENT:
			a = udpr_host_address(__h);
		case SERVER:
			a = udpr_host_address(__h);
		case PEER:
			a = udpr_host_address(_udprsHost.__h);
		}
		releaseHostLock();
		var h = new Host("127.0.0.1");
		untyped h.ip = a[0];
		return { host : h, port : a[1] };
	}

	public function peer() : { host : Host, port : Int } {
		var a : Dynamic;
		getHostLock();
		switch(_type) {
		case UNKNOWN:
			throw("udprsocket@udpr_peer_address");
		case CLIENT:
			a = udpr_peer_address(getPeer().__p);
		case SERVER:
			throw("udprsocket@udpr_peer_address");
			//a = udpr_host_address(__h);
		case PEER:
			a = udpr_peer_address(__p);
		}
		releaseHostLock();
		var h = new Host("127.0.0.1");
		untyped h.ip = a[0];
		return { host : h, port : a[1] };
	}

	public function shutdown(read : Bool, write : Bool) : Void {
		close();
	}
	public function waitForRead() : Void {
		select([this],null,null,null);
	}


	///////////////////////////////////////////////////////////////
	//  EVENT QUEUE FUNCTIONS                                    //
	///////////////////////////////////////////////////////////////
	function eventAdd(e: UdpReliableEvent) {
		if(e != null)
			_events.add(e);
	}
	function eventPeek() : UdpReliableEvent {
		if(_events.length == 0)
			return null;
		return _events.first();
	}
	function eventPop() : UdpReliableEvent {
		var e = _events.pop();
		if(e == null)
			return null;
		return e;
	}
	function eventUnget(e : UdpReliableEvent) {
		_events.push(e);
	}
	public function eventCount() : Int {
		return _events.length;
	}

	///////////////////////////////////////////////////////////////
	//  THREAD MESSAGE QUEUE FUNCTIONS                           //
	///////////////////////////////////////////////////////////////
	function messageAdd(e: ThreadMsg) {
		if(e != null)
			_messages.add(e);
		else
			logFatalError("null msg");
	}
	function messagePeek() : ThreadMsg {
		if(_messages.length == 0)
			return null;
		return _messages.first();
	}
	function messagePop() : ThreadMsg {
		var e = _messages.pop();
		if(e == null)
			return null;
		return e;
	}
	function messageUnget(e : ThreadMsg) {
		_messages.push(e);
	}
	public function messageCount() : Int {
		return _messages.length;
	}

	///////////////////////////////////////////////
	//  For UdpReliableSocketInput               //
	///////////////////////////////////////////////
	public function getPeer() : UdpReliableSocket {
		if(_type != CLIENT)
			throw Error.Custom("Wrong socket type " + _type);
		if(_state == DISCONNECTED || _state == DISCONNECTING || _state == ZOMBIE)
			throw Error.Closed;
		if(peers.length != 1)
			throw Error.Custom("peers length is " + peers.length);
		return peers[0];
	}
	public function getType() {
		return _type;
	}

	///////////////////////////////////////////////
	//Attach a peer to a SERVER or CLIENT socket //
	///////////////////////////////////////////////
	static function createPeer(s : UdpReliableSocket, peerPtr : UdprPeerPointer, idx : Int) : UdpReliableSocket {
		var p = new UdpReliableSocket();
		p._type = PEER;
		p.__p = peerPtr;
		p._udprsHost = s; // tie it back to host instance
		if(s._type == CLIENT)
			p.setBlocking(s._blocking);
		p.hndPeer = idx;
		s.seqno++;
		p.seqno = s.seqno;
		//p.worker = s.worker;
		return p;
	}

	///////////////////////////////////////////////
	// Recreate the peers array                  //
	///////////////////////////////////////////////
	function initPeers() {
		if(_type != SERVER && _type != CLIENT)
			throw("unable to init peers");
		peers = new Array();
		for(i in 0..._connections) {
			peers[i] = null;
		}
	}

	///////////////////////////////////////////////
	// Set a peer state                          //
	///////////////////////////////////////////////
	function setState(s:UdprSocketState) {
		if(getHostLock(0.1)) {
			trace("You have not acquired a state change lock!");
			logFatalError(haxe.Stack.callStack);
		}
		_state = s;
	}

	///////////////////////////////////////////////
	// Get all ips on box                        //
	///////////////////////////////////////////////
	public static function enumerateIpAddr() : Hash<String> {
		var a : Array<Dynamic>;
		var rv = new Hash();
		var host = new neko.net.Host("localhost");

		try {
			a = enumerate_ips();
			while(a != null) {
				var key = new String(a[0]);
				untyped host.ip = a[1];
				var value = host.toString();
				rv.set(key, value);
				a = a[2];
			}
		}
		catch(e: Dynamic) {}
		return rv;
	}

	private static var udpr_init = neko.Lib.load("udprsocket","udpr_init",0);
	private static var udpr_bind = neko.Lib.load("udprsocket","udpr_bind",5);
	private static var udpr_connect = neko.Lib.load("udprsocket","udpr_connect",5);
	private static var udpr_connect_out = neko.Lib.load("udprsocket","udpr_connect_out",5);
	private static var udpr_close = neko.Lib.load("udprsocket","udpr_close",2);
	private static var udpr_close_now = neko.Lib.load("udprsocket","udpr_close_now",1);
	private static var udpr_close_graceful = neko.Lib.load("udprsocket","udpr_close_graceful",1);
	private static var udpr_setrate = neko.Lib.load("udprsocket","udpr_setrate",3);
	private static var updr_max_peers = neko.Lib.load("udprsocket","udpr_max_peers",0);
	private static var udpr_max_channels = neko.Lib.load("udprsocket","udpr_max_channels",0);
	private static var udpr_client_create = neko.Lib.load("udprsocket","udpr_client_create",3);
	private static var udpr_poll = neko.Lib.load("udprsocket","udpr_poll",2);
	//private static var udpr_host_service = neko.Lib.load("udprsocket","udpr_host_service",2);
	private static var udpr_flush = neko.Lib.load("udprsocket","udpr_flush",1);
	private static var udpr_write = neko.Lib.load("udprsocket","udpr_write",4);
	private static var udpr_send_oob = neko.Lib.load("udprsocket","udpr_send_oob",4);
	private static var udpr_peer_equal = neko.Lib.load("udprsocket","udpr_peer_equal",2);
	private static var udpr_host_address = neko.Lib.load("udprsocket","udpr_host_address",1);
	private static var udpr_peer_address = neko.Lib.load("udprsocket","udpr_peer_address",1);

	private static var udpr_peer_pointer = neko.Lib.load("udprsocket","udpr_peer_pointer",1);
	private static var udpr_get_peer_pointer = neko.Lib.load("udprsocket","udpr_get_peer_pointer",2);
	private static var udpr_get_peer_handle = neko.Lib.load("udprsocket","udpr_get_peer_handle",2);


	private static var enumerate_ips = neko.Lib.load("udprsocket","enumerate_ips",0);
	//private static var udpr_register_worker_thread = neko.Lib.load("udprsocket","udpr_register_worker_thread",2);
}

/*
	function findSource(s : Array<UdpReliableSocket>, ph : UdprPeerPointer) : UdpReliableSocket {
			if(ph == null)
				return null;
			for(i in s) {
				switch(i._type) {
				case UNKNOWN:
				case CLIENT:
					var s = i.findSource(peers, ph);
					if(s != null)
						return s;
				case SERVER:
					var s = i.findSource(peers, ph);
					if(s != null)
						return s;
				case PEER:
					if(udpr_peer_equal(i.__p, ph))
						return i;
				}
			}
			return null;
	}
*/
