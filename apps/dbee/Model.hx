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
 import dbee.field.Datafield;

class Model implements PersistentObject, implements haxe.rtti.Infos, implements haxe.Public
{
#if flash9
	/** Used for RTTI cache **/
	private static var fieldCache = new IntHash<Array<String>>();
	/** Used for RTTI cache **/
	private static var modelCount = 0;
#end
	private var __class__:Class<PersistentObject>;
	
	/** Global unique Object ID **/
	public var _oid(default,null):Int;
	/** True when all required fields are properly filled. **/
	public var _isValid(validate,null):Bool;
	/** String array of all Datafields in this model **/
	public var _fields(default,null):Array<String>;
	/** Used to resolve what manager to use for this object. **/
	public var _tableID : String;
#if neko
	/** Which manager this object delegates saves and deletes to. **/
	public var _manager:PersistenceManager<PersistentObject>;
	
	/** @abstract Used to upgrade old serialized objects to the current version. **/
	public function upgradeObject(version:Int, fields:Dynamic) : Void {
		throw "not implemented";
	}
#end
	
	private function validate():Bool
	{	
		for(f in _fields) if(!getField(f).isValid) return false;
		return true;
	}
	
	/** @abstract Give the empty or invalid fields their default values **/
	private function applyDefaults() {
		throw "not implemented";
	}
	
	/** @abstract In here you specify all your field constraints. **/
	private function defineModel() {
		throw "not implemented";
	}
	
	public function getField( name:String ) : Datafield {
		return Reflect.field(this, name);
	}
	
	private function new()
	{
		defineModel();
		
		// Build sort and cache fields array
	#if flash9
		if(__class__ == null) __class__ = Type.getClass(this);
		if( untyped __class__.__mID > 0 )
			_fields = fieldCache.get(untyped __class__.__mID);
		else
		{
			_fields = [];
	#else true
		if(_fields == null) 
		{
			var cl:Dynamic = __class__; //Type.getClass(this);
			cl.prototype._fields = [];
	#end
		#if neko
			if(!(cl.version > 0))
				throw Type.getClassName(cl)+": Model must be versioned! Example: static var version = 1;";
		#end
			for(x in Xml.parse(cl.__rtti).firstChild()) if(x.nodeType == Xml.Element)
			{
				var fe = x.firstElement();
				if( fe != null && fe.nodeName == 'c' && fe.exists('path') ){
					var n = fe.get('path');
					if( implementsObjectField(n) )
						_fields.push(x.nodeName);
				}
			}
			
			// Sort so that required fields get pushed to the front
			var me = this;
			var rf = function(f){ return Reflect.field(me, f); };
			
			_fields.sort(function(x,y){
				var a:Datafield = rf(x), b:Datafield = rf(y);
				if( a == b ) return 0;
				if( a.required  && !b.required ) return -1;
				if( a.required  && b.required )  return  0;
				if( !a.required && b.required )  return  1;
				return 0;
			});
			
		#if flash9 
			fieldCache.set( untyped __class__.__mID = ++modelCount, _fields );
		#end
		}
		// End fields array
		
	//	for(f in _fields) getField(f).onChanged.bind(this, onDataChanged.call);
	}
	
	private function implementsObjectField( className : String )
	{
		var tempInstance = try Type.createEmptyInstance(Type.resolveClass(className)) catch(e:Dynamic) return false;
		return tempInstance != null && Std.is(tempInstance, dbee.ObjectField);
	}
	
#if neko
	// ----------------------
	//  PersistentObject API
	// ----------------------
	
	public function save()
	{
		if(_manager == null && _tableID == null)
			throw dbee.Error.NoTableID(this);
		else if(_manager == null)
			_manager = dbee.Configuration.persistenceManager.tableMapping.get(_tableID);
		
		if(!_isValid) applyDefaults();
		if(!_isValid) throw dbee.Error.InvalidObjectData(cast __class__, this);
		_manager.save(this);
	}
	
	public function delete()
	{
		_manager.delete(this._oid);
	}
	
#end
}
