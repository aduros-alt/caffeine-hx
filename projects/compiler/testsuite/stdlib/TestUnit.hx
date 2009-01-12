package stdlib;

import unit.Assert;

class TestUnit {
	public function new(){}
	
	public function testTrue(){
		Assert.isTrue( true );
	}

	public function testFalse(){
		Assert.isFalse( false );
	}

	public function testEquals(){
		Assert.equals( "A", "A" );
	}
	
}
