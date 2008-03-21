package unit;

import haxe.PosInfos;

class Runner {
  public function new() {
	test_classes = [];
  }

  private var test_classes : Array<Dynamic>;
  public function register(t : Dynamic) {
	test_classes.push(t);
  }

#if flash9
	static var tf : flash.text.TextField = null;
#else flash
	static var tf : flash.TextField = null;
#end

  private function println(v : String) {
#if php
    php.Lib.print(v + "</br>");
#else flash9
	if( tf == null ) {
		tf = new flash.text.TextField();
		tf.selectable = true;
		tf.width = flash.Lib.current.stage.stageWidth;
		tf.autoSize = flash.text.TextFieldAutoSize.LEFT;
		tf.multiline = true;
		flash.Lib.current.addChild(tf);
	}
	tf.htmlText += v + "</br>";
#else flash
	var root = flash.Lib.current;
	if( tf == null ) {
		root.createTextField("__tf",1048500,0,0,flash.Stage.width,flash.Stage.height+30);
		tf = untyped root.__tf;
		tf.selectable = true;
		tf.html = true;
		tf.multiline = true;
	}
	tf.htmlText += v + "</br>";
#else neko
	neko.Lib.print(v + "</br>");
#else js
	var d = js.Lib.document.getElementById("haxe:trace");
	if( d == null )
		js.Lib.alert("haxe:trace element not found")
	else
		d.innerHTML += v + "</br>";
#else lua
	lua.Lib.println(v);
#end
  }

  public function run() {
    println("<pre>classes to test: <b>" + test_classes.length + "</b>");
    for(t in test_classes) {
	  println("   ");
	  println("testing class: <b>" + Type.getClassName(t) + "</b>");
	  var inst = Type.createInstance(t, []);
	  var tests = getTestMethods(inst, t);
	  var i = 1;
	  var tot = tests.length;
	  var failures = 0;
	  for(test in tests) {
	    var msg = "... test " + i + " of " + tot + ", <i>" + test + "</i>:";
		var passed = true;
		try {
		  Reflect.callMethod(inst, Reflect.field(inst, test), []);
		} catch(e : AssertException) {
		  passed = false;
		  msg += "<i>" + e.message + " at line #" + e.pos.lineNumber + "</i>";
		  failures++;
		} catch(e : Dynamic) {
		  passed = false;
		  msg += "<i>" + "uncaught exception " + Std.string(e) + "</i>";
		  failures++;
		}
		if(passed)
		  msg += " <b>OK</b>";

		println(msg);
		i++;
	  }
	  if(failures == 0)
		println("<i>all tests passed</i>");
	  else
	    println("Huston we have a problem: <b>" + failures + " failed test(s)</b> out of " + tot);
	}
	println("</pre>");
  }

  private function getTestMethods(inst, cl) {
    var allFields = Type.getInstanceFields(cl);
	var testFields = [];
	for(name in allFields) {
	  if(name.substr(0, 4) == "test") {
	    var field = Reflect.field(inst, name);
		if(Reflect.isFunction(field)) {
			testFields.push(name);
		}
	  }
	}
	return testFields;
  }
}