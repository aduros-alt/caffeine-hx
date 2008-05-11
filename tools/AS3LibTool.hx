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

package tools;

/**
**/

enum AssetType {
	UNKNOWN;
	SWF;
	IMAGE;
	CLASS;
}

typedef Descriptor = {
/*
	var name:String;
	var className:String;
	var relpath : String;
*/
	var path : Array<String>;
	var filename : String;
	var extension : String;
	var type:AssetType;
};

class AS3LibTool {
	static var system : String = { neko.Sys.systemName(); }
	static var indir 	: String;
	static var outdir	: String;
	static var haxedir  : String;
	static var cpath	: Array<String>;

	static var sources  : Array<Descriptor> = new Array();
	static var outfilename : String = "as3libtool_assets.swf";
	static var mainClassName : String = "as3libtool_res";
	static var mainClassContent : String = "package{\n\timport flash.display.Sprite;\n\tpublic class as3libtool_res extends Sprite {\n\t\tpublic function as3libtool_res() { super(); }\n\t}\n}";

	static var imgAppend : String = "";
	static var mxmlc	 : String = "mxmlc";
	static var doClasses : Bool = true;
	static var doImages  : Bool = true;
	static var doSwfs    : Bool = true;
/*
	static var haxe_base: String;
	static var haxe_cur : String;
	static var env 		: Hash<String>;

*/
	static var eClasses = ~/^(.+)\.(as)$/i;
	static var eImg = ~/^(.+)\.((png)|(gif)|(jpg)|(jpeg))$/i;
	static var eSwf = ~/^(.+)\.(swf)$/i;

	public static function usage() {
		var pf = neko.Lib.println;
		neko.Lib.println("as3libtool -i [path] -o [path] -h [path]");
		pf("Creates classes for all assets in inputdir into outdir");
		pf("\t-i [inputdir]   Input source path");
		pf("\t-o [output.swf] Output library file");
		pf("\t-h [haxedir]    Path for outputting haxe extern classes");

		pf("\t--build [path]  Path for compiling classes into");
		pf("\t--img-append [text] Append text to class names for image resources");
		pf("\t--no-images     Do not process images in inputdir");
		pf("\t--no-swf        Do not add swf files found in input dir");
		pf("\t--no-classes    Ignore .as files in inputdir");
		pf("\t--mxmlc [path]  mxmlc compiler binary");

	}
	public static function main() {
		var argv = neko.Sys.args();
		var startdir = neko.Sys.getCwd();
		if(argv.length < 2) {
			usage();
			neko.Sys.exit(1);
		}

		var i = 0;
		while(i < argv.length) {
			switch(argv[i]) {
			case "-i":
				indir = neko.FileSystem.fullPath(argv[++i]);
				if(!neko.FileSystem.isDirectory(indir))
					error("Specify the input directory");
			case "-o":
				outfilename = argv[++i];
			case "--build":
				outdir = StringTools.trim(argv[++i]);
				if(!neko.FileSystem.exists(outdir) || !neko.FileSystem.isDirectory(outdir)) {
					try {
						neko.FileSystem.createDirectory(outdir);
					}
					catch(e:Dynamic) {
						error("Unable to create output directory.");
					}
				}
				outdir = neko.FileSystem.fullPath(outdir);
			case "--img-append":
				imgAppend = argv[++i];
				log("> appending " + imgAppend + " to images");
			case "--no-images":
				doImages = false;
			case "--no-swf":
				doSwfs = false;
			case "--no-classes":
				doClasses = false;
			case "--mxmlc":
				mxmlc = argv[++i];
			default:
				error("Unknown option " + argv[i]);
			}
			i++;
		}
		if(indir == null)
			error("No input path specified");
		if(outdir == null)
			error("No output path specified");


		cpath = new Array();

		neko.Sys.setCwd(indir);
		sources = processDirectory(".");

		neko.Sys.setCwd(startdir);
		neko.Lib.println("");
		if(sources.length == 0) {
			error("No asset files to process.");
		}

		var cmdArgs : Array<String> = [
			"-source-path=" + outdir
		];

		var includeArgs = new Array<String>();
		for(s in sources) {
			switch(s.type) {
			case UNKNOWN,IMAGE,SWF:
			case CLASS:
				copyClass(s);
				includeArgs.push(classPath(s));
			}
		}
		for(s in sources) {
			switch(s.type) {
			case UNKNOWN,SWF,CLASS:
			case IMAGE:
				includeArgs.push(classPath(s,imgAppend));
				createImageClass(s);
			}
		}

		if(includeArgs.length > 0) {
			cmdArgs.push("-includes");
			for(a in includeArgs) {
				cmdArgs.push(a);
			}
		}
		cmdArgs.push("-o");
		cmdArgs.push(outfilename);
		cmdArgs.push(outdir + "/" + mainClassName + ".as");

		createMainClass();
		log(mxmlc + cmdArgs.join(" "));
		neko.Sys.command(mxmlc, cmdArgs);
	}

	public static function error( s : String ) {
		neko.Lib.println(s);
		usage();
		neko.Sys.exit(1);
	}

	public static function getDirs(p : String) {
		var a = neko.FileSystem.readDirectory(p);
		var b : Array<String> = new Array();
		for(d in a) {
			if(!neko.FileSystem.isDirectory(d))
				continue;
			if(d == ".svn")
				continue;
			b.push(d);
		}
		return b;
	}

	public static function getFilesInCwd() {
		var a = neko.FileSystem.readDirectory(".");
		var b : Array<Descriptor> = new Array();
		for(d in a) {
			if(neko.FileSystem.isDirectory(d)) continue;
			var type = UNKNOWN;
			var filename : String = null;
			var ext : String = null;
			if(eClasses.match(d)) {
				if(!doClasses) continue;
				filename = eClasses.matched(1);
				ext = eClasses.matched(2);
				type = CLASS;
			}
			else if(eImg.match(d)) {
				if(!doImages) continue;
				filename = eImg.matched(1);
				ext = eImg.matched(2);
				type = IMAGE;
			}
			else if(eSwf.match(d)) {
				if(!doSwfs) continue;
				filename = eSwf.matched(1);
				ext = eSwf.matched(2);
				type = SWF;
			}
			else {
				log("!! Found unknown file " + d);
				continue;
			}
			if(!neko.FileSystem.isFile(d)) {
				error("file " + neko.Sys.getCwd() + "/"+ d + " is not a regular file!");
			}

			b.push({
				path:cpath.slice(1),
				filename: filename,
				extension:ext,
				type:type}
			);
		}
		return b;
	}


	static function log(s : String) {
		neko.io.File.stderr().write(s+"\n");
		neko.io.File.stderr().flush();
	}

	/**
		Create the output directories for flash and haxe.
	**/
	static function makeOutputPaths() : Void {
		if(cpath.length > 1) {
			createOutputPath(outdir, cpath.slice(1));
			if(haxedir != null)
				createOutputPath(haxedir, cpath.slice(1));
		}
	}

	static function processDirectory(p : String) : Array<Descriptor> {
		cpath.push(p);
		neko.Sys.setCwd(p);
		makeOutputPaths();
		var files = getFilesInCwd();
		for(f in files) {
			switch(f.type) {
			case UNKNOWN:
				error("Unset asset type!");
			case SWF:
				log("+[SWF] " + relativePath(f) );
			case IMAGE:
				log("+[IMG] " + relativePath(f) );
			case CLASS:
				log("+[AS3] " + relativePath(f) );
			}
		}
		var dirs = getDirs(".");
		for(d in dirs) {
			var ef = processDirectory(d);
			for(f in ef)
				files.push(f);
		}
		cpath.pop();
		neko.Sys.setCwd("./../");
		return files;
	}



	static function checkOverWrite(s) {
		if(neko.FileSystem.exists(s))
			error(s + " already exists in the output directory.");
	}

	/**
		Full relative path to file
		ie. /subdir/myimage.png
		replExt can replace the extension.
	**/
	static function relativePath(d:Descriptor, ?replExt:String) {
		var ext = d.extension;
		if(replExt != null)
			ext = replExt;
		var pp = "/" + d.filename + "." + ext;
		if(d.path.length > 0)
			return "/" + d.path.join("/") + pp;
		return pp;
	}

	/**
		Full path to original file
	**/
	static function sourcePath(d:Descriptor) {
		return indir + relativePath(d);
	}

	/**
		Full path to output file. If appendToFilename is specified, the resulting
		filename will be modified.
	**/
	static function destinationPath(d : Descriptor, ?appendToFilename:String) : String {
		if(appendToFilename == null) appendToFilename = "";
		var desc : Descriptor = {
			path: d.path,
			filename: d.filename + appendToFilename,
			extension: d.extension,
			type: d.type
		};

		return switch(d.type) {
		case UNKNOWN: "";
		case SWF, CLASS:
			outdir + relativePath(desc);
		case IMAGE:
			outdir + relativePath(desc, "as");
		}
	}

	/**
		FQ package name
	**/
	static function packageName(d) : String {
		return d.path.join(".");
	}

	/**
		FQ class path ie mydir.myclass
	**/
	static function classPath(d:Descriptor, ?appendToClassName:String) {
		if(appendToClassName == null)
			appendToClassName = "";
		var rv = Std.string(packageName(d));
		if(d.path.length > 0) rv += ".";
		rv += d.filename + appendToClassName;
		return rv;
	}

	/**
		Create a path in an output directory. Base is a path with no trailing /
	**/
	static function createOutputPath(base:String, e:Array<String>) {
		var p = base + "/" + e.join("/");
		if(neko.FileSystem.exists(p)) {
			if(!neko.FileSystem.isDirectory(p)) {
				error("Unable to create output directory " + p);
			}
			return;
		}

		try {
			neko.FileSystem.createDirectory(p);
		}
		catch(e:Dynamic) {
			error("Unable to create output directory " + p);
		}
	}

	static function copyClass(d) {
		var spath = sourcePath(d);
		var dpath = destinationPath(d);
		neko.io.File.copy(spath,dpath);
	}

	static function createImageClass(d) {
		var spath = sourcePath(d);
		var dpath = destinationPath(d, imgAppend);
		var s = "package " + packageName(d) + " {\n";
		s += "\timport flash.display.Sprite;\n";
		s += "\tpublic class " + d.filename + imgAppend + " extends Sprite {\n";
		s += "\t\t[Embed(source=\"" + sourcePath(d) + "\")]\n";
		s += "\t\tprivate var c:Class;\n";
		s += "\t\tpublic function " + d.filename + imgAppend + "() {\n";
		s += "\t\t\tsuper();\n";
		s += "\t\t\taddChild(new c());\n";
		s += "\t\t}\n";
		s += "\t}\n";
		s += "}\n";

		var fo = neko.io.File.write(destinationPath(d, imgAppend), false);
		fo.write(s);
		fo.close();
	}

	static function createMainClass() {
		var fo = neko.io.File.write(
				destinationPath(
					{
						path : new Array(),
						filename: mainClassName,
						extension: "as",
						type: CLASS
					}
				),
				false
		);
		fo.write(mainClassContent);
		fo.close();
	}

/*

	static function createStdLibPatch(file:String, caf:String, path:String ) {
		var hf = haxe_cur + path;
		var hs : String;
		try {
			hs = neko.io.File.getContent(hf);
		}
		catch(e:Dynamic) {
			hs = "";
		}
		var fdate : Date;
		try {
			fdate = neko.FileSystem.stat(hf).mtime;
		}
		catch(e:Dynamic) {
			fdate = Date.now();
		}

		var ofile = "haxe.orig/std" + path;
		var nfile = "haxe/std" + path;
		var oline = "--- " + ofile + "     " + xdiff.Tools.dateFormat(fdate);
		var mline = "+++ " + nfile + "  " + xdiff.Tools.dateFormat(Date.now());

		var patch = xdiff.Tools.diff(hs, caf);
		var fo = new neko.io.StringOutput();
		//var fo = neko.io.File.write(file + ".patch",false);
		fo.write(oline + "\n");
		fo.write(mline + "\n");
		fo.write(patch);
		fo.close();
		return fo.toString();
	}
*/
}
