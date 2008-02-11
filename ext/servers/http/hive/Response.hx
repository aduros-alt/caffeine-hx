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

import neko.io.File;
import neko.io.FileInput;
import neko.FileSystem;

import servers.http.hive.TypesHttp;
import protocols.Mime;
import protocols.http.Cookie;
import dates.GmtDate;

class Response {
	static var codemap : IntHash<String>;
	static var htmlmap : IntHash<String>;
	static var initialized : Bool		= false;

	//public var client(default,null)			: HttpdClientData;
	public var client(default,null)				: Client;
	public var status(default,setStatus)		: Int;
	public var headers							: Hash<String>;
	public var headers_sent						: Bool;
	public var cookies							: List<Cookie>;
	public var type								: ResponseType;
	public var message							: String;
	public var file								: FileInput;
	public var bytes_left						: Int;
	public var content_count					: Int;
	public var content_type					 	: String;
	public var content_length 					: Int;
	//public var content_boundary(default,null)	: String;
	public var content_boundary					: String;
	public var transfer_encoding				: String;
	public var last_modified					: GmtDate;
	public var location							: String;
	public var ranges							: Array<Range>;
	public var multipart						: Bool;

	public function new(client:Client) {
		this.client = client;
		status = 0;
		headers = new Hash();
		headers_sent = false;
		cookies = new List();
		type = TYPE_UNKNOWN;
		message = null;
		file = null;
		bytes_left = null;
		content_count = 0;
		content_type = null;
		content_length = 0;
		content_boundary = null; //generateContentBoundary();
		transfer_encoding = null;
		last_modified = null;
		location = null;
		ranges = null;
		multipart = false;
	}

	public function getMainModuleResponse() {
		return this;
	}

	public function setStatus(code:Int) {
		status = code;
		return status;
	}

	public function setStatusMessage(code:Int) {
		status = code;
		setMessage(codeToHtml(code));
		return status;
	}

	public function setHeader(key : String, value : String) : Void
	{
		var klc = key.toLowerCase();

		// The are handled when
		// generating response header
		if(klc == "date") return;
		if(klc == "server") return;
		//if(klc == "connection") return;
		// last content type in gets the prize.
		if(klc == "content-type") {
			content_type = value;
			return;
		}
		if(klc == "transfer-encoding") {
			transfer_encoding = value;
			return;
		}
		headers.set(key, value);
	}

	public function setHeaderIfNotSet(key:String, value:String) : Void
	{
		var klc = key.toLowerCase();
			if(klc == "date") return;
		if(klc == "server") return;
		if(klc == "content-type") {
			if(content_type != null)
				return;
			content_type = value;
			return;
		}
		if(klc == "transfer-encoding") {
			if(transfer_encoding != null)
				return;
			transfer_encoding = value;
			return;
		}
		headers.set(key, value);
	}

	public function setMessage(value : String) : Void
	{
		content_type = "text/html";
		content_length = value.length;
		content_count = 1;
		last_modified = null;
		message = value;
	}


	/**
		Prepare appropriate headers for the response.
		Used mainly for serving static content.
	*/
	public function prepare() {
		//trace(here.methodName + " response code: "+ status);
		if(content_type != null)
			setHeader("Content-Type", content_type);

		if(content_count > 0 && status != 206) {
			if(last_modified != null)
				setHeader("Last-Modified", last_modified.rfc822timestamp());
			if(message != null)
				setHeader("Content-Length", Std.string(message.length));
			else
				setHeader("Content-Length", Std.string(content_length));
		}

		switch(status) {
		case 206: // partial content
			if(! multipart) {
				setHeader("Content-Type", content_type);
				setHeader("Content-Range", "bytes " + ranges[0].off_start + "-" + ranges[0].off_end + "/" + content_length);
			}
			else {
				setHeader("Content-Type", "multipart/byteranges; boundary="+content_boundary);
			}
			// in the case of multipart, the content-type for the file is sent in the
			// multipart sections
		case 301:
			if(location != null)
				setHeader("Location", location);
		case 302:
			if(location != null)
				setHeader("Location", location);
		case 401:
			setHeader("WWW-Authenticate", "Basic realm=myrealmchangeme");
		case 405:
			setHeader("Allow","GET, POST, HEAD");
		case 416:
			// A server SHOULD return a response with this status code if a request
			// included a Range request-header field (section 14.35), and none of
			// the range-specifier values in this field overlap the current extent
			// of the selected resource, and the request did not include an If-Range
			// request-header field. (For byte-ranges, this means that the first-
			// byte-pos of all of the byte-range-spec values were greater than the
			// current length of the selected resource.)
			// When this status code is returned for a byte-range request, the
			// response SHOULD include a Content-Range entity-header field
			// specifying the current length of the selected resource (see section
			// 14.16). This response MUST NOT use the multipart/byteranges content-
			// type.

			setHeader("Content-Range", "bytes */"+content_length);

			// which means... what, return only satisfiable ranges, and silently
			// ignore the rest??
		}

		if (client.request.in_content_length > 0 || client.request.in_transfer_encoding != null) {
			client.keepalive = false;
		}

		// 300s are redirects, not modified
		if(status < 300 || status == 301 || status == 302) {
			if(client.keepalive == true && client.request.version_minor == 0) {
				setHeader("Connection", "keep-alive");
			}
			else if(client.request.version_minor > 0 || client.keepalive == false) {
				setHeader("Connection", "close");
			}
		}
		else {
			setHeader("Connection", "close");
		}
	}


	public function createHeader() : String {
		var head = new StringBuf();
		head.add("HTTP/1.1 ");
		head.add(Response.codeToText(status));
		head.add("\r\nDate: ");
		head.add(GmtDate.timestamp());
		head.add("\r\nServer: HxTTPD\r\n");
		for(i in headers.keys()) {
			head.add(i);
			head.add(": ");
			head.add(headers.get(i));
			head.add("\r\n");
		}
		if(transfer_encoding != null) {
			head.add("Transfer-Encoding: ");
			head.add(transfer_encoding);
			head.add("\r\n");
		}
		if(content_type != null) {
			head.add("Content-Type: ");
			head.add(content_type);
			head.add("\r\n");
		}
		// cookies
		//neko.Lib.println(here.methodName + " cookie count "+cookies.length);
		for(c in cookies) {
			head.add(c.toString());
			head.add("\r\n");
		}

		head.add("\r\n");

		return(head.toString());
	}

	public function send() {
		// TODO not the place to log?
		client.server.log_request(client);
		var hs = createHeader();
		client.output.writeFullBytes( hs, 0, hs.length);
		headers_sent = true;

		if(message != null) {
			client.output.writeFullBytes( message, 0, message.length);
			client.setState(STATE_CLOSING);
		}
		else {
			// add them as a writesocket as there
			// is file data to send to client
			//client.server.addWriteSock(client.sock);
		}
	}

	public function startChunkedResponse() {
		// TODO not the place to log?
		client.server.log_request(client);

		transfer_encoding = "chunked";
		var hs = createHeader();
		client.output.writeFullBytes( hs, 0, hs.length);
		headers_sent = true;
		content_length = 0;
	}

	public function sendChunk(chunk:String) {
		// length hex\r\n
		// chunk
		// \r\n
		//[length hex..n]
		if(chunk == null) return;
		var l : String = StringTools.hex(chunk.length);
		client.output.writeFullBytes(l,0,l.length);
		client.output.writeFullBytes("\r\n",0,2);
		client.output.writeFullBytes(chunk,0,chunk.length);
		client.output.writeFullBytes("\r\n",0,2);
		content_length += chunk.length;
	}

	public function endChunkedResponse() {
		client.output.writeFullBytes("0\r\n\r\n",0,5);
	}

	public function openFile( filename : String) : Bool {
		if( file != null ) {
			Server.log_error(client, "Request already has an open file");
			return false;
		}
		try {
			file = File.read(filename, true);
		}
		catch(e : Dynamic) { file = null; return false; }
		type = ResponseType.TYPE_FILE;
		var stat = FileSystem.stat( filename );
		last_modified = GmtDate.fromLocalDate(stat.mtime);
		if(last_modified.gt(GmtDate.now())) {
			Server.log_error(client, "File "+filename+" has a modification date in the future");
			last_modified = GmtDate.now();
		}
		content_length = stat.size;
		content_count = 1;
		setMimeType(filename);
		//trace(here.methodName + " file: " + filename + " size: " + stat.size);
		return true;
	}

	function setMimeType(filename : String) : Bool {
		content_type = "unknown/unknown";
		var r : EReg = ~/\.([0-9A-Za-z]+)$/;
		r.match(filename);
		try {
			content_type = Mime.extensionToMime(r.matched(1));
		}
		catch(e :Dynamic) {}
		//trace(here.methodName + " " + content_type);
		return true;
	}

	public function setCookie(c:Cookie) {
		cookies.add(c);
	}

	////////////////////////////////////////////////////////////////////////////
	//                      Static Methods                                    //
	////////////////////////////////////////////////////////////////////////////

	static public function staticsInit() {
		// must be done first, html init below relies on
		// codemap being setup already
		initialized = true;

		codemap = new IntHash<String>();
		// http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html
		codemap.set(100, "Continue");
		codemap.set(101, "Switching Protocols");
		codemap.set(200, "OK");
		codemap.set(201, "Created");
		codemap.set(204, "No Content");
		codemap.set(206, "Partial Content");
		codemap.set(301, "Moved Permanently");
		codemap.set(302, "Moved");
		codemap.set(304, "Not Modified");
		codemap.set(307, "Temporary Redirect");
		codemap.set(400, "Bad Request");
		codemap.set(401, "Not Authorized");
		codemap.set(403, "Forbidden");
		codemap.set(404, "Not Found");
		codemap.set(405, "Method Not Allowed");
		codemap.set(411, "Length Required");
		codemap.set(412, "Precondition Failed");
		codemap.set(414, "Request-URI Too Long");
		codemap.set(416, "Requested Range Not Satisfiable");
		codemap.set(417, "Expectation Failed");
		codemap.set(500, "Internal Server Error");
		codemap.set(501, "Method Not Implemented");
		codemap.set(503, "Service Unavailable");
		codemap.set(505, "HTTP Version Not Supported");

		// TITLE MSG SERVERNAME for initialization
		// ~URL~
		// for 0 only ~CODESTR~
		var html : String = "<!DOCTYPE HTML PUBLIC \"-//IETF//DTD HTML 2.0//EN\">\n<html>\n<head><title>~TITLE~</title>\n</head><body>\n<h1>~TITLE~</h1>\n<p>~MSG~</p>\n<HR>\n<ADDRESS>~SERVERNAME~</ADDRESS>\n</body>\n</html>\n";
		htmlmap = new IntHash<String>();
		htmlmap.set(0, initHtml(html,"~CODESTR~", ""));
		htmlmap.set(301, initHtml(html,codeToText(301), "The document has moved <a href=\"~URL~\">here</a>."));
		htmlmap.set(400, initHtml(html,codeToText(400), "Your browser sent a request that this server could not understand."));
		htmlmap.set(403, initHtml(html,codeToText(403), "You don't have permission to access ~URL~ on this server."));
		htmlmap.set(404, initHtml(html,codeToText(404), "The requested URL ~URL~ was not found on this server."));
		htmlmap.set(414, initHtml(html,codeToText(414), "The URI ~URL~ supplied by your browser is too long."));
		htmlmap.set(417, initHtml(html,codeToText(417), "Expectation can not be met by this server."));
		htmlmap.set(500, initHtml(html,codeToText(500), "The server encountered an internal error."));
		htmlmap.set(501, initHtml(html,codeToText(501), "The server does not handle this type of request."));
		htmlmap.set(505, initHtml(html,codeToText(505), "The server does not speak this version of the HTTP protocol."));
	}

	static function initHtml(html:String,title:String,msg:String) : String {
		var r : EReg = ~/~TITLE~/g;
		html = r.replace(html, title);
		r = ~/~MSG~/g;
		html = r.replace(html, msg);
		return html;
	}


	static public function codeToText(val : Int) : String {
		if(!initialized) staticsInit();
		if(codemap.exists(val))
			return ("" + val + " " + codemap.get(val));
		return "" + val;
	}

	static public function codeToHtml(val : Int, ?requrl : String) : String {
		if(!initialized) staticsInit();
		if(requrl == null) requrl = "";
		var s : String;
		var r : EReg;
		if(htmlmap.exists(val))
			s = htmlmap.get(val);
		else {
			s = htmlmap.get(0);
			r = ~/~CODESTR~/g;
			s = r.replace(s, codeToText(val));
		}
		r = ~/~URL~/g;
		s = r.replace(s, requrl);
		r = ~/~SERVERNAME~/g;
		s = r.replace(s, "HxTTPD");
		return s;
	}

	/**
		Create a response content boundary string.
		TODO: This should notbe called on initialization
			of the request
	**/
	public static function generateContentBoundary() : String {
		var s : String = "------------";
		for(x in 0...55) {
			var r = Std.random(62);
			if(r < 10) { // 0-9
				s += Std.chr(48 + r);
			}
			else if(r < 36) { // A-Z
				s += Std.chr(55 + r);
			}
			else { // a-z
				s += Std.chr(61 + r);
			}
		}
		return s;
	}

}
