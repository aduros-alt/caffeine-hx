package hxfront.route;

class ExpressionAnalyzer {
	static var rvar   = ~/^:([a-zA-Z][a-zA-Z0-9]*)/;
	static var rconst = ~/^([^\/.]+)+/;
	static var rsep   = ~/^([\/.])/;
	static var rrule  = ~/^{([^}]*)}/;

	static var rsymbolrange = ~/^([\/.])(\d+)-(\d+)/;
	static var rsymbolleast = ~/^([\/.])(\d+)\+/;
	static var rsymbolrep   = ~/^([\/.])(\d+)/;
	static var rsymbolone   = ~/^([\/.])/;

	public static function buildGrammar(expression : String) {
		var grammar = [];
		var rules = [rvar, rconst, rsep];
		var nrules = rules.length;
		while(expression.length > 0) {
			for(i in 0...nrules) {
				var rule = rules[i];
				if(!rule.match(expression)) {
					if(i == nrules-1 && expression.length > 0)
						throw "Error in expression near: '" + expression + "'";
					continue;
				}
				switch(i) {
					case 0:
						var param = rule.matched(1);
						if(rrule.match(rule.matchedRight())) {
							var pattern = rrule.matched(1);
							rule = rrule;
							if(pattern == '') {
								grammar.push(Param(param));
							} else if(pattern == '*') {
								grammar.push(ParamRest(param));
							} else {
								var srules = [rsymbolrange, rsymbolleast, rsymbolrep, rsymbolone];
								var nsrules = srules.length;
								var symbols = [];
								while(pattern.length > 0) {
									for(j in 0...nsrules) {
										var srule = srules[j];
										if(!srule.match(pattern)) {
											if(i == nsrules-1 && pattern.length > 0)
												throw "Error in symbol pattern for param '"+param+"' near: '" + pattern + "'";
											continue;
										}
										var s = srule.matched(1);
										var separator = s == '.' ? SDot : SSlash;
										switch(j) {
											case 0:
												symbols.push({
													separator : separator,
													min       : Std.parseInt(srule.matched(2)),
													max       : Std.parseInt(srule.matched(3))
												});
											case 1:
												symbols.push({
													separator : separator,
													min       : Std.parseInt(srule.matched(2)),
													max       : null
												});
											case 2:
												var r = Std.parseInt(srule.matched(2));
												symbols.push({
													separator : separator,
													min       : r,
													max       : r
												});
											case 3:
												symbols.push({
													separator : separator,
													min       : 1,
													max       : 1
												});
										}
										pattern = srule.matchedRight();
										break;
									}

								}
								grammar.push(ParamIncludes(param, symbols));
							}
						} else
							grammar.push(Param(param));
					case 1:
						grammar.push(Scalar(rule.matched(1)));
					case 2:
						grammar.push(rule.matched(1) == '/' ? Slash : Dot);
				}
				expression = rule.matchedRight();
				break;
			}
		}
		return grammar;
	}

	public static function matchGrammar(grammars : Array<ExpressionGrammar>, path : String) : Dynamic {
		var captures = [];
		var pattern = '^';
		for(i in 0...grammars.length) {
			switch(grammars[i]) {
				case Param(name):
					pattern += '([^/.]+)';
					captures.push(name);
				case ParamRest(name):
					pattern += '(.+)';
					captures.push(name);
				case ParamIncludes(name, symbols):
					pattern += '(';
					for(symbol in symbols) {
						switch(symbol.separator) {
							case SDot:
								pattern += '(?:[^.]+\\.)';
							case SSlash:
								pattern += '(?:[^/]+/)';
						}
						if(symbol.min == 0 && symbol.max == 1)
							pattern += '?';
						else if(symbol.min == symbol.max && symbol.max > 1)
							pattern += '{' + symbol.max + '}';
						else if(symbol.max  > 1)
							pattern += '{'+symbol.min+','+symbol.max+'}';
					}
					pattern += '[^./]+)';
					captures.push(name);
				case Scalar(value):
					// TODO: escape special chars?
					pattern += value;
				case Dot:
					pattern += '\\.';
				case Slash:
					pattern += '/';
			}
		}
		pattern += '$';
		var re = new EReg(pattern, '');
		if(!re.match(path)) return null;
		var params : Dynamic = {};
		for(i in 0...captures.length) {
			var name = captures[i];
			Reflect.setField(params, name, re.matched(i+1));
		}
		return params;
	}

/*
* :name
* :name.:format
* :filename{.}       <- must include a dot
* :filename{.?}      <- can include a dot
* :filename{.+}      <- can include a dot or more
* :filename{.*}      <- can include zero dots or more
* :year/:month/:day
* :date{/0-2}      <- can include up to two slashes
*/
}

enum ExpressionSeparator {
	SSlash;
	SDot;
}

enum ExpressionGrammar {
	Scalar(value : String);
	Slash;
	Dot;
	Param(name : String);
	ParamRest(name : String);
	ParamIncludes(name : String, separators : Array<{
		separator : ExpressionSeparator,
		min : Int,
		max : Null<Int>
	}>);
}

typedef RouteMethod = {
	cls : Class<Dynamic>,
	action : String
}