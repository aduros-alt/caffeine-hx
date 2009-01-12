package stdlib;

import unit.Assert;

class TestEReg {
	public function new(){}
	
	public function testMatch(){
		var e = ~/abc((ab)+)(.*?)(d+)/;

		Assert.isTrue( e.match("alaabcababbaaadddeel") );
		Assert.equals( 3, e.matchedPos().pos );
		Assert.equals( 14, e.matchedPos().len );
		Assert.equals( "abcababbaaaddd" ,e.matched(0) );
		Assert.equals( "abab" ,e.matched(1) );
		Assert.equals( "ab" ,e.matched(2) );
		Assert.equals( "baaa" ,e.matched(3) );
		Assert.equals( "ddd" ,e.matched(4) );
	}

	public function testMatch2(){
		var e = ~/^(abc|def)$/;

		Assert.isFalse( e.match("abcdef") );
		Assert.isTrue( e.match("abc") );
		Assert.equals( 0, e.matchedPos().pos );
		Assert.equals( 3, e.matchedPos().len );
		Assert.equals( "abc" ,e.matched(0) );
		Assert.equals( "abc" ,e.matched(1) );
	}

	public function testMatch3(){
		var e = ~/(a{2,})(.*?)(b{2,4})/;

		Assert.isTrue( e.match("laaaabcdebbbbbb") );
		Assert.equals( 1, e.matchedPos().pos );
		Assert.equals( 12, e.matchedPos().len );
		Assert.equals( "aaaabcdebbbb" ,e.matched(0) );
		Assert.equals( "aaaa" ,e.matched(1) );
		Assert.equals( "bcde" ,e.matched(2) );
		Assert.equals( "bbbb" ,e.matched(3) );
	}

	#if (neko || flash9)
	public function testMatch4(){
		var e = ~/(?<!abc)(def)(.*)/;

		Assert.isTrue( e.match("abcdefdefabc") );
		Assert.equals( 6, e.matchedPos().pos );
		Assert.equals( 6, e.matchedPos().len );
		Assert.equals( "defabc" ,e.matched(0) );
		Assert.equals( "def" ,e.matched(1) );
		Assert.equals( "abc" ,e.matched(2) );
	}
	#end

	public function testMatch5(){
		var e = ~/(.*?)(def)(?!abc)/;

		Assert.isTrue( e.match("laladefabcdeflala") );
		Assert.equals( 0, e.matchedPos().pos );
		Assert.equals( 13, e.matchedPos().len );
		Assert.equals( "laladefabcdef" ,e.matched(0) );
		Assert.equals( "laladefabc" ,e.matched(1) );
		Assert.equals( "def" ,e.matched(2) );
	}

	public function testMatch6(){
		var e = ~/\x20/;
		#if (flash9 || php)
		#else true
		untyped Assert.isFalse( e.r == null );
		#end

		Assert.isTrue( e.match(" ") );
		Assert.equals( 0, e.matchedPos().pos );
		Assert.equals( 1, e.matchedPos().len );
		Assert.equals( " " ,e.matched(0) );
	}

	public function testReplaceDollar(){
		var r = ~/(aa)/;
		var r2 = ~/aa/;

		Assert.equals( "$", r2.replace("aa","$$") );
		Assert.equals( "$", r.replace("aa","$$") );
		Assert.equals( "$1", r.replace("aa","$$1") );
		Assert.equals( "$$p", r.replace("aa","$$$$p") );
		Assert.equals( "$$p", r.replace("aa","$$$p") );
		Assert.equals( "$p", r.replace("aa","$$p") );
		Assert.equals( "$p", r.replace("aa","$p") );
		Assert.equals( "aap$", r.replace("aa","$1p$") );
		Assert.equals( "xx$", r.replace("aa","xx$$") );
		Assert.equals( "xx$y", r.replace("aa","xx$$y") );
		Assert.equals( "xx$$y", r.replace("aa","xx$$$$y") );
		Assert.equals( "$1p$", r2.replace("aa","$1p$") );
	}

	#if neko
	// error on safari, flash9
	public function testBadPattern(){
		try {
			var e = ~/(a))/;
		}catch( e : Dynamic ){
			Assert.isTrue( e != null );
		}
	}
	#end

}
