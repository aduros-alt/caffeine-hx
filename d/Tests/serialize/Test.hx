
enum MyEnum {
	Nada;
	Zero;
	One(a:Int);
	Two(a:String, b:Float);
	Three(d:Date);
}

class MyClass {
	var e : MyEnum;
	var a : Int;
	var b : Null<Int>;
	var c : Array<String>;
	var d : String;
	var ni: Float;
	var pi: Float;
	var nn: Float;

	public function new() {
		a = 5;
		b = null;
		c = new Array();
		c[0] = "Hello";
		d = "Uncle";
		ni = Math.NEGATIVE_INFINITY;
		pi = Math.POSITIVE_INFINITY;
		nn = Math.NaN;
	}
}

class Test {
	public static function main() {
		var c = new MyClass();
		neko.Lib.println(haxe.Serializer.run(c));

		var e = Nada;
		neko.Lib.println(haxe.Serializer.run(e));

		e = One(456);
		neko.Lib.println(haxe.Serializer.run(e));

		haxe.Serializer.USE_ENUM_INDEX = true;
		neko.Lib.println(haxe.Serializer.run(e));

		//trace(haxe.Unserializer.run(haxe.Serializer.run(e)));
		//trace(haxe.Unserializer.run("jy6:MyEnum:2:1i456"));
		//trace(untyped e.index);
	}
}