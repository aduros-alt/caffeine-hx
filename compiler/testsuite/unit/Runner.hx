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

  private function print(v : String) {
#if php
    php.Lib.print(v);
#else flash9
	if( tf == null ) {
		tf = new flash.text.TextField();
		tf.selectable = true;
		tf.width = flash.Lib.current.stage.stageWidth;
		tf.autoSize = flash.text.TextFieldAutoSize.LEFT;
		flash.Lib.current.addChild(tf);
	}
	tf.text += v;
#else flash
	var root = flash.Lib.current;
	if( tf == null ) {
		root.createTextField("__tf",1048500,0,0,flash.Stage.width,flash.Stage.height+30);
		tf = untyped root.__tf;
		tf.selectable = true;
		tf.multiline = true;
	}
	tf.text += v;
#else neko
	neko.Lib.print(v);
#else js
	var d = js.Lib.document.getElementById("haxe:trace");
	if( d == null )
		js.Lib.alert("haxe:trace element not found")
	else
		d.innerHTML += v;
#else hllua
	lua.Lib.print(v);
#end
  }

  private function println(v : String) {
    print(v + "\n");
  }

  public function run() {
    println("classes to test: " + test_classes.length + "");
    for(t in test_classes) {
	  var messages = [];
	  print("testing class: " + Type.getClassName(t) + " ");
	  var inst = Type.createInstance(t, []);
	  var tests = getTestMethods(inst, t);
	  var i = 1;
	  var tot = tests.length;
	  for(test in tests) {
		var passed = true;
		var error = false;
		try {
		  Reflect.callMethod(inst, Reflect.field(inst, test), []);
		} catch(e : AssertException) {
		  passed = false;
		  messages.push(test + " failed at line #" + e.pos.lineNumber + ", " + e.message);
		} catch(e : Dynamic) {
		  passed = false;
		  error = true;
		  messages.push(test + " error: " + Std.string(e));
		}
		if(passed)
		  print('.');
		else if(error)
		  print('E');
		else
		  print('F');
		i++;
	  }
	  println('   ');
	  if(messages.length > 0) {
	    println("!!! Huston we have a problem (maybe more): " + messages.length + " failed test(s) out of " + tot);
		for(message in messages)
		  println("!!! " + message);
	  }
	}
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