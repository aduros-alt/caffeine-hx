import neko.net.Host;
import neko.net.UdpReliableSocket;
import neko.net.servers.MetaServer;
import neko.net.servers.MetaServer.ServerType;

class Client {
	public var socket : neko.net.Socket;
	var server : ServerTwo;
	var extraData : String;

	public function new(serv, s) {
		server = serv;
		socket = s;

		var sb = new StringBuf();
		for(i in 0...2000) {
			sb.addChar(Std.random(20) + 65);
		}
		extraData = sb.toString();

	}

	//public function readProgressive( buf, pos, len ) {
	public function readProgressive( buf : String, bufpos : Int, buflen : Int ) : Int {
		trace("\n>> "+here.methodName + "\n>> buf: "+buf.substr(bufpos,buflen)+"\n>> bufpos: "+bufpos+"\n>> buflen: "+buflen);
		var server = cast(this.socket,UdpReliableSocket);
		if(buflen > 6 ) {
			if(buf.substr(bufpos,7) == "CONNECT") {
				trace(here.lineNumber);
				var sock : UdpReliableSocket;
				var args = buf.substr(bufpos, buflen).split(":");
				if(args.length == 3) {
					try {
						sock = server.connectOut(new neko.net.Host(args[1]), Std.parseInt(args[2]), 2,onOutConnect, onOutConnectFail);
						if(sock == null)
							server.logFatalError("Null socket recvd");
						trace("Received outgoing handle " + sock.hndPeer);

					}
					catch(e : Dynamic) {
						server.logError(e);
					}
				}
				else {
					server.logError("Outgoing connect string invalid: " + buf.substr(bufpos, buflen));
				}
			}
			if(buf.substr(bufpos,7) == "SENDOOB") {
				trace(here.lineNumber);
				var hnd : Int;
				var args = buf.substr(bufpos, buflen).split(":");
				if(args.length > 3) {
					if(args[3] == null)
						args[3] = "mydata";
					try {
						server.writeOOB(new neko.net.Host(args[1]), Std.parseInt(args[2]), args[3]);
						trace("Sent packet");
					}
					catch(e : Dynamic) {
						server.logError(e);
					}
				}
				else {
					server.logError("Outgoing connect string invalid: " + buf.substr(bufpos, buflen));
				}
			}
		}
		else if(buf.substr(bufpos, buflen) == "SHUTDOWN") {
			try {
				server.close();
			}
			catch(e : Dynamic) {
				trace("Can't close " + e);
			}
			neko.Sys.exit(0);
		}
		else {
			var sb = new StringBuf();
			sb.add(Std.string(untyped socket.seqno));
			sb.add(":");
			sb.add(buf.substr(bufpos, buflen));
			sb.add(":");
			sb.add(extraData);
			//sb.add("ewjrjwer");
			//trace(sb);
			//d.sock.write(Std.string(d.sock.seqno) + ":" + buf.substr(bufpos, buflen) + ":" + sb.toString());
			//socket.write(sb.toString());
			socket.output.writeBytes(sb.toString(),0,sb.toString().length);
		}
		return buflen;
	}

	function onOutConnect(s : UdpReliableSocket) : Void {
		trace(here.methodName);
		trace(s);
	}
	function onOutConnectFail(s : UdpReliableSocket) : Void {
		trace(here.methodName);
		trace(s);
	}
	public function updateTime( t : Float ) {}
	public function cleanup() {}
}

class ServerTwo extends MetaServer<Client> {
	public var  extraData : String;
	public function new(host, port) {
		super(this);

		var sb = new StringBuf();
		for(i in 0...2000) {
			sb.addChar(Std.random(20) + 65);
		}
		extraData = sb.toString();

		create(UDPR, host, port);
		create(INTERNAL, host, port);

		//create(TCP, host, port);
		while(true) {
		}
	}

	public static function main() {

		var h : String = neko.Sys.args()[0];
		var p = Std.parseInt(neko.Sys.args()[1]);
		if(neko.Sys.args().length != 2 || p == 0) {
			neko.Lib.print("Usage: server host port\n");
			neko.Sys.exit(10);
		}
		var sg = new ServerTwo(new neko.net.Host(h), p);
	}

	public function clientConnected( s : neko.net.Socket ) {
		trace(here.methodName);
		s.write(Std.string(untyped s.seqno));
		return new Client(this,s);
	}

	public function clientDisconnected( c : Client ) {
		c.cleanup();
	}

	public function readClientMessage( c : Client, buf : String, pos : Int, len : Int ) {
		//trace(here.methodName + " pos: " + pos + " len : " + len);
		if(len > 0) {
			//trace(buf.substr(pos,len));
			var m = c.readProgressive(buf,pos,len);
			//trace(m);
			return m;
		}
		else
			return null;
		//if( m == null )
			//return null;
		//if( m.msg != null )
			//c.processPacket(m.msg.header,m.msg.packet);
		//return m.bytes;
		return 0;
	}

	public function clientFillBuffer( c : Client ) {
		c.updateTime(neko.Sys.time());
	}

	public function clientWakeUp( c : Client ) {
		c.updateTime(neko.Sys.time());
	}

}
