package testneutral;

import unit.Assert;

import neutral.db.Connection;
import neutral.db.Mysql;

class TestMysqlDb extends TestBaseDb {
	public function new() {
		super();
		dbtype = "MySQL";
	}
	
	override function getConnection() : Connection {
		return Mysql.connect({
			host     : "localhost",
			port     : null,
			user     : "root",
			pass     : "",
			socket   : null,
			database : "test"
		});
	}
	
	override function createSql() {
		return "CREATE TABLE Persons (id INTEGER PRIMARY KEY AUTO_INCREMENT, name VARCHAR(255)) ENGINE=InnoDB;";
	}
}