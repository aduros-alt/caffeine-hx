import protocols.couchdb.Session;
import protocols.couchdb.Document;
import protocols.couchdb.Database;
import protocols.couchdb.DesignDocument;
import protocols.couchdb.DesignView;
import protocols.couchdb.Result;
import protocols.couchdb.Row;
import protocols.couchdb.View;

class Couch {
	static var print : String->Void = neko.Lib.print;
	static var println : String->Void = neko.Lib.println;
	var session : Session;

	public function new() {
		session = new Session("localhost", 5984);

		var dbn = session.getDatabaseNames();
		println("Existing databases: ");
		for(i in dbn) {
			println("\t" + i);
		}

		initialTests();
		dbCreateTest();
		docTest();
		//createMultipleDocuments();
		//viewTest();
		storedViewsTest();
		compactTest();
		//cleanup();
	}

	public function getDb(n : String) : Database {
		var db = session.getDatabase(n);
		if(db == null) {
			traceError("session.getDatabase(" + n+ ")");
		}
		else {
			//trace("Got database");
		}
		return db;
	}

	function initialTests() {
		println("\n---- Initial Tests ----");
		println(">>> Should not exist");
		var db = getDb("mytestdb");
		println(">>> Should be an illegal name");
		db = getDb("Idon'tExist");
		println(">>> Should not exist");
		db = getDb("idonteither");
	}

	function dbCreateTest() {
		println("\n---- Db Create Test ----");
		var db = session.createDatabase("mytestdb");
		if(db == null) {
			traceError("creating mytestdb");
		}
		else
			print("Ok.");
	}

	function docTest() {
		println("============= docTest ================");
		var db = getDb("mytestdb");
		if(db == null) throw "failed";

		var doc = new Document();
		doc.set("myfield", "myvalue");
		db.save(doc);
		println("Created document "+doc.id);
		println("\trev: "+doc.revision);
		println("\ttoString: " + Std.string(doc));

		doc.set("myfield", "I updated this");
		if(db.save(doc)) {
			println("Updated document "+doc.id);
			println("\trev: "+doc.revision);
			println("\ttoString: " + Std.string(doc));
		}
		else {
			traceError();
			throw "exit";
		}

		if(!db.delete(doc)) {
			traceError();
			throw "exit";
		}
	}

	function createMultipleDocuments() {
		var db = session.createDatabase("mytestdb2");
		var rand = new neko.Random();
		var idx : Int = 0;
		var names= ['Jack','Judy','Jill','John','Jeremy','Joseph','Jaqueline','Jim'];

		var insert = function() {
			var d = new Document();
			d.set("name", names[rand.int(names.length)]);
			d.set("age", rand.int(100));
			d.id = Std.string(idx++);
			db.save(d);
		}

		for(i in 0...10) {
			insert();
		}
	}

	function viewTest() {
		var db = getDb("mytestdb2");
		if(db == null) {
			throw "exit";
		}
		var result : Result = db.getAll();
		//trace(result.getView());
		var rows = result.getRows();

		for (d in rows) {
			//println(d.getId() + " " + d.get("age"));
			d.reload();
			println(d.getId() + " " + d.getInt("age"));
		}

		println("---- filtered ----");

		result = db.query(
			"function(doc) { emit(doc._id, doc.age); }"
			//, //// reduce functions /////
			//"function(keys, values){return sum(values);};"
		);

		/*
		reduce : function(keys, values){ return sum(values);   }
		*/


		//result = db.query("function (doc) { map(null, age: doc.age); }");
		for(d in result.getRows()) {
			//d.reload();
			//println(d.getId() + " " + d.data.getInt("age"));
			println(d.getId() + " " + d.getValue());
		}

		for(r in result.getStrings()) {
			println(r);
		}

	}

	function storedViewsTest() {
		println("============= storedViewsTest ================");
		var db = getDb("mytestdb2");
			if(db == null) throw "failed";
		var dd : DesignDocument;
		var dv : DesignView;

		dd = db.openDesignDocument("test");
		if(dd == null) {
			dd = new DesignDocument("test");
			var v = new View("function(doc) { emit(doc._id, doc.age); }");
			dv = v.toDesignView("all_ages", dd);
			//trace(dv.getPathEncoded());
			//trace(dd.getId());
			if(!db.save(dd)) {
				traceError("DesignDocument save result");
				throw "exit";
			}
		}
		else {
			dv = dd.getView("all_ages");
			dv.setMapFunction("function(doc) { emit(null, doc.age); }");
			dd.addView(dv);

		}

		var nv = new DesignView(
			"sum_ages",
			"function(doc) { emit(doc._id, doc.age); }",
			"function(keys, values) {return sum(values);};"
		);
		dd.addView(nv);
		db.save(dd);

		//trace(dv);
		//trace(dv.getPathEncoded());
		println("------ running all_ages view --------");
		var result = db.view(dv);
		for(r in result.getStrings()) {
			println(r);
		}
		println("---- end of results --------");

		println("------ running sum_ages view -------");
		var result = db.view(dd.getView("sum_ages"));
		println("The sum: " + result.getValue());
		for(r in result.getRows()) {
			println(r.value);
		}
		println("---- end of results --------");
		//trace(untyped result.outputRequest);
	}

	function compactTest() {
		println("============= Compact Test ================");
		var db = getDb("mytestdb2");
			if(db == null) throw "failed";
		if(!db.compact())
			throw "Compact failed";
	}

	function cleanup() {
		println("\n---- cleanup ----");
		var deletes = ["mytestdb", "mytestdb2"];
		for(n in deletes) {
			print("Removing " + n + "...");
			if(session.deleteDatabaseByName(n))
				println("removed.");
			else {
				if(session.getLastTransaction().getErrorId() == "not_found")
					println("not found.");
				else
					traceError();
			}
		}
	}

	function traceError(?msg:String) {
		if(msg == null) msg = "";
		else msg += " : ";

		var r = session.getLastTransaction();
		var em = r.getHttpError();
		if(em != "")
			println("HTTP:" + em);
			trace(r);
			println("COUCH ERROR: " + msg + r.getErrorId()  + " : " + r.getErrorReason() );

	}

	public static function main() {
		var c = new Couch();
	}
}
