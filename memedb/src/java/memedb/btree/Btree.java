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

package memedb.btree;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.io.StreamCorruptedException;
import java.io.UnsupportedEncodingException;

import java.util.Comparator;
import memedb.io.BlockFile;

/**
 *
 * @author Russell Weir
 */
public class Btree {
	private long rootBlock;
	private Bnode root;
	final private Object lock;
	final private BlockFile file;
	final private Comparator cmp;
	
	public Btree(File path, String mode, Comparator cmp) 
			throws UnsupportedEncodingException, StreamCorruptedException, IOException, ClassNotFoundException
	{
		this.file = new BlockFile(path, mode);
		this.lock = this.file.getLock();
		this.cmp = cmp;
		this.rootBlock = file.getUserPointer();
		this.root = loadNode(rootBlock);
	}
	
	public void close() throws IOException {
		file.close();
	}
	
	public boolean delete(Object key) throws IOException {
		return true;
	}
	
	public Object get(Object key) throws IOException, ClassNotFoundException {
		byte[] data = root.get(key);
		ByteArrayInputStream bis = new ByteArrayInputStream(data);
		ObjectInputStream in = new ObjectInputStream(bis);
		return in.readObject();
	}
	
	protected Bnode loadNode(long fileOffset) throws IOException, ClassNotFoundException {
		byte[] data = file.read(fileOffset);
		ByteArrayInputStream bis = new ByteArrayInputStream(data);
		ObjectInputStream in = new ObjectInputStream(bis);
		return (Bnode)in.readObject();
	}
		
	protected Comparator getComparator() {
		return this.cmp;
	}
	
	final public boolean set(Object key, Object value) 
			throws IOException
	{
		ByteArrayOutputStream bos = new ByteArrayOutputStream();
		ObjectOutputStream oos = new ObjectOutputStream(bos);
		oos.writeObject(value);
		byte[] ba = bos.toByteArray();
		return set(key, ba, 0, ba.length);
	}
	
	final private boolean set(Object key, byte[] data, int dataOffset, int dataLen) 
			throws IOException
	{
		boolean rv = root.set(key, data, dataOffset, dataLen);
		return rv;
	}
	
	/**
	 * Creates a new Btree at path, returning a read/write instance
	 * @param path File name
	 * @param blocksize Bytes per each data block >= 64
	 * @return new writable Btree
	 */
	public static Btree create(File path, int blocksize, Comparator cmp) 
			throws IOException, ClassNotFoundException 
	{
		if(path.exists()) {
			throw new IOException("File exists");
		}
		BlockFile bf = new BlockFile(path, blocksize);
		bf.close();
		Btree btree =  new Btree(path, "w", cmp);
		btree.root = new Bnode();
		byte[] ba = serializeNode(btree.root);
		long off = btree.file.write(ba, 0, ba.length);
		btree.file.setUserPointer(off);
		btree.root.init(btree, off);
		return btree;
	}
	
	public static byte[] serializeNode(Bnode n) throws IOException {
		ByteArrayOutputStream bos = new ByteArrayOutputStream();
		ObjectOutputStream oos = new ObjectOutputStream(bos);
		oos.writeObject(n);
		return bos.toByteArray();
	}

}
