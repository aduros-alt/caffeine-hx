/*
 * Copyright (c) 2009, The Caffeine-hx project contributors
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

package chx.net;

import chx.lang.UriFormatException;

/**
	http://www.ietf.org/rfc/rfc2396.txt
	@todo Test parser
	@todo No IPv6 support yet
	@see {@link http://www.ietf.org/rfc/rfc2396.txt rfc2396}
	@author rweir
**/
class URI {
	// in order
	public var scheme(default, null)			: String;
	public var authority(default, null)			: String;
	public var userInfo(default, null)			: String;
 	public var host(default, null)				: String;
	/** Will be null if not a valid port **/
	public var port(default, null)				: Null<Int>;
	public var path(default, null)				: String;
	public var query(default, null)				: String;
	public var fragment(default, null)			: String;

	// combination
	public var schemeSpecific(default, null)	: String;

	private function new() {
		port = null; // all others undefined as null
	}

	/**
		Parses a full uri string and returns a Uri instance
		@param uri Full uri string (ex. mailto:john@foo.com or http://foo.com/index.html)
		@returns new Uri instance
		@todo rfc2396 3.2.1 authority
		@throws chx.lang.UriFormatException if the uri is invalid
	**/
	public static function parse(uri : String) : URI {
		var u = new URI();

		try {
			var e= ~/^(([^:\/?#]+):)?(\/\/([^\/?#]*))?([^?#]*)(\?([^#]*))?(#(.*))?/;
			if(!e.match(uri))
				throw "uri invalid";
			/*
			trace("scheme: " + e.matched(2));
			trace(": " + e.matched(3));
			trace("authority: " + e.matched(4));
			trace("path: " + e.matched(5));
			trace(": " + e.matched(6));
			trace("query: " + e.matched(7));
			trace(": " + e.matched(8));
			trace("fragment: " + e.matched(9));
			*/

			u.scheme = e.matched(2);
			u.authority = e.matched(4);
			u.path = e.matched(5);
			u.query = e.matched(7);
			u.fragment = e.matched(9);
		} catch(e : Dynamic) {
			throw new UriFormatException(Std.string(e));
		}

		if(u.authority != null) {
			try {
				// todo 3.2.1 here

				// 3.2.2 <userinfo>@<host>:<port>
				var e = ~/^(([^\/\?@]+)@)?([A-Za-z\.0-9\-]*)?(:([0-9]+))?/;
				if(!e.match(u.authority))
					throw "authority invalid";
				u.userInfo = e.matched(2);
				u.host = e.matched(3);
				if(u.host == null)
					throw "invalid host";
				if(e.matched(5) != null) {
					u.port = Std.parseInt(e.matched(5));
					if(u.port == null)
						throw "invalid port";
				}
			} catch(e : Dynamic) {
				throw new UriFormatException(Std.string(e));
			}
		}

		return u;
	}

	/**
		Creates a URI by first creating a string version, RFC 2396, section 5.2, step 7, which is then passed through parse() to return the resulting URI instance. Any param may be null.
		@param scheme URI scheme (ex. http)
		@param userInfo User information (ex. user:password)
		@param host Hostname. No support for IPv6 yet.
		@param port Port number, null or <0 for no port
		@param path Path part
		@param query Part that would be after a ? in a web url
		@param fragment A URI fragment (ex. top)
		@todo Check quoting of path param
	**/
	public static function create(
				scheme : String,
				userInfo : String,
				host : String,
				port : Null<Int>,
				path : String,
				query : String,
				fragment : String) : URI
	{
		var uri : String = "";
		if(scheme != null)
			uri += scheme + ":";
		if(userInfo != null || host != null || (port != null && port >= 0))
			uri += "//";
		if(userInfo != null) {
			// todo here, quote userInfo
			uri += userInfo;
			uri += "@";
		}
		if(host != null)
			uri += host;
		if(port != null && port >= 0)
			uri += ":" + Std.string(port);
		if(path != null) {
			var pathQuoted = StringTools.urlEncode(path);
			pathQuoted = StringTools.replace(pathQuoted, "%2F", "/");
			pathQuoted = StringTools.replace(pathQuoted, "%40", "@");
			uri += path;
		}
		if(query != null) {
			uri += "?";
			uri += StringTools.urlEncode(query);
		}

		if(fragment != null) {
			uri += "#";
			uri += StringTools.urlEncode(fragment);
		}
		return parse(uri);
	}

	/**
		http://www.foo.com/subdir/file.html#top
		@param scheme URI scheme (ex. http)
		@param host URI hostname (ex. www.foo.com)
		@param path URI path part (ex. /subdir/file.html)
		@param fragment URI fragment (ex. top)
		@returns new Uri instance
	**/
	public static function createShort(scheme : String, host : String, path : String, fragment : String) : URI {
		return create(scheme, null, host, null, path, null, fragment);
	}
}