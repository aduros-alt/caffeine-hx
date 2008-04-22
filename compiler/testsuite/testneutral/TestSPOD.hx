package testneutral;

import unit.Assert;

import neutral.db.Connection;
import neutral.db.Mysql;
import neutral.db.Manager;

class TestSPOD {
	public function new() { }
	
	function createSql() {
		return "CREATE TABLE User (
    id INT NOT NULL auto_increment,
    name VARCHAR(32) NOT NULL,
    age INT NOT NULL,
	parentId INT NULL,
    PRIMARY KEY (id),
	FOREIGN KEY (parentId) REFERENCES User(id) ON DELETE SET NULL
) ENGINE=InnoDB";
	}
	
	public function setup() {
		Manager.cnx = Mysql.connect({
			host     : "localhost",
			port     : null,
			user     : "root",
			pass     : "",
			socket   : null,
			database : "test"
		});
		if(Manager.cnx == null)
			throw "DB Connection Failed";
		Manager.initialize();
		Manager.cnx.request(createSql());
	}
	
	function dropSql() {
		return "DROP TABLE IF EXISTS User;";
	}
	
	public function teardown() {
		if(Manager.cnx != null) {
			Manager.cnx.request(dropSql());
			Manager.cleanup();
			Manager.cnx.close();
		}
	}
	
	private function createSampleUser() {
		var user = new User();
		user.id   = 1;
		user.name = "haXe";
		user.age  = 3;
		return user;
	}
	
	public function testUse() {
		Assert.equals(0, User.manager.count());
		var user = createSampleUser();
		user.insert();
		Assert.equals(1, User.manager.count());
		user = User.manager.get(1);
		Assert.equals(1, user.id);
		Assert.equals("haXe", user.name);
		Assert.equals(3, user.age);
		user.age++;
		user.update();
		user = User.manager.get(1);
		Assert.equals(4, user.age);
		user.delete();
		Assert.equals(0, User.manager.count());
	}
	
	public function testCache() {
		var user = createSampleUser();
		user.insert();
		user = User.manager.get(1);
		Assert.equals(1, user.id);
		Manager.cnx.request(dropSql());
		user = User.manager.get(1);
		Assert.equals(1, user.id);
	}
	
	public function testRelations() {
		var user = createSampleUser();
		user.insert();
		
		var other = new User();
		other.name = "Neko";
		other.insert();
		other.parent = user;
		other.update();
		Assert.equals("haXe", other.parent.name);
	}
	
}

class User extends neutral.db.Object {
    public var id : Int;
    public var name : String;
    public var age : Int;
	private var parentId : Int;
	
	// REMOVE ME
	private var __parent : Int;
	
	
    public var parent(dynamic,dynamic) : User;
	/*
	public var getdynamic(dynamic,null) : User;
	public var setdynamic(default,dynamic) : User;
    
	static public var staticparent(dynamic,dynamic) : User;
	static public var staticgetdynamic(dynamic,null) : User;
	static public var staticsetdynamic(default,dynamic) : User;
	*/
	static function RELATIONS() {
		return [{ key : "parentId", prop : "parent", manager : User.manager }];
	}
	
    public static var manager = new neutral.db.Manager<User>(User);
}