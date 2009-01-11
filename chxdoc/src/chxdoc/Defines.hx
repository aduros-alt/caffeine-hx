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

import chxdoc.Types;


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
	var classes				: Array<ClassCtx>;
	var enums				: Array<EnumCtx>;
	var typedefs			: Array<TypedefCtx>;
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

typedef FileInfo = {
	// example 1) public a.b.C 2) private a.b.D defined in a.b.C 3)flash9.MyClass
	// TypeInfos.path: 1) a.b.C 2) a.b._C.D
	var name			: String; // Short name.  1) C 2) D 3) MyClass
	var nameDots		: String; // Dotted filename 1) a.b.C 2) a.b._C.D 3) flash.MyClass
	var packageDots		: String; // Dotted package name. 1) a.b 2) a.b._C 3) flash
	var subdir			: String; // Relative subdir for html 1) a/b/ 2) a/b/_C/ 3) flash9
}