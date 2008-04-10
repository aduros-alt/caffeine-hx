package stdlib;

import unit.Assert;

import Type;

class TestReflect {
	public function new(){}
	
	public function testNullFields(){
		var l = Reflect.fields( null );
		Assert.equals( 0, l.length);
	}

	public function testEnumFields(){
		var l = Type.getEnumConstructs(TestReflectColor);

		Assert.isTrue( arrHas(l,__unprotect__("blue")) );
		Assert.isTrue( arrHas(l,__unprotect__("red")) );
		Assert.isTrue( arrHas(l,__unprotect__("yellow")) );
		Assert.isTrue( l.length == 3 );
	}

	public function testAnonyFields() {
		var o = { a : "haXe", b : 7 };
		var l = Reflect.fields(o);
		Assert.equals(2, l.length);
		Assert.isTrue( arrHas(l,__unprotect__("a")) );
		Assert.isTrue( arrHas(l,__unprotect__("b")) );
	}
	
	public function testInstanceFields(){
		var l = Type.getInstanceFields(Type.getClass(new TestReflectClass()));
		// private fields are not listed
		var n = #if as3gen 4 #else true 5 #end;
		Assert.equals( n, l.length );

		l = Type.getClassFields(Type.getClass(new TestReflectClass()));
		Assert.equals( 2, l.length );
	}

	// fails on flash9
	#if (flash9 || php)
	#else true
	public function testInstanceInitFields(){
		var o = new TestReflectClass();
		o.init();
		var l = Reflect.fields(o);
		Assert.isTrue( arrHas(l,__unprotect__("b")) );
		Assert.isTrue( arrHas(l,__unprotect__("c")) );
		Assert.isTrue( arrHas(l,__unprotect__("d")) );
		Assert.equals( 3, l.length );
	}
	#end

	public function testClassA(){
		var o = new TestReflectClass();
		o.init();

		var c = Type.getClass(o);
		Assert.isTrue( c != null );
		Assert.equals( c, TestReflectClass );
		Assert.equals( __unprotect__("stdlib.TestReflectClass"), Type.getClassName(c) );
#if !php
		Assert.isTrue( untyped c.prototype != null );
#end
		untyped Assert.isTrue( c.staticFunction != null );
		Assert.isTrue( Reflect.hasField( c, __unprotect__("staticVar") ) );
	}

	public function testExtendsImplements(){
		var o = new TestReflectExt();
		o.init();

		var c = Type.getClass(o);
		var trc : Class<Dynamic> = TestReflectClass;
		Assert.isTrue( c != null );
		Assert.equals( TestReflectExt, c );
		Assert.equals( trc, Type.getSuperClass(c) );
		Assert.equals( __unprotect__("stdlib.TestReflectExt"), Type.getClassName(c) );
	}

	public function testIsFunction(){
		Assert.isTrue(Reflect.isFunction(testIsFunction));
		Assert.isTrue(Reflect.isFunction(this.testIsFunction));
		Assert.isTrue(Reflect.isFunction(TestReflectClass.staticFunction));
		Assert.isFalse(Reflect.isFunction(TestReflectClass));
	}

	public function testResolve(){
		var trc : Class<Dynamic> = TestReflectClass;
		Assert.equals(trc,Type.resolveClass(__unprotect__("stdlib.TestReflectClass")));
		var name = "haxe.unit.TestCase";
		Assert.equals(haxe.unit.TestCase,Type.resolveClass(name));
	}

	public function testDeleteField(){
		var o = { foo:"test", bar:null };
		var foo = __unprotect__("foo");
		var bar = __unprotect__("bar");
		var baz = __unprotect__("baz");

		Assert.isTrue( Reflect.hasField( o, foo ) );
		Assert.isTrue( Reflect.hasField( o, bar ) );
		Assert.isFalse( Reflect.hasField( o, baz ) );

		Assert.isTrue( Reflect.deleteField( o, foo ) );
		Assert.isFalse( Reflect.hasField( o, foo ) );

		Assert.isTrue( Reflect.deleteField( o, bar ) );
		Assert.isFalse( Reflect.deleteField( o, bar ) );
		Assert.isFalse( Reflect.deleteField( o, baz ) );
	}

	public function testNull(){
		assertMultiple(null);
	}

	public function testInt(){
		assertMultiple(0);
	}

	public function testFloat(){
		assertMultiple(1.3);
	}

	public function testString(){
		assertMultiple("","String");
	}

	public function testArray(){
		assertMultiple([],"Array");
	}

	public function testDate(){
		assertMultiple(Date.now(),"Date");
	}

	public function testXml(){
		assertMultiple(Xml.createDocument(),"Xml");
	}


	public function testList(){
		assertMultiple(new List(),__unprotect__("List"));
	}

	public function testHash(){
		assertMultiple(new Hash(),__unprotect__("Hash"));
	}

	public function testBool(){
		assertMultiple(true);
	}

	public function testAnonObject(){
		assertMultiple({ x : 0 });
	}

	public function testInstace(){
		assertMultiple(new TestReflectExt(),__unprotect__("stdlib.TestReflectExt"),__unprotect__("stdlib.TestReflectClass"));
	}

	public function testClass(){
		assertMultiple(TestReflectExt);
	}

	public function testEnumSimple(){
		assertMultiple(TestEnumA);
	}

	public function testEnumParam(){
		assertMultiple(TestEnumB(0));
	}

	public function testEnum(){
		assertMultiple(MyPublicEnum);
	}

	public function testMethod(){
		assertMultiple(assertMultiple);
	}

	public function testMisc(){
		Assert.equals(Type.getEnum(TestEnumA),MyPublicEnum);
		Assert.equals(Type.getEnumName(MyPublicEnum),__unprotect__("stdlib.MyPublicEnum"));
		Assert.equals(Type.resolveClass(__unprotect__("stdlib.TestReflectExt")),TestReflectExt);
		Assert.equals(Type.resolveClass(__unprotect__("stdlib.MyPublicEnum")),null);
		Assert.equals(Type.resolveEnum(__unprotect__("stdlib.TestReflectExt")),null);
		Assert.equals(Type.resolveEnum(__unprotect__("stdlib.MyPublicEnum")),MyPublicEnum);
		Assert.equals(Type.resolveEnum("XXXX.XXX"),null);
		Assert.equals(Type.resolveClass("XXXX.XX"),null);
	}

	private function assertMultiple( x : Dynamic, ?name : String, ?supername : String, ?pos : haxe.PosInfos ){
		var c = Type.getClass(x);
		if( c == null )
			Assert.equals( name, null, pos );
		else
			Assert.isFalse( name == null, pos );
		var n = Type.getClassName(c);
		Assert.equals( name, n, pos );

		var csup = if( c == null ) null else Type.getSuperClass(c);
		if( csup == null ) 
			Assert.equals( supername, null, pos );
		else
			Assert.isFalse( supername == null, pos );
		var nsup = Type.getClassName( csup );
		Assert.equals( supername, nsup, pos );
	}

	private function arrHas( a : Array<Dynamic>, v : Dynamic ) : Bool {
		for( t in a ){
			if( t == v ) return true;
		}
		return false;
	}

	public function testTypeof() {
	 	assertType(null,TNull);
	 	assertType(0,TInt);
	 	assertType(1.54,TFloat);
	 	assertType(Math.NaN,TFloat);
	 	assertType(Math.POSITIVE_INFINITY,TFloat);
		assertType(Math.NEGATIVE_INFINITY,TFloat);
	 	assertType(true,TBool);
	 	assertType(false,TBool);
	 	assertType("",TClass(String));
	 	assertType(new String("hello"),TClass(String));
	 	assertType([],TClass(Array));
		assertType(new TestReflectClass(),TClass(TestReflectClass));
		assertType(TestEnumA,TEnum(MyPublicEnum));
		assertType(TestEnumB(0),TEnum(MyPublicEnum));
		assertType(Private,TEnum(TestEnumPriv));
		assertType({ x : 0 },TObject);
		assertType(testTypeof,TFunction);
		assertType(function() { },TFunction);
		assertType(MyPublicEnum,TObject);
		assertType(TestReflectClass,TObject);
	}

	function assertType( v : Dynamic, et : ValueType, ?pos : haxe.PosInfos ) {
		var t = Type.typeof(v);
		switch( t ) {
		case TClass(c): switch( et ) { case TClass(c2): Assert.equals(c2,c,pos); default: Assert.equals(et,t,pos); }
		case TEnum(e): switch( et ) { case TEnum(e2): Assert.equals(e2,e,pos); default: Assert.equals(et,t,pos); }
		default:
			Assert.equals(et,t,pos);
		}
	}

	public function testCreateInstance() {
		var i = Type.createInstance(TestCreate,["ok"]);
		Assert.isTrue( Std.is(i,TestCreate) );
		i = Type.createEmptyInstance(TestCreate);
		Assert.isTrue( Std.is(i,TestCreate) );
	}

	public function testEnumEq() {
		Assert.isTrue( Type.enumEq(X,X) );
		Assert.isFalse( Type.enumEq(X,Y) );
		Assert.isTrue( Type.enumEq(Z(0),Z(0)) );
		Assert.isFalse( Type.enumEq(Z(0),Z(1)) );
		Assert.isFalse( Type.enumEq(W(X,Z(0)),W(X,Z(1))) );
		Assert.isTrue( Type.enumEq(W(Z(1),W(X,Y)),W(Z(1),W(X,Y))) );
	}

	public function testVarArgs() {
		var sum : Dynamic = Reflect.makeVarArgs(function(a : Array<Dynamic>) {
			var x = 0;
			for( i in a )
				x += i;
			return x;
		});
		Assert.equals( 0, sum() );
		Assert.equals( 5, sum(5) );
		Assert.equals( 8, sum(5,2,1) );
		Assert.equals( 28, sum(1,2,3,4,5,6,7) );
	}

	#if !neko
	public function testCompareMethods() {
		#if !hllua
		var o1 = new List();
		var o2 = new List();
		Assert.isTrue( Reflect.compareMethods(o1.add,o1.add) );
		Assert.isFalse( Reflect.compareMethods(o1.add,o2.add) );
		Assert.isFalse( Reflect.compareMethods(o1.add,o1.remove) );
		#end
	}
	#end

}

private enum TestEnumPriv {
	Private;
}

enum TestReflectColor {
	blue;
	red;
	yellow;
}

enum MyPublicEnum {
	TestEnumA;
	TestEnumB( x : Int );
}

class TestCreate {
	public function new(v) {
		if( v != "ok" ) throw "error";
	}
}

class TestReflectClass {
	public var a : Int;
	public var b : Int;
	public var c : Null<Int>;
	private var d : Null<Int>;

	public static var staticVar : Dynamic;

	public static function staticFunction(){
	}

	public function new(){

	}

	public function init(){
		b = 2;
		c = null;
		d = null;
	}
}

interface TestReflectInterface {
	public var a : Int;
	public var b : Int;
	public var c : Int;
}

interface TestReflectInterface2 {
	public var toto : Int;
}

class TestReflectExt extends TestReflectClass, implements TestReflectInterface, implements TestReflectInterface2 {
	public var toto : Int;
}

private enum E {
	X;
	Y;
	Z( v : Int );
	W( a : E, b : E );
}
