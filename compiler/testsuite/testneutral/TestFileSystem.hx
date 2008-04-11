package testneutral;

import unit.Assert;

import neutral.FileSystem;

class TestFileSystem {
	var base : String;
	var testdir : String;
	public function new() {
		base = neutral.Sys.getCwd().substr(0, -1);
		testdir = base + #if neko "/testdirneko" #else true "/testdirphp" #end;
	}
	
	public function testExists() {
		Assert.isTrue(FileSystem.exists(base));
		Assert.isFalse(FileSystem.exists(base+"/unexistent"));
	}

	public function testCreateRenameDelete() {
		var t1 = testdir + "/temp1";
		var t2 = testdir + "/temp";
		try {
			FileSystem.createDirectory(testdir);
			Assert.isTrue(FileSystem.exists(testdir));
			FileSystem.createDirectory(t1);
			Assert.isTrue(FileSystem.exists(t1));
			FileSystem.rename(t1, t2);
			Assert.isFalse(FileSystem.exists(t1));
			Assert.isTrue(FileSystem.exists(t2));
			Assert.isTrue(FileSystem.isDirectory(t2));
			FileSystem.deleteDirectory(t2);
			Assert.isFalse(FileSystem.exists(t2));
		} catch(e : Dynamic) {
			Assert.fail();
		}
		if(FileSystem.exists(t1))
			FileSystem.deleteDirectory(t1);
		if(FileSystem.exists(t2))
			FileSystem.deleteDirectory(t2);
		if(FileSystem.exists(testdir))
			FileSystem.deleteDirectory(testdir);
	}

	public function testStat() {

	}

	public function testFullPath() {

	}

	public function testKind() {
	}


	public function testDeleteFile() {
		
	}

	public function testReadDirectory() {

	}
}