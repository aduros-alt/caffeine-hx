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

import haxe.xml.Check;

enum XmlConfigError {
	FileOpenError;
	FileReadError;
	AlreadyLoaded;
	XmlParseError(e:Dynamic);
	XmlMissingError(e:Dynamic);
}

class XmlConfigSection {
	public var name(default, null) : String;
	public var xml(default, null) : Xml;
	public var v : Void->haxe.xml.Rule;

	public function new(name:String, x:Xml, validator : Void->haxe.xml.Rule)
	{
		this.name = name;
		xml = x.elementsNamed(name).next();
		if(xml == null)
			throw XmlParseError("Missing "+name+" section");
		this.v = validator;
	}

	public function checkFormat( ) {
		var rule = v();
		try {
			haxe.xml.Check.checkNode(xml, rule);
		}
		catch(e:Dynamic) {
			throw XmlMissingError(e);
		}
	}
}

/**
	An XmlConfig file is defined by the node <config>, and can hold
	multiple sections with arbitrary names, so it is possible to
	configure multiple things in one config file. Once the data is
	loaded through one of the load functions, further attempts to
	load data will result in an exception.
**/
class XmlConfig {
	var xml : Xml;
	var sections : Hash<XmlConfigSection>;
	var loaded : Bool;

	public function new() {
		sections = new Hash();
		loaded = false;
	}

	/**
		Load from file
	**/
	public function loadFile( path : String ) {
		if(loaded)
			throw AlreadyLoaded;
#if neko
		var i : neko.io.FileInput = null;
		var b : neko.io.Bytes = null;
		try i = neko.io.File.read( path, false )
		catch(e:Dynamic) {
			onLoadError(FileOpenError);
		}
		try b = i.readAll()
		catch(e:Dynamic) {
			onLoadError(FileReadError);
		}
		loadString(b.toString());
#end
	}

	/**
		Load from a url. The function completeCallback will be
		called when the XmlConfig is loaded and ready for use.
	**/
	public function loadUrl( url : String, completeCallback : Void->Void )
	{
		if(loaded)
			throw AlreadyLoaded;
		if(url.substr(0,7) == "file://") {
			loadFile(url.substr(7));
			return;
		}
		var s = new haxe.Http(url);
		var me = this;
		s.onData = function(s:String) {
			me.loadString(s);
			completeCallback();
		}
		s.onError = onLoadError;
		s.request(false);
	}

	/**
		Populate from an xml string.
	**/
	public function loadString( s : String ) {
		var x : Xml;
		if(loaded)
			throw AlreadyLoaded;
		try {
			x = Xml.parse( s );
		}
		catch(e : Dynamic) {
			throw XmlParseError(e);
		}
		xml = x.elementsNamed("config").next();
		if(xml == null)
			throw XmlParseError("Missing config section");
		loaded = true;
	}

	/**
		Return the XmlConfigSection by name. The validator function
		must return a haxe.xml.Check Rule. The section will be cached
		once it is validated, so further accesses to the section
		will not cause section validation.
	**/
	public function getSection(name:String, validator : Void->haxe.xml.Rule) : XmlConfigSection
	{
		if(sections.exists(name))
			return sections.get(name);
		var sec = new XmlConfigSection(name, xml, validator);
		sec.checkFormat();
		sections.set(name, sec);
		return sec;
	}

	/**
		Override to handle loading errors. Default behavior is
		an exception.
	**/
	public function onLoadError(e:Dynamic) {
		throw(e);
	}
}
