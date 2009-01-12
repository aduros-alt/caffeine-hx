package syntax;

import unit.Assert;

class UndefinedVariables {
  public function new() {}
  
  var x : Int;
  var y : Null<Int>;
  
  public function testLocalUnknown() {
    var a;
#if (neko || php || flash9)
    Assert.isNull(a);
#else !php
    Assert.equals(untyped undefined, a);
#end
  }

#if !flash9
  public function testLocalInt() {
    var a : Int;
#if (neko || php)
    Assert.isNull(a);
#else !php
    Assert.equals(untyped undefined, a);
#end
  }
#end

  public function testLocalNullInt() {
    var a : Null<Int>;
#if (neko || php || flash9)
    Assert.isNull(a);
#else !php
    Assert.equals(untyped undefined, a);
#end
  }
  
  public function testLocalString() {
    var a : String;
#if (neko || php || flash9)
    Assert.isNull(a);
#else !php
    Assert.equals(untyped undefined, a);
#end
  }
  
  public function testLocalDynamic() {
    var a : Dynamic;
#if (neko || php || flash9)
    Assert.isNull(a);
#else !php
    Assert.equals(untyped undefined, a);
#end
  }
  
  public function testLocalInstance() {
    var a : syntax.util.A;
#if (neko || php || flash9)
    Assert.isNull(a);
#else !php
    Assert.equals(untyped undefined, a);
#end
  }
  
#if !flash9
  public function testFieldInt() {
#if (neko || php)
    Assert.isNull(x);
#else !php
    Assert.equals(untyped undefined, x);
#end
  }
#end

  public function testField() {
#if (neko || php || flash9)
    Assert.isNull(y);
#else !php
    Assert.equals(untyped undefined, y);
#end
  }
}