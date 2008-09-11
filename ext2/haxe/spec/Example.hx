/*
 * Copyright (c) 2008, The Caffeine-hx project contributors
 * Original author : Danny Wilson - deCube.net.
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

class Example extends haxe.spec.Specification
{
	static function main()
	{
		var r = new haxe.spec.SpecRunner();
		r.add(new Example());
		r.run();
	}
	
	var number:Int;
	var someText:String;
	
	function before() {
		// Do this before every test
		number = 1;
		someText = "This is an example specification";
	}
	
	function after() {
		// Do this after every test
		number = 0;
		someText = "Enjoy!";
	}
	
	function Should_be_a_clear_example() {
		The(number).should.be.greaterThen(0);
	}
	
	function Should_be_useful_for_Behaviour_Driven_Development() {
		Calling(this.before()).should.not._return.value("Bla bla bla");
		Field(this.someText).should.contain.text("example");
		Var([0,2,3,4,5]).should.not.contain.value(number);
	}
	
	function Should_fail_this_specification() {
		The(number).should.be.lessThen(0);
	}
} 
