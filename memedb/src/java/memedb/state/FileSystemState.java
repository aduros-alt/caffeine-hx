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

package memedb.state;

import java.io.File;
import java.io.IOException;
import java.io.RandomAccessFile;
import java.util.ArrayList;
import java.util.List;
import java.util.Iterator;

import memedb.MemeDB;
import memedb.document.Document;
import memedb.utils.FileUtils;
import memedb.utils.Logger;


/**
* A DBState manager that records events in a streamed and indexed file.
* @author Russell Weir
* @todo Index rebuilding etc.
*/
public class FileSystemState extends DBState {
	public static final String STATE_PATH = "state.fs.path";
	public static final String INDEX_FILENAME= "state.idx";
	public static final String DATA_FILENAME="state.dat";

	private static final int SIZEOF_LONG=8;
	private static final int SIZEOF_INDEX_ENTRY=16;

	private MemeDB memeDB;
	private File stateDir;
	private File fIndexFile;
	private File fDataFile;
	private RandomAccessFile indexFile;
	private RandomAccessFile dataFile;

	private long nextSequenceNumber;

	final private Logger log = Logger.get(FileSystemState.class);

	public FileSystemState() {
	}

	public long getCurrentSequenceNumber() {
		return nextSequenceNumber - 1;
	}

	/**
	*
	* @todo index rebuild, last entry check
	*/
	public void init(MemeDB memeDB) {
		this.memeDB=memeDB;
		this.nextSequenceNumber = 0;

		String path = memeDB.getProperty(STATE_PATH);
		if (path == null) {
			throw new RuntimeException(
				"You must include a "+STATE_PATH+" element in memedb.properties");
		}
		this.stateDir = new File(path);
		if(!stateDir.exists()) {
			log.info("Creating state directory " + path);
			stateDir.mkdirs();
		} else if (!stateDir.isDirectory()) {
			log.error("Path: {} not valid!", path);
			throw new RuntimeException("Path: " + path + " not valid!");
		}

		this.fIndexFile = new File(stateDir, INDEX_FILENAME);
		this.fDataFile = new File(stateDir, DATA_FILENAME);

		boolean createDummyEntry = false;
		boolean createDummyIndex = false;
		try {
			if(!fIndexFile.exists()) {
				log.info("Creating state index file ");
				createDummyIndex = true;
			}
			indexFile = new RandomAccessFile(fIndexFile, "rws");
			if(!fDataFile.exists()) {
				log.info("Creating state data file ");
				createDummyEntry = true;
			}
			dataFile = new RandomAccessFile(fDataFile, "rws");
		} catch(Exception e) {
			throw new RuntimeException("Error opening state indexes: " + e.getMessage());
		}

		try {
			long iPos = indexFile.length();
			long dPos = 0;
			long seq = 0;

			if(iPos != 0) {
				if(indexFile.length() % SIZEOF_INDEX_ENTRY != 0) {
					throw new RuntimeException("Index file broken");
				}
				log.debug("index seeking to {}", iPos - SIZEOF_INDEX_ENTRY);
				indexFile.seek(iPos - SIZEOF_INDEX_ENTRY);
				seq = indexFile.readLong();
				dPos = indexFile.readLong();
				log.debug("index got seq {} dPos {}", seq, dPos);
			}
			else {
				indexFile.seek(0);
				seq = -1;
			}
			nextSequenceNumber = seq + 1;

			dataFile.seek(dPos);
			if(dPos != 0) {
				// read the entry make sure it's ok etc etc
				dataFile.seek(dataFile.length());
			}
		} catch(Exception e) {
			throw new RuntimeException(e.getMessage(), e);
		}

		// If it's a new datafile, we need to write an empty
		// entry for id 0... otherwise we'd be subtracting 1 from
		// the seqNo before every operation.
		if(createDummyEntry) {
			try {
				log.info("Initializing data file");
				writeDocUpdateEntry("","", 0, "");
				dataFile.seek(0);
			} catch(IOException e) {
				throw new RuntimeException("Unable to initialize data file");
			}
		}
		if(createDummyIndex) {
			try {
				log.info("Initializing index file");
				writeIndexEntry(0,0);
			} catch(IOException e) {
				throw new RuntimeException("Unable to initialize index file");
			}
		}

		log.info("State started at sequence {}", nextSequenceNumber);
		try {
			log.debug("Data file position {}", dataFile.getFilePointer());
			try {
				log.debug("Last entry {}", readEventEntry(nextSequenceNumber - 1).toString());
			} catch(NullPointerException e) {}
			log.debug("Data file position {}", dataFile.getFilePointer());

			log.warn("{}", eventsFromSequence(0,-1));
		} catch(IOException e) {
			log.error("{}", e.getMessage());
			throw new RuntimeException(e);
		}
	}

	public void shutdown() {
		synchronized(this) {
			try {
				dataFile.close();
				indexFile.close();
			} catch(Exception e) {
			}
		}
	}

	public Iterator<StateEvent> eventIterator(long seq, long maxCount) {
		if(seq < 0) seq = 0;
		final long mc = maxCount;
		final long sq = seq;

		final Iterator<StateEvent> i = new Iterator<StateEvent>() {
			StateEvent nextEvent = null;
			RandomAccessFile fp;
			long idx = sq;
			long count = 0;
			long max = mc;
			boolean first = true;

			protected void getNext() {
				nextEvent = null;
				if(fp != null && idx<nextSequenceNumber && (max<0 || count<max)) {
					try {
						fp.seek(readIndexEntry(idx));
						nextEvent = readEventEntry(idx, fp);
						idx++;
						count++;
					} catch(Exception e) {
						nextEvent = null;
					}
				}
			}
			public boolean hasNext() {
				if(first) {
					try {
						fp = new RandomAccessFile(fDataFile, "r");
					} catch(Exception e) {
						fp = null;
					}
					getNext();
					first = false;
				}
				return nextEvent != null;
			}
			public StateEvent next() {
				StateEvent se = nextEvent;
				getNext();
				return se;
			}
			public void remove() {
				getNext();
			}
		};
		return i;
	}

	public Iterable<StateEvent> eventsFromSequence(long seq, long maxCount) {
		final Iterator<StateEvent> i = eventIterator(seq, maxCount);
		return new Iterable<StateEvent>() {
			public Iterator<StateEvent> iterator() {
				return i;
			}
		};
	}


	public void updateDocument(Document doc) {
		synchronized(this) {
			doc.setSequence(nextSequenceNumber);
			long i = 0;
			try {
				i = writeDocUpdateEntry(doc.getDatabase(), doc.getId(), nextSequenceNumber, doc.getRevision());
			} catch(IOException e) {
				throw new RuntimeException("FileSystemState: error writing data.");
			}
			try {
				writeIndexEntry(nextSequenceNumber, i);
			} catch(IOException e) {
				throw new RuntimeException("FileSystemState: error writing index.");
			}
			nextSequenceNumber++;
		}
	}

	public void finalizeDocument(Document doc) {
		memeDB.onDocumentUpdate(doc);
	}

	public void deleteDocument(Document doc) {
		deleteDocument(doc.getDatabase(), doc.getId());
	}

	public void deleteDocument(String db, String id) {
		synchronized(this) {
			long seq = nextSequenceNumber;
			try {
				long i = dataFile.getFilePointer();
				dataFile.writeByte(StateEvent.EVENT_DOC_DELETE_ID);
				dataFile.writeLong(nextSequenceNumber);
				dataFile.writeUTF(db);
				dataFile.writeUTF(id);
				writeIndexEntry(nextSequenceNumber++, i);
			} catch(Exception e) {
				throw new RuntimeException("FileSystemState.deleteDocument");
			}
			memeDB.onDocumentDeleting(db, id, seq);
		}
	}

	public long addDatabase(String name) {
		synchronized(this) {
			try {
				long i = dataFile.getFilePointer();
				long seq = nextSequenceNumber;
				dataFile.writeByte(StateEvent.EVENT_DB_CREATE_ID);
				dataFile.writeLong(nextSequenceNumber);
				dataFile.writeUTF(name);
				writeIndexEntry(seq, i);
				nextSequenceNumber++;
				return seq;
			} catch(Exception e) {
				throw new RuntimeException("FileSystemState.deleteDocument");
			}
		}
	}

	public long deleteDatabase(String name) {
		synchronized(this) {
			try {
				long i = dataFile.getFilePointer();
				long seq = nextSequenceNumber;
				dataFile.writeByte(StateEvent.EVENT_DB_DELETE_ID);
				dataFile.writeLong(nextSequenceNumber);
				dataFile.writeUTF(name);
				writeIndexEntry(seq, i);
				nextSequenceNumber++;
				return seq;
			} catch(Exception e) {
				throw new RuntimeException("FileSystemState.deleteDocument");
			}
		}
	}

	/**
	* Reads a StateEvent from the sequence number provided
	* @param seqNo Database sequence number
	* @return StateEvent data entry
	*/
	private final StateEvent readEventEntry(long seqNo)
		throws IOException
	{
		if(seqNo < 0) return null;
		RandomAccessFile fp = new RandomAccessFile(fDataFile, "r");
		fp.seek(readIndexEntry(seqNo));
		return readEventEntry(seqNo, fp);
	}

	/**
	* Reads a StateEvent from the data file pointer provided. The
	* data file pointer must already be posistioned at the start
	* of the data record.
	* @param seqNo Sequence number expected
	* @param fp RandomAccessFile already seek'd
	* @return StateEvent object of the entry
	*/
	private final StateEvent readEventEntry(long seqNo, RandomAccessFile fp)
		throws IOException
	{
		int t_id = fp.readByte();
		long seq = fp.readLong();
		if(seq != seqNo)
			throw new IOException("Unexpected sequence number " + seq +". Expecting "+seqNo);
		String db = fp.readUTF();

		String id = null;
		String rev = null;
		Document doc = null;
		if(t_id == StateEvent.EVENT_DOC_UPDATE_ID || t_id == StateEvent.EVENT_DOC_DELETE_ID) {
			id = fp.readUTF();
			if(t_id == StateEvent.EVENT_DOC_UPDATE_ID) {
				rev = fp.readUTF();
				boolean hasChainedData = fp.readBoolean();
				if(hasChainedData) {
					//doc = fp.readUTF();
					fp.readUTF();
				}
			}
		}
		return new StateEvent(seq, t_id, db, id, rev, doc);
	}


	/**
	* Write a document insert/update entry.
	* Returns the index in the dataFile where the record has
	* been written. A lock must be acquired before using this
	* method.
	*/
	private final long writeDocUpdateEntry(String db, String id, long seq, String rev)
		throws IOException
	{
		long i = dataFile.getFilePointer();
// 		log.debug("Writing data entry seq: {} id: {} rev: {} at position {}",seq,id,rev,i);
		dataFile.writeByte(StateEvent.EVENT_DOC_UPDATE_ID);
		dataFile.writeLong(seq);
		dataFile.writeUTF(db);
		dataFile.writeUTF(id);
		dataFile.writeUTF(rev);
		dataFile.writeBoolean(false);
		return i;
	}

	/**
	* Write a document insert/update entry.
	* Returns the index in the dataFile where the record has
	* been written. A lock must be acquired before using this
	* method.
	* @param fullRecord If true, the entire document will be written
	*/
	private final long writeDocUpdateEntry(Document doc, boolean fullRecord)
		throws IOException
	{
		long i = dataFile.getFilePointer();
		dataFile.writeByte(StateEvent.EVENT_DOC_UPDATE_ID);
		dataFile.writeLong(doc.getSequence());
		dataFile.writeUTF(doc.getDatabase());
		dataFile.writeUTF(doc.getId());
		dataFile.writeUTF(doc.getRevision());
		dataFile.writeBoolean(fullRecord);
		if(fullRecord)
			dataFile.writeUTF(doc.toString());
		return i;
	}




	/**
	* Creates or overwrites an index entry.
	* @param seqNo Database sequence number
	* @param dataFilePosition Position in data file
	*/
	private final void writeIndexEntry(long seqNo, long dataFilePosition)
		throws IOException
	{
		synchronized(this) {
			indexFile.seek(seqNo * SIZEOF_INDEX_ENTRY);
			indexFile.writeLong(seqNo);
			indexFile.writeLong(dataFilePosition);
		}
	}

	/**
	* Returns the offset into the datafile for the given
	* sequence number
	* @param seqNo Database sequence number
	* @return Data file seek posistion
	*/
	private final long readIndexEntry(long seqNo)
		throws IOException
	{
		long p = seqNo * SIZEOF_INDEX_ENTRY;
		synchronized(this) {
			indexFile.seek(p);
			long seq = indexFile.readLong();
			long pos = indexFile.readLong();
//	 		log.debug("readIndexEntry: for seq#{} shows seq:{} pos:{}", seqNo,seq,pos);
			return pos;
		}
	}

	/**
	* @todo Write
	*/
	private void rebuildIndex() {
	}


/*
	public Iterable<Document> documentsBySequence(String db, long startSeq) {
		Iterator it = eventIterator(startSeq, -1);
		final Iterator<Document> i = new Iterator<Document>() {
			boolean first = true;
			Document nextDoc = null;

			public void getNext() {
			}
			public boolean hasNext() {
				if (first ) {
					getNext();
					first = false;
				}
				return nextDoc != null;
			}

			public Document next() {
				Document doc = nextDoc;
				getNext();
				return doc;
			}

			public void remove() {
				getNext();
			}

		};
		return new Iterable<Document>() {
			public Iterator<Document> iterator() {
				return i;
			}
		};
	}
*/


}