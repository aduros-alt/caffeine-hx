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

interface PersistenceManager<ObjectType:PersistentObject>
{
	public var lastInsertID							: Int;
	public var objectClass							: Class<ObjectType>;
	public var objectTableID						: String;
	public var objectVersion(default,null)			: Int;
	public var objectFields							: Array<String>;
	
	public function save(object:ObjectType)			: Void;
	public function delete(oid:Int)					: Void;
	
	public function get(oid:Int)					: Null<ObjectType>;
	public function exists(oid:Int)					: Bool;
	public function findFirst(fieldsValues:Dynamic)	: Null<ObjectType>;
	public function find(fieldsValues:Dynamic)		: List<ObjectType>;
	public function select(func:ObjectType->Bool)	: List<ObjectType>;
	
	public function serialize(object:ObjectType, ?serializedChangedFields:Array<String>)	: String;
	public function deSerialize(s:String)			: ObjectType;
	
//	public function events()						: PersistenceManagerEvents;
}

/*
 import hxbase.event.Event;
class PersistenceManagerEvents extends BasicEventGroup
{
	var save
	var load
}
*/
