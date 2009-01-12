/*
 * Copyright (c) 2008, The Caffeine-hx project contributors
 * Original author: Danny Wilson - deCube.net
 * Contributors:
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
package specifications.dbee;

class MockDatafield implements dbee.field.Datafield
{
	private var _v:Dynamic;
	private var _escMe : Bool;
	
	public var value(getValue,setValue) : Dynamic;
	public var isValid : Bool;
	public var changed : Bool;
	public var required: Bool;
	
	private var _value:Dynamic;
		function getValue(){
			if(_value == null && _v != null){ _value = _v; _v = null; }
			if(_value == null) setValue('default');
			return new String(_value);
		}
		function setValue(v:String){
			_value = untyped v.__s;
			changed = true;
			return v;
		}
	
	public function new(){
		_escMe	 = false;
		isValid  = false;
		changed  = false;
		required = false;
	}
	
	public function changeValue(){
		isValid = true;
		setValue('changed');
		changed = true;
		dbee.Events.valueChanged.call(this);
	}
	
	public function toXML(){
		return Xml.createCData("MockDataField");
	}
	
	public function toURI(){
		return 'MockDataField';
	}
	
	public function toHTML(){
		return '<span>'+value+'</span>';
	}
	
	public function toString(){
		return '[MockDataField]';
	}
	
	public function serialize(){
		return if(_value != null) value else untyped getValue().__s;
	}
	
	public function deSerialize(s){
	//	trace("Deserialize: "+s);
		setValue(s);
		changed = false;
	}
	
	public function equals(data:Dynamic){
		// Direct
		if( data == this ) return true;
		// String
		if( data == this.value ) return true;
		// Datafield
		var v = untyped data._value;
		return( v != null && v == _value );
	}
}
