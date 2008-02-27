package specifications.dbee;

class ModelSpecs extends #if neko PersistentObjectSpecs #else true hxspec.Specification #end
{
	var model : dbee.Model;
	
	/** [!] Override this function: subclass specific **/
	function before() {
		super.before();
		new MockModel2();
		if(model == null) model = new MockModel();
		model._manager = this.manager;
		#if neko po = model; #end
	}
	
	function after() {
		model = null;
		
		// Cleanup EVERYTHING
		untyped {
			MockModel2.prototype._fields = null;
			MockModel2.manager = null;
			MockModel.prototype._fields = null;
			MockModel.manager = null;
		}
		super.after();
	}
	
	/** [!] Override this function: subclass specific **/
	function fillObject() {
		var m = cast(model, MockModel);
		m.somefield.changeValue();
		m.another.changeValue();
		m.evenother.changeValue();
	}
	
	/** [!] Override this function: subclass specific. Fills model with exception of 1 field having a default. **/
	function fillModelExceptRequiredThatHasDefault() {
		var m = cast(model, MockModel);
		m.another.changeValue();
		m.evenother.changeValue();
	}
	
	/** [!] Override this function: subclass specific. Fills model with exception of 2 required fields **/
	function fillModelExceptTwoRequired() {
		var m = cast(model, MockModel);
		m.another.changeValue();
	}
	
	function Should_be_invalid_when_required_fields_are_not_valid(){
		Field(model._isValid).should.not.be._true();
		fillObject();
		Field(model._isValid).should.be._true();
	}

#if neko
	function Should_try_to_become_valid_by_filling_required_fields_with_defaults_when_saving__or_throw_an_error(){
		// First try setting all defaults
		Field(model._isValid).should.not.be._true();
		fillModelExceptRequiredThatHasDefault();
		Field(model._isValid).should.not.be._true();
		model.save();
		Field(model._isValid).should.be._true();
		after();
		
		before();
		Field(model._isValid).should.not.be._true();
		fillModelExceptTwoRequired();
		Field(model._isValid).should.not.be._true();
		var exception:dbee.Error;
		try model.save() catch(e:Dynamic) exception = e;
		
		The(exception).should.not.be._null();
		The(Type.getEnum(exception)).should.be.equalTo(dbee.Error);
		switch(exception){
			default: return;
			case InvalidObjectData( mclass, object ):
				The(object).should.be.equalTo(this.model);
				The(Type.getClassName(mclass)).should.be.equalTo(Type.getClassName(Type.getClass(this.model)));
		}
	}

	function Should_have_a_positive_version_number_stored_as_static_class_var(){
		The(untyped model.__class__.version).should.be.greaterThen(-1);
	}
	
	function Should_be_able_to_upgrade_from_older_versions(){
		if( untyped this.model.__class__ != MockModel )
			throw 'Override this spec for your model';
		else
			The(true).should.be._true();
	}
#end
/*	
	function Should_trigger_change_event_when_data_is_modified(){
		var wasCalled = false;
		var receiver = function(x){
			wasCalled = true;
		}
		model.onDataChanged.bind(this, receiver);
		fillObject();
		Var(wasCalled).should.be._true();
	}
	
	function Should_define_which_traits_it_uses(){
		
	}
*/
}

private class MockModel2 extends dbee.Model
{
	static var version = 1;
	
	var totallyOther	: MockDatafield;
	
	function new() {
		_tableID		= "MockObject";
		totallyOther	= new MockDatafield();
		super();
	}
	
	private function defineModel(){
		totallyOther.required = true;
	}
}
 
private class MockModel extends dbee.Model
{
	static var version = 1;
	
	var somefield	: MockDatafield;
	var another		: MockDatafield;
	var evenother	: MockDatafield;
	
	function new() {
		_tableID	= "MockObject";
		somefield	= new MockDatafield();
		another		= new MockDatafield();
		evenother	= new MockDatafield();
		super();
	}
	
	private function defineModel()
	{
		somefield.required	= true;
		another.required	= false;
		evenother.required	= true;
	}
	
	private function applyDefaults()
	{
		if(!somefield.isValid)	somefield.changeValue();
	}
}
