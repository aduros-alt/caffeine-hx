
class Builder { 
	function print(s : String) {
		neko.Lib.print(s);
	}
	public function new() {
		var dirs = Maintain.getDirs();
		var owd = neko.Sys.getCwd();
		for(d in dirs) {
			neko.Sys.setCwd(d);
			print("Building " + d + "\n");
			var rv = neko.Sys.command("haxe", ["build.hxml"]);
			neko.Sys.setCwd(owd);
			if(rv != 0) {
				if(!Maintain.doContinue)
					Maintain.exitError("");
			}
		}
	}
}

class Runner {
	function print(s : String) {
		neko.Lib.print(s);
	}
	public function new() {
		var dirs = Maintain.getDirs();
		var owd = neko.Sys.getCwd();
		for(d in dirs) {
			neko.Sys.setCwd(d);
			print("\n----------------------------------------\n");
			print(d + "...");
			if(neko.FileSystem.exists("test.n")) {
				print("\n----------------------------------------\n");
				var rv = neko.Sys.command("neko", ["test.n"]);
				if(rv != 0) {
					if(!Maintain.doContinue)
						Maintain.exitError("");
				}
			}
			else {
				print("skipped. No neko file.");
				print("\n----------------------------------------\n");
			}
			neko.Sys.setCwd(owd);
		}
	}
}

class Cleaner {
	function print(s : String) {
		neko.Lib.print(s);
	}

	public static function getFiles() {
		var a = neko.FileSystem.readDirectory(".");
		var b : Array<String> = new Array();
		for(d in a) {
			var ereg = ~/^[test]/;
			if(!ereg.match(d)) {
				var ereg = ~/\.n$/;
				if(!ereg.match(d))
					continue;
			}
			if(!neko.FileSystem.isFile(d)) {
				if(!neko.FileSystem.isDirectory(d))
					Maintain.exitError("file " + d + " is not a regular file!");
			}
			else
				b.push(d);
		}
		return b;
	}

	public function new() {
		var dirs = Maintain.getDirs();
		var owd = neko.Sys.getCwd();
		for(d in dirs) {
			print("Cleaning " + d + "\n");
			neko.Sys.setCwd(d);
			var flist = getFiles();
			for(f in flist) {
				print("..."+f+"\n");
				var rv = neko.Sys.command("rm", [f]);
				if(rv != 0) {
					Maintain.exitError("Error removing " + f);
				}
			}
			neko.Sys.setCwd(owd);
		}
	}
}

class Maintain {
	static public var doBuild : Bool;
	static public var doRun : Bool;
	static public var doClean : Bool;
	static public var doContinue : Bool;

	public static function usage() {
		var s = "neko maintain.n\n";
		s+= "\t--build\tBuild all tests\n";
		s += "\t--run       Run neko tests\n";
		s += "\t--clean     Remove all compiled files\n";
		s += "\t--continue  Continue on errors\n";
		return s;
	}

	public static function getDirs() {
		var a = neko.FileSystem.readDirectory(".");
		var b : Array<String> = new Array();
		for(d in a) {
			if(!neko.FileSystem.isDirectory(d))
				continue;
			var ereg = ~/^[a-z]/;
			if(!ereg.match(d))
				continue;
			b.push(d);
		}
		return b;
	}

	public static function main() {
		if(!neko.FileSystem.exists("Templates") || !neko.FileSystem.exists("hash"))
			exitError("You don't seem to be running in the Tests directory");
		if(neko.Sys.args().length == 0)
			exitError(usage());

		for(arg in neko.Sys.args()) {
			if(arg == "--help" || arg == "-h") {
				neko.Lib.println(usage());
				neko.Sys.exit(0);
			}
			if(arg == "--build")
				doBuild = true;
			else if ( arg == "--run" )
				doRun = true;
			else if ( arg == "--clean" )
				doClean = true;
			else if ( arg == "--continue" )
				doContinue = true;
			else
				exitError("Invalid command " + arg);
		}

		if(doBuild) {
			var p = new Builder();
		}
		if(doRun) {
			var p = new Runner();
		}
		if(doClean) {
			var p = new Cleaner();
		}

	}

	public static function exitError(s:String) {
		neko.Lib.println(s);
		neko.Sys.exit(100);
	}

}

