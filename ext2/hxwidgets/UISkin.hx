package hxwidgets;

import haxe.xml.Fast;
import flash.net.URLRequest;
import flash.net.URLLoader;
import flash.net.URLLoaderDataFormat;

class UISkin {

	var assetXmlUrl : String;
	var statusCallback : Bool->String->Void;
	var assets : LibraryLoader;
	var loader : flash.net.URLLoader;
	var fast : haxe.xml.Fast;
	public var loaded(default,null) : Bool;

	public function new(xmlUrl: String,loadedStatus: Bool->String->Void) {
		assetXmlUrl = xmlUrl;
		statusCallback = loadedStatus;
		loaded = false;
	}

	/////////////////////////////////////////////
	//        XML File loading stage           //
	/////////////////////////////////////////////
	public function load() {
		var urlReq = new URLRequest(assetXmlUrl);
		loader = new URLLoader(urlReq);
		loader.dataFormat = URLLoaderDataFormat.TEXT;
		loader.addEventListener(flash.events.Event.COMPLETE, onXmlFileLoaded);
		loader.addEventListener(flash.events.IOErrorEvent.IO_ERROR, onXmlError);
	}

	function onXmlFileLoaded(e) {
		parseXmlFile(loader.data);
	}

	function onXmlError(e) {
		statusCallback(false,"UISkin xml file failed to load");
	}

	function parseXmlFile(s:String) {
		fast = new haxe.xml.Fast(Xml.parse(s).firstElement());
		if(!fast.has.assetSwf) {
			statusCallback(false,"Skin xml file does not specify assetSwf");
			return;
		}
		assets = new LibraryLoader(fast.att.assetSwf);
		assets.addLoadedHandler(assetsLoaded);
		assets.addIoErrorHandler(assetsFailed);
		assets.load();
	}

	/////////////////////////////////////////////
	//        Asset SWF loading stage          //
	/////////////////////////////////////////////
	function assetsFailed(e:flash.events.IOErrorEvent) {
		statusCallback(false,"Unable to load asset pack " + fast.att.assetSwf + ". "+e.text);
	}

	function assetsLoaded(e) {
		loaded = true;
		statusCallback(true, "Complete.");
	}

	/////////////////////////////////////////////
	//          Component Skinning             //
	/////////////////////////////////////////////
	public function getSkinFor(c:Component) {
		var obj :Dynamic = {};
		switch(c.className()) {
		case "Component":
		case "Button":
			var button = fast.node.button;
			obj.sprNormal = createAsset(button.node.normal);
			obj.sprOver = createAsset(button.node.over);
			obj.sprPress = createAsset(button.node.press);
		case "CheckBox":
			var cb = fast.node.checkbox;
			obj.sprNormal = createAsset(cb.node.normal);
			obj.sprToggled = createAsset(cb.node.checked);
		case "RadioButton":
			var rb = fast.node.radio;
			obj.sprNormal = createAsset(rb.node.normal);
			obj.sprToggled = createAsset(rb.node.checked);
		case "Slider":
			var sn = fast.node.slider;
			createColors(obj, sn);
			obj.normal = {};
			obj.over = {};
			var norm = sn.node.normal;
			var over = sn.node.over;
			obj.normal.north = createAsset(norm.node.north);
			obj.normal.south = createAsset(norm.node.south);
			obj.normal.west = createAsset(norm.node.west);
			obj.normal.east = createAsset(norm.node.east);
			obj.over.north = createAsset(over.node.north);
			obj.over.south = createAsset(over.node.south);
			obj.over.west = createAsset(over.node.west);
			obj.over.east = createAsset(over.node.east);
		case "ProgressBar":
			var pn = fast.node.progressbar;
			if(pn.hasNode.as3) {
				var as3 = pn.node.as3;
				obj.classname = as3.att.classname;
			}
			else
				throw "Not complete";
		case "ItemList", "Label":
		default:
			throw c.className() + " not registered in UI";
		}
		return obj;
	}

	function initComponentDefaults(c:Component, fn:Fast) {
		var minw : Float = if(fn.has.minWidth) Std.parseFloat(fn.att.minWidth) else -1;
		var maxw : Float = if(fn.has.maxWidth) Std.parseFloat(fn.att.maxWidth) else -1;
		var minh : Float = if(fn.has.minHeight) Std.parseFloat(fn.att.minHeight) else -1;
		var maxh : Float = if(fn.has.maxHeight) Std.parseFloat(fn.att.maxHeight) else -1;
		var prefw : Float = if(fn.has.prefWidth) Std.parseFloat(fn.att.prefWidth) else -1;
		var prefh : Float = if(fn.has.prefHeight) Std.parseFloat(fn.att.prefHeight) else -1;
		c.minimumSize = new Dimension(minw,minh);
		c.maximumSize = new Dimension(maxw,maxh);
		c.preferedSize = new Dimension(prefw,prefh);
	}

	function createColors(obj:Dynamic, fn:Fast) {
		var oc = {};
		obj.colors = oc;
		if(!fn.hasNode.colors) return;
		var colors = fn.node.colors;
		for(n in colors.nodes.color) {
			var c = new AlphaColor(
				Std.parseInt(n.att.rgb),
				Std.parseFloat(n.att.alpha)
			);
			Reflect.setField(oc,n.att.name,c);
		}
	}

	function createAsset(fn:Fast) : AssetContainer {
		var a : AssetContainer = null;
		switch(fn.att.type) {
		case "bitmap":
			a = new BitmapAsset(fn.att.id);
			getScale9Grid(a,fn);
		case "sprite":
			a = new LibraryAsset(fn.att.id);
			getScale9Grid(a,fn);
		}
		return a;
	}

	function getScale9Grid(a:HWSprite,fn:Fast) {
		if(fn.hasNode.scale9Grid) {
			var g = fn.node.scale9Grid;
			a.scale9Grid = new flash.geom.Rectangle(
				Std.parseFloat(g.att.x),
				Std.parseFloat(g.att.y),
				Std.parseFloat(g.att.width),
				Std.parseFloat(g.att.height));
		}
	}
}
