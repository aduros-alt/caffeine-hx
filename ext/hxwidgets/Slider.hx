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

import hxwidgets.events.SliderEvent;

enum SliderState {
	NORMAL;
	OVER;
	DRAGGING;
}

class Slider extends Component {
	/** The value from 0-1 **/
	public var value(getSliderValue, setSliderValue) : Float;
	/** Color of the slot border **/
	public var colorBorder : AlphaColor;
	/** Color of the slot fill **/
	public var colorFill : AlphaColor;
	/** size of the slot in pixels **/
	public var slotSize : Int;


	private var sliderState : SliderState;
	private var sliderBounds : Rectangle;
	// canvases
	private var sprSlot : HWSprite;
	private var sprIndicator : HWSprite;
	// assets
	private var sprNormal : BitmapAsset;
	private var sprOver : BitmapAsset;



	override public function className() { return "Slider"; }

	public function new(id:String, ?bounds:Rectangle) {
		super(id);
		slotSize = 2;
		sliderState = NORMAL;
		sprSlot = new HWSprite();
		sprIndicator = new HWSprite();
		addChild(sprSlot.getDisplay());
		addChild(sprIndicator.getDisplay());
		setComponentBounds(bounds);
		onConstructed("Slider");
		initEvents();
	}

	public function addValueListener(f:SliderEvent->Void) {
		addEventListener(SliderEvent.VALUE_CHANGED, f);
	}

	public function removeValueListener(f:SliderEvent->Void) {
		removeEventListener(SliderEvent.VALUE_CHANGED, f);
	}

	override public function setSkin(obj:Dynamic) {
		if(sprNormal != null)
			sprNormal.destroy();
		if(sprOver != null)
			sprOver.destroy();
		sprIndicator.clearChildren();

		sprNormal = obj.sprNormal;
		sprOver = obj.sprOver;
		colorBorder = obj.colors.border;
		colorFill = obj.colors.fill;

		sprIndicator.addChild(sprNormal.getDisplay());
		sprIndicator.addChild(sprOver.getDisplay());
		sprSlot.setForegroundChild(sprIndicator.getDisplay());
		redraw();
	}

	override function setEnabled(v:Bool) {
		super.setEnabled(v);
		alpha = if(v) 1.0 else 0.8;
		initEvents();
		return v;
	}

	function initEvents() {
		if(sprIndicator == null) return;
		var s = sprIndicator.getDisplay();
		if(s != null) {
			if(enabled) {
				s.addEventListener(flash.events.MouseEvent.MOUSE_OVER, onMouseOver);
				s.addEventListener(flash.events.MouseEvent.MOUSE_DOWN, onPress);
				s.addEventListener(flash.events.MouseEvent.MOUSE_UP, onRelease);
				s.addEventListener(flash.events.MouseEvent.MOUSE_OUT, onMouseOut);
			}
			else {
				s.removeEventListener(flash.events.MouseEvent.MOUSE_OVER, onMouseOver);
				s.removeEventListener(flash.events.MouseEvent.MOUSE_DOWN, onPress);
				s.removeEventListener(flash.events.MouseEvent.MOUSE_UP, onRelease);
				s.removeEventListener(flash.events.MouseEvent.MOUSE_OUT, onMouseOut);
			}
		}
	}

	function onMouseOver(e) {
		//trace(here.methodName);
		if(sliderState == NORMAL) {
			sliderState = OVER;
			sprOver.visible = true;
			sprNormal.visible = false;
		}
	}
	function onPress(e) {
		// redraw first, or the onMouseOut is fired
		redraw();
		sliderState = DRAGGING;
		sprIndicator.startDrag(false, sliderBounds.toFlash());
		sprIndicator.getDisplay().addEventListener(flash.events.MouseEvent.MOUSE_MOVE, onMouseMove);
	}
	function onRelease(e) {
		sprIndicator.stopDrag();
		sliderState = OVER;
		sprIndicator.getDisplay().removeEventListener(flash.events.MouseEvent.MOUSE_MOVE, onMouseMove);
		redraw();
	}
	function onMouseOut(e) {
		//trace(here.methodName);
		if(sliderState == DRAGGING) {
			onRelease(null);
			//sprIndicator.stopDrag();
		}
		if(sliderState != NORMAL) {
			sliderState = NORMAL;
			redraw();
		}
	}

	function onMouseMove(e:flash.events.MouseEvent) {
		dispatchEvent(
			new SliderEvent(SliderEvent.VALUE_CHANGED, this, getSliderValue())
		);
	}

	override function sizeChanged() {
		super.sizeChanged();
		var cv = getSliderValue();
		sliderBounds = null;
		redraw();
		setSliderValue(cv);
	}

	override public function onRepaint() {
		switch(sliderState) {
		case NORMAL, DRAGGING:
			sprNormal.visible = true;
			sprOver.visible = false;
		case OVER:
			sprOver.visible = true;
			sprNormal.visible = false;
		}

		if(sliderBounds == null) {
			var hiw = sprIndicator.width / 2;
			var hih = sprIndicator.height / 2;
			var thisWidth = componentBounds.width;

			var slotWidth = Math.max(thisWidth - sprIndicator.width, sprIndicator.width);

			var s = new flash.display.Shape();
			var g = s.graphics;
			g.lineStyle(0, colorBorder.rgb, colorBorder.alpha);
			g.beginFill(colorFill.rgb, colorFill.alpha);
			g.drawRect(0,0,slotWidth,slotSize);
			sprSlot.setBackgroundChild(s);
			s.x = hiw;
			s.y = hih - slotSize;
			sliderBounds = new Rectangle(0,sprIndicator.y, slotWidth,0);
		}
	}


	/**
		Returns the percentage of the slider's current position. Range 0-1
	**/
	public function getSliderValue() : Float {
		var rv = 0.0;
		if(sprIndicator != null && componentBounds != null) {
			rv = Math.min(100, sprIndicator.x / (componentBounds.width - sprIndicator.width));
		}
		rv = Math.max(0,rv);
		return rv;
	}

	public function setSliderValue(v:Float) {
		if(sprIndicator != null && componentBounds != null) {
			var maxx = componentBounds.width - sprIndicator.width;
			sprIndicator.x = Math.max(
				0,
				Math.min(maxx, v * maxx)
			);
		}
		return v;
	}

}