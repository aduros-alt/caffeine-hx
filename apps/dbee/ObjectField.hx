/*
 * Copyright (c) 2008, The Caffeine-hx project contributors
 * Original author: Danny Wilson - deCube.net
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
package dbee;

/**
	Abstract Datafield baseclass.
**/
interface ObjectField
{
	/** Serialized version of the data in this object. This variable is usually set by PersistenceManagers. **/
	private var _v : Dynamic;
	
	/** Set to true if the serialize() result contains any characters with charCode 255 **/
	private var _escMe : Bool;
	
	/** Serialize into a compact basic type like: Neko string, Integer, Float or Boolean. It should be ready for storage or transmission. **/
	public function serialize() : Dynamic;
	
	/** @abstract Deserialize String, and set current value to it **/
	public function deSerialize(s:String) : Void;
	
	/** @abstract Check if given data value equals own value. Test for direct equality, Dynamic(String,Int,Float,etc...)-value equality and Datafield equality... **/
	public function equals(data:Dynamic) : Bool;
}
