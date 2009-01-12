package specification.dbee.field;

/**
	Artibtrary numbers within a defined range.
**/
class NumberSpecs extends DatafieldSpecs
{
	function Should_have_an_optional_minimal_value(){
		
	}
	
	function Should_have_an_optional_maximum_value(){
		
	}
	
	function Should_be_invalid_when_min_and_max_value_requirements_are_not_met(){
		var n = new dbee.field.Text(10,15);
		n.text = 'ABC';
		The(tf.isValid).should.be._false();
		tf.text = '1234567890';
		The(tf.isValid).should.be._true();
		tf.text = '1234567890123456';
		The(tf.isValid).should.be._false();
		tf.text = '123456789012345';
		The(tf.isValid).should.be._true();
		
		var tf = new dbee.field.Text(10);
		tf.text = 'ABC';
		The(tf.isValid).should.be._false();
		tf.text = '1234567890';
		The(tf.isValid).should.be._true();
		tf.text = '1234567890123456';
		The(tf.isValid).should.be._true();
		tf.text = '123456789012345';
		The(tf.isValid).should.be._true();
		
		var tf = new dbee.field.Text(0,10);
		tf.text = 'ABC';
		The(tf.isValid).should.be._true();
		tf.text = '1234567890';
		The(tf.isValid).should.be._true();
		tf.text = '1234567890123456';
		The(tf.isValid).should.be._false();
		tf.text = '123456789012345';
		The(tf.isValid).should.be._false();
	}
}
