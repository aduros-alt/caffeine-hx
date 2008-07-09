
enum MyEnum {
	Nada;
	Zero;
	One(a:Int);
	Two(a:String, b:Float);
	Three(d:Date);
}

class MyClass {
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
	static var println : Dynamic = #if neko neko.Lib.println #else true trace #end;
	public static function main() {
		var c = new MyClass();
		println(haxe.Serializer.run(c));
	}
}