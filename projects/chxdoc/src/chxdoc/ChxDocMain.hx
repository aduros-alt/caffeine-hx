/*
 * Copyright (c) 2008-2009, The Caffeine-hx project contributors
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

package chxdoc;

import chxdoc.Defines;
import chxdoc.Types;
import haxe.rtti.CType;

class ChxDocMain {
	static var proginfo = "ChxDoc Generator 0.6 - (c) 2009 Russell Weir";
	static var buildNumber = 447;

	public static var buildData : BuildData;
	public static var platformData : PlatformData;

	public static var config : Config =
	{
		showAuthorTags		: false,
		showPrivateClasses	: false,
		showPrivateTypedefs	: false,
		showPrivateEnums	: false,
		showPrivateMethods	: false,
		showPrivateVars		: false,
		showTodoTags		: false,
		temploBaseDir		: "./templates/",
		temploTmpDir		: "./tmp/",
		temploMacros		: "macros.mtt",
		htmlFileExtension	: ".html", // .html

		stylesheet			: "stylesheet.css",

		baseDirectory		: "./html/",
		packageDirectory	: "./html/packages/",
		typeDirectory		: "./html/types/",

		noPrompt			: false, // not implemented
		installImagesDir	: false,
		installCssFile		: false,

		generateTodo		: false,
	};

	static var classPaths : List<String>;

	static var parser = new haxe.rtti.XmlParser();
	//static var todoLines : Array<{link: Link, message:String}> = new Array();

	/////////////////////
	//      Dates      //
	/////////////////////
	public static var now 			: Date;
	public static var shortDate 	: String;
	public static var longDate		: String;

	/** The platforms being generated for **/
	public static var platforms					: List<String>;

	/** the one instance of PackageHandler that crawls the TypeTree **/
	static var packageHandler : PackageHandler;
	/** the root context, named "0" */
	static var packageRoot		: PackageContext;
	/** all package contexts below the root */
	static var packageContexts : Array<PackageContext>;


	// These are only used during pass1, and are invalid after
	/** Current package being processed, dotted form **/
	public static var currentPackageDots : String;
	/** Path to ascend to base index directory **/
	public static var baseRelPath(default,null) : String;





	//////////////////////////////////////////////
	//               Pass 1                     //
	//////////////////////////////////////////////
	static function pass1(list: Array<TypeTree>) {
		for( entry in list ) {
			switch(entry) {
			case TPackage(name, full, subs):
				var ocpd = currentPackageDots;
				var obrp = baseRelPath;
				//path += name + "/";
				if(name != "root") {
					currentPackageDots = full;
					baseRelPath = "../" + baseRelPath;
				} else {
					currentPackageDots = "";
					baseRelPath = "";
				}
				var ctx = packageHandler.pass1(name, full, subs);
				if(name == "root")
					packageRoot = ctx;
				else
					packageContexts.push(ctx);

				pass1(subs);

				baseRelPath = obrp;
				currentPackageDots = ocpd;
			// the rest are handled by packageHandler
			default:
			}
		}
	}

	//////////////////////////////////////////////
	//               Pass 2                     //
	//////////////////////////////////////////////
	/**
		<pre>
		Types -> create documentation
		Package -> Make directories
		</pre>
	**/
	static function pass2() {
		packageContexts.sort(PackageHandler.sorter);
		packageHandler.pass2(packageRoot);
		for(i in packageContexts)
			packageHandler.pass2(i);
		// these were added in reverse order since DocProcessor does it that way
		platformData.todoLines.reverse();
	}


	//////////////////////////////////////////////
	//               Pass 3                     //
	//////////////////////////////////////////////

	// these are initialized in pass3
	// and contain all types that are not filtered
	static var allClasses : Array<ClassCtx>;
	static var allEnums : Array<EnumCtx>;
	static var allTypedefs : Array<TypedefCtx>;
	static var allTypes : Array<PackageFileTypesContext>;
	// all packages that have types not filtered
	static var allPackages : Array<PackageOutputContext>;

	/**
		<pre>
		Types	-> Resolve all super classes, inheritance, subclasses
		Package -> Prune filtered types
				-> Sort classes
				-> Add all types to main types
		</pre>
	**/
	static function pass3() {
		allClasses = new Array();
		allEnums = new Array();
		allTypedefs = new Array();
		allTypes = new Array();
		allPackages = new Array();
		packageHandler.pass3(packageRoot);
		for(i in packageContexts)
			packageHandler.pass3(i);

		allClasses.sort(TypeHandler.ctxSorter);
		allEnums.sort(TypeHandler.ctxSorter);
		allTypedefs.sort(TypeHandler.ctxSorter);
		allTypes.sort(function(a,b) {
			return Utils.stringSorter(a.name, b.name);
		});
		allPackages.sort(function(a,b) {
			return Utils.stringSorter(a.name, b.name);
		});
	}

	public static function registerClass(ctx : ClassCtx) : Void
	{
		allClasses.push(ctx);
		allTypes.push({
			name			: ctx.name,
			linkString		: "types/" + Utils.makeRelativeSubdirLink(ctx) + ctx.name + config.htmlFileExtension,
			type			: ctx.type,
		});
	}

	public static function registerEnum(ctx : EnumCtx) : Void
	{
		allEnums.push(ctx);
		allTypes.push({
			name			: ctx.name,
			linkString		: "types/" + Utils.makeRelativeSubdirLink(ctx) + ctx.name + config.htmlFileExtension,
			type			: ctx.type,
		});
	}

	public static function registerTypedef(ctx : TypedefCtx) : Void
	{
		allTypedefs.push(ctx);
		allTypes.push({
			name			: ctx.name,
			linkString		: "types/" + Utils.makeRelativeSubdirLink(ctx) + ctx.name + config.htmlFileExtension,
			type			: ctx.type,
		});
	}

	public static function registerPackage(context : PackageContext) : Void
	{
		allPackages.push({
			name			: context.full,
			linkString		: "packages/" + Utils.makeRelativePackageLink(context) + "package" + config.htmlFileExtension,
			rootRelative	: context.rootRelative,
		});
	}

	public static function registerTodo(pkg:PackageContext, ctx:Ctx, msg: String) {
		if(!config.generateTodo)
			return;
		var parentCtx = CtxApi.getParent(ctx, true);
		var childCtx = ctx;

		if(parentCtx == null) {
			parentCtx = ctx;
			childCtx = null;
		}

		var dots = parentCtx.packageDots;
		if(dots == null)
			dots = pkg.full;

		var href = "types/" +
				Utils.addSubdirTrailingSlash(dots.split(".").join("/")) +
				parentCtx.name +
				config.htmlFileExtension +
				CtxApi.makeAnchor(childCtx);

		var linkText = parentCtx.nameDots;

		platformData.todoLines.push({
			link: Utils.makeLink(
					href,
					linkText,
					"todoLine"
				),
			message: msg,
		});
	}

	//////////////////////////////////////////////
	//               Pass 4                     //
	//////////////////////////////////////////////
	/**
		Write everything
	**/
	static function pass4() {
		packageHandler.pass4(packageRoot);
		for(i in packageContexts)
			packageHandler.pass4(i);

		var e : PackageOutputContext = null;
		for(i in allPackages) {
			if(i.name == "root types") {
				e = i;
				break;
			}
		}
		if(e != null)
			allPackages.remove(e);


		var metaData = {
			date : DateTools.format(now, "%Y-%m-%d"),
			keywords : new Array<String>(),
			stylesheet : ChxDocMain.config.stylesheet,
		};
		metaData.keywords.push("");
		var context : IndexContext = {
			meta		: metaData,
			build 		: buildData,
			platform 	: platformData,

			packages	: allPackages,
			types		: allTypes,
		};

		for(i in ["index", "overview", "all_packages", "all_classes"]) {
			var t = new mtwin.templo.Loader(i+".mtt");
			Utils.writeFileContents(config.baseDirectory + i + config.htmlFileExtension, t.execute(context));
		}

		if(config.generateTodo) {
			var t = new mtwin.templo.Loader("todo.mtt");
			Utils.writeFileContents(config.baseDirectory + "todo" + config.htmlFileExtension, t.execute(context));
		}
	}


	//////////////////////////////////////////////
	//               Utilities                  //
	//////////////////////////////////////////////
	/**
		Locate a type context from it's full path in all
		packages. Can not be used until after pass 1.
	**/
	public static function findType( path : String ) : Ctx {
		var parts = path.split(".");
		var name = parts.pop();
		var pkgPath = parts.join(".");

		var pkg : PackageContext = null;
		if(pkgPath == "")
			pkg = packageRoot;
		else {
			for(i in packageContexts) {
				if(i.full == pkgPath) {
					pkg = i;
					break;
				}
			}
		}
		if(pkg == null)
			throw "Unable to locate package " + pkgPath + " for "+ path;

		for(ctx in pkg.classes) {
			if(ctx.name == name)
				return ctx;
		}
		throw "Could not find type " + path;
	}



	//////////////////////////////////////////////
	//              Main                        //
	//////////////////////////////////////////////
	public static function main() {
		#if BUILD_DEBUG
			chx.Log.redirectTraces(true);
		#end
		var print = neko.Lib.print;
		print(proginfo + "\n");
		now = Date.now();
		shortDate = DateTools.format(now, "%Y-%m-%d");
		longDate = DateTools.format(now, "%a %b %d %H:%M:%S %Z %Y");

		buildData = {
			date: shortDate,
			number: Std.string(buildNumber),
			comment: "<!-- Generated by chxdoc (build "+buildNumber+") on "+shortDate+" -->",
		};

		platformData = {
			title : "Haxe Application",
			subtitle : "http://www.haxe.org/",
			developer : false,
			platforms : new List(),
			footerText : null,
			generateTodo : false,
			todoLines : new Array(),
			todoFile	: "todo" + config.htmlFileExtension,
		}
		platforms = new List();

		initDefaultPaths();
		parseArgs();

		platformData.todoFile = "todo" + config.htmlFileExtension;
		platformData.generateTodo = config.generateTodo;

		if(	config.showPrivateClasses ||
			config.showPrivateTypedefs ||
			config.showPrivateEnums ||
			config.showPrivateMethods ||
			config.showPrivateVars)
				platformData.developer = true;
		platformData.platforms = platforms;

		checkAllPaths();


		////////////////
		//  Generator //
		////////////////
		packageHandler = new PackageHandler();
		packageContexts = new Array<PackageContext>();
		baseRelPath = "";

		pass1([TPackage("root", "root types", parser.root)]);
		print(".");
		pass2();
		print(".");
		pass3();
		print(".");
		pass4();
		print("\nComplete.\n");
	}


	static function initDefaultPaths() {
		config.baseDirectory = neko.Sys.getCwd() + "html/";
		config.packageDirectory = config.baseDirectory + "packages/";
		config.typeDirectory = config.baseDirectory + "types/";
	}

	static function checkAllPaths() {
		initTemplo();

		// Add trailing slashes to all directory paths
		config.baseDirectory = Utils.addSubdirTrailingSlash(config.baseDirectory);
		config.packageDirectory = config.baseDirectory + "packages/";
		config.typeDirectory = config.baseDirectory + "types/";

		Utils.createOutputDirectory(config.baseDirectory);
		Utils.createOutputDirectory(config.packageDirectory);
		Utils.createOutputDirectory(config.typeDirectory);

		var targetImgDir = config.baseDirectory + "images";
		/*
		if(!neko.FileSystem.exists(targetImgDir)) {
			var copyImgDir = config.installImagesDir;
			var srcDir = config.temploBaseDir + "images";
			if(neko.FileSystem.exists(srcDir)) {
				if(!copyImgDir && !config.noPrompt) {
					//copyImgDir = system.Terminal.promptYesNo("Install the images directory from the template?", true);
				}
			}
			if(copyImgDir) {
				// cp -R srcDir config.baseDirectory
			}
		}
		*/
		if(config.installImagesDir) {
			Utils.createOutputDirectory(targetImgDir);
			var srcDir = config.temploBaseDir + "images";
			if(neko.FileSystem.exists(srcDir) && neko.FileSystem.isDirectory(srcDir)) {
				targetImgDir += "/";
				var entries = neko.FileSystem.readDirectory(srcDir);
				for(i in entries) {
					var p = srcDir + "/" + i;
					switch(neko.FileSystem.kind(p)) {
					case kfile:
					default:
						continue;
					}
					neko.Lib.println("Installing " + p + " to " + targetImgDir);
					neko.io.File.copy(p, targetImgDir + i);
				}
			} else {
				logWarning("Template " + config.temploBaseDir + " has no 'images' directory");

			}
		}

		if(config.installCssFile) {
			var srcCssFile = config.temploBaseDir + "stylesheet.css";
			if(neko.FileSystem.exists(srcCssFile)) {
				var targetCssFile = config.baseDirectory + config.stylesheet;
				neko.Lib.println("Installing " + srcCssFile + " to " + targetCssFile);
				neko.io.File.copy(srcCssFile, targetCssFile);
			} else {
				logWarning("Template " + config.temploBaseDir + " has no stylesheet.css");
			}
		}
	}

	/**
		Initializes Templo, exiting if there is any error.
	**/
	static function initTemplo() {
		config.temploBaseDir = Utils.addSubdirTrailingSlash(config.temploBaseDir);
		config.temploTmpDir = Utils.addSubdirTrailingSlash(config.temploTmpDir);

		mtwin.templo.Loader.BASE_DIR = config.temploBaseDir;
		mtwin.templo.Loader.TMP_DIR = config.temploTmpDir;
		mtwin.templo.Loader.MACROS = config.temploMacros;

		var tmf = config.temploBaseDir + config.temploMacros;
		if(!neko.FileSystem.exists(tmf)) {
			neko.Lib.println("The macro file " + tmf + " does not exist.");
			neko.Sys.exit(1);
		}

		Utils.createOutputDirectory(config.temploTmpDir);
	}

	static function parseArgs() {
		initDefaultPaths();

		var expectOutputDir = false;
		var expectFilter = false;
		var expectClassPath = false;

		classPaths = new List();

		for( x in neko.Sys.args() ) {
			if( x == "-f" )
				expectFilter = true;
			else if( expectFilter ) {
				Utils.addFilter(x);
				expectFilter = false;
			}
			else if( x == "-o")
				expectOutputDir = true;
			else if( expectOutputDir ) {
				config.baseDirectory = x;
				config.baseDirectory = StringTools.replace(config.baseDirectory,"\\", "/");
				if(config.baseDirectory.charAt(0) != "/") {
					config.baseDirectory = neko.Sys.getCwd() + config.baseDirectory;
				}
				expectOutputDir = false;
			}
			else if( x == "-cp")
				expectClassPath = true;
			else if(expectClassPath) {
				classPaths.add(x);
				expectClassPath = false;
			}
			else if( x.indexOf("=") > 0) {
				var parts = x.split("=");
				if(parts.length < 2) {
					fatal("Error with parameter " + x);
				}
				if(parts.length > 2) {
					var zero = parts.shift();
					var rest = parts.join("");
					parts = [zero, rest];
				}
				switch(parts[0]) {
				case "--title": platformData.title = parts[1];
				case "--subtitle": platformData.subtitle = parts[1];
				case "--developer":
					var show = getBool(parts[1]);
					config.showAuthorTags = show;
					config.showPrivateClasses = show;
					config.showPrivateTypedefs = show;
					config.showPrivateEnums = show;
					config.showPrivateMethods = show;
					config.showPrivateVars = show;
					config.showTodoTags = show;
					config.generateTodo = show;
				case "--footerText":
					platformData.footerText = parts[1];
				case "--footerTextFile":
					try {
						platformData.footerText = neko.io.File.getContent(parts[1]);
					} catch(e : Dynamic) {
						fatal("Unable to load footer file " + parts[1]);
					}
				case "--generateTodoFile":
					config.generateTodo = getBool(parts[1]);
				case "--installTemplate":
					var i = getBool(parts[1]);
					config.installImagesDir = i;
					config.installCssFile = i;
				case "--stylesheet": config.stylesheet = parts[1];
				case "--showAuthorTags": config.showAuthorTags = getBool(parts[1]);
				case "--showPrivateClasses": config.showPrivateClasses = getBool(parts[1]);
				case "--showPrivateTypedefs": config.showPrivateTypedefs = getBool(parts[1]);
				case "--showPrivateEnums": config.showPrivateEnums = getBool(parts[1]);
				case "--showPrivateMethods": config.showPrivateMethods = getBool(parts[1]);
				case "--showPrivateVars": config.showPrivateVars = getBool(parts[1]);
				case "--showTodoTags": config.showTodoTags = getBool(parts[1]);
				case "--templateDir": config.temploBaseDir = parts[1];
				case "--tmpDir": config.temploTmpDir = parts[1];
				case "--macroFile": config.temploMacros = parts[1];
				}
			}
			else if( x == "--help" || x == "-help")
				usage(0);
			else {
				var f = x.split(",");
				loadFile(f[0],f[1],f[2]);
			}
		}
		// sort parsed entries
		parser.sort();
		if( parser.root.length == 0 ) {
			usage(1);
		}
	}

	static function getBool(s : String) : Bool {
		if(s == "1" || s == "true" || s == "yes")
			return true;
		return false;
	}

	static function usage(exitVal : Int) {
		var print = neko.Lib.println;
		print(proginfo);
		print(" Usage : chxdoc [options] [xml files]");
		print(" Options:");
		print("\t-f filter Add a package or class filter");
		print("\t-o outputdir Sets the output directory (defaults to ./html)");
// 		print("\t-cp classpath Add a source file class path"); // not implemented
		print("\t--title=string Set the package title");
		print("\t--subtitle=string Set the package subtitle");
		print("\t--developer=[true|false] Shortcut to showing all privates, if true");
		print("\t--footerText=\"text\" Text that will be added to footer of Type pages");
		print("\t--footerTextFile=/path/to/file Type pages footer text from file");
		print("\t--installTemplate=[true|false] Install stylesheet and images from template");
		print("\t--showPrivateClasses=[true|false] Toggle private classes display");
		print("\t--showPrivateTypedefs=[true|false] Toggle private typedef display");
		print("\t--showPrivateEnums=[true|false] Toggle private enum display");
		print("\t--showPrivateMethods=[true|false] Toggle private method display");
		print("\t--showPrivateVars=[true|false] Toggle private var display");
		print("\t--stylesheet=file Sets the stylesheet relative to the outputdir");
		print("\t--templateDir=path Path to template (.mtt) directory (default ./templates)");
		print("\t--tmpDir=path Path for tempory file generation (default ./tmp)");
		print("\t--macroFile=file.mtt Temploc macro file. (default macros.mtt)");
		print(" XML Files:");
		print("\tinput.xml[,platform[,remap]");
		print("\tXml files are generated using the -xml option when compiling haxe projects. ");
		print("\tplatform - generate docs for a given platform" );
		print("\tremap - change all references of 'remap' to 'package'");
		print(" Sample usage:");
		print("\tchxdoc flash9.xml,flash,flash9");
		print("\t\tWill transform all references to flash.* to flash9.*");
		print("");
		neko.Sys.exit(exitVal);
	}

	static function loadFile(file : String, platform:String, ?remap:String) {
		var data : String = null;
		try {
			data = neko.io.File.getContent(neko.Sys.getCwd()+file);
		} catch(e:Dynamic) {
			fatal("Unable to load platform xml file " + file);
		}
		var x = Xml.parse(data).firstElement();
		if( remap != null )
			transformPackage(x,remap,platform);

		parser.process(x,platform);
		if(platform != null)
			platforms.add(platform);
	}

	static function transformPackage( x : Xml, remap, platform ) {
		switch( x.nodeType ) {
		case Xml.Element:
			var p = x.get("path");
			if( p != null && p.substr(0,6) == remap + "." )
				x.set("path", platform + "." + p.substr(6));
			for( x in x.elements() )
				transformPackage(x, remap, platform);
		default:
		}
	}

	/**
	@todo Ctx may be a function, so we need the parent ClassCtx. Requires adding
			'parent' to Ctx typedef
	**/
	public static function logWarning(msg:String, ?pkg:PackageContext, ?ctx : Ctx) {
		if(pkg != null) {
			msg += " in package " + pkg.full;
		}
		if(ctx != null) {
			msg += " in " + ctx.name;
		}
		neko.Lib.println("WARNING: " + msg);
	}

	public static function fatal(msg:String, ?exitVal) {
		if(exitVal == null)
			exitVal = 1;
		neko.Lib.println("FATAL: " + msg);
		neko.Sys.exit(exitVal);
	}
}
