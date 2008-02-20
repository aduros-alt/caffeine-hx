package hxspec;

class Example extends hxspec.Specification
{
	static function main()
	{
		var r = new hxspec.SpecRunner();
		r.add(new Example());
		r.run();
	}
	
	var number:Int;
	var someText:String;
	
	function before() {
		// Do this before every test
		number = 1;
		someText = "This is an example specification";
	}
	
	function after() {
		// Do this after every test
		number = 0;
		someText = "Enjoy!";
	}
	
	function Should_be_a_clear_example() {
		The(number).should.be.greaterThen(0);
	}
	
	function Should_be_useful_for_Behaviour_Driven_Development() {
		Calling(this.before()).should.not._return.value("Bla bla bla");
		Field(this.someText).should.contain.text("example");
		Var([0,2,3,4,5]).should.not.contain.value(number);
	}
	
	function Should_fail_this_specification() {
		The(number).should.be.lessThen(0);
	}
} 
