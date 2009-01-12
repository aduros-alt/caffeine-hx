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

/**
 *
 * @author Russell Weir
 */
public class FreeBlockIndex {
		final private BlockFile file;
		final private int blocksize;
		private long[] freeBlocks; // array of file offsets
		private long nextOffset; // next block in chain
		private int length;
		private long offset;
		
		FreeBlockIndex(BlockFile file, long blockOffset) throws IOException {
			this.file = file;
			this.offset = blockOffset;
			this.blocksize = file.getBlocksize();
			Block b = file.getBlock(offset);
			nextOffset = b.readLong();
			length = (int)(b.readInt() / 4);
			freeBlocks = new long[length];
			for(int x = 0; x < length; x++) {
				freeBlocks[x] = b.readInt();
			}
		}
		
		/**
		 * Adds an entry indicating the block at offset has been freed.
		 * @param blockOffset file offset where block is being freed
		 */
		protected synchronized void freeBlockAtOffset(long blockOffset) throws IOException {
			if(this.isFull())
				throw new RuntimeException("Length of index exceeded. Check isFull() first.");
			if(blockOffset == 0)
				throw new RuntimeException("Attempted to free block 0");
			if(blockOffset == this.blocksize)
				throw new RuntimeException("Attempted to free block 1");
			long[] bfa = new long[length + 1];
			if(length > 0)
				System.arraycopy(freeBlocks, 0, bfa, 0, length);
			bfa[length] = blockOffset;
			length++;
			freeBlocks = bfa;
			byte[] bytes = new byte[12];
			for(int x = 0; x < 12; x++)
				bytes[x] = 0;
			file.writeRaw(offset, bytes);
		}
		
		/**
		 * Pops the last free block offset off the stack 
		 * @return File offset
		 * @throws java.io.IOException when there are no free blocks left
		 * in this index page
		 * @see getNextIndex()
		 */
		protected synchronized long getFreeBlockOffset() throws IOException {
			if(length == 0)
				throw new IOException();
			long rv = freeBlocks[length];
			length--;
			return rv;
		}
		
		/**
		 * Get offset in file to next FreeBlockListEntry. Throws
		 * IOException if there are no more.
		 * @return next FreeBlockIndex or null
		 */
		protected FreeBlockIndex getNextIndex() throws IOException {
			if(nextOffset == 0)
				return null;
			return new FreeBlockIndex(file, nextOffset);
		}
		
		protected long getOffset() {
			return this.offset;
		}
		
		protected synchronized boolean isFull() {
			if(((int) ((blocksize - 12) / 8)) - length > 0) 
				return false;
			return true;
		}
		
		protected int size() {
			return length;
		}
		
		/**
		 * Creates a new FreeBlockIndex chained to the previous one.
		 * @param lastOffset previous (full) FreeBlockIndex offset
		 * @param file the Blockfile
		 * @param fileOffset new offset
		 * @return New FreeBlockIndex
		 */
		protected static FreeBlockIndex create(long lastOffset, BlockFile file, long fileOffset) throws IOException
		{
			/* non-destructive
			byte[] buf = new byte[12];
			int pos = 0;
			buf[pos++] = (byte)(0xff & (lastOffset >> 56));
			buf[pos++] = (byte)(0xff & (lastOffset >> 48));
			buf[pos++] = (byte)(0xff & (lastOffset >> 40));
			buf[pos++] = (byte)(0xff & (lastOffset >> 32));
			buf[pos++] = (byte)(0xff & (lastOffset >> 24));
			buf[pos++] = (byte)(0xff & (lastOffset >> 16));
			buf[pos++] = (byte)(0xff & (lastOffset >>  8));
			buf[pos++] = (byte)(0xff & lastOffset);	
			for(int x = 0; x < 4; x++)
				buf[pos++] = 0;
			file.writeRaw(fileOffset, buf);
			 */
			Block b = file.getBlock(fileOffset);
			b.seek(0);
			b.writeLong(lastOffset);
			b.writeInt(0);
			b.flush();
			file.updateLastBlockIndex(fileOffset);
			return new FreeBlockIndex(file, fileOffset);
		}
}
