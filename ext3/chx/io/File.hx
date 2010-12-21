/*
 * Copyright (c) 2005, The haXe Project Contributors
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
 * THIS SOFTWARE IS PROVIDED BY THE HAXE PROJECT CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE HAXE PROJECT CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */
package chx.io;

enum FileHandle {
}

enum FileSeek {
	SeekBegin;
	SeekCur;
	SeekEnd;
}


#if neko

/**
	API for reading and writing to files.
**/
class File {

	public static function getContent( path : String ) {
		return new String(file_contents(untyped path.__s));
	}

	public static function getBytes( path : String ) {
		return neko.Lib.bytesReference(getContent(path));
	}

	public static function read( path : String, binary : Bool ) {
		return new FileInput(untyped file_open(path.__s,(if( binary ) "rb" else "r").__s));
	}

	public static function write( path : String, binary : Bool ) : FileOutput {
		return new FileOutput(untyped file_open(path.__s,(if( binary ) "wb" else "w").__s));
	}

	public static function append( path : String, binary : Bool ) : FileOutput {
		return new FileOutput(untyped file_open(path.__s,(if( binary ) "ab" else "a").__s));
	}

	public static function copy( src : String, dst : String ) : Void {
		var s = read(src,true);
		var d = write(dst,true);
		d.writeInput(s);
		s.close();
		d.close();
	}

	public static function stdin() {
		return new FileInput(file_stdin());
	}

	public static function stdout() : FileOutput {
		return new FileOutput(file_stdout());
	}

	public static function stderr() : FileOutput {
		return new FileOutput(file_stderr());
	}

	public static function getChar( echo : Bool ) : Int {
		return getch(echo);
	}

	private static var file_stdin = neko.Lib.load("std","file_stdin",0);
	private static var file_stdout = neko.Lib.load("std","file_stdout",0);
	private static var file_stderr = neko.Lib.load("std","file_stderr",0);

	private static var file_contents = neko.Lib.load("std","file_contents",1);
	private static var file_open = neko.Lib.load("std","file_open",2);

	private static var getch = neko.Lib.load("std","sys_getch",1);

}

#elseif php

/**
	API for reading and writing to files.
**/
class File {

	public static function getContent( path : String ) : String {
		return untyped __call__("file_get_contents", path);
	}
	
	public static function getBytes( path : String ) {
		return Bytes.ofString(getContent(path));
	}
	
	public static function putContent( path : String, content : String) : Int {
		return untyped __call__("file_put_contents", path, content);
	}
	
	public static function read( path : String, binary : Bool ) {
		return new FileInput(untyped __call__('fopen', path, binary ? "rb" : "r"));
	}

	public static function write( path : String, binary : Bool ) : FileOutput {
		return new FileOutput(untyped __call__('fopen', path, binary ? "wb" : "w"));
	}

	public static function append( path : String, binary : Bool ) : FileOutput {
		return new FileOutput(untyped __call__('fopen', path, binary ? "ab" : "a"));
	}
	
	public static function copy( src : String, dst : String ) {
		return untyped __call__("copy", src, dst);
	}

	public static function stdin() {
		return new FileInput(untyped __call__('fopen', 'php://stdin', "r"));
	}

	public static function stdout() : FileOutput {
		return new FileOutput(untyped __call__('fopen', 'php://stdout', "w"));
	}

	public static function stderr() : FileOutput {
		return new FileOutput(untyped __call__('fopen', 'php://stderr', "w"));
	}
	
	public static function getChar( echo : Bool ) : Int {
		var v : Int = untyped __call__("fgetc", __php__("STDIN"));
		if(echo)
			untyped __call__('echo', v);
		return v;
	}
}

#elseif cpp

/**
	API for reading and writing to files.
**/
class File {

	public static function getContent( path : String ) {
		var b = getBytes(path);
		return b.toString();
	}

	public static function getBytes( path : String ) : Bytes {
		var data:BytesData = file_contents(path);
		return Bytes.ofData(data);
	}

	public static function read( path : String, binary : Bool ) {
		return new FileInput(untyped file_open(path,(if( binary ) "rb" else "r")));
	}

	public static function write( path : String, binary : Bool ) {
		return new FileOutput(untyped file_open(path.__s,(if( binary ) "wb" else "w")));
	}

	public static function append( path : String, binary : Bool ) {
		return new FileOutput(untyped file_open(path.__s,(if( binary ) "ab" else "a")));
	}

	public static function copy( src : String, dst : String ) {
		var s = read(src,true);
		var d = write(dst,true);
		d.writeInput(s);
		s.close();
		d.close();
	}

	public static function stdin() {
		return new FileInput(file_stdin());
	}

	public static function stdout() {
		return new FileOutput(file_stdout());
	}

	public static function stderr() {
		return new FileOutput(file_stderr());
	}

	public static function getChar( echo : Bool ) : Int {
		return getch(echo);
	}

	private static var file_stdin = cpp.Lib.load("std","file_stdin",0);
	private static var file_stdout = cpp.Lib.load("std","file_stdout",0);
	private static var file_stderr = cpp.Lib.load("std","file_stderr",0);

	private static var file_contents = cpp.Lib.load("std","file_contents",1);
	private static var file_open = cpp.Lib.load("std","file_open",2);

	private static var getch = cpp.Lib.load("std","sys_getch",1);

}

#else
#error
#end