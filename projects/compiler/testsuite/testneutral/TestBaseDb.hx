package testneutral;

import unit.Assert;

import neutral.db.Connection;

class TestBaseDb {
	var dbtype : String;
	public function new() { }
	
	function getConnection() : Connection {
		return throw "Abstract method";
	}
	
	function createSql() {
		return "CREATE TABLE Persons (id INTEGER PRIMARY KEY, name VARCHAR(255));";
	}
	
	function dropSql() {
		return "DROP TABLE Persons;";
	}
	
	function insertSql(name : String) {
		return "INSERT INTO Persons VALUES(NULL, '" + db.escape(name) + "');";
	}
	
	function selectSql() {
		return "SELECT * FROM Persons";
	}
	
	function selectCountSql() {
		return "SELECT COUNT(*) FROM Persons";
	}
	
	var db : Connection;
	public function setup() {
		db = getConnection();
		if(db == null)
			throw "DB Connection Failed";
		db.request(createSql());
	}
	
	public function teardown() {
		if(db != null) {
			db.request(dropSql());
			db.close();			
		}
	}
	
	public function testOpen() {
		Assert.equals(dbtype, db.dbName());
	}
	
	public function testInsertSelect() {
		var comp = ["haXe", "Neko"];
		
		var lastid = db.lastInsertId();		
		for(n in comp) {
			db.request(insertSql(n));
			Assert.equals(lastid+1, db.lastInsertId());
			lastid = db.lastInsertId();
		}
		
		var rs = db.request(selectCountSql());
		Assert.equals(2, rs.getIntResult(0));
		
		rs = db.request(selectSql());
		Assert.equals(2, rs.length);
			
		var i = 0;
		while(rs.hasNext()) {
			var o = rs.next();
			Assert.isTrue(Std.int(o.id) > 0);			
			Assert.equals(comp[i], o.name);
			i++;
		}
	}
	
	public function testTransaction() {
		var comp = ["haXe", "Neko"];
		
		try {
			db.startTransaction();
			for(n in comp)
				db.request(insertSql(n));
			db.commit();
		} catch(e : Dynamic) {
			db.rollback();
		}
		var rs = db.request(selectCountSql());
		Assert.equals(2, rs.getIntResult(0));	
	}
	
	public function testRollback() {
		var comp = ["haXe", "Neko"];
		
		try {
			db.startTransaction();
			for(n in comp)
				db.request(insertSql(n));
			throw "Problem";
			db.commit();
		} catch(e : Dynamic) {
			db.rollback();
		}
		var rs = db.request(selectCountSql());
		Assert.equals(0, rs.getIntResult(0));	
	}
}