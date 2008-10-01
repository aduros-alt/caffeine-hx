
import protocols.memedb.Session;
import protocols.memedb.Document;
import protocols.memedb.Database;
import protocols.memedb.DesignDocument;
import protocols.memedb.DesignView;
import protocols.memedb.Filter;
import protocols.memedb.Result;
import protocols.memedb.Row;
import protocols.memedb.View;
import formats.json.JSON;

class WordCountQuery {
	static var echo = neko.Lib.println;
	static var puts = neko.Lib.print;

	static function showResult(res:Result) {
		for(l in res.getStrings()) {
			echo(l);
		}
	}

	public static function main() {
		var args = neko.Sys.args();
		if(args.length != 2) {
			neko.Lib.println("usage: query [host] [port]");
			neko.Sys.exit(1);
		}
		var host = args[0];
		var port = Std.parseInt(args[1]);
		var session = new Session(host, port, Settings.USER, Settings.PASS);
		var db = session.getDatabase(Settings.DBNAME);
		if(db == null)
			throw "Unable to open database";
		puts("Now that we've parsed all those books into MemeDB, the queries we can run are incredibly flexible.");
		puts("\nThe simplest query we can run is the total word count for all words in all documents: ");

		echo (db.view('_word_count').value);

		puts ("\nWe can also narrow the query down to just one word, across all documents. Here is the count for 'flight' in all books: ");

		var word = 'flight';
		var filter = new Filter();
		filter.setStartKey([word,null],true).setEndKey([word,'z']);

		echo(db.view('_word_count', filter).value);

		puts ("\nSimply by skipping the reduce method of the view, we can now see all the results for the last view : \n");
		filter.setSkipReduce(true);
		showResult(db.view('_word_count', filter));

		puts ("\nWe scope the query using startkey and endkey params to take advantage of MemeDB's collation ordering. Here are the params for the last query:");
		echo(Std.string(filter));

		puts ("\nWe can also count words on a per-title basis. Number of times 'flight' occurs in 'davinci_notebook': ");
		filter = new Filter();
		var title = 'davinci_notebook';
		filter.key = [word, title];
		echo(db.view('_word_count', filter).value);

		echo('The url looks like this:');
		echo(
			"http://" + host+ ":" + port +
			"/"+Settings.DBNAME+"/_view/_word_count?key=[\"flight\",\"davinci_notebook\"]");
		echo("\nTry dropping that in your browser...");

		echo("\nTo run a fulltext query, simply call db.fulltextQuery(). In this example, our default fulltext field is named 'text', and we are looking for the word 'brown'. The results from a fulltext query are keyed from most relevant to least relevant, with a DocumentId field 'id' and Document revision field 'rev'");
		showResult(db.fulltextQuery("text", "brown"));
	}

	static function traceError(session, ?msg:String) {
		if(msg == null) msg = "";
		else msg += " : ";

		var r = session.getLastTransaction();
		var em = r.getHttpError();
		if(em != "")
			neko.Lib.println("HTTP:" + em);
			trace(r);
			neko.Lib.println("MEMEDB ERROR: " + msg + r.getErrorId()  + " : " + r.getErrorReason() );

	}
}

