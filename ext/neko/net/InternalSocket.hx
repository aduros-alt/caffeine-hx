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
import neko.net.Socket.SocketHandle;
import neko.io.Error;

enum ISocketType {
	UNKNOWN;
	CLIENT;
	SERVER;
	PEER;
}

enum ISocketEventType {
	CONNECT;
	DISCONNECT;
	DATA;
}

private typedef PortDescriptor = {
	var port : Int;
	var sock : InternalSocket;
}

private typedef Event = {
	var type : ISocketEventType;
	var data : String;
	var sock : InternalSocket;
}

class InternalSocket implements neko.net.Socket {
	private var __s : SocketHandle;
	public var custom : Dynamic;
	public var input(default,null) : SocketInput;
	public var output(default,null) : SocketOutput;
	var _type : ISocketType;
	var _blocking : Bool;
	var _events : List<Event>;
	var _host : InternalSocket;
	var _port : Int;
	var peers: Array<InternalSocket>;
	public var remoteHost : neko.net.Host;
	public var remotePort : Int;
	static var _boundports : List<PortDescriptor>;

	static var lockBoundPorts : neko.vm.Lock;
	var _subscriber : neko.vm.Lock; // null initially. Set to select lock awaiting data.
	var lockAccept : neko.vm.Lock;
	//var lockSelect : neko.vm.Lock;
	var lockEvents : neko.vm.Lock;
	//var lockDataOut : neko.vm.Lock;

	public function new(?s : SocketHandle) : Void {
		reinitialize();
		remoteHost = new neko.net.Host("localhost");
		remotePort = 0;
	}

	public static function __init__() {
		_boundports = new List();
		lockBoundPorts = new neko.vm.Lock();
		lockBoundPorts.release();
	}

	function reinitialize() {
		if(_blocking == null)
			_blocking = true;
		_type = UNKNOWN;
		_events = new List();
        _host = null;
		peers = new Array();
		lockAccept = new neko.vm.Lock();
		lockEvents = new neko.vm.Lock();
		input = new InternalSocketInput(this);
		output = new InternalSocketOutput(this);
	}

	public function accept() : InternalSocket {
		while(true) {
			if(_blocking)
				lockAccept.wait();
			for(i in _events) {
				if(i.type == CONNECT) {
					_events.remove(i);
					return i.sock;
				}
			}
			if(!_blocking)
				throw "Blocking";
		}
		return null;
	}

	public function bind(host : Host, port : Int) : Void {
		close();
		reinitialize();
		_type = SERVER;
		lockBoundPorts.wait();
		for(i in _boundports) {
			if(i.port == port) {
				lockBoundPorts.release();
				throw "std@socket_bind";
			}
		}
		_boundports.add({ port: port, sock: this});
		lockBoundPorts.release();
	}

	public function close() : Void {
		switch(_type) {
		case UNKNOWN:
			return;
		case CLIENT:
			if(peers[0] != null)
				peers[0].postEvent({type:DISCONNECT, data: null, sock: this});
			peers[0] = null;
		case SERVER:
			lockBoundPorts.wait();
			for(p in peers) {
				p.peers[0].postEvent({type:DISCONNECT, data: null, sock: this});
			}
			peers = new Array();
			_boundports.remove({ port: _port, sock: this});
			lockBoundPorts.release();
		case PEER:
			peers[0].postEvent({type:DISCONNECT, data: null, sock: this});
		}
	}

	public function connect(host : Host, port : Int) : Void {
		//trace(here.methodName);
		close();
		lockBoundPorts.wait();
		var bp : PortDescriptor = null;
		for(p in _boundports) {
			if(p.port == port) {
				bp = p;
				break;
			}
		}
		if(bp == null) {
			lockBoundPorts.release();
			throw "Failed to connect on " + Std.string(port);
		}
		peers[0] = bp.sock.doConnect(this);
		_port = port;
		_type = CLIENT;
		lockBoundPorts.release();
	}

	// this is server side.
	function doConnect(client : InternalSocket) : InternalSocket {
		//trace(here.methodName);
		var s = new InternalSocket();
		s._type = PEER;
		s._host = this;
		s.host = client.host;
		s._port = client._port;
		s.remoteHost = client.remoteHost;
		s.remotePort = client.remotePort;
		s.peers[0] = client;
		postEvent({type:CONNECT, data:null, sock:s});
		return s;
	}

	public function getBlocking() {
		return _blocking;
	}

	public function getPeer() : InternalSocket {
		if(_type != CLIENT)
			throw Error.Custom("Wrong socket type " + _type);
		if(peers.length != 1)
			throw Error.Custom("peers length is " + peers.length);
		return peers[0];
	}

	public function getType() {
		return _type;
	}

	public function host() : { port : Int, host : Host} {
		return { port : _port, host: new neko.net.Host("localhost") };
	}

	public function listen(connections : Int) : Void {}

	public function peer() : { port : Int, host : Host} {
		switch(_type) {
		case UNKNOWN:
			throw("internalsocket@peer()");
		case CLIENT:
		case SERVER:
			throw("internalsocket@peer()");
		case PEER:
		}
		return { host : remoteHost, port : remotePort };
	}

	public function read() : String {
		switch(_type) {
		case UNKNOWN:
			throw Error.Closed;
		case SERVER:
			throw "Can't read from server socket.";
		case CLIENT:
			if(peers[0] == null)
				throw Error.Closed;
		case PEER:
			if(peers[0] == null)
				throw Error.Closed;
		}
		while(true) {
			if(_blocking) {
				lockEvents.wait();
				lockEvents.release();
			}
			var e = popEvent([DISCONNECT, DATA]);
			if(e == null) {
				if(_blocking)
					continue;
				throw Error.Blocked;
			}
			if(e.type == DISCONNECT) {
				lockEvents.release(); // allow any thread to re-pop this.
				throw Error.Closed;
			}
			return e.data;
		}
		return "";
	}

	public function setBlocking(b : Bool) : Void {
		_blocking = b;
	}
	public function setTimeout(timeout : Float) : Void {
	}
	public function shutdown(read : Bool, write : Bool) : Void {
		close();
	}
	public function waitForRead() : Void {
		throw "waitForRead() Not implemented";
	}

	public function write(content : String) : Void {
		switch(_type) {
		case UNKNOWN:
			throw Error.Closed;
		case SERVER:
			throw "Can't write to server socket.";
		case CLIENT:
			if(peers[0] == null)
				throw Error.Closed;
			peers[0].postEvent({type:DATA, data:content, sock: this});
		case PEER:
			if(peers[0] == null || _host == null)
				throw Error.Closed;
			try {
				peers[0].postEvent({type:DATA, data:content, sock: this});
			}
			catch(e:Dynamic) {
				throw Error.Closed;
			}
		}
	}

	static public function select(read : Array<InternalSocket>, write : Array<InternalSocket>, others : Array<InternalSocket>, timeout : Float) : { write : Array<InternalSocket>, read : Array<InternalSocket>, others : Array<InternalSocket>}
    {
        var ra = new Array<InternalSocket>();
        var wa = write;
        var ea = new Array<InternalSocket>();
        var blocking :Bool = if(timeout == 0) true else false;

		var poll = function(lock) {
			for(p in read) {
				switch(p._type) {
				case UNKNOWN:
					throw "select() UNKNOWN";
				case CLIENT:
					throw "select() CLIENT";
				case SERVER:
					p._subscriber = lock;
					if(p._events.length > 0)
						ra.push(p);
				case PEER:
					p._subscriber = lock;
					if(p._events.length > 0)
						ra.push(p);
				}
			}
		}
		var llock = new neko.vm.Lock();
		poll(llock);
		if(wa.length > 0 || ra.length > 0) {
			for(p in read)
				p._subscriber = null;
			return { write : wa, read : ra, others : ea }
		}

		if(blocking)
			llock.wait();
		else
			llock.wait(timeout);
		poll(null);

		return { write : wa, read : ra, others : ea }
    }

	// these are from the point of view of the CLIENT,
	// so InEvents are sent _from_ the server, OutEvents
	// are what the client is sending _to_ the server.
	// as many times as a lock has been released, it can
	// be acquired. The DataIn lock starts locked.
	function postEvent(e : Event) {
		//trace(here.methodName + " " + e.type + " " + _type);
		switch(_type) {
		case UNKNOWN:
			throw("postEvent UNKNOWN");
		case CLIENT:
			_events.add(e);
			lockEvents.release();
		case SERVER:
			switch(e.type) {
			case CONNECT:
				/*
				var placed = false;
				for(i in 0...peers.length) {
					if(peers[i] == null) {
						peers[i] = e.sock;
						placed = true;
						break;
					}
				}
				if(!placed)
					peers.push(e.sock);
				*/
				_events.add(e);
				lockAccept.release();
				try { _subscriber.release(); } catch (e:Dynamic) {}
			case DATA:
			case DISCONNECT:
				e.sock._host = null;
				// remove from peers?
			}
		case PEER:
			try { _host.postEvent(e); } catch(e:Dynamic) {} // _host could be null by this point
			if(e.type != CONNECT) {
				_events.add(e);
				try { _subscriber.release(); } catch (e:Dynamic) {}
			}
			lockEvents.release();
		}
	}

	function popEvent(types: Array<ISocketEventType>) : Event {
		for(e in _events) {
			for(t in types)
				if(e.type == t) {
					// here, the lock was release once to push the event
					// on the stack, so this (should) never wait at all.
					if(!lockEvents.wait(0.001))
						throw "Concurrency error in popEvent()";
                    if(e.type != DISCONNECT)
						_events.remove(e);
					return e;
				}
		}
		return null;
	}
}
