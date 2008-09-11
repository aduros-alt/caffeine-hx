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
package haxe.spec;
 import haxe.unit.TestStatus;

class SpecResult {

	var m_tests : List<TestStatus>;
	public var success(default,null) : Bool;

	public function new() {
		m_tests = new List();
		success = true;
	}

	public function add( t:TestStatus ) : Void {
		m_tests.add(t);
		if( !t.success )
			success = false;
	}

	public function toString() : String
	{
		var buf = new StringBuf();
		var failures = 0;
		for ( test in m_tests ){
			if (test.success == false){
				buf.add("* ");
				buf.add(test.classname);
				buf.add(' - ');
				var m = test.method;
				for(i in 0 ... m.length) {
					var c = m.charAt(i);
					buf.add( if(c == '_') ' ' else c ); // Convert _ to [space]
				}
				buf.add('\n');

				buf.add('Failed ');
				if( test.posInfos != null )
				{
					buf.add('[');
					buf.add(test.posInfos.fileName);
					buf.add(":");
					buf.add(test.posInfos.lineNumber);
					buf.add("] ");
				/*	buf.add(test.posInfos.className);
					buf.add(".");
					buf.add(test.posInfos.methodName);
					buf.add(") - ");
				*/}
				buf.add(test.error);
				buf.add("\n");

				if (test.backtrace != null) {
					buf.add(test.backtrace);
					buf.add("\n");
				}

				buf.add("\n");
				failures++;
			}
		}
		buf.add("\n");
		if (failures == 0)
			buf.add("OK - ");
		else
			buf.add("FAILED - ");

		buf.add(m_tests.length);
		buf.add(" expectations, ");
		buf.add(failures);
		buf.add(" failed, ");
		buf.add( (m_tests.length - failures) );
		buf.add(" success");
		buf.add("\n");
		return buf.toString();
	}

}
