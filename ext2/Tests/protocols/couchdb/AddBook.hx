import protocols.couchdb.Session;
import protocols.couchdb.Document;
import protocols.couchdb.Database;
import protocols.couchdb.DesignDocument;
import protocols.couchdb.DesignView;
import protocols.couchdb.Result;
import protocols.couchdb.Row;
import protocols.couchdb.View;
import formats.json.JsonObject;

class AddBook {
	static var DBNAME : String = "word-count-example";
	static var FILES : Array<String> = [];

	static function recordText() {
		var session = new Session("localhost", 5984);
		var db = session.getDatabase(DBNAME);
		if(db == null)
			throw "Unable to open database";

		for(book in FILES) {
			var title = book.split('.')[0];
			var fi = neko.io.File.read(book, false);

			var lines : Array<String> = new Array();
			var chunk = 0;
			var cont : Bool = true;
			while(cont) {
				try {
					lines.push(fi.readLine());
				}
				catch(e:neko.io.Eof) {
					cont = false;
				}
				if(lines.length > 100 || !cont) {
					db.save(new Document(new JsonObject(
						{
							title : title,
							chunk : chunk,
							text : lines.join('')
						}
					)));
					chunk++;
					lines = [];
				}
			}
		}
	}

	public static function main() {
		FILES = neko.Sys.args();
		if(FILES.length == 0) {
			neko.Lib.println("usage: neko addbook.n [textfile] [textfile]...");
			neko.Sys.exit(0);
		}
		recordText();
		neko.Lib.println("The books have been stored in your CouchDB. To initiate the MapReduce process, visit http://localhost:5984/_utils/ in your browser and click 'word-count-example', then select view 'words' or 'count'. The process takes about 5 minutes per MB of text added.");
	}

}