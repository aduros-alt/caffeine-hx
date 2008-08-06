import protocols.memedb.Session;
import protocols.memedb.Database;
import protocols.memedb.DesignDocument;
import protocols.memedb.DesignView;
import protocols.memedb.JSONDocument;
import protocols.memedb.Result;
import protocols.memedb.Row;
import protocols.memedb.View;

class MemeHammer {
	static var testname = "hammertest";
	static var maxRecords : Int = 1000;
	static var host : String = "localhost";
	static var port : Int = 4100;
	static var user : String = "russell";
	static var pass : String = "";

	var session : Session;
	var db : Database;

	public static function main() {
		var args = neko.Sys.args();
		if(args.length > 0)
			host = args[0];
		var c = new MemeHammer();
		c.createDataFast();
	}

	public function new() {
		session = new Session(host, port, user, pass);
		db = session.getDatabase(testname);
		if(db == null) {
			db = session.createDatabase(testname);
			if(db == null) {
				trace("Could not create database");
				neko.Sys.exit(1);
			}
		}

	}

	public function createDataFast() {
		var rand = new neko.Random();
		rand.setSeed(Std.int(neko.Sys.time()) + (145 * 2));

		neko.Lib.println("Creating test data");
		var start = neko.Sys.time();
		for(x in 1...maxRecords+1) {
			var keysb = new StringBuf();
			for(x in 0...12) {
				keysb.addChar(rand.int(25)+65);
			}

			var mr = new JSONDocument();
			mr.set("title", "Test Post");
			mr.set("author", keysb.toString());
			//mr.set("postTime", Date.now());
			db.save(mr);
		}
		var end = neko.Sys.time();
		neko.Lib.println("Created "+maxRecords+ " in "+Std.string(end-start) + " seconds.. "+ Std.string(maxRecords/(end-start)) + " per second");
	}
}
