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

/**
	Here for reference. External AS3 classes must implement these methods.
**/
interface As3ProgressBar {
	function setProgressBarSize(width:Int, height: Int) :Void;
	// Progress value 0.0 - 1.0
	function update(?val : Float):Void;
}

/**
	Current status: ProgressBar is an example of how to use an external Actionscript 3 class
	as a component renderer.
**/
class ProgressBar extends Component {
	/** percentage complete 0.0 - 1.0 **/
	public var value(default, setProgressBarValue) : Float;
	/** allow value to decrease, defaults to false **/
	public var allowDecrease : Bool;
	/** smooths the action of the progress bar. Set < 0 to disable, or number of milliseconds to smooth to **/
	public var smoothing : Float;

	var asAsset : LibraryAsset;
	var asClass : Dynamic;

	// target value for smoother.
	var targetValue : Float;
	var lastUpdated : Float;

	override public function className() { return "ProgressBar"; }

	public function new(id:String, ?bounds:Rectangle) {
		super(id);
		this.smoothing = 3000;
		this.value = 0.0;
		setComponentBounds(bounds);
		onConstructed("ProgressBar");
	}

	override public function setSkin(obj:Dynamic) {
// 		trace(here.methodName);
		if(obj.classname != null) {
			asAsset = new LibraryAsset(obj.classname);
			//asAsset.visible = true;
			asClass = cast asAsset.asset;
			add(asAsset);
			return;
		}
	}

	override public function onRepaint() {
		asClass.setProgressBarSize(
			Std.int(componentBounds.width),
			Std.int(componentBounds.height));
		asClass.update(value);
	}

	function setProgressBarValue(v:Float) : Float {
		var newvalue = Math.max(Math.min(1.0, v),0.0);
		if(Math.isNaN(this.value))
			this.value = newvalue;
		if(newvalue >= this.value || (newvalue < this.value && allowDecrease ))
		{
			var otv = targetValue;
			if(Math.isNaN(otv)) otv = 0.0;
			targetValue = newvalue;
			if(smoothing < 0.0) {
				this.value = newvalue;
				updateBar();
			}
			else {
				if(otv != targetValue)
					smoother(true);
			}
		}
		return v;
	}

	function smoother(manualUpdate:Bool, ?inc:Float) {
		if(smoothing < 0) {
			setProgressBarValue(Math.max(targetValue, value));
			return;
		}
		var t = Date.now().getTime();
		if(manualUpdate && targetValue > 0.0) {
			if(!Math.isNaN(lastUpdated))
				smoothing = (( t - lastUpdated) + smoothing) / 2;
			inc = (targetValue - value) / (smoothing/100);
			lastUpdated = t;
		}
		if(value < targetValue ) {
			Reflect.setField(this, "value", value + inc);
			haxe.Timer.delay(callback(smoother,false,inc), 100);
		}
		updateBar();
	}


	function updateBar() {
		if(asClass != null) {
			asClass.update(this.value);
		}
	}
}
