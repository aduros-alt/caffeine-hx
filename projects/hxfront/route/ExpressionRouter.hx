package hxfront.route;

import hxfront.route.ExpressionAnalyzer;

class ExpressionRouter {
	var queryseparator : String;
	public function new(queryseparator = ";") {
		this.queryseparator = queryseparator;
		map = new Hash();
		expressions = new Array();
	}

	var map : Hash<RouteInfo>;
	var expressions : Array<String>;
	public function add(expression : String, cls : Class<Dynamic>, action : String) {
		expressions.push(expression);
		map.set(expression, {
			grammar : null,
			cls     : cls,
			action  : action
		});
	}

	public static function parseQueryParams(query : String, queryseparator : String) {
		var p = query.split(queryseparator);
		var q = {};
		for(part in p) {
			var pair = part.split('=');
			Reflect.setField(q, StringTools.urlDecode(pair[0]), StringTools.urlDecode(pair[1]));
		}
		return q;
	}

	public static function baseParts(path : String, queryseparator : String) {
		var p = path.split('#');
		var fragment = null;
		if(p.length > 1) {
			fragment = StringTools.urlDecode(p.pop());
			path = p.join('');
		}
		p = path.split('?');
		var query = null;
		if(p.length > 1) {
			query = p.pop();
			path = p.join('');
		}
		return {
			path     : StringTools.urlDecode(path),
			cls      : null,
			action   : null,
			method   : null,
			qparams  : query == null ? {} : parseQueryParams(query, queryseparator),
			params   : null,
			fragment : fragment
		}
	}

	public function resolve(query : ActionRoute) : String {
		for(expression in expressions) {
			var route = map.get(expression);
			if(route.cls != query.cls || route.action != query.action) continue;
			if(route.grammar == null)
				route.grammar = ExpressionAnalyzer.buildGrammar(expression);
			var url = '';
			var ok = true;
			for(g in route.grammar) {
				switch(g) {
					case Param(name), ParamRest(name), ParamIncludes(name, _):
						if(!Reflect.hasField(query.qparams, name)) {
							ok = false;
							break;
						}
						url += Reflect.field(query.qparams, name);
						Reflect.deleteField(query.qparams, name);
					case Scalar(value):
						url += value;
					case Dot:
						url += '.';
					case Slash:
						url += '/';
				}
			}
			if(!ok) continue;

			var fields = Reflect.fields(query.qparams);
			var qstring = '';
			for(i in 0...fields.length) {
				var field = fields[i];
				if(i == 0) {
					qstring += '?';
				} else {
					qstring += queryseparator;
				}
				qstring += field +'='+Reflect.field(query.qparams, field);
			}
			return url + qstring + (query.fragment == null ? '' : '#' + query.fragment);
		}
		return null;
	}

#if php
	static var blacklist = ['list'];
	static function cleanReflectName(n : String) {
		if(Lambda.has(blacklist, n.toLowerCase()))
			return 'h'+n;
		else
			return n;
	}
#else
	static inline function cleanReflectName(n : String) {
		return n;
	}
#end

	public function find(path : String) : Iterator<ActionRoute> {
		var base = baseParts(path, queryseparator);
		var index = 0;
		var me = this;
		var it : { last : ActionRoute, fetch : Void -> Void, hasNext : Void -> Bool, next : Void -> ActionRoute } = null;
		it = {
			last : null,
			fetch : function() {
				while(index < me.expressions.length) {
					var expression = me.expressions[index];
					index++;
					var route = me.map.get(expression);
					if(route.grammar == null)
						route.grammar = ExpressionAnalyzer.buildGrammar(expression);
					var params = ExpressionAnalyzer.matchGrammar(route.grammar, base.path);
					if(params == null) continue;
					base.action = route.action;
					base.method = cleanReflectName(route.action);
					base.cls = route.cls;
					base.params = params;
					it.last = base;
					return;
				}
				it.last = null;
			},
			hasNext : function() {
				if(it.last == null) it.fetch();
				return it.last != null;
			},
			next : function() {
				if(it.last == null) it.fetch();
				if(it.last == null) return null;
				var r = it.last;
				it.last = null;
				return r;
			}
		};
		return cast it;
	}
}

typedef RouteInfo = {
	grammar : Array<ExpressionGrammar>,
	cls : Class<Dynamic>,
	action : String
}