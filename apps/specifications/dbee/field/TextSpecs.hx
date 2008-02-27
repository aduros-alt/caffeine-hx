package specifications.dbee.field;

class TextSpecs extends DatafieldSpecs
{
	function before(){
		this.df = new dbee.field.Text();
	}
	
	function changeValue()
	{
		cast(df, dbee.field.Text).text = 'Dit is tekst <COOL>! #*&%^!*(^';
	}
	
	function readValue()
	{
		return cast(df, dbee.field.Text).text;
	}
	
	function Should_not_be_marked_as_changed_after_setting_the_value_from_memory() {
		untyped df._v = 'blabla'.__s;
		readValue();
		The(df.changed).should.not.be._true();
	}
	
	function Should_have_an_optional_maxlength(){
		var tf = new dbee.field.Text(0,10);
		The(tf.maxlength).should.not.be._null();
	}
	
	function Should_have_an_optional_minlength(){
		var tf = new dbee.field.Text(10);
		The(tf.minlength).should.not.be._null();
	}
	
	function Should_be_invalid_when_length_requirements_are_not_met(){
		var tf = new dbee.field.Text(10,15);
		tf.text = 'ABC';
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
	
	function Should_have_a_HTML_representation(){
		super.Should_have_a_HTML_representation();
		
		Calling(df.toHTML()).should.not.contain.text('>');
		Calling(df.toHTML()).should.not.contain.text('<');
	}
}
