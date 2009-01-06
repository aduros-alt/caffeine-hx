/*
 * Copyright (c) 2009, The Caffeine-HX Project Contributors
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
 *
 * Author:
 *  Danny Wilson - deCube.net
 * Based on:
 *  http://xinf.org event code
 */

package event;

class ShiftCtrlAltMod
{
	private static inline var SHIFT	= 1;
	private static inline var CTRL	= 2;
	private static inline var ALT		= 4;
	
	private var mod : Int;
	
	public var shiftMod(shift,null)	: Bool;
	public var ctrlMod(ctrl,null)		: Bool;
	public var altMod(alt,null)		: Bool;
	
	private inline function shift() { return mod & SHIFT	> 0; }
	private inline function ctrl()  { return mod & CTRL	> 0; }
	private inline function alt()   { return mod & ALT	> 0; }
	
	public function new(shiftMod:Bool, ctrlMod:Bool, altMod:Bool)
	{
		if(shiftMod)	this.mod = SHIFT;
		if(ctrlMod)	this.mod = mod | CTRL;
		if(altMod)	this.mod = mod | ALT;
	}
}
