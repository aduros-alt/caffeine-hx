package chxdoc;

import chxdoc.Types;

class CtxApi {
	/**
		Returns the parent Ctx, ascending to the very top if [top] is [true]
		@param ctx Any Ctx
		@param top Return root anscestor if true
		@returns Parent or null
	**/
	public static function getParent(ctx : Ctx, top : Bool = false) {
		if(!top)
			return ctx.parent;
		var c = ctx;
		if(ctx.type == "field") {
			var f : FieldCtx = cast ctx;
			if(f.isInherited || f.isOverride) {
				c = f.inheritance.owner;
			}
		}
		while(c.parent != null)
			c = c.parent;
		return c;
	}

	/**
		Makes an Anchor tag for a type
		@param ctx Any Ctx
		@return Empty string or "#..."
	**/
	public static function makeAnchor(ctx : Ctx) : String {
		if(ctx == null)
			return "";
		switch(ctx.type) {
		case "class", "alias", "typedef", "enum":
			return "#top";
		case "field":
			var f : FieldCtx = cast ctx;
			var rv = "#" + ctx.name;
			if(f.isMethod)
				rv += "()";
			return rv;
		case "enumfield":
			return "#" + ctx.name + "()";
		}
		trace("Error in makeAnchor for type " + ctx.type + " Please report.");
		return "";
	}
}