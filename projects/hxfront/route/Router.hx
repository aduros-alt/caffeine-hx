package hxfront.route;

import hxfront.Module;

import hxfront.route.ExpressionRouter;
import hxfront.route.handlers.TypeHandler;
import hxfront.route.handlers.MultipleHandler;
import haxe.rtti.CType;
import hxfront.rtti.RttiUtil;
import hxfront.utils.ObjectTools;

import hxfront.route.handlers.StringHandler;
import hxfront.route.handlers.IntHandler;
import hxfront.route.handlers.FloatHandler;
import hxfront.route.handlers.BoolHandler;
import hxfront.route.handlers.ArrayHandler;
import hxfront.route.handlers.ListHandler;

class Router {
	var router : ExpressionRouter;
	var handler : MultipleHandler;
	var expHandlers : Hash<MultipleHandler>;
	var controllers : Hash<Module>;
	var queryseparator : String;
	public function new(queryseparator = "&") {
		this.queryseparator = queryseparator;
		router = new ExpressionRouter(queryseparator);
		handler = new MultipleHandler();
		expHandlers = new Hash();
		controllers = new Hash();
		registerBaseHandlers();
	}

	function registerBaseHandlers() {
		var bnames = ['String', 'Int', 'Float', 'Bool'];
		var base   = [StringHandler, IntHandler, FloatHandler, BoolHandler];
		var cnames = ['Array', 'List'];
		var comp   = [ArrayHandler, ListHandler];

		var me = this;

		for(i in 0...base.length) {
			var bname = bnames[i];
			var nbname = 'Null<'+bname+'>';
			var b = base[i];
			handler.registerType('Null<'+bname+'>', b, [true]);
			handler.registerType(bname, b, [false]);
			for(j in 0...comp.length) {
				var cname = cnames[j];
				var c = comp[j];
				handler.registerInstantiator(cname+'<'+bname+'>', function() {
					return Type.createInstance(c, [false, me.handler.getHandler(bname)]);
				});
				handler.registerInstantiator(cname+'<'+nbname+'>', function() {
					return Type.createInstance(c, [false, me.handler.getHandler(nbname)]);
				});
				handler.registerInstantiator('Null<'+cname+'<'+bname+'>>', function() {
					return Type.createInstance(c, [true, me.handler.getHandler(bname)]);
				});
				handler.registerInstantiator('Null<'+cname+'<'+nbname+'>>', function() {
					return Type.createInstance(c, [true, me.handler.getHandler(nbname)]);
				});
			}
		}
	}

	public function setGlobalTypeHandler(type : String, cls : Class<Dynamic>, ?args : Array<Dynamic>) {
		handler.registerType(type, cls, args);
	}

	public function setGlobalHandler(type : String, handler : TypeHandler<Dynamic>) {
		this.handler.register(type, handler);
	}

	function getTypeHandlerForExpression(expression : String) {
		var h = expHandlers.get(expression);
		if(h == null) {
			h = new MultipleHandler();
			expHandlers.set(expression, h);
		}
		return h;
	}

	public function setTypeHandler(expression : String, type : String, cls : Class<Dynamic>, ?args : Array<Dynamic>) {
		getTypeHandlerForExpression(expression).registerType(type, cls, args);
	}

	public function setHandlerInstantiator(expression : String, type : String, f : Void->TypeHandler<Dynamic>) {
		getTypeHandlerForExpression(expression).registerInstantiator(type, f);
	}

	public function setHandler(expression : String, type : String, handler : TypeHandler<Dynamic>) {
		getTypeHandlerForExpression(expression).register(type, handler);
	}

	public function add(expression : String, cls : Class<Dynamic>, action : String) {
		router.add(expression, cls, action);
		return expression;
	}

	public function transformUrl(actionpath : String) {
		var route = ExpressionRouter.baseParts(actionpath, queryseparator);
		var p = route.path.split('.');
		if(p.length < 2) throw "Invalid action path: " + actionpath;
		route.action = p.pop();
		route.cls = Type.resolveClass(p.join('.'));
		var u = router.resolve(route);
		if(u == null)
			throw "Invalid action path: " + actionpath;
		return u;
	}

	public function dispatch(path : String, params : Dynamic) : Dynamic {
		var it = router.find(path);
		while(it.hasNext()) {
			var route : ActionInfo = cast it.next();
			route.params = ObjectTools.merge([route.params, params]);
			var fields = RttiUtil.unifyFields(RttiUtil.getClassDef(route.cls));
			var field = fields.get(route.action);
			var clsname = Type.getClassName(route.cls);

			if(field == null) throw "Invalid action '"+route.action+"' for class '"+clsname+"'";
			if(!field.isPublic) throw "Actions must be public methods: " + clsname + "." + route.action;

			switch(field.type) {
				case CFunction(args, _):
					route.values = new Array<Dynamic>();
					var ok = true;
					for(arg in args) {
						var type = RttiUtil.typeName(arg.t, arg.opt);
						var v = Reflect.field(route.qparams, arg.name);
						if(Reflect.hasField(route.params, arg.name))
							v = Reflect.field(route.params, arg.name);
						var h = expHandlers.get(route.path);
						if(h == null || !h.canHandleType(type))
							h = handler;
						if(!h.canHandleType(type)) {
							throw "Unable to handle type " + type;
						}
						if(!h.handle(InputTools.ofVar(v))) {
							ok = false;
							break; // Invalid parameter
						}
						route.values.push(h.handled);
					}
					if(ok)
						return route;
				default:
					throw "Invalid action type (must be an instance method): " + clsname + "." + route.action;
			}

		}
		return null;
	}
}

typedef ActionInfo = {>ActionRoute,
	values : Array<Dynamic>
}

class TypeBroker {

}

typedef HandlerInfo = {
	inst : TypeHandler<Dynamic>,
	cls  : Class<Dynamic>
}