import protocols.http.Cookie;
import dates.GmtDate;


#if (neko || php)

import system.Posix;

class PosixTest extends haxe.unit.TestCase {
	public function testOne() {
		trace("");
		trace("system.Posix results: ");
		trace("Process ID: " + Posix.getpid());
		trace("ctermid: " + Posix.ctermid());
		trace("Effective User ID: " + Posix.geteuid());
		trace("User ID: " + Posix.getuid());
		trace("Effective Group ID: " + Posix.getegid());
		trace("Group ID: " + Posix.getgid());

		trace("Uname: " + Posix.uname());
		assertEquals(1,1);
	}
}
#end

class SystemTest {

	public static function main() {
#if (FIREBUG && ! neko)
		if(haxe.Firebug.detect()) {
			haxe.Firebug.redirectTraces();
		}
#end
		var r = new haxe.unit.TestRunner();
#if (neko || php)
		r.add(new PosixTest());
#end
		r.run();
	}
}
