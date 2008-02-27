package specifications.dbee.field;

enum TestEnum {
	One;
	Two;
	Three( val1:String, val2:String );
}

class EnumFieldSpecs extends DatafieldSpecs
{
	function before() {
		// new EnumField(MyEnum,['const1','const3','const2']);
	}
	
	/** This? **/
	function Should_accept_number_to_constructor_name_mapping(){
		
	}
	/** Or this? **/
	function Should_accept_function_which_maps_number_to_constructor(){
		
	}
	
	/** Use a string and charCodeAt()? How to store IPv6 effecient? **/
	function Should_throw_error_when_name_mapping_contains_nonexistent_constructor(){
		
	}
	
	function Should_accept_default_constructor(){
		
	}
}
