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

class MockPersistentObject implements dbee.PersistentObject
{
	static var version = 10;
	
	static function __init__()
	{
		untyped {
			MockPersistentObject.prototype._fields = ['df_1','df_2'];
		}
	}
	
	public var df_1 : MockDatafield;
	public var df_2 : MockDatafield;
	
	public var arrayTest:Array<String>;
	public var stringTest:String;
	public var nrTest:Int;
	public var objTest:Dynamic;
	
	public function new()
	{
	//	objTest = { dit:{moet:'zo'} };
	//	arrayTest = ['1','2','drie'];
	//	stringTest = 'Sjaak';
		nrTest = 100;
		
		df_1 = new MockDatafield();
		df_2 = new MockDatafield();
		upgradeWasHandled = false;
	}
	
	var __class__  		: Class<dbee.PersistentObject>;
	public var _manager	: dbee.PersistenceManager<dbee.PersistentObject>;
	
	public var _oid		: Int;
	public var _fields	: Array<String>;
	
	public function delete(){
		if(_manager == null) _manager = dbee.Configuration.persistenceManager.tableMapping.get('MockObject'); 
		_manager.delete(this._oid);
	}
	
	public function save(){
		if(_manager == null) _manager = dbee.Configuration.persistenceManager.tableMapping.get('MockObject');
		_manager.save(this);
	}
	
	public function getField(s){
		// trace('GET GET '+s);
		switch(s){
			case 'df_1': return this.df_1;
			case 'df_2': return this.df_2;
		}
		return null;
	}
	
	public var upgradeWasHandled:Bool;
	
	public function upgradeObject(version:Int, fields:Dynamic) : Void
	{
	//	trace('UPGRADE FROM VERSION: '+version);
		upgradeWasHandled = true;
	}
}
