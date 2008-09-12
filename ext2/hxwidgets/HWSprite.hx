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
import flash.display.DisplayObject;
import flash.display.Sprite;
import flash.geom.Rectangle;


class HWSprite extends flash.events.EventDispatcher {
	public var _mc(default,null) : Sprite;
	var backgroundChild : DisplayObject;
	var foregroundChild : DisplayObject;
	public var _data : Dynamic;

	public var alpha(getAlpha,setAlpha) : Float;
	public var dropTarget(getDropTarget,null) : DisplayObject;
	public var graphics(getGraphics, null) : flash.display.Graphics;
	public var height(getHeight,setHeight) : Float;
	public var mask(getMask,setMask) : DisplayObject;
	//getParent is application specific.
	public var visible(getVisible,setVisible) : Bool;
	public var width(getWidth,setWidth) : Float;
	public var x(getX, setX) : Float;
	public var y(getY, setY) : Float;
	public var scale9Grid(getScale9,setScale9) : Rectangle;
	public var scaleX(getScaleX,setScaleX) : Float;
	public var scaleY(getScaleY,setScaleY) : Float;

	public function new() {
		super(this);
		_mc = new Sprite();
		backgroundChild = null;
		foregroundChild = null;
	}

	function getAlpha() { return _mc.alpha; }
	function setAlpha(v:Float) { return _mc.alpha = v; }
	function getDropTarget() { return _mc.dropTarget; }
	function getGraphics() { return _mc.graphics; }
	function getHeight() { return _mc.height; }
	function setHeight(v:Float) { height = v; _mc.height = v; return v; }
	function getMask() { return _mc.mask; }
	function setMask(v) { _mc.mask = v; return v; }
	function getVisible() { return _mc.visible; }
	function setVisible(v) { _mc.visible = v; return v; }
	function getWidth() { return _mc.width; }
	function setWidth(v:Float) { width = v; _mc.width = v; return v; }

	function getX() { return _mc.x; }
	function setX(v) { _mc.x = v; return v; }
	function getY() { return _mc.y; }
	function setY(v) { _mc.y = v; return v;}

	function getScale9() { return _mc.scale9Grid; }
	function setScale9(v) { _mc.scale9Grid = v; return v; }
	function getScaleX() { return _mc.scaleX; }
	function setScaleX(v) { _mc.scaleX = v; return v; }
	function getScaleY() { return _mc.scaleY; }
	function setScaleY(v) { _mc.scaleY = v; return v; }

	function startDrag(?lockCenter:Bool, ?bounds:Rectangle) {
		_mc.startDrag(lockCenter,bounds);
	}
	function stopDrag() { _mc.stopDrag(); }

	function getDisplayObject() : DisplayObject {
		return _mc;
	}

	public function getDisplay() : DisplayObject {
		return _mc;
	}

	public function setMaskRectangle(r:hxwidgets.Rectangle) {
		var om = getMask();
		var m = new Sprite();
		m.graphics.beginFill(0xFF0000);
		m.graphics.drawRect(r.x,r.y,r.width,r.height);
		_mc.addChild(m);
		_mc.mask = m;
		if(om != null)
			_mc.removeChild(om);
	}

	public function getSpriteBounds() {
		return new hxwidgets.Rectangle(x,y,width,height);
	}


	////////////////////////////////////////
	//          Child display objects     //
	////////////////////////////////////////
	public function addChild(v:DisplayObject) {
		var fgi : Int = getForegroundChildIndex();
		if(fgi >= 0) {
			_mc.addChildAt(v, fgi);
			onChildAdded(v, fgi);
		}
		else {
			_mc.addChild(v);
			onChildAdded(v, _mc.numChildren - 1);
		}
	}

	public function addChildAt(v:DisplayObject, pos:Int) {
		var fgi : Int = getForegroundChildIndex();
		_mc.addChildAt(v, pos);
		if(pos == 0 && backgroundChild != null) {
			_mc.removeChild(backgroundChild);
			_mc.addChildAt(backgroundChild, 0);
		}
		if( fgi >=0 && fgi < pos ) {
			_mc.removeChild(foregroundChild);
			_mc.addChild(foregroundChild);
		}
		onChildAdded(v, pos);
	}

	/**
		Remove all children from the sprite. The background and foreground
		can be left alone by setting saveForeground or saveBackground to true.
	**/
	public function clearChildren(?saveForeground : Bool, ?saveBackground : Bool) {
		var nc = _mc.numChildren;
		var idx : Int = 0;
		for(i in 0...nc) {
			if(
				(saveBackground && _mc.getChildAt(idx) == backgroundChild) ||
				(saveForeground && _mc.getChildAt(idx) == foregroundChild)
			)
			{
				idx ++;
				continue;
			}
			removeChildAt(idx);
		}
	}

	public function contains(c : DisplayObject) {
		return _mc.contains(c);
	}

	public function getBackgroundChild():DisplayObject {
		return backgroundChild;
	}

	public function getForegroundChild():DisplayObject{
		return foregroundChild;
	}

	/**
		Get the current index of the foregroundChild object.
		Returns -1 if the foregroundChild does not exist.
	**/
	public function getForegroundChildIndex(): Int {
		var fgi : Int = -1;
		if(foregroundChild != null) {
			try {
				fgi = _mc.getChildIndex(foregroundChild);
			}
			catch(e:Dynamic) { }
		}
		return fgi;
	}

	/**
		override to set data for child added to container
	**/
	function onChildAdded(v : DisplayObject, pos:Int) {}

	function onChildRemoved(v : DisplayObject, pos:Int) {}

	public function setBackgroundChild(child:DisplayObject) {
		if(child != backgroundChild){
			if(backgroundChild != null){
				_mc.removeChild(backgroundChild);
			}
			backgroundChild = child;
			if(child != null){
				_mc.addChildAt(child, 0);
			}
		}
	}

	public function setForegroundChild(child:DisplayObject) {
		if(child != foregroundChild){
			if(foregroundChild != null){
				_mc.removeChild(foregroundChild);
			}
			foregroundChild = child;
			if(child != null){
				_mc.addChild(child);
			}
		}
	}

	public function removeChild(v:DisplayObject) {
		_mc.removeChild(v);
	}

	public function removeChildAt(pos : Int) {
		_mc.removeChildAt(pos);
	}

/*
	override public function addEventListener(evt:String, f:Dynamic->Void, ?useCapture : Bool, ?priority : Int, ?useWeakReference : Bool )
	{
		_mc.addEventListener(evt, f, useCapture, priority, useWeakReference);
	}
	/**
		Unsubscribe to the underlying Sprite event
	**
	override public function removeEventListener(evt:String, f:Dynamic->Void, ?useCapture :Bool) {
		_mc.removeEventListener(evt, f, useCapture);
	}
*/
}
