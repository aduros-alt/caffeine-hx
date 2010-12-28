package chx.sys;

enum A {
	Good;
	/**
		Doc for Things
	**/
	Things;
	Happen;
}

private enum B {
	You;
	Cant;
	See;
	Me;
}

class C {
	public function new() {
	}
}

private class D {
	public function new() {
	}
}

class Base {
	public var baseVar : Int;
	public function baseFunc() : Void {
	}

	/**
		This is the documentation from Base for baseOver1
		@throws chx.sys.Layer1
never ever, this is just an
		example of multiline
  text
	**/
	public function baseOver1() : Void {}

	public function baseOver2() : Void {}
}

class Layer1 extends Base {
	private static var privateStatic : Int;
	private var privateMember	: Int;

	public var layer1var : Int;

	public function layer1Func() : Void {}

	public function layer1Over() : Void {}

	private function layer1OverPrivate() : Void {}

	public override function baseOver1() : Void {}

	private function privateMethod() : Void {}
	private static function privateFunction() : Void {}

	public dynamic function dynamicMethod() : Void {}
}

/**
	This is the class documentation for TestDeleteMe
	@author Russell Weir
**/
class TestDeleteMe extends Layer1, implements Dynamic {
	public static var sa : Int;
	private static var sb : String;

	inline public static var staticInlineVarPublic : Int = 5;
	inline private static var staticInlineVarPrivate : Int = 6;

	static function iAmAPrivateStaticMethod(gg:Int) {
	}

	public static function iAmAPublicStaticMethod(gg:Int) : Array<String> {
		return new Array();
	}

	private static inline function iAmAPrivateStaticInlineMethod() {
		return 1;
	}

	public static inline function iAmAPublicStaticInlineMethod() {
		return 2;
	}

	public inline function iAmAPublicInlineMethod() {
		return 3;
	}

	private inline function iAmAPrivateInlineMethod() {
		return 4;
	}

	public override function baseOver2() {}

	public override function layer1Over() {}

	private override function layer1OverPrivate() {}

	/** This var is documented. Lucky you **/
	public var a : Int;
	public var b : String;

	/**
		Creates a new TestDeleteMe with int value
		@param v An ignored value
		@throws chx.lang.Exception When it feels like, just for fun!
		@returns Nothing cause it's a constructor, fool&
but this is an example of
			a multiline tag that should
				      format nicely.
		And here are some "quotes" for you
	**/
	public function new(v:Int) {
	}


	/**
		Does nothing of interest
		@param a A TestDeleteMe instance
		@param b A typeable nothing
		@throws chx.lang.Exception Every single time
		@returns Null always
	**/
	public function myTemplateMethod<T>(a: TestDeleteMe, b : T) : Int {
		return null;
	}

	public function objectMethod(obj : { a: Int, b:Float}) :
#if neko
		{ a : Int, b : Float }
#else
		Null<Int>
#end
	{
		return null;
	}

	/**
	@author Ian Fleming
	@deprecated By a shot to the head
	@type F Any female you want
	@type M Any male you want
	@param girl A sexy woman
	@requires A fast car
	@returns Always 007. Even in Octal it's the same
	@see him and you're probably dead
	@throws chx.lang.Exception never
	@todo Learn more secret agent stuff
	@todo Fix this method so it actually accomplishes something
	**/
	public function JamesBond<F,M>(girl:String) : Int {
		return 7;
	}
}

class ClassWithPrivateConstructor {
	private function new() {
	}

	public static function createInstance() : ClassWithPrivateConstructor {
		return new ClassWithPrivateConstructor();
	}
}
