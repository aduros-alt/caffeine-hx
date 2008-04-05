package syntax;

import unit.Assert;

import syntax.util.A;
import syntax.util.B;

// cases with === or !== have been commented because inconsistents in several platforms. 
// Those operators maybe be removed in a future version.

class EqualityOperators {
	public function new() {}
	
  //OK
	public function testInt() {
		Assert.isTrue (0 == 0);
    Assert.isFalse(0 != 0);
//    Assert.isTrue(0 === 0);
	}

  
#if !flash9
	public function testFloatInt() {
    Assert.isTrue (0 == 0.0);
// PLATFORM INCONSISTENCY
/*
#if neko
		Assert.isFalse(0 === 0.0);
    Assert.isTrue (0 !== 0.0);
#else true
    Assert.isTrue (0 === 0.0);
    Assert.isFalse(0 !== 0.0);
#end
*/
	}
#end

  
	public function testFloatIntVar() {
    var i = 0;
    var f = 0.0;
    Assert.isTrue (i ==  f);
    Assert.isFalse(i !=  f);
/*
// PLATFORM INCONSISTENCY, see above
#if neko
		Assert.isFalse(i === f);
    Assert.isTrue(i !== f);
#else true
    Assert.isTrue (i === f);
    Assert.isFalse(i !== f);
#end
*/
	}

#if !flash9
  public function testIntNullity() {
//    Assert.isTrue(0 !== null);
    Assert.isTrue (0 !=  null);
    Assert.isFalse(0 ==  null);
  }
#end

  // OK
	public function testIntVar() {
    var i1 = 0;
    var i2 = 0;
		Assert.isTrue (i1 ==  i2);
    Assert.isFalse(i1 !=  i2);
//    Assert.isTrue(i1 === i2);
	}

  // all but PHP
  public function testIntNullityVar() {
    var n = null;
    var i : Null<Int> = 0;
//    Assert.isTrue(i !== n);
    Assert.isTrue( i !=  n);
    Assert.isFalse(i ==  n);
  }
  
  public function testIntNullityVar2() {
    var n : Null<Int> = null;
    var i : Null<Int> = 0;
//    Assert.isTrue(i !== n);
    Assert.isTrue( i !=  n);
    Assert.isFalse(i ==  n);
  }
    

  // all but PHP
#if !flash9
  public function testFloatNullity() {
//    Assert.isTrue(0.0 !== null);
    Assert.isTrue (0.0 !=  null);
    Assert.isFalse(0.0 ==  null);
  }
#end
  
  // all but PHP
  public function testFloatNullityVar() {
    var n = null;
    var f : Null<Float> = 0.0;
//    Assert.isTrue(f !== n);
    Assert.isTrue (f !=  n);
    Assert.isFalse(f ==  n);
  }

	public function testFloatIntDynamic1() {
    var i : Dynamic = 0;
    var f = 0.0;
    Assert.isTrue (i ==  f);
    Assert.isFalse(i !=  f);
// PLATFORM INCONSISTENCY
/*
#if neko
		Assert.isFalse(i === f);
#else true
    Assert.isTrue (i === f);
#end
*/
	}
  
	public function testFloatIntDynamic2() {
    var i = 0;
    var f : Dynamic = 0.0;
    Assert.isTrue (i ==  f);
    Assert.isFalse(i !=  f);
// PLATFORM INCONSISTENCY, same as above
/*
#if neko
		Assert.isFalse(i === f);
#else true
    Assert.isTrue (i === f);
#end
*/
	}
    
	public function testFloatIntDynamic3() {
    var i : Dynamic = 0;
    var f : Dynamic = 0.0;
    Assert.isTrue (i ==  f);
    Assert.isFalse(i !=  f);
// PLATFORM INCONSISTENCY, same as above
/*
#if neko
		Assert.isFalse(i === f);
#else true
    Assert.isTrue (i === f);
#end
*/
	}

  // OK
  public function testNull() {
    Assert.isTrue(null == null);
    Assert.isTrue(null == null);
//    Assert.isTrue(null === null);
  }

  
  public function testString() {
    Assert.isTrue ("a" ==  "a");
    Assert.isFalse("a" !=  "a");
// PLATFORM INCONSISTENCY
/*
#if neko
		Assert.isFalse("a" === "a");
    Assert.isTrue ("a" !== "a");
#else true
    Assert.isTrue ("a" === "a");
    Assert.isFalse("a" !== "a");
#end    
*/
    Assert.isTrue ("a" !=  null);
//    Assert.isTrue ("a" !== null);
  }

  public function testStringVar() {
    var s1 = "a";
    var s2 = "a";
    Assert.isTrue (s1 == s2);
    Assert.isFalse(s1 != s2);
// PLATFORM INCONSISTENCY, see above
/*
#if neko
		Assert.isFalse(s1 === s2);
    Assert.isTrue (s1 !== s2);
#else true
    Assert.isTrue (s1 === s2);
    Assert.isFalse(s1 !== s2);
#end  
*/
  }

  public function testStringDynamic1() {
    var s1 : Dynamic = "a";
    var s2 = "a";
    Assert.isTrue (s1 == s2);
    Assert.isFalse(s1 != s2);
/*    
// PLATFORM INCONSISTENCY, see above
#if neko
		Assert.isFalse(s1 === s2);
    Assert.isTrue (s1 !== s2);
#else true
    Assert.isTrue (s1 === s2);
    Assert.isFalse(s1 !== s2);
#end 
*/
  }
  
  public function testStringDynamic2() {
    var s1 = "a";
    var s2 : Dynamic = "a";
    Assert.isTrue (s1 == s2);
    Assert.isFalse(s1 != s2);
// PLATFORM INCONSISTENCY, see above
/*
#if neko
		Assert.isFalse(s1 === s2);
    Assert.isTrue (s1 !== s2);
#else true
    Assert.isTrue (s1 === s2);
    Assert.isFalse(s1 !== s2);
#end  
*/
  }
  
  public function testStringDynamic3() {
    var s1 : Dynamic = "a";
    var s2 : Dynamic = "a";
    Assert.isTrue (s1 == s2);
    Assert.isFalse(s1 != s2);
// PLATFORM INCONSISTENCY, see above
/*
#if neko
		Assert.isFalse(s1 === s2);
    Assert.isTrue (s1 !== s2);
#else true
    Assert.isTrue (s1 === s2);
    Assert.isFalse(s1 !== s2);
#end  
*/
  }

  // OK
  public function testStringNullityDynamic1() {
    var n : Dynamic = null;
    var i = "a";
//    Assert.isTrue(i !== n);
    Assert.isTrue (i !=  n);
    Assert.isFalse(i ==  n);
  }

  // OK
  public function testStringNullityDynamic2() {
    var n = null;
    var i : Dynamic = "a";
//    Assert.isTrue(i !== n);
    Assert.isTrue (i !=  n);
    Assert.isFalse(i ==  n);
  }

  // OK
  public function testStringNullityDynamic3() {
    var n : Dynamic = null;
    var i : Dynamic = "a";
//    Assert.isTrue(i !== n);
    Assert.isTrue (i !=  n);
    Assert.isFalse(i ==  n);
  }
  
  // all but PHP
  public function testIntNullityDynamic1() {
    var n : Dynamic = null;
    var i : Null<Int> = 0;
//    Assert.isTrue(i !== n);
    Assert.isTrue (i !=  n);
    Assert.isFalse(i ==  n);
  }
  
  // all but PHP
  public function testIntNullityDynamic2() {
    var n = null;
    var i : Dynamic = 0;
//    Assert.isTrue(i !== n);
    Assert.isTrue (i !=  n);
    Assert.isFalse(i ==  n);
  }
  
  // all but PHP
  public function testIntNullityDynamic3() {
    var n : Dynamic = null;
    var i : Dynamic = 0;
//    Assert.isTrue(i !== n);
    Assert.isTrue (i !=  n);
    Assert.isFalse(i ==  n);
  }
  
  // all but PHP
  public function testFloatNullityDynamic1() {
    var n : Dynamic = null;
    var f : Null<Float> = 0.0;
//    Assert.isTrue(f !== n);
    Assert.isTrue (f !=  n);
    Assert.isFalse(f ==  n);
  }
  
  // all but PHP
  public function testFloatNullityDynamic2() {
    var n = null;
    var f : Dynamic = 0.0;
//    Assert.isTrue(f !== n);
    Assert.isTrue (f !=  n);
    Assert.isFalse(f ==  n);
  }
  
  // all but PHP
  public function testFloatNullityDynamic3() {
    var n : Dynamic = null;
    var f : Dynamic = 0.0;
//    Assert.isTrue(f !== n);
    Assert.isTrue (f !=  n);
    Assert.isFalse(f ==  n);
  }
  
  // all but PHP
  public function testAnonymous() {
    Assert.isTrue ({ name : "haXe" } !=  { name : "haXe" });
//    Assert.isTrue ({ name : "haXe" } !== { name : "haXe" });
    Assert.isFalse({ name : "haXe" } ==  { name : "haXe" });
//    Assert.isFalse({ name : "haXe" } === { name : "haXe" });
  }

  // all but PHP
  public function testAnonymousVar() {
    var x = { name : "haXe" };
    var y = { name : "haXe" };
    var z = { name : "neko" };
    Assert.isTrue (x !=  y);
//    Assert.isTrue (x !== y);
    Assert.isTrue (x !=  z);
//    Assert.isTrue (x !== z);
    Assert.isFalse(x !=  x);
//    Assert.isFalse(x !== x);
    Assert.isTrue (x ==  x);
//    Assert.isTrue (x === x);
    Assert.isFalse(x ==  y);
//    Assert.isFalse(x === y);
    Assert.isFalse(x ==  z);
//    Assert.isFalse(x === z);
  }
  
  // all but PHP
  public function testAnonymousDynamic1() {
    var x : Dynamic = { name : "haXe" };
    var y = { name : "haXe" };
    var z = { name : "neko" };
    Assert.isTrue (x !=  y);
//    Assert.isTrue (x !== y);
    Assert.isTrue (x !=  z);
//    Assert.isTrue (x !== z);
    Assert.isFalse(x !=  x);
//    Assert.isFalse(x !== x);
    Assert.isTrue (x ==  x);
//    Assert.isTrue (x === x);
    Assert.isFalse(x ==  y);
//    Assert.isFalse(x === y);
    Assert.isFalse(x ==  z);
//    Assert.isFalse(x === z);
  }
  
  // all but PHP
  public function testAnonymousDynamic2() {
    var x : Dynamic = { name : "haXe" };
    var y : Dynamic = { name : "haXe" };
    var z = { name : "neko" };
    Assert.isTrue (x !=  y);
//    Assert.isTrue (x !== y);
    Assert.isTrue (x !=  z);
//    Assert.isTrue (x !== z);
    Assert.isFalse(x !=  x);
//    Assert.isFalse(x !== x);
    Assert.isTrue (x ==  x);
//    Assert.isTrue (x === x);
    Assert.isFalse(x ==  y);
//    Assert.isFalse(x === y);
    Assert.isFalse(x ==  z);
//    Assert.isFalse(x === z);
  }

  // all but PHP
  public function testInstance() {
    Assert.isTrue(new A() !=  new A());
//    Assert.isTrue(new A() !== new A());
    Assert.isTrue(new A() !=  new B());
//    Assert.isTrue(new A() !== new B());
//    Assert.isFalse(new A() === new A());
    Assert.isFalse(new A() ==  new B());
//    Assert.isFalse(new A() === new B());
  }

  // all but PHP
  public function testInstanceVar() {
    var x = new A();
    var y = new A();
    var z = new B();
    Assert.isTrue(x ==  x);
//    Assert.isTrue(x === x);
//    Assert.isTrue(x !== y);
    Assert.isTrue(x !=  z);
//    Assert.isTrue(x !== z);
    Assert.isTrue(x !=  y);
  }

  // all but PHP
  public function testInstanceDynamic1() {
    var x : Dynamic = new A();
    var y = new A();
    var z = new B();
    Assert.isTrue(x ==  x);
//    Assert.isTrue(x === x);
//    Assert.isTrue(x !== y);
    Assert.isTrue(x !=  z);
//    Assert.isTrue(x !== z);
    Assert.isTrue(x !=  y);
  }

  // all but PHP
  public function testInstanceDynamic2() {
    var x : Dynamic = new A();
    var y : Dynamic = new A();
    var z = new B();
    Assert.isTrue(x ==  x);
//    Assert.isTrue(x === x);
//    Assert.isTrue(x !== y);
    Assert.isTrue(x !=  z);
//    Assert.isTrue(x !== z);
    Assert.isTrue(x !=  y);
  }
  
  // all but PHP
  public function testBool() {
    Assert.isTrue (true  != null);
    Assert.isTrue (false != null);
    Assert.isFalse(true  == null);
    Assert.isFalse(false == null);
  }

  // all but PHP
  public function testBoolDynamic1() {
    var t : Dynamic = true;
    var f : Dynamic = false;
    var z : Bool = null;
    Assert.isTrue (t != z);
    Assert.isTrue (f != z);
    Assert.isFalse(t == z);
    Assert.isFalse(f == z);
  }

  // all but PHP
  public function testBoolDynamic2() {
    var t : Bool = true;
    var f : Bool = false;
    var z : Dynamic = null;
    Assert.isTrue (t != z);
    Assert.isTrue (f != z);
    Assert.isFalse(t == z);
    Assert.isFalse(f == z);
  }
  
  public function testBoolDynamic3() {
    var t : Dynamic = true;
    var f : Dynamic = false;
    var z : Dynamic = null;
    Assert.isTrue (t != z);
    Assert.isTrue (f != z);
    Assert.isFalse(t == z);
    Assert.isFalse(f == z);
  }
}