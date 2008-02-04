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

package neko.net.servers;

enum ServerType {
	/** A TCP based server **/
	TCP;
	/** UDP reliable server **/
	UDPR;
	/** Internal socket server **/
	INTERNAL;
}

private typedef ThreadInfo<ClientData> = {
	var thread : neko.vm.Thread;
	var manager : MetaServer<ClientData>;
	var worker : neko.vm.Thread;
	var server : Dynamic;
	var type : ServerType;
	var host : neko.net.Host;
	var port : Int;
}

/**
	MetaServer allows you to create a realtime server that listens on any number
	of ip addresses and ports, with any combination of TCP, UDP and
	internal sockets.
*/
class MetaServer<ClientData> {
	var listener	: Dynamic;
	var servers		: List<ThreadInfo<ClientData>>;

	public var config : {
		listenValue : Int,
		connectLag : Float,
		minReadBufferSize : Int,
		maxReadBufferSize : Int,
		writeBufferSize : Int,
		blockingBytes : Int,
		messageHeaderSize : Int,
		threadsCount : Int,
	};

	/**
		Create a MetaServer, which by itself does not serve. Use the create() method
		to bind to ports.
	**/
	public function new(listener:Dynamic) {
		this.listener = listener;
		servers = new List();
		config = {
			listenValue : 10,
			connectLag : 0.5,
			minReadBufferSize : 1 << 10, // 1 KB
			maxReadBufferSize : 1 << 16, // 64 KB
			writeBufferSize : 1 << 18, // 256 KB
			blockingBytes : 1 << 17, // 128 KB
			messageHeaderSize : 0,
			threadsCount : 10,
		};
	}

	/**
		Create a server, bound to the given host and port.
	**/
	public function create(type : ServerType, host : neko.net.Host, port : Int) {
		var s : Dynamic;
		switch(type) {
		case TCP:
			s = new TcpRealtimeServer<ClientData>();
		case UDPR:
			s = new UdprRealtimeServer<ClientData>();
		case INTERNAL:
			s = new InternalSocketRealtimeServer<ClientData>();
		}
		s.config = config;

		// bind API functions
		if(Reflect.isFunction(listener.clientConnected)) {
			s.clientConnected = listener.clientConnected;
		}
		if(Reflect.isFunction(listener.readClientMessage)) {
			s.readClientMessage = listener.readClientMessage;
		}
		if(Reflect.isFunction(listener.clientDisconnected)) {
			s.clientDisconnected = listener.clientDisconnected;
		}
		if(Reflect.isFunction(listener.clientFillBuffer)) {
			s.clientFillBuffer = listener.clientFillBuffer;
		}
		if(Reflect.isFunction(listener.clientWakeUp)) {
			s.clientWakeUp = listener.clientWakeUp;
		}
		if(Reflect.isFunction(listener.isBlocking)) {
			s.isBlocking = listener.isBlocking;
		}
		if(Reflect.isFunction(listener.wakeUp)) {
			s.wakeUp = listener.wakeUp;
		}
		if(Reflect.isFunction(listener.stopClient)) {
			s.stopClient = listener.stopClient;
		}

		try {
			s.doBind(host, port);
		}
		catch(e : Dynamic) {
			neko.Lib.rethrow(e);
		}

		var m = this;
		var i : ThreadInfo<ClientData> = {
			thread: neko.vm.Thread.current(),
			manager: m,
			worker : null,
			server: s,
			type : type,
			host : host,
			port : port
		}

		i.worker = neko.vm.Thread.create(callback(workerLoop, i));
	}

	/**
		Graceful shutdown of all servers.
	**/
	public function shutdown() {
		for(i in servers) {
			if(i != null)
				i.server.shutdown = true;
		}
	}

	function workerLoop(i : ThreadInfo<ClientData>) {
		while(true) {
			try {
				i.server.doRun();
			} catch(e : Dynamic) {
				logError(e);
			}
			if(untyped i.s.shutdown == true)
				return;
		}
	}

	function logError( e : Dynamic ) {
		var stack = haxe.Stack.exceptionStack();
		var str = "["+Date.now().toString()+"] "+(try Std.string(e) catch( e : Dynamic ) "???");
		neko.Lib.print(str+"\n"+haxe.Stack.toString(stack));
	}
}
