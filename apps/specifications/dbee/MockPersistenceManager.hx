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
package specifications.dbee;

class MockPersistenceManager implements dbee.PersistenceManager<dbee.PersistentObject>
{
	public var objectClass:Class<dbee.PersistentObject>;
	public var objectFields:Array<String>;
	public var objectVersion:Int;
	public var objectTableID:String;
	public var appliedOIDtoObject:Bool;
	public var hasSaved:Bool;
	public var hasDeleted:Bool;
	public var lastInsertID:Int;
	
	private var storage:IntHash<dbee.PersistentObject>;
	
	public function new() {
		storage = new IntHash();
		lastInsertID  = 0;
		objectVersion = 1;
		objectTableID = "MockObject";
		dbee.Configuration.persistenceManager.tableMapping.set("MockObject", this);
		this.appliedOIDtoObject = this.hasSaved = this.hasDeleted = false;
	}
	
	public function save(obj:dbee.PersistentObject) {
		this.hasSaved = true;
		if(obj._oid == null) {
			untyped obj._oid = ++lastInsertID;
			this.appliedOIDtoObject = true;
		}
		storage.set(obj._oid, obj);
	}
	
	public function get(o){
		return storage.get(o);
	}
	
	public function delete(oid) {
		this.hasDeleted = true;
	}
	
	public function exists(o){			return false;	}
	public function find(o){			return null;	}
	public function findFirst(o){		return null;	}
	public function select(o){			return null;	}
	public function serialize(o,?c){	return null;	}
	public function deSerialize(o){		return null;	}
}
