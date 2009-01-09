package chxdoc;

import haxe.rtti.CType;
import chxdoc.Types;

class EnumHandler extends TypeHandler<EnumContext> {
	public function new() {
		super();
	}

	public function pass1(e : Enumdef) : EnumContext {
		var context = newEnumContext(e);

		if( context.params != null && context.params.length != 0 )
			context.paramsStr = "<"+context.params.join(", ")+">";

		context.meta.keywords[0] = context.fileInfo.nameDots + " enum";

		for(c in context.constructors) {
			var f = newEnumFieldContext(c);
			if(f.args != null) {
				var me = this;
				f.argsStr = doStringBlock( function() {
					me.display(f.args, function(a) {
						if( a.opt )
							me.print("?");
						me.print(a.name);
						me.print(" : ");
						me.processType(a.t);
					},",");
				});
			}
			context.constructorInfo.push(f);
		}
		context.constructorInfo.sort(constructorInfoSorter);

		return context;
	}

	/**
		<pre>Types -> create documentation</pre>
	**/
	public function pass2(context : EnumContext) {
		if(context.doc != null)
			context.docsContext = processDoc(context.doc);
		else
			context.docsContext = null;
		for(f in context.constructorInfo) {
			if(f.doc == null)
				f.docsContext = null;
			else
				f.docsContext = processDoc(f.doc);
		}
	}

	/**
		<pre>Types	-> Resolve all super classes, inheritance, subclasses</pre>
	**/
	public function pass3(context : EnumContext) {
	}

	/**
		Array sort function for EnumContexts.
	**/
	public static function sorter(a : EnumContext, b : EnumContext) {
		return Utils.stringSorter(a.fileInfo.nameDots, b.fileInfo.nameDots);
	}

	static function constructorInfoSorter(a : EnumFieldContext, b : EnumFieldContext) {
		return Utils.stringSorter(a.name, b.name);
	}

	public static function write(context : EnumContext) : String  {
		var t = new mtwin.templo.Loader("enum.mtt");
		try {
			var rv = t.execute(context);
			return rv;
		} catch(e : Dynamic) {
			trace("ERROR generating doc for " + context.path + ". Check enum.mtt");
			return neko.Lib.rethrow(e);
		}
	}

	function newEnumContext(c : Enumdef) : EnumContext {
		return {
			meta			: newMetaData(),
			build			: ChxDocMain.buildData,
			platform		: ChxDocMain.platformData,
			footerText		: "",
			fileInfo		: makeFileInfo(c),
			paramsStr		: "",
			constructorInfo	: new Array(),
			docsContext		: null,

			// inherited from TypeInfos
			path			: c.path,
			module			: c.module,
			params			: c.params, // Array<String> -> paramsStr
			doc				: c.doc, // raw docs
			isPrivate		: (c.isPrivate ? true : false),
			platforms		: c.platforms, // List<String>

			// inherited from Enumdef
			isExtern		: (c.isExtern ? true : false),
			constructors	: c.constructors,
		};
	}

	function newEnumFieldContext(f : EnumField) : EnumFieldContext {
		return {
			argsStr			: null,
			docsContext		: null,

			// inherited from EnumField
			platforms		: f.platforms, // List<String>
			name			: f.name,
			doc 			: f.doc,
			args			: f.args, // Null<List<{ t : CType, opt : Bool, name : String }>>
		}
	}


}