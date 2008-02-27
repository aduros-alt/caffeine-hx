package specifications.dbee.field;

/**
	Artibtrary numbers within a defined range.
**/
class IntegerSpecs extends DatafieldSpecs
{
	function before(){
		this.df = new dbee.field.Integer();
	}
	
	function changeValue()
	{
		cast(df, dbee.field.Integer).value = 1337;
	}
	
	function readValue()
	{
		return cast(df, dbee.field.Integer).value;
	}
	
	function Should_not_be_marked_as_changed_after_setting_the_value_from_memory() {
		untyped df._v = 1234;
		readValue();
		The(df.changed).should.not.be._true();
	}
	
	function Should_have_an_optional_minimal_value(){
		var n = new dbee.field.Integer(0);
		The(n.minvalue).should.not.be._null();
	}
	
	function Should_have_an_optional_maximum_value(){
		var n = new dbee.field.Integer(null, 100);
		The(n.maxvalue).should.not.be._null();
	}
	
	function Should_be_invalid_when_min_and_max_value_requirements_are_not_met(){
		var n = new dbee.field.Integer(0);
		n.value = -1;
		The(n.isValid).should.be._false();
		n.value = 0;
		The(n.isValid).should.be._true();
		
		var n = new dbee.field.Integer(10000000);
		n.value = 1000000000;
		The(n.isValid).should.be._true();
		
		var n = new dbee.field.Integer(null, 100);
		n.value = -1;
		The(n.isValid).should.be._true();
		n.value = 0;
		The(n.isValid).should.be._true();
		
		var n = new dbee.field.Integer(null, 1000000000);
		n.value = 1000000000;
		The(n.isValid).should.be._true();
		n.value = 1000000001;
		The(n.isValid).should.be._false();
		
		var n = new dbee.field.Integer(1337, 13337);
		n.value = 13337;
		The(n.isValid).should.be._true();
		n.value = 1337;
		The(n.isValid).should.be._true();
		n.value = 12337;
		The(n.isValid).should.be._true();
		n.value = 137;
		The(n.isValid).should.be._false();
		n.value = 133337;
		The(n.isValid).should.be._false();
	}
}
