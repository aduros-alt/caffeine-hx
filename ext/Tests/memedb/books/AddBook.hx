import protocols.memedb.Session;
import protocols.memedb.JSONDocument;
import protocols.memedb.Database;
import protocols.memedb.DesignDocument;
import protocols.memedb.DesignView;
import protocols.memedb.Result;
import protocols.memedb.Row;
import protocols.memedb.View;
import formats.json.JsonObject;

class AddBook {
	static var FILES : Array<String> = [];
	static var host : String;
	static var port : Int;

	static function recordText() {
		var session = new Session(host, port, Settings.USER, Settings.PASS);
		var db = session.getDatabase(Settings.DBNAME);
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
					db.save(new JSONDocument(new JsonObject(
						{
							title : title,
							chunk : chunk,
							text : lines.join('')
						}

					), title + "-Page" + chunk));
					chunk++;
					lines = [];
				}
			}
		}
	}

	public static function main() {
		FILES = neko.Sys.args();
		if(FILES.length != 3) {
			neko.Lib.println("usage: neko addbook.n [host] [port] [textfile] [textfile]...");
			neko.Sys.exit(0);
		}
		host = FILES.shift();
		port = Std.parseInt(FILES.shift());
		recordText();
		neko.Lib.println("The books have been stored in your MemeDB. To initiate the MapReduce process, visit http://"+host+":"+port+"/_utils/ in your browser and click 'word-count-example', then select view 'words' or 'count'. The process takes about 5 minutes per MB of text added.");
	}

}