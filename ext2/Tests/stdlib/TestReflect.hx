import Type;

class TestReflect extends haxe.unit.TestCase {

	public function testNullFields(){
		var l = Reflect.fields( null );
		assertEquals( 0, l.length);
	}

	public function testEnumFields(){
		var l = Type.getEnumConstructs(TestReflectColor);

		assertTrue( arrHas(l,__unprotect__("blue")) );
		assertTrue( arrHas(l,__unprotect__("red")) );
		assertTrue( arrHas(l,__unprotect__("yellow")) );
		assertTrue( l.length == 3 );
	}

	public function testInstanceFields(){
		var l = Type.getInstanceFields(Type.getClass(new TestReflectClass()));
		// private fields are not listed
		var n = #if as3gen 4 #else 5 #end;
		assertEquals( n, l.length );

		l = Type.getClassFields(Type.getClass(new TestReflectClass()));
		assertEquals( 2, l.length );
	}

	// fails on flash9
	#if !flash9
	public function testInstanceInitFields(){
		var o = new TestReflectClass();
		o.init();
		var l = Reflect.fields(o);
		assertTrue( arrHas(l,__unprotect__("b")) );
		assertTrue( arrHas(l,__unprotect__("c")) );
		assertTrue( arrHas(l,__unprotect__("d")) );
		assertEquals( 3, l.length );

		l = Reflect.fields(o);
		assertTrue( arrHas(l,__unprotect__("b")) );
		assertTrue( arrHas(l,__unprotect__("c")) );
		assertTrue( arrHas(l,__unprotect__("d")) );
		assertEquals( 3, l.length );
	}
	#end

	public function testClassA(){
		var o = new TestReflectClass();
		o.init();

		var c = Type.getClass(o);
		assertTrue( c != null );
		assertEquals( c, TestReflectClass );
		assertEquals( __unprotect__("TestReflectClass"), Type.getClassName(c) );
		assertTrue( untyped c.prototype != null );
		untyped assertTrue( c.staticFunction != null );
		assertTrue( Reflect.hasField( c, __unprotect__("staticVar") ) );
	}

	public function testExtendsImplements(){
		var o = new TestReflectExt();
		o.init();

		var c = Type.getClass(o);
		var trc : Class<Dynamic> = TestReflectClass;
		assertTrue( c != null );
		assertEquals( TestReflectExt, c );
		assertEquals( trc, Type.getSuperClass(c) );
		assertEquals( __unprotect__("TestReflectExt"), Type.getClassName(c) );
	}

	public function testIsFunction(){
		assertTrue(Reflect.isFunction(assertEquals));
		assertTrue(Reflect.isFunction(this.assertEquals));
		assertTrue(Reflect.isFunction(TestReflectClass.staticFunction));
		assertFalse(Reflect.isFunction(TestReflectClass));
	}

	public function testResolve(){
		var trc : Class<Dynamic> = TestReflectClass;
		assertEquals(trc,Type.resolveClass(__unprotect__("TestReflectClass")));
		var name = [__unprotect__("haxe"),__unprotect__("unit"),__unprotect__("TestCase")].join(".");
		assertEquals(haxe.unit.TestCase,Type.resolveClass(name));
	}

	public function testDeleteField(){
		var o = { foo:"test", bar:null };
		var foo = __unprotect__("foo");
		var bar = __unprotect__("bar");
		var baz = __unprotect__("baz");

		assertTrue( Reflect.hasField( o, foo ) );
		assertTrue( Reflect.hasField( o, bar ) );
		assertFalse( Reflect.hasField( o, baz ) );

		assertTrue( Reflect.deleteField( o, foo ) );
		assertFalse( Reflect.hasField( o, foo ) );

		assertTrue( Reflect.deleteField( o, bar ) );
		assertFalse( Reflect.deleteField( o, bar ) );
		assertFalse( Reflect.deleteField( o, baz ) );
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
		assertMultiple(new TestReflectExt(),__unprotect__("TestReflectExt"),__unprotect__("TestReflectClass"));
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
		assertEquals(Type.getEnum(TestEnumA),MyPublicEnum);
		assertEquals(Type.getEnumName(MyPublicEnum),__unprotect__("MyPublicEnum"));
		assertEquals(Type.resolveClass(__unprotect__("TestReflectExt")),TestReflectExt);
		assertEquals(Type.resolveClass(__unprotect__("MyPublicEnum")),null);
		assertEquals(Type.resolveEnum(__unprotect__("TestReflectExt")),null);
		assertEquals(Type.resolveEnum(__unprotect__("MyPublicEnum")),MyPublicEnum);
		assertEquals(Type.resolveEnum("XXXX.XXX"),null);
		assertEquals(Type.resolveClass("XXXX.XX"),null);
	}

	private function assertMultiple( x : Dynamic, ?name : String, ?supername : String, ?pos : haxe.PosInfos ){
		var c = Type.getClass(x);
		if( c == null ) {
			assertEquals( name, null );
		}else{
			assertFalse( name == null );
		}
		var n = Type.getClassName(c);
		assertEquals( name, n );

		var csup = if( c == null ) null else Type.getSuperClass(c);
		if( csup == null ) {
			assertEquals( supername, null );
		}else{
			assertFalse( supername == null );
		}
		var nsup = Type.getClassName( csup );
		assertEquals( supername, nsup );
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
		case TClass(c): switch( et ) { case TClass(c2): assertEquals(c2,c,pos); default: assertEquals(et,t,pos); }
		case TEnum(e): switch( et ) { case TEnum(e2): assertEquals(e2,e,pos); default: assertEquals(et,t,pos); }
		default:
			assertEquals(et,t,pos);
		}
	}

	public function testCreateInstance() {
		var i = Type.createInstance(TestCreate,["ok"]);
		assertTrue( Std.is(i,TestCreate) );
		i = Type.createEmptyInstance(TestCreate);
		assertTrue( Std.is(i,TestCreate) );
	}

	public function testEnumEq() {
		assertTrue( Type.enumEq(X,X) );
		assertFalse( Type.enumEq(X,Y) );
		assertTrue( Type.enumEq(Z(0),Z(0)) );
		assertFalse( Type.enumEq(Z(0),Z(1)) );
		assertFalse( Type.enumEq(W(X,Z(0)),W(X,Z(1))) );
		assertTrue( Type.enumEq(W(Z(1),W(X,Y)),W(Z(1),W(X,Y))) );
	}

	public function testVarArgs() {
		var sum : Dynamic = Reflect.makeVarArgs(function(a : Array<Dynamic>) {
			var x = 0;
			for( i in a )
				x += i;
			return x;
		});
		assertEquals( 0, sum() );
		assertEquals( 5, sum(5) );
		assertEquals( 8, sum(5,2,1) );
		assertEquals( 28, sum(1,2,3,4,5,6,7) );
	}

	#if !neko
	public function testCompareMethods() {
		var o1 = new List();
		var o2 = new List();
		assertTrue( Reflect.compareMethods(o1.add,o1.add) );
		assertFalse( Reflect.compareMethods(o1.add,o2.add) );
		assertFalse( Reflect.compareMethods(o1.add,o1.remove) );
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
	public var c : Null<Int>;
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
