package hxfront.engines;

#if neko
import neko.Lib;
import neko.Utf8;
import neko.io.Path;
#elseif php
import php.Lib;
import php.Utf8;
import php.io.Path;
#end
import hxfront.Controller;
import templo.Loader;

class TemploEngine implements RenderingEngine<Dynamic> {
	public var controller : Controller;
	public var context : Dynamic;
	public function new(dirtemplates : String, dircompiled : String, macros : String, allowcompile : Bool, context : Dynamic) {
		Loader.MACROS    = macros;
		Loader.BASE_DIR  = dirtemplates;
		Loader.TMP_DIR   = dircompiled;
		Loader.OPTIMIZED = !allowcompile;
		this.context     = context == null ? {} : context;
	}

	public function render(viewname : String, v : Dynamic, params : Dynamic) {
		var template = viewname.toLowerCase().split('.').join('/')+".html";

		if(v != null) {
			for(field in Reflect.fields(v))
				Reflect.setField(context, field, Reflect.field(v, field));
		}
		context._params = params;
		context._controller = controller;
		var template = new Loader(template);
		try {
			Lib.print(template.execute(context));
		} catch(e : Dynamic) {
			var err = "Error in template\n<br>";
			err += StringTools.replace(haxe.Stack.toString(haxe.Stack.exceptionStack()), "\n", "\n<br>");
#if neko
			neko.Lib.rethrow(err);
#else
			throw err;
#end
		}
	}
}
/*
class TemplateHelper {
	public function new();

	public function currency(v : Null<Float>) {
		var thoundsep = '.';
		var decsep = ',';
		if(v == null) return '-';
		var s = Std.string(v);
		var p = s.split('.');
		s = p[0];
		var r = '';
		while(s.length > 3) {
			var sub = s.substr(-3);
			r = thoundsep + sub + r;
			s = s.substr(0, -3);
		}
		r = s + r;
		if(p.length > 1) {
			if(p[1].length > 2)
				r += decsep + p[1].substr(0, 2);
			else if(p[1].length == 2)
				r += decsep + p[1];
			else
				r += decsep + p[1] + '0';
		} else {
			r += decsep+'00';
		}
		return r;
	}

	public function shortDate(v : Date) {
		if(v == null) return '-';
		return DateTools.format(v, '%Y-%m-%d');
	}

	public function addArg(action : String, name : String, value : String) {
		if(value == '' || value == null) return action;
		value = StringTools.urlEncode(value);
		name = StringTools.urlEncode(name);
		if(action.indexOf('&') >= 0 || action.indexOf('?') >= 0) {
			return action + '&' + name + '=' + value;
		} else
			return action + '?' + name + '=' + value;
	}

	public function utf8Encode(s : String) {
		return Utf8.encode(s);
	}

	public function extension(s : String) {
		return Path.extension(s);
	}
}
*/