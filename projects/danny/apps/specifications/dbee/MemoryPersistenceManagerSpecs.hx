package specifications.dbee;
 import dbee.Error;

class MemoryPersistenceManagerSpecs extends PersistenceManagerSpecs
{
	function before() {
		removeFromMapping();
		try { dbee.MemoryPersistenceManager.defaultLogger = new neko.io.StringOutput();
		this.manager = newPersistenceManager(false);
		} catch(e:Dynamic) trace('\n'+e+'\n'+this.currentTest.method+'\n');
		super.before();
	}
	
	function after() {
		dbee.MemoryPersistenceManager.defaultLogger = null;
		super.after();
	}
	
	function newPersistenceManager(removeManagerFromMappingFirst:Bool):dbee.MemoryPersistenceManager<MockPersistentObject>{
		if(removeManagerFromMappingFirst) removeFromMapping();
		return new dbee.MemoryPersistenceManager<MockPersistentObject>(MockPersistentObject, "MockObject");
	}
	
	function Should_keep_track_of_of_the_PersistentObject_class_version(){
		The(manager.objectVersion).should.not.be._null();
	}
	
	function Should_keep_track_of_of_the_PersistentObject_unique_Model_ID(){
		The(manager.objectTableID).should.not.be._null();
	}
	
	function Should_keep_track_of_the_fields_of_the_PersistentObject_it_is_managing(){
		The(manager.objectFields.length).should.be.greaterThen(0);
	}
	
	function Should_seperate_serialization_parts_by_char_255(){
		po._oid = 88;
		The(manager.serialize(po).split(String.fromCharCode(255)).length).should.be.greaterThen(2);
	}
	
	function Should_have_model_id_in_serialize_string_part_1(){
		po._oid = 88;
		The(manager.serialize(po).split(String.fromCharCode(255))[0]).should.be.equalTo(manager.objectTableID);
	}
	
	function Should_have_model_version_as_series_of_charcodes_in_serialize_string_part_2(){
		po._oid = 88;
		var result = manager.serialize(po).split(String.fromCharCode(255));
		var version = 0;
		for(i in 0 ... result[1].length) version += result[1].charCodeAt(i);
		The( version ).should.be.greaterThen(0);
	}
	
	function Should_throw_UnversionedClass_error_when_instantiating_and_given_class_version_is_null_or_negative(){
		untyped po.__class__.version = null;
		var exceptionWasThrown = false;
		
		try newPersistenceManager(true)
		catch(e:PersistenceManagerError) switch(e){
			default:
			case UnversionedClass( clname ):
				exceptionWasThrown = true;
		}
		The(exceptionWasThrown).should.be._true();
		
		untyped po.__class__.version = -1;
		var exceptionWasThrown = false;
		
		try newPersistenceManager(true)
		catch(e:PersistenceManagerError) switch(e){
			default:
			case UnversionedClass( clname ):
				exceptionWasThrown = true;
		}
		The(exceptionWasThrown).should.be._true();
		
		// Reset version
		untyped po.__class__.version = 10;
	}
	
	function Should_store_changed_fields_in_the_remaining_serialize_parts(){
		po._oid = 88;
		po.df_1.value = 'somevalue_1';
		po.df_2.value = 'somevalue_2';
		var serializeResult = manager.serialize(po);
		The(serializeResult).should.contain.text('somevalue_1');
		The(serializeResult).should.contain.text('somevalue_2');
	}

/*	Something else (config class?) should check the logger is configured, way before any save calls...
	
	function Should_have_a_default_Writer_and_throw_LoggingFailed_error_when_none_is_configured(){
		dbee.MemoryPersistenceManager.defaultLogger = null;
		this.manager = newPersistenceManager(true);
		po._manager = cast this.manager;
		var errorWasThrown = false;
		
		try po.save() catch(e:LoggerError) switch(e) {
			default:
			case NoWriterConfigured(className):
				The(className).should.be.equalTo("dbee.MemoryPersistenceManager<specifications.dbee.MockPersistentObject>");
				errorWasThrown = true;
		}
		The(errorWasThrown).should.be._true();
		
		var l = new neko.io.StringOutput();
		dbee.MemoryPersistenceManager.defaultLogger = l;
		this.manager = newPersistenceManager(true);
		po._manager = cast this.manager;
		po.save();
		var log = l.toString();
		The(log).should.not.be._null();
	}
*/
	/** On save() the object should be serialized into the transaction log file. **/
	function Should_write_PersistentObject_changes_to_the_log(){
		po.df_1.value = 'danny';
		po.save();
		var log = cast(dbee.MemoryPersistenceManager.defaultLogger, neko.io.StringOutput).toString();
		The(log).should.not.be._null();
		The(log).should.contain.text('danny');
	}
	
	/** When an object is to be deleted, it should be marked so in the log. **/
	function Should_write_deletes_to_the_log(){
		po._oid = 1;//'SOME-ID';
		po.delete();
		var log = cast(dbee.MemoryPersistenceManager.defaultLogger, neko.io.StringOutput).toString();
		The(log).should.contain.text("X"+String.fromCharCode(255));
		The(log).should.contain.text(String.fromCharCode(255)+"1");
		The(log).should.contain.text("X"+String.fromCharCode(255)+"MockObject"+String.fromCharCode(255)+"1");
		The(log.substr(-2)).should.be.equalTo(String.fromCharCode(255)+String.fromCharCode(255));
	}
/*	
	function Should_remove_object_when_deserializing_a_delete_command(){
		po._oid = 'SOME-ID';
		po.save();
		Calling(manager.get('SOME-ID')).should._return.equalTo(po);
		po.delete();
		Calling(manager.get('SOME-ID')).should._return._null();
		po.save();
		Calling(manager.get('SOME-ID')).should._return.equalTo(po);
		
		var log = new neko.io.StringOutput();
		dbee.MemoryPersistenceManager.defaultLogger = log;
		po._manager = cast manager = newPersistenceManager();
		po.delete();
		
		manager.deSerialize(log.toString());
		Calling(manager.get('SOME-ID')).should._return._null();
	}
*/	
	/** When the application starts, state should be read back into memory. **/
	function Should_read_back_state_from_a_given_logfile(){
		var oid = po._oid = 1;//'SOME-ID';
		po.df_1.value = 'val1';
		po.save();
		po.df_1.value = 'val2';
		po.save();
		po.delete();
		po.df_1.value = 'val3';
		po.save();
		po = null;
		Calling(manager.get(oid)).should.not._return._null();
		
		var log = cast(dbee.MemoryPersistenceManager.defaultLogger, neko.io.StringOutput).toString();
		var manager = newPersistenceManager(true);
		Calling(manager.exists(oid)).should._return._false();
		
		//untyped dbee.MemoryPersistenceManager.managerMap.set("MockObject", cast manager);
		dbee.MemoryPersistenceManager.loadTransactionLog( new neko.io.StringInput(log) );
		
		Calling(manager.exists(oid)).should._return._true();
		The(manager.get(oid).df_1.value).should.be.equalTo('val3');
	}
	
	function Should_have_highest_found_ID_as_lastInsertID_after_reading_back_state(){
		po._oid = 10;
		po.save();
		po._oid = 1000;
		po.save();
		po._oid = 100;
		po.save();
		
		var log = cast(dbee.MemoryPersistenceManager.defaultLogger, neko.io.StringOutput).toString();
		var manager = newPersistenceManager(true);
		The(manager.lastInsertID).should.be.equalTo(0);
		
		dbee.Configuration.persistenceManager.tableMapping.set("MockObject", cast manager);
		dbee.MemoryPersistenceManager.loadTransactionLog( new neko.io.StringInput(log) );
		
		The(manager.lastInsertID).should.be.equalTo(1000);
	}
	
	function Should_throw_DeserializeError_when_trying_to_read_Transaction_log_with_an_empty_managerMap(){
		untyped dbee.MemoryPersistenceManager.managerMap = new Hash();
		
		var errorWasThrown = false;
		try dbee.MemoryPersistenceManager.loadTransactionLog( new neko.io.StringInput("") )
		catch(e:TransactionLogReaderError) switch(e){
			default:
			case ManagerMapConfiguration:
				errorWasThrown = true;
		}
		The(errorWasThrown).should.be._true();
	}
	
	function Should_PersistentObject_class_in_constructor_to_create_empty_PersistentObject_instances(){
		Calling( newPersistenceManager(true) ).should.not._return._null();
	}
	
	function Should_be_able_to_escape_and_unescape_character_255() {
		var esc = untyped manager.escapeChar255;
		var unesc = untyped manager.unescapeChar255;
		Var(esc).should.not.be._null();
		Var(unesc).should.not.be._null();
		
		var x = String.fromCharCode(255);
		Calling( esc(x+x) ).should.not.contain.text(x);
		Calling( esc('Testing'+x+x+'Testing more'+x+'yay') ).should.not.contain.text(x);
		
		Calling(unesc('Testing'+x+x+'Testing more'+x+'yay')).should.contain.text(x);
		Calling(unesc(esc('Testing'+x+x+'Testing more'+x+'yay'))).should.contain.text(x);
	}
	
	function Should_have_a_writable_PersistentObject_copy_after_get(){
		po._oid = 100;
		po.df_1.value = 'Cool';
		po.save();
		
		var obj1 = manager.get(100);
		var obj2 = manager.get(100);
		
		obj1.upgradeWasHandled = true;
		The(obj1.upgradeWasHandled).should.be.equalTo(true);
		The(obj2.upgradeWasHandled).should.be.equalTo(false);
		
	/*	These fail:
	
		obj1.arrayTest[0] = 'Obj1';
		obj2.arrayTest[0] = 'Obj2';
		The(obj1.arrayTest[0]).should.be.equalTo('Obj1');
		The(obj2.arrayTest[0]).should.be.equalTo('Obj2');
		
		obj1.stringTest = 'Obj1';
		obj2.stringTest = 'Obj2';
		The(obj1.stringTest).should.be.equalTo('Obj1');
		The(obj2.stringTest).should.be.equalTo('Obj2');
		
		obj1.objTest.dit.moet = 'niet';
		obj2.objTest.dit.moet = 'wel';
		The(obj1.objTest.dit.moet).should.be.equalTo('niet');
		The(obj2.objTest.dit.moet).should.be.equalTo('wel');
	*/	
		obj1.nrTest = 10;
		obj2.nrTest = 20;
		The(obj1.nrTest).should.be.equalTo(10);
		The(obj2.nrTest).should.be.equalTo(20);
		
		obj2.df_1.value = 'Awesome';
		The(obj1.df_1.value).should.be.equalTo('Cool');
		The(obj2.df_1.value).should.be.equalTo('Awesome');
	}
	
///*	
	function Should_be_pretty_fast()
	{
		var recordCount = 50000;
		
		untyped manager.logger = neko.io.File.write('transaction.log', true);
		var obj;
		neko.Lib.print(' Writing[');
		var loadStart = neko.Sys.time();
		for(i in 0 ... recordCount)
		{
			if(i % 10000 == 0) neko.Lib.print('=');
			
			obj = new MockPersistentObject();
			obj._manager = cast this.manager;
			obj.df_1.value = 'DF1: This is the first field';
		//	randFill(po.df_1);
			obj.df_2.value = 'DF2: And perhaps this is second?';
		//	randFill(po.df_2);
			obj.save();
			
		//	if( Std.int(Math.random()*3) == 1 )
		//		po.delete();
		}
		var loadEnd = neko.Sys.time();
		
		obj = null;
		neko.Lib.print(' '+(recordCount/(loadEnd-loadStart))+' per second] Reading[');
		var r = Std.random;
		var getStart = neko.Sys.time();
		for(i in 0 ... 500000) {
			if(i % 50000 == 0) neko.Lib.print('>');
			obj = manager.get(10000);
		}
		var getEnd = neko.Sys.time();
		neko.Lib.print(' '+(500000/(getEnd-getStart))+' per second] ');// Waiting...\n');
		//trace(obj._oid+': '+obj.df_1.value);
		//while(true) if(neko.io.File.stdin().readLine().length > 0) break;
		
		The(getEnd-getStart).should.be.lessThen(2);
		The(loadEnd-loadStart).should.be.lessThen(2);
		//trace(untyped dbee.MemoryPersistenceManager.defaultLogger.toString());
	}
// */
}


class ClusteredMemoryPersistenceManagerSpecs extends MemoryPersistenceManagerSpecs
{
	/** Whenever a new object is created, or an existing one updated, the change-data should be sent using multicast over the private cluster network. **/
	function Should_multicast_transactions(){
		
	}
	
	/** When object state changes on a different machine, it should be updated on this machine aswell. **/
	function Should_receive_multicast_transactions(){
		
	}
	
	/** For some reason, the system asks for an object which wasn't pushed to this machine yet. Ask if other machines have it. **/
	function Should_ask_other_nodes_for_nonexisting_objects(){
		
	}
	
	/** When this machine simply can't store the object, it should multicast it with high priority so another machine gets the chance to store it. **/
	function Should_delegate_save_to_different_node_when_memory_limit_is_full(){
		
	}
	
	/** Suppose some object isnt accessed for a day and more then 2 other nodes have the same object in memory. 
		It should notify the nodes it is removing the object from cache, so they won't do it instead. **/
	function Should_cleanup_old_highly_replicated_objects_and_notify_other_nodes(){
		
	}	
	
	function Should_remove_old_objects_from_memory_when_replication_level_and_notify_other_nodes(){
		
	}
}
