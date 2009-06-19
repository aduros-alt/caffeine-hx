import chx.protocols.memedb.Session;
import chx.protocols.memedb.Database;
import chx.protocols.memedb.Document;
import chx.protocols.memedb.DesignDocument;
import chx.protocols.memedb.DesignView;
import chx.protocols.memedb.JSONDocument;
import chx.protocols.memedb.Result;
import chx.protocols.memedb.Row;
import chx.protocols.memedb.View;

class MemeHammer {
	static var testname = "hammertest";
	static var maxRecords : Int = 1000;
	static var host : String = "localhost";
	static var port : Int = 4100;
	static var user : String = "sa";
	static var pass : String = "password";

	var session : Session;
	var db : Database;

	public static function main() {
		var args = neko.Sys.args();
		if(args.length > 0) {
			host = args[0];
			if(args.length > 1)
				port = Std.parseInt(args[1]);
		}
		var c = new MemeHammer();
		var records = c.createDataFast();
		var ids = c.saveData(records);
		c.fetchData(ids);
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
		var records = new Array<JSONDocument>();
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
			records.push(mr);
		}
		var end = neko.Sys.time();
		neko.Lib.println("Created "+maxRecords+ " in "+Std.string(end-start) + " seconds.. "+ Std.string(maxRecords/(end-start)) + " per second");
		return records;
	}

	public function saveData(records : Array<JSONDocument>) : Array<String> {
		var ids = new Array<String>();
		neko.Lib.println("Saving test data");
		var start = neko.Sys.time();

		for(mr in records) {
			if(db.save(mr))
				ids.push(mr.id);
			else
				throw "Save error";
		}
		var end = neko.Sys.time();
		neko.Lib.println("Saved "+maxRecords+ " in "+Std.string(end-start) + " seconds.. "+ Std.string(maxRecords/(end-start)) + " per second");
		return ids;
	}

	public function fetchData(ids : Array<String>) : Void {
		neko.Lib.println("Retrieving test data");
		var start = neko.Sys.time();

		for(id in ids) {
			var doc : Document = db.open(id);
			if(doc == null)
				throw "Error retrieving document id " + id;
		}

		var end = neko.Sys.time();
		neko.Lib.println("Retrieved "+maxRecords+ " in "+Std.string(end-start) + " seconds.. "+ Std.string(maxRecords/(end-start)) + " per second");
	}
}
