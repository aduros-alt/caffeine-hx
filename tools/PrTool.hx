
package tools;

/**
	PrTool writes all PR request patches to std output.

	The PR format is:
**/
//BEGINPR/ID/CREATED_DATE/SUBMIT_DATE/AUTHOR/COMMENT
//ENDPR/ID/STATUS(N|A|R|I)/ACTION_DATE/REASON

typedef Creation = {
	var date : Date;
	var author : String;
	var comment : String;
};

enum Pr {
	//OPENING TAGS
	// to submit
	PR_NEW(line:Int, id:String, info : Creation);
	// submitted on
	PR_SUBMITTED(line:Int, id:String, info: Creation, sdate : Date);
	// accepted into haxe

	//CLOSING TAGS
	PR_CLOSE_NEW(line:Int, id:String);
	PR_ACCEPTED(line:Int, id:String, date:Date);
	// rejected with reason
	PR_REJECTED(line:Int, id:String, date:Date, reason: String);
	// rejected but we're keeping the change
	PR_IGNORE(line:Int, id:String, date : Date);
}

class PrTool {
	static var system : String = { neko.Sys.systemName(); }
	static var base 	: String  = "ext/";
	static var haxe_base: String;
	static var haxe_cur : String;
	static var env 		: Hash<String>;
	static var cpath	: Array<String>;
	static var openPr : EReg = ~/^[\s]*\/\/BEGINPR/;
	static var closePr : EReg = ~/^[\s]*\/\/ENDPR/;


	public static function main() {
		if(system != "Linux") {
			error("This program is only tested on Linux");
		}
		if(!neko.FileSystem.isDirectory(base))
			error("Run this from the root directory of caffeine-hx");
		init_env();
		cpath = new Array();
		neko.Sys.setCwd(base);
		haxe_cur = haxe_base + "/std";
		processDirectory("");
	}

	public static function error( s : String ) {
		neko.Lib.println(s);
		neko.Sys.exit(1);
	}

	public static function getDirs(p : String) {
		var a = neko.FileSystem.readDirectory(p);
		var b : Array<String> = new Array();
		for(d in a) {
			if(!neko.FileSystem.isDirectory(d))
				continue;
			if(d == ".svn")
				continue;
			var ereg = ~/^[a-z]/;
			if(!ereg.match(d))
				continue;
			b.push(d);
		}
		return b;
	}

	public static function getFilesInCwd() {
		var a = neko.FileSystem.readDirectory(".");
		var b : Array<String> = new Array();
		for(d in a) {
			var ereg = ~/[A-Z]+.*\.hx$/;
			if(!ereg.match(d))
				continue;
			if(!neko.FileSystem.isFile(d)) {
				error("file " + neko.Sys.getCwd() + "/"+ d + " is not a regular file!");
			}
			b.push(d);
		}
		return b;
	}

	static function init_env() {
		env = neko.Sys.environment();
		if(!env.exists("CAFFEINE_HAXE_CVS"))
			error("The CAFFEINE_HAXE_CVS environment variable is not set");
		haxe_base = env.get("CAFFEINE_HAXE_CVS");
		if(!neko.FileSystem.isDirectory(haxe_base))
			error("The CAFFEINE_HAXE_CVS does not exist");
	}

	static function log(s : String) {
		neko.io.File.stderr().write(s+"\n");
		neko.io.File.stderr().flush();
	}

	static function makePath() : String {
		var sb = new StringBuf();

		for(pp in cpath) {
			sb.add(pp);
			sb.add("/");
		}
		return sb.toString();
	}

	static function processDirectory(p : String) {
		cpath.push(p);
		neko.Sys.setCwd("./" + p);
		var path = makePath();
		var files = getFilesInCwd();
		for(f in files) {
			var rv = checkFile(f);
			if(rv.hasPr) {
				var fullFile = makePath() + f;
				log(fullFile + " HAS PR");
				var p = createStdLibPatch(f, rv.fileContents, path+f);
				neko.Lib.println(p);
			}
		}
		var dirs = getDirs(".");
		for(d in dirs) {
			processDirectory(d);
		}
		cpath.pop();
		neko.Sys.setCwd("./../");
	}


	static function checkFile( f : String) {
		var fullFile = makePath() + f;
		var hasPr = false;
		var vCaffeine : Array<String> = new Array();
		var vPatch : Array<String> = new Array();
		var lastPr : Pr = null;

		var fiCaffeine = neko.io.File.read(f, false);
		var line : Int = 0;
		try {
			while(true) {
				var s = fiCaffeine.readLine();
				line ++;
				if(openPr.match(s)) {
					if(lastPr != null) {
						var lstr = switch(lastPr) {
						case PR_NEW(line,id,info) : Std.string(line);
						case PR_SUBMITTED(line,id,info,sdate) : Std.string(line);
						default : "???";
						}
						error(fullFile + ": Unclosed PR tag at line " + line + ". Opened on line "+lstr);
					}
					lastPr = processTag(s, line);
					hasPr = true;
				}
				else if(closePr.match(s)) {
					if(lastPr == null)
						error(fullFile + ": Close PR tag on line " + line + " with no open pr." );
					var ct = processTag(s,line);
					switch(ct) {
					case PR_CLOSE_NEW(line, label):
						vCaffeine = vCaffeine.concat(vPatch);
					case PR_ACCEPTED(line, label, date):
						vCaffeine = vCaffeine.concat(vPatch);
					case PR_REJECTED(line, label, date, reason):
					case PR_IGNORE(line, label, date):
					default:
						error(fullFile + ": Unexpected Close PR tag "+ct + "at line "+line);
					}
					lastPr = null;
					vPatch = new Array();
				}
				else {
					if(lastPr != null)
						vPatch.push(s);
					else
						vCaffeine.push(s);
				}
			}
		}
		catch(e : neko.io.Eof) {
			fiCaffeine.close();
		}
		catch(e : Dynamic) {
			error(fullFile + ": "+ Std.string(e));
		}
		return {hasPr: hasPr, fileContents: vCaffeine.join('\n') + "\n"};
	}

	static function processTag(s : String, line : Int) {
		var rv: Pr = null;
		var parts = s.split("/");
		parts.shift();
		parts.shift();
		var t = parts.shift();
		if(t == "BEGINPR") {
			var label = parts.shift();
			var odate = Date.fromString(parts.shift());
			var submitted = true;
			var sdate : Date;
			try {
				sdate = Date.fromString(parts.shift());
			} catch(e:Dynamic) {
				submitted = false;
			}
			var a = parts.shift();
			var c = parts.join("");
			var infos = {
				date: odate,
				author: a,
				comment: c,
			};
			if(submitted) {
				rv = PR_SUBMITTED(line, label, infos, sdate);
			}
			else {
				rv = PR_NEW(line, label, infos);
			}
		}
		else if(t == "ENDPR") {
			var label = parts.shift();
			var status = parts.shift();
			if(status == null || status == '')
				status = "N";
			status = status.toUpperCase();
			switch(status.substr(0,1)) {
			case "N":
				return PR_CLOSE_NEW(line, label);
			case "A","R","I":
			default:
				throw("Invalid status ["+ status + "] on close pr tag");
			}
			/*
			//CLOSING TAGS
			PR_CLOSE_NEW(line:Int, id:String);
			PR_ACCEPTED(line:Int, id:String, date:Date);
			// rejected with reason
			PR_REJECTED(line:Int, id:String, date:Date, reason: String);
			// rejected but we're keeping the change
			PR_IGNORE(line:Int, id:String, date : Date);
			*/
			var sDate = parts.shift();
			var date : Date;
			try {
				date = Date.fromString(sDate);
			}
			catch(e :Dynamic) {
				throw("End PR date field " + sDate + " is invalid");
			}
			var reason = parts.join('');
			return switch(status.substr(0,1)) {
			case "A": PR_ACCEPTED(line, label, date);
			case "R": PR_REJECTED(line, label, date, reason);
			case "I": PR_IGNORE(line, label, date);
			}
		}
		return rv;
	}

	static function createStdLibPatch(file:String, caf:String, path:String ) {
		var hf = haxe_cur + path;
		var hs = neko.io.File.getContent(hf);
		var fdate = neko.FileSystem.stat(hf).mtime;

		var ofile = "haxe.orig/std" + path;
		var nfile = "haxe/std" + path;
		var oline = "--- " + ofile + "     " + xdiff.Tools.dateFormat(fdate);
		var mline = "+++ " + nfile + "  " + xdiff.Tools.dateFormat(Date.now());

		var patch = xdiff.Tools.diff(hs, caf);
		var fo = new neko.io.StringOutput();
		//var fo = neko.io.File.write(file + ".patch",false);
		fo.write(oline + "\n");
		fo.write(mline + "\n");
		fo.write(patch);
		fo.close();
		return fo.toString();
	}
}
