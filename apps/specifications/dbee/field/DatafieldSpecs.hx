package specifications.dbee.field;
 import specifications.dbee.MockDatafield;
 import hxbase.event.Event;

class DatafieldSpecs extends hxspec.Specification
{
	private var df : dbee.field.Datafield;
	
	/** [!] Override this function: subclass specific **/
	function before(){
		if(df == null) this.df = new MockDatafield();
	}
	
	function after() {
		df = null;
	}
	
	/** [!] Override this function: subclass specific **/
	function changeValue()
	{
		cast(df, MockDatafield).changeValue();
	}
	
	/** [!] Override this function: subclass specific **/
	function readValue():Dynamic
	{
		return cast(df, MockDatafield).value;
	}
	
	function Should_specify_if_required(){
		Field(df.required).should.not.be._null();
	}
	
	function Should_be_encodable_as_XML(){
		var xml = df.toXML();
		The(xml).should.not.be._null();
	}
	
	function Should_be_encodable_as_URI_string(){
		changeValue();
		var uri = df.toURI();
		The(uri).should.not.be._null();
		The(uri).should.not.contain.text(' ');
	}
	
	function Should_have_a_HTML_representation(){
		changeValue();
		Calling(df.toHTML()).should.not._return._null();
	}
	
	function Should_have_a_String_representation(){
		changeValue();
		Calling(df.toString()).should.not._return._null();
	}
	
	function Should_be_able_to_validate_itself(){
		Field(df.isValid).should.not.be._null();
	}
/*	
	function Should_try_to_make_itself_from_a_random_String_and_throw_a_ParseError(){
		var exceptionWasThrown = false;
		try df.parseString("ASDHP&Y##HPHfp97hp3hiaxck;3-97")
		catch(e:dbee.field.ParseError) {
			exceptionWasThrown = true;
		}
		The(exceptionWasThrown).should.be._true();
	}
	
	/* * Not entirely sure what i want this to do exactly *
	function Should_be_bindable_to_other_Datafields(){
		
	}
	*/
	
	/** Not entirely sure about performance implications etc **/
	function Should_call_a_change_event_when_modified(){
		var global_wasCalled = false,
			_df = this.df;
		
		var gReceiver = function(f){
			if(f == _df) global_wasCalled = true;
		}
		dbee.Events.valueChanged.bind(this, gReceiver);
		changeValue();
		
		Field(global_wasCalled).should.be._true();
	}
	
	function Should_be_able_to_check_if_Datafield_object___is_equal_to_another_datafield_object(){
		Calling(df.equals(df)).should._return._true();
	}
	
	function Should_be_able_to_check_if_Datafield_data___is_equal_to_another_datafield(){
		Calling(df.equals(df)).should._return._true();
	}
	
	function Should_be_able_to_check_if_a_given_Dynamic_value_equals_Datafield_data(){
		Calling(df.equals(df)).should._return._true();
	}
	
	function Should_be_serializable(){
		changeValue();
		Calling(df.serialize()).should.not._return._null();
	}
	
	function Should_be_deSerializable_from_serialized_value_converted_to_string(){
		this.changeValue();
		var s = new String( df.serialize() );
		var olddf = df;
		after();
		before();
		df.deSerialize(s);
		Calling( df.equals(olddf) ).should._return._true();
	}
	
	function Should_not_be_marked_as_changed_after_deSerializing() {
		this.changeValue();
		var s = new String( df.serialize() );
		var olddf = df;
		after();
		before();
		df.deSerialize(s);
		Field(df.changed).should.be._false();
	}
	
	/** [!] Override this function: subclass specific **/
	function Should_not_be_marked_as_changed_after_setting_the_value_from_memory() {
		untyped df._v = 'blabla'.__s;
		readValue();
		The(df.changed).should.not.be._true();
	}
	
	function Should_not_have_char_255_in_serialized_string(){
		var serializeResult = df.serialize();
		The(serializeResult).should.not.contain.text(String.fromCharCode(255));
	}
}
