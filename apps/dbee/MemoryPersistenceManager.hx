/*
 *	Copyright (c) 2008, The Caffeine-hx project contributors
 *	Original author: Danny Wilson from deCube.net
 *	Contributors:
 *	This program is free software; you can redistribute it and/or modify
 *	it under the terms of the GNU General Public License as published by
 *	the Free Software Foundation; either version 2 of the License, or
 *	(at your option) any later version.
 *	
 *	This program is distributed in the hope that it will be useful,
 *	but WITHOUT ANY WARRANTY; without even the implied warranty of
 *	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *	GNU General Public License for more details.
 */
package dbee;
 import dbee.Configuration; // Makes sure the typemap is initialized before this class
 import dbee.Error;

/** 
	A PersistentObject implementation where the data is kept in memory and all changes are written to a transaction log on disk.
**/
class MemoryPersistenceManager<ObjectType:PersistentObject> implements PersistenceManager<ObjectType>
{
	// -------------------
	// Transaction Log API
	// -------------------
	public static var defaultLogger : neko.io.Output;
	
	public static function loadTransactionLog( i:neko.io.Input )
	{
		var managerMap = dbee.Configuration.persistenceManager.tableMapping;
		if(managerMap == null || Lambda.count(managerMap) < 1)
			throw TransactionLogReaderError.ManagerMapConfiguration;
		
		var prev;
		var char;
		var sbuf = new StringBuf();
		var delete = false;
		var deleteModel;
		
		var manager:PersistenceManager<Dynamic>;
		
		var reset = function(){
			prev = null;
			manager = null;
			sbuf = new StringBuf();
			delete = false;
			deleteModel = null;
		}
		var parseInt = Std.parseInt;
		
		while(true) try
		{
			prev = char;
			char = i.readChar();
			
			if(char == 255)
			{
				// Reached end of block
				if(prev == 255)
				{
					if(delete){
						var s = sbuf.toString();
						//s = s.substr(1, s.length-2);
					//	trace('\n\n DELETE MODEL '+deleteModel+' - '+s+'\n\n');
						managerMap.get(deleteModel).delete(parseInt(s));
					}
					else {
				//		sbuf.addChar(255);
						var s = sbuf.toString();
					//	trace('\n\n DESERIALIZE '+s+'\n\n');
						var o:PersistentObject = manager.deSerialize( s );
						if( o._oid > manager.lastInsertID ) manager.lastInsertID = o._oid;
					}
					
					// reset statevars
					reset();
				}
				// First block
				else if(manager == null)
				{
					var s = sbuf.toString();
				//	trace('\n\n'+s+'\n\n');
					if( delete && deleteModel == null ) {
						deleteModel = s.substr(1); /* Skip X char */
						sbuf = new StringBuf();
					}
					if(s.length == 1 && s.charCodeAt(0) == 88 /* X */)
						delete = true;
					else {
						manager = managerMap.get(s);
						if(!delete) sbuf.addChar(255);
					}
				}
				else sbuf.addChar(char);
			}
			else sbuf.addChar(char);
		}
		catch(e:neko.io.Eof){ break; };
	}
	
	// -------------------
	// --- Manager API ---
	// -------------------
	public var objectClass					: Class<ObjectType>;
	public var objectTableID				: String;
	public var objectVersion(default,null)	: Int;
	public var objectFields					: Array<String>;
	/** Last ID of inserted Object ID. 0 means no objects inserted. **/
	public var lastInsertID					: Int;
	
	/** Neko Hashtable **/
	private var storage						: Dynamic;
	private var newObject					: ObjectType;
	private var logger						: neko.io.Output;
	
	/** Pre-hashed compact version of objectFields **/
	private var h_fields					: Array<Int>;
	/** For speeding up stuff like s.indexOf(String.fromCharCode(255)); **/
	private var char255						: String;
	
	public function new(objectClass:Class<ObjectType>, tableID:String)
	{
		if(tableID == null) throw dbee.PersistenceManagerError.NoTableIDGiven(Type.getClassName(objectClass));
		var managerMap = dbee.Configuration.persistenceManager.tableMapping;
		if(managerMap.exists(tableID)) throw dbee.PersistenceManagerError.TableIDTaken(tableID);
		managerMap.set(tableID, cast this);
		
		this.objectTableID	= tableID;
		this.objectClass	= objectClass;
		this.objectVersion	= untyped objectClass.version;
		if( !(objectVersion > 0) )
			throw throw dbee.PersistenceManagerError.UnversionedClass(Type.getClassName(objectClass));
		
		newObject = Type.createInstance(objectClass,[]); // Initializes the class if needed
		newObject._manager = cast this;
		untyped newObject._oid = 0;
		objectFields = newObject._fields;
		
		// Init Hashtable storage stuff
		storage  = untyped __dollar__hnew(0);
		h_fields = untyped __dollar__amake( objectFields.length );
		for(f in 0 ... objectFields.length) h_fields[f] = untyped __dollar__hash(objectFields[f].__s);
		
		var className = Type.getClassName(objectClass);
		var loader = neko.vm.Loader.local();
		var m;
		// Only generate code if not allready done for this ObjectType
		if( (m = loader.getCache().get(className)) == null )
		{
			var code = { prepareObject:"", copyFields:"", getFields:"", setChangedFields:"", setAllFields:"", arraySize:objectFields.length };
			
			// Generate copying body
			var f_id = 0;
			for(f in Reflect.fields(newObject))
			{
				if( f == '_manager' ) continue;
				
				var field = Reflect.field(newObject, f);
				if( field != null ) {
					
					if( new String(field) == field 
					 || Reflect.hasField(field, '__a')
					 || Reflect.isObject(field) && !Std.is(field, dbee.ObjectField) )
						throw Error.ModelDefinition("The new() constructor of class "+Type.getClassName(objectClass)+" is too complicated and will impact performance severely."+
							" Please only set numbers, booleans and objects implementing dbee.ObjectField");
					
					if( Reflect.isObject(field) ) {
						code.prepareObject += "var f"+f_id+" = m."+f+'; \n\t';
						code.copyFields += "o."+f+" = $new(f"+(f_id++)+");\n\t\t";
					}
				//	else
				//		code.copyFields += "o."+f+" = f"+(f_id++)+",\n\t\t\t";
					
					// Delete field in newObject so it wont be copied unessaserily
					// Reflect.setField(newObject, f, null);
				}
			}
			// Strip first comma
		//	code.prepareObject = code.prepareObject.substr(2);
			
			// Generate get function body
			for(f in 0 ... objectFields.length)
				code.getFields += "if(s["+f+"] != null) o."+objectFields[f]+"._v = s["+f+"];\n\t\t";
			// Generate set function body
			for(f in 0 ... objectFields.length) {
				code.setAllFields += "a["+f+"] = o."+objectFields[f]+".serialize();\n\t\t\t";
				code.setChangedFields += "if( (f=o."+objectFields[f]+").changed) a["+f+"] = f.serialize();\n\t\t\t";
			}
			
			// Generate code using template resource
			var nekoml = new haxe.Template(Std.resource("MemoryPersistenceMacro.neko")).execute(code);
			// trace(nekoml.toString());
			
			// TODO: Change to tmp file?
			// TODO: Further loader improvements, Madrok help me out :-)
			var f = neko.io.File.write(className+".neko",false);
			f.write(nekoml.toString()); f.close();
		//	trace(nekoml.toString());
			
			var comp = new neko.io.Process("nekoc", [className+".neko", "-o", neko.Sys.getCwd()]);
		//	trace(comp.stdout.readAll());
			comp.exitCode();
			m = neko.vm.Module.readPath(className+".n", [neko.Sys.getCwd()], loader);
			m.execute();
			loader.setCache(className,m);
		}
		this.get = this.getH = m.getExports().get("makeGetter")(storage, newObject);
		this.setH = m.getExports().get("makeSetter")(storage);
		
		// Set default logger
		logger = defaultLogger;
		lastInsertID = 0;
		
		if(char255 == null)
			untyped Type.getClass(this).prototype.char255 = String.fromCharCode(255);
	}
	
	// Generated function to set serialized data in Hashtable
	private var getH : Int->ObjectType;
	private var setH : ObjectType->Bool->Array<String>;
	
	public function save(object:ObjectType) : Void
	{
//		TODO: This check should be way before calling save()
//		----------------------------------------------------
//		if(logger == null) throw LoggerError.NoWriterConfigured(here.className+"<"+Type.getClassName(objectClass)+">");
		if(object._oid == null) untyped object._oid = ++lastInsertID;
		var changes = setH(object,true);
		logger.write( serialize(object, changes) );
	}
	
	public function delete(oid:Int) : Void
	{
		if(oid == null) return;
		var s = new StringBuf();
		var C = s.addChar;
		C(88); // X
		C(255);
		s.add(objectTableID);
		C(255);
		s.add(oid);
		C(255);
		C(255);
		logger.write(s.toString());
		untyped __dollar__hremove(storage, oid, null);
	}
	
	/** Get object by ID. If the object does not exist, a new one is returned with the ID allready set. **/
	public function get(oid) : ObjectType {
		return null; // This function is overridden on new()
	}
	
	public function exists(oid) : Bool
	{
		return untyped __dollar__hmem(storage,oid,null);
	}
	
	/** Optimized for neko speed as you can probably see. **/
	private function fieldValuesMatchObject(fieldHashes:Array<Int>, fieldH_len:Int, fieldsValues:Dynamic, object:ObjectType):Bool
	{
		for( f in 0 ... fieldH_len ) untyped {
			if( !__dollar__objget(object, fieldHashes[f])
				.equals(__dollar__objget(fieldsValues, fieldHashes[f])) ) return false;
		}
		return true;
	}
	
	/** TODO: Make it a multithreaded find? **/
	public function findFirst(fieldsValues:Dynamic) : Null<ObjectType>
	{
		var fields = Reflect.fields(fieldsValues);
		var hashes = untyped __dollar__amake( fields.length );
		for( f in 0 ... fields.length )
			hashes[f] = untyped __dollar__hash(fields[f].__s);
		
		var hasFields = callback(this.fieldValuesMatchObject, hashes, fields.length, fieldsValues);
		fields = null;
		
		var getH = this.getH;
		var result;
		var matcher = function(key,val){
			if(result != null) return;
			var obj = getH(key);
			if( hasFields(obj) ) result = obj;
		}
		untyped __dollar__hiter(storage, matcher);
		
		return result;
	}
	
	/** TODO: Make it a multithreaded find? **/
	public function find(fieldsValues:Dynamic) : List<ObjectType>
	{
		var fields = Reflect.fields(fieldsValues);
		var hashes = untyped __dollar__amake( fields.length );
		for( f in 0 ... fields.length )
			hashes[f] = untyped __dollar__hash(fields[f].__s);
		
		var hasFields = callback(this.fieldValuesMatchObject, hashes, fields.length, fieldsValues);
		fields = null;
		
		var getH = this.getH;
		var results = new List();
		var matcher = function(key,val){
			var obj = getH(key);
			if( hasFields(obj) ) results.add(obj);
		}
		untyped __dollar__hiter(storage, matcher);
		
		return results;
	}
	
	/** TODO: Make it a multithreaded select **/
	public function select(func:ObjectType->Bool) : Null<List<ObjectType>>
	{
		var getH = this.getH;
		var results = new List();
		var matcher = function(key,val){
			var obj = getH(key);
			if( func(obj) ) results.add(obj);
		}
		untyped __dollar__hiter(storage, matcher);
		
		return results;
	}
	
/*	public function getAll()
	{
		return storage.iterator();
	}
*/	
	/** TODO: Multithread: Serialize Datafields in parallel and merge at the end **/
	public function serialize( object:ObjectType, ?serializedChangedFields:Array<String> ) : String
	{
		if(object._oid == null) throw Error.NoObjectID(object);
		var s = new StringBuf();
		var C = s.addChar;
		
		s.add(objectTableID);
		C(255);
		this.addPositiveIntAsCharCodes(objectVersion, s, object);
		C(255);
		s.add(object._oid);
		C(255);
		
		var of = objectFields;
		var oh = h_fields;
		var field : Dynamic;
		
		if( serializedChangedFields == null ) for(f in 0 ... of.length) {
			s.add(of[f]);
			C(255);
			field = untyped __dollar__objget(object, oh[f]);
			s.add( if(field._escMe) escapeChar255(field.serialize()) else field.serialize() );
			C(255);
		}
		else for(f in 0 ... of.length) if(untyped __dollar__objget(object, oh[f]).changed) {
			s.add(of[f]);
			C(255);
			field = untyped __dollar__objget(object, oh[f]);
			s.add( if(field._escMe) escapeChar255(new String(serializedChangedFields[f])) else serializedChangedFields[f] );
			C(255);
		}
		C(255);
		return s.toString();
	}
	
	private function escapeChar255(s:String)
	{
		if(s.indexOf(char255) == -1) return s;
		
		var sbuf;
		var addC;
		var code:Int;
		for(i in 0 ... s.length)
		{
			switch( (code = s.charCodeAt(i)) )
			{
				case 255:
					if(sbuf == null) {
						sbuf = new StringBuf();
						sbuf.add( s.substr(0,i) );
						addC = sbuf.addChar;
					}
					addC(1);
					addC(254);
				case 1:
					if(sbuf == null) {
						sbuf = new StringBuf();
						sbuf.add( s.substr(0,i) );
						addC = sbuf.addChar;
					}
					addC(1);
					addC(1);
				default:
					if(sbuf != null) addC(code);
			}
		}
		
		return sbuf.toString();
	}
	
	private function unescapeChar255(s:String)
	{
		if(s.indexOf(char255) > -1) return s;
		
		var sbuf;
		var addC;
		var code:Int;
		
		var len = s.length, i=0;
		do {
			code = s.charCodeAt(i);
			if( code == 1 ) switch(s.charCodeAt(i+1))
			{
				case 1:
					if(sbuf == null) {
						sbuf = new StringBuf();
						sbuf.add( s.substr(0,i) );
						addC = sbuf.addChar;
					}
					sbuf.addChar(1);
					++i; // Skip next char
				case 254:
					if(sbuf == null) {
						sbuf = new StringBuf();
						sbuf.add( s.substr(0,i) );
						addC = sbuf.addChar;
					}
					sbuf.addChar(255);
					++i; // Skip next char
				default:
					// Reaching this code means, the string doesnt need any unescaping
					return s;
			}
			else if(sbuf != null) addC(code);
			
		} while(++i < len);
		
		return sbuf.toString();
	}
	
	private function addPositiveIntAsCharCodes(i:Int,s:StringBuf,obj):Void
	{
		do {
			if( i > 254 ) {
				s.addChar(254);
				i -= 254;
			}
			else {
				s.addChar(i);
				break;
			}
		} while(i > 0);
	}
	
	private function sumCharCodes(s:String):Int
	{
		var r = 0;	
		for(x in 0 ... s.length) r += s.charCodeAt(x);
		return r;
	}
	
	/** De-serializes the given string, sets the object in memory and return the object. **/
	public function deSerialize( s:String ) : ObjectType
	{
		var ver;
		var blocks = s.split( String.fromCharCode(255) );
		var upgradeData:Dynamic;
		
		// Check if data needs upgrade
		ver = sumCharCodes(blocks[1]);
		if(objectVersion > ver) upgradeData = Reflect.empty();
		else if(objectVersion < ver) throw DeSerializerError.CannotDowngrade(ver, objectVersion, objectTableID);
		
		var obj = getH( Std.parseInt(blocks[2]) );
		var b;
		var i = 3;
		var l = blocks.length;
		blocks = untyped blocks.__a;
		
		if(upgradeData != null)
		{
			var set = Reflect.setField;
			do {
				b = blocks[i];
				if(b.length == 0) break;
				set(upgradeData, b, blocks[++i]);
			}
			while(++i < l);
			
			untyped obj.upgradeObject(ver, upgradeData);
		}
		else do {
			b = blocks[i];
			if(b == null || b.length == 0) break;
			untyped __dollar__objget(obj,__dollar__hash(b.__s)).deSerialize(blocks[++i]);
		}
		while(++i < l);
		
		setH(obj,false);
		return obj;
		
	/*
		// Multithreaded deserializing
		var t=0;
		var th=fieldDeSerializeThreads;
		do {
			b = blocks[i];
			if(b.length == 0) break;
			th[t++].sendMessage({b1 : untyped b.__s, b2:blocks[++i], obj:obj});
			if(t == 4) t=0;
			//untyped __dollar__objget(obj,__dollar__hash(b.__s)).deSerialize(blocks[++i]);
		}
		while(++i < l);
	*/
	}
}
