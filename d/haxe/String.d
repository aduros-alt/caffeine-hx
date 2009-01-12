module haxe.String;

import haxe.HaxeTypes;
static import tango.text.Util;
//import tango.io.Console;

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
	public size_t length() { return value.length; }
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

	String opAdd(char[] v) {
		this.isNull = false;
		return new String(this.value ~ v);
	}
	String opAdd(Dynamic v) {
		this.isNull = false;
		return new String(this.value ~ v.toString);
	}
	String opAdd(real v) {
		this.isNull = false;
		return new String(this.value ~ FloatUtil.toString(v));
	}
	String opAddAssign(char[] v) {
		this.isNull = false;
		this.value ~= v; return this;
	}
	String opAddAssign(Dynamic v) {
		this.isNull = false;
		this.value ~= v.toString; return this;
	}
	String opAddAssign(real v) {
		this.isNull = false;
		this.value ~= FloatUtil.toString(v); return this;
	}



	mixin Castable!(char[]);
	mixin NullComparator!(typeof(this));
	mixin NullEquality!(typeof(this));

	public StringArray split(String delim) {
		return split(delim.value);
	}

	public StringArray split(char[] delim) {
		char[][] parts;
		String[] d;

		parts = tango.text.Util.split(value, delim);
		d.length = parts.length;
		for(size_t x = 0; x < parts.length; x++)
			d[x] = String(parts[x]);
		return new StringArray(d);
	}
}
