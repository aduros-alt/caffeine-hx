/*
 * Copyright (c) 2009, The Caffeine-HX Project Contributors
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
 * THIS SOFTWARE IS PROVIDED BY THE HAXE PROJECT CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE HAXE PROJECT CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 *
 * Author:
 *  Danny Wilson - deCube.net
 */

package event;
 import event.Event;

/**
	Every AutoEventGroup that is instantiated, will have it's event dispatchers automatically instantiated
	using the haxe.rtti.Infos. So all you have to do to create your own Event group, is extend.
	
	For example:
	
	class MyMouseEvents extends EventGroup {
		var thisIsnotAnEvent : Bool;
		var move : Event<{ x : Int, y : Int } -> MyComponent -> Void>;
	}
	
	var x = new MyMouseEvents();
	trace(x.move); // Event
	trace(x.thisIsnotAnEvent); // null
**/
class AutoEventGroup extends BasicEventGroup, implements haxe.rtti.Infos
{
	public function new() {
		rtti();
		super();
	}
	
	/**	This method initializes all event dispatchers using haxe.rtti **/
	private function rtti()
	{
		var cl = Type.getClass(this),
			rf = Reflect.field,
			sf = Reflect.setField,
			af : Array<String> = untyped cl.fields;
		
		if( af == null )
		{
			af = untyped cl.fields = new Array();
			var f:Xml, xml = Xml.parse(untyped cl.__rtti);
			for(x in xml.firstElement().elements())
				if( (f = x.firstElement()) != null && f.nodeName == 'c' && f.get('path') == 'hxbase.event.Event') {
					af.push(x.nodeName);
					if( rf(this, x.nodeName) == null )
						sf(this, x.nodeName, new Dispatcher());
				}
		}
		else for(f in af)
			if(rf(this, f) == null) sf(this, f, new Dispatcher());
	}
}
