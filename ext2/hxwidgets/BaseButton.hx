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

import flash.events.Event;
import flash.events.MouseEvent;
import hxwidgets.AlignVertical.AlignVertical;
import hxwidgets.AlignHorizontal.AlignHorizontal;
import hxwidgets.events.ButtonEvent;

enum ButtonState {
	Normal;
	Toggled;
	Over;
	Press;
}

class BaseButton extends Component {
	public var onMouseClick :  BaseButton->Event->Void;
	public var verticalTextPosition(default,setVerticalTextPosition) : AlignVertical;
	public var horizontalTextPosition(default,setHorizontalTextPosition) : AlignHorizontal;
	public var icon(default, setIcon) : BitmapAsset;
	public var label(default,setLabel) : Label;
	public var state(default,setButtonState) : ButtonState;
	/** Space between edge of button and contents **/
	public var padding(default,setPadding) : Int;

	private var toggleButton : Bool;
	private var releaseOutside : Bool;
	private var pressInside : Bool;
	private var sprNormal : BitmapAsset;
	private var sprOver   : BitmapAsset;
	private var sprToggled: BitmapAsset;
	private var sprPress  : BitmapAsset;
	private var sprDisabled : BitmapAsset;
	private var sprDisabledToggled : BitmapAsset;

	private var originalX : Float;
	private var originalY : Float;

	public function new(
			id:String,
			?label:Label,
			?onClick : BaseButton->Event->Void,
			?icon:BitmapAsset,
			?pos:Point)
	{
		super(id);
		this.toggleButton = false;
		this.padding = 3;
		originalX = originalY = 0.0;
		Reflect.setField(this,"label",label);
		add(label);
		this.onMouseClick = onClick;
		setPosition(pos);
    	Reflect.setField(this,"verticalTextPosition", AlignVertical.MIDDLE);
    	Reflect.setField(this,"horizontalTextPosition",AlignHorizontal.RIGHT);
		Reflect.setField(this,"icon",icon);
		if(icon != null)
			addChild(icon.getIcon(this));
		Reflect.setField(this,"state",Normal);
		setEnabled(true);
	}

	public function addClickListener(f:ButtonEvent->Void, ?priority:Int) {
		addEventListener(ButtonEvent.CLICKED, f, false, priority);
	}

	function setVerticalTextPosition(v) {
		if(verticalTextPosition != v) {
			verticalTextPosition = v;
			repaint();
		}
		return v;
	}

	function setHorizontalTextPosition(v) {
		if(horizontalTextPosition != v) {
			horizontalTextPosition = v;
			repaint();
		}
		return v;
	}

	function setIcon(v) {
		if(icon != v) {
			icon = v;
			repaint();
		}
		return v;
	}

	override function setX(v) {
		super.setX(v);
		originalX = v;
		return v;
	}

	override function setY(v) {
		super.setY(v);
		originalY = v;
		return v;
	}

	override function setEnabled(v:Bool) {
		super.setEnabled(v);
		if(v) {
			subscribeEvent(flash.events.MouseEvent.MOUSE_OVER, onMouseOver);
			subscribeEvent(flash.events.MouseEvent.MOUSE_DOWN, onPress);
			subscribeEvent(flash.events.MouseEvent.MOUSE_UP, onRelease);
			subscribeEvent(flash.events.MouseEvent.MOUSE_OUT, onMouseOut);
			alpha = 1.0;
		}
		else {
			unSubscribeEvent(flash.events.MouseEvent.MOUSE_OVER, onMouseOver);
			unSubscribeEvent(flash.events.MouseEvent.MOUSE_DOWN, onPress);
			unSubscribeEvent(flash.events.MouseEvent.MOUSE_UP, onRelease);
			unSubscribeEvent(flash.events.MouseEvent.MOUSE_OUT, onMouseOut);
			if(state == Toggled) {
				if(sprDisabledToggled == null)
					alpha = 0.8;
			}
			else {
				if(sprDisabled == null)
					alpha = 0.8;
			}
		}
		setButtonState(state);
		return v;
	}

	function onMouseOver(e) {
		//trace(here.methodName);
		if(releaseOutside) {
			releaseOutside = false;
			state = Over;
		}
		redraw();
	}
	function onPress(e) {
		//trace(here.methodName);
		_mc.y += 2; _mc.x += 1;
		state = Press;
		pressInside = true;
		redraw();
	}
	function onRelease(e) {
		//trace(here.methodName + " " + releaseOutside);
		_mc.y = originalY;
		_mc.x = originalX;
		if(!releaseOutside && pressInside) {
			state = Over;
			if(onMouseClick != null)
				onMouseClick(this, e);
			dispatchEvent(
				new ButtonEvent(
					ButtonEvent.CLICKED,
					this
				)
			);
		}
		else {
			state = Normal;
		}
		redraw();
	}
	function onMouseOut(e) {
		releaseOutside = true;
		state = Normal;
		_mc.y = originalY;
		_mc.x = originalX;
		redraw();
	}

	function setButtonState(s:ButtonState) {
		state = s;
		return s;
	}

	function setLabel(v:Label) {
		//trace(here.methodName);
		if(v != label) {
			if(label != null) {
				remove(label);
			}
			label = v;
			if(label != null) {
				add(label);
			}
			redraw();
		}
		return v;
	}

	function setPadding(v:Int) {
		this.padding = v;
		repaint();
		return v;
	}

	override public function onRepaint() {
		//trace(here.methodName);
		var spr : BitmapAsset;
		switch(state) {
		case Normal:
			spr = sprNormal;
		case Toggled:
			spr = sprNormal;
		case Over:
			spr = sprOver;
		case Press:
			spr = sprPress;
		}

		var me = this;
		var setSprWidth = function(w) {
			spr.width = me.adjustWidthValue(w);
		}
		var setSprHeight = function(h) {
			spr.height = me.adjustHeightValue(h);
		}

		if(spr != null) {
			setBackgroundChild(spr.getDisplay());
			var p2 = 2*padding;
			var p3 = p2 + padding;
			var lblRect = new Rectangle(0,0,0,0);
			var iconRect = new Rectangle(0,0,0,0);
			if(label != null) {
				lblRect = label.getSpriteBounds();
				spr.width = label.width + p2;
				spr.height = label.height + p2;
			}
			if(icon != null) {
				iconRect.width = icon.getIconWidth(this);
				iconRect.height = icon.getIconHeight(this);
			}
			if(label != null || icon != null) {
				var sb : Rectangle;
				switch(horizontalTextPosition) {
				case LEFT: // icon on right, above or below
					switch(verticalTextPosition) {
					case MIDDLE:
						spr.width = p3 + iconRect.width + lblRect.width;
						sb = spr.getSpriteBounds();
						if(label != null)
							label.x = padding;
						if(icon != null)
							icon.x = sb.width - padding - iconRect.width;
					case TOP, BOTTOM:
						spr.width = p2 + Math.max(iconRect.width, lblRect.width);
						sb = spr.getSpriteBounds();
						if(label != null) {
							label.x = padding;
						}
						if(icon != null) {
							iconRect.centerHorizontalIn(sb);
							icon.x = iconRect.x;
						}
					}
				case CENTER:
					switch(verticalTextPosition) {
					// icon on left if vertical is MIDDLE
					case MIDDLE:
						setSprWidth( p3 + iconRect.width + lblRect.width );
						sb = spr.getSpriteBounds();
						if(label != null)
							label.x = sb.width - padding - lblRect.width;
						if(icon != null)
							icon.x = padding;
					case TOP, BOTTOM: // icon above or below.
						setSprWidth( p2 + Math.max(iconRect.width,lblRect.width) );
						sb = spr.getSpriteBounds();
						if(label != null) {
							lblRect.centerHorizontalIn(sb);
							label.x = lblRect.x;
						}
						if(icon != null) {
							iconRect.centerHorizontalIn(sb);
							icon.x = iconRect.x;
						}
					}
				case RIGHT: // icon on left, above or below
					switch(verticalTextPosition) {
					case MIDDLE:
						setSprWidth( p3 + iconRect.width + lblRect.width );
						sb = spr.getSpriteBounds();
						if(label != null)
							label.x = sb.width - padding - label.width;
						if(icon != null)
							icon.x = padding;
					case TOP,BOTTOM:
						setSprWidth( p2 + Math.max(iconRect.width,lblRect.width) );
						sb = spr.getSpriteBounds();
						if(label != null) {
							lblRect.centerHorizontalIn(sb);
							label.x = sb.width - padding - label.width;
						}
						if(icon != null) {
							iconRect.centerHorizontalIn(sb);
							icon.x = iconRect.x;
						}
					}
				} // end switch horizontalTextPosition

				switch(verticalTextPosition) {
				case TOP: // icon on bottom
					setSprHeight( p3 + iconRect.height + lblRect.height );
					sb = spr.getSpriteBounds();
					if(label != null)
						label.y = padding;
					if(icon != null)
						icon.y = sb.height - padding - icon.height;
				case MIDDLE: // icon on left or right, X already set above.
					setSprHeight( p2 + Math.max(iconRect.height,lblRect.height) );
					sb = spr.getSpriteBounds();
					if(icon != null) {
						iconRect.centerVerticalIn(sb);
						icon.y = iconRect.y;
					}
					if(label != null) {
						lblRect.centerVerticalIn(sb);
						label.y = lblRect.y;
					}
				case BOTTOM: // icon on top
					setSprHeight( p3 + iconRect.height + lblRect.height );
					sb = spr.getSpriteBounds();
					if(label != null)
						label.y = sb.height - padding - label.height;
					if(icon != null)
						icon.y = padding;
				}
			}
		}
	}
}