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
 import dbee.Error;

/**
	Abstract Datafield baseclass.
**/
class Reference<ForeignObject:PersistentObject> implements dbee.ObjectField
{
	private var _escMe	: Bool;
	/** Serialized version of the reference. This variable is usually set by PersistenceManagers. **/
	private var _v		: Dynamic;
	/** Cached record **/
	private var _r		: ForeignObject;
	/** Object ID of the ForeignObject **/
	public  var oid(default, null) : Int;
	private var manager	: dbee.PersistenceManager<ForeignObject>;
	
	public var tableID(default,setTable)	: String;
		public function setTable(s:String)  : String {
			if(s != null) {
				this.tableID = s;
				manager = cast Configuration.persistenceManager.tableMapping.get(s);
			}
			return s;
		}
	
	/** Getter/Setter for the referenced real object **/
	public var r(getRecord,setRecord) : ForeignObject;
		private function getRecord()
		{
			if(_r != null) return _r;
			
			if(_v != null) {
				deSerialize(new String(_v));
				_v = null;
			}
			else if(tableID == null) throw Error.NoTableID( this );
			
			return _r = manager.get(oid);
		}
		private function setRecord(r:ForeignObject)
		{
			oid = r._oid;
			if(tableID == null) tableID = r._manager.objectTableID;
			if(manager == null) manager = cast r._manager;
			if(manager.objectTableID != tableID)
				throw ReferenceError.WrongTableID(tableID, manager.objectTableID, this);
			
			_r = r;
			return r;
		}
	
	public function new(?tableID:String)
	{
		_escMe = false;
		setTable(tableID);
	}
	
	/** Serialize into a compact (semi-binary)String, ready for storage or transmission. **/
	public function serialize() : Dynamic
	{
		// tableID must be supplied by now
		if(tableID == null) throw Error.NoTableID( this );
		return untyped (tableID +'%'+ oid).__s;
	}
	
	public function deSerialize(s:String)
	{
		var b = s.split('%');
		tableID = b[0];
		oid = Std.parseInt(b[1]);
	}
	
	/** @abstract Check if given data value equals own value. Test for direct equality, Dynamic(String,Int,Float,etc...)-value equality and Datafield equality... **/
	public function equals(data:Dynamic):Bool
	{
		if( Std.string(data) == new String(serialize()) )
			return true;
		
		return false;
	}
}
