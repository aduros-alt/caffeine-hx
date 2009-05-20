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
import hxwidgets.events.SizeEvent;
import hxwidgets.events.ItemListEvent;

class ItemList extends Component {
	public static var SINGLE : String = "single";
	public static var MULTI : String = "multi";

	public var mode(default, setSelectionMode) : String;
	private var list : Array<String>;
	private var data : Array<Dynamic>;
	private var selected : List<Int>;
	private var labels : Array<IconLabel>;

	//private var canvas : HWSprite;

	public function new(id:String, ?pos:Point) {
		super(id);
		canvas = new HWSprite();
		add(canvas);
		list = new Array();
		data = new Array();
		selected = new List();
		setPosition(pos);
		setEnabled(true);
		repaint();
		updateUI();
		addEventListener(SizeEvent.PREFERED_SIZE_CHANGE, onPreferedSizeChange);
	}

	override public function getUIClassID():String{
		return "ItemList";
	}

	public function addSelectionListener(f:ItemListEvent->Void,?priority:Int) {
		addEventListener(ItemListEvent.SELECTION_CHANGED, f, false, priority);
	}

	public function removeSelectionListener(f:ComboBoxEvent->Void) {
		removeEventListener(ItemListEvent.SELECTION_CHANGED, f);
	}

	public function addItem(label:String, data:Dynamic) {
		this.list.push(label);
		this.data.push(data);
		repaint();
	}

	public function addItemAt(label:String, data:Dynamic, idx : Int) {
		this.list.insert(idx,label);
		this.data.insert(idx,data);
		repaint();
	}

	public function removeItem(label:String) {
		for(i in 0...list.length) {
			if(list[i] == label) {
				removeItemAt(i);
				return;
			}
		}
	}

	public function removeItemAt(idx:Int) {
		if(idx >= list.length || idx < 0)
			return;
		list.slice(idx);
		data.slice(idx);
		repaint();
	}

	public function selectionMode(m : String) {
		switch(m) {
		case SINGLE:
			if(mode == MULTI) {
				var lsIdx : Null<Int> = selected.last();
				var iLen  = select.length;
				selected = new List();
				if(lsIdx != null) {
					selected.add(lsIdx);
					repaint();
					if(iLen > 1)
						updateUI();
				}
			}
			mode = m;
		case MULTI:
			mode = m;
		default:
			throw("Invalid selectionMode " + m);
		}
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
			alpha = 0.8;
		}
		return v;
	}

	function onMouseOver(e) {
		//trace(here.methodName);
		if(releaseOutside) {
			releaseOutside = false;
			state = Over;
		}
		updateUI();
	}
	function onPress(e) {
		//trace(here.methodName);
		state = Press;
		updateUI();
	}
	function onRelease(e) {
		//trace(here.methodName + " " + releaseOutside);
		if(!releaseOutside) {
			if(onMouseClick != null)
				onMouseClick(this, e);
		}
		else {
		}
		updateUI();
	}
	function onMouseOut(e) {
		releaseOutside = true;
		updateUI();
	}

	function onPreferedSizeChange(e) {
		onRepaint();
	}

	override public function onRepaint() {
		setMaskRectangle(new Rectangle(0,0,preferedSize.width,preferedSize.height));
		canvas.clearChildren();
		var sy : Int = 0;
		for(li in list) {

		}
	}
}
