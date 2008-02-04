
class HaxelibRelease {
	static var project : String = "caffeine-hx";
	static var desc : String = "Extended library for haxe";
	static var maintainer : String = "Madrok";
	static var version : String;
	static var releasenotes : String;


	public static function main() {
		if(neko.FileSystem.exists(".svn"))
			error("Must be run from an exported version of caffeine-hx");
	}

	public static function fileContents() : String {
		var s = "<project name=\""+ project +"\" url=\"http://code.google.com/p/caffeine-hx\" license=\"BSD\">\n";
		s += "    <user name=\""+ maintainer +"\"/>\n";
		s += "    <description>"+ desc +"</description>\n";
		s += "    <version name=\""+ version +"\">"+releasenotes+"</version>\n";
		s += "</project>\n";
		return s;
	}

	public static function error( s : String ) {
		neko.Lib.println(s);
		neko.Sys.exit(1);
	}
}
