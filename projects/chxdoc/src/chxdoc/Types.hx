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

// typedef Html = String; // output this as raw
typedef DotPath = String; // a.b.c

/**
	A DefType is one of class, typedef, alias, field, enum, enumfield
**/
typedef DefType = String;

/**
	Links include the html escaped text and href, as well as the css type.
**/
typedef Link = {
	var href		: Html;
	var text		: Html;
	var css			: String;
};

typedef PlatformCtx = {
	var platforms		: Array<String>;
	var data			: Ctx;
}

typedef Ctx = {
	var type				: DefType; // type of the definition

	// example 1) public a.b.C 2) private a.b.D defined in a.b.C 3)flash9.MyClass
	// TypeInfos.path: 1) a.b.C 2) a.b._C.D
	var name				: String; // Short name.  1) C 2) D 3) MyClass
	var nameDots			: DotPath; // Dotted filename 1) a.b.C 2) a.b._C.D 3) flash.MyClass
	var path				: String; // Dotted filename after remap
	var packageDots			: String; // Dotted package name. 1) a.b 2) a.b._C 3) flash
	var subdir				: String; // Relative subdir for html 1) a/b/ 2) a/b/_C/ 3) flash9/
	var rootRelative		: Html;   // Relative subdir for root 1) ../../ etc.

	/**
		if isAllPlatforms is set, contexts will only have one entry, which will
		define the type for all platforms
	**/
	var isAllPlatforms		: Bool;
	var platforms			: List<String>;
	var contexts			: Array<Ctx>;


	var params				: Html;			// "" or "<T>"
	var module				: DotPath;		// null if not contained in another file
	var isPrivate			: Bool;
	var access				: String;		// 'public' or 'private'
	var docs				: DocsContext;

	var meta				: MetaData;
	var build				: BuildData;
	var platform			: PlatformData;

	var setField			: String->Dynamic->Void;
	var originalDoc			: String;
}

/**
	All arrays in a ClassCtx will be initialized, but may be 0 length.
**/
typedef ClassCtx = {
	> Ctx,
	var scPathParams		: PathParams;		// null if no super, not for html output
	var superClassHtml		: Html;				// null if no super
	var superClasses		: Array<ClassCtx>;
	var interfacesHtml		: Array<Html>;		// Html list of interface links
	var isDynamic			: Bool; 			// true if class implements Dynamic
	var constructor			: FieldCtx;			// null if no constructor
	var vars				: Array<FieldCtx>;
	var staticVars			: Array<FieldCtx>;
	var methods				: Array<FieldCtx>;
	var staticMethods		: Array<FieldCtx>;
	var subclasses			: Array<Link>;
}

typedef Inheritance = {
	var owner			: ClassCtx;
	var link			: Link; // ../../a/b/MyClass.html, a.b.MyClass with css inherited
};

typedef FieldCtx = {
	> Ctx,
	var args				: Html; // "" or "a:Int, b:Int, etc"
	var returns				: Html; // html formatted return value or var type
	var isMethod 			: Bool; // true if method, false if field
	var isInherited			: Bool; // true if field (var or method) is inherited
	var isOverride			: Bool; // true if method is an override
	var inheritance			: Inheritance;
	var isStatic 			: Bool;
	var isDynamic			: Bool;
	var rights				: Html; // "" or "(get, set)"
};


typedef EnumCtx = {
	>Ctx,
	/**	Only uses the [platforms], [name], [args] and [docs] fields of the FieldCtx **/
	var constructorInfo		: Array<FieldCtx>; // only
};

/**
	A parent TypedefCtx does not contain valid [alias] or [fields] values. Each member of the [contexts] array will either have [alias] or [fields] set
**/
typedef TypedefCtx = {
	>Ctx,
	/** Html content for aliases, or null if child is a typedef **/
	var alias				: Html;
	/** Uses only [name] and [returns] **/
	var fields				: Array<FieldCtx>;
};
