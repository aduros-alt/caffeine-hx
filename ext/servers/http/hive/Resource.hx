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

/**
	Class to contain POSTed files
	Errors thrown by file io are not caught.
*/
import neko.io.File;

class Resource {
	public var name		: String;
	public var mime_type	: String; 	// as set by browser
	public var size		: Int;		// bytes
	public var length	: Int;		// data so far
	public var filename	: String;	// full path to file
	public var error	: Int;
	public var isFile	: Bool;

	public static var ERR_OK	: Int	= 0;
	public static var ERR_FORM_SIZE : Int	= 1; // bigger than MAX_FILE_SIZE in html form
	public static var ERR_PARTIAL	: Int	= 2; // partial upload
	public static var ERR_NO_FILE	: Int 	= 3; // received no file

	private var tmpfile		: neko.io.TmpFile;
	private var sval		: StringBuf;

	public function new(name : String, ?contentsize:Null<Int>) {
		this.name = name;
		this.filename = null;
		size = contentsize;
		length = 0;
		isFile = false;
		if(size == 0 || size == null || size > (16*1024)) {
			tmpfile = new neko.io.TmpFile();
		}
		else {
			tmpfile = null;
		}
		mime_type = "unknown/unknown";
		error = ERR_OK;

		sval = new StringBuf();
	}

	public function setFilename(filename:String) {
		this.filename = filename;
		if(filename.length <= 0) {
			error = ERR_NO_FILE;
		}
		if(tmpfile == null && length == 0)
			tmpfile = new neko.io.TmpFile();
		isFile = true;
	}


	public function addData(s:String, p:Int, len: Int) : Void {
		if(len <= 0)
			return;
		//trace(s.substr(p,len));
		//var data = s.substr(p,len);
		//trace(data);
		if(tmpfile != null)
			tmpfile.getOutput().writeBytes(s, p, len);
		else
			sval.addSub(s, p, len);
			//sval.add(data);
		length += len;
	}


	public function getValue() : String {
		try {
			if(tmpfile != null) {
				var fi = tmpfile.getInput();
				fi.seek(0, SeekBegin);
				var data = fi.readAll();
				fi.seek(0,SeekEnd);
				return data;
			}
		}
		catch(e:Dynamic) {
			return null;
		}
		trace(sval.toString());
		return sval.toString();
	}

	public function copyTo(o : neko.io.Output) : Bool {
		if(tmpfile == null)
			return false;
		var fi : neko.io.FileInput;
		try {
			fi = tmpfile.getInput();
			fi.seek(0, SeekBegin);
			while(true) {
				o.writeChar(fi.readChar());
			}
		}
		catch(e:neko.io.Eof) {}
		catch(e:Dynamic) {
			return false;
		}
		try {
			fi.seek(0,SeekEnd);
		}
		catch(e:Dynamic) {}
		return true;
	}

	public function parse_multipart_data(onData : String -> Int -> Int -> Void) : Void
	{
		var fi : neko.io.FileInput;
		try {
			fi = tmpfile.getInput();
			fi.seek(0, SeekBegin);
		}
		catch(e:Dynamic) {
			return;
		}

		while(true) {
			var retval = read(fi, 64*1024);
			if(retval.bytes > 0) {
				onData(
					//neko.Lib.haxeToNeko(retval.buffer),
					retval.buffer.substr(0,retval.bytes),
					0,
					retval.bytes
				);
			}
			if(retval.status != 0)
				break;
		}
	}

	// stat: -1 on error, 0 read all, 1 = eof
	static function read( i : neko.io.FileInput, len : Int ) : {buffer:String,bytes:Int,status:Int}
	{
		var c : Int;
		var s = neko.Lib.makeString(len);
		var p = 0;
		var stat = 0;
		while( p < len ) {
			try {
				c = i.readChar();
			}
			catch(e:neko.io.Eof) {
				stat = 1;
			}
			catch(e:Dynamic) {
				stat = -1;
			}
			if(stat != 0)
				break;
			untyped __dollar__sset(s.__s,p,c);
			p += 1;
		}
		return {buffer: s, bytes: p, status: stat};
	}
}