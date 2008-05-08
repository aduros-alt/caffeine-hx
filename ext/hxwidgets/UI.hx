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
import hxwidgets.Component.ScaleMode;

class UI {
	static var repaintQueue : List<List<Component>>;
	static public var currentSkin : UISkin;

	static public function getSkinFor(c:Component) {
		return currentSkin.getSkinFor(c);
		/*
		//trace(here.methodName);
		var obj :Dynamic = Reflect.empty();
		switch(c.getUIClassName()) {
		case "Component":
		case "Button":
			var n = new BitmapAsset("btn_normal_tan");
			n.scale9Grid = new flash.geom.Rectangle(5,5,118,22);
			var no = new BitmapAsset("btn_over_tan");
			no.scale9Grid = new flash.geom.Rectangle(5,5,118,22);
			var np = new BitmapAsset("btn_press_tan");
			np.scale9Grid = new flash.geom.Rectangle(5,5,118,22);
			c.minimumSize = new Dimension(64,16);
			c.maximumSize = new Dimension(200,200);
			c.scaleMode = ScaleWidth;
			obj.sprNormal = n;
			obj.sprOver = no;
			obj.sprPress = np;
		case "CheckBox":
			var n = new BitmapAsset("cb_normal_tan");
			var c = new BitmapAsset("cb_checked_tan");
			c.minimumSize = new Dimension(12,12);
			obj.sprNormal = n;
			obj.sprToggled = c;
		case "RadioButton":
			var n = new BitmapAsset("rb_normal_tan");
			var c = new BitmapAsset("rb_checked_tan");
			c.minimumSize = new Dimension(12,12);
			obj.sprNormal = n;
			obj.sprToggled = c;
		case "ItemList":
			c.minimumSize = new Dimension(50,12);
			c.preferedSize = new Dimension(150,100);
			c.maximumSize = new Dimension(500,500);
		default:
			throw c.getUIClassName() + " not registered in UI";
		}
		return obj;
		*/
	}

	/**
		Adds the component to the list of things that need to be redrawn
		on next call to updateUI().
	**/
	static public function scheduleRepaint(c:Component) {
		if(repaintQueue == null)
			repaintQueue = new List();
		var l : List<Component>;
		for(li in repaintQueue) {
			if(li.first() == c) {
				l = li;
				l.clear();
				break;
			}
		}
		if(l == null)
			l = new List<Component>();
		l.add(c);
		var p : Component = c.parent;
		while(p != null) {
			l.add(p);
			p = p.parent;
		}
		repaintQueue.add(l);
	}

	static public function repaint() {
		var orq = repaintQueue;
		repaintQueue = new List();
		for(li in orq) {
			for(c in li) {
				c.onRepaint();
				//Reflect.callMethod(c,"onRepaint",[]);
				repaintQueue.remove(li);
			}
		}
	}

	static public function initialize(initialSkinXmlUrl : String, onInitialized:Bool->String->Void)
	{
		currentSkin = new UISkin(initialSkinXmlUrl,callback(initSkinHandler,onInitialized));
		currentSkin.load();
	}

	static function initSkinHandler(cb, res:Bool, msg:String) : Void {
		if(!res) {
			cb(res, msg);
			return;
		}

		cb(true,"Complete.");
	}

	static function __init__() {
		repaintQueue = new List();

	}
}