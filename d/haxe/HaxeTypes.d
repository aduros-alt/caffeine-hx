module haxe.HaxeTypes;

private {
	import FloatUtil = tango.text.convert.Float;
	import IntUtil = tango.text.convert.Integer;
	import tango.math.Math;
	import tango.util.container.HashMap;
	import tango.io.Console;
}

public {
	import haxe.HaxeObject;
	import haxe.HaxeClass;
	import haxe.IntHash;
	import haxe.Hash;
	import haxe.Array;
	import haxe.List;
	import haxe.HaxeDate;
	import haxe.Enum;
	import haxe.String;
	import haxe.FunctionBase;
}

public enum HaxeType
{
	TNull,
	TString,
	TInt,
	TFloat,
	TBool,
	TArray,
	TList,
	TDate,
	THash,
	TIntHash,
	TEnum,
	TObject,
	TClass,
	TFunction
}

/**
	The base class for all Haxe types
**/

private {
	alias HaxeType.TNull TNull;
	alias HaxeType.TString TString;
	alias HaxeType.TInt TInt;
	alias HaxeType.TFloat TFloat;
	alias HaxeType.TBool TBool;
	alias HaxeType.TArray TArray;
	alias HaxeType.TList TList;
	alias HaxeType.TDate TDate;
	alias HaxeType.THash THash;
	alias HaxeType.TIntHash TIntHash;
    alias HaxeType.TEnum TEnum;
	alias HaxeType.TObject TObject;
	alias HaxeType.TClass TClass;
	alias HaxeType.TFunction TFunction;
}

package template CantCast(char[] name) {
	const char[] CantCast =
		name ~" cast_"~name~
		"(ref bool ok = *new bool()) { ok = false; return null; }";
}

package template CanCast(char[] name) {
	const char[] CanCast =
		name ~" cast_"~name~
		"(ref bool ok = *new bool()) { ok = true; return this; }";
}

class Dynamic
{
	public bool isNull = true;
	this() { }
	this(FunctionBase b) {
		if(b !is null) {
			this.__func = b;
			this.isNull = false;
		}
	}

	public HaxeType type() {
		if(__func !is null)
			return HaxeType.TFunction;
		return HaxeType.TNull;
	}
	public char[] toString() { return isNull ? "(null)" : "Dynamic"; }

	HaxeClass __objPtr;
	HaxeObject __context;
	public FunctionBase __func;

	Dynamic clone() {
		try {
			return Unserializer.run(Serializer.run(this, true));
		}
		catch(Exception e) {
			return null;
		}
	}

	bool cast_bool(ref bool ok = *new bool()) {
		ok = false;
		return false;
	}
	int cast_int(ref bool ok = *new bool()) {
		ok = false;
		return 0;
	}
	real cast_real(ref bool ok = *new bool()) {
		ok = false;
		return 0;
	}
	char[] cast_string(ref bool ok = *new bool()) {
		ok = true;
		return toString();
	}
	mixin(CantCast!("Array"));
	mixin(CantCast!("StringArray"));
	mixin(CantCast!("IntArray"));
	mixin(CantCast!("FloatArray"));
	mixin(CantCast!("List"));
	mixin(CantCast!("HaxeDate"));
	mixin(CantCast!("Hash"));
	mixin(CantCast!("IntHash"));
	mixin(CantCast!("Enum"));
	mixin(CantCast!("HaxeObject"));
	mixin(CantCast!("HaxeClass"));
// 	mixin(CantCast!("Function"));

	private alias Dynamic DYN;
// 	Dynamic opCall(Dynamic[] params) {
// 		if(this.type != HaxeType.TFunction)
// 			throw new Exception("Not a function");
// 		return __func(__objPtr, params, __context);
// 	}

	private template CheckFunc() {
		const char[] CheckFunc =
		"if(__func is null) {
			Cout(\"Dynamic.opCall\").newline;
			throw new Exception(\"Not a function\");
		}";
	}

	Dynamic opCall(Dynamic[] params) {
		mixin(CheckFunc!());
		return __func(params);
	}
	Dynamic opCall() {
		mixin(CheckFunc!());
		return __func();
	};
	Dynamic opCall(DYN a) {
		mixin(CheckFunc!());
		return __func(a);
	};
	Dynamic opCall(DYN a,DYN b) {
		mixin(CheckFunc!());
		return __func(a,b);
	};
	Dynamic opCall(DYN a,DYN b,DYN c) {
		mixin(CheckFunc!());
		return __func(a,b,c);
	};
	Dynamic opCall(DYN a,DYN b,DYN c,DYN d) {
		mixin(CheckFunc!());
		return __func(a,b,c,d);
	};
	Dynamic opCall(DYN a,DYN b,DYN c,DYN d,DYN e) {
		mixin(CheckFunc!());
		return __func(a,b,c,d,e);
	};
	Dynamic opCall(DYN a,DYN b,DYN c,DYN d,DYN e,DYN f) {
		mixin(CheckFunc!());
		return __func(a,b,c,d,e,f);
	};
	Dynamic opCall(DYN a,DYN b,DYN c,DYN d,DYN e,DYN f,DYN g) {
		mixin(CheckFunc!());
		return __func(a,b,c,d,e,f,g);
	};
}

/**
	Base class for all haxe class types
**/
import haxe.Serializer;
public interface HaxeSerializable
{
	char[] __classname();
	void __serialize(ref Serializer s);
	bool __unserialize(ref HaxeObject o);
}

private template Comparator(T:Dynamic) {
	int opCmp(Object val) {
		if( val is this ) return 0;
		if( cast(T) val ) {
			auto v = (cast(T) val).value;
			if( v == this.value ) return 0;
			if( v  > this.value ) return 1;
		}
		return -1;
	}
}

private template NullComparator(T:Dynamic) {
	int opCmp(Object val) {
		if( val is this ) return 0;
		if( cast(T) val ) {
			bool oIsNull = (cast(T) val).isNull;
			if(this.isNull) {
				if(oIsNull) return 0;
				return 1;
			}
			if(oIsNull) return -1;
			auto v = (cast(T) val).value;
			if( v == this.value ) return 0;
			if( v  > this.value ) return 1;
		}
		return -1;
	}
}

private template Equality(T:Dynamic) {
	int opEquals(Object o) {
		if( o is this || (o !is null && cast(T)o) )
			return (cast(T)o).value == this.value;
		return false;
	}
}

/**
	opEquals that includes comparison of null values.
**/
private template NullEquality(T:Dynamic) {
	int opEquals(Object o) {
		if( o is this )
			return 0;
		if( ! cast(T) o)
			return false;
		if( cast(Null) o) {
			if(this.isNull) return true;
			return false;
		}
		bool oIsNull = (cast(T) o).isNull;
		if(this.isNull) {
			if(oIsNull) return true;
			return false;
		}
		if(oIsNull) return false;
		return (cast(T)o).value == this.value;
	}
}

private template Castable(B) {
	B opCast() { return value; }
}

//////////////////////////////////////////////////////////
//                BASIC TYPES                           //
//////////////////////////////////////////////////////////
class Null : Dynamic
{
	public HaxeType type() { return HaxeType.TNull; }
	this() { isNull = true; }
	static Null opCall() { return new Null(); }
 	int opEquals(Object o) {
		if(o is this || o is null) return true;
		if(! cast(Dynamic) o)
			return false;
		if( (cast(Dynamic)o).isNull)
			return true;
		return false;
	}
	int opCmp(Object o) {
		if(o is this || o is null) return 0;
		if( (cast(Dynamic)o).isNull)
			return 0;
		return 1;
	}
	public char[] toString()
	{
		return "(null)";
	}

}

class Bool : Dynamic
{
	public HaxeType type() { return HaxeType.TBool; }
	public bool value;

	this() {}
	this(bool val) { this.value = val; }

	public char[] toString()
	{
		return (value) ? "true" : "false";
	}

	int opCmp(Object o) {
		if( o is this ) return 0;
		if( cast(Bool) o ) {
			if(value) return (cast(Bool)o).value ? 0 : 1;
			else return (cast(Bool)o).value ? -1 : 0;
		}
		return 0;
	}
	mixin Castable!(bool);
	mixin Equality!(typeof(this));
}



//////////////////////////////////////////////////////////
//              NUMERIC VALUES                          //
//////////////////////////////////////////////////////////
abstract class HaxeNumeric : Dynamic
{
}

/**
	Only applicable to integer type
**/
private template Bitwise(T:Dynamic) {
	T opAnd(T v) {
		if(this.isNull || v.isNull)
			throw new Exception("null value");
		return new T(this.value & v.value);
	}
	T opOr(T v) {
		if(this.isNull || v.isNull)
			throw new Exception("null value");
		return new T(this.value | v.value);
	}
	T opXor(T v) {
		if(this.isNull || v.isNull)
			throw new Exception("null value");
		return new T(this.value ^ v.value);
	}
	T opShl(T v) {
		if(this.isNull || v.isNull)
			throw new Exception("null value");
		return new T(this.value << v.value);
	}
	T opShr(T v) {
		if(this.isNull || v.isNull)
			throw new Exception("null value");
		return new T(this.value >> v.value);
	}
	T opUShr(T v) {
		if(this.isNull || v.isNull)
			throw new Exception("null value");
		return new T(this.value >>> v.value);
	}
}

private template NumericMath(T:Dynamic) {
	static T opCall() { return new T(); }
	static T opCall(real v) { return new T(v); }
	T opNeg() {
		this.value = 0 - this.value;
		return this;
	}
	T opPos() {
		this.value = abs(this.value);
		return this;
	}
	T opPostInc() {
		this.value++;
		return this;
	}
	T opPostDec() {
		this.value--;
		return this;
	}
	T opAdd(T v) {
		if(this.isNull || v.isNull)
			throw new Exception("null value");
		return new T(this.value + v.value);
	}
	T opAdd(real v) {
		if(this.isNull)
			throw new Exception("null value");
		return new T(this.value + v);
	}
	T opAddAssign(T v) {
		if(this.isNull || v.isNull)
			throw new Exception("null value");
		this.value += v.value;
		return this;
	}
	T opAddAssign(real v) {
		if(this.isNull)
			throw new Exception("null value");
		this.value += v;
		return this;
	}
	T opSub(T v) {
		if(this.isNull || v.isNull)
			throw new Exception("null value");
		return new T(this.value - v.value);
	}
	T opSub(real v) {
		if(this.isNull)
			throw new Exception("null value");
		return new T(this.value - v);
	}
	T opSubAssign(T v) {
		if(this.isNull || v.isNull)
			throw new Exception("null value");
		this.value -= v.value;
		return this;
	}
	T opSubAssign(real v) {
		if(this.isNull)
			throw new Exception("null value");
		this.value -= v;
		return this;
	}
	T opMul(T v) {
		if(this.isNull || v.isNull)
			throw new Exception("null value");
		return new T(this.value * v.value);
	}
	T opMul(real v) {
		if(this.isNull)
			throw new Exception("null value");
		return new T(this.value * v);
	}
	T opMulAssign(T v) {
		if(this.isNull || v.isNull)
			throw new Exception("null value");
		this.value *= v.value;
		return this;
	}
	T opMulAssign(real v) {
		if(this.isNull)
			throw new Exception("null value");
		this.value *= v;
		return this;
	}
	T opDiv(T v) {
		if(this.isNull || v.isNull)
			throw new Exception("null value");
		return new T(this.value / v.value);
	}
	T opDiv(real v) {
		if(this.isNull)
			throw new Exception("null value");
		return new T(this.value / v);
	}
	T opDivAssign(T v) {
		if(this.isNull || v.isNull)
			throw new Exception("null value");
		this.value /= v.value;
		return this;
	}
	T opDivAssign(real v) {
		if(this.isNull)
			throw new Exception("null value");
		this.value /= v;
		return this;
	}
	T opMod(T v) {
		if(this.isNull || v.isNull)
			throw new Exception("null value");
		return new T(this.value % v.value);
	}
	T opMod(long v) {
		if(this.isNull)
			throw new Exception("null value");
		return new T(this.value % v);
	}
	T opModAssign(T v) {
		if(this.isNull || v.isNull)
			throw new Exception("null value");
		this.value %= v.value;
		return this;
	}
	T opModAssign(long v) {
		if(this.isNull)
			throw new Exception("null value");
		this.value %= v;
		return this;
	}
}

class Int : HaxeNumeric
{
	public HaxeType type() { return HaxeType.TInt; }
	public int value;

	this() { isNull = true; this.value = 0; }
	this(real val) { isNull = false; this.value = cast (int)val; }
	this(Object o) {
		if(o is null) {
			isNull = true;
			return;
		}
		if(cast(Int) o) {
			this.value = (cast(Int) o).value;
			this.isNull = (cast(Int) o).isNull;
		}
		else
			throw new Exception("Incompatible object assigned to Int");
	}

	public char[] toString()
	{
		if(isNull) return "(null)";
		return IntUtil.toString(value);
	}
	Int opAssign(real v) {
		this.isNull = false;
		this.value = cast(int)v;
		return this;
	}
	mixin Castable!(int);
	mixin NullComparator!(typeof(this));
	mixin NullEquality!(typeof(this));
	mixin NumericMath!(typeof(this));
	mixin Bitwise!(typeof(this));
	bool cast_bool(ref bool ok = *new bool()) {
		ok = true;
		if(isNull) return false;
		return this.value == 0 ? false : true;
	}
	int cast_int(ref bool ok = *new bool()) { ok = true; return this.value; }
	real cast_real(ref bool ok = *new bool()) { ok = true; return this.value; }
	unittest
	{
		HInt v = new HInt();
		assert(v.isNull, v.type.toString);
		assert(v.isNull == false);
		assert(v.isNull == false);
		assert(0, "I ran unittest");
	}
}


class Float : HaxeNumeric
{
	public HaxeType type() { return HaxeType.TFloat; }
	public real value;

	this() { isNull = false; this.value = real.nan; }
	this(real val) { isNull = false; this.value = val; }
	this(long val) { isNull = false; this.value = val; }

	public char[] toString()
	{
		//if(isNull) return "(null)";
		return FloatUtil.toString(value);
	}

	Float opAssign(real v) {
		this.isNull = false;
		this.value = v;
		return this;
	}
	mixin Castable!(real);
	mixin Comparator!(typeof(this));
	int opEquals(Object o) {
		if(o is this) return true;
		if(o is null) return false;
		auto ov = (cast(Float) o).value;
		if(ov !<>= ov) { // unordered (NaN)
			if(value !<>= value)
				return true;
			return false;
		}
		if(ov is ov.infinity) {
			if(value is value.infinity) {
				// let tango handle the signed values of infinity
				if(FloatUtil.toString(ov) == FloatUtil.toString(value))
					return true;
			}
			return false;
		}

		return ov == value;
	}
	mixin NumericMath!(typeof(this));

	public static Float NEGATIVE_INFINITY() {
		return new Float(-real.infinity);
	}

	public static Float POSITIVE_INFINITY() {
		return new Float(real.infinity);
	}

	public static Float NaN() {
		//return new Float(real.nan);
		auto f = new Float;
		f.value = real.nan;
		return f;
	}

}


import tango.text.Util;
/**
	Converts a D class Module name to a haxe package name
**/
char[] moduleToPackage(char[] modName) {
	auto parts = split(modName, ".");
	if(parts.length < 2)
		return modName;
	int skip = parts.length - 2;
	char[] name;
	for(int x=0; x < parts.length; x++) {
		if(x == skip)
			continue;
		name ~= parts[x];
		if(x != parts.length - 1)
			name ~= ".";
	}
	return name;
}

import tango.core.Traits;
Dynamic toDynamic(T)(T val) {
	static if(is(T : Dynamic))
		return val;
	else static if(is(T == bool))
		return new Bool(val);
    else static if(isIntegerType!(T))
		return new Int(val);
	else static if(isFloatingPointType!(T))
		return new Float(val);
    else static if(is(T:char[]))
		return new String(val);
//     else static if(is(T : Time))
// 		return new HaxeDate();
	else static if(is(T : FunctionBase))
		return new Dynamic(val);
    else
        static assert(false, "Can not translate variable of type " ~ T.stringof);
}

import haxe.Unserializer;
Dynamic clone(Dynamic v) {
	try {
		return Unserializer.run(Serializer.run(v, true));
	}
	catch(Exception e) {
		return null;
	}
}

/**
	Use in static this() constructors to register the class
	for resolving to haxe packages.
	D paths are the module.classname
**/
void registerHaxeClass(char[] haxeName, char[] dName) {
	HaxeClass.haxe2dmd[haxeName] = dName;
}