import neko.net.InternalSocket;
import neko.net.servers.GenericServer;

private class MyData {
	public var server : IntSock;
	public var sock : neko.net.InternalSocket;
	public var remote_host		: neko.net.Host;
	public var remote_port		: Int;

	public function new(server, s: neko.net.InternalSocket) {
		this.server = server;
		sock = s;
		var ph = s.peer();
		remote_host = ph.host;
		remote_port = ph.port;
	}
}

class IntSock extends neko.net.servers.GenericServer<InternalSocket,MyData> {
	var extraData : String;

    public static function main() {
        var s = new IntSock();
    }

    public function new() {
        super();
        var sb = new StringBuf();
		for(i in 0...2000) {
			sb.addChar(Std.random(20) + 65);
		}
		extraData = sb.toString();
        var st = neko.vm.Thread.create(callback(serverThread, neko.vm.Thread.current()));
        neko.vm.Thread.readMessage(true);
        neko.Sys.sleep(0.01);
        var sock = new InternalSocket();
        sock.remoteHost = new neko.net.Host("www.tzc.com");
        sock.remotePort = 23535;
        sock.connect(new neko.net.Host("localhost"), 12);
        sock.setBlocking(true);
        trace(sock.read());
        for(x in 0...20) {
        	sock.write(Std.string(x));
        	var r = sock.read();
        	var ar = r.split(":");
        	r = ar[0];
        	if(Std.parseInt(r) != x) {
        		trace("Received bad value " +r + " expected " + x);
        	}
        }
        neko.Sys.sleep(10);
        sock.close();
        st = null;
        neko.Sys.sleep(2);
        trace("I'm done");
    }

    function serverThread(t : neko.vm.Thread) : Void {
		server = new InternalSocket();
		fSelect = neko.net.InternalSocket.select;
		t.sendMessage("I'm workin");
		run(new neko.net.Host("localhost"), 12);
    }

	override public function onConnect(s:neko.net.InternalSocket) : MyData {
		var cdata = new MyData(this, s);
		trace(here.methodName + " New connection from "+ cdata.remote_host.toString() + " port: "+ Std.string(cdata.remote_port),2);
		//s.write(Std.string(cdata.sock.seqno));
		s.write("BOO");
		return cdata;
	}

    override public function onReadable( d : MyData, buf : String, bufpos : Int, buflen : Int ) : Int {
		trace("\n>> "+here.methodName + "\n>> buf: "+buf.substr(bufpos,buflen)+"\n>> bufpos: "+bufpos+"\n>> buflen: "+buflen);

        var sb = new StringBuf();
        //sb.add(Std.string(d.sock.seqno));
        //sb.add(":");
        sb.add(buf.substr(bufpos, buflen));
        sb.add(":");
        sb.add(extraData);
        //trace(sb);
        //d.sock.write(Std.string(d.sock.seqno) + ":" + buf.substr(bufpos, buflen) + ":" + sb.toString());
        d.sock.write(sb.toString());

		return buflen;
    }


}
