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
import flash.display.DisplayObject;

class LibraryAsset extends AssetContainer {
	var linkageName(default,setLinkage) : String;
	var applicationDomain(default,setApplicationDomain) : ApplicationDomain;

	public function new(linkage:String, ?appDomain:ApplicationDomain)
	{
		super();
		Reflect.setField(this,"linkageName",linkage);
		Reflect.setField(this,"applicationDomain", appDomain);
		if(applicationDomain == null) applicationDomain = ApplicationDomain.currentDomain;
		setAsset(createAsset());
	}

	private function setLinkage(linkage:String) {
		if(linkageName != linkage) {
			linkageName = linkage;
			setAsset(createAsset());
		}
		return linkage;
	}

	private function setApplicationDomain(ad:ApplicationDomain) {
		if(applicationDomain != ad) {
			applicationDomain = ad;
			setAsset(createAsset());
		}
		return ad;
	}

	private function createAsset():DisplayObject {
		//trace(here.methodName + " " + linkageName);
		if(linkageName == null)
			return null;
		var classReference:Class<Dynamic> = null;

		if (applicationDomain == null) {
			classReference = Type.resolveClass(linkageName);
		}
		else {
			classReference = Type.toClass(applicationDomain.getDefinition(linkageName));
		}

		if(classReference == null) {
			trace("Could not locate asset class "+linkageName);
			return null;
		}

		var mc:DisplayObject = cast Type.createInstance(classReference,[]);
		if(mc == null) {
			return null;
		}
		setAssetOriginalSize(mc.width, mc.height);
		return mc;
	}
}