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

import java.io.IOException;
import java.util.concurrent.atomic.AtomicInteger;
import java.io.EOFException;

/**
 *
 * @author Russell Weir
 */
public class Block {
	// data block entries
	final protected static int OFFSET_NEXT_BLOCK = 0;
	final protected static int OFFSET_LENGTH = 8;
	final protected static int OFFSET_DATA = 12;
	
	final private BlockFile file;
	final private int blocksize;
	final private AtomicInteger refCount;
	
	private long nextBlock;
	private int dataLen;
	
	private byte[] buf;
	private boolean dirty = false;
	private long offset;
	private int pos;
	
	public Block(BlockFile bf) {
		this.file = bf;
		this.blocksize = bf.getBlocksize();
		this.pos = 0;
		this.refCount = new AtomicInteger(0);
		this.buf = new byte[this.blocksize];
		this.nextBlock = 0;
	}
	
	public Block(BlockFile bf, long offset) {
		this(bf);		
		this.offset = offset;
	}
	
	/**
	 * Creates a Block setting the data section
	 * @param bf BlockFile
	 * @param offset Offset in BlockFile for this block
	 * @param src Source byte data
	 * @param srcPos Source byte data position
	 * @param len Source byte data length to copy
	 * @throws java.io.IOException
	 */
	public Block(BlockFile bf, long offset, byte[] src, int srcPos, int len) throws IOException {
		this(bf, offset);
		this.updateDataLength(OFFSET_DATA + len);
		System.arraycopy(src, srcPos, buf, OFFSET_DATA, len);
	}
	
	/**
	 * Clears all the user data from the block.
	 */
	protected void clear() {
		buf = new byte[blocksize];
		pos = 0;
		dataLen = 0;
		setDirty(true);
	}
	
	/**
	 * Copy the data portion of the block to the outbuf provided. Does not
	 * affect the internal position pointer.
	 * @param outbuf Destination buffer
	 * @param offset destination buffer offset
	 * @return length of data copied
	 */
	protected final int copyData(byte[] outbuf, int offset) {
		System.arraycopy(buf, OFFSET_DATA, outbuf, offset, this.dataLen);
        return dataLen;
	}
		
	protected int decRefCount() {
		return refCount.decrementAndGet();
	}

	protected void flush() throws IOException {
		if(offset <= 0)
			throw new RuntimeException("Offset not set.");
		if(dirty) {
			file.writeRaw(offset, buf);
			dirty = false;
		}
	}
	
	/**
	 * Clears all the data from the block and returns the old data.  The 
	 * returned data includes the OFFSET_DATA bytes of header data, so to create a 
	 * new block from it make sure to use OFFSET_DATA as a src position
	 * @return Previous data byte array.
	 */
	protected byte[] getBufAndClear() {
		byte[] rv = buf;
		clear();
		return rv;
	}
	
	protected int getDataLength() {
		return this.dataLen;
	}

	protected long getNextOffset() {
		return this.nextBlock;
	}
	
	protected long getOffset() {
		return this.offset;
	}
	
	protected int getRefCount() {
		return refCount.intValue();
	}
	
	protected void load() throws IOException {
		file.readRaw(offset, buf);
		this.nextBlock = this.readLong();
		this.dataLen = this.readInt();
		this.pos = 0;
	}
	
	protected int incRefCount() {
		return refCount.incrementAndGet();
	}
	
	protected void setDirty(boolean v) {
		dirty = v;
	}
	
	/**
	 * Chains the block b to the end of the current block. If b is null
	 * then this block is the last in a chain.
	 * @param b next Block
	 */
	protected void setNextBlock(Block b) {
		if(b == null) {
			this.nextBlock = 0;
		}
		else {
			this.nextBlock = b.getOffset();
		}
	}
	/**
	 * Set the offset in the BlockFile for this block
	 * @param off File offset
	 * @throws java.io.IOException if offset already set
	 */
	protected void setOffset(long off) throws IOException {
		if(this.offset != 0)
			throw new IOException();
		this.offset = off;
	}
	
	private void updateDataLength(int p) throws EOFException {
		if(p >= this.blocksize)
			throw new EOFException();
		p -= OFFSET_DATA;
		this.dataLen = Math.max(this.dataLen, p);
	}
	
	/////////// DATA ACCESS METHODS /////////////////////
	protected void seek(int newPos) throws IOException {
		if(newPos >= this.blocksize)
			throw new IOException();
		this.pos = newPos;
	}
	
	protected void seekDataStart() {
		this.pos = OFFSET_DATA;
	}
	
	protected final int read(byte[] outbuf, int offset, int len) {
		if(pos + len > this.blocksize)
			len = this.blocksize - this.pos;
		System.arraycopy(buf, pos, outbuf, offset, len);
		pos += len;
        return len;
	}
	
	protected final int write(byte[] inbuf, int offset, int len) throws IOException {
		if(len + pos > this.blocksize)
			throw new IOException();
		updateDataLength(pos + len);
		System.arraycopy(inbuf, offset, buf, pos, len);
		pos += len;
		setDirty(true);
		return len;
	}
	
	protected final byte readByte() {
		return buf[pos++];
	}

	protected final void writeByte(byte v) throws IOException {
		updateDataLength(pos + 1);
		buf[pos++] = v;
		setDirty(true);
	}
	
	protected final int readInt() {
		return
			((buf[pos++] & 0xff) << 24) +
			((buf[pos++] & 0xff) << 16) +
			((buf[pos++] & 0xff) << 8) +
			(buf[pos++] & 0xff);
	}
		
	protected final void writeInt(int v) throws IOException {
		updateDataLength(pos + 4);
		buf[pos++] = (byte)(0xff & (v >> 24));
		buf[pos++] = (byte)(0xff & (v >> 16));
		buf[pos++] = (byte)(0xff & (v >>    8));
		buf[pos++] = (byte)(0xff & v);
		setDirty(true);
	}
	
	protected final long readLong() {
		return
			(((long)(buf[pos++] & 0xff) << 56) |
			((long)(buf[pos++] & 0xff) << 48) |
			((long)(buf[pos++] & 0xff) << 40) |
			((long)(buf[pos++] & 0xff) << 32) |
			((long)(buf[pos++] & 0xff) << 24) |
			((long)(buf[pos++] & 0xff) << 16) |
			((long)(buf[pos++] & 0xff) <<  8) |
			((long)(buf[pos++] & 0xff)));
	}
	
	protected final void writeLong(long v) throws IOException {
		updateDataLength(pos + 8);
		buf[pos++] = (byte)(0xff & (v >> 56));
		buf[pos++] = (byte)(0xff & (v >> 48));
		buf[pos++] = (byte)(0xff & (v >> 40));
		buf[pos++] = (byte)(0xff & (v >> 32));
		buf[pos++] = (byte)(0xff & (v >> 24));
		buf[pos++] = (byte)(0xff & (v >> 16));
		buf[pos++] = (byte)(0xff & (v >>  8));
		buf[pos++] = (byte)(0xff & v);
		setDirty(true);
	}
}
