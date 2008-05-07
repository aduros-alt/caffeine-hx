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

import flash.text.TextField;
import flash.text.TextFieldType;
import flash.text.TextFormat;
import flash.text.StyleSheet;

class Label extends Component {
	public var defaultTextFormat(getTextFormat,setTextFormat) : TextFormat;
	public var text(getText, setText) : String;
	public var htmlText(getHtmlText,setHtmlText) : String;
	public var styleSheet(getStyleSheet,setStyleSheet) : StyleSheet;
	public var shortCutCharCode(default,null) : Int;
	public var shortCutTarget : Component;

	private var scIndex : Int;
	private var originalText : String;

	private var _textField : TextField;
	private var isHtml : Bool;
	private var tFormat : TextFormat;

	public function new(id:String,txt:String, ?pos : Point, ?asHtml:Bool, ?css : StyleSheet) {
		super(id);
		super.setPosition(pos);
		if(Component.defaultStyleSheet != null)
			styleSheet = Component.defaultStyleSheet;
		_textField = iCreateField();
		_mc.addChild(_textField);
		tFormat = Config.getTextFormat();

		if(asHtml) {
			isHtml = true;
			setHtmlText(txt);
			if(css != null)
				styleSheet = css;
		}
		else {
			isHtml = false;
			setText(txt);
		}
		updateUI();
	}

	function iCreateField() {
		var rv = new TextField();
		rv.autoSize = flash.text.TextFieldAutoSize.LEFT;
		rv.selectable = false;
		return rv;
	}

	function getTextFormat() {
		return tFormat;
	}

	function setTextFormat(v:flash.text.TextFormat) {
		tFormat = v;
		if(!isHtml)
			setText(originalText);
		return v;
	}


	function getText() {
		return _textField.text;
	}

	function setText(v) {
 		originalText = v;
		_textField.defaultTextFormat = tFormat;
		_textField.text = findShortcut();
		if(shortCutCharCode != -1) {
			var tfu = new TextFormat();
			tfu.underline = !tFormat.underline;
			_textField.setTextFormat(tfu,scIndex,scIndex+1);
		}
		repaint();
		return v;
	}

	function getHtmlText() {
		return _textField.htmlText;
	}

	function setHtmlText(v) {
		originalText = v;
		findShortcut();

		if(shortCutCharCode != -1) {
			_textField.htmlText = originalText.substr(0,scIndex) + "<u>" + originalText.charAt(scIndex+1) + "</u>" + originalText.substr(scIndex+2);
		}
		else {
			_textField.htmlText = originalText;
		}
		repaint();
		return v;
	}

	function getStyleSheet() {
		return _textField.styleSheet;
	}

	function setStyleSheet(v) {
		if(_textField.styleSheet != v) {
			_textField.styleSheet = v;
			repaint();
		}
		return v;
	}

	private function findShortcut() :String {
		//trace(here.methodName);
		var cleanText = originalText;
		shortCutCharCode = -1;
		if(originalText == null) {
			return "";
		}
		var i = originalText.indexOf("&");
		while(i>=0 && i < originalText.length - 1) {
			if(StringTools.isAlpha(originalText, i+1)) {
				shortCutCharCode = originalText.charCodeAt(i+1);
				break;
			}
			i = originalText.indexOf("&",i+1);
		}
		scIndex = i;
		if(shortCutCharCode != -1) {
			shortCutCharCode = originalText.toLowerCase().charCodeAt(i+1);
			cleanText = originalText.substr(0,scIndex) + originalText.substr(scIndex+1);
		}
		return cleanText;
	}

	override public function onRepaint() { }

	/**
		Copy a flash text format.
	**/
	static public function copyTextFormat(tf) : flash.text.TextFormat
	{
		var rv = new flash.text.TextFormat();
		rv.align = tf.align;
		rv.blockIndent = tf.blockIndent;
		rv.bold = tf.bold;
		rv.bullet = tf.bullet;
		rv.color = tf.color;
		rv.font = tf.font;
		rv.indent = tf.indent;
		rv.italic = tf.italic;
		rv.kerning = tf.kerning;
		rv.leading = tf.leading;
		rv.leftMargin = tf.leftMargin;
		rv.letterSpacing = tf.letterSpacing;
		rv.rightMargin = tf.rightMargin;
		rv.size = tf.size;
		rv.tabStops = tf.tabStops;
		rv.target = tf.target;
		rv.underline = tf.underline;
		rv.url = tf.url;
		return rv;
	}
}