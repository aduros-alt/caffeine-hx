package chxdoc;

import haxe.rtti.CType;
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
		var context = {
			name				: name,	// short name
			full				: full,	// full dotted name
			resolvedPath		: "",	// final output path
// 			typeCount			: 0,		// number of items in path
			classes				: new Array(),
			enums				: new Array(),
			typedefs			: new Array(),
		};

		if(name == "root") {
			name = "0";
			full = "";
			context.resolvedPath = ChxDocMain.outputDir;
		} else {
			context.resolvedPath = ChxDocMain.outputDir + full.split(".").join("/") + "/";
		}

// 		trace("FOUND PACKAGE " + full + " named: "+name+" resolvedPath: " + context.resolvedPath);

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
				context.typedefs.push(ctx);
			case TEnumdecl(e):
				var info = setTypeParams(entry);
				var ctx = enumHandler.pass1(e);
				context.enums.push(ctx);
			case TClassdecl(c):
				var info = setTypeParams(entry);
				var ctx = classHandler.pass1(c);
				context.classes.push(ctx);
			}
		}
		return context;
	}

	public function pass2(context : PackageContext) {
		if(!isFilteredPackage(context.full))
			Utils.createOutputDirectory(context.resolvedPath);
		for(ctx in context.classes)
			classHandler.pass2(ctx);
		for(ctx in context.enums)
			enumHandler.pass2(ctx);
		for(ctx in context.typedefs)
			typedefHandler.pass2(ctx);
	}

	/**
		<pre>Package -> Prune filtered types
				-> Sort classes
				-> Add all types to main types
		</pre>
	**/

	public function pass3(context : PackageContext) {
		if(isFilteredPackage(context.full))
			return;
		var hasTypes = false;
		for(ctx in context.classes) {
			classHandler.pass3(ctx);
			if(!isFilteredType("class", ctx)) {
				ChxDocMain.registerClass(ctx);
				hasTypes = true;
			}
		}
		for(ctx in context.enums) {
			enumHandler.pass3(ctx);
			if(!isFilteredType("enum", ctx)) {
				ChxDocMain.registerEnum(ctx);
				hasTypes = true;
			}
		}
		for(ctx in context.typedefs) {
			typedefHandler.pass3(ctx);
			if(!isFilteredType("typedef", ctx)) {
				ChxDocMain.registerTypedef(ctx);
				hasTypes = true;
			}
		}
		if(hasTypes) {
			ChxDocMain.registerPackage(context);
			// write package html
		}
	}

	public function pass4(context : PackageContext) {
		if(isFilteredPackage(context.full))
			return;
		var me = this;
		var makePath = function(ctx : TypeInfos) {
			var fi :FileInfo = cast Reflect.field(ctx, "fileInfo");
			if(fi == null)
				throw "Error determining output path for " + ctx.path;
			return  ChxDocMain.outputDir +
					Std.string(fi.subdir) +
					Std.string(fi.name) +
					".html";
		}
		var writeHtml = function(ctx : TypeInfos, content: String) {
			var path = makePath(ctx);
			Utils.writeFileContents(path, content);
		}

		var types = new Array<PackageFileTypesContext>();

// 		var pkgPathCount = context.full.split(".").length;
		var makeTypeLink = function(typeContext : TypeInfos) {
// 			var parts = typeContext.path.split(".");
// 			parts = parts.slice(pkgPathCount - parts.length);
// 			return parts.join("/") + ".html";
			return untyped typeContext.fileInfo.name + ".html";
		}

		for(ctx in context.classes) {
			if(!isFilteredType("class", ctx)) {
				writeHtml(ctx, ClassHandler.write(ctx));
				types.push(
					{
						type		: (ctx.isInterface ? "interface" : "class"),
						name		: ctx.fileInfo.name,
						linkString	: makeTypeLink(ctx),
					}
				);
			}
		}
		for(ctx in context.enums) {
			if(!isFilteredType("enum", ctx)) {
				writeHtml(ctx, EnumHandler.write(ctx));
				types.push(
					{
						type		: "enum",
						name		: ctx.fileInfo.name,
						linkString	: makeTypeLink(ctx),
					}
				);
			}
		}
		for(ctx in context.typedefs) {
			if(!isFilteredType("typedef", ctx)) {
				writeHtml(ctx, TypedefHandler.write(ctx));
				types.push(
					{
						type		: "typedef",
						name		: ctx.fileInfo.name,
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
					platform		: ChxDocMain.platformData,
					name			: context.full,
					types			: types,
				});
		} catch(e : Dynamic) {
			trace("ERROR generating package file for " + context.full + ". Check package.mtt");
			neko.Lib.rethrow(e);
		}

		var p = context.resolvedPath + "package.html";
// 		trace("Writing " + p);
		Utils.writeFileContents(p, output);
	}

	public static function sorter(a : PackageContext, b : PackageContext) : Int {
		return Utils.stringSorter(a.full, b.full);
	}

	/** Returns true if the type is filtered **/
	function isFilteredType(type:String, info : TypeInfos) {
		if(Utils.isFiltered(info.path,false))
			return true;
		var showFlag = switch(type) {
		case "class": ChxDocMain.config.showPrivateClasses;
		case "enum": ChxDocMain.config.showPrivateEnums;
		case "typedef": ChxDocMain.config.showPrivateTypedefs;
		default: throw "bad type " + Std.string(type) + " for " + Std.string(info);
		}
		if(showFlag)
			return true;
		return (info.isPrivate == true);
	}

	function isFilteredPackage(full : String) {
		return Utils.isFiltered(full, true);
	}

}