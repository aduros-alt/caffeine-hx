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
	public var parentComponent(getParentComponent,null) : Component;
	public var enabled(default,setEnabled) : Bool;
	public var initialized(default, null) : Bool;

	public var minimumSize:Dimension;
	public var maximumSize:Dimension;
	public var preferedSize(default,setPreferedSize):Dimension;
	public var scaleMode : ScaleMode;
	public var componentBounds(default, setComponentBounds) : hxwidgets.Rectangle;


	private var children : List<Component>;
	//private var background : Component;
	private var lastSize : Dimension;
	private var lastPosition : Point;

	public function className() { return "Component"; }

	public function new(id) {
		super();
		this.id = id;
		children = new List();
		minimumSize = new Dimension(10,10);
		maximumSize = new Dimension(100,100);
		Reflect.setField(this,"componentBounds",new Rectangle(0,0,0,0));
		initialized = false;
		register(this);
		enabled = true;
		repaint();
	}

	public function destroy() {
		for(c in children) {
			c.destroy();
		}
		_mc.parent.removeChild(_mc);
		_mc = null;
		var r = registry.get(id);
		if(r == this) {
			registry.remove(id);
		}
		parentComponent = null;
	}


	///////////////////////////////////////////////////////
	//          Global component registry                //
	///////////////////////////////////////////////////////
	public static function register(c:Component) {
		if(c.id != null && c.id != "")
			registry.set(c.id, c);
	}

	/**
		Find a component by it's ID string
	**/
	public static function findById(idstr:String) {
		return registry.get(idstr);
	}

	///////////////////////////////////////////////////////
	//          Parent/Child Releationship               //
	///////////////////////////////////////////////////////
	/**
		Set the parent<->child relationship between components
	**/
	function attachChildComponent(v:Component) {
		v.parentComponent = this;
		for(c in children) {
			if(c == v)
				return;
		}
		children.add(v);
	}

	/**
		Clear the parent<->child relationship between components
	**/
	function detachChildComponent(v:Component) {
		v.parentComponent = null;
		children.remove(v);
	}

	///////////////////////////////////////////////////////
	//       Adding/Removing Child Components            //
	///////////////////////////////////////////////////////
	public function add(v:Component) {
		if(v.parentComponent != this) {
			if(v.parentComponent != null)
				v.parentComponent.remove(v);
		}
		else {
			remove(v);
		}
		addChild(v.getDisplay());
		v.parentComponent = this;
		attachChildComponent(v);
	}

	public function addAt(v:Component, pos:Int) {
		if(v.parentComponent != this) {
			if(v.parentComponent != null)
				v.parentComponent.remove(v);
		}
		else {
			remove(v);
		}
		addChildAt(v.getDisplay(), pos);
		v.parentComponent = this;
		attachChildComponent(v);
	}

	override function onChildAdded(v:DisplayObject, idx : Int) {
	}

	override function onChildRemoved(v:DisplayObject, idx : Int) {
		for(c in children) {
			if(v == c.getDisplay()) {
				detachChildComponent(c);
				return;
			}
		}
	}

	public function remove(v) {
		if(v != null)
			removeChild(v.getDisplay());
	}

	public function removeAt(pos : Int) {
		removeChildAt(pos);
	}

	function getParentComponent() { return parentComponent; }
	function getParentContainer() : Container
	{
		if(parentComponent != null) {
			if(Std.is(parentComponent, hxwidgets.Container))
				return cast parentComponent;
			return parentComponent.getParentContainer();
		}
		return null;
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
		if(r != null) {
			setPosition(new Point(r.x, r.y));
			setSize(new Dimension(r.width, r.height));
		}
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
			sizeChanged();
			dispatchEvent(
				new SizeEvent(SizeEvent.SIZE_CHANGE, this, lastSize, newDim)
			);
		}
	}

	/**
		Override this. Called after a call to setSize() determines that
		the size is different.
	**/
	function sizeChanged() {
		repaint();
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