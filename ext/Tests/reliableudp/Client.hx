import neko.net.Host;
import neko.net.UdpReliableSocket;


class Client {

    public function new() {
    }

    public function run(host : Host, port : Int, ln : Int ) {
    	var mySeqNo : Int;
		var s = new neko.net.UdpReliableSocket();
//for(x in 0...200) {
		s.setBlocking(true);
		//trace(host + " " + port);
		trace("###### Connecting");
		s.connect(host, port);
		trace("###### Connected");
		if(ln % 3 == 0) {
			//s.close();
			//trace("##### Immediate close");
			//return;
		}
//neko.Sys.sleep(15);
//trace("finished sleep");
trace(here.lineNumber);
		var start = neko.Sys.time();
		var bytes : Int = 0;
		for(i in 0...Std.random(300)+5000) {
			//trace("LOOP:: "+i);
			//var actsock = neko.net.UdpReliableSocket.select([s], null, null, 10);
			try {
				//trace(s);
				var rv = s.read();
				//var rv = s.input.readAll();
				//var rv : String = neko.Lib.makeString(50);
				//s.input.readBytes(rv,0,1);
				if(i == 0) {
					mySeqNo = Std.parseInt(rv);
					trace(">>>> Client SEQNO : " + mySeqNo);
				}
				else {
					bytes += rv.length;
					var ar = rv.split(":");
					var seq = Std.parseInt(ar[0]);
					var lo = Std.parseInt(ar[1]);
					//trace(">>>> Client "+seq+" RECEIVED: " + lo);
					//trace(ar[2]);
					if(lo != i-1 || seq != mySeqNo) {
						trace("Error on loop "+i+" response: "+lo+" expected:"+Std.string(i-1));
						trace("MySeqNo " + mySeqNo + " recvd seqno: "+seq);
						neko.Sys.exit(0);
					}
				}
				if(i%100 == 0)
					trace(">>>> Client "+mySeqNo+" SENDING: " +i);
				//if(i < 100 || i > 110)
					s.write(Std.string(i));
					//trace("sent");
				if(i == 115) {
					//neko.Sys.sleep(10);
					//s.close();
					//return;
				}
			}
			catch (e:Dynamic) {
				if(e == neko.io.Error.Blocked) {
					trace(here.methodName + " ************** received BLOCKED condition");
				}
				else if(Std.is(e, neko.io.Eof)) {
					trace(here.methodName + " *************** connection closed");
					return;
				}
				else {
					trace(" **************** ACK");
					s.close();
					neko.Lib.rethrow(e);
				}
			}

		}
//}
		start = neko.Sys.time() - start;
		trace(bytes + " bytes in " + start + " seconds");
		trace(Std.string(bytes/1024/start) + " kBps");
		trace(Std.string(bytes*8/1024/1024/start) + " Mbps");
		trace("UDPR RUN finished");
		trace("UDP HOST: " + s.host());
		trace("UDP PEER: " + s.peer());
		s.close();

    }

	// SHUTDOWN
	// CONNECT:host:port
	public function sendServerCommand(host : Host, port : Int, cmd :String ) {
		var s = new neko.net.UdpReliableSocket();
		s.setBlocking(true);
		trace("###### Connecting");
		s.connect(host, port);
		trace("###### Connected");
		var rv = s.read();
		trace(rv);
		trace("Sending command "+ cmd);
		s.write(cmd);
		s.close();
		neko.Sys.exit(0);
	}

	public function srun(host:Host, port : Int) {
		var s = new neko.net.Socket();
		s.connect(host, port);
		trace("Connected to webserver");
		trace(s.host());
		trace(s.peer());
		return;
	}

	public function urun(host:Host, port : Int) {
		var s = neko.net.Socket.newUdpSocket();
		s.connect(host, port);
		trace("Connected to UDP");
		trace(s.host());
		trace(s.peer());
		return;
	}

    public static function main() {
		var serv = new Client();

		trace(UdpReliableSocket.enumerateIpAddr());

		var h : String = neko.Sys.args()[0];
		var p = Std.parseInt(neko.Sys.args()[1]);
		if(neko.Sys.args().length < 2 || p == 0) {
			neko.Lib.print("Usage: client host port [command]\n");
			neko.Sys.exit(10);
		}

		if(neko.Sys.args().length == 3) {
			serv.sendServerCommand(new neko.net.Host(h), p, neko.Sys.args()[2]);
			trace(neko.Sys.args());
			return;
		}

		for(x in 0...2000) {
			serv.run(new neko.net.Host(h), p, x);
			trace("Loop "+x+" done");
		}
		//serv.srun(new neko.net.Host("www.tzc.com"), 80);
		//serv.urun(new neko.net.Host("10.0.0.103"), 8000);

    }

}
