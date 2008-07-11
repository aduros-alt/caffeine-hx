module haxe.Serializer;

import tango.util.container.HashMap;
import tango.net.Uri;
import Integer = tango.text.convert.Integer;

import tango.io.Console;

import haxe.HaxeTypes;
import haxe.Enum;

private alias HashMap!(char[], int) HashOfInts;

class Serializer {
	public static bool 	USE_CACHE;
	public static bool	USE_ENUM_INDEX;
	package char[]		buf;
	private Dynamic[]	cache;
	private HashOfInts	shash;
	private int			scount;
	private bool		useCache;
	private bool		useEnumIndex;

	static this() {
		USE_CACHE = false;
		USE_ENUM_INDEX = false;
	}

	this() {
		useCache = USE_CACHE;
		useEnumIndex = USE_ENUM_INDEX;
		scount = 0;
		this.shash = new HashOfInts();
		buf = "";
	}

	public override char[] toString() {
		return buf;
	}

	/* prefixes :
		a : array
		b : hash
		c : class
		d : Float
		e : reserved (float exp)
		f : false
		g : object end
		h : array/list/hash end
		i : Int
		I : Int32
		j : enum (by index)
		k : NaN
		l : list
		m : -Inf
		n : null
		o : object
		p : +Inf
		q : inthash
		r : reference
		s :
		t : true
		u : array nulls
		v : date
		w : enum
		x : exception
		y : urlencoded string
		z : zero
        */

	public void serializeString( char[] s ) {
			int x;
			if( shash.containsKey(s) ) {
				x = shash[s];
				buf = buf ~ "R" ~ Integer.toString(x);
				return;
			}
			shash.add(s,scount++);
			buf ~= "y";
			auto u = new Uri();
			char[] res = u.encode(s, Uri.IncGeneric); ///Uri.IncGeneric
			buf ~= Integer.toString(res.length);
			buf ~= ":";
			buf ~= res;
	}

	bool serializeRef(Dynamic v) {
		for( size_t i = 0; i < cache.length; i++ ) {
			if( cache[i] == v ) {
				buf ~= "r";
				buf ~= IntUtil.toString(i);
				return true;
			}
		}
		cache ~= v;
		return false;
	}

	/**
		Serialize a hash of Dynamics
	**/
	public void serializeFields(Dynamic[char[]] v) {
		foreach(field, value; v) {
			serializeString(field);
			serialize(value);
		}
	}

	public void serializeInt(int v) {
		if(v == 0) {
			buf ~= "z";
			return;
		}
		buf ~= "i";
		buf ~= Integer.toString(v);
	}

	public void serializeIntArray(int[] v) {
		buf ~= "a";
		foreach(i; v)
			serializeInt(i);
		buf ~= "h";
	}

	public void serializeDouble(double v) {
		if(v == -double.infinity)
			buf ~= "m";
		else if( v == double.infinity )
			buf ~= "p";
		else if(v == double.nan) {
			buf ~= "k";
		}
		else {
			buf ~= "d";
			buf ~= FloatUtil.toString(v);
		}
	}

	public void serializeDoubleArray(double[] v) {
		buf ~= "a";
		foreach(i; v)
			serializeDouble(i);
		buf ~= "h";
	}

	public void serializeBool(bool v) {
		buf ~= (v ? "t" : "f");
	}

	/**
		Classes must only serialize their member variables in
		the __serialize() callback.
	**/
	public void serializeClass(HaxeSerializable c) {
		buf ~= "c";
		char[] name;
		bool found;
		foreach(h,d; HaxeClass.haxe2dmd) {
			if(d == c.__classname) {
				name = h;
				found = true;
				break;
			}
		}
		if(!found) name = c.__classname;
		serializeString(name);
		if(cast(Dynamic) c)
			cache ~= cast(Dynamic)c;
		buf ~= c.__serialize();
		buf ~= "g";
	}

	public void serializeEnum(Enum c) {
		if( useCache && serializeRef(c) )
			return;
		if(cache.length > 0)
			cache.length = cache.length - 1;
		buf ~= (useEnumIndex ? "j" : "w");
		char[] name;
		bool found;
		foreach(h,d; Enum.haxe2dmd) {
			if(d == c.__enumname) {
				name = h;
				found = true;
				break;
			}
		}
		if(!found) name = c.__enumname;
		serializeString(name);
		if(useEnumIndex) {
			buf ~= ":";
			buf ~= IntUtil.toString(c.value);
		}
		else
			serialize(c.tag);
		buf ~= ":";
		buf ~= IntUtil.toString(c.argc);
		foreach(arg; c) {
			serialize(arg);
		}
		cache ~= c;
	}

	public Serializer serialize(Dynamic val) {
		if(val is null)
			val = new Null();
		switch(val.type) {
		case HaxeType.TNull:
			buf ~= "n";
			break;
		case HaxeType.TString:
			serializeString((cast(String) val).value);
			break;
		case HaxeType.TInt:
			auto v = cast(Int) val;
			if(v.isNull)
				serialize(new Null());
			else
				serializeInt(v.value);
			break;
		case HaxeType.TFloat:
			auto v = cast(Float) val;
			if(v == Float.NaN)
				buf ~= "k";
			else if(v == Float.POSITIVE_INFINITY)
				buf ~= "p";
			else if(v == Float.NEGATIVE_INFINITY)
				buf ~= "m";
			else
				serializeDouble(cast(double)v.value);
			break;
		case HaxeType.TBool:
			bool v = (cast(Bool) val).value;
			serializeBool(v);
			break;
		case HaxeType.TArray:
			if( cast(Array)val ) {
				buf ~= (cast(Array)val).__serialize();
			}
			else {
				throw new Exception("Unable to cast "~ typeof(val).stringof ~" to Array!(Dynamic) " );
			}
			break;
		case HaxeType.TList:
			if( cast(List)val ) {
				buf ~= (cast(List)val).__serialize();
			}
			else {
				throw new Exception("Unable to cast "~ typeof(val).stringof ~" to List!(Dynamic) " );
			}
			break;
		case HaxeType.TDate:
			buf ~= "v";
			buf ~= (cast(HaxeDate)val).toString();
			break;
		case HaxeType.THash:
			buf ~= (cast(Hash)val).__serialize();
			break;
		case HaxeType.TIntHash:
			buf ~= (cast(IntHash)val).__serialize();
			break;
		case HaxeType.TEnum:
			serializeEnum(cast(Enum)val);
			break;
		case HaxeType.TObject:
			if( useCache && serializeRef(val) )
				return this;
			buf ~= "o";
			buf ~= (cast(HaxeObject)val).__serialize();
			buf ~= "g";
			break;
		case HaxeType.TClass:
			serializeClass(cast(HaxeClass) val);
			break;
		case HaxeType.TFunction:
			throw new Exception("Unable to serialize functions");
			break;
		}
		return this;
	}

	static public char[] run(Dynamic v) {
		auto s = new Serializer();
		s.serialize(v);
		return s.toString();
	}
}