/*
 * Copyright (c) 2009, The Caffeine-hx project contributors
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

#if neko
typedef Int32 = I32;
#else
typedef Int32 = Int;
#end

/**
* Static methods for cross platform use of 32 bit Int. All methods are inline,
* so there is no performance penalty.
*
* The Int32 typedef wraps either an I32 in neko, or Int on all other platforms.
* In general, do not define variables or functions typed as I32, use the
* Int32 typedef instead. This allows for native operations without having to
* call the I32 functions.
*
* @author		Russell Weir
**/
class I32 {
	#if neko
	public static var ZERO : Int32;
	public static var ONE : Int32;
	/** 0xFF **/
	public static var BYTE_MASK : Int32;
	#else
	public static inline var ZERO : Int32 = 0;
	public static inline var ONE : Int32 = 1;
	/** 0xFF **/
	public static inline var BYTE_MASK : Int32 = 0xFF;
	#end

	/**
	* Returns byte 4 (highest byte) from the 32 bit int.
	* This is equivalent to v >>> 24 (which is the same as v >> 24 & 0xFF)
	*/
	public static inline function B4(v : Int32) : Int
	{
		return toInt(ushr(v,24));
	}

	/**
	* Returns byte 3 (second highest byte) from the 32 bit int.
	* This is equivalent to v >>> 16 & 0xFF
	*/
	public static inline function B3(v : Int32) : Int
	{
		return toInt(and(ushr(v,16), ofInt(0xFF)));
	}

	/**
	* Returns byte 2 (second lowest byte) from the 32 bit int.
	* This is equivalent to v >>> 8 & 0xFF
	*/
	public static inline function B2(v : Int32) : Int
	{
		return toInt(and(ushr(v,8), ofInt(0xFF)));
	}

	/**
	* Returns byte 1 (lowest byte) from the 32 bit int.
	* This is equivalent to v & 0xFF
	*/
	public static inline function B1(v : Int32) : Int
	{
		return toInt(and(v, ofInt(0xFF)));
	}

	/**
	* Absolute value
	**/
	public static inline function abs(v : Int32) : Int32
	{
		#if neko
		if(I32.compare(ofInt(0), v) > 0)
			return(neg(v));
		return v;
		#else
		return Std.int(Math.abs(v));
		#end
	}

	/**
	* Returns a + b
	*/
	public static inline function add(a : Int32, b : Int32) : Int32
	{
		return #if neko untyped __i32__add(a,b) #else a + b #end;
	}

	/**
	* Extracts an alpha value (high byte) from an ARGB color. An
	* alias for B4()
	*/
	public static inline function alphaFromArgb(v : Int32) : Int
	{
		return B4(v);
	}

	/**
	* Returns a & b
	*/
	public static inline function and(a : Int32, b : Int32) : Int32
	{
		return #if neko untyped __i32__and(a,b) #else a & b #end;
	}

	/**
	* Returns ~v
	*/
	public static inline function complement( v : Int32 ) : Int32 {
		return
			#if neko
				untyped __i32__complement(a);
			#else
				~v;
			#end
	}

	/**
	* Returns 0 if a == b, >0 if a > b, and <0 if a < b
	*/
	public static inline function compare( a : Int32, b : Int32 ) : Int {
		return
			#if neko
				untyped __i32__compare(a,b);
			#else
				cast a - b;
			#end
	}


	/**
	* Returns integer division a / b
	*/
	public static inline function div(a : Int32, b : Int32) : Int32
	{
		return #if neko untyped __i32__div(a,b) #else Std.int(a / b) #end;
	}

	/**
	*	Returns true if a == b
	**/
	public static inline function eq(a:Int32, b:Int32) : Bool
	{
		return
			#if neko
				(I32.compare(a,b) == 0) ? true : false;
			#else
				(a == b);
			#end
	}

	/**
	*	Returns true if a > b
	**/
	public static inline function gt(a:Int32, b:Int32)
	{
		return
			#if neko
				(I32.compare(a,b) > 0) ? true : false;
			#else
				(a > b);
			#end
	}

	/**
	*	Returns true if a >= b
	**/
	public static inline function gteq(a:Int32, b:Int32)
	{
		return
			#if neko
				(I32.compare(a,b) >= 0) ? true : false;
			#else
				(a >= b);
			#end
	}

	/**
	*	Returns true if a < b
	**/
	public static inline function lt(a:Int32, b:Int32) : Bool
	{
		return
			#if neko
				(I32.compare(a,b) < 0) ? true : false;
			#else
				(a < b);
			#end
	}

	/**
	*	Returns true if a <= b
	**/
	public static inline function lteq(a:Int32, b:Int32)
	{
		return
			#if neko
				(I32.compare(a,b) <= 0) ? true : false;
			#else
				(a <= b);
			#end
	}

	/**
	*  Create an Int32 from a high word (a) and a low word(b)
	*/
	public static inline function make( a : Int, b : Int ) : Int32 {
		return
			#if neko
				add(shl(cast a,16),cast b);
			#else
				a << 16 + b;
			#end
	}

	/**
	* Makes a color from an alpha value (0-255) and a 3 byte rgb value
	*/
	public static function makeColor( alpha:Int, rgb:Int) : Int32 {
		#if neko
			var a = shl(ofInt(alpha), 24);
			var c = and(ofInt(rgb), ofInt(0xFFFFFF));
			return or(a, c);
		#else
			return alpha << 24 | (rgb & 0xFFFFFF);
		#end
	}

	/**
	* Returns a % b
	*/
	public static inline function mod(a : Int32, b : Int32) : Int32
	{
		return #if neko untyped __i32__mod(a,b) #else a % b #end;
	}

	/**
	* Returns a * b
	*/
	public static inline function mul(a : Int32, b : Int32) : Int32
	{
		return #if neko untyped __i32__mul(a,b) #else a * b #end;
	}

	/**
	* Negates v, returns -v
	*/
	public static inline function neg(v : Int32) : Int32
	{
		return #if neko untyped __i32__neg(v) #else -v #end;
	}

	/**
	* Creates an Int32 from a haxe Int type
	*/
	public static inline function ofInt(v:Int) : Int32
	{
		return #if neko untyped __i32__new(v) #else v #end;
	}

	/**
	* Returns a | b
	*/
	public static inline function or(a : Int32, b : Int32) : Int32
	{
		return #if neko untyped __i32__or(a,b) #else a | b #end;
	}

	/**
	* Returns the lower 3 bytes of an Int32, most commonly used
	* to extract an RGB value from ARGB color
	*/
	public static inline function rgbFromArgb(v : Int32) : Int
	{
		return
			#if neko
				toInt(and(v, ofInt(0xFFFFFF)));
			#else
				return v & 0xFFFFFF;
			#end
	}

	/**
	* Returns a - b
	*/
	public static inline function sub(a : Int32, b : Int32) : Int32
	{
		return #if neko untyped __i32__sub(a,b) #else a - b #end;
	}

	/**
	* Returns v << bits
	*/
	public static inline function shl(v : Int32, bits:Int) : Int32
	{
		return #if neko untyped __i32__shl(v,bits) #else v << bits #end;
	}

	/**
	* Returns v >> bits (signed shift)
	*/
	public static inline function shr(v : Int32, bits:Int) : Int32
	{
		return #if neko untyped __i32__shr(v,bits) #else v >> bits #end;
	}

	/**
	* Returns v >>> bits (unsigned shift)
	*/
	public static inline function ushr(v : Int32, bits:Int) : Int32
	{
		return #if neko untyped __i32__ushr(v,bits) #else v >>> bits #end;
	}

	/**
	* Returns a ^ b
	*/
	public static inline function xor(a : Int32, b : Int32) : Int32
	{
		return #if neko untyped __i32__xor(a,b) #else a ^ b #end;
	}

	/**
	* Returns an exploded color value from the Int32
	*/
	public static inline function toColor(v : Int32) : {alpha:Int,color:Int}
	{
		return {
			alpha : B4(v),
			color : rgbFromArgb(v)
		};
	}

	/**
	* Creates a haxe Int from an Int32
	*
	* @throws String Overflow in neko only if 32 bits are required.
	**/
	public static inline function toInt(v : Int32) : Int
	{
		return
			#if neko
				try untyped __i32__to_int(v) catch( e : Dynamic ) throw "Overflow " + v;
			#else
				v;
			#end
	}

	/**
	* Safely converts an Int32 to Float. In neko, there
	* is no possibility of overflow
	*/
	public static inline function toFloat(v:Int32) : Float
	{
		#if neko
		var high : Int = I32.toInt(I32.ushr(v, 16));
		var low : Int = I32.toInt(I32.and(v, I32.ofInt(0xFFFF)));
		return (high * 0x10000) + (low * 1.0);
		#else
		return v * 1.0;
		#end
	}

	#if neko
	static function __init__() untyped {
		__i32__new = neko.Lib.load("std","int32_new",1);
		__i32__to_int = neko.Lib.load("std","int32_to_int",1);
		__i32__add = neko.Lib.load("std","int32_add",2);
		__i32__sub = neko.Lib.load("std","int32_sub",2);
		__i32__mul = neko.Lib.load("std","int32_mul",2);
		__i32__div = neko.Lib.load("std","int32_div",2);
		__i32__mod = neko.Lib.load("std","int32_mod",2);
		__i32__shl = neko.Lib.load("std","int32_shl",2);
		__i32__shr = neko.Lib.load("std","int32_shr",2);
		__i32__ushr = neko.Lib.load("std","int32_ushr",2);
		__i32__and = neko.Lib.load("std","int32_and",2);
		__i32__or = neko.Lib.load("std","int32_or",2);
		__i32__xor = neko.Lib.load("std","int32_xor",2);
		__i32__neg = neko.Lib.load("std","int32_neg",1);
		__i32__complement = neko.Lib.load("std","int32_complement",1);
		__i32__compare = neko.Lib.load("std","int32_compare",2);

		ZERO = untyped __i32__new(0);
		ONE = untyped __i32__new(1);
		BYTE_MASK = untyped __i32__new(0xFF);
	}
	#end

}
