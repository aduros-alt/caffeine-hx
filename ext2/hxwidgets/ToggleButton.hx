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

class ToggleButton extends Button {
	public var toggled(default,setToggled) : Bool;

	public function new(
			id : String,
			label:Label,
			?onClick : BaseButton->Event->Void,
			?icon:BitmapAsset,
			?pos:Point
			)
	{
		super(id,label,onClick,icon,pos);
		toggleButton = true;
		updateUI();
	}

	override public function getUIClassName() { return "ToggleButton"; }
	override public function setUI(obj:Dynamic) {
		super.setUI(obj);
		sprToggled = obj.sprToggled;
		sprDisabledToggled = obj.sprDisabledToggled;
	}

	override function setButtonState(s:ButtonState) {
		state = s;
		repaint();
		return s;
	}

	function setToggled(v) {
		state = if(v) Toggled else Normal;
		return v;
	}

	override function onMouseOver(e) {
		if(releaseOutside) {
			releaseOutside = false;
			if(state != Toggled)
				state = Over;
			updateUI();
		}
	}
	override function onPress(e) {
		if(state != Toggled) {
			_mc.y += 2; _mc.x += 1;
			state = Press;
			updateUI();
		}
	}
	override function onRelease(e) {
		if(!releaseOutside) {
			toggled = !toggled;
			if(toggled) {
				state = Toggled;
			}
			else {
				state = Over;
				_mc.y = originalY;
				_mc.x = originalX;
			}
			if(onMouseClick != null)
				onMouseClick(this, e);
			updateUI();
		}
	}
	override function onMouseOut(e) {
		releaseOutside = true;
		if(state != Toggled) {
			state = Normal;
			_mc.y = originalY;
			_mc.x = originalX;
		}
		updateUI();
	}


}
