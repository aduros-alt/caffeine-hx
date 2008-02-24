/*
 * Copyright (c) 2008, The Caffeine-hx project contributors
 * Original author : Russell Weir
 * Contributors:
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE CAFFEINE-HX PROJECT CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE CAFFEINE-HX PROJECT CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

package servers.http.hive;

#if SCHED_REALTIME
import neko.net.servers.RealtimeServer;
#else true
import servers.http.hive.ThreadPollServer;
#end
import neko.net.Host;
import servers.http.hive.TypesHttp;
import config.XmlConfig;
import dates.GmtDate;
import servers.http.hive.Logger;

#if SCHED_REALTIME
class Server extends RealtimeServer<Client> {
#else true
class Server extends ThreadPollServer<Client> {
#end
	public static var SERVER_VERSION 	: String	= "0.4";
	public static var CLIENT_BUFFER_SIZE: Int		= (1 << 16); // 64 KB buffer
	public static var SERVER_THREADS	: Int		= 30;
	public static var LISTEN			: Int		= 200;
	public static var default_host		: String	= "localhost";
	public static var default_port 		: Int		= 3000;
	public static var log_format		: String 	= "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\"";
	public static var debug_level		: Int		= 0;

	public var server_root				: String;
	public var document_root			: String;
	public var log_root					: String;
//	public var state_root				: String;
	public var template_root			: String;
	public var scratch_root				: String;

	public var host						: Host;
	public var port						: Int;
	public var index_names				: Array<String>;
	public var keepalive_enabled		: Bool;
	public var keepalive_timeout		: Int;
	public var connection_timeout		: Int;
	public var data_timeout				: Int;	// timeout for form data etc.

	var access_loggers					: List<Logger>;
	var error_loggers					: List<Logger>;

	var request_serial					: Int;

	var pathsStatic						: Hash<Bool>;

//	public var db(default,null)			: hive.state.Database;
	public var handlers(default,null)	: List<ReqHandler>;

	var xmlConf							: ServerConfig;

	public var stats : {
		headers_in : Hash<Int>,		// to optimize Request.setRequestHeader
	};

	public function new() {
		super();
		config.writeBufferSize = CLIENT_BUFFER_SIZE;
		config.blockingBytes = CLIENT_BUFFER_SIZE >> 2;
		if( config.blockingBytes < (1 << 16) ) // 64 KB
			config.blockingBytes = (1 << 16);
#if SCHED_REALTIME
		config.listenValue = 64*SERVER_THREADS; //50;
		config.threadsCount = SERVER_THREADS;
#else true
		config.listenValue = Math.floor(Math.min(1000, LISTEN));
		config.timeoutRead = 10.0;
		config.timeoutWrite = 10.0;
#end
		config.connectLag = 0.0001;

		server_root = neko.Sys.getCwd();
		host = new neko.net.Host(default_host);
		port = default_port;
		index_names = new Array();
		index_names.push("index.html");
		index_names.push("index.htm");
		keepalive_enabled = true;
		keepalive_timeout = 20;
		connection_timeout = 100;
		data_timeout = 0;

		access_loggers = new List();
		error_loggers = new List();

		pathsStatic = new Hash();
		handlers = new List();

		stats = {
			headers_in: new Hash<Int>(),
		};

		parseArgs();

		server_root = neko.FileSystem.fullPath(server_root);
		var r : EReg = ~/\/$/;
		server_root = r.replace(server_root, "");

		if(!neko.FileSystem.isDirectory(server_root)) {
			neko.Lib.println("Server root path "+server_root+" does not exist");
			usage();
		}
		neko.Sys.setCwd(server_root);

		document_root = server_root + "/public";
		log_root = server_root + "/_log";
//		state_root = server_root + "/_state";
		template_root = server_root + "/_templates";
		scratch_root = server_root + "/_tmp";
		if(!testDirectory(document_root,false)) {
			neko.Lib.println("Error: 'public' directory does not exist");
			usage();
		}
		if(!testDirectory(log_root,true)) {
			neko.Lib.println("Error: '_log' directory does not exist, or can not be written to");
			usage();
		}
/*		if(!testDirectory(state_root,true)) {
			neko.Lib.println("Warning: '_state' directory does not exist");
			usage();
		}
*/		if(!testDirectory(template_root,false)) {
			neko.Lib.println("Error: '_templates' directory does not exist");
			usage();
		}
		if(!testDirectory(scratch_root,true)) {
			neko.Lib.println("Error: '_tmp' directory does not exist, or can not be written to");
			usage();
		}

		var h = new Logger("*", log_root + "/accesslog", log_format);
		access_loggers.add(h);
//		db = new hive.state.Database(state_root);
		mtwin.templo.Loader.BASE_DIR = template_root + "/";
		mtwin.templo.Loader.TMP_DIR = scratch_root + "/";
		mtwin.templo.Loader.MACROS = null;
		request_serial = 0;
	}

	///////////////////////////////////////////////////////////////////////////
	//                         Public API                                    //
	///////////////////////////////////////////////////////////////////////////
	public function registerHandler(pat:String, opt:String, handlerClass:Class<Dynamic>) {
		var e : EReg = new EReg(pat, opt);
		handlers.add ( { hnd:handlerClass, pattern:pat, options:opt, ereg: e } );
	}

	/**
		Register a static file directory. Any path registered this
		way will serve the static html or images from the path.
	*/
	public function registerStatic(path:String) {
		if(path.charAt(0) != "/")
			path = "/" + path;
		if(!testDirectory(document_root+path,false)) {
			neko.Lib.println("Warning: registered static directory " +document_root+path+ " does not exist.");
			return;
		}
		pathsStatic.set(path,true);
	}

	public function start() {
		neko.Lib.println("Hive Server Version " + SERVER_VERSION + " starting up on " + host.toString() + ":" + Std.string(port)+" "+ GmtDate.timestamp());
		neko.Lib.println("Listening for "+config.listenValue + " connections");
		neko.Lib.print("Request parser: ");
#if PARSER_HAXE
		neko.Lib.println("haxe");
#else true
		neko.Lib.println("C");
#end
		neko.Lib.print("Scheduler: ");
#if SCHED_REALTIME
		neko.Lib.print("Realtime");
		neko.Lib.println(" on " + Std.string(SERVER_THREADS) + " threads");
#else SCHED_THREAD_POLL
		neko.Lib.println("ThreadPoll");
#end
		neko.Lib.println("");

		try {
			super.run(host.toString(), port);
		}
		catch( e : String ) {
			if( e == "std@socket_bind" )
				e = "Error : unable to bind to " + port;
			neko.Lib.rethrow(e);
		}
		neko.Lib.println("Hive Server Version " + SERVER_VERSION + " shutdown");
	}

	//
	// Parse commandline arguments
	//
	private function parseArgs() : Array<String> {
		var p = new Array<String>();
		var sc = new ServerConfig();
		for(i in neko.Sys.args()) {
			var parts = i.split("=");
			switch(parts[0]) {
			case "--root":
				if(!neko.FileSystem.isDirectory(parts[1])) {
					neko.Lib.println("Server root "+parts[1]+" does not exist");
					usage();
				}
				sc.serverRoot = parts[1];
			case "--host":
				if(parts[1] == null) {
					neko.Lib.println("Host argument expected.");
					usage();
				}
				sc.host = Std.string(parts[1]);
			case "--config":
				if(parts[1] == null) {
					neko.Lib.println("No file specified for --config");
					usage();
				}
				var f = parts[1];
				try {
					sc.loadFile( f );
				}
				catch(e:XmlConfigError) {
					var msg = "Error loading "+f+" : ";
					switch(e) {
					case FileOpenError:
						msg += "could not open file";
					case FileReadError:
						msg += "error reading file";
					case AlreadyLoaded:
						msg += "config already loaded";
					case XmlParseError(e):
						msg += "xml parse error : " + e;
					case XmlMissingError(e):
						msg += "node missing : "+e;
					}
					neko.Lib.println(msg);
					neko.Sys.exit(1);
				}
			case "--port":
				sc.port = Std.parseInt(parts[1]);
			case "--debug":
				var lvl = Std.parseInt(parts[1]);
				if(lvl>=0 && lvl<=5) {
					debug_level = lvl;
				}
				else {
					neko.Lib.print("Invalid debug level\n");
					usage();
				}
			default:
				usage();
			}
		}

		server_root = sc.serverRoot;
		try {
			host = new neko.net.Host(sc.host);
		}
		catch(e : Dynamic) {
			neko.Lib.println("Host not specified or invalid.");
			usage();
		}
		port = sc.port;
		if(port == null || port < 1 || port > 65535) {
			neko.Lib.print("Port out of range\n");
			usage();
		}
		return p;
	}

	public override function clientConnected( s : neko.net.Socket ) {
		return new Client(this,s);
	}

	public override function clientDisconnected( c : Client ) {
		c.onDisconnected();
	}

	public override function readClientMessage( c : Client, buf : String, pos : Int, len : Int ) {
		var m = c.readFromClient(buf,pos,len);
		if( m == null )
			return null;
		if( m.close != null ) {
trace(here.methodName + " examine this");
			stopClient(c.sock);
			return len;
		}
		return m.bytes;
	}

	public override function clientFillBuffer( c : Client ) {
		c.clientFillBuffer();
	}

#if SCHED_REALTIME
	public override function clientWakeUp( c : Client ) {
		c.clientWakeUp();
	}
#end

	static function usage() {
		neko.Lib.print("\nHive Server Version " + SERVER_VERSION + " (c) 2007\n");
		neko.Lib.print("USAGE: hive [options]\n");
		neko.Lib.print(" Options:\n");
		neko.Lib.print("  --root=/path/\t\tPath to the server root.\n");
		neko.Lib.print("  --host=localhost\t\tThe ip address or hostname to bind to\n");
		neko.Lib.print("  --port=3000\t\t\tThe port to bind to.\n");
		neko.Lib.print("  --debug=[0-5]\t\t\tLevel of trace messages dumped to console.\n");
		neko.Lib.print("  --config=path/to/config.xml\tXML config file path\n");
		neko.Lib.print("  --help\t\t\tThis message.");
		neko.Lib.print("\n");
		neko.Sys.exit(0);
	}

	/**
		Tests if a directory exists, and optionally whether it
		can be written to.
	*/
	public function testDirectory(p:String, needWrite:Bool) : Bool {
		if(!neko.FileSystem.exists(p))
			return false;
		if(!neko.FileSystem.isDirectory(p))
			return false;
		if(needWrite) {
			var s = neko.FileSystem.stat(p);
			if(!(s.mode & 0x80 == 0x80))
				return false;
		}
		return true;
	}

	public static function log_error(d : Client, msg : String, ?level : Int)
	{
		if(level == null || level == 0) level = 1;
		if(level <= debug_level) {
			trace("Error: "+msg);
			//for(i in error_loggers) {
			//	i.log(d);
			//}
		}
	}

	public function log_request(d : Client)
	{
		trace(here.methodName);
		for(i in access_loggers) {
			i.log(d);
		}
	}

	public static function logTrace(s:String, ?level:Int) {
		if(level==null) level = 5;
		if(level <= debug_level) {
			neko.io.File.stdout().write(s+"\n");
			neko.io.File.stdout().flush();
		}
	}
}
