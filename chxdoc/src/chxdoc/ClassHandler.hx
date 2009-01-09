package chxdoc;

import haxe.rtti.CType;
import chxdoc.Types;

class ClassHandler extends TypeHandler<ClassContext> {
	public function new() {
		super();
	}

	public function pass1(c : Classdef) : ClassContext {
		var context = newClassContext(c);

		if( context.isInterface ) {
			context.type = "interface";
		}
		else {
			context.type = "class";
		}

		if( context.params != null && context.params.length != 0 )
			context.paramsStr = "<"+context.params.join(", ")+">";

		/*
		trace(
			"found " + context.type + " " +
			context.fileInfo.nameDots +
			(context.paramsStr != null ? context.paramsStr : "") +
			(context.module != null ? " in module " + context.module : "") +
			". Original "+ context.path +
			" and html out to " + context.fileInfo.subdir);
		*/

		if( context.superClass != null ) {
			var me = this;
			context.superClassHtml = doStringBlock(
				function() {
					me.processPath(context.superClass.path, context.superClass.params);
				}
			);
		}

		if(!context.interfaces.isEmpty()) {
			var me = this;
			context.interfacesHtml = new Array();
			for(i in context.interfaces) {
				context.interfacesHtml.push(
					doStringBlock(
						function() {
							me.processPath(i.path,i.params);
						}
					)
				);
			}
		}

		if(c.tdynamic != null) {
			var me = this;
			context.dynamicTypeHtml = doStringBlock(
				function() {
					var d = new List();
					d.add(c.tdynamic);
					me.processPath("Dynamic",d);
				}
			);
		}

		context.meta.keywords[0] = context.fileInfo.nameDots + " " + context.type;

		for( f in context.fields ) {
			var cfctx = classFieldPass1(context, c.platforms,f,false);
			if(cfctx != null) {
				if(cfctx.name == "new" && !context.isInterface) {
					context.constructor = cfctx;
				} else {
					if(cfctx.isMethod)
						context.methods.push(cfctx);
					else
						context.vars.push(cfctx);
				}
			}
		}

		for( f in context.statics ) {
			var cfctx = classFieldPass1(context, c.platforms,f,true);
			if(cfctx != null) {
				if(cfctx.isMethod)
					context.staticMethods.push(cfctx);
				else
					context.staticVars.push(cfctx);
			}
		}

		return context;
	}

	function classFieldPass1(cContext : ClassContext, platforms : Platforms, f : ClassField, stat : Bool) : ClassFieldContext {
		var context : ClassFieldContext = newClassFieldContext();
		context.isStatic = stat;
		var me = this;

		var oldParams = TypeHandler.typeParams;
		if( f.params != null )
			TypeHandler.typeParams = TypeHandler.typeParams.concat(Utils.prefix(f.params,f.name));

		context.name = f.name;
		context.isMethod = false;
		context.isVar = true;
		switch( f.type ) {
		case CFunction(args,ret):
			//trace("Examining method " + f.name + " in " + cContext.path + " f.get: " + Std.string(f.get));
			if( f.get == RNormal && (f.set == RNormal || f.set == RF9Dynamic) ) {
				context.isMethod = true;
				context.isVar = false;

				if( f.set == RF9Dynamic )
					context.isDynamic = true;
				context.name = f.name;
				if( f.params != null )
					context.paramsStr = "<"+f.params.join(", ")+">";
				else
					context.paramsStr = "";

				context.argsStr = doStringBlock( function() {
					me.display(args,function(a) {
						if( a.opt )
							me.print("?");
						if( a.name != null && a.name != "" ) {
							me.print(a.name);
							me.print(" : ");
						}
						me.processType(a.t);
					},", ");
				});

				context.returnType = doStringBlock(
					function() {
						me.processType(ret);
					}
				);
			}
		default:
		}
		if(context.isVar) {
			if( f.get != RNormal || f.set != RNormal )
				context.rights = ("("+Utils.rightsStr(f.get)+","+Utils.rightsStr(f.set)+")");
			else
				context.rights = null;

			context.returnType = doStringBlock(
				function() {
					me.processType(f.type);
				}
			);
		}

		if( !f.isPublic ) {
			context.isPublic = false;
			context.access = "private";
			if(context.isMethod && !ChxDocMain.config.showPrivateMethods)
				return null;
			if(context.isVar && !ChxDocMain.config.showPrivateVars)
				return null;
		} else {
			context.isPublic = true;
			context.access = "public";
		}

		if( f.platforms.length != platforms.length )
			context.platforms = f.platforms;

		context.docsContext = processDoc(f.doc);

		if( f.params != null )
			TypeHandler.typeParams = oldParams;
		return context;
	}

	public function pass2(context : ClassContext) {
		if(context.doc != null)
			context.docsContext = processDoc(context.doc);
		else
			context.docsContext = null;
	}

	//Types	-> Resolve all super classes, inheritance, subclasses
	public function pass3(context : ClassContext) {
		var sc = context.superClass;
// 		if(sc != null)
// 			trace("Class " + context.path + " has a super");
		var first = true;
		while(sc != null) {
			var source : ClassContext = cast ChxDocMain.findType(sc.path);
			if(first) {
				first = false;
				addSubclass(source, context);
			}
			for(i in source.vars)
				makeInheritedVar(context, source, i);
			for(i in source.methods)
				makeInheritedMethod(context, source, i);
			sc = source.superClass;
		}

		// private vars and methods do not need to be removed
		// here, since they are ignored in pass 1
		context.vars.sort(fieldSorter);
		context.methods.sort(fieldSorter);
	}

	/**
		Array sort function for classes.
	**/
	public static function sorter(a : ClassContext, b : ClassContext) {
		return Utils.stringSorter(a.path, b.path);
	}

	static function fieldSorter(a : ClassFieldContext, b:ClassFieldContext) {
		return Utils.stringSorter(a.name, b.name);
	}

	/**
		Returns a ClassFieldContext
	**/
	static function getMethod(context: ClassContext, name : String) : ClassFieldContext {
// 		if(tr) {
// 			trace("Searching " + context.path + " for method " + name);
// 			for(i in context.methods)
// 				trace("-> " + i.name);
// 		}
		for(i in context.methods)
			if(i.name == name)
				return i;
// 		if(tr)
// 			trace("----- not found");
		return null;
	}

	public static function write(context : ClassContext) : String  {
		var t = new mtwin.templo.Loader("class.mtt");
		try {
			var rv = t.execute(context);
			return rv;
		} catch(e : Dynamic) {
			trace("ERROR generating doc for " + context.path + ". Check class.mtt");
			return neko.Lib.rethrow(e);
		}
	}

	function newClassContext(c : Classdef) : ClassContext {
		return {
			meta			: newMetaData(),
			build			: ChxDocMain.buildData,
			platform		: ChxDocMain.platformData,
			footerText		: "",
			fileInfo		: makeFileInfo(c),
			type			: null,
			paramsStr		: null,
			superClassHtml	: null,
			interfacesHtml	: null,
			dynamicTypeHtml	: null,
			constructor 	: null,
			vars			: new Array(),
			staticVars		: new Array(),
			methods			: new Array(),
			staticMethods	: new Array(),
			docsContext		: null,
			subclasses		: new Array(),

			// inherited from TypeInfos
			path			: c.path,
			module			: c.module,
			params			: c.params, // Array<String> -> paramsStr
			doc				: c.doc, // raw docs
			isPrivate		: (c.isPrivate ? true : false),
			platforms		: c.platforms, // List<String>

			// inherited from Classdef
			isExtern		: c.isExtern,
			isInterface 	: c.isInterface,
			superClass		: c.superClass, // { path : String, params:List<CType>}
			interfaces		: c.interfaces,//List<{ path : String, params:List<CType>}>
			fields			: c.fields, // Liat<ClassField>
			statics			: c.statics, // List<ClassField>
			tdynamic		: c.tdynamic, // Null<CType>
		};
	}

	static function newClassFieldContext() : ClassFieldContext {
		return {
			name 		: null,
			returnType	: null,
			isMethod 	: false,
			isVar		: false,
			isPublic 	: true,
			isInherited	: false,
			isOverride	: false,
			inheritance : { owner :null, nameDots: null, linkString : null },
			access		: "public",
			isStatic 	: false,
			isDynamic	: false,
			platforms	: null,
			paramsStr	: null,
			argsStr		: "",
			rights		: "",
			docsContext		: null,
		};
	}


	function addSubclass(superClass : ClassContext, subClass : ClassContext) : Void {
		var link = makeBaseRelPath(superClass) +
			subClass.fileInfo.subdir +
			subClass.fileInfo.name + ".html";
		superClass.subclasses.push({
			nameDots : subClass.fileInfo.nameDots,
			linkString : link
		});
	}

	static function makeInheritedField(field : ClassFieldContext) {
		return {
			name 		: field.name,
			returnType	: field.returnType,
			isMethod 	: field.isMethod,
			isVar		: field.isVar,
			isPublic 	: field.isPublic,
			isInherited	: true,
			isOverride	: false,
			inheritance : {
							owner : null,
							nameDots: null,
							linkString : null,
						},
			access		: field.access,
			isStatic 	: field.isStatic,
			isDynamic	: field.isDynamic,
			platforms	: field.platforms,
			paramsStr	: field.paramsStr,
			argsStr		: field.argsStr,
			rights		: field.rights,
			docsContext	: field.docsContext,
		};
	}

	function makeInheritedVar(context : ClassContext, srcContext:ClassContext, field : ClassFieldContext) {
		var f = makeInheritedField(field);
		if(!field.isInherited) {
			f.inheritance.owner = srcContext;
			f.inheritance.nameDots = srcContext.fileInfo.nameDots;
		}
		else {
			f.inheritance.owner = field.inheritance.owner;
			f.inheritance.nameDots = field.inheritance.nameDots;
		}
		f.inheritance.linkString =
				makeBaseRelPath(context) +
				f.inheritance.owner.fileInfo.subdir +
				f.inheritance.owner.fileInfo.name + ".html";
		context.vars.push(f);
	}

	function makeInheritedMethod(context : ClassContext, srcContext:ClassContext, field : ClassFieldContext) {
		var cur = getMethod(context, field.name);
		if(cur != null && (cur.isInherited || cur.isOverride))
			return;

		var f = makeInheritedField(field);
		if(cur != null) {
			f.isInherited = false;
			f.isOverride = true;
		}
		if(!field.isInherited) {
			f.inheritance.owner = srcContext;
			f.inheritance.nameDots = srcContext.fileInfo.nameDots;
		}
		else {
			var f2 = getMethod(srcContext, field.name);
			while(!f2.isInherited)
				f2 = getMethod(f2.inheritance.owner, field.name);
			f.inheritance.owner = f2.inheritance.owner;
			f.inheritance.nameDots = f2.inheritance.nameDots;
		}
		f.inheritance.linkString =
				makeBaseRelPath(context) +
				f.inheritance.owner.fileInfo.subdir +
				f.inheritance.owner.fileInfo.name + ".html";
		context.methods.push(f);
	}


}
