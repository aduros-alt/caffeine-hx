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
		var obj :Dynamic = Reflect.empty();
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

	function createAsset(fn:Fast) : AssetContainer {
		var a : AssetContainer;
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