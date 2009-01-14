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

class TypedefHandler extends TypeHandler<TypedefCtx> {

	var current : Typedef;

	public function new() {
		super();
	}

	public function pass1(t : Typedef) : TypedefCtx {
		current = t;
		var ctx = newTypedefCtx(t);

		if( t.platforms.length == 0 ) {
			processTypedefType(ctx, t.type, t.platforms, t.platforms);
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
				processTypedefType(ctx, td, t.platforms, support);
			}
		}

		var aliases = 0;
		var typedefs = 0;
		for(i in ctx.contexts) {
			switch(i.type) {
			case "alias":
				aliases++;
			case "typedef":
				typedefs++;
			default:
				throw "error";
			}
		}
		if(aliases >= typedefs)
			ctx.type = "alias";

		// may have changed from "typedef" to "alias"
		resetMetaKeywords(ctx);

		return ctx;
	}

	function processTypedefType(origContext : TypedefCtx, t : CType, all : List<String>, platforms : List<String>) {
		var me = this;
		var context = newTypedefCtx(current);

		switch(t) {
		case CAnonymous(fields): // fields == list<{t:CType, name:String}>
			for( f in fields ) {
				var field = {
					name : f.name,
					returns : doStringBlock(
						function() {
							me.processType(f.t);
						}
					)
				};
				context.fields.push(untyped field);
			}
			context.type = "typedef";
		default:
			context.alias = doStringBlock(
				function() {
					me.processType(t);
				}
			);
			context.type = "alias";
		}
		if( all.length == platforms.length || platforms.length == ChxDocMain.platforms.length) {
			context.isAllPlatforms = true;
			context.platforms = cloneList(ChxDocMain.platforms);
		} else {
			context.isAllPlatforms = false;
			context.platforms = cloneList(platforms);
		}

		if(context.type == "typedef") {
			context.fields.sort(TypeHandler.ctxFieldSorter);
		}

		context.parent = origContext;
		origContext.contexts.push(context);
	}


	/**
		<pre>Types -> create documentation</pre>
	**/
	public function pass2(pkg : PackageContext, ctx : TypedefCtx) {
		if(ctx.originalDoc != null)
			ctx.docs = DocProcessor.process(pkg, ctx, ctx.originalDoc);
		else
			ctx.docs = null;
	}

	/**
		<pre>Types	-> Resolve all super classes, inheritance, subclasses</pre>
	**/
	public function pass3(pkg : PackageContext, context : TypedefCtx) {
	}

	public static function write(context : TypedefCtx) : String  {
		var t = new mtwin.templo.Loader("typedef.mtt");
		try {
			var rv = t.execute(context);
			return rv;
		} catch(e : Dynamic) {
			trace("ERROR generating doc for " + context.path + ". Check typedef.mtt");
			return neko.Lib.rethrow(e);
		}
	}

	public function newTypedefCtx(t : Typedef) : TypedefCtx {
		var c = createCommon(t, "typedef");
		c.setField("alias",null);
		c.setField("fields", new Array<FieldCtx>());
		return cast c;
	}


}