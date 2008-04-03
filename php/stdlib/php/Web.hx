package php;

/**
	This class is used for accessing the local Web server and the current
	client request and informations.
**/
class Web {

	/**
		Returns the GET and POST parameters.
	**/
	public static function getParams() {
		return Hash.fromAssociativeArray(untyped __php__("array_merge($__GET__, $__POST__)"));
	}

	/**
		Returns an Array of Strings built using GET / POST values.
		If you have in your URL the parameters [a[]=foo;a[]=hello;a[5]=bar;a[3]=baz] then
		[neko.Web.getParamValues("a")] will return [["foo","hello",null,"baz",null,"bar"]]
	**/
	public static function getParamValues( param : String ) : Array<String> {
		var reg = new EReg("^"+param+"(\\[|%5B)([0-9]*?)(\\]|%5D)=(.*?)$", "");
		var res = new Array<String>();
		var explore = function(data:String){
			if (data == null || data.length == 0)
				return;
			for (part in data.split("&")){
				if (reg.match(part)){
					var idx = reg.matched(2);
					var val = StringTools.urlDecode(reg.matched(4));
					if (idx == "")
						res.push(val);
					else
						res[Std.parseInt(idx)] = val;
				}
			}
		}
		explore(StringTools.replace(getParamsString(), ";", "&"));
		explore(getPostData());
		if (res.length == 0)
			return null;
		return res;
	}

	/**
		Returns the local server host name
	**/
	public static function getHostName() {
		return untyped __php__("$_SERVER['SERVER_NAME']");
	}

	/**
		Surprisingly returns the client IP address.
	**/
	public static function getClientIP() {
		return untyped __php__("$_SERVER['REMOTE_ADDR']");
	}

	/**
		Returns the original request URL (before any server internal redirections)
	**/
	public static function getURI() {
		return untyped __php__("$_SERVER['REQUEST_URI']");
	}

	/**
		Tell the client to redirect to the given url ("Location" header)
	**/
	public static function redirect( url : String ) {
		untyped __php__('header("Location: " . $url)');
		untyped __php__('exit()');
	}

	/**
		Set an output header value. If some data have been printed, the headers have
		already been sent so this will raise an exception.
	**/
	public static function setHeader( h : String, v : String ) {
		untyped __php__('header($h.": ".$v)');
	}

	/**
		Set the HTTP return code. Same remark as setHeader.
	**/
	public static function setReturnCode( r : Int ) {
		untyped __php__('header("", true, $r)'); // TODO: TEST ME
	}

	/**
		Retrieve a client header value sent with the request.
	**/
	public static function getClientHeader( k : String ) {
		return null; // TODO, IMPLEMENT
		/*
		var v = _get_client_header(untyped k.__s);
		if( v == null )
			return null;
		return new String(v);
		*/
	}

	/**
		Retrieve all the client headers.
	**/
	public static function getClientHeaders() {
		return null; // TODO, IMPLEMENT
		/*
		var v = _get_client_headers();
		var a = new List();
		while( v != null ) {
			a.add({ header : new String(v[0]), value : new String(v[1]) });
			v = cast v[2];
		}
		return a;
		*/
	}

	/**
		Returns all the GET parameters String
	**/
	public static function getParamsString() {
		return null; // TODO, IMPLEMENT
		/*
		return new String(_get_params_string());
		*/
	}

	/**
		Returns all the POST data. POST Data is always parsed as
		being application/x-www-form-urlencoded and is stored into
		the getParams hashtable. POST Data is maximimized to 256K
		unless the content type is multipart/form-data. In that
		case, you will have to use [getMultipart] or [parseMultipart]
		methods.
	**/
	public static function getPostData() {
		return null; // TODO, IMPLEMENT
		/*
		var v = _get_post_data();
		if( v == null )
			return null;
		return new String(v);
		*/
	}

	/**
		Returns an hashtable of all Cookies sent by the client.
		Modifying the hashtable will not modify the cookie, use setCookie instead.
	**/
	public static function getCookies() {
		return null; // TODO, IMPLEMENT
		/*
		var p = _get_cookies();
		var h = new Hash<String>();
		var k = "";
		while( p != null ) {
			untyped k.__s = p[0];
			h.set(k,new String(p[1]));
			p = untyped p[2];
		}
		return h;
		*/
	}


	/**
		Set a Cookie value in the HTTP headers. Same remark as setHeader.
	**/
	public static function setCookie( key : String, value : String, ?expire: Date, ?domain: String, ?path: String, ?secure: Bool ) {
		return null; // TODO, IMPLEMENT
		/*
		var buf = new StringBuf();
		buf.add(value);
		if( expire != null ) addPair(buf, "expires=", DateTools.format(expire, "%a, %d-%b-%Y %H:%M:%S GMT"));
		addPair(buf, "domain=", domain);
		addPair(buf, "path=", path);
		if( secure ) addPair(buf, "secure", "");
		var v = buf.toString();
		_set_cookie(untyped key.__s, untyped v.__s);
		*/
	}
/*
	static function addPair( buf : StringBuf, name, value ) {
		if( value == null ) return;
		buf.add("; ");
		buf.add(name);
		buf.add(value);
	}
*/
	/**
		Returns an object with the authorization sent by the client (Basic scheme only).
	**/
	public static function getAuthorization() : { user : String, pass : String } {
		return null; // TODO, IMPLEMENT
		/*
		var h = getClientHeader("Authorization");
		var reg = ~/^Basic ([^=]+)=*$/;
		if( h != null && reg.match(h) ){
			var val = reg.matched(1);
			untyped val = new String(_base_decode(val.__s,"ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/".__s));
			var a = val.split(":");
			if( a.length != 2 ){
				throw "Unable to decode authorization.";
			}
			return {user: a[0],pass: a[1]};
		}
		return null;
		*/
	}

	/**
		Get the current script directory in the local filesystem.
	**/
	public static function getCwd() {
		return null; // TODO, IMPLEMENT
		/*
		return new String(_get_cwd());
		*/
	}

	/**
		Set the main entry point function used to handle requests.
		Setting it back to null will disable code caching.
	**/
	public static function cacheModule( f : Void -> Void ) {
		return null; // TODO, IMPLEMENT
		/*
		_set_main(f);
		*/
	}

	/**
		Get the multipart parameters as an hashtable. The data
		cannot exceed the maximum size specified.
	**/
	public static function getMultipart( maxSize : Int ) : Hash<String> {
		return null; // TODO, IMPLEMENT
		/*
		var h = new Hash();
		var buf : StringBuf = null;
		var curname = null;
		parseMultipart(function(p,_) {
			if( curname != null )
				h.set(curname,buf.toString());
			curname = p;
			buf = new StringBuf();
			maxSize -= p.length;
			if( maxSize < 0 )
				throw "Maximum size reached";
		},function(str,pos,len) {
			maxSize -= len;
			if( maxSize < 0 )
				throw "Maximum size reached";
			buf.addSub(str,pos,len);
		});
		if( curname != null )
			h.set(curname,buf.toString());
		return h;
		*/
	}

	/**
		Parse the multipart data. Call [onPart] when a new part is found
		with the part name and the filename if present
		and [onData] when some part data is readed. You can this way
		directly save the data on hard drive in the case of a file upload.
	**/
	public static function parseMultipart( onPart : String -> String -> Void, onData : String -> Int -> Int -> Void ) : Void {
		return null; // TODO, IMPLEMENT
		/*
		_parse_multipart(
			function(p,f) { onPart(new String(p),if( f == null ) null else new String(f)); },
			function(buf,pos,len) { onData(new String(buf),pos,len); }
		);
		*/
	}

	/**
		Flush the data sent to the client. By default on Apache, outgoing data is buffered so
		this can be useful for displaying some long operation progress.
	**/
	public static function flush() : Void {
		untyped __call__("flush");
	}
}
