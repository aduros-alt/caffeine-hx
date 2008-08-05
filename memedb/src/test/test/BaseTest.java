package test;

import org.junit.AfterClass;
import org.junit.BeforeClass;

import memedb.MemeDB;
import memedb.backend.Backend;
import memedb.backend.BackendException;
import memedb.backend.FileSystemBackend;
import memedb.views.ViewException;

public class BaseTest {
	static protected MemeDB db;
	static protected Backend backend;
	
	@BeforeClass 
	static public void setup(){
		backend = new FileSystemBackend();
		db = new MemeDB(backend);
		db.init();
		if (!backend.doesDatabaseExist("foodb")) {
			try {
				db.addDatabase("foodb");
			} catch (BackendException e) {
				e.printStackTrace();
			} catch (ViewException e) {
				e.printStackTrace();
			}
		}

	}
	@AfterClass
	static public void destroy() {
		if (db!=null) {
			db.shutdown();
//			try {
//				backend.deleteDatabase("foodb");
//			} catch (BackendException e) {
//				e.printStackTrace();
//			}
		}
	}
}
