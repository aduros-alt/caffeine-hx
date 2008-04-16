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

	public function print(v : String) {
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
			var setup = Reflect.field(t, "setup");
			var teardown = Reflect.field(t, "teardown");
			
			for(test in tests) {
				var passed = false;
				var failure : String = null;
				var assertions = Assert.counter;
								
				result += "\n";
				result += "      "+dotted(Std.string(i) + ". " + test);
				// run setup
				try {
					if(setup != null)
						Reflect.callMethod(t, setup, []);
					// run test
					try {
						Reflect.callMethod(t, Reflect.field(t, test), []);
						passed = true;
					} catch(e : AssertException) {
						failure = "........FAILED";
						messages.push(test + " failed at #" + e.pos.lineNumber + ", " + e.message);
					} catch(e : Dynamic) {
						failure = ".........ERROR";
						messages.push(test + " error: " + Std.string(e));
					}
				} catch(e : Dynamic) {
					failure = "...SETUP ERROR";
					messages.push(test + " setup failed: " + Std.string(e));
				}
				// run teardown
				try {
					if(teardown != null) 
						Reflect.callMethod(t, teardown, []);
				} catch(e : Dynamic) {
					if(failure == null)
						failure = "TEARDOWN ERROR";
					messages.push(test + " teardown failed: " + Std.string(e));
				}
				
				if(passed) {
					if(assertions == Assert.counter) {
						tests_withdrawn++;
						result += '.....WITHDRAWN';
					} else {
						tests_ok++;
						result += '............OK';
					}
				} else {
					if(failure == '........FAILED')
						tests_failed++;
					else
						tests_error++;
					result += failure;
				}
				i++;
				tests_tot++;
			}
			if(messages.length > 0)
				for(message in messages)
					result += "\n-------> " + message;
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