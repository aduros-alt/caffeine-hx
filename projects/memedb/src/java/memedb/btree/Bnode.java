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

import java.io.Externalizable;
import java.io.IOException;
import java.io.ObjectInput;
import java.io.ObjectOutput;
import java.io.Serializable;
import java.util.ArrayList;
import java.util.Comparator;

/**
 *
 * @author Russell Weir
 */
public class Bnode implements Externalizable {
	
	private class BNodeEntry implements Serializable {
		private static final long serialVersionUID = 4156429367250816025L;
		public Object key;
		public Object value;
		private Long left;
		private Long right;
		
		public BNodeEntry() {}
		public BNodeEntry(Object key, Object value) {
			this.key = key;
			this.value = value;
		}

		public void clearChildren() {
			this.left = null;
			this.right = null;
		}
				
		public Long getLeft() {
			return left;
		}
		
		public Long getRight() {
			return right;
		}
		
		public void setLeft(long v) {
			this.right = null;
			this.left = new Long(v);
		}
		
		public void setRight(long v) {
			this.left = null;
			this.right = new Long(v);
		}
	}
	
	private class EntrySorter implements Comparator<BNodeEntry> {
		private Comparator<Object> cmp;
		
		public EntrySorter(Comparator<Object> cmp) {
			this.cmp = cmp;
		}
		
		public int compare(BNodeEntry left, BNodeEntry right) {
			return cmp.compare(left, right);
		}
	}
	
	private static final long serialVersionUID = 3596599597074756753L;
	private boolean isLeaf;
	
	transient private long fileOffset;
	transient private ArrayList<BNodeEntry> entries;
	transient private Btree btree;
	transient private Comparator cmp;
	
	public Bnode() {
	}
	
	protected void init(Btree btree, long fileOffset) {
		this.btree = btree;
		this.fileOffset = fileOffset;
		if(this.entries == null)
			this.entries = new ArrayList<BNodeEntry>();
		this.cmp = btree.getComparator();
	}

	
	private int compareKeyAtPos(int idx, Object key) {
		return cmp.compare(key, entries.get(idx).key);
	}
		
	final private boolean delete(Object key) {
		return false;
	}
	
	final byte[] get(Object key) {
		return new byte[1];
	}
	
	final long getOffset() {
		return this.fileOffset;
	}
	
	public boolean isLeaf() {
		return this.isLeaf;
	}
	
	final boolean set(Object key, Object value, int dataOffset, int dataLen) 
			throws IOException
	{
		BNodeEntry e = new BNodeEntry(key, value);
		if(entries.size() == 0) {
			entries.add(e);
		} else {
			int start = 0;
			int end = entries.size() - 1;
			int middle = 0;
			while(end >= start) {
				middle = (start + end) / 2;
				int v = compareKeyAtPos(middle, key);
				if(v < 0) end = middle - 1;
				else if(v > 0) start = middle + 1;
				else break;
			}
		}
		return true;
	}
	
	public Bnode setIsLeafNode(boolean v) {
		this.isLeaf = v;
		return this;
	}
	
	public void writeExternal(ObjectOutput out) throws IOException {
		out.writeBoolean(isLeaf);
		out.writeObject(entries);
	}

	public void readExternal(ObjectInput in) throws IOException, ClassNotFoundException {
		this.isLeaf = in.readBoolean();
		this.entries = (ArrayList<BNodeEntry>)in.readObject();
	}

}
