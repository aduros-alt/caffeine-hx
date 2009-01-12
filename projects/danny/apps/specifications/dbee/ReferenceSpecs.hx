package specifications.dbee;

class ReferenceSpecs extends hxspec.Specification
{
	var ref:dbee.Reference<MockPersistentObject>;
	var po:MockPersistentObject;
	var manager:MockPersistenceManager;
	
	function before() {
		manager = new MockPersistenceManager();
		ref = new dbee.Reference<MockPersistentObject>("MockObject");
		po = new MockPersistentObject();
	}
	
	function after() {
		manager = null;
		ref = null;
		po = null;
	}
	
	function fillObject() {
		throw 'Override fillObject() for PersistentObject subclass specifications';
	}
	
	function Should_serialize_tableID_and_Object_oid()
	{
		po.save();
		ref.r = po;
		var serial = new String(ref.serialize());
		The(serial).should.contain.text(Std.string(po._oid));
		The(serial).should.contain.text(po._manager.objectTableID);
	}
	
	function Should_get_record_when_deserialized_and_accessing_r(){
		po.df_1.value = 'Some data';
		po.save();
		ref.r = po;
		var serial = new String(ref.serialize());
		
		po = null;
		ref = new dbee.Reference<MockPersistentObject>();
		ref.deSerialize(serial);
		
		The(ref.r.df_1.value).should.be.equalTo('Some data');
	}
}
