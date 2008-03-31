package syntax;

import unit.Assert;
import syntax.util.ImplementsDynamic;
import syntax.util.F9Dynamic;
import syntax.util.MethodVariable;

class DynamicFunction {
	public function new() {}

	public function testInline() {
		var f = function() { return "test"; };
		Assert.equals("test", f());
	}

	function passFunction(f : Void -> String) {
		return f();
	}

	public function testArgument1() {
		var f = function() { return "test"; };
		Assert.equals("test", passFunction(f));
	}

	public function testArgument2() {
		Assert.equals("test", passFunction(function() { return "test"; }));
	}

	public function testAnonymousObject1() {
		var a = { f : function(){ return "test"; } };
		Assert.equals("test", a.f());
	}

	public function testAnonymousObject2() {
		var a : Dynamic = Reflect.empty();
		a.f = function(){ return "test"; };
		Assert.equals("test", a.f());
	}

	public function testAnonymousObject3() {
#if !php
		var a = { f : f };
		Assert.equals("test", a.f());
#end
	}

	public function testAnonymousObject4() {
#if !php
		var a : Dynamic = Reflect.empty();
		a.f = f;
		Assert.equals("test", a.f());
#end
	}

	public function testAnonymousObject5() {
#if !php
		var a = { f : staticF };
		Assert.equals("test", a.f());
#end
	}

	public function testAnonymousObject6() {
#if !php
		var a : Dynamic = Reflect.empty();
		a.f = staticF;
		Assert.equals("test", a.f());
#end
	}

	public function testImplementsDynamicAddMethod1() {
#if !php
		var a = new ImplementsDynamic();
		a.f = function(){ return "test"; };
		Assert.equals("test", a.f());
#end
	}

	public function testImplementsDynamicAddMethod2() {
#if !php
		var a = new ImplementsDynamic();
		a.f = f;
		Assert.equals("test", a.f());
#end
	}

	public function testImplementsDynamicAddMethod3() {
#if !php
		var a = new ImplementsDynamic();
		a.f = staticF;
		Assert.equals("test", a.f());
#end
	}

	public function testImplementsDynamicRedefineMethod1() {
#if !php
		var a = new ImplementsDynamic();
		Assert.equals("stub", a.stub());
		a.stub = function(){ return "test"; };
		Assert.equals("test", a.stub());
#end
	}

	public function testImplementsDynamicRedefineMethod2() {
#if !php
		var a = new ImplementsDynamic();
		Assert.equals("stub", a.stub());
		a.stub = f;
		Assert.equals("test", a.stub());
#end
	}

	public function testImplementsDynamicRedefineMethod3() {
#if !php
		var a = new ImplementsDynamic();
		Assert.equals("stub", a.stub());
		a.stub = staticF;
		Assert.equals("test", a.stub());
#end
	}

	public function testF9DynamicRedefineMethod1() {
#if !php
		var a = new F9Dynamic();
		Assert.equals("stub", a.stub());
		a.stub = function(){ return "test"; };
		Assert.equals("test", a.stub());
#end
	}

	public function testF9DynamicRedefineMethod2() {
#if !php
		var a = new F9Dynamic();
		Assert.equals("stub", a.stub());
		a.stub = f;
		Assert.equals("test", a.stub());
#end
	}

	public function testF9DynamicRedefineMethod3() {
#if !php
		var a = new F9Dynamic();
		Assert.equals("stub", a.stub());
		a.stub = staticF;
		Assert.equals("test", a.stub());
#end
	}

	public function testMethodVariable1() {
#if !php
		var a = new MethodVariable();
		a.f = function(){ return "test"; };
		Assert.equals("test", a.f());
#end
	}

	public function testMethodVariable2() {
#if !php
		var a = new MethodVariable();
		a.f = f;
		Assert.equals("test", a.f());
#end
	}

	public function testMethodVariable3() {
#if !php
		var a = new MethodVariable();
		a.f = staticF;
		Assert.equals("test", a.f());
#end
	}

	public function testStaticMethodVariable1() {
#if !php
		MethodVariable.staticF = function(){ return "test"; };
		Assert.equals("test", MethodVariable.staticF());
#end
	}

	public function testStaticMethodVariable2() {
#if !php
		MethodVariable.staticF = f;
		Assert.equals("test", MethodVariable.staticF());
#end
	}

	public function testStaticMethodVariable3() {
#if !php
		MethodVariable.staticF = staticF;
		Assert.equals("test", MethodVariable.staticF());
#end
	}

	private function f() {
		return "test";
	}

	private static function staticF() {
		return "test";
	}
}