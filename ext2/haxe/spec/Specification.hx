/*
 * Copyright (c) 2008, The Caffeine-hx project contributors
 * Original author : Danny Wilson - deCube.net.
 * Partly based on haxe.unit written by Nicolas Cannasse.
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
 import haxe.PosInfos;

class EqualityCheck implements haxe.Public
{
	private var isNot		: Bool;
	private var val			: Dynamic;
	private var currentTest : TestStatus;
	
	public function new(value:Dynamic, currentTest:TestStatus, isNot:Bool)
	{
		this.val = value;
		this.currentTest = currentTest;
		this.isNot = isNot;
	}
	
	function _true( ?c : PosInfos ) : Void {
		currentTest.done = true;
		if( val == (if(isNot) true else false) ){
			currentTest.success = false;
			currentTest.error   = "expected "+(if(isNot)"not "else"")+"true but was "+Std.string(val);
			currentTest.posInfos = c;
			throw currentTest;
		}
	}
	
	function greaterThan<T>( number:Float, ?c:PosInfos ) : Void {
		currentTest.done = true;
		if( (isNot && val > number) || (!isNot && !(val > number)) ){
			currentTest.success = false;
			currentTest.error   = "expected a greater value, but the expression was "+ (if(isNot)"not "else"") + Std.string(val) + " > " + Std.string(number);
			currentTest.posInfos = c;
			throw currentTest;
		}
	}

	function greaterThanOrEqualTo<T>( number:Float, ?c:PosInfos ) : Void {
		currentTest.done = true;
		if( (isNot && val >= number) || (!isNot && !(val >= number)) ){
			currentTest.success = false;
			currentTest.error   = "expected a greater value, but the expression was "+ (if(isNot)"not "else"") + Std.string(val) + " > " + Std.string(number);
			currentTest.posInfos = c;
			throw currentTest;
		}
	}
	
	function lessThan<T>( number:Float, ?c:PosInfos ) : Void {
		currentTest.done = true;
		
		if( (isNot && val < number) || (!isNot && !(val < number)) ){
			currentTest.success = false;
			currentTest.error   = "expected a lesser value, but the expression was "+ (if(isNot)"not "else"") + Std.string(val) + " < " + Std.string(number);
			currentTest.posInfos = c;
			throw currentTest;
		}
	}

	function lessThanOrEqualTo<T>( number:Float, ?c:PosInfos ) : Void {
		currentTest.done = true;
		
		if( (isNot && val <= number) || (!isNot && !(val <= number)) ){
			currentTest.success = false;
			currentTest.error   = "expected a lesser value, but the expression was "+ (if(isNot)"not "else"") + Std.string(val) + " < " + Std.string(number);
			currentTest.posInfos = c;
			throw currentTest;
		}
	}

	function _false( ?c : PosInfos ) : Void {
		currentTest.done = true;
		if( val == (if(isNot) false else true) ){
			currentTest.success = false;
			currentTest.error   = "expected "+(if(isNot)"not "else"")+"false but was "+Std.string(val);
			currentTest.posInfos = c;
			throw currentTest;
		}
	}

	function equalTo<T>( expected: T, ?c : PosInfos ) : Void {
		value(expected,c);
	}
	
	function value<T>( expected: T, ?c : PosInfos ) : Void {
		currentTest.done = true;
		if( (isNot && val == expected) || (!isNot && val != expected) ){
			currentTest.success = false;
			currentTest.error   = "expected "+ (if(isNot)"not '"else"'") + Std.string(expected) + "' but was '" + Std.string(val) + "'";
			currentTest.posInfos = c;
			throw currentTest;
		}
	}
	
	function _null( ?c : PosInfos ) : Void {
		currentTest.done = true;
		if ( (isNot && val == null) || (!isNot && val != null) ){
			currentTest.success = false;
			currentTest.error   = "expected "+ (if(isNot)'not 'else'') +"null but was "+ Std.string(val);
			currentTest.posInfos = c;
			throw currentTest;
		}
	}
}

class ContainingCheck implements haxe.Public
{
	private var isNot		: Bool;
	private var val			: Dynamic;
	private var currentTest : TestStatus;
	
	public function new(value:Dynamic, currentTest:TestStatus, isNot:Bool)
	{
		this.val = value;
		this.currentTest = currentTest;
		this.isNot = isNot;
	}
	
	function value( object:Dynamic, ?c : PosInfos ) : Void {
		currentTest.done = true;
		var contains = Lambda.has(val, object);
		if( (isNot && contains) || (!isNot && !contains) ){
			currentTest.success = false;
			currentTest.error   = 'expected "'+val+'" to '+(if(isNot)"not "else"")+'contain "'+object+'".';
			currentTest.posInfos = c;
			throw currentTest;
		}
	}
	
	function text( text:String, ?c : PosInfos ) : Void {
		currentTest.done = true;
		var contains = Std.string(val).indexOf(text) > -1;
		if( (isNot && contains) || (!isNot && !contains) ){
			currentTest.success = false;
			currentTest.error   = 'expected "'+val+'" to '+(if(isNot)"not "else"")+'contain "'+text+'".';
			currentTest.posInfos = c;
			throw currentTest;
		}
	}
}

class Specification implements haxe.Public
{
	public var currentTest : TestStatus;
	public function new();
	
	/** This will run before each specification **/
	public function before() : Void {
	}
	/** This will run after each specification **/
	public function after() : Void {
	}

	function print( v : Dynamic ) {
		haxe.unit.TestRunner.print(v);
	}
	
	/** Use to start a sentence with a variable or state
		The(list.first)
	**/
	function The(value:Dynamic)
	{
		return {should:{
			be : new EqualityCheck(value, currentTest, false),
			contain : new ContainingCheck(value, currentTest, false),
			not: {
				be : new EqualityCheck(value, currentTest, true),
				contain : new ContainingCheck(value, currentTest, true)
			}
		}};
	}

	/** Use to start a sentence with a function call **/
	function Calling(functionResult:Dynamic)
	{
		return {should:{
			_return : new EqualityCheck(functionResult, currentTest, false),
			contain : new ContainingCheck(functionResult, currentTest, false),
			not:{
				_return:new EqualityCheck(functionResult, currentTest, true),
				contain : new ContainingCheck(functionResult, currentTest, true)
			}
		}};
	}
	
	/** Use to start a sentence with a variable **/
	function Var(value:Dynamic)
	{
		return The(value);
	}
	
	/** Use to start a sentence with a property **/
	function Field(value:Dynamic)
	{
		return The(value);
	}
}

/*
class Specification<Target>
{
	var beforeEach	: Void -> Void;
	
	function Describe_as(desc:String)
	{
		
	}
	
	function Subject( instance : Target )
	{
		
	}
	
	function It(should : String)
	{
		if( beforeEach != null ) beforeEach();
	}
	
	function The(value:Dynamic) : Should
	{
		
	}
	
	function Calling(value:Dynamic) : Should
	{
		
	}
	
	function Should_behave_like( spec : Void -> Result )
	{
		
	}
}

class NewSpec implements Dynamic
{
	
}

class StackSpecifications //extends Specification<Account>
{
	var account : NewSpec;
	
	function newStack() {
		stack = new Stack();
	}

	/** A new empty stack ** /
	function EmptyStack()
	{
		Describe_as("an empty Stack");
		beforeEach = newStack;
		afterEach  = newStack;
		Subject(stack);
		
		It("should return the top item when sent #peek");
		The(stack.balance).should.equal(0);
		
		It("should NOT remove the top item when sent #peek");
	    Calling(stack.peek()).should.give(last_item_added);
		Calling(stack.peek()).should.give(last_item_added);
		
		It("should return the top item when sent #pop");
		Calling(stack.pop()).should.give(last_item_added);
		
		It("should throw an EmptyStack exception when popping with no more items left");
		Calling(stack.pop()).should.raise(EmptyStack));
		
		Should_behave_like(EmptyStack);
	}
}
*/
