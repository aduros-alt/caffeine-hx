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

class ClassHandler extends TypeHandler<ClassCtx> {
	public function new() {
		super();
	}

	public function pass1(c : Classdef) : ClassCtx {
// 		#if BUILD_DEBUG
// 		var rv = newClassCtx(c);
// 		if(rv.path == "flash9.display.MovieClip")
// 			trace(rv);
// 		return rv;
// 		#else
		return newClassCtx(c);
// 		#end
	}


	public function pass2(pkg : PackageContext, ctx : ClassCtx) {
		ctx.docs = DocProcessor.process(pkg, ctx, ctx.originalDoc);

		if(ctx.constructor != null)
			ctx.constructor.docs = DocProcessor.process(pkg, ctx.constructor, ctx.constructor.originalDoc);
		var me = this;
		forAllFields(ctx,
			function(f:FieldCtx) {
				f.docs = DocProcessor.process(pkg, f, f.originalDoc);
			}
		);
	}

	//Types	-> Resolve all super classes, inheritance, subclasses
	public function pass3(pkg : PackageContext, ctx : ClassCtx) {
		var sc = ctx.scPathParams;
		var first = true;
		while(sc != null) {
			var s : Ctx = ChxDocMain.findType(sc.path);
			var source : ClassCtx = cast s;
			if(first) {
				first = false;
				addSubclass(source, ctx);
			}
			for(i in source.vars)
				makeInheritedVar(ctx, source, i);
			for(i in source.methods)
				makeInheritedMethod(ctx, source, i);
			sc = source.scPathParams;
		}

		// private vars and methods do not need to be removed
		// here, since they are ignored in pass 1
		var a = [ctx.vars, ctx.staticVars, ctx.methods, ctx.staticMethods];
		for(e in a)
			e.sort(TypeHandler.ctxFieldSorter);

	}


	/**
		@return FieldCtx or null
	**/
	static function getMethod(ctx: ClassCtx, name : String) : FieldCtx {
		for(i in ctx.methods)
			if(i.name == name)
				return i;
		return null;
	}

	function addSubclass(superClass : ClassCtx, subClass : ClassCtx) : Void {
		var link = makeBaseRelPath(superClass) +
			subClass.subdir +
			subClass.name +
			ChxDocMain.config.htmlFileExtension;
		superClass.subclasses.push({
			text : subClass.nameDots,
			href : link,
			css : "subclass",
		});
	}

	/**
		Creates and returns a new field based on an existing super class field.
		@param ownerCtx The super class Ctx which owns [field]
		@param field The method or var being inherited or overridden
	**/
	function createInheritedField(ownerCtx:ClassCtx, field : FieldCtx) : FieldCtx {
		var f = createField(
			ownerCtx,
			field.name,
			field.isPrivate,
			field.platforms,
			field.originalDoc);

		f.params = field.params;
		f.docs = field.docs;

		f.args = field.args;
		f.returns = field.returns;
		f.isMethod = field.isMethod;
		f.isInherited = true;
		f.isOverride = false;
		f.inheritance = {
			owner : ownerCtx,
			link :
				{
					text: null,
					href: null,
					css : null,
				},
		};
		f.isStatic = field.isStatic;
		f.isDynamic = field.isDynamic;
		f.rights = field.rights;

		return f;
	}

	/**
		Recreates the link for field inheritance.
		@param ctx The class that [field] belongs to
		@param field A field with [inheritance.owner] set
		@throws String if inheritance or inheritance.owner is null
	**/
	function makeInheritedFieldLink(ctx : ClassCtx, field : FieldCtx) : Void {
		if(field.inheritance == null || field.inheritance.owner == null)
			throw "Error creating inheritance field link for " + field;

		field.inheritance.link = Utils.makeLink(
			makeBaseRelPath(ctx) +
				field.inheritance.owner.subdir +
				field.inheritance.owner.name +
				ChxDocMain.config.htmlFileExtension,
			field.inheritance.owner.nameDots,
			"inherited"
		);
	}

	/**
		Creates an inherited var field and attaches it to the supplied ClassCtx.
		@param ctx The class receiving a new field.
		@param srcCtx The super class that owns [field]
		@param field The field to be copied
	**/
	function makeInheritedVar(ctx : ClassCtx, srcCtx:ClassCtx, field : FieldCtx) {
		var f : FieldCtx =
			if(!field.isInherited)
				createInheritedField(srcCtx, field)
			else
				createInheritedField(field.inheritance.owner, field);

		makeInheritedFieldLink(ctx, f);
		ctx.vars.push(f);
	}

	function makeInheritedMethod(ctx : ClassCtx, srcCtx:ClassCtx, field : FieldCtx) {
		var cur = getMethod(ctx, field.name);
		if(cur != null && (cur.isInherited || cur.isOverride))
			return;

		var f = createInheritedField(srcCtx, field);
		if(cur != null) {
			f.isInherited = false;
			f.isOverride = true;
		}
		if(!field.isInherited) {
			f.inheritance.owner = srcCtx;
		}
		else {
			var f2 = getMethod(srcCtx, field.name);
			while(!f2.isInherited)
				f2 = getMethod(f2.inheritance.owner, field.name);
			f.inheritance.owner = f2.inheritance.owner;
		}

		makeInheritedFieldLink(ctx, f);
		ctx.methods.push(f);
	}

	function newClassCtx(c : Classdef) : ClassCtx {
		var ctx : ClassCtx = null;
		var me = this;

		if( c.isInterface )
			ctx = cast createCommon(c, "interface");
		else
			ctx = cast createCommon(c, "class");

		Reflect.setField(ctx, "scPathParams", c.superClass);
		Reflect.setField(ctx, "superClassHtml", null);
		Reflect.setField(ctx, "superClasses", new Array<ClassCtx>());
		Reflect.setField(ctx, "interfacesHtml", new Array<Html>());
		Reflect.setField(ctx, "isDynamic", (c.tdynamic != null));
		Reflect.setField(ctx, "constructor", null);
		Reflect.setField(ctx, "vars", new Array<FieldCtx>());
		Reflect.setField(ctx, "staticVars", new Array<FieldCtx>());
		Reflect.setField(ctx, "methods", new Array<FieldCtx>());
		Reflect.setField(ctx, "staticMethods", new Array<FieldCtx>());
		Reflect.setField(ctx, "subclasses", new Array<Link>());

		if( c.superClass != null ) {
			ctx.superClassHtml = doStringBlock(
				function() {
					me.processPath(c.superClass.path, c.superClass.params);
				}
			);
		}

		if(!c.interfaces.isEmpty()) {
			ctx.interfacesHtml = new Array();
			for(i in c.interfaces) {
				ctx.interfacesHtml.push(
					doStringBlock(
						function() {
							me.processPath(i.path, i.params);
						}
					)
				);
			}
		}

		if(c.tdynamic != null) {
			ctx.interfacesHtml.push(
				"<A HREF=\"http://haxe.org/ref/dynamic#Implementing Dynamic\" TARGET=\"#new\">Dynamic</A>"
			);
		}

		for( f in c.fields ) {
			var field = newClassFieldCtx(ctx, f, false);
			if(field != null) {
				if(field.name == "new" && !c.isInterface) {
					ctx.constructor = field;
				} else {
					if(field.isMethod)
						ctx.methods.push(field);
					else
						ctx.vars.push(field);
				}
			}
		}

		for( f in c.statics ) {
			var field = newClassFieldCtx(ctx, f, true);
			if(field != null) {
				if(field.isMethod)
					ctx.staticMethods.push(field);
				else
					ctx.staticVars.push(field);
			}
		}

		return ctx;
	}


	function newClassFieldCtx(c : ClassCtx, f : ClassField, isStatic : Bool) : FieldCtx
	{
		var me = this;
		var ctx : FieldCtx = createField(c, f.name, !f.isPublic, f.platforms, f.doc);
		ctx.isStatic = isStatic;

		var oldParams = TypeHandler.typeParams;
		if( f.params != null )
			TypeHandler.typeParams = TypeHandler.typeParams.concat(Utils.prefix(f.params,f.name));

		switch( f.type ) {
		case CFunction(args,ret):
			//trace("Examining method " + f.name + " in " + current.nameDots + " f.get: " + Std.string(f.get));
			if( f.get == RNormal && (f.set == RNormal || f.set == RF9Dynamic) ) {
				ctx.isMethod = true;

				if( f.set == RF9Dynamic )
					ctx.isDynamic = true;

				if( f.params != null )
					ctx.params = "<"+f.params.join(", ")+">";

				ctx.args = doStringBlock( function() {
					me.display(args,function(a) {
						if( a.opt )
							me.write("?");
						if( a.name != null && a.name != "" ) {
							me.write(a.name);
							me.write(" : ");
						}
						me.processType(a.t);
					},", ");
				});

				ctx.returns = doStringBlock(
					function() {
						me.processType(ret);
					}
				);
			}
		default:
		}
		if(!ctx.isMethod) {
			if( f.get != RNormal || f.set != RNormal )
				ctx.rights = ("("+Utils.rightsStr(f.get)+","+Utils.rightsStr(f.set)+")");

			ctx.returns = doStringBlock(
				function() {
					me.processType(f.type);
				}
			);
		}

		if( !f.isPublic ) {
			if(ctx.isMethod && !ChxDocMain.config.showPrivateMethods)
				return null;
			if(!ctx.isMethod && !ChxDocMain.config.showPrivateVars)
				return null;
		}



		if( f.params != null )
			TypeHandler.typeParams = oldParams;
		return ctx;
	}

	/**
		Applies a function to all fields (vars and methods both static and member) in a class context.
		@param ctx A class context
		@param f Function taking a FieldCtx returning Void
	**/
	function forAllFields(ctx : ClassCtx, f : FieldCtx->Void) {
		var a = [ctx.vars, ctx.staticVars, ctx.methods, ctx.staticMethods];
		for(e in a)
			for(i in e)
				f(i);
	}
}
