/*
* The idea behind this Unit system is to avoid using anything that is not very-very basic.
* No Lists, no StringBuf, few Reflection/Type calls.
*/
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
    php.Lib.print(StringTools.htmlEscape(v));
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

  private function dotted(s : String) {
	var l = s.length;
	for(i in l...50)
		s += '.';
	return s;
  }
  
  public function run() {
    var tests_tot       = 0;
    var tests_ok        = 0;
    var tests_error     = 0;
    var tests_failed    = 0;
    var tests_withdrawn = 0;
    
    var result = '';
    for(t in test_classes) {
      var messages = [];
      var cname = Type.getClassName(Type.getClass(t));
      result += "\n\ntesting: " + cname;
      var tests = getTestMethods(t);
      var i = 1;
      var tot = tests.length;
      for(test in tests) {
      var passed = true;
      var error = false;
      var assertions = Assert.counter;
      try {
        result += "\n";
        result += "      "+dotted(Std.string(i) + ". " + test);
        Reflect.callMethod(t, Reflect.field(t, test), []);
      } catch(e : AssertException) {
        passed = false;
        messages.push(test + " failed at #" + e.pos.lineNumber + ", " + e.message);
      } catch(e : Dynamic) {
        passed = false;
        error = true;
        messages.push(test + " error: " + Std.string(e));
      }
      if(passed) {
        if(assertions == Assert.counter) {
          tests_withdrawn++;
        result += 'WITHDRAWN';
        } else {
          tests_ok++;
        result += '.......OK';
        }
      } else if(error) {
        tests_error++;
        result += '....ERROR';
      } else {
        tests_failed++;
        result += '...FAILED';
      }
      i++;
          tests_tot++;
      }
      if(messages.length > 0) {
      for(message in messages)
        result += "\n-------> " + message;
      }
    }
    var tots = "tested classes:    " + test_classes.length;
    tots += "\ntotal tests:       " + tests_tot;
    tots += "\npassed tests:      " + tests_ok;
    tots += "\nfailed tests:      " + tests_failed;
    tots += "\ntests with errors: " + tests_error;
    tots += "\nwithdrawn tests:   " + tests_withdrawn;
	
    print(tots);
    print(result);
	
  }

  private function getTestMethods(t) {
    var allFields = Type.getInstanceFields(Type.getClass(t));
	var testFields = [];
	for(name in allFields) {
	  if(name.substr(0, 4) == "test") {
	    var field = Reflect.field(t, name);
		if(Reflect.isFunction(field)) {
			testFields.push(name);
		}
	  }
	}
	return testFields;
  }
}