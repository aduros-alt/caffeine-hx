/*
 * Copyright (c) 2008, The Caffeine-hx project contributors
 * Original author : Danny Wilson - deCube.net.
 * Based on haxe.unit written by Nicolas Cannasse.
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE CAFFEINE-HX PROJECT CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE CAFFEINE-HX PROJECT CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */
package hxspec;
 import haxe.unit.TestStatus;

class SpecRunner {
	var result : SpecResult;
	var cases  : List<hxspec.Specification>;

#if flash9
	static var tf : flash.text.TextField = null;
#else flash
	static var tf : flash.TextField = null;
#end

	public static dynamic function print( v : Dynamic ) {
		#if flash9
		untyped {
			if( tf == null ) {
				tf = new flash.text.TextField();
				tf.selectable = false;
				tf.width = flash.Lib.current.stage.stageWidth;
				tf.autoSize = flash.text.TextFieldAutoSize.LEFT;
				flash.Lib.current.addChild(tf);
			}
			tf.appendText(v);
		}
		#else flash
		untyped {
			var root = flash.Lib.current;
			if( tf == null ) {
				root.createTextField("__tf",1048500,0,0,flash.Stage.width,flash.Stage.height+30);
				tf = root.__tf;
				tf.selectable = false;
				tf.wordWrap = true;
			}
			var s = flash.Boot.__string_rec(v,"");
			tf.text += s;
			while( tf.textHeight > flash.Stage.height ) {
				var lines = tf.text.split("\r");
				lines.shift();
				tf.text = lines.join("\n");
			}
		}
		#else neko
		untyped __dollar__print(v);
		#else js
		untyped {
			var msg = StringTools.htmlEscape(js.Boot.__string_rec(v,"")).split("\n").join("<br/>");
			var d = document.getElementById("haxe:trace");
			if( d == null )
				alert("haxe:trace element not found")
			else
				d.innerHTML += msg;
		}
		#else error
		#end
	}

	private static function customTrace( v, ?p : haxe.PosInfos ) {
		print(p.fileName+":"+p.lineNumber+": "+Std.string(v)+"\n");
	}

	public function new() {
		result = new SpecResult();
		cases = new List();
	}

	public function add( c:hxspec.Specification ) : Void {
		cases.add(c);
	}

	public function run() : Bool {
		result = new SpecResult();
		for ( c in cases ){
			runCase(c);
		}
		print(result.toString());
		return result.success;
	}

	function getBT( e : Dynamic ) {
		#if flash9
		if( e != null && Std.is(e,untyped __global__["Error"] ) )
			return e.getStackTrace();
		return null;
		#else true
		return haxe.Stack.toString(haxe.Stack.exceptionStack());
		#end
	}

	function runCase( t:hxspec.Specification ) : Void 	{
		var old = haxe.Log.trace;
		haxe.Log.trace = customTrace;

		var cl = Type.getClass(t);
		var fields = Type.getInstanceFields(cl);

		print( "Class: "+Type.getClassName(cl)+" ");
		for ( f in fields ){
			var fname = f;
			var field = Reflect.field(t, f);
			if ( StringTools.startsWith(fname.toLowerCase(),"should") && Reflect.isFunction(field) ){
				t.currentTest = new TestStatus();
				t.currentTest.classname = Type.getClassName(cl);
				t.currentTest.method = fname;
				t.before();
				
				try {
					Reflect.callMethod(t, field, []);
					
					if( t.currentTest.done ){
						t.currentTest.success = true;
						print(".");
					}else{
						t.currentTest.success = false;
						t.currentTest.error = "(warning) Not specified.";
						print("W");
					}
				}catch ( e : TestStatus ){
					print("F");
					t.currentTest.backtrace = getBT(e);
				}catch ( e : Dynamic ){
					print("E");
					#if js
					if( e.message != null ){
						t.currentTest.error = "because exception was thrown: "+e+" ["+e.message+"]";
					}else{
						t.currentTest.error = "because exception was thrown: "+e;
					}
					#else
					t.currentTest.error = "because exception was thrown: "+e;
					#end
					t.currentTest.backtrace = getBT(e);
				}
				result.add(t.currentTest);
				t.after();
			}
		}

		print("\n");
		haxe.Log.trace = old;
	}
}
