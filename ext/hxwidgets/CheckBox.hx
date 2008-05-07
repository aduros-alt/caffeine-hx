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
/**
	A 2 state button
**/
class CheckBox extends BaseButton {
	public var checked(default, setChecked) : Bool;

	public function new(
		id:String,
		label:Label,
		?onClick : BaseButton->Event->Void,
		?pos:Point)
	{
		super(id,label,onClick,null,pos);
		checked = false;
	}

	override public function getUIClassName() { return "CheckBox"; }
	override public function setUI(obj:Dynamic) {
		sprNormal = obj.sprNormal;
		sprToggled = obj.sprToggled;
		add(sprNormal);
		add(sprToggled);
		repaint();
		updateUI();
	}

	function setChecked(v : Bool) : Bool {
		if(v != checked) {
			checked = v;
			repaint();
			updateUI();
		}
		return v;
	}

	override function onMouseOver(e) {
		releaseOutside = false;
	}
	override function onPress(e) {	}
	override function onRelease(e) {
		if(!releaseOutside) {
			setChecked(!checked);
			if(onMouseClick != null)
				onMouseClick(this, e);
		}
	}
	override function onMouseOut(e) {
		releaseOutside = true;
	}

	override public function onRepaint() {
		switch(checked) {
		case true:
			sprToggled.visible = true;
			sprNormal.visible = false;
		case false:
			sprToggled.visible = false;
			sprNormal.visible = true;
		}

		if(label != null) {
			var sb = sprNormal.bounds;
			var lb = label.bounds;
			lb.centerVerticalIn(sb);
			label.x = sb.width + padding;
			label.y = lb.y;
		}
	}
}