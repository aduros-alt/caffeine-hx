package hxfront;

class Module implements haxe.rtti.Infos {
	public var params(default, null) : Dynamic;
	public var controller(default, null) : Controller;
	public function new(controller : Controller, params : Dynamic) {
		this.controller = controller;
		this.params     = params;
	}
}