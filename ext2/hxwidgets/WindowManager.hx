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

import flash.display.DisplayObjectContainer;
/*
import flash.display.Bitmap;
import flash.display.MovieClip;
import flash.events.MouseEvent;
import flash.text.TextField;
import flash.text.TextFormat;
*/
class WindowManager extends Component {
	public static var instance(default,null) : WindowManager;

	private var rootContainer	: DisplayObjectContainer;
	private var dockbar : Dockbar;
	private var windows	: IntHash<Window>;
	private var rootmc	: DisplayObjectContainer;
	private var nextHandle	: Int;

	public static function create(
		rootMC:flash.display.DisplayObjectContainer,
		maxSize : Dimension
		)
	{
		if(instance == null)
			instance = new WindowManager(rootMC,maxSize);
		else
			throw("Only one window manager may be active");
		return instance;
	}

	function new(rootMC:flash.display.DisplayObjectContainer, maxSize : Dimension)
	{
		super("WindowManager");
		this.rootContainer = rootMC;
		this.maximumSize = maxSize;
		rootContainer.addChild(getDisplay());
		windows = new IntHash();
		nextHandle = 0;
		setMaskRectangle(new Rectangle(0,0,maxSize.width,maxSize.height));
	}

	/**
		Sets the main dockbar component.
	**/
	public static function setDockbar(d:Dockbar) {
		if(instance.dockbar != null)
			throw "Only one window dockbar may be created";
		instance.dockbar = d;
	}

	public static function getFullScreenBounds() : hxwidgets.Rectangle {
		var x : Float = 0;
		var y : Float = 0;
		var w : Float = instance.maximumSize.width;
		var h : Float = instance.maximumSize.height;
		if(instance.dockbar != null) {
			var dockbar = instance.dockbar;
			switch(dockbar.orientation) {
			case NORTH:
				y += dockbar.width;
				h -= dockbar.height;
			case SOUTH:
				h -= dockbar.height;
			case WEST:
				x += dockbar.width;
				w -= dockbar.width;
			case EAST:
				w -= dockbar.width;
			}
		}
		return new hxwidgets.Rectangle(x,y,w,h);
	}

	public static function destroy(win:Window) :Void
	{
		win.destroy();
	}

	public static function findByHandle(hnd:Int) : Window
	{
		return instance.windows.get(hnd);
	}

	public static function findByName(name:String) : Window
	{
		for(i in instance.windows) {
			if(i.id == name)
				return i;
		}
		return null;
	}

	public static function getNextHandle() : Int
	{
		instance.nextHandle++;
		return instance.nextHandle;
	}

	public static function minimize(win:Window) : Void
	{
		win.minimize(instance.dockbar);
	}


	public static function defaultSize() : Dimension
	{
		return new Dimension(
			Math.floor(instance.maximumSize.width/3),
			Math.floor(instance.maximumSize.height/3)
		);
	}

	public static function defaultPosition(?s:Dimension) : Point
	{
		if(s == null)
			s = new Dimension(0,0);
		return new Point(
			Math.floor(instance.maximumSize.width/2 - s.width/2),
			Math.floor(instance.maximumSize.height/2 - s.height/2)
		);
	}

	/**
		Called by the Window constructor. Do not call directly.
	**/
	private function registerWindow(win:Window) {
		var h = getNextHandle();
		Reflect.setField(win,"hnd",h);
		instance.windows.set(h, win);
	}

	/**
		Called from Window.destroy when window is finished destroying itself.
	**/
	private function unregisterWindow(win:Window) {
		if(win == null)
			return;
		for(i in instance.windows.keys()) {
			if(instance.windows.get(i) == win) {
				instance.windows.remove(i);
			}
		}
		if(instance.dockbar != null)
			instance.dockbar.remove(win);
	}
}
