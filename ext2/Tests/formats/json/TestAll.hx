import formats.json.JSON;

class X {
  var a : Int;
  var b : String;

  public function new() {
    a = 42;
    b = "foobar";
  }
}

class TestAll extends haxe.unit.TestCase {

	public function testSimple() {
		var v = {x:"nice",y:"one"};
		var e = JSON.encode(v);
		assertEquals(e,"{\"x\":\"nice\",\"y\":\"one\"}");
		var d = JSON.decode(e);
		assertEquals(v.y,d.y);
		assertEquals(v.x,d.x);
	}

	public function testNumVal() {
		var v = {x:2};
		var e = JSON.encode(v);
		var d = JSON.decode(e);
		assertEquals(v.x,d.x);
	}

	public function testStrVal() {
		var v = {y:"blackdog"};
		var e = JSON.encode(v);
		var d = JSON.decode(e);
		assertEquals(d.y,"blackdog");
	}

	public function testWords() {

		var p:Dynamic = JSON.decode('{"y":null}');
		assertEquals(p.y,null);

		 p = JSON.decode('{"y":true}');
		assertEquals(p.y,true);

		 p = JSON.decode('{"y":false}');
		assertEquals(p.y,false);
	}

	public function testStrArray() {
		var a = ["black","dog","is","wired"];
		var e = JSON.encode(a);
		var d = JSON.decode(e);
		var i = 0;
		while (i <	a.length) {
			assertEquals(a[i],d[i]);
			i++;
		}
	}

	public function testNumArray() {
		var a = [5,10,400000,1.32];
		var e = JSON.encode(a);
		var d = JSON.decode(e);
		var i = 0;
		while (i <	a.length) {
			assertEquals(a[i],d[i]);
			i++;
		}
	}

	public function testObjectObject() {
		var o = {x: {y:1} } ;
		var e = JSON.encode(o);
		var d = JSON.decode(e);
			throw "bla";
		assertEquals(d.x.y ,1);
	}

	public function testObjectArray() {
		var o = {x:[5,10,400000,1.32,1000,0.0001]};
		var e = JSON.encode(o);
		var d = JSON.decode(e);
		var i = 0;
		while (i < o.x.length) {
			assertEquals(o.x[i],d.x[i]);
			i++;
		}
	}

	public function testObjectArrayObject() {
		var o = {x:[5,10,{y:4},1.32,1000,0.0001]};
		var e = JSON.encode(o);
		var d = JSON.decode(e);
		assertEquals(d.x[2].y ,4);
	}


	public function testObjectArrayObjectArray() {
		var o = {x:[5,10,{y:[0,1,2,3,4]},1.32,1000,0.0001]} ;
		var e = JSON.encode(o);
		var d = JSON.decode(e);
		assertEquals(d.x[2].y[3] ,3);
	}

	public function testQuoted() {
		var o = {msg:'hello world\"s'};
		var e = JSON.encode(o);
		var d = JSON.decode(e);
		assertEquals(o.msg,d.msg);
	}

	public function testNewLine() {
		var o = {msg:'hello\nworld\nhola el mundo'};
		var e = JSON.encode(o);
		var d = JSON.decode(e);
		assertEquals(o.msg,d.msg);
	}

	public function testABitMoreComplicated() {
		var o = '{"resultset":[{"link":"/vvvv/hhhhhhh.pl?report=/opt/apache/gggg/tmp/gggg_JYak2WWn_2-3.blastz&num=30&db=GEvo_JYak2WWn.sqlite","color":"0x69CDCD","features":{"3":[289,30,297,40],"2":[633,30,637,50]},"annotation":"
Match: 460
Length: 590
Identity: 82.10
E_val: N/A"}]}';

		var d = JSON.decode(o);

		var resultset:Array<Dynamic> = d.resultset;

		var features = resultset[0].features;
		var fld2 = Reflect.field(features,"2");
		assertEquals(fld2[0],633);

		trace(resultset[0].annotation);
        trace(resultset[0].features);

	}

	public function testList() {

		var o = new List<{name:String,age:Int}>() ;
		o.add({name:"blackdog",age:41});

		var e:Dynamic = JSON.encode(o);
		trace("encoded:"+e);
		var d:Dynamic = JSON.decode(e);
		trace("decoded:"+d);
		assertEquals(o.first().name,d[0].name);
	}

/*
	public function testObjectEncoding() {
		//var v = { x : "f", y: 3};
		var v = new X();

		var encoded_text = JSON.encode(v);
		trace("Encoded as " + encoded_text);

		var decoded_text : Dynamic  = JSON.decode(encoded_text);
		trace("Decoded as " + decoded_text);
		trace(Std.string(decoded_text));

	}
//	*/
}
