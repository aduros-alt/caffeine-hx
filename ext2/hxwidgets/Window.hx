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

import hxwidgets.events.WindowEvent;

private class WindowBarBackground extends Component {
	var win : Window;
	var wb : WindowBar;
	public function new(win:Window, wb:WindowBar) {
		super("");
		this.win = win;
		this.wb = wb;
		subscribeEvent(flash.events.MouseEvent.MOUSE_DOWN, onBarPress);
		subscribeEvent(flash.events.MouseEvent.MOUSE_UP, onBarRelease);
	}
	override public function getUIClassName() { return "WindowBarBackground"; }
	override public function setUI(obj:Dynamic) {
	}

	function onBarPress(e) { untyped win.startDrag(false); }
	function onBarRelease(e) { untyped win.stopDrag(); }
}

private class WindowBar extends Component {
	public var title(default,setTitle) : String;
	var win : Window;
	var sprBackground : WindowBarBackground;
	var sprTitle : Label;
	var sprIcon : BitmapAsset;
	var sprMinimize : BitmapAsset;
	var sprFullscreen : BitmapAsset;
	var sprRestore : BitmapAsset;
	var sprClose : BitmapAsset;

	public function new(win:Window) {
		super("");
		this.win = win;
		sprBackground = new WindowBarBackground(win, this);
	}

	override public function getUIClassName() { return "WindowBar"; }

	override public function setUI(obj:Dynamic) {
		sprIcon = obj.sprIcon;
		sprMinimize = obj.sprMinimize;
		sprFullscreen = obj.sprFullscreen;
		sprRestore = obj.sprRestore;
		sprClose = obj.sprClose;
	}

	function setTitle(v:String) {
		sprTitle.text = v;
		return v;
	}

	function onIconClick(e) {}
	function onMinimizeClick(e) { win.minimize(); }
	function onFullscreenClick(e) { win.fullscreen(); }
	function onRestoreClick(e) { win.restore(); }
	function onCloseClick(e) { win.destroy(); }


	override public function onRepaint() {
		sprBackground.setPreferedSize( new Dimension(win.width, win.height));
	}
}

class Window extends Component {
	public var name(default,null) : String;
	/** the window handle **/
	public var hnd(default,null) : Null<Int>;
	public var title(default,setTitle) : String;

	var windowBar : WindowBar;
	var shaded : Bool;
	var maximized : Bool;
	var minimized : Bool;
	// usually the same as minimized, unless there is no dockbar
	var docked : Bool;
	var dockbar : Dockbar;
	var modal : Bool;



	public function new(id:String, modal:Bool) {
		super(id);
		hnd = null;
		this.modal = modal;
		untyped WindowManager.instance.registerWindow(this);
		windowBar = new WindowBar(this);
	}

	override public function destroy() {
		var e = new WindowEvent(WindowEvent.CLOSING, this, false, true);
		// Window closing can be prevented with the preventDefault()
		// method of the WindowEvent.
		if(!dispatchEvent(e)) {
			return;
		}
		var i = WindowManager.instance;
		untyped i.unregisterWindow(this);
		super.destroy();
		dispatchEvent(new WindowEvent(WindowEvent.DESTROYED, this));
	}

	/**
		Minimize the window, either to a docking bar if one exists, or
		to an icon.
	**/
	public function minimize(?d:Dockbar) {
		if(minimized)
			return;
		// Window minimizing can be prevented with the preventDefault()
		// method of the WindowEvent.
		if(!dispatchEvent(new WindowEvent(WindowEvent.MINIMIZING, this, false, true)))
			return;
		minimized = true;
		if(d == null)
			d = untyped WindowManager.instance.dockbar;
		if(d != null) {
			d.startDock(this);
			docked = true;
			dockbar = d;
		}
		else {
		}

	}

	public function restore() {
		if(minimized || maximized) {
			setPosition(lastPosition);
			setSize(lastSize);
			dispatchEvent(new WindowEvent(WindowEvent.RESTORED, this));
		}
	}

	public function fullscreen() {
		if(maximized)
			return;
		maximized = true;
		setComponentBounds(WindowManager.getFullScreenBounds());
		dispatchEvent(new WindowEvent(WindowEvent.MAXIMIZED, this));
	}

	function setTitle(v:String) {
		title = v;
		if(windowBar != null) {
			windowBar.title = v;
		}
		return v;
	}
}