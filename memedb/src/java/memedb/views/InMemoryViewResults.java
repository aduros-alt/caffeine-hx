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

package memedb.views;

import java.io.Serializable;

import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.ObjectOutputStream;
import java.util.ArrayList;
import java.util.Map;
import java.util.List;
import java.util.Iterator;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentSkipListMap;
import java.util.concurrent.ConcurrentSkipListSet;
import java.util.concurrent.ConcurrentNavigableMap;
import java.util.concurrent.locks.ReentrantLock;

import java.util.LinkedList;
import java.util.Deque;

import memedb.MemeDB;
import memedb.document.Document;
import memedb.document.JSONDocument;
import memedb.state.StateEvent;
import memedb.utils.Logger;
import memedb.utils.FileUtils;

import org.json.JSONArray;
import org.json.JSONObject;
import org.json.JSONException;

/**
* InMemoryViewResults are stored in RAM until the server shuts down,
* at which point they are serialized to disk.
* @author Russell Weir
**/
public class InMemoryViewResults implements Serializable, ViewResults, MapResultConsumer {
	static final long serialVersionUID = -8013847062047838865L;

	private class ResultsUpdater extends Thread {
		boolean stop = false;
		final private View view;
		final private InMemoryViewResults vr;
		final private Logger log;
		final private String db;
		final private long maxSequence;
		final private ReentrantLock lock;
		private String id;

		public ResultsUpdater(String db, String docName, String functionName, View view, InMemoryViewResults viewResults, long seqNo, ReentrantLock lock)
		{
			this.view = view;
			this.vr = viewResults;
			this.db = db;
			this.lock = lock;
			this.id = db+"/"+docName+"/"+functionName;
			this.maxSequence = seqNo;
			log = Logger.get("viewResultsUpdater:"+id);
		}

		public long syncingTo() {
			return maxSequence;
		}

		@Override
		public void run() {
			log.debug("////////////// Started view results updater thread " + id);
			if(view == null || vr == null) return;
			lock.lock();
			try {
				long vrseq = vr.getCurrentSequenceNumber();
				//Iterator<Document> it = null;
				if(vrseq < 0) {
					for(Document doc: memeDB.getBackend().allDocuments(db)) {
						if(!vr.isAlive())
							throw new Exception();
						if(doc.getSequence() > maxSequence) {
							log.debug("\t{} SeqNo {} higher than {}", id, doc.getSequence(), maxSequence);
							continue;
						}
						if(stop) {
							// here we have no way of knowing what docs
							// are indexed on next load. The results
							// must be cleared
							vr.clearFromUpdater();
							throw new Exception();
						}
						vr.doMap(doc);
					}
				}
				else {
					long max = memeDB.getState().getCurrentSequenceNumber() - vrseq;
					for(StateEvent se: memeDB.getState().eventsFromSequence(vrseq, max)) {
						if(!vr.isAlive() || stop)
							throw new Exception();
						if(!se.isForDatabase(db)) continue;
						if(se.isDatabaseEvent()) {
							vr.clearFromUpdater();
							continue;
						}
						if(se.isDocumentDelete()) {
							vr.removeResult(se.getDocumentId(), se.getSequence());
						}
						else {
							Document doc = se.getDocumentAtRevision(memeDB.getBackend());
							doc.setSequence(se.getSequence());
							vr.doMap(doc);
							log.debug("\t{} mapped {} seq {}",id,doc.getId(),doc.getSequence());
						}
					}
				}
			}
			catch(Exception e) {}
			finally {
				lock.unlock();
			}
			log.debug("////////////// View results updater thread complete "+id);
		}

		@Override
		public void interrupt() {
			this.stop = true;
			super.interrupt();
		}
	};

	private final class MapResultEntry {
		public final Document doc;
		public final long seqNo;
		public final long timestamp;

		private JSONObject result;
		private boolean hasResult = false;
		public MapResultEntry(Document doc) {
			this.doc = doc;
			this.seqNo = doc.getSequence();
			result = null;
			hasResult = false;
			this.timestamp = new java.util.Date().getTime();
		}
		final public JSONObject getResult() {
			return result;
		}
		final public boolean hasResult() {
			return hasResult;
		}
		final public void setResult(JSONObject r) {
			result = r;
			hasResult = true;
		}

	};

	/*
	* Now why would it be that ArrayList.removeRange is protected?
	*/
	private class ArrayListExp<T> extends ArrayList<T> {
		public void rangeRemove(int fromIndex, int toIndex) {
			int l = size();
			if (l != 0) {
				if(fromIndex < l ) {
					if(toIndex > l)
						toIndex = l;
					removeRange(fromIndex, toIndex);
				}
			}
		}
	}

	protected final static String PATH_PROPERTY		= "viewresults.inmemory.path";
	protected final static String VIEW_RESULTS_NAME = "view.res";

	// id -> JSON data
	protected ConcurrentHashMap<String,JSONObject> idMap = new ConcurrentHashMap<String,JSONObject>();

	// key -> ListSet[ JSON Data]
	private ConcurrentSkipListMap<Object, ConcurrentSkipListSet<JSONObject>> keyMap
		= new ConcurrentSkipListMap<Object, ConcurrentSkipListSet<JSONObject>>(new Collate());

	// the highest sequence number yet indexed
	private long currentSequenceNumber;

	final private String db;
	final private String docName;
	final private String functionName;
	final private String id;
	private File baseDir;
	private Object mgrObject;


	private View view;
	private String map_src;
	private String reduce_src;
	private Object reduceResult;


	transient protected MemeDB memeDB;
	transient protected Logger log;
	transient private boolean shutdown;
	transient private boolean destroy;
	transient private ResultsUpdater updater;
	transient private boolean isAlive;
	transient private ReentrantLock lock;
	transient private ConcurrentSkipListMap<Long, MapResultEntry> expectedResults;

	///////////////////////////////////////
	//       Java deserializtion         //
	///////////////////////////////////////
	private void readObject(java.io.ObjectInputStream in)
     throws IOException, ClassNotFoundException {
		in.defaultReadObject();
		log = Logger.get(InMemoryViewResults.class);
		shutdown = false;
		destroy = false;
		isAlive = false;
		lock = new ReentrantLock(true);
		this.expectedResults = new ConcurrentSkipListMap<Long, MapResultEntry>();
	}

	private InMemoryViewResults() {
		db = null;
		docName = null;
		functionName = null;
		id = null;
		lock = new ReentrantLock(true);
	}

	public InMemoryViewResults(String db, String docName, String functionName, View view)
	{
		this.db = db;
		this.docName = docName;
		this.functionName = functionName;
		this.view = view;
		this.map_src = view.getMapSrc();
		this.reduce_src = view.getReduceSrc();
		this.currentSequenceNumber = -1;
		this.id = "InMemoryViewResults ("+db+"/"+docName+"/"+functionName+")";
		this.isAlive = false;
		this.lock = new ReentrantLock(true);
		this.expectedResults = new ConcurrentSkipListMap<Long, MapResultEntry>();
	}

	/**
	* Point at which a document is actually passed to the View for processing.
	* Exposed for ResultsUpdater thread use
	*/
	public void doMap(Document doc) {
		log.debug("doMap {}", doc.getId());
		String id = doc.getId();
		if(id == null) return;
		expectedResults.put(new Long(doc.getSequence()), new MapResultEntry(doc));
		view.map(this, doc);
	}

	///////////////////////////////////////
	//      ViewResults Interface        //
	///////////////////////////////////////
	public synchronized void addResult(Document doc) {
		log.debug("\t{} addResult {} {}", id, doc.getSequence(),currentSequenceNumber);
		if(doc == null)
			throw new NullPointerException();

		boolean haveLock = false;
		try {
			if(lock.tryLock()) {
				haveLock = true;
				doMap(doc);
			} else {
				if(!updater.isAlive()) {
					updater = new ResultsUpdater(db, docName, functionName, view, this, doc.getSequence(), lock);
					updater.start();
				}
			}
		} finally {
			if(haveLock)
				lock.unlock();
		}
	}

/*
	public Deque all() {
		LinkedList<JSONObject> rv = new LinkedList<JSONObject>();

		for(Object key: keyMap.keySet()) {
			ConcurrentSkipListSet<JSONObject> clq = keyMap.get(key);
			Iterator<JSONObject> it = clq.iterator();
			while(it.hasNext()) {
				JSONObject j = it.next();
				if(j == null)
					continue;
				JSONObject o = new JSONObject();
				try {
					o.put("id", j.get("id"));
					o.put("key", j.get("key"));
					o.put("value", j.get("value"));
					rv.add(o);
				} catch(JSONException e) {}
			}
		}
		return rv;
	}
*/
	public List<JSONObject> all() {
		ArrayList<JSONObject> rv = new ArrayList<JSONObject>();

/*
#ifdef COPY_BEFORE_GIVING_TO_CONSUMER
		for(Object key: keyMap.keySet()) {
			ConcurrentSkipListSet<JSONObject> clq = keyMap.get(key);
			Iterator<JSONObject> it = clq.iterator();
			while(it.hasNext()) {
				JSONObject j = it.next();
				if(j == null)
					continue;
				JSONObject o = new JSONObject();
				try {
					o.put("id", j.get("id"));
					o.put("key", j.get("key"));
					o.put("value", j.get("value"));
					rv.add(o);
				} catch(JSONException e) {}
			}
		}
#endif ;)
*/

		for(Object key: keyMap.keySet()) {
			rv.addAll(keyMap.get(key));
		}
		return rv;
	}

	public void destroyResults() {
		log.info("{} destroying...", id);
		isAlive = false;
		if(updater != null)
			updater.interrupt();
		lock.lock(); // never released. Deadlock, sure.
		synchronized(this) {
			try {
				recursivelyDeleteFiles(baseDir);
			} catch(Exception e) {
				log.error("{} Error removing view ", id, e);
			}
		}
		log.info("{} destroying complete.", id);
	}

	public void clear() {
		if(updater != null)
			updater.interrupt();
		lock.lock();
		try {
			synchronized(this) {
				idMap.clear();
				keyMap.clear();
				currentSequenceNumber = -1;
			}
		} finally {
			lock.unlock();
		}
	}

	public void clearFromUpdater() {
		synchronized(this) {
			idMap.clear();
			keyMap.clear();
		}
	}

	public long getCurrentSequenceNumber() {
		return currentSequenceNumber;
	}

	/*
	* Returns the arbitrary object attached to the ViewResults instance
	* @see setManagerObject
	**/
	public Object getManagerObject() {
		return mgrObject;
	}

	/*
	* Returns a full path to locate any existing instance of InMemoryViewResults
	*/
	public File getInstanceFile()
	{
		File f = new File(
			getInstancePath(memeDB, db, docName, functionName),
			VIEW_RESULTS_NAME);
		return f;
	}

	public void init(MemeDB memedb) {
		this.memeDB = memedb;
		baseDir = getInstancePath(memedb, db, docName, functionName);
		if (!baseDir.exists()) {
			baseDir.mkdirs();
		}
		shutdown = false;
		destroy = false;
		log = Logger.get(InMemoryViewResults.class);
		log.info("{} Initialized at seq {} {}", id, currentSequenceNumber, view.getMapSrc());
	}

	public View getView() {
		return view;
	}

	public boolean isAlive() {
		return isAlive;
	}

	public void removeResult(String id, long seqNo) {
		boolean haveLock = false;
		try {
			if(lock.tryLock()) {
				haveLock = true;
				synchronized(this) {
					JSONObject o = idMap.remove(id);
					if(o == null)
						throw new Exception("no_instance");
					Object key = o.opt("key");
					if(key == null)
						throw new Exception("key missing");
					ConcurrentSkipListSet<JSONObject> set = keyMap.get(key);
					if(set == null)
						throw new Exception("no_instance");
					set.remove(o);
				}
			} else {
				synchronized(this) {
					if(!updater.isAlive()) {
						updater = new ResultsUpdater(db, docName, functionName, view, this, seqNo, lock);
						updater.start();
					}
				}
			}
		} catch(Exception e) {
			if(!e.getMessage().equals("no_instance"))
				log.error("{} error removing result: {}",id,e);
		} finally {
			if(haveLock)
				lock.unlock();
		}
	}

	/*
	* sets the arbitrary object attached to the ViewResults instance
	* @see setManagerObject
	**/
	public void setManagerObject(Object o) {
		mgrObject = o;
	}

	/*
	* Validate that the source has not changed from the provided view
	**/
	public void setView(View view) throws ViewException {
		if(view == null)
			throw new RuntimeException("view should not be null");
		if(view.getMapSrc() == null)
			throw new RuntimeException("view.getMapSrc() should not be null");

		if(map_src == null || !map_src.equals(view.getMapSrc()))
			throw new ViewException("Map source changed.");

		String rs = view.getReduceSrc();
		if((reduce_src == null && rs != null) ||
			rs == null || !reduce_src.equals(rs)) {
			reduce_src = rs;
			invalidateReduce();
		}
	}

	public void start() {
		synchronized(this) {
			isAlive = true;
			updater = new ResultsUpdater(db, docName, functionName, view, this, memeDB.getState().getCurrentSequenceNumber(), lock);
			updater.start();
		}
	}

	public void shutdown() {
		isAlive = false;
		synchronized(this) {
			isAlive = false;
			try {
				save();
			} catch(ViewException e) {
				log.error("{} Error saving {} : {}", id, baseDir.toString(), e.getMessage());
			}
		}
	}

	public Deque<JSONObject> subSet(Object startKey, boolean startInclusive, Object endKey, boolean endInclusive) {
		LinkedList<JSONObject> rv = new LinkedList<JSONObject>();
		ConcurrentNavigableMap<Object,ConcurrentSkipListSet<JSONObject>>
			sm = keyMap.subMap(startKey, startInclusive, endKey, endInclusive);

		for(Object key: sm.keySet()) {
			ConcurrentSkipListSet<JSONObject> clq = keyMap.get(key);
			Iterator<JSONObject> it = clq.iterator();
			while(it.hasNext()) {
				JSONObject j = it.next();
				if(j == null)
					continue;
				JSONObject o = new JSONObject();
				try {
					o.put("key", j.get("key"));
					o.put("value", j.get("value"));
					rv.add(o);
				} catch(JSONException e) {}
			}
		}
		return rv;
	}

	/**
	* In order of how they are applied
	* <ul>
	* <li>key - single key filter. If specified, no startkey or endkey matters
	* <li>startkey - starting key
	* <li>startkey_inclusive - starting key included in results (default true)
	* <li>endkey - ending key
	* <li>endkey_inclusive - ending key included in result (default true)
	* <li>descending - descending results (default false)
	* <li>skip - number of results to ignore
	* <li>count - maximum number of rows to return
	* <li>
	*/
	public ArrayList<JSONObject> subList(Map<String,String> options) {
		Object key = makeKeyMapKey("key", options);
		Object startkey = makeKeyMapKey("startkey", options);
		Object endkey = makeKeyMapKey("endkey", options);
		boolean startInclusive = "false".equals(options.get("startkey_inclusive")) ? false : true;
		boolean endInclusive = "false".equals(options.get("endkey_inclusive")) ? false : true;
		boolean descending = "true".equals(options.get("descending"));
		Long skip = null;
		try {
			skip = new Long(options.get("skip"));
		} catch ( Exception e ) {}
		Long count = null;
		try {
			count = new Long(options.get("count"));
		} catch ( Exception e ) {}


		ArrayListExp<JSONObject> rv = new ArrayListExp<JSONObject>();
		if(count != null && count.longValue() == 0)
			return rv;
		ConcurrentNavigableMap<Object,ConcurrentSkipListSet<JSONObject>>
			sm = keyMap;

		if(key != null) {
			startkey = key;
			endkey = key;
			startInclusive = true;
			endInclusive = true;
			sm = keyMap.subMap(startkey, startInclusive, endkey, endInclusive);
		}
		else {
			if(startkey != null) {
				if(endkey != null) {
					sm = keyMap.subMap(startkey, startInclusive, endkey, endInclusive);
				} else {
					sm = keyMap.tailMap(startkey, startInclusive);
				}
			}
			else if(endkey != null) {
				sm = keyMap.headMap(endkey, endInclusive);
			}
		}

		if(descending)
			sm = sm.descendingMap();

		for(Object smkey: sm.keySet()) {
			ConcurrentSkipListSet<JSONObject> clq = keyMap.get(smkey);
			Iterator<JSONObject> it = null;
			if(descending)
				it = clq.descendingIterator();
			else
				it = clq.iterator();
			while(it.hasNext()) {
				JSONObject j = it.next();
				if(j == null)
					continue;
				JSONObject o = new JSONObject();
				try {
					o.put("key", j.get("key"));
					o.put("value", j.get("value"));
					o.put("id", j.get("id"));
					rv.add(o);
				} catch(JSONException e) {}
			}
		}

		if(skip != null) {
			int start = skip.intValue();
			rv.rangeRemove(0, start);
		}

		if(count != null) {
			int end = count.intValue();
			try {
				rv.rangeRemove(end, rv.size());
			} catch( Exception e ) {}
		}
// log.debug("####### {}", idMap);
// log.debug("####### {}", keyMap);
// log.debug("####### {} {}", key, key.getClass());
		return rv;
	}

	///////////////////////////////////////
	//  MapResultConsumer Interface      //
	///////////////////////////////////////
	public synchronized void onMapResult(Document doc, JSONObject j) {
		MapResultEntry mre = expectedResults.get(new Long(doc.getSequence()));
		if(mre == null)
			return;
		mre.setResult(j);
		processMapResults();
	}

	private synchronized void processMapResults() {
		for(MapResultEntry mre: expectedResults.values()) {
			if(!mre.hasResult) {
				// todo timeout value of 5 seconds, tunable?
				if(new java.util.Date().getTime() > mre.timestamp + 5000) {
					doMap(mre.doc);
				}
				return;
			}
			Document doc = mre.doc;
			JSONObject j = mre.getResult();
			JSONObject o = idMap.get(doc.getId());
			try {
				if(j == null) {
					log.debug("\tNo result for view {} {}", id, view.getMapSrc());
				}
				else {
					log.debug("\tResult for view {} {} : {}", id, view.getMapSrc(), j.toString());
					j.put("id", doc.getId());

					Object key = j.get("key");
					Object value = j.get("value");

					ConcurrentSkipListSet<JSONObject> newSet =
						new ConcurrentSkipListSet<JSONObject>(new Collate());

					idMap.put(doc.getId(), j);
					ConcurrentSkipListSet<JSONObject> set =
						keyMap.putIfAbsent(key, newSet);
					if(set == null)
						set = newSet;
					set.add(j);

					if(view.hasReduce()) {
						if(o != null) {
							invalidateReduce();
						}
						else {
							JSONObject no = new JSONObject();
							no.put("key", JSONObject.NULL);
							no.put("value", o);
							JSONArray a = new JSONArray();
							a.put(no);
							a.put(j);
							reduceResult = view.reduce(a);
						}
					}

					if(doc.getSequence() > currentSequenceNumber)
						currentSequenceNumber = doc.getSequence();
				}
			}
			catch(JSONException e) {
				log.warn("{} JSONException {} adding {}", id, e.getMessage(),j.toString());
			}
			expectedResults.remove(new Long(mre.seqNo));
		}
	}


	///////////////////////////////////////
	//         Protected Methods         //
	///////////////////////////////////////
	protected File getInstancePath(MemeDB memedb, String db, String docName, String functionName)
	{
		File d = new File(memedb.getProperty(PATH_PROPERTY));
		if (d==null) {
			throw new RuntimeException("Could not open InMemoryViewResults path ("+PATH_PROPERTY+")");
		}
		d = new File(d, FileUtils.fsEncode(db));
		d = new File(d, FileUtils.fsEncode(docName));
		d = new File(d, FileUtils.fsEncode(functionName));
		return d;
	}

	protected void invalidateReduce() {
		reduceResult = null;
	}

	protected void recursivelyDeleteFiles(File file) {
		if (file.isDirectory()) {
			for (File f:file.listFiles()) {
				recursivelyDeleteFiles(f);
			}
		}
		file.delete();
	}

	private final void save() throws ViewException {
		if (!baseDir.exists()) {
			baseDir.mkdirs();
		}
		ObjectOutputStream oos =null;
		try {
			oos = new ObjectOutputStream(new FileOutputStream(new File(baseDir,VIEW_RESULTS_NAME)));
			oos.writeObject(this);
			oos.close();
		} catch (FileNotFoundException e) {
			throw new ViewException(e);
		} catch (IOException e) {
			throw new ViewException(e);
		} finally {
			if (oos!=null) {
				try {
					oos.close();
				} catch (IOException e) {
				}
			}
		}
	}

	static private Object makeKeyMapKey(String opt, Map<String,String> options) {
		if(!options.containsKey(opt))
			return null;
		try {
			String val = options.get(opt);
			return makeKey(val).get("key");
		} catch (Exception e) {
		}
		return null;
	}

	/**
	* Makes a JSONObject key structure from the String provided. The String
	* must be valid JSON, that is strings wrapped with quotations, arrays
	* in brackets, ie. ["one", 2, [3, "four"]]
	*/
	static public JSONObject makeKey(String value) {
		return new JSONObject("{ key: " +value+ "}");
	}
}

