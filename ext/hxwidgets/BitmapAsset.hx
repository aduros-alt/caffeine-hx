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

import flash.system.ApplicationDomain;
import flash.display.Sprite;
import flash.display.DisplayObject;
import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.geom.Rectangle;
import flash.geom.Point;

enum Position {
	TopLeft;
	TopCenter;
	TopRight;
	LeftCenter;
	Center;
	RightCenter;
	BottomLeft;
	BottomCenter;
	BottomRight;
}

/**
	A bitmap that can have a scale9Grid applied to it.
**/
class BitmapAsset extends LibraryAsset, implements Icon {
	// for scale9Grid
	var sourceRect : Rectangle;
	var bm_tl : Bitmap;
	var bm_tc : Bitmap;
	var bm_tr : Bitmap;
	var bm_lc : Bitmap;
	var bm_c  : Bitmap;
	var bm_rc : Bitmap;
	var bm_bl : Bitmap;
	var bm_bc : Bitmap;
	var bm_br : Bitmap;
	var s9mx : Float;
	var s9my : Float;
	public var lhsWidth(default,null) : Float;
	public var rhsWidth(default,null) : Float;
	public var topHeight(default,null) : Float;
	public var bottomHeight(default,null) : Float;

	public function new(?linkage:String, ?appDomain:ApplicationDomain) {
		super(linkage, appDomain);
	}

	function makeS9Bitmap(pos:Position, data:BitmapData, rect) {
		// the source rectangle area to copy from
		var rx : Float;
		var ry : Float;
		// new destination bitmap width and height
		var dw : Float;
		var dh : Float;

		switch(pos) {
		case TopLeft:
			rx = ry = 0.0;
			dw = lhsWidth;
			dh = rect.y;
		case TopCenter:
			rx = rect.x;
			ry = 0.0;
			dw = rect.width;
			dh = rect.y;
		case TopRight:
			rx = s9mx;
			ry = 0.0;
			dw = rhsWidth;
			dh = rect.y;
		case LeftCenter:
			rx = 0.0; ry = rect.y;
			dw = lhsWidth;
			dh = rect.height;
		case Center:
			rx = lhsWidth; ry = rect.y;
			dw = rect.width;
			dh = rect.height;
		case RightCenter:
			rx = s9mx; ry = rect.y;
			dw = rhsWidth;
			dh = rect.height;
		case BottomLeft:
			rx = 0.0;
			ry = s9my;
			dw = lhsWidth;
			dh = bottomHeight;
		case BottomCenter:
			rx = rect.x;
			ry = s9my;
			dw = rect.width;
			dh = bottomHeight;
		case BottomRight:
			rx = s9mx; ry = s9my;
			dw = rhsWidth;
			dh = bottomHeight;
		}
		var p : Point = new Point(0,0);
		dw = Math.abs(dw);
		dh = Math.abs(dh);
		var r = new Rectangle ( rx, ry, dw, dh );
		var b = new BitmapData(Std.int(dw), Std.int(dh), true);
		b.copyPixels(data, r, p);
		return new Bitmap(b);
	}

	override function getScale9() { return scale9Grid; }

	override function setScale9(rect:Rectangle) {
		//trace(here.methodName);
		scale9Grid = rect;
		var bmd = new BitmapData(Std.int(assetWidth), Std.int(assetHeight), true, 0xFFFFFF);
		bmd.draw(asset);
		var img = bmd.rect;
		sourceRect = new Rectangle(img.x,img.y,img.width,img.height);

		// max X and Y of rect
		s9mx = rect.x+rect.width;
		s9my = rect.y+rect.height;

		// widths of sides are static
		lhsWidth = rect.x;
		rhsWidth = sourceRect.width - rect.width - lhsWidth;
		// height of top and bottom are static
		topHeight = rect.y;
		bottomHeight = sourceRect.height - s9my;


		// No Scaling
		bm_tl = makeS9Bitmap(TopLeft,bmd,rect);
		bm_tr = makeS9Bitmap(TopRight,bmd,rect);
		bm_bl = makeS9Bitmap(BottomLeft,bmd,rect);
		bm_br = makeS9Bitmap(BottomRight,bmd,rect);
		// Scaling
		bm_tc = makeS9Bitmap(TopCenter,bmd,rect);
		bm_lc = makeS9Bitmap(LeftCenter,bmd,rect);
		bm_c  = makeS9Bitmap(Center,bmd,rect);
		bm_rc = makeS9Bitmap(RightCenter,bmd,rect);
		bm_bc = makeS9Bitmap(BottomCenter,bmd,rect);
		clearChildren();
		_mc.addChild(bm_tl); bm_tl.y = 0.0;
		_mc.addChild(bm_tc); bm_tc.x = rect.x;
		_mc.addChild(bm_tr); bm_tr.y = 0.0;

		_mc.addChild(bm_lc); bm_lc.y = rect.y;
		_mc.addChild(bm_c);  bm_c.x = rect.x; bm_c.y = rect.y;
		_mc.addChild(bm_rc); bm_rc.y = rect.y;

		_mc.addChild(bm_bl); bm_bl.x = 0.0;
		_mc.addChild(bm_bc); bm_bc.x = rect.x;
		_mc.addChild(bm_br);
		rescale9(width,height);
		return rect;
	}

	override function setWidth(v:Float) {
		//trace(here.methodName + " " + v);
		rescale(v, height);
		return v;
	}

	override function setHeight(v) {
		rescale(width,v);
		return v;
	}

	override function getScaleX() {
		if(scale9Grid == null)
			return super.getScaleX();
		return assetWidth/width;
	}

	override function setScaleX(v:Float) : Float {
		if(scale9Grid == null)
			return super.setScaleX(v);
		width = v * assetWidth;
		return v;
	}

	override function getScaleY() {
		if(scale9Grid == null)
			return super.getScaleY();
		return assetHeight/height;
	}

	override function setScaleY(v:Float) : Float {
		if(scale9Grid == null)
			return super.setScaleY(v);
		height = v * assetHeight;
		return v;
	}

	function rescale(width:Float,height:Float) {
		if(scale9Grid != null) {
			rescale9(width,height);
		}
		else {
			_mc.width = width;
			_mc.height = height;
		}
	}

	function rescale9(width:Float, height:Float) {
		//trace(here.methodName + " w:"+width);
		var g = scale9Grid;
		var insideWidth = width - (lhsWidth + rhsWidth);
		var insideHeight = height - (topHeight + bottomHeight);
		var by = height - bottomHeight;
		var rx = width - rhsWidth;

		// TopLeft is always at 0,0
		// TopCenter
		bm_tc.width = insideWidth;
		// TopRight
		bm_tr.x = rx;

		// LeftCenter
		bm_lc.height = insideHeight;
		// Center
		bm_c.height = insideHeight;
		bm_c.width = insideWidth;
		// RightCenter
		bm_rc.height = insideHeight;
		bm_rc.x = rx;

		// BottomLeft
		bm_bl.y = by;
		// BottomCenter
		bm_bc.width = insideWidth;
		bm_bc.y = by;
		// BottomRight
		bm_br.x = rx;
		bm_br.y = by;
	}

	/**
		Returns the center area Rectangle. If the object has a scale9Grid
		applied, this will define the inner scaling region.
	**/
	public function getCenterRegion() : flash.geom.Rectangle {
		if(scale9Grid == null) {
			return new Rectangle(0,0,width,height);
		}
		var iw = Math.max(1,width - (lhsWidth + rhsWidth));
		var ih = Math.max(1,height - (topHeight + bottomHeight));
		var ix = Math.max(1,width - rhsWidth - lhsWidth);
		var iy = Math.max(1,height - topHeight- bottomHeight);
		return new Rectangle(ix,iy,iw,ih);
	}

	public function getIconWidth(c:Component) {
		if(Std.is(c,hxwidgets.BaseButton))
			return 16;
		return Std.int(assetWidth);
	}

	public function getIconHeight(c:Component) {
		if(Std.is(c,hxwidgets.BaseButton))
			return 16;
		return Std.int(assetHeight);
	}

	public function getIcon(c:Component) {
		width = getIconWidth(c);
		height = getIconHeight(c);
		return _mc;
	}
}
