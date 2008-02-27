package specifications.dbee;

class MockPersistentObjectSpecs extends PersistentObjectSpecs
{
	function before(){
		super.before();
		po = new MockPersistentObject();
		untyped po._manager = this.manager;
	}
	
	function fillObject(){
		var o = cast(po, MockPersistentObject);
		o.df_1.value = 'yay';
		o.df_2.value = 'even more yay';
	}
	
	/** Not needed for mock object **/
	function Should_have_a_default_manager(){
		The(untyped po._manager).should.not.be._null();
	}
	/** Not needed for mock object **/
	function Should_use_default_manager_when_none_is_configured_after_calling_save(){
		The(untyped po._manager).should.not.be._null();
	}
}
