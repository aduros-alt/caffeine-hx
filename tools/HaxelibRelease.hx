
package tools;

class HaxelibRelease {
	static var projectRoot : String = "ext";
	static var project : String = "caffeine-hx";
	static var desc : String = "Extended library for haxe";
	static var maintainer : String = "Madrok";
	static var version : String;
	static var releasenotes : String;

	static var system : String = { neko.Sys.systemName(); }

	public static function main() {
		if(system != "Linux") {
			error("This program is only tested on Linux");
		}
		if(neko.FileSystem.exists(".svn"))
			error("Must be run from an exported version of caffeine-hx");
		if(!neko.FileSystem.exists(projectRoot+"/ndll"))
			error("Run from the root directory of caffeine-hx");
		if(neko.FileSystem.exists(projectRoot+"/haxelib.xml"))
			error(projectRoot + "/haxelib.xml already exists");
		getNotes();
		getVersion();
		neko.Lib.println(makeFileContents());
		neko.Lib.println("If this looks correct, press Enter. Press CTRL-C to exit.");
		neko.io.File.stdin().readLine();
		writeFileContents();
		zipLib();

		neko.Lib.println("Success. The file "+project+".zip has been created.");
		neko.Lib.println("Remember to test it first with the command\nhaxelib test "+project+".zip");
		neko.Lib.println("After a successful test, it may be submitted with");
		neko.Lib.println("haxelib submit "+project+".zip");
	}

	static function getNotes() {
		var n : String = neko.Sys.args()[0];
		if(n == null || neko.Sys.args().length > 1) {
			error("Must include release notes as program argument. Did you forget to enclose them with quotes?");
		}
		if(n.length < 15) {
			error("Release notes should be at least 15 characters long, no?");
		}
		releasenotes = n;
	}

	static function getVersion() {
		if(!neko.FileSystem.exists("version.ext"))
			error("The version file 'version.ext' does not exist");
		var v = StringTools.trim(neko.io.File.getContent("version.ext"));
		var ereg = ~/^([0-9]+\.[0-9]+)$/;
		if(!ereg.match(v))
			error("Version string " + v + " is not properly formatted" );
		version = v;
	}

	public static function makeFileContents() : String {
		var s = "<project name=\""+ project +"\" url=\"http://code.google.com/p/caffeine-hx\" license=\"BSD\">\n";
		s += "    <user name=\""+ maintainer +"\"/>\n";
		s += "    <description>"+ desc +"</description>\n";
		s += "    <version name=\""+ version +"\">"+releasenotes+"</version>\n";
		s += "</project>\n";
		return s;
	}

	static function zipLib() {
		neko.Lib.println("Creating library zipfile");
		var cmd : String = "";
		var args : Array<String> = new Array();
		var owd = neko.Sys.getCwd();
		var oldDir = owd + projectRoot;
		var newDir = owd + project;

		neko.FileSystem.rename(oldDir, newDir);
		if(system == "Linux") {
			cmd = "zip";
			args.push("-r");
			args.push(project + ".zip");
			args.push(project);
		}
		try {
			neko.Sys.command(cmd, args);
		}
		catch(e:Dynamic) {
			neko.FileSystem.rename(newDir, oldDir);
			error(Std.string(e));
		}
		neko.FileSystem.rename(newDir, oldDir);
	}

	static function writeFileContents() {
		var fo = neko.io.File.write(projectRoot + "/haxelib.xml", false);
		fo.write(makeFileContents());
		fo.close();
	}

	public static function error( s : String ) {
		neko.Lib.println(s);
		neko.Sys.exit(1);
	}
}
