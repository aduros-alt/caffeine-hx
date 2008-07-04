module haxe.Serializer;

import haxe.HaxeTypes;
import haxe.Hash;
import haxe.IntHash;

import tango.core.Variant;
import tango.util.container.HashMap;
import tango.net.Uri;
import Integer = tango.text.convert.Integer;

import tango.io.Console;


alias HashMap!(char[], int) HashOfInts;
alias HashMap!(char[], char[]) HashOfStrings;


class Serializer {
	public static bool 	USE_CACHE;
	public static bool	USE_ENUM_INDEX;
	private char[]		buf;
	private Variant[]	cache;
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

/*
	void serializeRef(Variant v) {
			for( i in 0...cache.length ) {
					#if js
					var ci = cache[i];
					if( untyped __js__("typeof")(ci) == vt && ci == v ) {
					#else true
					if( cache[i] == v ) {
					#end
							buf.add("r");
							buf.add(i);
							return true;
					}
			}
			cache.push(v);
			return false;
	}
*/

	public void serialize(int v) {
		if(v == 0) {
			buf ~= "z";
			return;
		}
		buf ~= "i";
		buf ~= Integer.toString(v);
	}

	public void serialize(int[] v) {
		buf ~= "a";
		foreach(i; v)
			serialize(i);
		buf ~= "h";
	}

	public void serialize(bool v) {
		buf ~= (v ? "t" : "f");
	}

	public void serialize(char v) {
		char[] a;
		a ~= v;
		serializeString(a);
	}

	public void serialize(char[] v) {
		serializeString(v);
	}

// 	public void serialize(Dynamic v) {
// 	}

/*
	public void serialize(Object o) {
		Cout("SERIALIZE OBJECT ")(o.toString).newline;
/+
		TypeInfo ti = typeid(v);
		Cout("Type: {} ")(ti.classinfo.name).newline;
		Cout("Base: {} {}")
			(ti.classinfo.base.name)(" ")
			(v.toString)(" ").newline;
			//(v.get!(char [])).newline;
+/
	}
*/

	public void serialize(HaxeValue val) {
		switch(val.type) {
		case HaxeType.TNull:
			break;
		case HaxeType.TDynamic:
			serialize((cast(Dynamic) val).value);
			break;
		case HaxeType.TString:
			serialize((cast(String) val).value);
			break;
		case HaxeType.TInt:
		case HaxeType.TFloat:
		case HaxeType.TBool:
		case HaxeType.TArray:
		case HaxeType.TList:
		case HaxeType.TDate:
			break;
		case HaxeType.THash:
// 			buf ~= (cast(Hash)val).__serialize();
			break;
		case HaxeType.TIntHash:
// 			buf ~= (cast(IntHash)val).__serialize();
			break;
		case HaxeType.TEnum:
		case HaxeType.TObject:
		case HaxeType.TClass:
		case HaxeType.TFunction:
			throw new Exception("Unable to serialize functions");
			break;
		}
	}

/*
	public void serialize(T)( T val ) {

// 		if(value is null) {
// 			buf ~= "n";
// 			return;
// 		}

		Variant var = val;
		TypeInfo ti = var.type();
		auto name = var.toString;
/+
		//TypeInfo ti = typeid(v);
		Cout("Type: {} ")(ti.classinfo.name).newline;
		Cout("Base: {} {}")
			(ti.classinfo.base.name)(" ")
			(v.toString)(" ").newline;
			//(v.get!(char [])).newline;
+/
		bool handled = true;

		switch(name) {
		case "int":
			if(var.get!(int) == 0) {
				buf ~= "z";
				return;
			}
			buf ~= "i";
			buf ~= Integer.toString(var.get!(int));
			break;
		case "bool":
			buf ~= (var.get!(bool) ? "t" : "f");
			break;
		case "char[]":
			serializeString(var.get!(char[]));
			break;
		case "int[]":
			break;
		default:
			handled = false;
		}
		if(handled) return;


		// tango.util.container.HashMap.HashMap!(char[],int).HashMap
		if(name.length > 29  && name[29..37] == "HashMap!") {
			Cout(name[38..44]).newline;
			if(name[38..44] == "char[]") {
				buf ~= "b";
				auto h = new HashMap!(char[], Variant);
				foreach (key, value; cast(HashMap!(char[],void*))val) {
				}
			}
			else {}
		}

		throw new Exception("Cannot serialize " ~ var.toString);
	}
*/

}