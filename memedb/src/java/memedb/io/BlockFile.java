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
 *
 * @author Russell Weir
 */
public class BlockFile {

	final private RandomAccessFile file;
	final protected int dataBytesPerBlock;
		

	
	private boolean readOnly;
	private ObjectOutputStream oos;
	private Object lock = new Object();

	// root block
	private int magic = 0xC0FFEE;
	private int major = 1;
	private int minor = 0;
	private int blocksize;
	private long lastBlock = 0;
	private long freeBlockList;
		
	// root block entries
	final private static int OFFSET_MAGIC = 0;
	final private static int OFFSET_MAJOR = 4;
	final private static int OFFSET_MINOR = 5;
	final private static int OFFSET_BLOCKSIZE = 6;
	final private static int OFFSET_LASTBLOCK = 10;
	final private static int OFFSET_FREEBLOCKS = 18;
	
	private FreeBlockIndex freeBlockIndex;
	
	public BlockFile(File path, String mode, int blocksize, boolean createIfAbsent) 
			throws UnsupportedEncodingException, StreamCorruptedException, IOException
	{
		this.blocksize = blocksize;
		this.readOnly = mode.equalsIgnoreCase("r");
		this.dataBytesPerBlock = blocksize - Block.OFFSET_DATA;
		if(!path.exists()) {
			if(readOnly || !createIfAbsent)
				throw new IOException();
			file = new RandomAccessFile(path, "rws");
			file.setLength(blocksize * 2);
			// init free block index
			freeBlockIndex = FreeBlockIndex.create(0, this, this.blocksize);
			this.updateLastBlock(blocksize * 2);
			this.writeRootBlock();
		}
		else {
			if(readOnly)
				file = new RandomAccessFile(path, "r");
			else
				file = new RandomAccessFile(path, "rw");
		}
		
		readRootBlock();
		if(magic != 0xC0FFEE)
			throw new UnsupportedEncodingException();

		if(lastBlock + blocksize != file.length()) 
			throw new StreamCorruptedException();

		if(freeBlockIndex == null)
			freeBlockIndex = new FreeBlockIndex(this, this.blocksize);
		//this.oos = new ObjectOutputStream(s);
		
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
		
	private void updateLastBlock(long off) throws IOException {
		if(off > lastBlock) {
			lastBlock = off;
			file.seek(OFFSET_LASTBLOCK);
			file.writeLong(off);
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
	
	public long write(long fileOffset, byte[] src, int srcPos, int len) throws IOException {
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
		freeBlockList = b.readLong();
	}

	private void writeRootBlock() throws IOException {
		file.seek(0);
		file.writeInt(magic);
		file.writeByte(major);
		file.writeByte(minor);
		file.writeInt(blocksize);
		file.writeLong(lastBlock);
		file.writeLong(freeBlockList);
	}
}
