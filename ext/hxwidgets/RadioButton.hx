/*
 * Copyright (c) 2008, The Caffeine-hx project contributors
 * Original author : Russell Weir
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

package hxwidgets;
import flash.events.Event;

class RadioButton extends CheckBox {

	static var rbGroups : Hash<List<RadioButton>> = new Hash();
	var rbMemberOf : List<String>;

	public function new(
		id:String,
		label:Label,
		groups : Array<String>,
		?onClick : BaseButton->Event->Void,
		?pos:Point)
	{
		rbMemberOf  = new List();
		super(id,label,onClick,pos);
		checked = false;
		if(groups != null) {
			for(s in groups) {
				rbSubscribeTo(s);
			}
		}
	}

	override public function getUIClassName() { return "RadioButton"; }

	override function setChecked(v) {
		var ov = v;
		if(rbMemberOf.length > 0 && v == false) {
			var found = 0;
			for(s in rbMemberOf) {
				var g = rbGroups.get(s);
				if(g != null) {
					for(i in g) {
						if(i != this && i.checked)
							found++;
					}
				}
			}
			if(found != rbMemberOf.length)
				v = true;
		}
		super.setChecked(v);
		if(checked) {
			for(s in rbMemberOf) {
				var g = rbGroups.get(s);
				if(g != null) {
					for(i in g) {
						if(i != this)
							i.setChecked(false);
					}
				}
			}
		}
		return ov;
	}

	function rbSubscribeTo(s:String) {
		rbMemberOf.remove(s);
		var mg = rbGroups.get(s);
		if(mg == null) {
			var l = new List();
			l.add(this);
			rbGroups.set(s, l);
			setChecked(true);
		}
		else {
			var found = false;
			for(i in mg) {
				if(i == this) {
					found = true;
					break;
				}
			}
			if(!found) {
				mg.add(this);
				// an existing box should already be checked
				setChecked(false);
			}
		}
		rbMemberOf.add(s);
	}
}