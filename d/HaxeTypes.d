module haxe.HaxeTypes;

private {
	import FloatUtil = tango.text.convert.Float;
	import IntegerUtil = tango.text.convert.Integer;
	import tango.math.Math;
}


public enum HaxeType
{
	TNull,
	TDynamic,
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
abstract class HaxeValue
{
	public bool isNull;
	abstract public HaxeType type();
	abstract public char[] toString();
}

/**
	Base class for all haxe class types
**/
abstract class HaxeClass : HaxeValue
{
	abstract public char[] __classname();
	abstract public char[] __serialize();
	abstract public bool __unserialize();

	public HaxeType type() { return HaxeType.TClass; }
	public char[] toString() { return __classname(); }
}

private template Comparator(T:HaxeValue) {
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

private template NullComparator(T:HaxeValue) {
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

private template Equality(T:HaxeValue) {
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
private template NullEquality(T:HaxeValue) {
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
//                DYNAMIC TYPE                          //
//////////////////////////////////////////////////////////
/**
	Type that can contain types or objects
**/
class Dynamic : HaxeValue {
	public HaxeType type() { return HaxeType.TDynamic; }
	public HaxeValue value;

	this() { isNull = true; }
	this(HaxeValue val) { isNull = false; this.value = val; }

	public char[] toString()
	{
		if(isNull) return "(null)";
		return value.toString();
	}

	mixin Castable!(HaxeValue);
	mixin NullComparator!(typeof(this));
	mixin NullEquality!(typeof(this));
}



//////////////////////////////////////////////////////////
//                 STRING TYPE                          //
//////////////////////////////////////////////////////////
class String : HaxeValue
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
	String opAssign(char[] v) {
		this.isNull = false;
		this.value = v;
		return this;
	}
	String opCat(char[] v) {
		this.isNull = false;
		return new String(this.value ~ v);
	}
	String opCat(HaxeValue v) {
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
	String opCatAssign(HaxeValue v) {
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
class Null : HaxeValue
{
	public HaxeType type() { return HaxeType.TNull; }
	this() { isNull = true; }
	static Null opCall() { return new Null(); }
 	int opEquals(Object o) {
		if(o is this || o is null) return true;
		if(! cast(HaxeValue) o)
			return false;
		if( (cast(HaxeValue)o).isNull)
			return true;
		return false;
	}
	int opCmp(Object o) {
		if(o is this || o is null) return 0;
		if( (cast(HaxeValue)o).isNull)
			return 0;
		return 1;
	}
	public char[] toString()
	{
		return "(null)";
	}
}

class Bool : HaxeValue
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
abstract class HaxeNumeric : HaxeValue
{
}

/**
	Only applicable to integer type
**/
private template Bitwise(T:HaxeValue) {
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

private template NumericMath(T:HaxeValue) {
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
		return IntegerUtil.toString(value);
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

	this() { isNull = true; this.value = 0; }
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
}



