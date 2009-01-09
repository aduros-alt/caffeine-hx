package chxdoc;

import haxe.rtti.CType;
import chxdoc.Types;

class Utils {
	static var filters : List<String> = new List<String>();

	/**
		Takes all items in arr and prefixes them with the
		path and leading period.
		@param arr Package or class names
		@param path Prepended path data
		@return New array of strings
	**/
	public static function prefix( arr : Array<String>, path : String ) : Array<String> {
		var arr = arr.copy();
		for( i in 0...arr.length )
			arr[i] = path + "." + arr[i];
		return arr;
	}

	/**
		Transforms flash9.xxx to flash
	**/
// and any private types, which are
// 		created in subdirectories with a leading underscore,, have
// 		the underscore directory removed.
	public static function normalizeTypeInfosPath(path : String) : String {
		if( path.substr(0,7) == "flash9." )
			return "flash."+path.substr(7);
		return path;
	}

	/**
		Basic string sort function for Array.sort()
		@param a First string
		@param b Second string
		@return 0 if a == b, 1 if a > b, -1 if a < b
	**/
	public static function stringSorter(a : String, b : String) : Int {
		if(a > b) return 1;
		if(a < b) return -1;
		return 0;
	}

	/**
		Sorts an array of TypeTree elements based on full paths
		@param a Array to be sorted in place
	**/
	public static function sortTypeTree(a : Array<TypeTree>) : Void {
		var f = function(a, b) {
			var nameA = extractFullPath(a);
			var nameB = extractFullPath(b);
			return stringSorter(nameA, nameB);
		}
		a.sort(f);
	}

	/**
		Extracts the full path from a TypeTree instnace.
	**/
	public static function extractFullPath(t : TypeTree) : String {
		return switch(t) {
			case TPackage(_, full, _): full;
			case TEnumdecl(t): t.path;
			case TClassdecl(t): t.path;
			case TTypedecl(t): t.path;
		};
	}

	public static function stringFormatTree(list : Array<TypeTree>, indent:String, expandClasses: Bool) : String {
		var s : String = "";
		for( entry in list ) {
			switch(entry) {
			case TPackage(name, full, l):
				s += "\n"+indent+"TPackage " + full + " {" + stringFormatTree(l, indent + "  ", expandClasses);
				s += "\n"+indent+"}";
			case TTypedecl(t):
				s += "\n"+indent+"TTypedecl(" + t.path + ")";
			case TEnumdecl(e):
				s += "\n"+indent+"TEnumdecl(" + e.path + ")";
			case TClassdecl(c):
				if(!expandClasses)
					s += "\n"+indent+"TClassdecl(" + c.path + ")";
				else s += "\n"+indent+Std.string(c);
			}
		}
		return s;
	}

	/**
		Returns a keyword for the access rights of a class var
	**/
	public static function rightsStr(r) : String {
		return switch(r) {
		case RDynamic: "dynamic";
		case RF9Dynamic: "f9dynamic";
		case RMethod(m): m;
		case RNormal: "default";
		case RNo: "null";
		}
	}

	/**
		Creates a path to an html file relative to the current path.
	**/
	public static function makeRelPath( pathStr : String ) {
		return ChxDocMain.baseRelPath + pathStr  + ".html";
	}

	public static function makeUrl( url, text, cssClass ) {
		return "<a href=\"" + ChxDocMain.baseRelPath + url + ".html \" class=\""+cssClass+"\">"+text+"</a>";
	}

	public static function makeTypeBaseRelPath(path : String) {
		var parts = path.split(".");

	}

	/////////////////////////////////////
	//              FILTERS            //
	/////////////////////////////////////
	public static function addFilter(s : String) {
		filters.add(s);
	}

	/**
		Checks if a package or class is filtered
	**/
	public static function isFiltered( path : Path, isPackage : Bool ) {
		if( isPackage && path == "Remoting" )
			return true;
		if( StringTools.endsWith(path,"__") )
			return true;
		if( filters.isEmpty() )
			return false;
		for( x in filters )
			if( StringTools.startsWith(path,x) )
				return false;
		return true;
	}

	public static function writeFileContents(filePath:String, contents: String) {
		var fp = neko.io.File.write(filePath, true);
		fp.writeString(contents);
		fp.flush();
		fp.close();
	}

	public static function addSubdirTrailingSlash(dir : String) {
		if(dir.length > 0)
			if(dir != "/" && dir.charAt(dir.length -1) != "/")
				return dir + "/";
		return dir;
	}

	public static function makeRelativeSubdirLink(context : TypeInfos) {
		var parts = context.path.split(".");
		parts.pop();
		return addSubdirTrailingSlash(parts.join("/"));
	}

	public static function makeRelativePackageLink(context : PackageContext) {
		var parts = context.full.split(".");
		return addSubdirTrailingSlash(parts.join("/"));
	}
}
