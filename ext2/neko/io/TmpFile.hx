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


package neko.io;
import neko.io.File;

/**
	Create a temporary disk file that will be deleted automatically when
	the class is garbage collected.
**/
class TmpFile {
	private var fi : FileInput;
	private var fo : FileOutput;
	private var __f : FileHandle;

	/**
		Create a new TmpFile, which will be ready for io when the constructor returns.
	**/
	public function new() : Void {
		__f = untyped tmpfile_open();
		fi = new FileInput(__f);
		fo = new FileOutput(__f);
	}

	/**
		Once a TmpFile is closed, it can no longer be used. There is
		no need to call this function, as it will be done automatically.
	**/
	public function close() : Void {
		untyped tmpfile_close(__f);
	}

	/**
		Get the FileInput handle
	**/
	public function getInput() : FileInput {
		return fi;
	}

	/**
		Get the FileOutput handle
	**/
	public function getOutput() : FileOutput {
		return fo;
	}

	private static var tmpfile_open = neko.Lib.load("fileext","tmpfile_open",0);
	private static var tmpfile_close = neko.Lib.load("fileext", "tmpfile_close", 1);
}