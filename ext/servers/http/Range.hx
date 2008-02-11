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


/*
- The first 500 bytes (byte offsets 0-499, inclusive):  bytes=0-499
- The second 500 bytes (byte offsets 500-999, inclusive): bytes=500-999
- The final 500 bytes (byte offsets 9500-9999, inclusive): bytes=-500
	- Or bytes=9500-
- The first and last bytes only (bytes 0 and 9999):  bytes=0-0,-1
- Several legal but not canonical specifications of the second 500
   bytes (byte offsets 500-999, inclusive):
   bytes=500-600,601-999
   bytes=500-700,601-999


Fix problem with unsatisfiable range requests; there are two cases:
   syntactic problems, and range doesn't exist in the document. The 416
   status code was needed to resolve this ambiguity needed to indicate
   an error for a byte range request that falls outside of the actual
   contents of a document. (Section 10.4.17, 14.16)

If-Range
   header SHOULD only be used together with a Range header, and MUST be
   ignored if the request does not include a Range header

See section
	14.27 for If-Range: request header
	14.35 for Range: request header
	19.2 for 206 Partial Content examples


either
a) Encompass a range to include the min and max, then do a single range response
b) Do 206 Partial Content
   HTTP/1.1 206 Partial Content
   Date: Wed, 15 Nov 1995 06:25:24 GMT
   Last-Modified: Wed, 15 Nov 1995 04:58:08 GMT
   Content-type: multipart/byteranges; boundary=THIS_STRING_SEPARATES

   --THIS_STRING_SEPARATES
   Content-type: application/pdf
   Content-range: bytes 500-999/8000

    ...the first range...
   --THIS_STRING_SEPARATES
   Content-type: application/pdf
   Content-range: bytes 7000-7999/8000

   ...the second range
   --THIS_STRING_SEPARATES--


*/

package servers.http;

import servers.http.hive.TypesHttp;

class Range {
	/**
		Parse a range value, return an array of all the Range
		classes that satisfy it. Range value should take the form
		'bytes=?-?,?-?,...'. If any range in a spec is invalid,
		the whole range set is invalid and an empty set of ranges
		will be returned.
	**/
	static public function fromString(str : String) : Array<Range> {
		var hranges = new Array<Range>();
		str = StringTools.trim(str);
		str = StringTools.replace(str," ","");
		if(str.substr(0,6) != "bytes=")
			return hranges;
		str = str.substr(6);
		var parts = str.split(",");
		for(i in parts) {
			var r = new Range(i);
			if(! r.isValid()) {
				hranges = new Array<Range>();
				return hranges;
			}
			hranges.push(r);
		}
		return hranges;
	}

	static public function satisfyAll(ranges:Array<Range>, filesize:Int) {
		for(i in ranges) {
			if(!i.isValid())
				return false;
			if(!i.satisfy(filesize))
				return false;
		}
		return true;
	}

	public var off_start(default,null)	: Int;
	public var off_end(default,null)	: Int;
	public var type(default,null)		: RangeType;
	public var valid(default,null)		: Bool;
	public var length(default,null)		: Int;

	public function new(specstr: String) {
		off_start = null;
		off_end = null;
		type = null;
		valid = false;

		//possible input values look like
		//500-599 	== absolute range
		//-1		== last 1 byte
		//900-		== byte 900 onward

		var spec = StringTools.trim(specstr);
		var r : EReg = ~/([0-9]*)-([0-9]*)$/;
		try {
			var s : String = r.matched(1);
			var e : String = r.matched(2);

			if(s.length == 0) {
				type = OFFSET_END;
				off_start = Std.parseInt(e);
				off_end = off_start;
			}
			else if(e.length == 0) {
				type = HEAD;
				off_start = 0;
				off_end = Std.parseInt(e);
			}
			else {
				type = RANGE;
				off_start = Std.parseInt(s);
				off_end = Std.parseInt(e);
			}
		} catch (e : Dynamic) { return; }
		if(off_start < 0 || off_end < 0)
			return;
		if(off_end < off_start)
			return;
		valid = true;
	}

	public function isValid() {
		return valid;
	}

	public function satisfy(filelen : Int) : Bool {
		if(off_end >= filelen)
			off_end = filelen - 1;
		switch(type) {
		case RANGE:
			if(off_start < 0)
				off_start = 0;
		case HEAD:
			off_start = 0;
		case OFFSET_END:
			off_end = filelen - 1;
			if(off_start > filelen)
				off_start = 0;
			else
				off_start = filelen - off_start;
		}
		length = off_end - off_start + 1;
		return true;
	}


}

/*

SINGLE RANGE EXAMPLE

HTTP/1.1 206 Partial Content
Date: Mon, 04 Jun 2007 23:45:00 GMT
Server: Apache
Last-Modified: Tue, 28 Aug 2001 19:09:26 GMT
ETag: "56a0d-d4-cfe76580"
Accept-Ranges: bytes
Content-Length: 11
Content-Range: bytes 0-10/212
Connection: close
Content-Type: text/html

<HTML>
<HEAConnection closed by foreign host.

MULTIRANGE EXAMPLE

HTTP/1.1 206 Partial Content
Date: Mon, 04 Jun 2007 23:46:20 GMT
Server: Apache
Last-Modified: Tue, 28 Aug 2001 19:09:26 GMT
ETag: "56a0d-d4-cfe76580"
Accept-Ranges: bytes
Content-Length: 214
Connection: close
Content-Type: multipart/byteranges; boundary=4321d2bf99e7a140ce


--4321d2bf99e7a140ce
Content-type: text/html
Content-range: bytes 0-10/212

<HTML>
<HEA
--4321d2bf99e7a140ce
Content-type: text/html
Content-range: bytes 23-34/212

  t  h  e  .
--4321d2bf99e7a140ce--




RANGE NOT SATISFIED:

HTTP/1.1 416 Requested Range Not Satisfiable
Date: Mon, 04 Jun 2007 23:49:45 GMT
Server: Apache
Connection: close
Transfer-Encoding: chunked
Content-Type: text/html; charset=iso-8859-1

13a
<!DOCTYPE HTML PUBLIC "-//IETF//DTD HTML 2.0//EN">
<html><head>
<title>416 Requested Range Not Satisfiable</title>
</head><body>
<h1>Requested Range Not Satisfiable</h1>
<p>None of the range-specifier values in the Range
request-header field overlap the current extent
of the selected resource.</p>
</body></html>

0

Connection closed by foreign host.
*/
