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

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.EOFException;
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

	private static final int INITIAL_CAPACITY= 65536;
	private static final double GROWTH_FACTOR=0.5;

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

		try {
			if(!fIndexFile.exists()) {
				log.info("Creating state index file ");
			}
			indexFile = new RandomAccessFile(fIndexFile, "rws");
			if(!fDataFile.exists()) {
				log.info("Creating state data file ");
			}
			dataFile = new RandomAccessFile(fDataFile, "rws");


		} catch(Exception e) {
			throw new RuntimeException("Error opening state indexes: " + e.getMessage());
		}

		try {
			checkCapacities();
			log.debug("Data file pos {} len {}", dataFile.getFilePointer(), dataFile.length());
			log.debug("Index file pos {} len {}", indexFile.getFilePointer(), indexFile.length());
		} catch(IOException e) {
			throw new RuntimeException(e);
		}

		try {
			nextSequenceNumber = seekIndexEnd() + 1;
		} catch(IOException e) {
			throw new RuntimeException(e);
		}

		log.info("State started at sequence {}", nextSequenceNumber);
		//try {Thread.sleep(5000);} catch(Exception e) {}
		try {
			log.debug("Data file position {}", dataFile.getFilePointer());
			log.debug("Index file position {}", indexFile.getFilePointer());
			try {
				if(nextSequenceNumber > 0)
					log.debug("Last entry {}", readEventEntry(nextSequenceNumber - 1).toString());
			} catch(NullPointerException e) {}
			log.debug("Data file position {}", dataFile.getFilePointer());
			log.debug("Index file position {}", indexFile.getFilePointer());
		} catch(IOException e) {
			log.error("{}", e.getMessage());
			throw new RuntimeException(e);
		}
	}

	public void shutdown() {
		synchronized(this) {
			try {
				dataFile.close();
			} catch( Exception e ) {
			}
			try {
				indexFile.close();
			} catch( Exception e ) {
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
				ByteArrayOutputStream baos = new ByteArrayOutputStream();
				DataOutputStream dos = new DataOutputStream(baos);
				dos.writeByte(StateEvent.EVENT_DOC_DELETE_ID);
				dos.writeLong(nextSequenceNumber);
				dos.writeUTF(db);
				dos.writeUTF(id);
				dataFile.write(baos.toByteArray());
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
				ByteArrayOutputStream baos = new ByteArrayOutputStream();
				DataOutputStream dos = new DataOutputStream(baos);
				dos.writeByte(StateEvent.EVENT_DB_CREATE_ID);
				dos.writeLong(nextSequenceNumber);
				dos.writeUTF(name);
				dataFile.write(baos.toByteArray());
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
				ByteArrayOutputStream baos = new ByteArrayOutputStream();
				DataOutputStream dos = new DataOutputStream(baos);
				dos.writeByte(StateEvent.EVENT_DB_DELETE_ID);
				dos.writeLong(nextSequenceNumber);
				dos.writeUTF(name);
				dataFile.write(baos.toByteArray());
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
		ByteArrayOutputStream baos = new ByteArrayOutputStream();
		DataOutputStream dos = new DataOutputStream(baos);
		dos.writeByte(StateEvent.EVENT_DOC_UPDATE_ID);
		dos.writeLong(seq);
		dos.writeUTF(db);
		dos.writeUTF(id);
		dos.writeUTF(rev);
		dos.writeBoolean(false);
		dataFile.write(baos.toByteArray());
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
		ByteArrayOutputStream baos = new ByteArrayOutputStream();
		DataOutputStream dos = new DataOutputStream(baos);
		dos.writeByte(StateEvent.EVENT_DOC_UPDATE_ID);
		dos.writeLong(doc.getSequence());
		dos.writeUTF(doc.getDatabase());
		dos.writeUTF(doc.getId());
		dos.writeUTF(doc.getRevision());
		dos.writeBoolean(fullRecord);
		dataFile.write(baos.toByteArray());
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
		ByteArrayOutputStream baos = new ByteArrayOutputStream();
		DataOutputStream dos = new DataOutputStream(baos);
		dos.writeLong(seqNo);
		dos.writeLong(dataFilePosition);
		synchronized(this) {
			indexFile.seek(seqNo * SIZEOF_INDEX_ENTRY);
			indexFile.write(baos.toByteArray());
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
		byte[] ba = new byte[SIZEOF_INDEX_ENTRY];
		synchronized(this) {
			indexFile.seek(p);
			indexFile.readFully(ba, 0, SIZEOF_INDEX_ENTRY);
		}

		DataInputStream dis = new DataInputStream(new ByteArrayInputStream(ba));
		long seq = dis.readLong();
		long pos = dis.readLong();
		return pos;
	}

	/**
	* @todo Write
	*/
	private void rebuildIndex() {
	}

	/**
	* Checks the size of the index and data files, growing them to at least
	* initial capacity or GROWTH_FACTOR times larger
	**/
	private void checkCapacities() throws IOException {
		long posI = indexFile.getFilePointer();
		long lenI = indexFile.length();
		if(posI >= (0.8 * lenI)) {
			indexFile.seek(lenI);
			long newSize = ((long)(lenI * GROWTH_FACTOR)) + lenI;
			if(newSize == 0)
				newSize = INITIAL_CAPACITY * SIZEOF_INDEX_ENTRY;
			indexFile.setLength(newSize);
			long count = (newSize - lenI) / SIZEOF_INDEX_ENTRY / 1024;

			// 16k buffer, 1024 entries of 16 bytes
			ByteArrayOutputStream baos = new ByteArrayOutputStream();
			DataOutputStream dos = new DataOutputStream(baos);
			for(int x = 0; x < 1024; x++) {
				dos.writeLong(-1);
				dos.writeLong(-1);
			}
			byte[] ba = baos.toByteArray();
 			while(count-- > 0) {
				indexFile.write(ba);
			}
			indexFile.seek(posI);
		}

		long posD = dataFile.getFilePointer();
		long lenD = dataFile.length();
		if(posD >= (0.8 * lenD)) {
			long newSize = ((long)(lenD * GROWTH_FACTOR)) + lenD;
			if(newSize == 0)
				newSize = INITIAL_CAPACITY * 1024; // 1k per record
			dataFile.setLength(newSize);
			dataFile.seek(posD);
		}
	}

	/**
	* Sets the indexFile and dataFile to their next writing position.
	* @returns Last valid sequence number recorded, -1 if none
	*/
	private long seekIndexEnd() throws IOException {
		indexFile.seek(0);
		long lastIdx = 0;
		long lastSeq = -1;
		long lastPos = -1;
		try {
			while(true) {
				long seq = indexFile.readLong();
				long pos = indexFile.readLong();
				//log.debug("****** read {} {}", seq, pos);
				if(seq < 0) {
					indexFile.seek(lastIdx);
					break;
				}
				lastSeq = seq;
				lastPos = pos;
				lastIdx = indexFile.getFilePointer();
			}
		} catch( EOFException e ) {
		}

		if(lastPos == -1) {
			dataFile.seek(0);
			return lastSeq;
		}
		if(lastPos > dataFile.length())
			throw new RuntimeException("dataFile truncated?");

		dataFile.seek(lastPos);
		readEventEntry(lastSeq, dataFile);
		return lastSeq;
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