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
 import event.EventSystem;

#if flash9
import flash.events.MouseEvent;
#else error
#end

class MouseState extends ShiftCtrlAltMod
{
	public var x			(default,null)	: Float;
	public var y			(default,null)	: Float;
	public var xStage	(default,null)	: Float;
	public var yStage	(default,null)	: Float;
	public var button	(default,null)	: Int;
	
	public function new( x:Float, y:Float, xStage:Float, yStage:Float, ?button:Int, ?shiftMod:Bool, ?ctrlMod:Bool, ?altMod:Bool )
	{
		this.x = x;
		this.y = y;
		this.xStage = xStage;
		this.yStage = yStage;
		this.button = button;
		super(shiftMod, ctrlMod, altMod);
    }
	
	public function toString() :String
	{
		var r = "MouseState("+x+","+y+", ";
		if( shiftMod )	r+="Shift-";
		if( ctrlMod )	r+="Ctrl-";
		if( altMod )	r+="Alt-";
		r+="[Button "+button+"])";
		return r;
    }
}

/**
	Event.global() gives access to global mouseEvents, with stage coordinates.
**/
class MouseEvents extends BasicEventGroup
{
	var down		: Dispatcher<MouseState	-> Void>;
	var up		: Dispatcher<MouseState	-> Void>;
	var move		: Dispatcher<MouseState	-> Void>;
	var over		: Dispatcher<MouseState	-> Void>;
	var out		: Dispatcher<MouseState	-> Void>;
	var scroll	: Dispatcher<Int			-> Void>;
	
 #if flash9	
	static private function toMouseState(e:MouseEvent):MouseState {
		return new MouseState( e.localX, e.localY, e.stageX, e.stageY, e.buttonDown ? 1 : 0, e.shiftKey, e.ctrlKey, e.altKey );
	}
	
	private function preBind(parent:flash.events.EventDispatcher, evt:String) {
		return function(d:ProxiedDispatcher<Dynamic>){ 
			if (d.proxy_data == null)
				d.proxy_data = function(e:MouseEvent){ d.call(toMouseState(e)); };
			
			parent.addEventListener(evt, d.proxy_data);
		}
	}
	
	private function preScrollBind(parent:flash.events.EventDispatcher) {
		return function(d:ProxiedDispatcher<Dynamic>){ 
			if (d.proxy_data == null)
				d.proxy_data = function(e:MouseEvent){ d.call( e.delta ); };
			
			parent.addEventListener(MouseEvent.MOUSE_WHEEL, d.proxy_data);
		}
	}
	
	private function allUnbound(parent:flash.events.EventDispatcher, event:String)
	{
		return function(d:ProxiedDispatcher<Dynamic>){ 
			parent.removeEventListener(event, d.proxy_data);
		}
	}
	
	function new( parent:flash.events.EventDispatcher ) {
		down	= new ProxiedDispatcher( preBind(parent, MouseEvent.MOUSE_DOWN	),	allUnbound(parent, MouseEvent.MOUSE_DOWN)		);
		up		= new ProxiedDispatcher( preBind(parent, MouseEvent.MOUSE_UP	),	allUnbound(parent, MouseEvent.MOUSE_UP)		);
		move	= new ProxiedDispatcher( preBind(parent, MouseEvent.MOUSE_MOVE	),	allUnbound(parent, MouseEvent.MOUSE_MOVE)		);
		over	= new ProxiedDispatcher( preBind(parent, MouseEvent.MOUSE_OVER	),	allUnbound(parent, MouseEvent.MOUSE_OVER)		);
		out		= new ProxiedDispatcher( preBind(parent, MouseEvent.MOUSE_OUT	),	allUnbound(parent, MouseEvent.MOUSE_OUT)		);
		scroll	= new ProxiedDispatcher( preScrollBind(parent),					allUnbound(parent, MouseEvent.MOUSE_WHEEL)	);
		
		super();
	}
 #else error
 #end	
}
