module haxe.Serializer;

import tango.util.container.HashMap;
import tango.net.Uri;
import IntUtil = tango.text.convert.Integer;

// import tango.io.Console;

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

	this(bool useCache) {
		this();
		this.useCache = useCache;
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
				buf = buf ~ "R" ~ IntUtil.toString(x);
				return;
			}
			shash.add(s,scount++);
			buf ~= "y";
			auto u = new Uri();
			char[] res = u.encode(s, Uri.IncGeneric); ///Uri.IncGeneric
			buf ~= IntUtil.toString(res.length);
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

	public void serializeField(char[] k, Dynamic v) {
		serializeString(k);
		serialize(v);
	}

	public void serializeInt(int v) {
		if(v == 0) {
			buf ~= "z";
			return;
		}
		buf ~= "i";
		buf ~= IntUtil.toString(v);
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
		// TODO: there should be a dynamic type that wraps non-HaxeClass
		// type classes that can be added to the cache to prevent circular
		// references
		if(cast(Dynamic) c)
			cache ~= cast(Dynamic)c;
		//if(cast(HaxeClass) c) {
		//	serializeFields((cast(HaxeClass) c).__fields);
		//}
		c.__serialize(this);
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
			auto s = cast(String) val;
			if(!s) goto casterror;
			if(s.isNull)
				serialize(new Null());
			else
				serializeString(s.value);
			break;
		case HaxeType.TInt:
			auto v = cast(Int) val;
			if(!v) goto casterror;
			if(v.isNull)
				serialize(new Null());
			else
				serializeInt(v.value);
			break;
		case HaxeType.TFloat:
			auto v = cast(Float) val;
			if(!v) goto casterror;
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
			auto b = cast(Bool) val;
			if(!b) goto casterror;
			serializeBool(b.value);
			break;
		case HaxeType.TArray:
			auto a = cast(Array) val;
			if(!a) goto casterror;
			a.__serialize(this);
			break;
		case HaxeType.TList:
			auto l = cast(List)val;
			if(!l) goto casterror;
			buf ~= "l";
			foreach(v; l.data)
				serialize(v);
			buf ~= "h";
			break;
		case HaxeType.TDate:
			auto d = cast(HaxeDate)val;
			if(!d) goto casterror;
			buf ~= "v";
			buf ~= d.toString();
			break;
		case HaxeType.THash:
			auto h = cast(Hash)val;
			if(!h) goto casterror;
			buf ~= "b";
			foreach(k, v; h.data) {
				if(v !is null) {
					serializeString(k);
					serialize(v);
				}
			}
			buf ~= "h";
			break;
		case HaxeType.TIntHash:
			auto h = cast(IntHash)val;
			if(!h) goto casterror;
			buf ~= "q";
			foreach(k, v; h.data) {
				buf ~= ":";
				buf ~= IntUtil.toString(k);
				serialize(v);
			}
			buf ~= "h";
			break;
		case HaxeType.TEnum:
			serializeEnum(cast(Enum)val);
			break;
		case HaxeType.TObject:
			auto o = cast(HaxeObject)val;
			if(!o) goto casterror;
			if( useCache && serializeRef(val) )
				return this;
			buf ~= "o";
			o.__serialize(this);
			buf ~= "g";
			break;
		case HaxeType.TClass:
			auto c = cast(HaxeClass) val;
			if(!c) goto casterror;
			if( useCache && serializeRef(val) )
				return this;
			cache.length = cache.length - 1;
			serializeClass(c);
			break;
		case HaxeType.TFunction:
			throw new Exception("Unable to serialize functions");
			break;
		}
		return this;
casterror:
		throw new Exception("Unable to cast "~ typeof(val).stringof);
		return null;
	}

	static public char[] run(Dynamic v, bool useCache = true) {
		auto s = new Serializer(useCache);
		s.serialize(v);
		return s.toString();
	}
}