
package lua;

class Sys {

	static public function command(cmd:String, ?args : Array<String>) : Int {
		if(args != null) {
			cmd = escapeArgument(cmd);
			for(a in args)
				cmd += " " + escapeArgument(a);
		}
		return untyped __lua__("os.execute(cmd)");
	}

	static public function escapeArgument( arg : String ) : String {
		var ok = true;
		for( i in 0...arg.length )
			switch( arg.charCodeAt(i) ) {
			case 32, 34: // [space] "
				ok = false;
			case 0, 13, 10: // [eof] [cr] [lf]
				arg = arg.substr(0,i);
			}
		if(ok) return arg;
		return '"'+arg.split('"').join('\\"')+'"';
	}

	public static function exit( code : Int ) {
		untyped __lua__("os.exit(code)");
	}


	public static function getEnv(key:String) : String {
		return untyped __lua__("os.getenv(key)");
	}
}