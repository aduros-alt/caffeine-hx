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

import dates.GmtDate;

class Logger {
	public var host(default, null)		: String;	// hostname this logs for, or *
	public var format(default,null)		: String;
	public var filename(default,null)	: String;
	var fo : neko.io.FileOutput;

	var replace_header			: List<String>;

	public function new(host: String, filename : String, format : String) {
		this.host = host.toLowerCase();
		this.filename = filename;
		this.format = format;
		fo = neko.io.File.append(filename, false);
		if(fo == null)
			throw("Unable to open " + filename);
		replace_header = new List();

		//trace(format);
		var r : EReg = new EReg("%{([A-Z-]+)}i","i");
		var x : Int = 0;
		var h : Hash<Bool> = new Hash();
		var s : String = format;
		while(s.length > 0 && r.match(s) == true ) {
			var lcase = r.matched(1).toLowerCase();
			h.set(lcase, true);
			s = s.substr(r.matchedPos().pos + r.matchedPos().len);
			// replace all instances with a lowercase version in out format copy
			var er : EReg = new EReg("%{"+lcase+"}i","ig");
			this.format = er.replace(this.format,"%{"+lcase+"}i");
		}
		for(i in h.keys()) {
			replace_header.add(i);
		}
		//trace(this.format);
	}

	public function log(d : Client) : Void {
		if(host != "*" && d.request.host != host)
			return;
		var parsed = parse(d);
		//neko.Lib.println("ACCESSLOG: "+parsed);
		try {
			fo.write(parsed + "\n");
			fo.flush();
			return;
		}
		catch(e:Dynamic) {}
		neko.Lib.println("Attempting to reopen logfile "+filename);
		try {
			fo = neko.io.File.append(filename, false);
		}
		catch(e:Dynamic) {
			neko.Lib.println("Cannot reopen "+filename);
			return;
		}
		try {
			fo.write(parsed + "\n");
			fo.flush();
		}
		catch(e:Dynamic) {}

	}

	function parse(d : Client) : String {
		// http://httpd.apache.org/docs/2.0/mod/mod_log_config.html#formats
		// LogFormat "%h %l %u %t \"%r\" %>s %b" common
		// LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-agent}i\"" combined
		// CustomLog logs/access_log common
		// %h - remote host
		// %u - username (auth)
		// %t - timestamp
		// %r - request GET /apache_pb.gif HTTP/1.0
		// %>s - status code
		// %b - size of reply (or "-" for nothing returned besides headers)
		// %{Headername}i - Log specific header by name
		// %...{Foobar}C  - Cookie value of foobar
		var msg : String = format;
		msg = StringTools.replace(msg, "%h", d.remote_host.toString());
		//msg = StringTools.replace(msg, "%", Std.string(d.remote_port));
		msg = StringTools.replace(msg, "%l", "-");
		msg = StringTools.replace(msg, "%u", { if(d.request.username==null) "-"; else d.request.username; });
		msg = StringTools.replace(msg, "%t", GmtDate.timestamp());
		msg = StringTools.replace(msg, "%r", d.request.requestline);
		msg = StringTools.replace(msg, "%>s", Std.string(d.response.status));
		msg = StringTools.replace(msg, "%b", { if(d.response.content_length > 0) Std.string(d.response.content_length); else "-";});
		//msg = StringTools.replace(msg, "%
		//msg = StringTools.replace(msg, "%

		for(s in replace_header) {
			var r : EReg = new EReg("%{" + s + "}i", "g");
			var headval = d.request.getHeaderIn(s);
			if(headval == null) headval = "-";
			msg = r.replace(msg, headval);
		}

		return msg;
	}
}
