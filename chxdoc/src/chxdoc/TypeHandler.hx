package chxdoc;

import haxe.rtti.CType;
import chxdoc.Types;

class TypeHandler<T> {
	static var typeParams : TypeParams = new Array();

	public var curpackage : String;

	public function new() {
	}

	public dynamic function output(str) {
		neko.Lib.print(str);
	}

	public function print(str, ?params : Dynamic ) {
		if( params != null )
			for( f in Reflect.fields(params) )
				str = StringTools.replace(str, "$"+f, Std.string(Reflect.field(params, f)));
		output(str);
	}

	function doStringBlock(f : Void-> Void) : String {
		var oo = this.output;
		var s = new StringBuf();
		this.output = s.add;
		f();
		this.output = oo;
		return s.toString();
	}

	/**
		Creates a new metaData entry, with one empty entry in keywords
	**/
	function newMetaData() {
		var metaData = {
			date : ChxDocMain.shortDate,
			keywords : new Array<String>(),
			stylesheet : ChxDocMain.baseRelPath + ChxDocMain.stylesheet,
		};
		metaData.keywords.push("");
		return metaData;
	}

	/**
		From can be a ClassField, EnumField or TypeInfos type
	**/
	public function processDoc(doc : String) : DocsContext {
		var context = {
			comments : null,
			throws : new Array(),
			returns : new Array(),
			params : new Array(),
			deprecated : false,
			depMessage : null,
		};

		if( doc == null || doc.length == 0)
			return null;

		// unixify line endings
		doc = doc.split("\r\n").join("\n").split("\r").join("\n");
		// trim stars
		doc = ~/^([ \t]*)\*+/gm.replace(doc, "$1");
		doc = ~/\**[ \t]*$/gm.replace(doc, "");

		// process [] blocks
		var rx = ~/\[/;
		var tmp = new StringBuf();
		var codes = new List();
		while (rx.match(doc)) {
			tmp.add( rx.matchedLeft() );

			var code = rx.matchedRight();
			var brackets = 1;
			var i = 0;
			while( i < code.length && brackets > 0 ) {
				switch( code.charCodeAt(i++) ) {
				case 91: brackets++;
				case 93: brackets--;
				}
			}
			doc = code.substr(i);
			code = code.substr(0, i-1);
			code = ~/&/g.replace(code, "&amp;");
			code = ~/</g.replace(code, "&lt;");
			code = ~/>/g.replace(code, "&gt;");
			var tag = "##__code__"+codes.length+"##";
			if( code.indexOf('\n') != -1 ) {
				tmp.add("<pre>");
				tmp.add(tag);
				tmp.add("</pre>");
				codes.add(code.split("\t").join("    "));
			} else {
				tmp.add("<code>");
				tmp.add(tag);
				tmp.add("</code>");
				codes.add(code);
			}
		}
		tmp.add(doc);

		var parts = tmp.toString().split("\n");
		var newParts = new Array<String>();
		var i = 0;
		for(i in 0...parts.length) {
			var tagEreg = ~/[ \t]*@([A-Za-z]+)[ \t]*(.*)/;
			if(!tagEreg.match(parts[i])) {
				newParts.push(parts[i]);
				continue;
			}
			switch(tagEreg.matched(1)) {
			case "throw", "throws":
				var p = tagEreg.matched(2).split(" ");
				var e = p.shift();
				context.throws.push( {
					name : e,
					uri : Utils.makeRelPath(StringTools.replace(e,".","/")),
					desc : p.join(" "),
				});
			case "return", "returns":
				context.returns.push(tagEreg.matched(2));
			case "param":
				var p = tagEreg.matched(2).split(" ");
				context.params.push({ arg : p.shift(), desc : p.join(" ") });
			case "deprecated":
				context.deprecated = true;
				try {
					context.depMessage = tagEreg.matched(2);
				} catch(e:Dynamic) {
					context.depMessage = null;
				}
			default:
				trace("Unrecognized tag " + parts[i]);
			}
		}

		// separate into paragraphs
		parts = ~/\n[ \t]*\n/g.split(newParts.join("\n"));
		if( parts.length == 1 )
			doc = parts[0];
		else
			doc = Lambda.map(parts,function(x) { return "<p>"+StringTools.trim(x)+"</p>"; }).join("\n");

		// put back code parts
		i = 0;
		for( c in codes )
			doc = doc.split("##__code__"+(i++)+"##").join(c);
		context.comments = doc;
		return context;
	}

	function processType( t : CType ) {
		switch( t ) {
		case CUnknown:
			print("Unknown");
		case CEnum(path,params):
			processPath(path,params);
		case CClass(path,params):
			processPath(path,params);
		case CTypedef(path,params):
			processPath(path,params);
		case CFunction(args,ret):
			if( args.isEmpty() ) {
				processPath("Void");
				print(" -> ");
			}
			for( a in args ) {
				if( a.opt )
					print("?");
				if( a.name != null && a.name != "" )
					print(a.name+" : ");
				processTypeFun(a.t,true);
				print(" -> ");
			}
			processTypeFun(ret,false);
		case CAnonymous(fields):
			print("{ ");
			var me = this;
			display(fields,function(f) {
				me.print(f.name+" : ");
				me.processType(f.t);
			},", ");
			print("}");
		case CDynamic(t):
			if( t == null )
				processPath("Dynamic");
			else {
				var l = new List();
				l.add(t);
				processPath("Dynamic",l);
			}
		}
	}

	function processTypeFun( t : CType, isArg ) {
		var parent =  switch( t ) {
			case CFunction(_,_): true;
			case CEnum(n,_): isArg && n == "Void";
			default : false;
		};
		if( parent )
			print("(");
		processType(t);
		if( parent )
			print(")");
	}

	function display<T>( l : List<T>, f : T -> Void, sep : String ) {
		var first = true;
		for( x in l ) {
			if( first )
				first = false;
			else
				print(sep);
			f(x);
		}
	}


	function processPath( path : Path, ?params : List<CType> ) {
		print(makePathUrl(path,"type"));
		if( params != null && !params.isEmpty() ) {
			print("&lt;");
			for( t in params )
				processType(t);
			print("&gt;");
		}
	}

	function makePathUrl( path : Path, css ) {
		var p = path.split(".");
		var name = p.pop();
		var local = (p.join(".") == ChxDocMain.currentPackageDots);
		for( x in typeParams )
			if( x == path )
				return name;
		p.push(name);
		if( local )
			return Utils.makeUrl(p.join("/"),name,css);
		return Utils.makeUrl(p.join("/"), Utils.normalizeTypeInfosPath(path),css);
	}

	/**
		Makes a FileInfo structure from a TypeInfos structure. Used
		for Types, not Packages.
	**/
	function makeFileInfo( info : TypeInfos) : FileInfo {
		// with flash9
		var path = info.path;

		// with flash only
		var normalized =  Utils.normalizeTypeInfosPath(path).split(".");
		var nameDots = normalized.join(".");
		var name = normalized.pop();
		var packageDots = normalized.join(".");
		var parts = path.split(".");
		parts.pop();
		return {
			name 		: name,
			nameDots	: nameDots,
			packageDots : packageDots,
			subdir		: Utils.addSubdirTrailingSlash(parts.join("/")),
		}
	}

	/**
		Makes the base relative path from a context.
	**/
	function makeBaseRelPath(info : TypeInfos) {
		var parts = info.path.split(".");
		parts.pop();
		var s = "";
		for(i in 0...parts.length)
			s += "../";
		return s;
	}

	/**
		Sorter for any type array.
	**/
	static function TypeSorter(a : TypeInfos, b : TypeInfos) {
		var ap : String = null;
		var bp : String = null;
		if(Reflect.hasField(a, "fileInfo")) {
			ap = untyped a.fileInfo.nameDots;
		} else {
			ap = a.path;
		}
		if(Reflect.hasField(b, "fileInfo")) {
			bp = untyped b.fileInfo.nameDots;
		} else {
			bp = b.path;
		}
		return Utils.stringSorter(ap, bp);
	}
}