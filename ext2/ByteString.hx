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
	@todo Remove all references to this class and recode for Bytes
**/
// 0x12345678 in Big Endian (network byte order) is stored 12 34 56 78
// 0x12345678 in Little Endian (Intel architecture) is stored 78 56 34 12

import I32;

// TODO: implement as flash.util.ByteArray for flash 9
class ByteString {
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
		in [b] where the data will be written to, the [len] is the number of
		bytes to send, and if 0 all remaining data from [this] will be sent.
	**/
	public function readBytes(b:ByteString, ?offset:Int, ?len:Int): Void
	{
		if(offset == null)
			offset = 0;
		if(len == null)
			len = _buf.length - position;
		checkEof(len);

		var m = offset + len;
		if(offset >= b._buf.length)
			b.set(offset,0);
		for(i in offset...m) {
			b._buf[i] = _buf[position++];
		}
		b.update();
	}

	/**
		Read a 32 bit signed integer from the buffer.
	**/
	public function readInt() : Int32 {
		var b = new ByteString();
		readBytes(b, 0, 4);

		if(endian == BIG_ENDIAN)
			return(I32.decodeBE(Bytes.ofString(b.toString())));
		return I32.decodeLE(Bytes.ofString(b.toString()));
	}

	/**
		Read from the buffer using the specified multibyte char set.
	**/
	// TODO: Lots.
	public function readMultiByte(len : Int, set:String) : String {
		checkEof(len);
		var cset = set.toLowerCase();
		switch(cset) {
		case "latin1":
		case "us-ascii":
		default:
			throw set+" not supported";
		}
		var s = toString().substr(position, len);
		position += len;
		return s;
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
			update();
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
		Split a ByteString into an array of ByteStrings. The delimiter is another ByteString;
	**/
	public function splitB( delimiter : ByteString ) : Array<ByteString> {
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
	public function toHex(?sep:String,?pos:Int, ?len:Int) : String {
		if(sep == null)
			sep = new String("");
		if(pos == null)
			pos = 0;
		if(len == null)
			len = _buf.length - pos;
		var bs = ofIntArray(_buf.slice(pos,pos+len));
		var s = hexDump(bs, sep);
		if(sep == "" && s.length % 2 != 0)
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
		var l = _buf.length;
		for(x in 0...l)
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
		position = position + 1;
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
		Writes [length] bytes from the ByteString [v] to this, starting
		at [offset] in [v]. [offset] defaults to 0, and if null or 0,
		length will be everything starting at [offset]. If either param
		is out of bounds, it will be set to the beginning or end respectively.
	**/
	public function writeBytes(v : Dynamic, ?offset:Int, ?length:Int) : Void {
		if(offset == null || offset < 0 || offset >= v.length)
			offset = 0;
		if(length == null || length == 0 )
			length = v.length;
		if(offset + length > v.length)
			length = v.length - offset;

		if(Std.is(v, ByteString)) {
			_buf = _buf.concat(untyped v._buf.slice(offset, offset+length));
			update();
			return;
		}
		else if(Std.is(v, String)) {
			for(i in offset...length) {
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
	public function writeInt(v : Int32) : Void {
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
		if(position + required > _buf.length)
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
	/**
		Return a hex representation of the byte b. If
		b > 255 only the lowest 8 bits are used.
	**/
	public static function byte2Hex(b : Int) {
		b = b & 0xFF;
		return StringTools.hex(b,2).toLowerCase();
	}

	/**
		Transform an array of integers x where 0xFF >= x >= 0 to
		a string of binary data, optionally padded to a multiple of
		padToBytes. 0 length input returns 0 length output, not
		padded.
	**/
	public static function byteArrayToString(a: Array<Int>, ?padToBytes:Int) :String  {
		var sb = new BytesBuffer();
		for(i in a) {
			if(i > 0xFF || i < 0)
				throw "Value out of range";
			sb.addByte(i);
		}
		if(padToBytes != null && padToBytes > 0) {
			return nullPadString(sb.getBytes().toString(), padToBytes);
		}
		return sb.getBytes().toString();
	}

	/**
		Return the character code from a string at the given position.
		If pos is past the end of the string, 0 (null) is returned.
	**/
	public static function codeAt(s, pos) {
		if(pos >= s.length)
			return 0;
		return s.charCodeAt(pos);
	}

	/**
		Tests if two ByteStrings are equal.
	**/
	public static function eq(a:ByteString, b:ByteString) : Bool {
		if (a.length != b.length)
			return false;
		var l = a.length;
		for( i in 0...l)
		if (a._buf[i] != b._buf[i])
				return false;
		return true;
	}

	/**
		Dump a string to hex bytes. By default, will be seperated with
		spaces. To have no seperation, use the empty string as a seperator.
	**/
	public static function hexDump(obj : Dynamic, ?seperator:Dynamic) {
		var data = Std.string(obj);
		if(seperator == null)
			seperator = " ";
		var sb = new StringBuf();
		var l = data.length;
		for(i in 0...l) {
			sb.add(StringTools.hex(data.charCodeAt(i),2).toLowerCase());
			sb.add(seperator);
		}
		return StringTools.rtrim(sb.toString());
	}

	/**
		Convert an array of 32bit integers to a little endian string<br />
	**/
	public static function int32ToString(l : Array<Int32>) : String
	{
		return I32.packLE(#if !neko untyped #end l).toString();
	}

	/*
	public static function intsToPaddedString(a : Array<Int>, ?padTo : Int) {
		var sb = new StringBuf();
		if(padTo > 0) {
			var r = padTo - (a.length % padTo);
			for(i in 0...r) {
				sb.add(Std.chr(0));
			}
		}
		return sb.toString();
	}
	*/

	/**
		Pad a string with NULLs to the specified chunk length. Note
		that 0 length strings passed to this will not be padded. See also
		nullString()
	**/
	public static function nullPadString(s : String, chunkLen: Int) : String {
		var r = chunkLen - (s.length % chunkLen);
		if(r == chunkLen)
			return s;
		var sb = new BytesBuffer();
		sb.add(Bytes.ofString(s));
		for(x in 0...r) {
			sb.addByte(0);
		}
		return sb.getBytes().toString();
	}

	/**
		Create a string initialized to nulls of length len
	**/
	public static function nullString( len : Int ) : String {
		var sb = new StringBuf();
		for(i in 0...len)
			sb.addChar(0);
		return sb.toString();
	}

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
		var l = s.length;
		for(i in 0...l) {
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
		s = StringTools.replaceRecurse(s, "|", "").toLowerCase();
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

	/**
		Transform  a string into an array of integers x where
		0xFF >= x >= 0, optionally padded to a multiple of
		padToBytes. 0 length input returns 0 length output, not
		padded.
	**/
	public static function stringToByteArray( s : String, ?padToBytes:Int) : Array<Int> {
		var a = new Array();
		var len = s.length;
		for(x in 0...s.length) {
			a.push(s.charCodeAt(x));
		}
		if(padToBytes != null && padToBytes > 0) {
			var r = padToBytes - (a.length % padToBytes);
			if(r != padToBytes) {
				for(x in 0...r) {
					a.push(0);
				}
			}
		}
		return a;
	}

	/**
		Convert a string containing 32bit integers to an array of ints<br />
		If the string length is not a multiple of 4, it will be NULL padded
		at the end.
	**/
	public static function strToInt32(s : String) : Array<Int32>
	{
		return #if !neko cast #end
			I32.unpackLE(Bytes.ofString(nullPadString(s,4)));
	}

	/**
		Remove nulls at the end of a string
	**/
	public static function unNullPadString(s : String) {
		var er : EReg = ~/\0+$/;
		return er.replace(s, '');
	}

}

