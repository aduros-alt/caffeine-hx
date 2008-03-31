package stdlib;

import unit.Assert;

class TestHttp {
	public function new(){}
	
	#if neko
	public function testVirtualMotionTwin(){
		var r = haxe.Http.request("http://virtual.motion-twin.com/up");

		Assert.isTrue(r != null);
		Assert.equals("OK",StringTools.trim(r));
	}
	#end
	
}
