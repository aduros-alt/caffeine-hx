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

/**
	A class that represents arrays of bytes. Has methods from String
	class, as well as from Flash9 util.ByteArray
**/

#if neko
import neko.Int32;
#end

// TODO: implement as flash.util.ByteArray for flash 9
class ByteString implements IString {
	public static var BIG_ENDIAN : String = "bigEndian";
	public static var LITTLE_ENDIAN : String = "littleEndian";

	/** Number of bytes available to be read **/
	public var bytesAvailable(getBytesAvailable, null) : Int;
	/** the length. To modify use setLength **/
	public var length(default, null) : Int;
	/** the read/write position pointer. **/
	public var position(default, setPosition) : Int;
	/** sets or reads the endianess of the buffer. bigEndian or littleEndian **/
	public var endian(default, setEndian) : String;

	private var _buf : Array<Int>;

	public function new(?s : String) {
		_buf = new Array();
		if(s != null) {
			for(i in 0...s.length)
				_buf.push(s.charCodeAt(i));
			length = s.length;
		}
		position = 0;
		endian = BIG_ENDIAN;
		update();
	}

	public function charAt( index : Int ) : String {
		return Std.chr(_buf[index]);
	}

	public function charCodeAt( index : Int ) : Null<Int> {
		var a : Null<Int> = get(index);
		return a;
	}

	/**
		Get the value at position pos. Same as charCodeAt
	**/
	public function get(pos : Int) : Null<Int> {
		if(pos >= _buf.length || pos < 0)
			throw "index error";
		return _buf[pos];
	}

	public function getLength() : Int {
		return _buf.length;
	}

	public function indexOf( value : String, ?startIndex : Int ) : Int {
		return toString().indexOf(value, startIndex);
	}

	public function lastIndexOf( value : String, ?startIndex : Int ) : Int {
		return toString().indexOf(value, startIndex);
	}

	/**
		Removes the last byte and returns it.
	**/
	public function pop() : Null<Int> {
		if(_buf.length == 0) {
			update();
			return null;
		}
		var i = _buf.pop();
		update();
		return i;
	}

	/**
		Adds a byte to the end of the buffer. Returns the
		new length.
	**/
	public function push(v : Int) : Int {
		_buf.push(cleanValue(v));
		update();
		return length;
	}

	/**
		Read the next byte in stream, and returns false if it is 0
		or true otherwise.
	**/
	public function readBoolean() : Bool {
		var i = readByte();
		if(i == 0)
			return false;
		return true;
	}

	/**
		Read the next available byte as an signed integer.
	**/
	public function readByte() : Int {
		checkEof();
		var i = _buf[position++];
		if(i & 0x80 != 0) {
			i &= 0x7f;
			i ^= 0xff;
			i = 0 -i;
		}
		return i;
	}

	/**
		Read bytes from this into ByteString [b]. [offset] is the starting offset
		in [b] where the data will be written to, the [length] is the number of
		bytes to send, and if 0 all remaining data from [this] will be sent.
	**/
	public function readBytes(b:ByteString, ?offset:Int, ?length:Int): Void
	{
		if(offset == null)
			offset = 0;
		if(length == null)
			length = _buf.length - position;
		checkEof(length);

		var m = offset + length;
		if(offset > b._buf.length)
			b.set(offset,0);
		for(i in offset...m) {
			b._buf[i] = _buf[position++];
		}
		b.update();
	}

	/**
		Read a 32 bit signed integer from the buffer.
	**/
#if neko
	public function readInt() : Int32 {
#else true
	public function readInt() : Int {
#end
		var b = new ByteString();
		readBytes(b, 0, 4);
		if(endian == BIG_ENDIAN)
			return(I32.decodeBE(b.toString()));
		return I32.decodeLE(b.toString());
	}

	/**
		Read from the buffer using the specified multibyte char set.
	**/
	// TODO: Lots.
	function readMultiByte(len : Int, set:String) : String {
		checkEof();
		if(len + position > length)
			throwEof();
		var cset = set.toLowerCase();
		switch(cset) {
		case "latin1":
		case "us-ascii":
		default:
			throw set+" not supported";
		}
		return toString().substr(position, len);
		position += len;
	}

	/**
		Read the next available byte as an unsigned.
	**/
	public function readUnsignedByte() : Int {
		checkEof();
		var i : Int = _buf[position++];
		return i;
	}

	/**
		Set position to a byte value. Only the lower 8 bits
		of the integer are used. Attempts to set values beyond
		the buffer length NULL fill the buffer to that point.
	**/
	public function set(pos: Int, value:Int) {
		if(pos > _buf.length) {
			for(i in _buf.length...pos)
				_buf[i] = 0;
		}
		_buf[pos] = cleanValue(value);
		update();
	}

	/**
		Alias for set.
	**/
	public function setCodeAt(pos: Int, value:Int) : Void {
		set(pos, value);
	}

	/**
		Force buffer to a particular length. If the length
		is less than current, the data will be truncated. If
		greater, it will be null padded.
	**/
	public function setLength(i : Int) : Int {
		if(i == _buf.length)
			return i;
		if(i > _buf.length) {
			var o : Int = _buf.length;
			_buf[i-1] = 0;
			for(x in o...i) {
				_buf[x] = 0;
			}
			return i;
		}
		_buf = _buf.slice(0, i);
		update();
		return i;
	}

	/**
		Removes the last byte and returns it.
	**/
	public function shift() : Null<Int> {
		var r = _buf.shift();
		update();
		return r;
	}

	/**
		Split into array of binary strings, using delimiter which
		also may be a binary string.
	**/
	public function split( delimiter : String ) : Array<String> {
		return toString().split( delimiter.toString() );
	}

	/**
		Split a ByteString into an array of ByteStrings. The delimiter may
		be another ByteString;
	**/
	public function splitB( delimiter : IString ) : Array<ByteString> {
		var a = toString().split( delimiter.toString() );
		var r = new Array<ByteString>();
		for( i in a )
			r.push(new ByteString(i));
		return r;
	}

	public function substr( pos : Int, ?len : Int ) : String {
		return toString().substr( pos, len );
	}

	/**
		Return a ByteString slice
	**/
	public function substrB( pos : Int, ?len : Int ) : ByteString {
		return new ByteString(toString().substr( pos, len ));
	}

	/**
		Returns a copy of the internal int array buffer.
	**/
	public function toArray() : Array<Int>
	{
		return _buf.copy();
	}

	/**
		Return a hex representation of the data.
	**/
	public function toHex() : String {
		var s = ByteStringTools.byteArrayToString(_buf);
		if(s.length % 2 != 0)
			s = "0"+s;
		return s;
	}

	/** Unimplemented **/
	public function toLowerCase() : String {
		throw "unimplemented";
		return "";
	}

	/**
		Return binary string. May have embedded NULL chars.
	*/
	public function toString() : String {
		var sb = new StringBuf();
		for(x in 0..._buf.length)
			sb.addChar(_buf[x]);
		return sb.toString();
	}

	/** Unimplemented **/
	public function toUpperCase() : String {
		throw "unimplemented";
		return "";
	}

	/**
		Add a byte to the beginning of the buffer.
	**/
	public function unshift(v : Int ) : Void {
		_buf.unshift(v);
		position++;
		update();
	}

	/**
		Pushes a byte into the string
	**/
	public function writeByte(v : Int) : Void {
		_buf.push(cleanValue(v));
		update();
	}

	/**
		Pushes a byte into the string
	**/
	public function writeBytes(v : IString) : Void {
		if(Std.is(v, ByteString)) {
			_buf = _buf.concat(untyped v.buf);
			update();
			return;
		}
		else if(Std.is(v, String)) {
			for(i in 0...v.length) {
				_buf[i] = v.charCodeAt(i);
			}
			update();
			return;
		}
		else
			throw "Unable to add "+Type.getClassName(Type.getClass(v));
	}

	/**
		Write a 32 bit integer. It will be written in the byte order according to
		the 'endian' setting.
	**/
#if neko
	public function writeInt(v : Int32) : Void {
#else true
	public function writeInt(v : Int) : Void {
#end
		if(endian == BIG_ENDIAN)
			writeBytes(I32.encodeBE(v));
		else
			writeBytes(I32.encodeLE(v));
		update();
	}

	/////////////////////////////////////////////////////
	//                Private methods                  //
	/////////////////////////////////////////////////////
	/**
		reset position pointer to 1 past array length
	*/
	function update() {
		length = _buf.length;
		if(position > _buf.length)
			position = _buf.length;
	}

	function checkEof(?required : Int) {
		if(required == null) required = 0;
		if(position + required >= _buf.length)
			throwEof();
	}

	private static function cleanValue(v : Int) : Int {
		var neg = false;
		if(v < 0) {
			if(v < -128)
				throw "not a byte";
			neg = true;
			v = (v & 0xff) | 0x80;
		}
		if(v > 0xff)
			throw "not a byte";
		return v;
	}

	function getBytesAvailable() : Int {
		if(position >= length)
			return 0;
		return length - position;
	}

	function setEndian(s : String) : String {
		if(s == BIG_ENDIAN || s == LITTLE_ENDIAN)
			endian = s;
		else
			throw "unsupported";
		return s;
	}

	function setPosition(p : Int) : Int {
		if(p > _buf.length)
			set(p, 0);
		position = p;
		update();
		return p;
	}

	function throwEof() : Void {
		throw "eof";
	}

	/////////////////////////////////////////////////////
	//            Public Static methods                //
	/////////////////////////////////////////////////////
	public static function ofIntArray(a : Array<Int>) : ByteString {
		var b = new ByteString();
		for(i in 0... a.length) {
			b._buf[i] = cleanValue(a[i]);
		}
		b.update();
		return b;
	}

	/**
		Create from an existing string of bytes
	**/
	public static function ofString(s : String) : ByteString {
		var b = new ByteString();
		for(i in 0...s.length) {
			b._buf[i] = s.charCodeAt(i);
		}
		b.update();
		return b;
	}

	/**
		Parse a hex string into a ByteString. The hex string
		may start with 0x, may contain spaces, and may contain
		: delimiters.
	**/
	public static function ofHex(hs : String) : ByteString {
		var s : String = StringTools.stripWhite(hs);
		s = StringTools.replaceAll(s, "|", "").toLowerCase();
		if(StringTools.startsWith(s, "0x"))
			s = s.substr(2);
		if (s.length&1==1) s="0"+s;

		var b = new ByteString();
		var l = Std.int(s.length/2);
		for(x in 0...l) {
			var ch = s.substr(x * 2, 2);
			b._buf[x] = Std.parseInt("0x"+ch);
			if(b._buf[x] > 0xff)
				throw "error";
		}
		b.update();
		return b;
	}

}

