class CryptServer {

	public static var clients = new List<ClientData>();

	public static var trs(default,null) : neko.net.ThreadRemotingServer;
	public static var ip(default,null) : String;
	public static var port(default,null) : Int;
	public static var serverid(default,null) : Int;

	static var lock 		: neko.vm.Lock;
	static var requestid 		: Int;

	static var log			: neko.io.FileOutput;
	static var logLock 		: neko.vm.Lock;

	static var worker 		: neko.vm.Thread;


	/////////////////////////////////////////////
	//                 Main                    //
	/////////////////////////////////////////////
	static function main() {
		trs = new neko.net.servers.EncThrRemotingServer();
		trs.initClientApi = initClientApi;
		trs.clientDisconnected = onClientDisconnected;
		lock = new neko.vm.Lock();
		lock.release();

		ip = neko.Sys.args()[0];
		port = Std.parseInt(neko.Sys.args()[1]);
		var mip = neko.Sys.args()[2];
		var mport = Std.parseInt(neko.Sys.args()[3]);
		if(ip == null || port == 0 || mip == null || mport == 0) {
			neko.Lib.print("usage: server ip port masterip masterport");
			neko.Sys.exit(1);
		}

		initLog();
		trs.run(ip, port);
	}


	/////////////////////////////////////////////
	// ThreadRemotingServer Overrides          //
	/////////////////////////////////////////////
	static function initClientApi( scnx : haxe.remoting.SocketConnection, rserver : neko.net.RemotingServer ) {
		trace("Client connected");
		var c = new ClientData(scnx,rserver);
	}

	static function onClientDisconnected( scnx ) {
		trace("Client disconnected");
		ClientData.ofConnection(scnx).leave();
	}


	/////////////////////////////////////////////
	//            Logging                      //
	/////////////////////////////////////////////
	static function initLog() : Bool {
		logLock = new neko.vm.Lock();
		logLock.release();
		log = neko.io.File.stderr();
		return true;
	}

	public static function logError(s:String, e : Dynamic) {
		var stack = haxe.Stack.exceptionStack();
		if(stack == null || stack.length == 0)
			stack = haxe.Stack.callStack();
		var estr = try Std.string(e) catch( e2 : Dynamic ) "???" + try "["+Std.string(e2)+"]" catch( e3 : Dynamic ) "";
		var sstr = " - " + haxe.Stack.toString(stack);
		sstr = StringTools.replace(sstr, "\n", "\n - ");
		logLock.wait();
		log.write( s + ": " + estr + "\n" + sstr + "\n" );
		log.flush();
		logLock.release();
	}
}
