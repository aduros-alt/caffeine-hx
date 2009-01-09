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
package chxdoc;

import chxdoc.Types;
import haxe.rtti.CType;

class ChxDocMain {
	static var proginfo = "ChxDoc Generator 0.2 - (c) 2009 Russell Weir";
	static var buildNumber = 1;

	public static var buildData : BuildData;
	public static var platformData : PlatformData;

	public static var config : Config =
	{
		showPrivateClasses	: false,
		showPrivateTypedefs	: false,
		showPrivateEnums	: false,
		showPrivateMethods	: false,
		showPrivateVars		: false,
		temploBaseDir		: "./templates/",
		temploTmpDir		: "./tmp/",
		temploMacros		: "macros.mtt",
	};

	static var classPaths : List<String>;

	static var parser = new haxe.rtti.XmlParser();

	/////////////////////
	//      Dates      //
	/////////////////////
	public static var now 			: Date;
	public static var shortDate 	: String;
	public static var longDate		: String;

	/** The base output dir **/
	public static var outputDir(default, null) : String;
	/** the stylesheet name, relative to output root dir **/
	public static var stylesheet(default,null) : String;

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
	}


	//////////////////////////////////////////////
	//               Pass 3                     //
	//////////////////////////////////////////////

	// these are initialized in pass3
	// and contain all types that are not filtered
	static var allClasses : Array<ClassContext>;
	static var allEnums : Array<EnumContext>;
	static var allTypedefs : Array<TypedefContext>;
	static var allTypes : Array<PackageFileTypesContext>;
	// all packages that have types not filtered
	static var allPackages : Array<NameLinkStringContext>;

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

		allClasses.sort(ClassHandler.sorter);
		allEnums.sort(EnumHandler.sorter);
		allTypedefs.sort(TypedefHandler.sorter);
		allTypes.sort(function(a,b) {
			return Utils.stringSorter(a.name, b.name);
		});
		allPackages.sort(function(a,b) {
			return Utils.stringSorter(a.name, b.name);
		});
	}

	public static function registerClass(context : ClassContext) : Void
	{
		allClasses.push(context);
		allTypes.push({
			name			: context.fileInfo.name,
			linkString		: Utils.makeRelativeSubdirLink(context) + context.fileInfo.name + ".html",
			type			: (context.isInterface ? "interface" : "class"),
		});
	}

	public static function registerEnum(context : EnumContext) : Void
	{
		allEnums.push(context);
		allTypes.push({
			name			: context.fileInfo.name,
			linkString		: Utils.makeRelativeSubdirLink(context) + context.fileInfo.name + ".html",
			type			: "enum",
		});
	}

	public static function registerTypedef(context : TypedefContext) : Void
	{
		allTypedefs.push(context);
		allTypes.push({
			name			: context.fileInfo.name,
			linkString		: Utils.makeRelativeSubdirLink(context) + context.fileInfo.name + ".html",
			type			: (context.typeHtml == null ? "alias" : "typedef"),
		});
	}

	public static function registerPackage(context : PackageContext) : Void
	{
		allPackages.push({
			name			: context.full,
			linkString		: Utils.makeRelativePackageLink(context) + "package.html",
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

		var e : NameLinkStringContext = null;
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
			stylesheet : ChxDocMain.stylesheet,
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
			Utils.writeFileContents(outputDir + i +".html", t.execute(context));
		}
	}


	//////////////////////////////////////////////
	//               Utilities                  //
	//////////////////////////////////////////////
	/**
		Locate a type context from it's full path [TypeInfos.path] in all
		packages. Can not be used until after pass 1.
	**/
	public static function findType( path : String ) : TypeInfos {
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
			if(ctx.fileInfo.name == name)
				return ctx;
		}
		throw "Could not find type " + path;
	}



	//////////////////////////////////////////////
	//              Main                        //
	//////////////////////////////////////////////
	public static function main() {
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
		}
		stylesheet = "stylesheet.css";

		parseArgs();

		mtwin.templo.Loader.BASE_DIR = config.temploBaseDir;
		mtwin.templo.Loader.TMP_DIR = config.temploTmpDir;
		mtwin.templo.Loader.MACROS = config.temploMacros;

		////////////////
		//  Generator //
		////////////////
		packageHandler = new PackageHandler();
		packageContexts = new Array<PackageContext>();
		baseRelPath = "";

		pass1([TPackage("root", "root types", parser.root)]);
		pass2();
		pass3();
		pass4();
	}


	static function parseArgs() {
		var expectOutputDir = false;
		var expectFilter = false;
		var expectClassPath = false;

		classPaths = new List();
		outputDir = neko.Sys.getCwd() + "html/";
		stylesheet = "stylesheet.css";

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
				outputDir = x;
				outputDir = StringTools.replace(outputDir,"\\", "/");
				if(outputDir.charAt(0) != "/") {
					outputDir = neko.Sys.getCwd() + outputDir;
				}
				trace(outputDir);
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
				if(parts.length > 2)
					usage(1);
				switch(parts[0]) {
				case "--title": platformData.title = parts[1];
				case "--subtitle": platformData.subtitle = parts[1];
				case "--stylesheet": stylesheet = parts[1];
				case "--showPrivateClasses": config.showPrivateClasses = getBool(parts[1]);
				case "--showPrivateTypedefs": config.showPrivateTypedefs = getBool(parts[1]);
				case "--showPrivateEnums": config.showPrivateEnums = getBool(parts[1]);
				case "--showPrivateMethods": config.showPrivateMethods = getBool(parts[1]);
				case "--showPrivateVars": config.showPrivateVars = getBool(parts[1]);
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
// 		print("\t-s stylesheet Sets the stylesheet relative to the outputdir");
// 		print("\t-cp classpath Add a source file class path"); // not implemented
		print("\t--title=string Set the package title");
		print("\t--subtitle=string Set the package subtitle");
		print("\t--showPrivateClasses =[true|false] Toggle private classes display");
		print("\t--showPrivateTypedefs =[true|false] Toggle private typedef display");
		print("\t--showPrivateEnums =[true|false] Toggle private enum display");
		print("\t--showPrivateMethods =[true|false] Toggle private method display");
		print("\t--showPrivateVars =[true|false] Toggle private var display");
		print("\t--stylesheet=file Sets the stylesheet relative to the outputdir");
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
			usage(1);
		}
		var x = Xml.parse(data).firstElement();
		if( remap != null )
			transformPackage(x,remap,platform);

		parser.process(x,platform);
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

}
