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

package config;

enum DotConfigError {
	FileOpenError;
	FileReadError;
	AlreadyLoaded;
}

/*
private class DotNode implements Dynamic<DotConfig> {
	var data 		: String;
	var subNodes	: Hash<DotNode>;

	public function new( d : String ) {
		data = d;
	}

	function __resolve( name : String ) : DotNode {
		if(!subNodes.exists(name))
			throw "Element " + name + " does not exist";
		var dc = new DotConfig();
		return dc;
	}

	function __setfield( name: String, value : Dynamic) {
		//if(!subNodes.exists(name)) {
			subNodes.set(name, new DotNode(Std.string(value)));
		//}
	}
}
*/

/**
	DotConfig files consist of dotted path keys with string values, and look like <br />
	<i>
	Hive.Master = true
	Hive.Master.Port = 3460
	Hive.Master.Ip = 192.168.1.140;
	Http.Port = 80
	</i><br />
	The keys are case sensitive, and any path can contain a value and/or subkeys.
**/
class DotConfig {
	var sections			: Hash<DotConfig>;
	public var value		: String;
	var loaded 				: Bool;
	var parent				: DotConfig;

	public function new(?r : DotConfig) {
		sections = new Hash();
		loaded = false;
		parent = r;
	}

#if neko
	public function loadFile( path : String ) {
		if(parent != null)
			return parent.loadFile( path );
		if(loaded)
			throw AlreadyLoaded;
		var i : neko.io.FileInput;
		var s : String;
		try i = neko.io.File.read( path, false )
		catch(e:Dynamic) {
			onLoadError(FileOpenError);
		}
		try s = i.readAll()
		catch(e:Dynamic) {
			onLoadError(FileReadError);
		}
		loadString(s);
		return true;
	}
#end

	/**
		Populate from a string.
	**/
	public function loadString( s : String ) {
		if(parent != null)
			return parent.loadString( s );
		if(loaded)
			throw AlreadyLoaded;
		var lines = s.split("\n");
		var x : Int = 0;
		for(l in lines) {
			x ++;
			var ereg = ~/^[\s]*#/;
			if(ereg.match(l))
				continue;
			l = StringTools.ltrim(l);
			if(l == "")
				continue;
			var i = l.indexOf("=");
			if(i < 1)
				onParseError("Error on line " + x +": missing =");
			var textpath = StringTools.trim(l.substr(0,i));
			var value = StringTools.trim(l.substr(i+1));

			var sd = getRootPath(textpath);
			sd.section.set(sd.key, value);
		}
		loaded = true;
		return true;
	}

	/**
		Get a config section.
	**/
	public function section(name:String) : DotConfig
	{
		if(sections.exists(name))
			return sections.get(name);
		var sec = new DotConfig(this);
		sections.set(name, sec);
		return sec;
	}

	/**
		Get the fully qualified root path. This can be called from
		any sub path.
	**/
	public function getRootPath( textpath : String ) : { section: DotConfig, key: String }
	{
		if(parent != null)
			return parent.getRootPath( textpath );
		var path = textpath.split(".");
		if(path.length < 2)
			throw("Path too short");
		var key = path.pop();
		var section = this;
		for(p in path) {
			section = section.section(p);
		}
		return {section: section, key:key};
	}

	/**
		Get the value for the key 'name'
	**/
	public function get( name : String ) : String
	{
		if(sections.exists(name))
			return sections.get(name).value;
		return null;
	}

	/**
		Set a key to a value
	**/
	public function set( name : String, value: String ) {
		var sec = section(name);
		sec.value = value;
	}

	/**
		Override to handle loading errors. Default behavior is
		an exception.
	**/
	public function onLoadError(e:Dynamic) {
		throw(e);
	}

	/**
		Override to handle errors while parsing config file content.
	**/
	public function onParseError(e : String) {
		throw(e);
	}

	public function toString() : String {
		return "value: " + value + ", sections: " +  Std.string(sections);
	}
}