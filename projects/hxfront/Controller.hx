package hxfront;

#if neko
import neko.Web;
import neko.Sys;
#elseif php
import php.Web;
import php.Sys;
#end

import hxfront.route.Router;
import hxfront.engines.RenderingEngine;
import hxfront.rtti.Attributes;

class Controller {
	public var router : Router;
	public var baseUrl : String;
	public var loginAction: String;
	public var host : String;
	public var defaultMimeType(default, null) : String;

	public function new(baseurl : String, ?loginaction : String) {
		this.baseUrl = baseurl;
		this.loginAction = loginaction;
		router = new Router();
		engines = new Hash();
		engargs = new Hash();
		host = null; // TODO: FIXME, use Web to guess the host
	}

	public function isPost() {
		return WebRequest.isPost();
	}

	public dynamic function checkCredentials(requirement : String) : Bool {
		return false;
	}

	var engines : Hash<Class<Dynamic>>;
	var engargs : Hash<Array<Dynamic>>;
	public function registerEngine(mimetype : String, engine : Class<Dynamic>, ?args : Array<Dynamic>, ?isdefault = false) {
		if(isdefault) defaultMimeType = mimetype;
		if(args == null) args = [];
		engines.set(mimetype, engine);
		engargs.set(mimetype, args);
	}

	function getEngineInstance(mimetype : String) : RenderingEngine<Dynamic> {
		var cls = engines.get(mimetype);
		if(cls == null) throw "No engine is present for the mimetype: " + mimetype;
		var args = engargs.get(mimetype);
		var inst : RenderingEngine<Dynamic> = Type.createInstance(cls, args);
		inst.controller = this;
		return inst;
	}

	public function execute(?params : Dynamic) {
		var path = WebRequest.getRequestURI().substr(baseUrl.length);

		var ctx : Dynamic;
		try {
			var route = router.dispatch(path, WebRequest.getParams()); //WebRequest.getPostParams());
			if(route == null) throw RouterError.NotFound;

			// collect method params
			if(params == null) params = {};
			params.view     = Type.getClassName(route.cls)+'.'+route.action;
			params.mimetype = defaultMimeType;
			params.auth     = null;
			Attributes.ofClass(route.cls, params);
			Attributes.ofField(route.cls, route.action, params);
			if(params.auth != null && checkCredentials != null && !checkCredentials(params.auth)) throw Unauthorized;
			// execute
			var inst = Type.createInstance(route.cls, [this, params]);
			ctx = Reflect.callMethod(inst, Reflect.field(inst, route.method), route.values);
			getEngineInstance(params.mimetype).render(params.view, ctx, params);
		} catch(e : RouterError) {
			var error, code;
			switch(e) {
				case NotFound:
					error = "Error 404: Page Not Found";
					code  = 404;
					Web.setReturnCode(code);
				case Unauthorized:
					if(loginAction != null) {
						Web.redirect(host + actionToUrl(loginAction));
						Sys.exit(0);
					}
					error = "Error 401: Unauthorized";
					code  = 401;
					Web.setReturnCode(code);
				case InternalServerError(e):
					error = "Error 500: Internal Server Error\n"+Std.string(e);
					code  = 500;
					Web.setReturnCode(code);
			}
			getEngineInstance("text/html").render("error", { title : error, path : path, error : error, code : code }, params);
			return;
		} catch(e : Dynamic) {
			var code = 500;
			Web.setReturnCode(code);
			var error = "Error 500: Internal Server Error";
			getEngineInstance("text/html").render("error", { title : error, path : path, error : e, code : code }, params);
		}
	}

	public function redirectToAction(actionpath : String) {
		Web.redirect(actionToUrl(actionpath));
	}

	public function actionToUrl(actionpath : String, relative = true) {
		if(relative)
			return baseUrl + router.transformUrl(actionpath);
		else
			return host + baseUrl + router.transformUrl(actionpath);
	}

	public function relativeUrl(url : String) {
		return baseUrl + url;
	}
}

enum RouterError {
	NotFound;
	Unauthorized;
	InternalServerError(e : Dynamic);
}