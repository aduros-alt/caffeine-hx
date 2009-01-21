package hxfront.engines;

import hxfront.Controller;

interface RenderingEngine<T> {
	var controller : Controller;
	function render(viewname : String, value : T, params : Dynamic) : Void;
}