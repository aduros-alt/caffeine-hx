package specifications.dbee;

class TransactionSpecs extends hxspec.Specification
{
	function before() {
	}
	
	function after() {
	}
	
	function Should_accept_array_of_PersistentObjects_to_include_in_transaction(){
		
	}
	
	function Should_only_allow_commit_when_every_changed_field_data_is_valid(){
		
	}
	
	function Should_override_manager_to_catch_save_and_delete_calls(){
		
	}
	
	function Should_override_managers_set_in_references_aswell(){
		
	}
	
	function Should_allow_new_objects_to_be_added_to_the_transaction(){
		
	}
}
/*
	var k = DB.klanten.get(0);
	var t = Transaction.start([k]);
	
	k.blabla.value = 1;
	k.adres.r.value = 10;
	
	k.save();
	
	t.isValid(); // ?
	t.commit();
	
	var t = new Transaction();
	var k = new Klant();
	t.add(k);
	k.save();
	t.commit();
*/
