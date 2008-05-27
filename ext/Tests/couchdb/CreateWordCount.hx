import protocols.couchdb.Session;
import protocols.couchdb.Document;
import protocols.couchdb.Database;
import protocols.couchdb.DesignDocument;
import protocols.couchdb.DesignView;
import protocols.couchdb.Result;
import protocols.couchdb.Row;
import protocols.couchdb.View;
import formats.json.JsonObject;

class CreateWordCount {
	static var DBNAME : String = "word-count-example";
	static var FILES : Array<String> = ['da-vinci.txt', 'outline-of-science.txt', 'ulysses.txt'];

	static function recreateDatabase() {
		var session = new Session("localhost", 5984);
		try {
			session.deleteDatabaseByName(DBNAME);
		} catch(e : Dynamic) {}
		var db = session.createDatabase(DBNAME);
		if(db == null)
			throw "Unable to create database";
	}

	static function createDesign() {
		var session = new Session("localhost", 5984);
		var db = session.getDatabase(DBNAME);
		if(db == null)
			throw "Unable to open database";
		var dd = new DesignDocument("word_count", null, db);
		var word_count = {
			map :
			"function(doc) { " +
				"var words = doc.text.split(/\\W/); " +
				"words.forEach(function(word){ " +
					"if (word.length > 0) emit([word,doc.title],1); " +
				"}); " +
  			"}",
			reduce :
			"function(key,combine) { " +
				"return sum(combine);" +
 			"}"
		}

		dd.addView(
			new DesignView(
				"count",
				word_count.map,
				word_count.reduce
			)
		);

		dd.addView(
			new DesignView("words", word_count.map)
		);

		try {
			db.delete(db.open("_design/word_count"));
		} catch(e:Dynamic) {};
		db.save(dd);
	}

	static public function main() {
		recreateDatabase();
		createDesign();
	}
}
