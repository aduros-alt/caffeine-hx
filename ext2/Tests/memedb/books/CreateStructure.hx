import protocols.memedb.Session;
import protocols.memedb.Document;
import protocols.memedb.Database;
import protocols.memedb.DesignDocument;
import protocols.memedb.DesignView;
import protocols.memedb.Result;
import protocols.memedb.Row;
import protocols.memedb.View;
import formats.json.JsonObject;

class CreateStructure {
	static var FILES : Array<String> = ['davinci_notebook.txt'];
	static var host : String;
	static var port : Int;

	static function recreateDatabase() {
		var session = new Session(host, port, Settings.USER, Settings.PASS);
		try {
			session.deleteDatabaseByName(Settings.DBNAME);
		} catch(e : Dynamic) {}
		var db = session.createDatabase(Settings.DBNAME);
		if(db == null)
			throw "Unable to create database";
	}

	static function createDesign() {
		var session = new Session(host, port, Settings.USER, Settings.PASS);
		var db = session.getDatabase(Settings.DBNAME);
		if(db == null)
			throw "Unable to open database";
		var dd = new DesignDocument("_word_count", null, db);
		var word_count = {
			map :
			"function(doc) { " +
				"var words = doc.text.split(/\\W/); " +
				"for(key in words) { " +
					"var word = words[key];" +
					"if (word.length > 2) emit([word,doc.title],1); "  +
				"}; " +
				"tokenize(\"text\",doc.text);" +
  			"}",
			reduce :
			"function(results) { " +
				"return sum(results);" +
 			"}"
		}

		dd.addView(
			new View(
				word_count.map,
				word_count.reduce
			), "default"
		);

		try {
			db.delete(db.open("_word_count"));
		} catch(e:Dynamic) {};
		db.save(dd);
	}

	static public function main() {
		var args = neko.Sys.args();
		if(args.length != 2) {
			neko.Lib.println("usage: create [host] [port]");
			neko.Sys.exit(1);
		}
		host = args[0];
		port = Std.parseInt(args[1]);
		recreateDatabase();
		createDesign();
	}
}
