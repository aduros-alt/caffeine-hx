module haxe.Unserializer;

import IntUtil = tango.text.convert.Integer;
import FloatUtil = tango.text.convert.Float;
import tango.net.Uri;
import haxe.HaxeTypes;


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

	void unserializeObject(HaxeObject o) {
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
			return Float.nan();
			break;
		case 'm':
			return Float.negativeInfinity();
			break;
		case 'p':
			return Float.positiveInfinity();
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
			throw new Exception("Class unserializing not complete");
// 			auto cl = createClass(name);
// 			if(cl is null)
// 				throw new Exception("Class not found " ~ name);
// 			auto o = new HaxeObject();
// 			unserializeObject(o);
// 			cl.__unserialize(o);
// 			return cl;
			break;
		case 'w':
			throw new Exception("Enum unserializing not complete");
			break;
		case 'j':
			throw new Exception("Enum unserializing not complete");
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