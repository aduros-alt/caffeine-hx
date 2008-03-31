package stdlib;

import unit.Assert;

class TestHtmlDom {
	public function new(){}
	
	public function testAttribute() {
		var e = js.Lib.document.getElementById("testattr");
	
		Assert.equals("testattr",e.getAttribute("id"));

		// '' (empty string) on opera 8.54
		//Assert.equals(null,e.getAttribute("foobar"));

		Assert.equals("1",e.getAttribute("foo"));

		// '' (empty string) on opera 8.54
		//Assert.equals("3",e.getAttribute("x:bar"));

		// not working on IE 5.5/6/7beta2
		//Assert.equals("2",e.getAttribute("class"));

		// not working on firefox, others ?
		//Assert.equals("4",e.getAttribute("x:bar"));

	}
	
}
