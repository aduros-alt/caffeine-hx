class Base {
	static var guh : Int = 2;

	public function new() {}
	public function val() : Int {
		var v = 0;
		try {
			v = 1;
		}
		catch(e:Int) {
		}
		catch(e:Float) {
		}
		catch(e:Test) {
		}
		catch(e:Dynamic) {
		}
		return guh;
	}
}

class Test extends Base {
	var a : Int;
	public function new(va : Int) {
		super();
		a = va;
	}

	override public function val() : Int {
		var v = super.val();
		return v;
	}

	public static function main() {
/*
		trace("Hello world");
*/
#if neko
		neko.Lib.print("Hello world");
#else lua
		lua.Lib.print("Hello world");

		var s = new Test(67);
		var ms = "Hi";
		var fs = ms + " there";
		lua.Lib.print(fs);
		var sb = new StringBuf();
		sb.add("Hi");
		lua.Lib.print(sb.toString());
		lua.Lib.print(sb.toString().charCodeAt(1));
#end
	}
}
