module haxe.HaxeTypes;

private {
	import FloatUtil = tango.text.convert.Float;
	import IntUtil = tango.text.convert.Integer;
	import tango.math.Math;
	import tango.util.container.HashMap;
}

public {
	import haxe.IntHash;
	import haxe.Hash;
	import haxe.Array;
	import haxe.List;
	import haxe.HaxeObject;
	import haxe.HaxeDate;
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
class Dynamic
{
	public bool isNull;
	this() { isNull = true; }
	public HaxeType type() { return HaxeType.TNull; }
	public char[] toString() { return "Dynamic"; }
}

/**
	Base class for all haxe class types
**/
public interface HaxeSerializable
{
	char[] __classname();
	char[] __serialize();
	bool __unserialize();
}

abstract class HaxeClass : Dynamic, HaxeSerializable
{
	abstract public char[] __classname();
	abstract public char[] __serialize();
	abstract public bool __unserialize();

	public HaxeType type() { return HaxeType.TClass; }
	public char[] toString() { return __classname(); }
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
		if( o is this || o !is null && cast(T)o )
			return (cast(T)o).value == this.value;
		return false;
	}
}

private template Castable(B) {
	B opCast() { return value; }
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


//////////////////////////////////////////////////////////
//                 STRING TYPE                          //
//////////////////////////////////////////////////////////
class String : Dynamic
{
	public HaxeType type() { return HaxeType.TString; }
	public char[] value;

	this() { isNull = true; this.value = ""; }
	this(char[] v) {
		isNull = false;
		this.value = v;
	}

	public char[] toString()
	{
		if(isNull) return "(null)";
		return value;
	}
	static String opCall() { return new String(); }
	static String opCall(char[] v) { return new String(v); }
	static String opCall(char v) { char[] d; d~=v; return new String(d); }
	static String opCall(real v) { return new String(FloatUtil.toString(v)); }
	static String opCall(long v) { return new String(IntUtil.toString(v)); }

	String opAssign(char[] v) {
		this.isNull = false;
		this.value = v;
		return this;
	}
	String opCat(char[] v) {
		this.isNull = false;
		return new String(this.value ~ v);
	}
	String opCat(Dynamic v) {
		this.isNull = false;
		return new String(this.value ~ v.toString);
	}
	String opCat(real v) {
		this.isNull = false;
		return new String(this.value ~ FloatUtil.toString(v));
	}
	String opCatAssign(char[] v) {
		this.isNull = false;
		this.value ~= v; return this;
	}
	String opCatAssign(Dynamic v) {
		this.isNull = false;
		this.value ~= v.toString; return this;
	}
	String opCatAssign(real v) {
		this.isNull = false;
		this.value ~= FloatUtil.toString(v); return this;
	}

	mixin Castable!(char[]);
	mixin NullComparator!(typeof(this));
	mixin NullEquality!(typeof(this));
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
	//this(int val) { isNull = false; this.value = val; }
	this(real val) { isNull = false; this.value = cast (int)val; }

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

	this() { isNull = true; this.value = real.nan; }
	this(real val) { isNull = false; this.value = val; }
	this(long val) { isNull = false; this.value = val; }

	public char[] toString()
	{
		if(isNull) return "(null)";
		return FloatUtil.toString(value);
	}

	Float opAssign(real v) {
		this.isNull = false;
		this.value = v;
		return this;
	}
	mixin Castable!(real);
	mixin NullComparator!(typeof(this));
	mixin NullEquality!(typeof(this));
	mixin NumericMath!(typeof(this));

	public static Float negativeInfinity() {
		return new Float(-real.infinity);
	}

	public static Float positiveInfinity() {
		return new Float(real.infinity);
	}

	public static Float nan() {
		return new Float(real.nan);
	}
}

/**
	Types that can be accessed as integer arrays of Dynamic
**/
package template DynamicArrayType(T, alias F) {
	Dynamic opIndex(size_t i) {
		if(i >= F.length || F[i] == null)
			return new Null();
		return F[i];
	}

	Dynamic opIndexAssign(Dynamic v, size_t i) {
		if(v is null)
			v = new Null();
		if(i >= F.length) {
			auto olen = F.length;
			F.length = i + 1;
			while(olen < F.length) {
				F[olen++] = new Null();
			}
		}
		F[i] = v;

		// trim the size down
		size_t l = F.length;
		size_t x = l;
		do {
			x--;
			if(F[x] !is null)
				break;
			l--;
		}
		while(x > 0);
		F.length = l;
		return v;
	}
}

/**
	Types that can be accessed as hashes of Dynamic
**/
package template DynamicHashType(T, alias F) {
	Dynamic opIndex(char[] field) {
		try
			return F[field];
		catch(Exception e)
			return null;
	}

	Dynamic opIndexAssign(Dynamic v, char[] field) {
		if(v is null) {
			try
				F.remove(field);
			catch(Exception e) {}
			return null;
		}
		F[field] = v;
		return v;
	}
}

