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

import haxe.rtti.CType;
import chxdoc.Defines;
import chxdoc.Types;

class PackageHandler extends TypeHandler<PackageContext> {
	var classHandler : ClassHandler;
	var enumHandler : EnumHandler;
	var typedefHandler : TypedefHandler;

	public function new() {
		super();
		this.classHandler = new ClassHandler();
		this.enumHandler = new EnumHandler();
		this.typedefHandler = new TypedefHandler();
	}

	public function pass1(name : String, full:String, subs : Array<TypeTree>) : PackageContext {
		var pkg = {
			name				: name,	// short name
			full				: full,	// full dotted name
			resolvedTypeDir		: "",	// final output path for types
			resolvedPackageDir	: "", // final output dir for package.html
			rootRelative		: new String(ChxDocMain.baseRelPath),
			classes				: new Array(),
			enums				: new Array(),
			typedefs			: new Array(),
		};

		if(name == "root") {
			name = "0";
			full = "";
			pkg.resolvedTypeDir = ChxDocMain.config.typeDirectory;
			pkg.resolvedPackageDir = ChxDocMain.config.packageDirectory;
		} else {
			var subdir = full.split(".").join("/") + "/";
			pkg.resolvedTypeDir = ChxDocMain.config.typeDirectory + subdir;
			pkg.resolvedPackageDir = ChxDocMain.config.packageDirectory + subdir;
		}

// 		trace("FOUND PACKAGE " + full + " named: "+name+" resolvedPath: " + pkg.resolvedPath);

		var setTypeParams = function(t) : TypeInfos {
			var info = TypeApi.typeInfos(t);
			TypeHandler.typeParams = Utils.prefix(info.params,info.path);
			return info;
		}

		for( entry in subs ) {
			switch(entry) {
			case TPackage(name, full, list):
				continue;
			case TTypedecl(t):
				var info = setTypeParams(entry);
				var ctx = typedefHandler.pass1(t);
				pkg.typedefs.push(ctx);
			case TEnumdecl(e):
				var info = setTypeParams(entry);
				var ctx = enumHandler.pass1(e);
				pkg.enums.push(ctx);
			case TClassdecl(c):
				var info = setTypeParams(entry);
				var ctx = classHandler.pass1(c);
				pkg.classes.push(ctx);
			}
		}
		return pkg;
	}

	public function pass2(pkg : PackageContext) {
		if(!isFilteredPackage(pkg.full)) {
			Utils.createOutputDirectory(pkg.resolvedTypeDir);
			Utils.createOutputDirectory(pkg.resolvedPackageDir);
		}
		for(ctx in pkg.classes)
			classHandler.pass2(pkg, ctx);
		for(ctx in pkg.enums)
			enumHandler.pass2(pkg, ctx);
		for(ctx in pkg.typedefs)
			typedefHandler.pass2(pkg, ctx);
	}

	/**
		<pre>Package -> Prune filtered types
				-> Sort classes
				-> Add all types to main types
		</pre>
	**/

	public function pass3(pkg : PackageContext) {
		if(isFilteredPackage(pkg.full))
			return;
		var hasTypes = false;
		for(ctx in pkg.classes) {
			classHandler.pass3(pkg, ctx);
			if(!isFilteredCtx(ctx)) {
				ChxDocMain.registerClass(ctx);
				hasTypes = true;
			}
		}
		for(ctx in pkg.enums) {
			enumHandler.pass3(pkg, ctx);
			if(!isFilteredCtx(ctx)) {
				ChxDocMain.registerEnum(ctx);
				hasTypes = true;
			}
		}
		for(ctx in pkg.typedefs) {
			typedefHandler.pass3(pkg, ctx);
			if(!isFilteredCtx(ctx)) {
				ChxDocMain.registerTypedef(ctx);
				hasTypes = true;
			}
		}
		if(hasTypes) {
			ChxDocMain.registerPackage(pkg);
			// write package html
		}
	}

	/**
		@todo Remove TypeInfos methods, check path correct
	**/
	public function pass4(pkg : PackageContext) {
		var config = ChxDocMain.config;
		if(isFilteredPackage(pkg.full))
			return;
		var me = this;

		var makeCtxPath = function(ctx : Ctx) {
			if(ctx.subdir == null)
				throw "Error determining output path for " + ctx.path;
			return  ChxDocMain.config.typeDirectory +
					Std.string(ctx.subdir) +
					Std.string(ctx.name) +
					ChxDocMain.config.htmlFileExtension;
		}
		var writeCtxHtml = function(ctx : Ctx, content: String) {
			var path = makeCtxPath(ctx);
			Utils.writeFileContents(path, content);
			neko.Lib.print(".");
		}

		var types = new Array<PackageFileTypesContext>();

		var makeTypeLink = function(ctx : Ctx) {
			return
				pkg.rootRelative +
				"../types/" +
				ctx.subdir +
				ctx.name +
				ChxDocMain.config.htmlFileExtension;
		}

		for(ctx in pkg.classes) {
			if(!isFilteredCtx(ctx)) {
				writeCtxHtml(ctx, ClassHandler.write(ctx));
				types.push(
					{
						type		: ctx.type,
						name		: ctx.name,
						linkString	: makeTypeLink(ctx),
					}
				);
			}
		}
		for(ctx in pkg.enums) {
			if(!isFilteredCtx(ctx)) {
				writeCtxHtml(ctx, EnumHandler.write(ctx));
				types.push(
					{
						type		: ctx.type,
						name		: ctx.name,
						linkString	: makeTypeLink(ctx),
					}
				);
			}
		}
		for(ctx in pkg.typedefs) {
			if(!isFilteredCtx(ctx)) {
				writeCtxHtml(ctx, TypedefHandler.write(ctx));
				types.push(
					{
						type		: ctx.type,
						name		: ctx.name,
						linkString	: makeTypeLink(ctx),
					}
				);
			}
		}

		if(types.length == 0)
			return;

		types.sort(function(a, b) { return Utils.stringSorter(a.name, b.name); });
		var t = new mtwin.templo.Loader("package.mtt");
		var output : String = "";
		try {
			output = t.execute(
				{
					meta			: newMetaData(),
					build			: ChxDocMain.buildData,
					platform		: ChxDocMain.config,
					name			: pkg.full,
					types			: types,
					rootRelative	: pkg.rootRelative,
				});
		} catch(e : Dynamic) {
			trace("ERROR generating package file for " + pkg.full + ". Check package.mtt");
			neko.Lib.rethrow(e);
		}

		var p = pkg.resolvedPackageDir + "package" + ChxDocMain.config.htmlFileExtension;
// 		trace("Writing " + p);
		Utils.writeFileContents(p, output);
	}

	public static function sorter(a : PackageContext, b : PackageContext) : Int {
		return Utils.stringSorter(a.full, b.full);
	}

	/** Returns true if the type is filtered **/
	function isFilteredCtx(ctx : Ctx) : Bool {
		if(Utils.isFiltered(ctx.path, false))
			return true;
		var showFlag = switch(ctx.type) {
		case "class", "interface": ChxDocMain.config.showPrivateClasses;
		case "enum": ChxDocMain.config.showPrivateEnums;
		case "typedef", "alias": ChxDocMain.config.showPrivateTypedefs;
		default:
			throw "bad type " + Std.string(ctx.type) + " for \n" +
			#if BUILD_DEBUG
			 	chx.Log.prettyFormat(ctx) + "\n";
			#else
				Std.string(ctx) + "\n";
			#end
		}
		if(showFlag)
			return false;
		return (ctx.isPrivate == true);
	}

	function isFilteredPackage(full : String) {
		return Utils.isFiltered(full, true);
	}

}