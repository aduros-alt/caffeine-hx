package specifications.dbee;
 import dbee.Error;

class PersistenceManagerSpecs extends hxspec.Specification
{
	var po : MockPersistentObject;
	var manager : dbee.PersistenceManager<MockPersistentObject>;
	
	function before(){
		removeFromMapping();
		po = new MockPersistentObject();
		po._manager = cast this.manager;
	}
	
	function after(){
		removeFromMapping();
		if(po != null) untyped po.__class__.version = 10;
		manager = null;
		po = null;
	}
	
	function removeFromMapping(){
		dbee.Configuration.persistenceManager.tableMapping.remove('MockObject');
	}
	function newPersistenceManager(removeManagerFromMappingFirst:Bool):dbee.PersistenceManager<MockPersistentObject>{
		throw 'override for your manager implementation';
		return null;
	}
	
	function Should_throw_ConfigurationError_when_the_PersistentObject_unique_Model_ID_is_taken(){
		var t = dbee.Configuration.persistenceManager.tableMapping;
		var exceptionWasThrown = false;
		
		t.set('MockObject', null);
		try newPersistenceManager(false) catch(e:PersistenceManagerError) switch(e) {
			default:
			case TableIDTaken(id):
				exceptionWasThrown = (id == 'MockObject');
		}
		The(exceptionWasThrown).should.be._true();
	}
	
	function Should_generate_an_OID_when_saving_PersistentObjects_that_have_none(){
		The(po._oid).should.be._null();
		po.save();
		The(po._oid).should.not.be._null();
	}
	
	// -- Serialization specs -- //
	function Should_serialize_PersistentObjects(){
		po._oid = 88;
		Calling(manager.serialize( po )).should.not._return._null();
	}
	
	function Should_throw_NoObjectID_error_when_trying_to_serialize_PersistentObjects_that_have_no_oid(){
		The(po._oid).should.be._null();
		var exceptionWasThrown = false;
		try manager.serialize(po) catch(e:dbee.Error) switch(e)
		{
			default:
			case NoObjectID(o):
				if(po == o)
					exceptionWasThrown = true;
		}
		The(exceptionWasThrown).should.be._true();
	}
	
	function Should_be_able_to_deserialize_objects_from_serialized(){
		po._oid = 88;
		var s = manager.serialize(po);
		The(s).should.not.be._null();
		var newObj = manager.deSerialize(s);
		The(po.df_1.value).should.be.equalTo(newObj.df_1.value);
		The(po.df_2.value).should.be.equalTo(newObj.df_2.value);
	}
	
	function Should_let_the_model_upgrade_older_versioned_serializations(){
		untyped po.__class__.version = 8;
		manager = newPersistenceManager(true);
		po._oid = 88;
		var serializedLowerVersion = manager.serialize(po);
		
		untyped po.__class__.version = 10;
		manager = newPersistenceManager(true);
		var upgradedPO = manager.deSerialize( serializedLowerVersion );
		The( manager.objectVersion ).should.be.equalTo(10);
		The( upgradedPO.upgradeWasHandled ).should.be._true();
	}
	
	// -- End Serialization specs -- //
	
	
	function Should_be_able_to_get_saved_PersistentObjects(){
		var uid = po._oid = 2;//'ABC';
		po.df_1.value = 'Reference test';
		manager.save(po);
		var origPo = po;
		po = null;
		
		Calling(manager.get(uid).df_1.value).should._return.equalTo(origPo.df_1.value);
	}
	
	function Should_not_be_able_to_get_deleted_PersistentObjects(){
		po.df_1.value = 'Delete me!';
		po.save();
		Calling(manager.get(po._oid).df_1.value).should._return.equalTo('Delete me!');
		po.delete();
		Calling(manager.exists(po._oid)).should._return._false();
		Calling(manager.get(po._oid).df_1.value).should.not._return.equalTo('Delete me!');
	}
	
	function Should_be_able_to_find_objects_by_id(){
		po.df_1.value = 'Something different';
		po.save();
		Calling(manager.get(po._oid)._oid).should._return.equalTo(po._oid);
		Calling(manager.get(po._oid).df_1.value).should._return.equalTo(po.df_1.value);
	}
	
	function Should_be_able_to_find_objects_by_field_value_combinations(){
		po.df_1.value = 'danny';
		po.save();
		
		Calling(manager.findFirst({df_1:'danny'})).should.not._return._null();
		Calling(manager.findFirst({df_1:'danny'}).df_1.value).should._return.equalTo('danny');
		Calling(manager.find({df_1:'danny'}).first().df_1.value).should._return.equalTo('danny');
	}
	
	function Should_be_able_to_find_objects_by_a_given_function(){
		po.df_1.value = 'danny';
		po.save();
		var matcher = function(o:MockPersistentObject){
			return o.df_1.value == 'danny';
		}
		
		Calling(manager.select(matcher).first()).should.not._return._null();
		Calling(manager.select(matcher).first().df_1.value).should._return.equalTo('danny');
	}
	
	/* * Used to hook in stuff like Remoting synchronization ** /
	function Should_trigger_save_event_when_saving_object(){
		
	}
	
	/** Used to hook in stuff like Remoting synchronization ** /
	function Should_trigger_delete_event_when_deleting_object(){
		
	}
	
/*	
	/** For some reason, 2 seperate transactions are trying to update the same object.  ** /
	function Should_merge_transactions_when_in_conflict(){
		
	}
*/
}
