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
import flash.display.Sprite;


class AssetContainer extends Container {
	var asset : DisplayObject;

	public var assetWidth(default,null) : Float;
	public var assetHeight(default,null) : Float;
	var assetVisible : Bool;
	var assetLoaded : Bool;
	var assetOriginalScaleX : Float;
	var assetOriginalScaleY : Float;

	public function new() {
		super("");
		asset = null;

		assetLoaded = false;
		assetVisible = true;
	}

	public function setAsset(newasset:DisplayObject) {
		if(newasset != asset) {
			if(asset != null) {
				if(asset.parent == _mc)
					_mc.removeChild(asset);
			}
			asset = newasset;
			if(asset != null) {
				_mc.addChild(asset);
			}
			setLoaded(asset != null);
			resetAsset();
		}
	}

	public function clearAsset() {
		setAsset(null);
	}

	public function getAsset() {
		return asset;
	}

	private function setAssetOriginalSize(w:Float,h:Float) {
		//trace(here.methodName + " " + w );
		assetWidth = w;
		assetHeight = h;
	}

	private function setLoaded(b:Bool) {
		assetLoaded = b;
	}

	private function resetAsset() : Void {
		if (asset != null){
			asset.visible = assetVisible;
		}
	}

	override public function setSkin(obj:Dynamic) {}
}