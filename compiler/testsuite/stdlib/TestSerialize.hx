package stdlib;

import unit.Assert;

enum MyUniquePublicEnum {
	Y;
	Z( x : Int );
}

private enum TestEnum {
	X;
	P( x : Int );
}

class MyBaseClass {
	public var x : Int;

	public function foo() {
		return x;
	}
}

class MyTestClass extends MyBaseClass {
	public function new(x) {
		if( x != 787 ) throw "Constructor called !";
		this.x = x;
	}
	public function foo2() {
		return x;
	}
}

class TestSerialize {
	public function new(){}

	function id<T>( v : T ) : T {
		return haxe.Unserializer.run(haxe.Serializer.run(v));
	}

	public function testIds() {
#if !(php || hllua)
		Assert.equals( null, id(null) );
		Assert.equals( 125, id(125) );
		Assert.equals( -4563, id(-4563) );
		var f = 100.21546;
		var f2 = id(f);
		Assert.isTrue( Std.is(f2,Float) );
		Assert.isTrue( Math.abs(f - f2) < 1e-10  );
		Assert.equals( true, id(true) );
		Assert.equals( false, id(false) );
		Assert.equals( "hello", id("hello") );
		Assert.equals( "bla", id(new String("bla")) );
		Assert.equals( "ééé", id("ééé") );
#end
	}

	public function testObject() {
#if !(php || hllua)
		var o = { x : "a", y : -1.56, z : "hello" };
		var o2 = id(o);
		Assert.equals(o.x,o2.x);
		Assert.equals(o.y,o2.y);
		Assert.equals(o.z,o2.z);
#end
	}

	public function testClass() {
#if !(php || hllua)
		var c = new MyTestClass(787);
		var c2 = id(c);
		Assert.isTrue( Std.is(c2,MyTestClass) );
		Assert.equals( c.x, c2.x );
		Assert.equals( c.foo(), c2.foo() );
		Assert.equals( c.foo2(), c2.foo2() );
#end
	}

	public function testPrivateEnum() {
#if !(php || hllua)
		Assert.equals( X, id(X) );
		Assert.isTrue( Std.is(id(X),TestEnum) );
		var p = id(P(33));
		Assert.isTrue( Std.is(p,TestEnum) );
		switch( p ) {
		case P(x): Assert.isTrue( x == 33 );
		default: throw "Not-a-P";
		}
#end
	}

	public function testEnum() {
#if !(php || hllua)
		Assert.equals( Y, id(Y) );
		Assert.isTrue( Std.is(id(Y),MyUniquePublicEnum) );
		var p = id(Z(33));
		Assert.isTrue( Std.is(p,MyUniquePublicEnum) );
		switch( p ) {
		case Z(x): Assert.isTrue( x == 33 );
		default: throw "Not-a-Z";
		}
#end
	}

	public function testArray() {
#if !(php || hllua)
		var a = [0,1];
		var a2 : Array<Int> = id(a);
		Assert.isTrue( Std.is(a2,Array) );
		Assert.equals( 2, a2.length );
		Assert.equals( 0, a2[0] );
		Assert.equals( 1, a2[1] );
#end
	}

	public function testList() {
#if !(php || hllua)
		var l = new List();
		l.add(0);
		l.add(1);
		var l2 : List<Int> = id(l);
		Assert.isTrue( Std.is(l,List) );
		Assert.equals( 2, l2.length );
		Assert.equals( 0, l2.first() );
		Assert.equals( 1, l2.last() );
#end
	}

	public function testHash() {
#if !(php || hllua)
		var h = new Hash();
		h.set("a",0);
		h.set("b",1);
		var h2 : Hash<Int> = id(h);
		Assert.isTrue( Std.is(h2,Hash) );
		Assert.equals( 0, h2.get("a") );
		Assert.equals( 1, h2.get("b") );
		for( x in h.keys() )
			if( x != "a" )
				Assert.equals( x, "b" );
#end
	}

	public function testIntHash() {
#if !(php || hllua)
		var h = new IntHash();
		h.set(667,0);
		h.set(-55,1);
		var h2 : IntHash<Int> = id(h);
		Assert.isTrue( Std.is(h2,IntHash) );
		Assert.equals( 0, h2.get(667) );
		Assert.equals( 1, h2.get(-55) );
		for( x in h.keys() )
			if( x != 667 )
				Assert.equals( x, -55 );
#end
	}

	public function testDate() {
#if !(php || hllua)
		var d = Date.now();
		var d2 = id(d);
		Assert.isTrue( Std.is(d2,Date) );
		Assert.equals( d.toString(), d2.toString() );
#end
	}
}