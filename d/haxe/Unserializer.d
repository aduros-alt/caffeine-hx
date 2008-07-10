module haxe.Unserializer;

import IntUtil = tango.text.convert.Integer;
import FloatUtil = tango.text.convert.Float;
import tango.net.Uri;
import haxe.HaxeTypes;
//import tango.io.Console;


class Unserializer {
	private char[] buf;
	private uint pos;
	private size_t length;
	private Dynamic[]	cache;
	private char[][] scache;

	this( char[] s) {
		this.buf = s.dup;
		this.length = buf.length;
		this.pos = 0;
	}

	long readDigits() {
		long k = 0;
		bool s = false;
		auto fpos = pos;
		while(pos < length) {
			int c = cast(int) buf[pos];
			if(c == 45) {
				if(pos != fpos)
					break;
				s = true;
				pos++;
				continue;
			}
			c -= 48;
			if( c < 0 || c > 9)
				break;
			k = (k * 10) + c;
			pos++;
		}
		if(s)
			k *= -1;
		return k;
	}

	void unserializeObject(ref HaxeObject o) {
		while(true) {
			if(pos >= length)
				throw new Exception("Invalid object");
			if(buf[pos] == 'g')
				break;
			auto k = unserialize();
			if(!cast(String) k)
				throw new Exception("Invalid object key");
			auto v = unserialize();
			auto key = (cast(String) k).value;
			o[key] = v;
		}
	}

	private Enum unserializeEnum(String name, Dynamic v) {
		if( buf[pos++] != ':' )
			throw new Exception("Invalid enum format");
		auto nargs = readDigits();
		auto args = new Array();
		while( nargs > 0 ) {
			args.push(unserialize());
			nargs-=1;
		}
		return Enum.create(name, v, args);
	}

	public Dynamic unserialize() {
		switch( buf[pos++] ) {
		case 'n':
			return new Null(); break;
		case 't':
			return new Bool(true); break;
		case 'f':
			return new Bool(false); break;
		case 'z':
			return new Int(0); break;
		case 'i':
			return new Int(readDigits()); break;
		case 'd':
			auto p1 = pos;
			while(pos < length) {
				int c = cast(int) buf[pos];
				if(( c >= 43 && c < 58) || c == 101 /*e*/ || c == 69 /*E*/ )
					pos++;
				else break;
			}
			return new Float(FloatUtil.parse(buf[p1..pos+1]));
			break;
		case 'y':
			auto len = readDigits();
			if( buf[pos++] !=':' || length - pos < len )
				throw new Exception("Invalid string length");
			auto s = buf[pos..pos+len];
			pos += len;
			auto u = new Uri();
			s = u.decode(s);
			scache ~= s;
			return new String(s);
			break;
		case 'k':
			return Float.NaN();
			break;
		case 'm':
			return Float.NEGATIVE_INFINITY();
			break;
		case 'p':
			return Float.POSITIVE_INFINITY();
			break;
		case 'a':
			Array a = new Array();
			cache ~= a;
			while( true ) {
				char c = buf[pos];
				if( c == 'h' ) {
					pos++;
					break;
				}
				if( c == 'u' ) {
					pos++;
					auto n = readDigits();
					a[a.length + n - 1] = null;
				}
				else
					a.push(unserialize());
			}
			return a;
			break;
		case 'o':
			auto o = new HaxeObject();
			cache ~= o;
			unserializeObject(o);
			return o;
			break;
		case 'r':
			auto n = readDigits();
			if( n < 0 || n >= cache.length )
				throw new Exception("Invalid reference");
			return cache[n];
			break;
		case 'R':
			auto n = readDigits();
			if( n < 0 || n >= scache.length )
				throw new Exception("Invalid String reference");
			return new String(scache[n].dup);
			break;
		case 'x':
			throw unserialize();
			break;
		case 'c':
			Dynamic nd = unserialize();
			if(!cast(String) nd)
				throw new Exception("Class name invalid");
			char[] name = (cast(String) nd).value;
			// lok in HaxeClass registry
			foreach(h,d; HaxeClass.haxe2dmd) {
				if(h == name) {
					name = d;
					break;
				}
			}
			ClassInfo ci = ClassInfo.find(name);
			if(ci is null)
				throw new Exception("Class not found " ~ name);
			Object o = ci.create();
			if(!o)
				throw new Exception("Could not create class " ~ name);
			auto hso = cast(HaxeClass) o;
			if(!hso)
				throw new Exception("Class not serializable " ~ name);
			auto ho = new HaxeObject();
			unserializeObject(ho);
			if(!hso.__unserialize(ho))
				throw new Exception("Class unserialize failed " ~ name);
			return hso;
			break;
//wy6:MyEnumy3:One:1i456
//jy6:MyEnum:2:1i456
		case 'w':
			String name = cast(String) unserialize();
			return unserializeEnum(name, unserialize());
			break;
		case 'j':
			String name = cast(String) unserialize();
			if( buf[pos++] != ':' )
				throw new Exception("Invalid character");
			auto i = readDigits();
			return unserializeEnum(name, Int(i));
			break;
		case 'l':
			auto l = new List();
			while( buf[pos] != 'h' )
				l.add(unserialize());
			pos++;
			return l;
			break;
		case 'b':
			auto h = new Hash();
			while( buf[pos] != 'h' ) {
				auto s = unserialize();
				if(!cast(String) s)
					throw new Exception("Invalid hash key");
				h.set((cast(String)s).value, unserialize());
			}
			pos++;
			return h;
			break;
		case 'q':
			auto h = new IntHash();
			char c = buf[pos++];
			while( c == ':' ) {
				auto i = readDigits();
				h.set(i, unserialize());
				c = buf[pos++];
			}
			if( c != 'h')
				throw new Exception("Invalid IntHash format");
			return h;
			break;
		case 'v':
			auto d = HaxeDate.fromString(buf[pos..pos+19]);
			pos += 19;
			return d;
			break;
		default:
		}
		//pos--;
		throw new Exception("Invalid char " ~buf[pos] ~ " at position " ~ IntUtil.toString(pos) );
		return null;
	}

	static public Dynamic run( char[] v) {
		auto u = new Unserializer(v);
		return u.unserialize();
	}
}


/**
	Unserialize a field from the haxe object to either
	a haxe Int type or D int type field
**/
bool getInt(T)(ref HaxeObject o, char[] name, out T field)
{
	static if(is(T == Int)) {
		if(o[name] is null)
			field = new Int(null);
		else if(!cast(T) o[name])
			return false;
		else
			field = cast(T) o[name];
		return true;
	}
	else static if( is(T == int) ) {
		if(o[name] is null)
			field = 0;
		else if(!cast(Int) o[name])
			return false;
		else
			field = (cast(Int) o[name]).value;
		return true;
	}
	else {
		static assert(0);
	}
}

/**
	Unserialize a field from the haxe object to either
	a haxe Float type or D float type field
**/
bool getFloat(T)(ref HaxeObject o, char[] name, out T field)
{
	static if(is(T == Float)) {
		if(o[name] is null)
			field = new Float();
		else if(!cast(T) o[name])
			return false;
		else
			field = cast(T) o[name];
		return true;
	}
	else static if( is(T == float) ) {
		if(o[name] is null)
			field = T.nan;
		else if(!cast(Float) o[name])
			return false;
		else
			field = (cast(Float) o[name]).value;
		return true;
	}
	else {
		static assert(0);
	}
}

/**
	Unserialize a field from the haxe object to either
	a haxe String type or D char[] type field
**/
bool getString(T)(ref HaxeObject o, char[] name, out T field)
{
	static if(is(T == String)) {
		if(o[name] is null)
			field = new String();
		else if(!cast(T) o[name])
			return false;
		else
			field = cast(T) o[name];
		return true;
	}
	else static if( is(T == char[]) ) {
		if(o[name] is null)
			field.length = 0;
		else if(!cast(String) o[name])
			return false;
		else
			field = (cast(String) o[name]).value;
		return true;
	}
	else {
		static assert(0);
	}
}