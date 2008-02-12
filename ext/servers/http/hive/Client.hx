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

import neko.FileSystem;
import neko.io.File;
import neko.net.Socket;
import neko.net.Host;
import servers.http.hive.TypesHttp;
import servers.http.Range;

class Client {
#if !PARSER_HAXE
	static var pool	: Array<Dynamic>;
	static var pool_lock : neko.vm.Lock;
#end
	public var server(default,null) 			: Server;
	public var sock(default,null)				: Socket;
	public var output(default,null)				: neko.io.Output;
	public var remote_host						: Host;
	public var remote_port						: Int;
	public var state(default,null)				: ClientState;
	public var request							: Request;
	public var response							: Response;
	public var num_requests						: Int;
	public var timeout(default,null)			: Float;
	public var keepalive(default,setKeepalive)	: Bool;

	public function new(server, s:Socket) {
		this.server = server;
		this.sock = s;
		this.output = s.output;
		this.remote_host = s.peer().host;
		this.remote_port = s.peer().port;
		state = STATE_WAITING;
		request = null;
		response = null;
		num_requests = 0;
		updateTimeout();
		keepalive = true;	// HTTP/1.1 Default
#if !PARSER_HAXE
		if(pool == null) {
			pool = new Array();
			addParsers();
			pool_lock = new neko.vm.Lock();
			pool_lock.release();
		}
#end
	}

#if !PARSER_HAXE
	static function addParsers() {
		neko.Lib.println(here.methodName);
		for(x in 0...Server.SERVER_THREADS) {
			var p = parser_init();
			pool.push(p);
		}
	}

	static function getParser() {
		pool_lock.wait();
		if(pool.length == 0)
			addParsers();
		var p = pool.pop();
		pool_lock.release();
		return p;
	}

	static function returnParser(p:Dynamic) {
		pool_lock.wait();
		try {
			parser_reset(p);
			pool.push(p);
		}
		catch(e:Dynamic) {}
		pool_lock.release();
	}
#end

	/**
		Update the timeout counter.
	**/
	public function updateTimeout() {
		timeout = neko.Sys.time() + server.keepalive_timeout;
#if SCHED_REALTIME
		server.wakeUp(sock, server.keepalive_timeout);
#end
	}

	public function onDisconnected() {
	}

	public function readFromClient( buf:String, pos:Int, len:Int ) :Dynamic {
		//trace("\n>> "+here.methodName + "\n>> buf: "+buf.substr(pos,len)+"\n>> bufpos: "+pos+"\n>> buflen: "+len);
		switch(state) {
		case STATE_WAITING:
			var i = buf.indexOf("\r\n\r\n",pos);
			if(i < 0 || i >= pos + len)
				return null;
			updateTimeout();
			i += 4;
			trace("\n>> "+here.methodName + "\n>> buf: "+buf.substr(pos, i-pos )+"\n>> bufpos: "+pos+"\n>> buflen: "+len);
			var rv = parseRequest( buf.substr(pos, i- pos) );
			if( rv != 200 ) {
/*
				keepalive = false;
				response.setStatusMessage(rv);
				response.prepare();
				response.send();
*/
//trace(response.status);
//trace(keepalive);
				state = STATE_CLOSING;
				closeConnectionMessage(rv);
				return { bytes: i - pos };
			}
			if(state != STATE_DATA) {
				startResponse();
			}
			return { bytes: i - pos };
		case STATE_DATA:
			updateTimeout();
			request.addPostData(buf, pos, len);
			if(request.postComplete()) {
				request.finalizePost();
				state = STATE_PROCESSING;
				startResponse();
			}
			return { bytes: len };
		case STATE_READY:
		case STATE_PROCESSING:
		case STATE_FILE:
		case STATE_KEEPALIVE:
			state = STATE_WAITING;
			return readFromClient( buf, pos, len );
		case STATE_CLOSING:
			return { bytes: len }; // consume
		case STATE_CLOSED:
			return { bytes: len }; // consume
		}
		return null;
	}

	function parseRequest( s ) : Int {
		updateTimeout();
		num_requests ++;
		request = new Request(this, num_requests);
		response = new Response(this);

		var rv : Int;
#if PARSER_HAXE
		try {
			rv = request.parse(s);
		}
		catch(e:Dynamic) { return 400; }
#else true
		var parser = getParser();
		try {
			rv = request.parse(s, parser);
		}
		catch(e:Dynamic) {
			returnParser(parser);
			return 400;
		}
		returnParser(parser);
#end
		if(rv != 200)
			return rv;
		state = STATE_PROCESSING;
		// are we waiting for multipart data?
		//Content-Type: application/x-www-form-urlencoded
		//Content-Length: 31
		// or
		//Content-Type: multipart/form-data; boundary=----------Jud
		//Content-Length: 300000
		if( request.in_content_type != null) {
			trace(here.methodName + " Switching to STATE_DATA for content_length "+request.in_content_length);
			// TODO: Check states, and make .state(get,null)
			if(!request.startPost()) {
				return 400;
			}
			state = STATE_DATA;
			return 200;
		}
		return rv;
	}

	public function startResponse() : Void {
		state = STATE_PROCESSING;
		updateTimeout();
		// process url -> path + args
		if(! request.processUrl()) {
			if(response.status != 304) { // not modified
				//logTrace("URL invalid",4);
			}
			closeConnectionMessage();
			return;
		}
		if(!checkPath()) {
			setResponse(403);
			closeConnectionMessage();
			return;
		}

		switch(translatePath()) {
		case COMPLETE:
			return;
		case SKIP:
		case ERROR:
			if(response.status < 300)
				setResponse(404);
			closeConnectionMessage();
			return;
		case PROCESSING:
			return;
		}
		response.prepare();
		response.send();	// handles connection closing
	}

	function scheduleClose() : Void {
		trace(here.methodName);
		state = STATE_CLOSING;
	}

	function closeConnection() : Void {
		state = STATE_CLOSED;
		server.stopClient(sock);
	}

	function closeConnectionMessage(?status:Int) : Void {
		trace(here.methodName + " status: "+status);
		if(sock == null)
			return;
		keepalive = false;
		var url = request.url;
		if(status != null)
			response.setStatus(status);
		if(response.status == 301)
			url = response.location;
		response.setMessage(Response.codeToHtml(response.status, url));
		response.prepare();
		response.send();
		scheduleClose();
	}

	public function onInternalError( e : Dynamic ) {
		trace(here.methodName);
		setResponse(500);
		response.setMessage(Response.codeToHtml(500));
		keepalive = false;
		response.prepare();
		response.send();
		scheduleClose();
	}

	function closeConnectionTimeout() {
		trace(here.methodName);
		closeConnection();
	}

	public function endRequest() : Void {
		updateTimeout();
		closeFile();
		if(keepalive) {
			state = STATE_KEEPALIVE;
		}
		else {
			state = STATE_CLOSING;
			timeout = neko.Sys.time() - 2;
#if SCHED_REALTIME
			server.wakeUp(sock, 0);
#else SCHED_THREAD_POLL
			server.stopClient(sock);
#end
		}
	}

	/** Set response code for current request */
	public function setResponse(val : Int) : Void {
		if(request != null && response != null) {
			response.setStatus(val);
		}
		else {
			throw( new String("req not initialized"));
		}
	}

	/** Close current file associated with request */
	public function closeFile() : Void {
		if(response != null && response.file != null) {
			response.file.close();
		}
	}

	function setKeepalive(v:Bool) : Bool {
		if(v && server.keepalive_enabled) {
			keepalive = true;
		}
		else keepalive = false;
		return v;
	}

	public function setState(s:ClientState) {
		state = s;
	}



	/**
		Cleans up the uri and ensures it does not escape the document root (../../)
		does not set an error code
		Called after processUrl which urlDecodes the url
	**/
	function checkPath() : Bool {
		trace(here.methodName);
		var trail : Bool = { if(request.path.charAt(request.path.length-1) == "/") true; else false; }
		var items = request.path.split("/");
		var i : Int = 0;
		var newpathitems : Array<String> = new Array();
		for( x in 0 ... items.length ) {
			if(items[x] == null || items[x].length == 0)
				continue;
			if(items[x] == ".")
				continue;
			if(items[x] == "..") {
				if(newpathitems.length == 0)
					return false;
				continue;
			}
			// dot files, dot directories
			if(items[x].charAt(0) == ".")
				return false;
			// home dirs
			if(items[x].charAt(0) == "~")
				return false;
			newpathitems.push(items[x]);
		}
		request.path = "";
		if(newpathitems.length > 0) {
			for( p in newpathitems) {
				request.path += "/" + p;
			}
			if(trail) {
				request.path += "/";
			}
		}
		else request.path = "/";
		//trace(here.methodName + " new path: " + request.path);
		return true;
	}

	/**
		Translate a path to actual file type, checks for
		index docs on directories and symlinks, 404's any
		pipe or other special files, or any file that can
		not be opene
	**/
	function translatePath() : PluginState {
		trace(here.methodName);
		request.path_translated = server.document_root;
		request.uriparts = request.path.split("/");
		request.uriparts.shift();

		for( h in server.handlers ) {
			var e = new EReg(h.pattern, h.options);
			if(e.match(request.path)) {
				response.setStatus(200);
				var rv = handlerProcessRequest(h,e);
				switch(rv) {
				case COMPLETE:
					//closeConnection();
					return rv;
				case ERROR:
					//onInternalError(null);
					response.status = 500;
					return rv;
				case PROCESSING:
					return rv;
				case SKIP:
				}
			}
		}

		// hook _hTranslate
		/*
		for ( i in plugins ) {
			try {
				var func = Reflect.field(i, "_hTranslate");
				if (Reflect.isFunction(func)) {
					var rv : Int = Reflect.callMethod(i,func,[this,request,response]);
					switch(rv) {
					case COMPLETE:
						if(response.status < 100) {
							log_error(d,"Module "+i.name+" did not set response code");
							response.setStatus(200);
						}
						return rv;
					case ERROR:
						onInternalError(d, null);
						return rv;
					case PROCESSING:
						return rv;
					case SKIP:
					}
				}
			}
			catch (e:Dynamic) {
				logTrace(e,0);
				onInternalError(d, e);
				return ERROR;
			}
		}
		*/

		if(response.status == 500) {
			onInternalError(null);
			return ERROR;
		}

		var p = request.path;
		request.path_translated += p;
#if DEBUG_REQUEST
		logTrace(here.methodName + " final: " + request.path_translated,2);
#end

		try {
			switch(FileSystem.kind(request.path_translated)) {
			case kdir:
				if(!checkDirIndex()) {
					setResponse(404);
					return ERROR;
				}
			case kother(k):
				if(k != "symlink") {
					setResponse(404);
					return ERROR;
				}
				if(!checkDirIndex()) {
					setResponse(404);
					return ERROR;
				}
			case kfile:
				if(!response.openFile(request.path_translated)) {
					setResponse(404);
					return ERROR;
				}
			}
		}
		catch(e : Dynamic) { // file not found
			setResponse(404);
			return ERROR;
		}

		if(!processFile()) {
			if(response.status < 300)
				setResponse(404);
			return ERROR;
		}
		state = STATE_FILE;
		return SKIP;
	}

	function checkDirIndex() : Bool {
		trace(here.methodName);
		if(request.path_translated.length < 1 ||
			request.path_translated.charAt(request.path_translated.length-1) != "/")
		{
			setResponse(301);
			response.location = "http://" + request.host;
			if(request.port != 0) response.location += ":" + Std.string(request.port);
			response.location += request.path+"/";
			return false;
		}
		var found = false;
		for(i in server.index_names) {
			if(response.openFile(request.path_translated + i)) {
				found = true;
				break;
			}
		}
		if(! found) return false;
		return true;
	}

	/**
		Ignore POSTS to files
		Check for status of modified since requests, range
		and if-range requests.
		Called from translatePath()
	**/
	function processFile() : Bool {
		trace(here.methodName);
		if(request.if_modified_since != null) {
			//trace("HAS MODIFIED DATE file: " + response.last_modified.rfc822timestamp() + " browser: "+ request.if_modified_since.rfc822timestamp());
			if(response.last_modified.lt(request.if_modified_since) || response.last_modified.eq(request.if_modified_since)) {
				//trace("File not modified");
				setResponse(304);
				closeFile();
				return false;
			}
		}
		// TODO
		// if_unmodified_since
		// if-range
		// check ranges validity
		// copy ranges to response
		if(request.in_ranges != null) {
			Range.satisfyAll(request.in_ranges, response.content_length);
		}
		response.bytes_left = response.content_length;
		//
		setResponse(200);
		return true;
	}

	public function fileResponseFillBuffer() {
		// TODO: Multipart/ranges
		if(response.bytes_left == null)
			throw "fileResponseFillBuffer null bytes_left";

		// when finished
		if(response.bytes_left <= 0) {
			endRequest();
			return 0;
		}

		var nbytes = response.bytes_left;
		if(nbytes > server.config.writeBufferSize)
			nbytes = server.config.writeBufferSize - 1;

		var s = response.file.read(nbytes);
		//clientWrite(sock, s, 0, s.length);
		output.writeFullBytes(s,0,s.length);
		response.bytes_left -= nbytes;

		return 0;
	}


	function handlerProcessRequest(h:ReqHandler,matched:EReg) : PluginState
	{
		trace(here.methodName);
		state = STATE_PROCESSING;
		var inst:Dynamic;
		try {
			inst = Type.createInstance(h.hnd,[server, this, matched]);
		}
		catch(e:Dynamic) {
			trace("INSTANCE CREATION FAILURE");
			return ERROR;
		}
		if(inst == null) {
			trace("INSTANCE CREATION FAILURE");
			neko.Sys.exit(1);
		}

		if(true) {
			inst.processRequest();
			return PROCESSING;
		}
		try {
			//var t = neko.vm.Thread.create(callback(hndThread,inst));
			//var t = ThreadExtra.create(callback(hndThread,inst));
			//untyped inst.thread = t;
		}
		catch(e:Dynamic) {
			trace("HIVE THREAD CREATION FAILURE");
			return ERROR;
		}
		return PROCESSING;
	}

	function hndThread(inst) {
		try {
			inst.processRequest();
		}
		catch(e:Dynamic) {
			trace(here.methodName + " " + e);
			//ThreadExtra.exit();
		}
	}

	public function clientFillBuffer() {
		trace(here.methodName);
		switch(state) {
		case STATE_FILE:
			updateTimeout();
			fileResponseFillBuffer();
		case STATE_KEEPALIVE:
			if(!keepalive) {
				trace("clientFillBuffer forcing close state " + state);
				closeConnection();
			}
		default:
			trace("Unhandled state in "+here.methodName);
		}
	}

	public function clientWakeUp() {
		if(state == STATE_CLOSED)
			return;
		trace(here.methodName);
		if(neko.Sys.time() >= timeout) {
			closeConnectionTimeout();
			return;
		}
	}
#if !PARSER_HAXE
	static var parser_init = neko.Lib.load("httpp","httpp_init",0);
	static var parser_reset = neko.Lib.load("httpp","httpp_reset",1);
#end
}
