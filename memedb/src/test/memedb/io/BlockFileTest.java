/*
 * To change this template, choose Tools | Templates
 * and open the template in the editor.
 */

package memedb.io;

import java.io.File;
import org.junit.After;
import org.junit.AfterClass;
import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Test;
import static org.junit.Assert.*;

/**
 *
 * @author damon
 */
public class BlockFileTest {
	BlockFile instance;
	File file;
	static int BLOCKSIZE=128;
	
    public BlockFileTest() {
    }

	@BeforeClass
	public static void setUpClass() throws Exception {
	}

	@AfterClass
	public static void tearDownClass() throws Exception {
	}

	// runs before every test case
    @Before
    public void setUp() {
		try {
			file = new File("test.bf");
			instance = new BlockFile(file, BLOCKSIZE);
		} catch(Exception e) {
			throw new RuntimeException(e);
		}
    }

	// runs after every test case
    @After
    public void tearDown() {
		file.delete();
    }

	/**
	 * Test of allocBlock method, of class BlockFile.
	 */
	@Test
	public void testAllocBlock() throws Exception {
		System.out.println("allocBlock");
		Block result = instance.allocBlock();
		assertEquals((long)(3 * BLOCKSIZE), file.length());
		assertNotNull(result);
	}

	/**
	 * Test of chainBlocks method, of class BlockFile.
	 */
	@Test
	public void testChainBlocks() {
		System.out.println("chainBlocks");
		Block[] ba = null;
		instance.chainBlocks(ba);
		// TODO review the generated test code and remove the default call to fail.
		fail("The test case is a prototype.");
	}

	/**
	 * Test of close method, of class BlockFile.
	 */
	@Test
	public void testClose() throws Exception {
		System.out.println("close");
		instance.close();
		// TODO review the generated test code and remove the default call to fail.
		fail("The test case is a prototype.");
	}

	/**
	 * Test of flushBlocks method, of class BlockFile.
	 */
	@Test
	public void testFlushBlocks() throws Exception {
		System.out.println("flushBlocks");
		Block[] ba = null;
		instance.flushBlocks(ba);
		// TODO review the generated test code and remove the default call to fail.
		fail("The test case is a prototype.");
	}

	/**
	 * Test of freeBlock method, of class BlockFile.
	 */
	@Test
	public void testFreeBlock() throws Exception {
		System.out.println("freeBlock");
		Block b = null;
		instance.freeBlock(b);
		// TODO review the generated test code and remove the default call to fail.
		fail("The test case is a prototype.");
	}

	/**
	 * Test of getFreeBlocks method, of class BlockFile.
	 */
	@Test
	public void testGetFreeBlocks() throws Exception {
		System.out.println("getFreeBlocks");
		int count = 0;
		Block[] expResult = null;
		Block[] result = instance.getFreeBlocks(count);
		assertEquals(expResult, result);
		// TODO review the generated test code and remove the default call to fail.
		fail("The test case is a prototype.");
	}

	/**
	 * Test of getBlock method, of class BlockFile.
	 */
	@Test
	public void testGetBlock() throws Exception {
		System.out.println("getBlock");
		long offset = 0L;
		Block expResult = null;
		Block result = instance.getBlock(offset);
		assertEquals(expResult, result);
		// TODO review the generated test code and remove the default call to fail.
		fail("The test case is a prototype.");
	}

	/**
	 * Test of getBlocks method, of class BlockFile.
	 */
	@Test
	public void testGetBlocks() throws Exception {
		System.out.println("getBlocks");
		long offset = 0L;
		Block[] expResult = null;
		Block[] result = instance.getBlocks(offset);
		assertEquals(expResult, result);
		// TODO review the generated test code and remove the default call to fail.
		fail("The test case is a prototype.");
	}

	/**
	 * Test of getBlocksize method, of class BlockFile.
	 */
	@Test
	public void testGetBlocksize() {
		System.out.println("getBlocksize");
		int expResult = 0;
		int result = instance.getBlocksize();
		assertEquals(expResult, result);
		// TODO review the generated test code and remove the default call to fail.
		fail("The test case is a prototype.");
	}

	/**
	 * Test of getLock method, of class BlockFile.
	 */
	@Test
	public void testGetLock() {
		System.out.println("getLock");
		Object expResult = null;
		Object result = instance.getLock();
		assertEquals(expResult, result);
		// TODO review the generated test code and remove the default call to fail.
		fail("The test case is a prototype.");
	}

	/**
	 * Test of getUserPointer and setUserPointer methods, of class BlockFile.
	 */
	@Test
	public void testUserPointer() throws Exception {
		System.out.println("userPointer");
		long expResult = 384L;
		instance.setUserPointer(expResult);
		long result = instance.getUserPointer();
		assertEquals(expResult, result);
	}

	/**
	 * Test of read method, of class BlockFile.
	 */
	@Test
	public void testRead() throws Exception {
		System.out.println("read");
		long fileOffset = 0L;
		byte[] expResult = null;
		byte[] result = instance.read(fileOffset);
		assertEquals(expResult, result);
		// TODO review the generated test code and remove the default call to fail.
		fail("The test case is a prototype.");
	}

	/**
	 * Test of readRaw method, of class BlockFile.
	 */
	@Test
	public void testReadRaw() throws Exception {
		System.out.println("readRaw");
		long fileOffset = 0L;
		byte[] dst = null;
		instance.readRaw(fileOffset, dst);
		// TODO review the generated test code and remove the default call to fail.
		fail("The test case is a prototype.");
	}

	/**
	 * Test of reallocBlocks method, of class BlockFile.
	 */
	@Test
	public void testReallocBlocks() throws Exception {
		System.out.println("reallocBlocks");
		long fileOffset = 0L;
		int count = 0;
		Block[] expResult = null;
		Block[] result = instance.reallocBlocks(fileOffset, count);
		assertEquals(expResult, result);
		// TODO review the generated test code and remove the default call to fail.
		fail("The test case is a prototype.");
	}

	/**
	 * Test of write method, of class BlockFile.
	 */
	@Test
	public void testWrite_3args() throws Exception {
		System.out.println("write");
		byte[] src = null;
		int srcPos = 0;
		int len = 0;
		long expResult = 0L;
		long result = instance.write(src, srcPos, len);
		assertEquals(expResult, result);
		// TODO review the generated test code and remove the default call to fail.
		fail("The test case is a prototype.");
	}

	/**
	 * Test of write method, of class BlockFile.
	 */
	@Test
	public void testWrite_4args() throws Exception {
		System.out.println("write");
		long fileOffset = 0L;
		byte[] src = null;
		int srcPos = 0;
		int len = 0;
		long expResult = 0L;
		long result = instance.write(fileOffset, src, srcPos, len);
		assertEquals(expResult, result);
		// TODO review the generated test code and remove the default call to fail.
		fail("The test case is a prototype.");
	}

	/**
	 * Test of writeRaw method, of class BlockFile.
	 */
	@Test
	public void testWriteRaw() throws Exception {
		System.out.println("writeRaw");
		long fileOffset = 0L;
		byte[] src = null;
		instance.writeRaw(fileOffset, src);
		// TODO review the generated test code and remove the default call to fail.
		fail("The test case is a prototype.");
	}

}