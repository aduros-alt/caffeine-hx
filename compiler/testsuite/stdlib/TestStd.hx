package stdlib;

import unit.Assert;

class TestStd {
	public function new(){}
	
	public function testIs(){
		checkTypes(null,null);
		checkTypes(1,Int,Float);
		checkTypes(-1,Int,Float);
		checkTypes(1.2,Float);
		checkTypes(true,Bool);
		checkTypes(false,Bool);
		checkTypes([],Array);
		checkTypes(new List(),List);
		checkTypes(new Hash(),Hash);
		checkTypes(new ListExtended(),List,ListExtended);
		checkTypes(Foo,TestEnum);
		checkTypes(Bar(0),TestEnum);
	}

	function checkTypes( v : Dynamic, t : Dynamic, ?t2 : Dynamic, ?pos : haxe.PosInfos ){
		var a = [null,Int,Bool,Float,String,Array,Hash,List,ListExtended,TestEnum];
		for( c in a ){
			Assert.equals( c != null && (c == t || c == t2), Std.is(v,c), pos );
		}
	}

	public function testBool() {
		Assert.equals( false, Std.bool(0) );
		Assert.equals( false, Std.bool(null) );
		Assert.equals( false, Std.bool(false) );
		Assert.equals( true, Std.bool(1) );
		Assert.equals( true, Std.bool("") );
		Assert.equals( true, Std.bool({ x : null }) );
		Assert.equals( true, Std.bool(true) );
	}

	public function testConv() {
		Assert.equals( "A", Std.chr(65) );
		Assert.equals( 65 , Std.ord("A") );
		Assert.equals( 65 , Std.int(65) );
		Assert.equals( 65 , Std.int(65.456) );
		Assert.equals( 65 , Std.parseInt("65") );
		Assert.equals( 65 , Std.parseInt("65.3") );
		Assert.equals( 65.0 , Std.parseFloat("65") );
		Assert.equals( 65.3 , Std.parseFloat("65.3") );
		#if !neko
		Assert.isTrue( Math.isNaN(Std.parseFloat("abc")) );
		#end
		Assert.equals( 255 , Std.parseInt("0xFF") );
	}

}

private class ListExtended extends List<Dynamic> {
}

private enum TestEnum {
	Foo;
	Bar(c:Int);
}
