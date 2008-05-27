
import protocols.couchdb.Session;
import protocols.couchdb.Document;
import protocols.couchdb.Database;
import protocols.couchdb.DesignDocument;
import protocols.couchdb.DesignView;
import protocols.couchdb.Filter;
import protocols.couchdb.Result;
import protocols.couchdb.Row;
import protocols.couchdb.View;
import formats.json.JSON;

class WordCountQuery {
	static var echo = neko.Lib.println;
	static var puts = neko.Lib.print;
	static var DBNAME : String = "word-count-example";

	static function showResult(res:Result) {

		for(l in res.getStrings()) {
			echo(l);
		}
	}

	public static function main() {
		var session = new Session("localhost", 5984);
		var db = session.getDatabase(DBNAME);
		if(db == null)
			throw "Unable to open database";
		puts("Now that we've parsed all those books into CouchDB, the queries we can run are incredibly flexible.");
		puts("\nThe simplest query we can run is the total word count for all words in all documents: ");

		echo (db.view('word_count/count').value);


		puts ("\nWe can also narrow the query down to just one word, across all documents. Here is the count for 'flight' in all three books: ");

		var word = 'flight';
		var filter = new Filter();
		filter.startKey = [word];
		filter.endKey = [word,'Z'];
		filter.update = false;

		echo(db.view('word_count/count', filter).value);
		showResult(db.view('word_count/words', filter));

		puts ("\nWe scope the query using startkey and endkey params to take advantage of CouchDB's collation ordering. Here are the params for the last query:");
		echo(Std.string(filter));

		puts ("\nWe can also count words on a per-title basis. Number of times 'flight' occurs in 'da-vinci': ");
		filter = new Filter();
		var title = 'da-vinci';
		filter.key = [word, title];
		echo(db.view('word_count/count', filter).value);

		echo('The url looks like this:');
		echo('http://localhost:5984/word-count-example/_view/word_count/count?key=["flight","da-vinci"]');
		echo("\nTry dropping that in your browser...");
	}

}

