package chxdoc;

import haxe.rtti.CType;

typedef Html = String;

typedef Config = {
	var showPrivateClasses	: Bool;
	var showPrivateTypedefs	: Bool;
	var showPrivateEnums	: Bool;
	var showPrivateMethods	: Bool;
	var showPrivateVars		: Bool;
	var temploBaseDir		: String; // path
	var temploTmpDir		: String; // path
	var temploMacros		: String; // macros.mtt
};

typedef BuildData = {
	var date : String;
	var number : String;
	var comment : Html; // raw comment
};

typedef MetaData = {
	/**
		Short date for <META NAME="date" CONTENT="2009-01-23">
	**/
	var date			: String;
	/**
		Holds an array of keywords, first of which is type path [interface|class|enum]. <META NAME="keywords" CONTENT="haxe.Serializer class">
	**/
	var keywords		: Array<String>;
	/**
		Relative path to the stylesheet. <LINK REL ="stylesheet" TYPE="text/css" HREF="../../stylesheet" TITLE="Style">
	**/
	var stylesheet		: String;
};

typedef PlatformData = {
	var title 		: String;
	var subtitle 	: String;
};

typedef DocsContext = {
	var comments	: String;
	var throws		: Array<{name:String, uri:String, desc : String}>;
	var returns		: Array<String>;
	var params		: Array<{ arg : String, desc : String }>;
	var deprecated	: Bool;
	var depMessage	: String; // deprecation text
};

typedef PackageContext = {
	var name				: String;	// short name
	var full				: String;	// full dotted name
	var resolvedPath		: String;	// full final output path
	var classes				: Array<ClassContext>;
	var enums				: Array<EnumContext>;
	var typedefs			: Array<TypedefContext>;
};

/* This is found in CType
typedef TypeInfos = {
	// dotted path, incorrect for privates and flash9 use fileInfo
	var path : Path;

	var module : Path;       // not null if import different than classname
	var params : TypeParams; // Array<String> of <T> type params (without <>)
	var doc : String;		// raw documentation string
	var isPrivate : Bool;
	var platforms : Platforms; // available on ?. null if all
}

A Private class D defined in A.hx:
	path : chx.sys._A.D
	module: chx.sys.A
	Utils.formatPackagePath: chx.sys.D
*/

typedef FileInfo = {
	// example 1) public a.b.C 2) private a.b.D defined in a.b.C 3)flash9.MyClass
	// TypeInfos.path: 1) a.b.C 2) a.b._C.D
	var name			: String; // Short name.  1) C 2) D 3) MyClass
	var nameDots		: String; // Dotted filename 1) a.b.C 2) a.b._C.D 3) flash.MyClass
	var packageDots		: String; // Dotted package name. 1) a.b 2) a.b._C 3) flash
	var subdir			: String; // Relative subdir for html 1) a/b/ 2) a/b/_C/ 3) flash9
}

typedef ClassContext = {
	> Classdef,
	var meta			: MetaData;
	var build			: BuildData;
	var platform		: PlatformData;
	var footerText		: String;
	/** platforms, path, params, module, isPrivate, doc. Do not use this path **/
	var fileInfo		: FileInfo;
	var type			: String; // "class" or "interface"
	var paramsStr		: String;// string of type params ie. <T, B> or null
	var superClassHtml	: String; // html - null if no super
	var interfacesHtml	: Array<String>; // html array or null if none
	var dynamicTypeHtml : String; // Dynamic type html or null
	var constructor		: ClassFieldContext;
	var vars			: Array<ClassFieldContext>; // will exist
	var staticVars		: Array<ClassFieldContext>; // will exist
	var methods			: Array<ClassFieldContext>; // will exist
	var staticMethods	: Array<ClassFieldContext>; // will exist
	var docsContext		: DocsContext;				// null if no docs
	var subclasses		: Array<{nameDots : String, linkString : String}>; // will exist
};

typedef Inheritance = {
	var owner			: ClassContext;
	var nameDots		: String;
	var linkString		: String; // ../../a/b/MyClass.html
};

typedef ClassFieldContext = {
	var name 			: String;
	var returnType		: String; // html formatted return value or var type
	var isMethod 		: Bool;
	var isVar			: Bool;
	var isPublic 		: Bool;
	var isInherited		: Bool; // true if field (var or method) is inherited
	var isOverride		: Bool; // true if method is an override
	var inheritance		: Inheritance;
	var access			: String; // 'public' or 'private'
	var isStatic 		: Bool;
	var isDynamic		: Bool;
	var platforms		: List<String>; // available on ?. null if same as class
	var paramsStr		: String; // string of type params ie. <Int,Bool> or null
	var argsStr			: String; // html (a:Int, b:Int)
	var rights			: String;
	var docsContext		: DocsContext;
};

typedef EnumContext = {
	>Enumdef,
	var meta			: MetaData;
	var build			: BuildData;
	var platform		: PlatformData;
	var footerText		: String;
	var fileInfo		: FileInfo;
	var paramsStr		: String;// string of type params ie. <T; B>
	var constructorInfo	: Array<EnumFieldContext>;
	var docsContext		: DocsContext;
};

typedef EnumFieldContext = {
	>EnumField,
	var argsStr 		: String; // null or processed html
	var docsContext		: DocsContext;
};

typedef TypedefContext = {
	>Typedef,
	var meta			: MetaData;
	var build			: BuildData;
	var platform		: PlatformData;
	var footerText		: String;
	var fileInfo		: FileInfo;

	var paramsStr		: String; // string of type params ie. <Int;Bool>
	var typeHtml		: String; // string (if typedef wraps a type) or null if it is an anon object decl
	var typesInfo		: Array<{name : String, html: String}>;
	var docsContext		: DocsContext;
};

typedef PackageFileContext = {
	var meta		: MetaData;
	var build		: BuildData;
	var platform	: PlatformData;
	var name		: String;
	var types		: Array<PackageFileTypesContext>;
}

typedef NameLinkStringContext = {
	var name			: String;
	var linkString		: String;
}

typedef PackageFileTypesContext = {
	> NameLinkStringContext,
	var type			: String;
}

typedef IndexContext = {
	var meta		: MetaData;
	var platform	: PlatformData;
	var build		: BuildData;

	var packages	: Array<NameLinkStringContext>;
	var types		: Array<PackageFileTypesContext>;
}
