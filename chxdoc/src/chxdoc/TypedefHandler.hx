package chxdoc;

import haxe.rtti.CType;
import chxdoc.Types;

class TypedefHandler extends TypeHandler<TypedefContext> {
	public function new() {
		super();
	}

	public function pass1(t : Typedef) : TypedefContext {
		var context = newTypedefContext(t);

		if( context.params != null && context.params.length != 0 )
			context.paramsStr = "<"+context.params.join(", ")+">";

		context.meta.keywords[0] = context.fileInfo.nameDots + " typedef";


		if( t.platforms.length == 0 ) {
			processTypedefType(context, t.type, t.platforms, t.platforms);
		}
		else {
			var platforms = new List();
			for( p in t.platforms )
				platforms.add(p);
			for( p in t.types.keys() ) {
				var td = t.types.get(p);
				var support = new List();
				for( p2 in platforms )
					if( TypeApi.typeEq(td, t.types.get(p2)) ) {
						platforms.remove(p2);
						support.add(p2);
					}
				if( support.length == 0 )
					continue;
				processTypedefType(context, td, t.platforms, support);
			}
		}
		context.typesInfo.sort(typesInfoSorter);
		return context;
	}

	function processTypedefType(context : TypedefContext, t : CType, all : List<String>, platforms : List<String>) {

		var me = this;

		switch(t) {
		case CAnonymous(fields): // fields == list<{t:CType, name:String}>
			for( f in fields ) {
				var ti = {
					name : f.name,
					html: doStringBlock(
						function() {
							me.processType(f.t);
						}
					)
				};
				context.typesInfo.push(ti);
			}
		default:
			if( all.length != platforms.length ) {
			}
			context.typeHtml = doStringBlock(
				function() {
					me.processType(t);
				}
			);
		}
	}

	/**
		<pre>Types -> create documentation</pre>
	**/
	public function pass2(context : TypedefContext) {
		if(context.doc != null)
			context.docsContext = processDoc(context.doc);
		else
			context.docsContext = null;
	}

	/**
		<pre>Types	-> Resolve all super classes, inheritance, subclasses</pre>
	**/
	public function pass3(context : TypedefContext) {
	}

	public static function write(context : TypedefContext) : String  {
		var t = new mtwin.templo.Loader("typedef.mtt");
		try {
			var rv = t.execute(context);
			return rv;
		} catch(e : Dynamic) {
			trace("ERROR generating doc for " + context.path + ". Check typedef.mtt");
			return neko.Lib.rethrow(e);
		}
	}

	/**
		Array sort function for Typedefs.
	**/
	public static function sorter(a : TypedefContext, b : TypedefContext) {
		return Utils.stringSorter(a.fileInfo.nameDots, b.fileInfo.nameDots);
	}
	/**
		Sorter for TypedefContext.typesInfo
	**/
	static function typesInfoSorter(a : {name : String, html: String}, b : {name : String, html: String}) : Int
	{
		return Utils.stringSorter(a.name, b.name);
	}

	public function newTypedefContext(t : Typedef) : TypedefContext {
		return {
			meta			: newMetaData(),
			build			: ChxDocMain.buildData,
			platform		: ChxDocMain.platformData,
			footerText		: "",
			fileInfo		: makeFileInfo(t),

			paramsStr		: "",
			typeHtml		: null,
			typesInfo		: new Array(),
			docsContext		: null,

			// inherited from TypeInfos
			path			: t.path,
			module			: t.module,
			params			: t.params, // Array<String> -> paramsStr
			doc				: t.doc, // raw docs
			isPrivate		: (t.isPrivate ? true : false),
			platforms		: t.platforms, // List<String>

			// inherited from Typedef
			type			: t.type,	// CType
			types			: t.types,	// Hash<CType> // by platform
		};
	}

}