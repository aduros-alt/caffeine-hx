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
 * THIS SOFTWARE IS PROVIDED BY THE HAXE PROJECT CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE HAXE PROJECT CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */

package gd;

import neko.io.File;

enum GdImageHandle {
}

class Image {
	var __img : GdImageHandle;

	function new() {}

	public static function create(width: Int, height : Int) {
		var i = new Image();
		i.__img = gdImgCreate(width, height);
	}

/*
	public static function createFromGif(fi : neko.io.FileInput) {
		var i = new Image();
		var fh : { private var __f : FileHandle; } = fi;
		i.__img = gdImgCreateFromGif(fi);
	}
*/

	public static function createFromJpeg(fi : neko.io.FileInput) {
		var i = new Image();
		// this trick lets you get at the private FileHandle from the
		// FileInput
		var fh : { private var __f : FileHandle; } = fi;
		i.__img = gdImgCreateFromJpeg(fh.__f);
	}

	private static var gdImgCreate = neko.Lib.load("gd","gdImgCreate",2);
	//private static var gdImgCreateFromGif = neko.Lib.load("gd","gdImgCreateFromGif",1);
	private static var gdImgCreateFromJpeg = neko.Lib.load("gd","gdImgCreateFromJpeg",1);
}