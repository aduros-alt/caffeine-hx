/*
 * Copyright (c) 2008, The Caffeine-hx project contributors
 * Original author : Russell Weir
 * Contributors:
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE CAFFEINE-HX PROJECT CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE CAFFEINE-HX PROJECT CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

package hxwidgets;
import flash.text.StyleSheet;
import flash.display.DisplayObject;

import flash.events.EventDispatcher;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.events.HTTPStatusEvent;

import hxwidgets.events.SizeEvent;

enum ScaleMode {
	ScaleWidth;
	ScaleHeight;
}

class Component extends HWSprite {
	/** anything that takes a styleSheet will use this if set **/
	public static var defaultStyleSheet : StyleSheet = null;
	public static var registry : Hash<Component> = new Hash();

	/** Arbitrary id string **/
	public var id(default,null) : String;
	public var index : Int;
	public var parent(getParent,null) : Component;
	public var enabled(default,setEnabled) : Bool;
	public var initialized(default, null) : Bool;

	public var minimumSize:Dimension;
	public var maximumSize:Dimension;
	public var preferedSize(default,setPreferedSize):Dimension;
	public var scaleMode : ScaleMode;
	public var componentBounds(default, setComponentBounds) : hxwidgets.Rectangle;


	private var children : Array<Component>;
	private var background : Component;
	private var lastSize : Dimension;
	private var lastPosition : Point;

	public function new(id) {
		super();
		this.id = id;
		children = new Array();
		minimumSize = new Dimension(10,10);
		maximumSize = new Dimension(100,100);
		Reflect.setField(this,"componentBounds",new Rectangle(0,0,0,0));
		initialized = false;
		register(this);
		repaint();
	}

	public function className() { return "Component"; }

	public function add(v:Component) {
		if(v.parent != this) {
			if(v.parent != null)
				v.parent.remove(v);

		}
		else {
			remove(v);
		}
		_mc.addChild(v._mc);
		v.parent = this;
		children.push(v);
	}

	public function addChild(v:DisplayObject) {
		var s = new Component("");
		s._mc.addChild(v);
		add(s);
	}

	public function addAt(v:Component, pos:Int) {
		if(v.parent != this) {
			if(v.parent != null)
				v.parent.remove(v);
		}
		else {
			remove(v);
		}
		_mc.addChildAt(v._mc, pos);
		v.parent = this;
		children.insert(pos, v);
	}

	function setBackground(v:Component) {
		if(v != background) {
			if(background != null)
				remove(background);
			background = v;
			addAt(v,0);
		}
	}

	public function addChildAt(v:DisplayObject, pos:Int) {
		var s = new Component("");
		s._mc.addChild(v);
		addAt(s, pos);
	}

	function clearChildren() {
		var px : Int = children.length - 1;
		while(px >=0) {
			removeChildAt(px);
			px = px -1;
		}
		while(_mc.numChildren > 0) {
			_mc.removeChildAt(0);
		}
		children = new Array();
	}

	public function remove(v:Component) {
		for(i in 0...children.length) {
			if(children[i] == v) {
				children.splice(i,1);
				_mc.removeChild(v._mc);
				v.parent = null;
			}
		}
	}

	public function removeChild(v:DisplayObject) {
		for(i in 0...children.length) {
			if(children[i]._mc == v) {
				children.splice(i,1);
				_mc.removeChild(v);
			}
		}
	}

	public function removeChildAt(pos : Int) {
		if(pos < children.length) {
			var c = children.splice(pos,1);
			_mc.removeChildAt(pos);
			if(c != null)
				c[0].parent = null;
		}
	}

	function getParent() { return parent; }

	// xxx Do I have to do this?
	override function setAlpha(v:Float) {
		//trace(here.methodName);
		super.setAlpha(v);
		for(i in children)
			i.setAlpha(v);
		return v;
	}

	function setEnabled(v) {
		enabled = v;
		return v;
		repaint();
	}

	public function setPosition(p:Point) {
		if(p == null) {
			this.x = 0;
			this.y = 0;
		}
		else {
			this.x = p.x;
			this.y = p.y;
		}
	}


	/**
		Any skinnable component that overrides this should update the
		component from the supplied object, set 'initialized' to true,
		then call updateUI()
	**/
	public function setSkin(obj:Dynamic) : Void {
		//throw "Override me";
	}

	public function destroy() {
		_mc = null;
	}

	/**
		Redraw everything that is ready.
	**/
	function redraw() {
		UI.scheduleRepaint(this);
		UI.repaint();
	}

	/**
		Schedule component to be redrawn on next call to redraw()
	**/
	public function repaint() {
		UI.scheduleRepaint(this);
	}

	function onConstructed(name:String) {
		if(name == className()) {
			setSkin(UI.getSkinFor(this));
			initialized = true;
			redraw();
		}
	}



	public function onRepaint() {
		if(!Std.is(this,hxwidgets.AssetContainer) && Type.getClassName(Type.getClass(this)) != "hxwidgets.Component")
			trace(Type.getClassName(Type.getClass(this)) + " has not overriden onRepaint");
	}

	public function getComponentBounds() {
		return componentBounds;
	}

	public function setComponentBounds(r:Rectangle) {
		setPosition(new Point(r.x, r.y));
		setSize(new Dimension(r.width, r.height));
		return r;
	}

	public function setSize(d : Dimension) {
		if(d == null)
			d = new Dimension(0,0);
		var newDim = d.clone().setAtLeastZero();
		var b = getComponentBounds();
		var prevSize = new Dimension(b.width, b.height);
		if(!Dimension.equal(newDim, prevSize)) {
			lastSize = prevSize;
			componentBounds.width = newDim.width;
			componentBounds.height = newDim.height;
			repaint();
			dispatchEvent(
				new SizeEvent(SizeEvent.SIZE_CHANGE, this, lastSize, newDim)
			);
		}
	}

	public function adjustWidthValue(w) {
			if(minimumSize != null)
				w = Math.max(minimumSize.width, w);
			if(maximumSize != null && maximumSize.width > 0)
				w = Math.min(maximumSize.width,w);
			if(preferedSize != null && preferedSize.width > 0)
				w = preferedSize.width;
			return w;
	}

	public function adjustHeightValue(h) {
			if(minimumSize != null)
				h = Math.max(minimumSize.height, h);
			if(maximumSize != null && maximumSize.height > 0)
				h = Math.min(maximumSize.height,h);
			if(preferedSize != null && preferedSize.height > 0)
				h = preferedSize.height;
			return h;
	}

	public function setPreferedSize(v:Dimension) {
		var e = new SizeEvent(SizeEvent.PREFERED_SIZE_CHANGE, this, preferedSize, v);
		preferedSize = v;
		dispatchEvent( e );
		return v;
	}

	public static function register(c:Component) {
		if(c.id != null && c.id != "")
			registry.set(c.id, c);
	}

	public static function findById(idstr:String) {
		return registry.get(idstr);
	}

	///////////////////////////////////////////////////////
	//             Event Handlers                        //
	///////////////////////////////////////////////////////
	/**
		Subscribe to an event in the underlying movie clip.
	**/
	function subscribeEvent(evt:String, f:Dynamic->Void, ?useCapture : Bool, ?priority : Int, ?useWeakReference : Bool )
	{
		this._mc.addEventListener(evt, f, useCapture, priority, useWeakReference);
	}
	/**
		Unsubscribe to the underlying Sprite event
	**/
	function unSubscribeEvent(evt:String, f:Dynamic->Void, ?useCapture :Bool) {
		this._mc.removeEventListener(evt, f, useCapture);
	}

	public function addProgressHandler(f:ProgressEvent->Void,?priority:Int) {
		addEventListener(ProgressEvent.PROGRESS, f, false, priority);
	}
	public function removeProgressHandler(f) {
		removeEventListener(ProgressEvent.PROGRESS, f);
	}

	public function addLoadedHandler(f:Event->Void,?priority:Int) {
		addEventListener(Event.COMPLETE, f, false, priority);
	}
	public function removeLoadedHandler(f) {
		removeEventListener(Event.COMPLETE, f);
	}

	public function addIoErrorHandler(f:IOErrorEvent->Void,?priority:Int) {
		addEventListener(IOErrorEvent.IO_ERROR, f, false, priority);
	}
	public function removeIoErrorHandler(f) {
		removeEventListener(IOErrorEvent.IO_ERROR, f);
	}

}