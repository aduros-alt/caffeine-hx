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

package chx.vfs;

/**
	A base class representing any real or virtual file
	@todo Write me
	@author rweir
**/
class File {
	var name(getName, null) : String;
	var path(default, null) : Path;
	var size : Int;
	var mode : Int;
	var uid : Int;
	var gid : Int;
	var mtime : Date;
	/** @todo Move to a registry map of uid->username**/
	var user : String;
	/** @todo Move to a registry map of gid->groupname**/
	var group : String;


	public function getName() : String {
		return path.name;
	}

	/**
		Will create a File based on a uri.
	**/
	public static function createFromURI(uri : chx.net.URI) : File {
		return throw new chx.lang.FatalException("not written");
	}

	//--------  API ---------//

	/**
		The handlers for each uri with pointers to the function
		that shall return a File instance
	**/
	static var uriHandlers : Hash<String -> File> = new Hash();

	/**
		File implementations must register what URI types they handle
		on initialization
		@param uriType short uri type (ie. http)
		@param f Function taking the full URI and returning a File
	**/
	static function registerURIHandler(uriType:String, f : String->File) {
		if(uriHandlers.exists(uriType))
			throw new chx.lang.FatalException("URI Type " + uriType + " already registered");
		uriHandlers.set(uriType, f);
	}
}