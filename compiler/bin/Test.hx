class Base {
	static var guh : Int = 2;

	public function new() {}
	public function val() : Int { return guh; }
}

class Test extends Base {
	var a : Int;
	public function new(va : Int) {
		super();
		a = va;
	}

	public static function main() {
/*
		trace("Hello world");
*/
#if neko
		neko.Lib.print("Hello world");
#else lua
		lua.Lib.print("Hello world");
#end
		var s = new Test(67);
	}
}
