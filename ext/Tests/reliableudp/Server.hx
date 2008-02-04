import neko.net.Host;
import neko.net.UdpReliableSocket;

/*
neko client.n 10.0.0.103 8001 CONNECT:10.0.0.251:8002
neko client.n 10.0.0.251 8002 SENDOOB:10.0.0.103:8001:werweiuroweiurwoeiurwer
*/
private class MyData {
	public var server : Server;
	public var sock : neko.net.UdpReliableSocket;
	public var remote_host		: neko.net.Host;
	public var remote_port		: Int;

	public function new(server, s: neko.net.UdpReliableSocket) {
		this.server = server;
		sock = s;
		var ph = s.peer();
		remote_host = ph.host;
		remote_port = ph.port;
	}
}

//class Server extends neko.net.servers.UdprLoopedServer<MyData> {
class Server extends neko.net.servers.GenericServer<neko.net.UdpReliableSocket,MyData> {
	var extraData : String;
	public static function main() {
		var sg = new Server();
		var h : String = neko.Sys.args()[0];
		var p = Std.parseInt(neko.Sys.args()[1]);
		if(neko.Sys.args().length != 2 || p == 0) {
			neko.Lib.print("Usage: server host port\n");
			neko.Sys.exit(10);
		}
		sg.run(new neko.net.Host(h), p);
	}

	public function new() {
		super();
		server = new UdpReliableSocket();
		fSelect = neko.net.UdpReliableSocket.select;
		//server.setBlocking(false);
		var sb = new StringBuf();
		for(i in 0...2000) {
			sb.addChar(Std.random(20) + 65);
		}
		extraData = sb.toString();
	}

	override public function onConnect(s:neko.net.UdpReliableSocket) : MyData {
		var cdata = new MyData(this, s);
		trace(here.methodName + " New connection ["+s.hndPeer+"] from "+ cdata.remote_host.toString() + " port: "+ Std.string(cdata.remote_port),2);
		s.write(Std.string(cdata.sock.seqno));
		return cdata;
	}

	function onOutConnect(s : UdpReliableSocket) : Void {
		trace(here.methodName);
		trace(s);
	}
	function onOutConnectFail(s : UdpReliableSocket) : Void {
		trace(here.methodName);
		trace(s);
	}
	override public function onReadable( d : MyData, buf : String, bufpos : Int, buflen : Int ) : Int {
		//trace("\n>> "+here.methodName + "\n>> buf: "+buf.substr(bufpos,buflen)+"\n>> bufpos: "+bufpos+"\n>> buflen: "+buflen);
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
			sb.add(Std.string(d.sock.seqno));
			sb.add(":");
			sb.add(buf.substr(bufpos, buflen));
			sb.add(":");
			sb.add(extraData);
			//trace(sb);
			//d.sock.write(Std.string(d.sock.seqno) + ":" + buf.substr(bufpos, buflen) + ":" + sb.toString());
			d.sock.write(sb.toString());
		}
		return buflen;
	}

}
