
class ReflectTest extends haxe.unit.TestCase {
	function test_isFunction() {
		assertTrue(Reflect.isFunction(test_isFunction));
		var f = function(){ return 'This is a function'; }
		assertTrue(Reflect.isFunction(f));
	}
}
