/*
* Copyright 2008 The MemeDB Contributors (see CONTRIBUTORS)
* Licensed under the Apache License, Version 2.0 (the "License"); you may not
* use this file except in compliance with the License.  You may obtain a copy of
* the License at
*
*   http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
* WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
* License for the specific language governing permissions and limitations under
* the License.
*/

package memedb.io;

import java.io.File;
import java.io.IOException;
import java.io.ObjectOutputStream;
import java.io.RandomAccessFile;
import java.io.StreamCorruptedException;
import java.io.UnsupportedEncodingException;
import java.util.ArrayList;
import org.mortbay.jetty.EofException;

/**
 * A filesystem like random access file with configurable block sizes from 
 * a minimum of 64 bytes. 
 * @author Russell Weir
 */
public class BlockFile {

	private RandomAccessFile file;
	final protected int dataBytesPerBlock;
	final private boolean readOnly;
	private Object lock = new Object();

	// root block
	private int magic = 0xC0FFEE;
	private int major = 1;
	private int minor = 0;
	private int blocksize;
	private long lastBlock = 0;
	private long freeBlockIndexOffset;
	private long userPointer = 0;
		
	// root block entries
	final private static int OFFSET_MAGIC = 0;
	final private static int OFFSET_MAJOR = 4;
	final private static int OFFSET_MINOR = 5;
	final private static int OFFSET_BLOCKSIZE = 6;
	final private static int OFFSET_LASTBLOCK = 10;
	final private static int OFFSET_FREEBLOCKS = 18;
	final private static int OFFSET_USERPTR = 24;
	
	private FreeBlockIndex freeBlockIndex;
	
	/**
	 * Opens an existing BlockFile with read or read/write mode
	 * @param path Path to file
	 * @param "r" for read-only, "rw" or "w" for read/write
	 * @throws java.io.UnsupportedEncodingException
	 * @throws java.io.StreamCorruptedException
	 * @throws java.io.IOException
	 */
	public BlockFile(File path, String mode) 
			throws UnsupportedEncodingException, StreamCorruptedException, IOException
	{
		this.readOnly = mode.equalsIgnoreCase("r");
		initialize(path);
		this.dataBytesPerBlock = blocksize - Block.OFFSET_DATA;
	}
	
	/**
	 * Creates a new BlockFile. If an existing file exists, it will be 
	 * opened in read/write mode and the blocksize checked.
	 * @param path Path to file
	 * @param blocksize Bytes per block
	 * @throws java.io.UnsupportedEncodingException
	 * @throws java.io.StreamCorruptedException
	 * @throws java.io.IOException
	 */
	public BlockFile(File path, int blocksize) 
			throws UnsupportedEncodingException, StreamCorruptedException, IOException
	{
		if(blocksize < 64) {
			throw new UnsupportedEncodingException("Blocksize must be >= 64 bytes");
		}
		this.blocksize = blocksize;
		this.readOnly = false;
		if(!path.exists()) {
			file = new RandomAccessFile(path, "rws");
			file.setLength(blocksize * 2);
			// init free block index
			freeBlockIndex = FreeBlockIndex.create(0, this, this.blocksize);
			this.updateLastBlock(blocksize * 2);
			this.writeRootBlock();
			file.close();
		}
		initialize(path);
		if(this.blocksize != blocksize) {
			throw new StreamCorruptedException("Provided blocksize does not match existing file");
		}
		this.dataBytesPerBlock = blocksize - Block.OFFSET_DATA;
	}
	
	private void initialize(File path) throws IOException {
		if(readOnly)
			file = new RandomAccessFile(path, "r");
		else
			file = new RandomAccessFile(path, "rw");
		readRootBlock();
		if(magic != 0xC0FFEE)
			throw new UnsupportedEncodingException("Bad magic number");

		if(lastBlock + blocksize != file.length()) 
			throw new StreamCorruptedException();
		freeBlockIndex = new FreeBlockIndex(this, freeBlockIndexOffset);
		if(blocksize < 64)
			throw new UnsupportedEncodingException("Blocksize must be >= 64 bytes");
	}

	protected Block allocBlock() throws IOException {
		byte[] buf = new byte[12];
		for(int x = 0; x < 12; x++)
			buf[x] = 0;
		synchronized(lock) {
			long thisBlock = lastBlock + this.blocksize;
			this.writeRaw(thisBlock, buf);
			return new Block(this, thisBlock);
		}
	}
	
	/**
	 * Takes an array of ordered blocks and chains their pointers to the
	 * next in line, leaving the last block with a pointer of 0
	 * @param ba Array of aloocated or loaded blocks
	 */
	protected void chainBlocks(Block[] ba) {
		for(int x = 0; x < ba.length - 1; x++) {
			ba[x].setNextBlock(ba[x+1]);
		}
		ba[ba.length - 1].setNextBlock(null);
	}
	
	protected void flushBlocks(Block[] ba) throws IOException {
		synchronized(lock) {
			for(Block b: ba) {
				b.flush();
			}
		}
	}
	
	protected void freeBlock(Block b) throws IOException {
		b.clear();
		b.flush();
		synchronized(lock) {
			if(freeBlockIndex.isFull()) {
				Block newIndexBlock = allocBlock();
				freeBlockIndex = FreeBlockIndex.create(freeBlockIndex.getOffset(), this, newIndexBlock.getOffset());
			}
			freeBlockIndex.freeBlockAtOffset(b.getOffset());
		}
	}
	
	protected Block[] getFreeBlocks(int count) throws IOException {
		Block[] ba = new Block[count];
		for(int x = 0; x < count; x++) {
			Block b = null;
			try {
				long offset = freeBlockIndex.getFreeBlockOffset();
				b = new Block(this, offset);
			} catch(IOException e) {
				b = allocBlock();
			}
			ba[x] = b;
		}
		return ba;
	}
	
	protected Block getBlock(long offset) throws IOException {
		Block b = new Block(this, offset);
		b.load();
		return b;
	}
	
	protected Block[] getBlocks(long offset) throws IOException {
		long nextOffset = 0;
		ArrayList<Block> ba = new ArrayList<Block>();
		do {
			Block b = new Block(this, offset);
			b.load();
			nextOffset = b.getNextOffset();
			ba.add(b);
		} while(nextOffset != 0);
		return ba.toArray(new Block[ba.size()]);
	}
		
	protected int getBlocksize() {
		return blocksize;
	}
	
	/**
	 * Returns the user pointer data file offset. This is the file offset set
	 * by setUserPointer()
	 * @return long file offset
	 * @throws java.io.IOException on any IO error or pointer not initialized
	 * @see setUserPointer()
	 */
	public long getUserPointer() throws IOException {
		if(this.userPointer < 2 * this.blocksize)
			throw new IOException("Not initialized");
		return this.userPointer;
	}
	
	public byte[] read(long fileOffset) throws IOException {
		Block[] ba = getBlocks(fileOffset);
		int totalLen = 0;
		for(Block b: ba) {
			totalLen += b.getDataLength();
		}
		byte[] rv = new byte[totalLen];
		int pos = 0;
		for(Block b: ba) {
			int written = b.copyData(rv, pos);
			pos += written;
		}
		return rv;
	}
	
	protected void readRaw(long fileOffset, byte[] dst) throws IOException {
		if(dst.length != this.blocksize)
			throw new IOException("Buffer size mismatch");
		if(fileOffset % this.blocksize != 0)
			throw new IOException("Page alignment error");
		synchronized(lock) {
			file.seek(fileOffset);
			if(file.read(dst) < 0)
				throw new EofException();
		}
	}

	
	protected Block[] reallocBlocks(long fileOffset, int count) throws IOException {
		Block[] baTmp = getBlocks(fileOffset);
		Block[] ba = new Block[count];
		int toCopy = count;
		if(count < baTmp.length) {
			int start = baTmp.length - 1;
			int end = count - 1;
			while(start > end) {
				freeBlock(baTmp[start]);
				start--;
			}
		}
		else if(count > baTmp.length) {
			toCopy = baTmp.length;
		}
		System.arraycopy(baTmp, 0, ba, 0, toCopy);
		if(count > baTmp.length) {
			Block[] n = getFreeBlocks(count - baTmp.length);
			System.arraycopy(n, 0, ba, baTmp.length, n.length);
		}
		chainBlocks(ba);
		return ba;
	}
	
	/**
	 * Sets a root block entry in the file to an arbitrary long value. This
	 * is usually used to set the first data offset in the file, and must
	 * be >= 2 * blocksize to be valid.
	 * @param fileOffset long value
	 * @throws java.io.IOException
	 */
	public void setUserPointer(long fileOffset) throws IOException {
		synchronized(lock) {
			if(fileOffset != this.userPointer) {
				this.userPointer = fileOffset;
				file.seek(OFFSET_USERPTR);
				file.writeLong(fileOffset);
			}
		}
	}
		
	/**
	 * Updates the last allocated block pointer
	 * @param off File offset of last block
	 * @throws java.io.IOException
	 */
	private void updateLastBlock(long off) throws IOException {
		if(off > lastBlock) {
			lastBlock = off;
			synchronized(lock) {
				file.seek(OFFSET_LASTBLOCK);
				file.writeLong(off);
			}
		}
	}

	/**
	 * Write an arbitrary length byte buffer to the file, returning
	 * the file offset index.
	 * @param buf input byte buffer
	 * @return File offset where data is written
	 * @throws java.io.IOException
	 */
	public long write(byte[] src, int srcPos, int len) throws IOException {
		int blockCount = (int)Math.ceil(((double)src.length) / ((double)dataBytesPerBlock));
		Block[] ba = getFreeBlocks(blockCount);
		System.out.println("Bytes in buffer: "+ src.length + " blocks allocated : " + blockCount);
		this.writeToBlocks(ba, src, srcPos, len);
		flushBlocks(ba);
		return ba[0].getOffset();
	}
	
	/**
	 * Write a byte buffer to a specific file offset. If data already exists
	 * at the file offset, it is overwritten and blocks are either allocated
	 * or freed to match the length of the data written
	 * @param fileOffset multiple of blocksize
	 * @param src Input buffer
	 * @param srcPos Position in input buffer to start copy
	 * @param len Number of bytes to copy to file
	 * @return File offset
	 * @throws java.io.IOException
	 */
	public long write(long fileOffset, byte[] src, int srcPos, int len) throws IOException {
		if(fileOffset % this.blocksize != 0) {
			throw new IOException("Invalid file offset");
		}
		int blockCount = (int)Math.ceil(((double)src.length) / ((double)dataBytesPerBlock));
		Block[] ba = reallocBlocks(fileOffset, blockCount);
		System.out.println("Bytes in buffer: "+ src.length + " blocks allocated : " + blockCount);
		this.writeToBlocks(ba, src, srcPos, len);
		flushBlocks(ba);
		return ba[0].getOffset();
	}
	
	private void writeToBlocks(Block[] ba, byte[] src, int srcPos, int len) throws IOException {
		int i = 0;
		do {
			Block b = ba[i];
			b.seekDataStart();
			int count = len;
			if(count > this.dataBytesPerBlock)
				count = this.dataBytesPerBlock;
			b.write(src, srcPos, count);
			srcPos += count;
			len -= count;
			i++;
		} while(len > 0);
	}
		
	protected void writeRaw(long fileOffset, byte[] src) throws IOException {
		if(src.length > this.blocksize)
			throw new IOException("Buffer size mismatch");
		if(fileOffset % this.blocksize != 0)
			throw new IOException("Page alignment error");
		synchronized(lock) {
			if(fileOffset + this.blocksize > file.length())
				file.setLength(fileOffset + this.blocksize);
			updateLastBlock(fileOffset);
			file.seek(fileOffset);
			file.write(src);
		}
	}
	
	//////////// root block ///////////////////
	protected void readRootBlock() throws IOException {
		Block b = getBlock(0);
		b.seek(0);
		magic = b.readInt();
		major = b.readByte();
		minor = b.readByte();
		blocksize = b.readInt();
		lastBlock	= b.readLong();
		freeBlockIndexOffset = b.readLong();
		userPointer = b.readLong();
	}

	private void writeRootBlock() throws IOException {
		synchronized(lock) {
			file.seek(0);
			file.writeInt(magic);
			file.writeByte(major);
			file.writeByte(minor);
			file.writeInt(blocksize);
			file.writeLong(lastBlock);
			file.writeLong(freeBlockIndexOffset);
			file.writeLong(userPointer);
		}
	}
}
