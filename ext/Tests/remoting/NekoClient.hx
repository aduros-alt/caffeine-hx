class ServerApiImpl extends haxe.remoting.AsyncProxy<IServerApi> {
}

import crypt.Aes;
import hash.Sha1;
import haxe.remoting.EncRemotingAdaptor;

class NekoClient implements IClientApi {

	var rs : neko.net.RemotingServer;
	var sock : neko.net.Socket;
	var scnx : haxe.remoting.SocketConnection;
	var api : ServerApiImpl;
	var ra : EncRemotingAdaptor;

	var buf : String;
	var bufpos : Int;
	var maxBufferSize : Int;
	var messageHeaderSize : Int;
	var authenticated : Bool;

	var username : String;
	var password : String;

	static var worker : neko.vm.Thread;

	public function new(host:neko.net.Host, port:Int, username:String, password:String) {
		buf = neko.Lib.makeString(1 << 10);
		bufpos = 0;
		maxBufferSize = (1 << 16);
		messageHeaderSize = 2;
		authenticated = false;

		rs = new neko.net.RemotingServer();
		rs.addObject("inst", this);

		sock = new neko.net.Socket();
		sock.connect(host, port);
		sock.setBlocking(false);

		scnx = haxe.remoting.SocketConnection.socketConnect(sock,rs);
		api = new ServerApiImpl(scnx.api);
		ra = new EncRemotingAdaptor(scnx);

		this.username = username;
		this.password = password;
	}

	public function loginFailed() : Void {
		trace(here.methodName);
	}

	public function startEncSession() : Void {
		trace(here.methodName);
		authenticated = true;
		ra.startCrypt(new crypt.ModeCBC(new Aes(128, password)));
		api.join();
	}

	public function userJoin( name : String ) : Void {
		print("** " + name + " has joined\n");
	}

    public function userLeave( name : String ) : Void {
		print("** " + name + " has left\n");
	}

    public function userSay( name : String, text: String) : Void {
		print(name + "> " + text + "\n");
	}

	function print(s:String) {
		neko.Lib.print(s);
	}

	public function run() {
		var passcrypt = hash.Sha1.encode(password);

		var x = 0;
		while(!authenticated) {
			api.identify(username,passcrypt);
			trace(">> processing response");
			waitForResponse();
			trace(">> processing finished "+ authenticated);
			x++;
		}

		worker = neko.vm.Thread.create(callback(workerThread, neko.vm.Thread.current()));
		while(true) {
			var l = neko.io.File.stdin().readLine();
			api.say(l);
		}
	}

	function workerThread(parent : neko.vm.Thread) {
		while(true) {
			try {
			var socks = neko.net.Socket.select([sock],null,null,0.);
				for(i in socks.read) {
					try {
#if DEBUG_PROTOCOL
						trace("data received");
#end
						readResponse();
					}
					catch(e:Dynamic) {
						if(Std.is(e, neko.io.Eof)) {
							print("*** SERVER DISCONNECTED ***\n");
						}
						else {
							logError(e);
						}
						neko.Sys.exit(0);
						return;
					}
				}
			}
			catch(e : Dynamic) {
				trace(e);
			}
		}
	}

	function waitForResponse() {
		while(true) {
			sock.waitForRead();
			if(readResponse(true) > 0)
				break;
		}
		return true;
	}

	function readResponse(?oneOnly : Bool) {
		var msgCount = 0;
		var available = buf.length - bufpos;
		if( available == 0 ) {
			var newsize = buf.length * 2;
			if( newsize > maxBufferSize ) {
				newsize = maxBufferSize;
				if( buf.length == maxBufferSize )
					throw "Max buffer size reached";
			}
			var newbuf = neko.Lib.makeString(newsize);
			neko.Lib.copyBytes(newbuf,0,buf,0,bufpos);
			buf = newbuf;
			available = newsize - bufpos;
		}
		var bytes = sock.input.readBytes(buf,bufpos,available);
		var pos = 0;
		var len = bufpos + bytes;
		while( len >= messageHeaderSize ) {
			var m = EncRemotingAdaptor.readClientMessage(scnx,buf,pos,len);
			if( m == null )
				break;
			pos += m.bytes;
			len -= m.bytes;
			msgCount ++;
#if DEBUG_PROTOCOL
			trace(m.msg);
#end
			scnx.processMessage(m.msg);
			if(oneOnly) {
				break;
			}
		}
		if( pos > 0 )
			neko.Lib.copyBytes(buf,0,buf,pos,len);
		bufpos = len;
		return msgCount;
	}

	public static function main() {
		var h = neko.Sys.args()[0];
		var p = Std.parseInt(neko.Sys.args()[1]);
		var user = neko.Sys.args()[2];
		var pass = neko.Sys.args()[3];
		if(h == null || p == 0 || user == null || pass == null || user == "" || pass=="") {
			usage();
		}
		var c = new NekoClient(new neko.net.Host(h), p, user , pass);
		c.run();
	}

	static function usage() {
		neko.Lib.println("neko nekoclient.n host port username password");
		neko.Lib.println("Valid passwords for this example are:");
		neko.Lib.println("mypass passw0rd mango23");
		neko.Sys.exit(1);
	}

	function logError(e : Dynamic) {
		var estr = try Std.string(e) catch( e2 : Dynamic ) "???" + try "["+Std.string(e2)+"]" catch( e3 : Dynamic ) "";
		print(estr+"\n");
	}
}
