import protocols.http.Cookie;
import dates.GmtDate;

class CookieFunctions extends haxe.unit.TestCase {

	public function testOne() {
		var c = new Cookie("mycookie", "myvalue");

		assertEquals("Set-Cookie: mycookie=myvalue", Cookie.toSingleLineString([c]));
		assertEquals("Set-Cookie: mycookie=myvalue", c.toString());

		//var d = new Date(2008,09,15,0,0,0);
		var gd = GmtDate.fromString("Wed, 15 Oct 2008 06:00:00 GMT");
		var d = gd.getLocalDate();
		c.expires = d;
		trace(c.toString());

		assertEquals("Set-Cookie: mycookie=myvalue; expires=Wed, 15 Oct 2008 06:00:00 GMT", c.toString());
	}

}

class ProtocolsTest {

	public static function main() {
#if (FIREBUG && ! neko)
		if(haxe.Firebug.detect()) {
			haxe.Firebug.redirectTraces();
		}
#end
		var r = new haxe.unit.TestRunner();
		r.add(new CookieFunctions());
		r.run();
	}
}
