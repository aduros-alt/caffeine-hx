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

import haxe.Stack;
import Type;
import protocols.http.Cookie;
import servers.http.hive.TypesHttp;
import servers.http.hive.Server;

class Handler {
	public var Request	: Request;
	public var Response	: Response;
	var client			: Client;
	public var _ENV(get_ENV,null)			: Hash<Dynamic>;
	public var _GET(get_GET,null)			: Hash<Dynamic>;
	public var _POST(get_POST,null) 		: Hash<Dynamic>;
	public var _GETPOST(get_GETPOST,null)	: Hash<Dynamic>;
	public var _COOKIE(get_COOKIE,null)		: Hash<Dynamic>;
	public var _SERVER(get_SERVER,null)		: Hash<Dynamic>;
	public var _REQUEST(get_REQUEST,null)	: Hash<Dynamic>;
	public var _FILES(get_FILES,null)		: Hash<Resource>;

	var hive			: Server;
	var buffer			: StringBuf;
	var bufcount		: Int;

	/**
		Each client has an output buffer, for buffering output.
		This is 4K by default.
	**/
	public static var MAX_OUTBUFSIZE = (1 << 12);

	public function new(server:Server, client:Client) {
		this.hive = server;
		this.client = client;
		this.Request = client.request;
		this.Response = client.response;
		this.Response.setHeader("Content-Type", "text/html");
#if HIVE_NO_KEEPALIVE
		client.keepalive = false;
#end
		if(!client.keepalive)
			this.Response.setHeader("Connection","close");
		buffer = new StringBuf();
		bufcount = 0;
		_POST = null;
	}

	function finalize() {
		trace(here.methodName);
		try {
			if(!Response.headers_sent) {
				Response.startChunkedResponse();
			}
			flushbuffer();
			Response.endChunkedResponse();
		} catch(e:Dynamic) {
			trace("Error flushing thread buffer. " + e);
			neko.Lib.rethrow(e);
		}
	}

	public function flushbuffer() {
		var s = buffer.toString();
		try {
			if(s.length > 0) {
				Response.sendChunk(s);
				bufcount = 0;
				buffer = new StringBuf();
			}
		}
		catch(e:Dynamic) {
			trace("Error flushing thread buffer. " + e);
			neko.Lib.rethrow(e);
		}
	}

	//public function loadTemplate(n:String) {
	//	template = new mtwin.templo.Loader(n);
	//}

	public function createEmptyObject() : Dynamic {
		return Reflect.empty();
	}

	public function runTemplate(name:String, c:Dynamic) : String {
		var template = new mtwin.templo.Template(name);
		return template.execute(c);
	}
	/**
		Do not override or call this function. It is called
		automatically at the beginning of each client request,
		and will call handleRequest() when it is ready for
		your handler to continue.
	*/
	public function processRequest() {
		try {
			//trace("Handler handling request");
			handleRequest();
			//trace("Handler finalizing request");
			finalize();
		}
		catch(e:Dynamic) {
			trace("Handler error "+e);
			//trace(e);
			//trace(haxe.Stack.exceptionStack());
			err(e, null, haxe.Stack.exceptionStack());
			if(Response.status == 0)
				Response.status = 500;
		}
		//trace("Handler done");
		try {
			Request.client.setState(STATE_KEEPALIVE);
		}
		catch(e:Dynamic) {
			trace(e);
		}
	}


	/**
		When creating an instance of Hive, this method must
		be overridden, and is the main entry point of that
		handles each client request.
	*/
	public function handleRequest() : Void {
		throw "entryPoint not overridden";
	}

	///////////////////////////////////////////////////////////////////////////
	//                     STATIC METHODS                                    //
	///////////////////////////////////////////////////////////////////////////
	public static function exit() {
		trace(here.methodName);
		//ThreadExtra.exit();
	}

	public function err(msg, ?stack:Array<haxe.StackItem>,?exception:Array<haxe.StackItem>) {
		trace(here.methodName);
		printbr("");
		println("<hr>");
		println("<h1>ERROR: " + Std.string(msg)+"</h1>");
		println("<hr>");
		if(stack != null) {
			println("<h2>Call stack</h2>");
			// remove ModHive
			//stack.shift();
			//remove VmModule
			//stack.shift();
			//remove Reflect
			//stack.shift();
			var foundEntry = false;
			for(i in stack) {
				switch( i ) {
                        	case CFunction:
					foundEntry = true;
                        	case Module(m):
					if(foundEntry) {
                                		print("module ");
                                		printbr(m);
					}
                        	case FilePos(name,line):
					if(foundEntry) {
                                		print(name);
                                		print(" line ");
                                		printbr(line);
					}
                        	case Method(cname,meth):
					if(foundEntry) {
        	                        	print(cname);
                	                	print(" method ");
                        	        	printbr(meth);
					}
                        	}
			}
		}
		if(exception != null) {

			println("<h2>Exception stack</h2>");

			var foundEntry = true;
			for(i in exception) {
				switch( i ) {
                        	case CFunction:
					printbr("[.dll]");
                        	case Module(m):
					if(foundEntry) {
                                		print("module ");
                                		printbr(m);
					}
                        	case FilePos(name,line):
					if(foundEntry) {
                                		print(name);
                                		print(" line ");
                                		printbr(line);
					}
                        	case Method(cname,meth):
					if(foundEntry) {
        	                        	print(cname);
                	                	print(" method ");
                        	        	printbr(meth);
					}
                        	}
			}
		}
		//ThreadExtra.exit();
	}

	///////////////////////////////////////////////////////////////////////////
	//                     PRINTING METHODS                                  //
	///////////////////////////////////////////////////////////////////////////
	/**
		Print, shortcut for neko.Lib.print
	*/
	public function print(str:Dynamic) {
		var s : String = Std.string(str);
		var inLength = s.length;
		if(!Response.headers_sent) {
			Response.startChunkedResponse();
		}

		buffer.add(str);
		bufcount += inLength;
		if(bufcount >= MAX_OUTBUFSIZE) {
			try {
				flushbuffer();
			}
			catch(e:Dynamic) {
				trace(here.methodName + " " + e);
			}
		}
		//neko.io.File.stdout().write("REDIRECT BUFFER>> "+str);
	}

	/**
		Print, adding newline character. Shortcut for
		neko.Lib.println. To add breaks to the line,
		see printbr()
	*/
	public function println(s:Dynamic) {
		print(s + "\n");
	}
	/**
		Print, adding an html break and a newline
	*/
	public function printbr(s:Dynamic) {
		print(s + "<br />\n");
	}

	/**
		Print out an indented text representation
		of any value, like PHP's print_r. Will format
		in HTML by default, by placing breaks at the end
		of each line. Set htmlize to false to disable.
	*/
	public static function print_r(v:Dynamic, ?htmlize:Bool, ?depth:Null<Int>,?hasNext:Bool) {
		/*
		Name => {
			note => {
				0 => null,
				2 => Note 2,
				1 => Note 1
			},
			city => Los Angeles,
			submit => button,
			address => 123 Anywhere street
		}
		*/
		if(htmlize == null)
			htmlize = true;
		if(depth == null || depth<0)
			depth = 0;

		var space : String = " ";
		var newline : String = "\n";
		if(htmlize) {
			space = "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;";
			newline = "<br>\n";
		}
		if(hasNext == true)
			newline = ","+newline;

		var sb = new StringBuf();

		switch(Type.typeof(v)) {
		case TUnknown:
			sb.add("[Unknown]");
			sb.add(newline);
		case TObject:
			sb.add("[Object]");
			sb.add(newline);
		case TNull:
			sb.add("Null");
			sb.add(newline);
		case TInt:
			sb.add(v);
			sb.add(newline);
		case TFunction:
			sb.add("[Function]");
			sb.add(newline);
		case TFloat:
			sb.add(v);
			sb.add(newline);
		case TEnum(e):
			sb.add("[Enum]");
			sb.add(newline);
		case TClass(c):
			var s = c;
			while((s = Type.getSuperClass(s)) != null) {
				c = s;
			}
			var cn : String = Type.getClassName(c);
			if(cn == "Hash" || cn == "List" || cn == "Array") {
				sb.add("{");
				if(htmlize)
					sb.add("<br>\n");
				else
					sb.add("\n");

				var it:Iterator<Dynamic>;
				if(cn == "Hash") {
					it = v.keys();
					for(i in it) {
						for(i in 0...depth+1)
							sb.add(space);
						sb.add(i);
						sb.add(" => ");
						sb.add(print_r(v.get(i), htmlize, depth+1,it.hasNext()));
					}
				}
				else {
					it = v.iterator();
					for(i in it) {
						for(i in 0...depth+1)
							sb.add(space);
						sb.add(i);
						sb.add(" => ");
						sb.add(print_r(i, htmlize, depth+1,it.hasNext()));
					}
				}
				for(i in 0...depth)
					sb.add(space);
				sb.add("}");
				sb.add(newline);
			}
			else if(cn == "String") {
				sb.add(v);
				sb.add(newline);
			}
			else {
				sb.add("[Class]");
				sb.add(newline);
			}
		case TBool:
			sb.add(v);
			sb.add(newline);
		}
		if(depth == 0)
			untyped __dollar__print(sb.toString());
		return sb.toString();
	}


	// convenience
	/**
		Encode a string for URL use.
	*/
	public static function urlEncode( s : String ) : String {
		//return untyped encodeURIComponents(s);
		return StringTools.urlEncode(s);
	}
	/**
		Decode a URL encoded string.
	*/
	public static function urlDecode( s : String ) : String {
		//return untyped decodeURIComponents(s.split("+").join(" "));
		return StringTools.urlDecode(s);
	}
	/**
		Convert HTML elements in a string.
	*/
	public static function htmlEscape( s : String ) : String {
		return StringTools.htmlEscape(s);
	}
	/**
		Strip html tags from string.
	*/
	public static function htmlUnescape( s : String ) : String {
		return StringTools.htmlUnescape(s);
	}
	/**
		Html encode string.
	*/
	public static function urlEncodedToHtml( s : String ) : String {
		return htmlEscape(urlDecode(s));
	}
	/**
		Return a string representation of the base class of
		any value. Also returns string representations of the
		primary types, like Int, Bool etc.
	*/
	public static function getBaseClass( v : Dynamic) : String {
		switch(Type.typeof(v)) {
		case TUnknown:
			return "Unknown";
		case TObject:
			return "Object";
		case TNull:
			return "Null";
		case TInt:
			return "Int";
		case TFunction:
			return "Function";
		case TFloat:
			return "Float";
		case TEnum(e):
			return "Enum";
		case TClass(c):
			var s = c;
			while((s = Type.getSuperClass(s)) != null) {
				c = s;
			}
			return(Type.getClassName(c));
		case TBool:
			return "Bool";
		}
		return null;
	}

	public function val_string( v : Dynamic ) : String {
		if(v == null)
			return "";
		//if(!isString(v))
		//	return "";
		return Std.string(v);
	}

	/**
		Get an integer from a value.
	**/
	public function val_int( v : Dynamic ) : Int {
		if(v == null)
			return 0;
		return Std.parseInt(v);
	}

	/**
		Check if any value is a string.
	*/
	public static function isString( v : Dynamic) : Bool {
		var c = getBaseClass(v);
		if(c != "String")
			return false;
		return true;
	}
	/**
		Check if any value is a Hash.
	*/
	public static function isHash( v : Dynamic ) : Bool {
		var c = getBaseClass(v);
		if(c != "Hash")
			return false;
		return true;
	}
	/**
		Check if any value is a List.
	*/
	public static function isList( v : Dynamic ) : Bool {
		var c = getBaseClass(v);
		if(c != "List")
			return false;
		return true;
	}
	/**
		Check if any value is an Array.
	*/
	public static function isArray( v : Dynamic ) : Bool {
		var c = getBaseClass(v);
		if(c != "Array")
			return false;
		return true;
	}
	/**
		Check if any value is an Integer.
	*/
	public static function isInt( v : Dynamic) : Bool {
		switch(Type.typeof(v)) {
		case TUnknown:
		case TObject:
		case TNull:
		case TInt:
			return true;
		case TFunction:
		case TFloat:
		case TEnum(e):
		case TClass(c):
		case TBool:
		}
		return false;
	}
	/**
		Check if any value is an object.
	*/
	public static function isObject( v : Dynamic) : Bool {
		switch(Type.typeof(v)) {
		case TUnknown:
		case TObject:
			return true;
		case TNull:
		case TInt:
		case TFunction:
		case TFloat:
		case TEnum(e):
		case TClass(c):
		case TBool:
		}
		return false;
	}
	/**
		Check if any value is a Function.
	*/
	public static function isFunction( v : Dynamic) : Bool {
		switch(Type.typeof(v)) {
		case TUnknown:
		case TObject:
		case TNull:
		case TInt:
		case TFunction:
			return true;
		case TFloat:
		case TEnum(e):
		case TClass(c):
		case TBool:
		}
		return false;
	}
	/**
		Check if any value is a Float.
	*/
	public static function isFloat( v : Dynamic) : Bool {
		switch(Type.typeof(v)) {
		case TUnknown:
		case TObject:
		case TNull:
		case TInt:
		case TFunction:
		case TFloat:
			return true;
		case TEnum(e):
		case TClass(c):
		case TBool:
		}
		return false;
	}
	/**
		Check if any value is a Class.
	*/
	public static function isClass( v : Dynamic) : Bool {
		switch(Type.typeof(v)) {
		case TUnknown:
		case TObject:
		case TNull:
		case TInt:
		case TFunction:
		case TFloat:
		case TEnum(e):
		case TClass(c):
			return true;
		case TBool:
		}
		return false;
	}
	/**
		Check if any value is a Bool.
	*/
	public static function isBool( v : Dynamic) : Bool {
		switch(Type.typeof(v)) {
		case TUnknown:
		case TObject:
		case TNull:
		case TInt:
		case TFunction:
		case TFloat:
		case TEnum(e):
		case TClass(c):
		case TBool:
			return true;
		}
		return false;
	}
	///////////////////////////////////////////////////////////////////////////
	//                  neko.Web COMPAT STATIC METHODS                       //
	///////////////////////////////////////////////////////////////////////////
	/**
		Set the HTTP response code.
	*/
	public function setReturnCode(r:Int) : Void {
		Response.setStatus(r);
	}
	/**
		Set a HTTP response header.
	*/
	public function setHeader(h : String, v : String) : Void {
		if(Response.headers_sent)
			err("Headers already sent", haxe.Stack.callStack());
		Response.setHeader(h, v);
	}
	/**
		Set an HTTP cookie.
	*/
	public function setCookie(cookie : Cookie) {
		if(Response.headers_sent) {
			err("Headers already sent", haxe.Stack.callStack());
		}
		Response.setCookie(cookie);
	}
	/**
		Redirect to url.
	*/
	public function redirect(url : String) : Void {
		setHeader("Location", url);
		setReturnCode(302);
	}
	/**
		Return the request uri.
	*/
	public function getURI(Void) : String { return Request.url; }
	/**
		Return the raw POST variable string. In the case of multipart
		this value will be empty.
	*/
	public function getPostData(Void) : String { return Request.post_data; }
	/**
		Return the raw GET variable string (everything after ? in the URI).
	*/
	public function getParamsString(Void) : String { return Request.args; }
	/**
		Return the server hostname.
	*/
	public function getHostName() : String {
		return Std.string(Request.host);
	}
	/**
		Current script working directory.
	*/
	public function getCwd(Void) : String {
		var p : String = Request.path_translated;
		if(Request.path.charAt(0) != "/")
			p = p + "/";
		p = p + Request.path;
		p = p.substr(0,p.lastIndexOf("/"));
		return p;
	}
	/**
		Return array of Cookies.
	*/
	public function getCookies() : Array<Cookie> {
		return Request.getCookies();

	}
	/**
		Return a hash of the cookie name value pairs.
		Unlike the Hive._COOKIE variable, no array like
		hashing is done on the cookie values.
	*/
	public function getCookieAsString() : Hash<String> {
		var rv = new Hash<String>();
		var cv : Array<Cookie> = Request.getCookies();
		for(i in cv)
			rv.set(i.getName(), i.getValue());
		return rv;
	}
	/**
		Return string IP address of remote client.
	*/
	public function getClientIP() : String {
		return Request.client.remote_host.toString();
	}
	/**
		Return all webbrowser headers sent to server.
	*/
	public function getClientHeaders() : List<{ key : String, value : String }> {
		return Request.headers_in;
	}
	/**
		Return value of a specific client header.
	*/
	public function getClientHeader(k : String) : String {
		return Request.getHeaderIn(k);
	}
	//TODO
	public function getAuthorization() : { user : String, pass : String } {
		var t = { user:"Me",pass:"me"};
		return t;
	}
	/**
		Flush the output buffer. If headers have not been sent
		yet, they will be output by using this function. This
		comes in handy for any long running process, or for
		displaying content before the script is finished executing.
	*/
	public function flush() {
		if(!Response.headers_sent) {
			Response.startChunkedResponse();
		}
		flushbuffer();
	}

	///////////////////////////////////////////////////////////////////////////
	//                  FORM HANDLING STATIC METHODS                         //
	///////////////////////////////////////////////////////////////////////////

	/**
		Check if an html checkbox is set
		Either specify the source (_POST or _GET vars), or the
		default merged environment GP will be used.
	*/
	public function formIsChecked(name:String, ?source:Hash<Dynamic>) : Bool {
		if(source == null)
			source = _GETPOST;
		if(source.get(name) == name)
			return true;
		return if(source.get(name) == "on") true; else false;
	}

	/**
		Return text from form field. If field does not exist,
		returns empty string. If field is a hash, it will be
		converted to a string.
	*/
	public function formField(name:String, ?source:Hash<Dynamic>) :String {
		if(source == null)
			source = _GETPOST;
		if(!source.exists(name))
			return "";
		if(Type.getClassName(Type.getClass(source.get(name))) == "Hash")
			return(source.get(name).toString());
		return source.get(name);
	}

	/**
		Return a form Hash. If field does not exist, or is not a
		hash, will return null.
	*/
	public function formHash(name:String, ?source:Hash<Dynamic>) : Hash<Dynamic> {
		if(source == null)
			source = _GETPOST;
		if(!source.exists(name))
			return null;
		if(Type.getClassName(Type.getClass(source.get(name))) != "Hash")
			return null;
		return source.get(name);
	}

	/**
		Parses a GET style string into an associative hash.
		The associative hash creates a 'hash of hashes' or
		key-string pairs from GET, POST and COOKIE vars, much
		like PHP's implementation of _POST. By creating form fields
		with empty brackets [], all similar variable names are added
		to the Hash as integer values. Any specific name contained
		in the brackets will set that key to the value of the form
		field or GET variable.
		For example:
		&lt;input type='text' name='foo[]' value='zero'&gt;
		&lt;input type='text' name='foo[]' value='one'&gt;
		Will create a hash with one key 'foo' that is a hash
		with two keys '0' and '1' that contain the values 'zero'
		and 'one' respectively.
		This method is the same one used to create _GET,
		_POST and _COOKIE out of the client request.
	*/
	public function parseVars(s:String) : Hash<Dynamic> {
		var rv = new Hash<Dynamic>();
		var args = s.split("&");

		for(i in args) {
			var v = i.split("=");
			var key = StringTools.urlDecode(v[0]);
			var value = StringTools.urlDecode(v[1]);
			rv = makeHashFromSpec(key, value, rv);
		}
		return rv;
	}


	///////////////////////////////////////////////////////////////////////////
	//                      UTILITY STATIC METHODS                           //
	///////////////////////////////////////////////////////////////////////////
	public function makeHashFromSpec(key:String, value:String, ?h:Hash<Dynamic>, ?recursion:Int) : Hash<Dynamic>
	{
		//trace(here.methodName + " key: "+key + " value: "+value + " recurse: "+recursion);
		key = StringTools.trim(key);

		if(h == null) {
			h = new Hash<Dynamic>();
		}
		if(recursion == null)
			recursion = 0;
		/*
		if(recursion == null || recursion == 0) {
			recursion = 0;
			// match braces
			var opens = 0;
			var closes = 0;
			for(i in 0...key.length) {
				if(key.charAt(i) == "[") {
				}
				if(key.charAt(i) == "]") {
				}
			}
			if(opens != closes)
				throw("Invalid key");
		}
		*/
		var name : String = null;
		var element : String = null;
		var s:Int;
		var e:Int;
		if(key.length > 0) {
			s = key.indexOf("[");
			e = key.lastIndexOf("]");
			if(e<s || s < 0) {
				// if close brace comes before end brace, or
				// just name and no key, set name to value (myname,value)
				h.set(key, value);
				return h;
			}
			if(s>=0)
				element = StringTools.trim(key.substr(s+1,e-s-1));
			if(s > 0)
				name = key.substr(0,s);
		}
		else {
			s = 0;
			e = 0;
			element = null;
			name = null;
		}
		if(element == null || element.length == 0) { // []
			// if no name, set increment to value ([], value)
			if(name == null) {
				//trace("Setting by counter");
				var counter : Int = 0;
				for(i in h) { counter++; }
				//trace("Counter now "+counter);
				h.set(Std.string(counter), value);
				return h;
			}

		}
		// has name and element
		// if name exists, and is not a hash, make a new hash
		// taking any old value and making it the first entry
		// in the new hash.
		if(Type.getClassName(Type.getClass(h.get(name))) != "Hash") {
			var oldval = h.get(name);
			h.set(name, new Hash<Dynamic>());
			if(oldval != null)
				h.get(name).set("0", oldval);
		}
		makeHashFromSpec(element,value,h.get(name),recursion+1);
		//trace(h);
		return h;
	}

	/**
		Return a merged set of request variables, in the
		order of precedence specified by order. the least
		important is order[0]. Default is EGPCS Just like PHP
		E environment
		G GET vars
		P POST vars
		C Cookie vars
		S Server vars.
	*/
	public function mergeEnv(?order:Array<String>) : Hash<String>
	{
		var rv = new Hash<String>();
		if(order == null) {
			order = ["E","G","P","C","S"];
		}
		for(i in order) {
			var source = null;
			switch(i) {
			case "E":
				source = _ENV;
			case "G":
				source = _GET;
			case "P":
				source = _POST;
			case "C":
				source = _COOKIE;
			case "S":
				source = _SERVER;
			}
			if(source == null)
				continue;
			for(k in source.keys()) {
				rv.set(k, source.get(k));
			}
		}
		return rv;
	}

	/* *********************************************
		The following methods populate only the
		hashes that are used during request handling
	* **********************************************/
	function get_ENV() : Hash<Dynamic> {
		if(_ENV == null) {
			_ENV = new Hash<Dynamic>();
			/*
			pv = Request.env_vars;
			for(i in pv)
				_ENV = makeHashFromSpec(i.key,i.value,_ENV);
			*/
		}
		return _ENV;
	}

	function get_SERVER() : Hash<Dynamic> {
		if(_SERVER == null) {
			_SERVER = new Hash<Dynamic>();
			/*
			pv = Request.server_vars;
			for(i in pv)
				_SERVER = makeHashFromSpec(i.key,i.value,_SERVER);
			*/
		}
		return _SERVER;
	}

	function get_FILES() : Hash<Resource> {
		if(_FILES == null) {
			_FILES = new Hash();
			for(f in Request.file_vars)
				_FILES.set(f.name,f);
		}
		return _FILES;
	}

	function get_POST() : Hash<Dynamic> {
		if(_POST == null) {
			_POST = new Hash<Dynamic>();
			var pv = Request.post_vars;
			for(i in pv)
				_POST = makeHashFromSpec(i.key,i.value,_POST);
		}
		return _POST;
	}

	function get_GET() : Hash<Dynamic> {
		if(_GET == null) {
			_GET = new Hash<Dynamic>();
			var pv = Request.get_vars;
			for(i in pv)
				_GET = makeHashFromSpec(i.key,i.value,_GET);
		}
		return _GET;
	}

	function get_COOKIE() : Hash<Dynamic> {
		if(_COOKIE == null) {
			_COOKIE = new Hash<Dynamic>();
			var cv : Array<Cookie> = Request.getCookies();
			for(i in cv)
				_COOKIE = makeHashFromSpec(i.getName(), i.getValue(),_COOKIE);
		}
		return _COOKIE;
	}

	function get_REQUEST() : Hash<Dynamic> {
		if(_REQUEST == null)
			_REQUEST = mergeEnv(["E","G","P","C","S"]);
		return _REQUEST;
	}

	function get_GETPOST() : Hash<Dynamic> {
		if(_GETPOST == null)
			_GETPOST = mergeEnv(["G","P"]);
		return _GETPOST;
	}


}
