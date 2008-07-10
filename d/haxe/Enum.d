module haxe.Enum;

private {
	import haxe.HaxeTypes;
	import tango.io.Console;
}

class EnumException : Exception
{
	this(char[] msg) {
		super(msg);
	}
}

class Enum : Dynamic
{
	public static char[][char[]] haxe2dmd;

	public char[] __enumname() {
		ClassInfo fci = this.classinfo;
		return fci.name;
	}
	public HaxeType type() { return HaxeType.TEnum; }
	public char[] toString() {
		char [] sb;
		sb ~= (cast(String)__fields[0]).value;
		sb ~= "(";
		bool first = true;
		foreach(v; this) {
			if(first)
				first = false;
			else
				sb ~= ",";
			sb ~= v.toString();
		}
		sb ~= ")";
		return sb;
	}

	public int				value;
	public Dynamic[] 		__fields;

	this() {
		value = -1;
		//static assert(tags().length == argCounts().length);
	}

	public String tag() {
		return cast(String)__fields[0];
	}

	public uint argc() {
		return cast(uint)(cast(Int)__fields[1]).value;
	}

	/** This must be an array of string tag names, which match argCounts **/
	abstract public char[][] tags();
	/** This must return an array of argument counts for each tag **/
	abstract public int[] argCounts();

	private int fromTag(char[] tagName) {
		int x = 0;
		auto t = tags();
		while(x < t.length) {
			if(t[x] == tagName)
				return x;
			x++;
		}
		throw new EnumException("Tag " ~ tagName ~ " does not exist");
	}

	private char[] toTag(int idx) {
		auto t = tags();
		if(idx < 0 || idx >= t.length)
			throw new EnumException("Tag " ~ IntUtil.toString(idx) ~ " does not exist");
		return t[idx];
	}

	private int numArgs(int idx) {
		auto t = argCounts();
		if(idx < 0 || idx >= t.length)
			throw new EnumException("Tag index " ~ IntUtil.toString(idx) ~ " does not exist");
		return t[idx];
	}

	protected void initialize(char[] tag, Array args) {
		value = fromTag(tag);
		int na = numArgs(value);
		if(args is null)
			args = new Array();
		if(args.length != na)
			throw new EnumException("Argument count not correct");
		__fields.length = 2 + na;
		__fields[0] = String(tag);
		__fields[1] = Int(na);
		if(na > 0) {
			if(args is null)
				throw new EnumException("Argument list not provided");
			int x = 2;
			foreach(arg; args) {
				__fields[x++] = arg;
			}
		}
	}



	//////////////////////////////////////////////////////
	//     Indexing.                                    //
	// __fields[0] holds enum name (tag)                //
	// __fields[1] holds arg count                      //
    // __fields[2..] hold argument data                 //
	//////////////////////////////////////////////////////
	Dynamic opIndex(size_t i) {
		i += 2;
		return __fields[i];
	}

	Dynamic opIndexAssign(Dynamic v, size_t i) {
		if(i >= argc)
			throw new Exception("Enum index out of range");
		i += 2;
		if(v is null)
			v = new Null();
		if(i >= __fields.length) {
			auto olen = __fields.length;
			__fields.length = i + 1;
			while(olen < __fields.length) {
				__fields[olen++] = new Null();
			}
		}
		__fields[i] = v;

		// trim the size down
		size_t l = __fields.length;
		size_t x = l;
		do {
			x--;
			if(__fields[x] !is null)
				break;
			l--;
		}
		while(x > 0);
		__fields.length = l;
		return v;
	}

	int opApply(int delegate(ref Dynamic) dg) {
		int res = 0;
		for (int i = 2; i < __fields.length; i++) {
			res = dg(__fields[i]);
			if(res) break;
		}
		return res;
	}

	//////////////////////////////////
	//           Resolver           //
	//////////////////////////////////
	static Enum resolve(String ename) {
		char[] name = ename.value;
		// look in Enum registry
		foreach(h,d; Enum.haxe2dmd) {
			if(h == name) {
				name = d;
				break;
			}
		}
		ClassInfo ci = ClassInfo.find(name);
		if(ci is null)
			throw new Exception("Enum not found " ~ name);
		Object o = ci.create();
		if(!o)
			throw new Exception("Could not create enum " ~ name);
		auto hso = cast(Enum) o;
		if(!hso)
			throw new Exception("Enum cast error " ~ name);
		return hso;
	}

	public static Enum create(String ename, Dynamic etag, Array args) {
		char[] tag;
		auto e = resolve(ename);
		if(cast(Int) etag) {
			tag = e.toTag(cast(int)cast(Int) etag);
		}
		else if(cast(String) etag) {
			tag = (cast(String)etag).value;
		}
		else
			throw new EnumException("Invalid etag type");
		e.initialize(tag, args);
		return e;
	}
}