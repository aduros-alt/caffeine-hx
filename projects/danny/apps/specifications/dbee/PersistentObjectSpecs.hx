package specifications.dbee;

class PersistentObjectSpecs extends hxspec.Specification
{
	var po:dbee.PersistentObject;
	var manager:MockPersistenceManager;
	
	function before() {
		manager = new MockPersistenceManager();
	}
	
	function after() {
		manager = null;
		po = null;
	}
	
	function fillObject() {
		throw 'Override fillObject() for PersistentObject subclass specifications';
	}
	
	/** var c = new Client(); c.save(); Routed to the default manager. **/
	function Should_have_a_default_manager_after_saving(){
		//untyped trace(po.__class__.name);
		The(untyped po.__class__.manager).should.be._null();
		fillObject();
		po.save();
		The(po._manager).should.not.be._null();
		Calling(Std.is(untyped po._manager, dbee.PersistenceManager)).should._return._true();
	}
	
	function Should_try_to_get_default_manager_when_none_is_configured_when_calling_save(){
		fillObject();
		po._manager = null;
		untyped The(po._manager).should.be._null();
		po.save();
	/*	try po.save() catch(e:dbee.Error) switch(e) {
			default:
			case NoTableID(obj):
				The(obj).should.be.equalTo(po);
				return;
		}
	*/	
		The(po._manager).should.not.be._null();
		Calling(Std.is(untyped po._manager, dbee.PersistenceManager)).should._return._true();
	}
	
	function Should_delegate_save_to_a_PersistenceManager(){
		fillObject();
		var manager = new MockPersistenceManager();
		untyped po._manager = manager;
		po.save();
		The(manager.hasSaved).should.be._true();
	}
	
	function Should_get_new_OID_from_its_manager(){
		The(manager.appliedOIDtoObject).should.be._false();
		fillObject();
		po.save();
		The(manager.appliedOIDtoObject).should.be._true();
	}
	
	//function Should_
	
	function Should_delegate_delete_to_its_PersistenceManager(){
		var manager = new MockPersistenceManager();
		untyped po._manager = manager;
		po.delete();
		The(manager.hasDeleted).should.be._true();
	}
	
	function Should_have_a_OID_after_save(){
		fillObject();
		The(po._oid).should.be._null();
		po.save();
		The(po._oid).should.not.be._null();
	}
}
