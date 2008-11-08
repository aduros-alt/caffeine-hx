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
import flash.text.StyleSheet;

class UI {
	static var repaintQueue 		: List<List<Component>>;
	static public var currentSkin 	: UISkin;
	static public var defaultCss 	: StyleSheet 		= initCss();

	static public function getSkinFor(c:Component) {
		return currentSkin.getSkinFor(c);
	}

	/**
		Adds the component to the list of things that need to be redrawn
		on next call to updateUI().
	**/
	static public function scheduleRepaint(c:Component) {
		if(repaintQueue == null)
			repaintQueue = new List();
		var l : List<Component> = null;
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
		var p : Component = c.parentComponent;
		while(p != null) {
			l.add(p);
			p = p.parentComponent;
		}
		repaintQueue.add(l);
	}

	static public function repaint() {
		for(li in repaintQueue) {
			for(c in li) {
				if(c.initialized) {
					c.onRepaint();
					repaintQueue.remove(li);
				}
			}
		}
	}

	/**
		The first method that must be called when starting up hxwidgets. This takes a URL to the skin xml definition file, and a callback method that will receive true for a succeful load, or false and a String error message.
	**/
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


	////////////////////////////////////////
	//          Initialization            //
	////////////////////////////////////////
	static function __init__() {
		repaintQueue = new List();
	}

	/**
	* @return default CSS
	*/
	private static function initCss() : StyleSheet
	{
		defaultCss = new StyleSheet();
		defaultCss.setStyle( "p",
			{
				color		: "#000000",
				display		: "inline",
				fontFamily	: "Arial",
				fontSize	: 10
			}
		);
		return defaultCss;
	}
}
