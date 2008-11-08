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
	static var system 		: String = { neko.Sys.systemName(); }
	static var indir 		: String;
	static var outdir		: String;
	static var haxeOutdir	: String;
	static var cpath		: Array<String>;

	static var sources  	: Array<Descriptor> = new Array();
	static var outfilename 	: String = "as3libtool_assets.swf";
	static var mainClassName: String = "as3libtool_res";
	static var mainClassContent: String = "package{\n\timport flash.display.Sprite;\n\tpublic class as3libtool_res extends Sprite {\n\t\tpublic function as3libtool_res() { super(); }\n\t}\n}";

	static var imgAppend 	: String = "";
	static var mxmlc	 	: String = "mxmlc";
	static var compc		: String = "compc";
	static var haxe			: String = "haxe";
	static var doClasses 	: Bool = true;
	static var doImages  	: Bool = true;
	static var doSwfs    	: Bool = true;

	static var capitalizeClassNames	: Bool = false;
	static var ignoreClassPaths		: Array<EReg> = new Array();
/*
	static var haxe_base: String;
	static var haxe_cur : String;
	static var env 		: Hash<String>;

*/
	static var eClasses = ~/^(.+)\.(as)$/i;
	static var eImg = ~/^(.+)\.((png)|(gif)|(jpg)|(jpeg))$/i;
	static var eSwf = ~/^(.+)\.(swf)$/i;

	public static function usage() {
		var pf = log;
		pf("as3libtool -i [path] -o [path] -h [path]");
		pf("Creates classes for all assets in inputdir into --build dir");
		pf("\t-i [inputdir]   Input source path.");
		pf("\t-o [path]  Path for compiling classes into.");

		pf("");
		pf("Build options");
		pf("\t-f [output.swf] Output library file name. Default as3libtool_assets.swf");
		pf("\t--haxe-extern [haxeOutdir] Path for outputting haxe extern classes, if needed.");

		pf("");
		pf("File naming modifiers");
		pf("\t--capitalize    Capitalizes any input file for class name generation");
		pf("\t--img-append [text] Append text to class names for image resources");

		pf("");
		pf("Exclude targets");
		pf("\t--ignore-classpath [class.path.[?*]] ignore sources with filename pattern matching (before appends)");
		pf("\t--no-images     Do not process images in inputdir");
		pf("\t--no-swf        Do not add swf files found in input dir");
		pf("\t--no-classes    Ignore .as files in inputdir");

		pf("");
		pf("Support program paths (if as3libtool is unable to locate automatically)");
		pf("\t--mxmlc [path]  mxmlc compiler binary");
		pf("\t--haxe [path]   haxe compiler binary");

	}
	public static function main() {
		var argv = neko.Sys.args();
		var startdir = neko.Sys.getCwd();
		if(argv.length < 2) {
			usage();
			neko.Sys.exit(1);
		}

		var icp = new Array<String>();
		var i = 0;
		while(i < argv.length) {
			switch(argv[i]) {
			case "-i":
				indir = neko.FileSystem.fullPath(argv[++i]);
				if(!neko.FileSystem.isDirectory(indir))
					error("Specify a correct input directory");
			case "-o":
				outdir = StringTools.trim(argv[++i]);
				if(!neko.FileSystem.exists(outdir) || !neko.FileSystem.isDirectory(outdir)) {
					try {
						neko.FileSystem.createDirectory(outdir);
					}
					catch(e:Dynamic) {
						error("Unable to create output directory.");
					}
				}
				//outdir = StringTools.trim(argv[++i]);
				outdir = neko.FileSystem.fullPath(outdir);
			case "-f":
				outfilename = argv[++i];
			case "--haxe-extern":
				haxeOutdir = argv[++i];
				if(!neko.FileSystem.exists(haxeOutdir) || !neko.FileSystem.isDirectory(haxeOutdir)) {
					try {
						neko.FileSystem.createDirectory(haxeOutdir);
					}
					catch(e:Dynamic) {
						error("Unable to create output directory.");
					}
				}
				haxeOutdir = neko.FileSystem.fullPath(haxeOutdir);
			case "--ignore-classpath":
				icp.push(argv[++i]);
			case "--img-append":
				imgAppend = argv[++i];
				log("> appending " + imgAppend + " to images");
			case "--capitalize":
				capitalizeClassNames = true;
			case "--no-images":
				doImages = false;
			case "--no-swf":
				doSwfs = false;
			case "--no-classes":
				doClasses = false;
			case "--mxmlc":
				mxmlc = argv[++i];
			case "--haxe":
				haxe = argv[++i];
			case "--help":
				usage();
				neko.Sys.exit(0);
			default:
				error("Unknown option " + argv[i]);
			}
			i++;
		}
		if(indir == null)
			error("No input path specified");
		if(outdir == null)
			error("No output path specified");

		for(cp in icp) {
			var parts = cp.split(".");
			if(parts.length == 1)
				parts.push(".*");
			parts[parts.length - 1] = checkCapitalize(parts[parts.length - 1]);
			var mcp = parts.join(".");
			mcp = StringTools.replace(mcp, ".", "\\.");
			mcp = StringTools.replace(mcp, "-", "\\-");
			mcp = StringTools.replace(mcp, "?", "[\\.]{1,0}");
			mcp = StringTools.replace(mcp, "*", ".*");
			mcp = "^" + mcp + "$";
			var ereg = new EReg(mcp, "");
			ignoreClassPaths.push(new EReg(mcp,""));
		}

		cpath = new Array();

		neko.Sys.setCwd(indir);
		sources = processDirectory(".");

		neko.Sys.setCwd(startdir);
		log("");
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
		if(neko.Sys.command(mxmlc, cmdArgs) != 0) {
			error("**** There was an error running mxmlc.\nPlease review the compiler output for possible causes.");
		}

		if(haxeOutdir != null) {
			var cwd = neko.Sys.getCwd();
			var orig : String = null;
			try orig = neko.FileSystem.fullPath(outfilename) catch(e:Dynamic) {
				error("*** Could not locate " + outfilename);
			}
			/**
				This hack is because
				1) Haxe will not take a full path to a file for --gen-hx-classes
				2) Neko has no FileSystem.copy (yes, I could open...stream.. ya ya)
			**/


			try neko.Sys.setCwd(haxeOutdir) catch(e:Dynamic) {
				error("*** Unable to change directory to "+ haxeOutdir);
			}

			try neko.FileSystem.rename(orig, "./" + outfilename) catch(e:Dynamic) {
				neko.Sys.setCwd(cwd);
				error("*** Unable to copy asset pack to "+ haxeOutdir + "\n");
			}

			var cleanup = function() {
				neko.FileSystem.rename("./" + outfilename, orig);
				neko.Sys.setCwd(cwd);
			}

			neko.Lib.print("Creating haxe extern classes in " + haxeOutdir + "...");
			var proc = new neko.io.Process(haxe, ["--gen-hx-classes", outfilename]);
			if(proc.exitCode() != 0) {
				log("ERROR.");
				cleanup();
				error(proc.stderr.readAll().toString());
			}
			log("complete.");
			cleanup();
		}
	}

	/**
		Logs a string to stderr and exits program
	**/
	public static function error( s : String ) {
		neko.io.File.stderr().writeString(s + "\n");
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

	public static function getFilesInCwd() : Array<Descriptor> {
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

			var d = {
				path:cpath.slice(1),
				filename: filename,
				extension:ext,
				type:type
			};
			if(!ignoreClassPath(classPath(d)))
				b.push(d);
		}
		return b;
	}


	static function log(s : String) {
		neko.io.File.stdout().writeString(s+"\n");
		neko.io.File.stdout().flush();
	}

	/**
		Create the output directories for flash and haxe.
	**/
	static function makeOutputPaths() : Void {
		if(cpath.length > 1) {
			createOutputPath(outdir, cpath.slice(1));
// 			--gen-hx-classes takes carfe of this
// 			if(haxeOutdir != null)
// 				createOutputPath(haxeOutdir, cpath.slice(1));
		}
	}

	static function processDirectory(p : String) : Array<Descriptor> {
		cpath.push(p);
		var files = new Array();
		var bcp = cpath.slice(1).join(".");
		neko.Sys.setCwd(p);
		if(ignoreClassPath(bcp + ".")) {
			log(">>> Skipping path " + bcp);
		} else {
			log(">>> Starting " + (if(bcp == "") "(root)" else bcp));
			makeOutputPaths();
			files = getFilesInCwd();
			for(f in files) {
				switch(f.type) {
				case UNKNOWN:
					error("Unset asset type!");
				case SWF:
					log("+[SWF] " + relativePath(f));
				case IMAGE:
					log("+[IMG] " + relativePath(f));
				case CLASS:
					log("+[AS3] " + relativePath(f));
				}
			}
			var dirs = getDirs(".");
			for(d in dirs) {
				var ef = processDirectory(d);
				for(f in ef)
					files.push(f);
			}
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
		filename will be modified. If it is an image asset, the filename may be capitalized
		based on the capitalizeClassNames switch
	**/
	static function destinationPath(base:String, d : Descriptor, ?appendToFilename:String) : String {
		if(appendToFilename == null) appendToFilename = "";
		var desc : Descriptor = {
			path: d.path,
			filename: switch(d.type) {
				case IMAGE:
					checkCapitalize(d.filename) + appendToFilename;
				default:
					d.filename + appendToFilename;
				},
			extension: d.extension,
			type: d.type
		};

		return switch(d.type) {
		case UNKNOWN: "";
		case SWF, CLASS:
			base + relativePath(desc);
		case IMAGE:
			base + relativePath(desc, "as");
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
		rv += checkCapitalize(d.filename) + appendToClassName;
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
		var dpath = destinationPath(outdir, d);
		neko.io.File.copy(spath,dpath);
	}

	static function createImageClass(d) {
		var spath = sourcePath(d);
		var s = "package " + packageName(d) + " {\n";
		s += "\timport flash.display.Sprite;\n";
		s += "\tpublic class " + checkCapitalize(d.filename) + imgAppend + " extends Sprite {\n";
		s += "\t\t[Embed(source=\"" + sourcePath(d) + "\")]\n";
		s += "\t\tprivate var c:Class;\n";
		s += "\t\tpublic function " + checkCapitalize(d.filename) + imgAppend + "() {\n";
		s += "\t\t\tsuper();\n";
		s += "\t\t\taddChild(new c());\n";
		s += "\t\t}\n";
		s += "\t}\n";
		s += "}\n";

		var fo = neko.io.File.write(destinationPath(outdir, d, imgAppend), false);
		fo.writeString(s);
		fo.close();
	}

	/**
		This is just a stub class required for compiling with mxmlc
	**/
	static function createMainClass() {
		var fo = neko.io.File.write(
				destinationPath(
					outdir,
					{
						path : new Array(),
						filename: mainClassName,
						extension: "as",
						type: CLASS
					}
				),
				false
		);
		fo.writeString(mainClassContent);
		fo.close();
	}

	/**
		Takes a string class path and checks all --ignore-classpath args
		against it, returning true if the class is to be ignored.
	**/
	static function ignoreClassPath(s:String) : Bool {
		for(ereg in ignoreClassPaths) {
			if(ereg.match(s))
				return true;
		}
		return false;
	}

	/**
		Capitalizes a string if the
	**/
	static function checkCapitalize(s : String) : String {
		if(!capitalizeClassNames)
			return s;
		return s.substr(0,1).toUpperCase()+s.substr(1);
	}
}
