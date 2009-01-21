package hxfront;

class WebRequest {
	static function convert(v : Dynamic, strip : Bool) {
		if(Std.is(v, String)) {
			return untyped strip ? __call__("stripslashes", v) : v;
		} else {
			var a : Array<Dynamic> = untyped __call__("new _hx_array", v);
			for(i in 0...a.length)
				a[i] = convert(a[i], strip);
			return a;
		}
	}

	public static function getParams() : Dynamic {
#if neko
		var o = {};
		var params = neko.Web.getParams();
		for(k in params.keys())
			Reflect.setField(o, k, params.get(k));
		return o;
#elseif php
		var a : php.NativeArray = untyped __php__("array_merge($_GET, $_POST)");
		untyped __php__("foreach($a as $k => $v) $a[$k] = hxfront_Web::convert($v, get_magic_quotes_gpc())");
		return untyped __call__("_hx_anonymous", a);
#end
	}

	public static function getRequestURI() : String {
#if neko
		var uri = neko.Web.getURI();
		if(uri.substr(-2) == '.n')
			uri = neko.io.Path.directory(uri) + "/";
		return uri;
#elseif php
		return untyped __php__("$_SERVER['REQUEST_URI']");
#end
	}

	/*
	// TODO: this must be fixed for complex paramters like arrays or dot syntax
	public static function getPostParams() : Dynamic {
#if neko
		return throw "Implement getPostParams";
#elseif php
		var a = untyped __php__("$_POST");
		untyped __php__("foreach($a as $k => $v) $a[$k] = hxfront_Web::convert($v, get_magic_quotes_gpc())");
		return untyped __call__("_hx_anonymous", a);
#end
	}
*/
	public static function isPost() : Bool {
#if neko
		return neko.Web.getMethod() == 'POST';
#elseif php
		return untyped __php__("$_SERVER['REQUEST_METHOD'] == 'POST'");
#end
	}
}