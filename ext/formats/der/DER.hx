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

/*
 * Derived from AS3 implementation Copyright (c) 2007 Henri Torgemane
 */

/**
 * DER
 *
 * A basic class to parse DER structures.
 * Incomplete, but sufficient to extract whatever data we need so far.
 */
package formats.der;
import math.BigInteger;
import formats.der.Sequence;

class DER {
	// goal 1: to be able to parse an RSA Private Key PEM file.
	// goal 2: to parse an X509v3 cert. kinda.

	/*
	 * DER for dummies:
	 * http://luca.ntop.org/Teaching/Appunti/asn1.html
	 *
	 * This class does the bare minimum to get by. if that.
	 */

	public static var indent:String = "";

	public static function parse(der:ByteString, ?structure:Dynamic):IAsn1Type
	{
#if CAFFEINE_DEBUG
 		if (der.position == 0) {
			trace("DER.parse: "+ByteStringTools.hexDump(der));
			trace("DERlength: "+der.length);
		}
#end
		var type:Int = der.readUnsignedByte();
var otype  = type;
		var constructed:Bool = (type&0x20)!=0;
		type &=0x1F;
		// length
		var len:Int = der.readUnsignedByte();
		if (len>=0x80) {
			// TODO: may fail in neko.
			// long form of length
			var count:Int = len & 0x7f;
			len = 0;
			while (count>0) {
				len = (len<<8) | der.readUnsignedByte();
				count--;
			}
		}
#if CAFFEINE_DEBUG
var ts = "TYPE: 0x"+StringTools.hex(otype,2)+"/0x" + StringTools.hex(type,2) + " Len: "+len;
if(constructed) ts += " constructed ";
trace(ts);
#end
		// data
		var b:ByteString;
		switch (type) {
		//case 0x00: // WHAT IS THIS THINGY? (seen as 0xa0)
			// (note to self: read a spec someday.)
			// for now, treat as a sequence.
		case 0x00,0x10: // SEQUENCE/SEQUENCE OF. whatever
			// treat as an array
			var p:Int = der.position;
			var o:Sequence = new Sequence(type, len);
			var arrayStruct:Array<Dynamic> = null;
			try { arrayStruct = cast(structure, Array<Dynamic>); }
			catch(e:Dynamic) {}

			// copy the array, as we destroy it later.
			if (arrayStruct != null)
				arrayStruct = arrayStruct.concat([]);
trace("arrayStruct: " + arrayStruct);
trace("");

			while (der.position < p+len) {
trace("SEQUENCE DER pos: " +der.position + "/" + Std.string(p+len));
				var tmpStruct:Dynamic = null;
				if (arrayStruct != null)
					tmpStruct = arrayStruct.shift();

				if (tmpStruct != null) {
					while (tmpStruct && (untyped tmpStruct.optional != null && tmpStruct.optional))
					{
						// make sure we have something that looks reasonable. XXX I'm winging it here..
						var wantConstructed:Bool = Std.is(tmpStruct.value, Array);
						var isConstructed:Bool = isConstructedType(der);
						if (wantConstructed!=isConstructed) {
							// not found. put default stuff, or null
							o.push(tmpStruct.defaultValue);
							o.setKey(tmpStruct.name, tmpStruct.defaultValue);
							// try the next thing
							tmpStruct = arrayStruct.shift();
						}
						else {
							break;
						}
					}
				}
				if (tmpStruct != null) {
					var name:String = tmpStruct.name;
					var value:Dynamic = tmpStruct.value;
					if (tmpStruct.extract) {
						// we need to keep a binary copy of this element
						var size:Int = getLengthOfNextElement(der);
						var ba:ByteString = new ByteString();
						ba.writeBytes(der, der.position, size);
						o.setKey(name+"_bin", ba);
					}
					var obj:IAsn1Type = DER.parse(der, value);
					o.push(obj);
					o.setKey(name, obj);
				}
				else {
trace("=== Parsing next element ==");
					o.push(DER.parse(der));
trace("===========================");
				}
			}
trace(">>> SEQUENCE complete at position " + der.position+ "\n");
			return o;
		case 0x11: // SET/SET OF
			var p:Int = der.position;
			var s:Set = new Set(type, len);
			while (der.position < p+len) {
				s.push(DER.parse(der));
			}
			return s;
		case 0x02: // INTEGER
			// put in a BigInteger
			b = new ByteString();
trace("INTEGER of length "+len + " buf rem: " +der.bytesAvailable);
			der.readBytes(b,0,len);
			b.position=0;
			return new Integer(type, len, b);
		case 0x06: // OBJECT IDENTIFIER:
			b = new ByteString();
			der.readBytes(b,0,len);
			b.position=0;
			return new ObjectIdentifier(type, len, b);
		default: // 0x03, 0x04: // BIT STRING, OCTET STRING
			// see case 0x03, 0x04
			if(type != 0x03 && type != 0x04)
				trace("Cannot process DER TYPE "+type + " at position " + der.position);
			if (type != 0x04 && der.get(der.position) == 0) {
				//trace("Horrible Bit String pre-padding removal hack.");
				// I wish I had the patience to find a spec for this.
				der.position++;
				len--;
			}
			// stuff in a ByteString for now.
			var bs:DERByteString = new DERByteString(type, len);
			der.readBytes(bs,0,len);
trace(ByteString.hexDump(bs,":"));
			return bs;
		case 0x05: // NULL
			// if len!=0, something's horribly wrong.
			if(len != 0)
				throw "unexpected length: type 0x05";
			return null;
		case 0x13: // PrintableString
			var ps:PrintableString = new PrintableString(type, len);
			ps.setString(der.readMultiByte(len, "US-ASCII"));
			return ps;
		//case 0x22: // XXX look up what this is. openssl uses this to store my email.
		case 0x22, 0x14: // T61String - an horrible format we don't even pretend to support correctly
			var ps = new PrintableString(type, len);
			ps.setString(der.readMultiByte(len, "latin1"));
			return ps;
		case 0x17: // UTCTime
			var ut:UTCTime = new UTCTime(type, len);
			ut.setUTCTime(der.readMultiByte(len, "US-ASCII"));
			return ut;
		}
	}

	private static function getLengthOfNextElement(b:ByteString):Int {
		var p:Int = b.position;
		// length
		b.position++;
		var len:Int = b.readUnsignedByte();
		if (len>=0x80) {
			// long form of length
			// TODO: neko may fail
			var count:Int = len & 0x7f;
			len = 0;
			while (count>0) {
				len = (len<<8) | b.readUnsignedByte();
				count--;
			}
		}
		len += b.position-p; // length of length
		b.position = p;
		return len;
	}

	private static function isConstructedType(b:ByteString):Bool {
		var type:Int = b.get(b.position);
		return (type&0x20) != 0;
	}

	public static function wrapDER(type:Int, data:ByteString):ByteString {
		var d:ByteString = new ByteString();
		d.writeByte(type);
		var len:Int = data.length;
		if (len<128) {
			d.writeByte(len);
		} else if (len<256) {
			d.writeByte(1 | 0x80);
			d.writeByte(len);
		} else if (len<65536) {
			d.writeByte(2 | 0x80);
			d.writeByte(len>>8);
			d.writeByte(len);
		} else if (len<65536*256) {
			d.writeByte(3 | 0x80);
			d.writeByte(len>>16);
			d.writeByte(len>>8);
			d.writeByte(len);
		} else {
			d.writeByte(4 | 0x80);
			d.writeByte(len>>24);
			d.writeByte(len>>16);
			d.writeByte(len>>8);
			d.writeByte(len);
		}
		d.writeBytes(data);
		d.position=0;
		return d;
	}
}
