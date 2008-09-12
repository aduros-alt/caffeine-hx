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

import hxwidgets.BaseButton.ButtonState;
import flash.events.Event;

class Button extends BaseButton {
	var origTextColor : Null<UInt>;

	override public function className() { return "Button"; }

	public function new(
			id : String,
			label:Label,
			?onClick : BaseButton->Event->Void,
			?icon:BitmapAsset,
			?pos:Point
			)
	{
		super(id,label,onClick,icon,pos);
		onConstructed("Button");
	}

	override public function setSkin(obj:Dynamic) {
		sprNormal = obj.sprNormal;
		sprOver = obj.sprOver;
		sprPress = obj.sprPress;
		redraw();
	}

	override function setButtonState(s:ButtonState) {
		//trace(here.methodName + " " + enabled + " " + s);
		if(!enabled)
			state = Normal;
		else
			state = s;
		repaint();
		return s;
	}

	override function setEnabled(v) {
		if(this.enabled != v) {
			super.setEnabled(v);
			if(label != null) {
				var tf = untyped label._textField;
				if(enabled) {
					if(origTextColor != null)
						tf.textColor = origTextColor;
					if(icon != null)
						icon.alpha = 1.0;
				}
				if(!enabled) {
					origTextColor = tf.textColor;
					tf.textColor = 0x999999;
					alpha = 1.0;
					if(icon != null)
						icon.alpha = 0.5;
				}
			}
		}
		return v;
	}
}
