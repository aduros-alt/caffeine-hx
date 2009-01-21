package hxfront.route;

typedef ActionRoute = {
	path     : String,
	cls      : Class<Dynamic>,
	action   : String,
	method   : String,
	qparams  : Dynamic,
	params   : Dynamic,
	fragment : String
}