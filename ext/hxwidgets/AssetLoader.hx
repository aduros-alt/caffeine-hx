package hxwidgets;

import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.display.Loader;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.events.HTTPStatusEvent;
import flash.system.LoaderContext;
import flash.net.URLRequest;

class AssetLoader extends AssetContainer {
	var loader : Loader;
	var loaderContext : LoaderContext;
	var loaded : Bool;
	var assetContainer : flash.display.DisplayObjectContainer;
	var urlRequest : URLRequest;

	public function new(url:String, ?context:LoaderContext) {
		super();
		loaded = false;
		loader = new Loader();
		assetContainer = new Sprite();
		urlRequest = new URLRequest(url);
		loaderContext = context;
		var cli = loader.contentLoaderInfo;
		cli.addEventListener(Event.COMPLETE, onLoadComplete);
		cli.addEventListener(HTTPStatusEvent.HTTP_STATUS, onHttpStatus);
		cli.addEventListener(Event.INIT, onLoadInit);
		cli.addEventListener(IOErrorEvent.IO_ERROR, onIoError);
		cli.addEventListener(Event.OPEN, onOpen);
		cli.addEventListener(ProgressEvent.PROGRESS, onProgress);
		cli.addEventListener(Event.UNLOAD, onUnload);
	}

	public function load() {
		loader.load(urlRequest, loaderContext);
	}

	override public function setAsset(newasset:DisplayObject) {
		if(newasset != asset) {
			if(asset != null) {
				if(asset.parent == assetContainer)
					assetContainer.removeChild(asset);
			}
			asset = newasset;
			if(asset != null) {
				assetContainer.addChild(asset);
			}
			setLoaded(asset != null);
			resetAsset();
		}
	}

	function onLoadComplete(e:flash.events.Event) {
		//trace(here.methodName);
		//trace(loader.contentLoaderInfo.parentAllowsChild);
		//trace(loader.contentLoaderInfo.sameDomain);
		setAsset(loader.content);
		dispatchEvent(new Event(Event.COMPLETE));
	}

	function onHttpStatus(e) {
		dispatchEvent(new HTTPStatusEvent(HTTPStatusEvent.HTTP_STATUS,false,false,e.status));
	}

	function onLoadInit(e) {
		dispatchEvent(new Event(Event.INIT));
	}

	function onIoError(e) {
		trace(here.methodName);
		dispatchEvent(new IOErrorEvent(IOErrorEvent.IO_ERROR, false, false, e.toString()));
	}

	function onOpen(e) {
		dispatchEvent(new Event(Event.OPEN));
	}

	function onProgress(e:ProgressEvent) {
		dispatchEvent(new ProgressEvent(ProgressEvent.PROGRESS, false, false, e.bytesLoaded, e.bytesTotal));
	}

	function onUnload(e) {
		dispatchEvent(new Event(Event.UNLOAD));
	}

	function onSecurityError(e) {
	}


}