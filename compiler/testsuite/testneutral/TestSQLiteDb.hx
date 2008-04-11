package testneutral;

import unit.Assert;

import neutral.db.Connection;
import neutral.db.Sqlite;

class TestSQLiteDb extends TestBaseDb {
	public function new() {
		super();
		dbtype = "SQLite";
	}
	
	static var sqlitefile = neutral.Sys.getCwd() + #if php "test.php.db" #else neko "test.neko.db" #end;
	
	override function getConnection() : Connection {
		return Sqlite.open(sqlitefile);
	}
	
	override public function teardown() {
		super.teardown();
		if(neutral.FileSystem.exists(sqlitefile))
			neutral.FileSystem.deleteFile(sqlitefile);
	}
}