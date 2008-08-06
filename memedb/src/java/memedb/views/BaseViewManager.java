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

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.lang.reflect.InvocationTargetException;
import java.util.Comparator;
import java.util.Date;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentSkipListSet;
import java.util.concurrent.atomic.AtomicLong;

import memedb.MemeDB;
import memedb.utils.Logger;
import memedb.document.Document;
import memedb.state.DBState;
import memedb.state.StateEvent;

import org.json.JSONObject;

/**
* A base for view managers that keep a set of Views and ViewResults
* @author Russell Weir
*/
abstract public class BaseViewManager extends ViewManager {

	protected abstract class BaseEvent {
		ViewManager vm;
		String db;
		String id;
		long seqNo;
		long timestamp;
		private BaseEvent() {}
// 		return ( new Date().getTime() > timeoutTimestamp );
		abstract public void apply() throws ViewException;
		public long getSequence() { return seqNo; }
		public long getTimestamp() { return timestamp; }
	}

	protected class addDocEvent extends BaseEvent {
		Document doc;
		public addDocEvent(ViewManager vm, Document doc) {
			this.timestamp = new Date().getTime();
			this.vm = vm; this.doc = doc; this.seqNo = doc.getSequence();
		}
		public void apply() throws ViewException {
			vm.recalculateDocument(doc);
		}
	}
	protected class deleteDocEvent extends BaseEvent {
		public deleteDocEvent(ViewManager vm, String db, String id, long seqNo) {
			this.timestamp = new Date().getTime();
			this.vm = vm; this.db = db; this.id = id; this.seqNo = seqNo;
		}
		public void apply() throws ViewException {
			vm.deletingDocument(db, id, seqNo);
		}
	}
	protected class addDbEvent extends BaseEvent {
		public addDbEvent(ViewManager vm, String db, long seqNo) {
			this.timestamp = new Date().getTime();
			this.vm = vm; this.db = db; this.seqNo = seqNo;
		}
		public void apply() throws ViewException {
			vm.onDatabaseCreated(db, seqNo);
		}
	}
	protected class deleteDbEvent extends BaseEvent {
		public deleteDbEvent(ViewManager vm, String db, long seqNo) {
			this.timestamp = new Date().getTime();
			this.vm = vm; this.db = db; this.seqNo = seqNo;
		}
		public void apply() throws ViewException {
			vm.onDatabaseDeleted(db, seqNo);
		}
	}
	protected class nullEvent extends BaseEvent {
		public nullEvent(ViewManager vm, long seqNo) {
			this.timestamp = new Date().getTime();
			this.vm = vm; this.db = db; this.seqNo = seqNo;
		}
		public void apply() throws ViewException {
		}
	}
	protected class EventSorter implements Comparator {
		public int compare(Object obj1, Object obj2) {
			long s1 = ((BaseEvent) obj1).getSequence();
			long s2 = ((BaseEvent) obj2).getSequence();
			if(s1 == s2) return 0;
			return (s1 < s2) ? -1 : 1;
		}
	}

	public final static String CONFIG_VIEWRESULTS_CLASS="viewresults.class";
	protected Logger log;
	protected Thread monitor = null;
	protected AtomicLong nextSequenceNumber = new AtomicLong();

	protected ConcurrentSkipListSet<BaseEvent> eventCache = new ConcurrentSkipListSet<BaseEvent>(new EventSorter());
	protected MemeDB memeDB;

	//				db					doc						func
	protected ConcurrentHashMap<String,ConcurrentHashMap<String, ConcurrentHashMap<String,View>>> views
			= new ConcurrentHashMap<String,ConcurrentHashMap<String, ConcurrentHashMap<String,View>>>();
	protected ConcurrentHashMap<String,ConcurrentHashMap<String,ConcurrentHashMap<String,ViewResults>>> viewResults
			= new ConcurrentHashMap<String,ConcurrentHashMap<String,ConcurrentHashMap<String,ViewResults>>>();


	protected void postEvent(BaseEvent be) {
		eventCache.add(be);
	}

	protected void startMonitor() {
		final BaseViewManager me = this;
		monitor = new Thread() {
			boolean stop = false;
			@Override
			public void run() {
				log.info("Starting view cache monitoring thread");
				while (!stop) {
					boolean doSleep = true;
					for(BaseEvent event: eventCache) {
						if(event.getSequence() == nextSequenceNumber.get()) {
							try {
								event.apply();
							} catch (Exception e) {}
							eventCache.remove(event);
						}
						else if(event.getTimestamp() < new Date().getTime() - 5000) {
							doSleep = false;
							// we'll be optimistic here in assuming we're only
							// missing 1 event.
							for(StateEvent se : memeDB.getState().eventsFromSequence(event.getSequence() - 1, 1)) {
								switch(se.getTypeId()) {
								case StateEvent.EVENT_DOC_UPDATE_ID:
									Document doc = memeDB.getBackend().getDocument(se.getDatabase(), se.getDocumentId(),se.getRevision());
									if(doc != null)
										postEvent(new addDocEvent(me, doc));
									else
										postEvent(new nullEvent(me,se.getSequence()));
									break;
								case StateEvent.EVENT_DOC_DELETE_ID:
									postEvent(new deleteDocEvent(me, se.getDatabase(), se.getDocumentId(), se.getSequence()));
									break;
								case StateEvent.EVENT_DB_CREATE_ID:
									postEvent(new addDbEvent(me, se.getDatabase(), se.getSequence()));
									break;
								case StateEvent.EVENT_DB_DELETE_ID:
									postEvent(new deleteDbEvent(me, se.getDatabase(), se.getSequence()));
									break;
								default:
									log.error("FATAL: Bad event received from DBState: {}",se.toString());
									memeDB.shutdown();
								}
							}
						}
						else break;
					}
					try {
						if(doSleep)
							Thread.sleep(1000);
						else
							Thread.sleep(10);
					} catch (InterruptedException e) {
						stop = true;
					}
				}
				log.info("Stopping view cache monitoring thread");
			}

			@Override
			public void interrupt() {
				this.stop = true;
				super.interrupt();
			}
		};
		monitor.start();
	}




	/**
	* Returns a Map of docNames -> Functions -> Views. Will create an entry
	* if no views exist
	*/
	protected ConcurrentHashMap<String, ConcurrentHashMap<String,View>> getDbViewEntries(String db) {
		ConcurrentHashMap<String, ConcurrentHashMap<String,View>>
			nv = new ConcurrentHashMap<String, ConcurrentHashMap<String,View>>();
		ConcurrentHashMap<String, ConcurrentHashMap<String,View>>
			rv = views.putIfAbsent(db, nv);
		if(rv == null)
			rv = nv;
		return rv;
	}

	/**
	* Returns a Map of Functions -> Views. Will create an entry
	* if no views exist
	*/
	protected ConcurrentHashMap<String,View> getViewEntries(String db, String docName) {
		ConcurrentHashMap<String, ConcurrentHashMap<String,View>>
			viewMap = getDbViewEntries(db);

		ConcurrentHashMap<String,View>
			nv = new ConcurrentHashMap<String,View>();
		ConcurrentHashMap<String,View>
			rv = viewMap.putIfAbsent(docName, nv);
		if(rv == null)
			rv = nv;
		return rv;
	}

	/*
	*/
	protected void removeViewEntries(String db) {
		views.remove(db);
	}

	/*
	*/
	protected void removeViewEntries(String db, String docName) {
		getDbViewEntries(db).remove(docName);
	}

	protected View getViewEntry(String db, String docName, String functionName) {
		Map<String,View> v = getViewEntries(db, docName);
		return v.get(functionName);
	}

	/*
	* @return The previous View, or null if there was none
	*
	*/
	protected View putViewEntry(String db, String docName, String functionName, View v) {
		Map<String,View> vm = getViewEntries(db, docName);
		return vm.put(functionName, v);

	}

	/*
	* @return The previous View, or null if there was none
	*/
	protected View putViewEntryIfAbsent(String db, String docName, String functionName, View v) {
		ConcurrentHashMap<String,View> vm = getViewEntries(db, docName);
		return vm.putIfAbsent(functionName, v);
	}







	/**
	* Returns a Map of docNames -> Functions -> ViewResults. Will create an entry
	* if no view results exist
	*/
	protected ConcurrentHashMap<String, ConcurrentHashMap<String,ViewResults>> getDbResultsEntries(String db) {
		ConcurrentHashMap<String, ConcurrentHashMap<String,ViewResults>>
			nv = new ConcurrentHashMap<String, ConcurrentHashMap<String,ViewResults>>();
		ConcurrentHashMap<String, ConcurrentHashMap<String,ViewResults>>
			rv = viewResults.putIfAbsent(db, nv);
		if(rv == null)
			rv = nv;
		return rv;
	}

	/**
	* Returns a Map of Functions -> Views. Will create an entry
	* if no views exist
	*/
	protected ConcurrentHashMap<String,ViewResults> getResultEntries(String db, String docName) {
		ConcurrentHashMap<String, ConcurrentHashMap<String,ViewResults>>
			viewMap = getDbResultsEntries(db);

		ConcurrentHashMap<String,ViewResults>
			nv = new ConcurrentHashMap<String,ViewResults>();
		ConcurrentHashMap<String,ViewResults>
			rv = viewMap.putIfAbsent(docName, nv);
		if(rv == null)
			rv = nv;
		return rv;
	}

	/**
	* Deletes all view results for a db
	*/
	protected void removeResultEntries(String db) {
		ConcurrentHashMap<String, ConcurrentHashMap<String,ViewResults>> vrs = getDbResultsEntries(db);
		for(String k: vrs.keySet())
			removeResultEntries(db, k);
	}

	/**
	* Deletes all view results for a db/doc
	*/
	protected void removeResultEntries(String db, String docName) {
		ConcurrentHashMap<String,ViewResults> h = getDbResultsEntries(db).remove(docName);
		if(h != null)
			for(ViewResults v: h.values())
				v.destroyResults();
	}


	protected ViewResults getResultEntry(String db, String docName, String functionName) {
		Map<String,ViewResults> v = getResultEntries(db, docName);
		return v.get(functionName);
	}

	/*
	* @return The previous ViewResults, or null if there was none
	*
	*/
	protected ViewResults putResultEntry(String db, String docName, String functionName, ViewResults v) {
		Map<String,ViewResults> vm = getResultEntries(db, docName);
		return vm.put(functionName, v);
	}

	/*
	* @return The previous ViewResults, or null if there was none
	*/
	protected ViewResults putResultEntryIfAbsent(String db, String docName, String functionName, ViewResults v) {
		ConcurrentHashMap<String,ViewResults> vm = getResultEntries(db, docName);
		return vm.putIfAbsent(functionName, v);
	}


	protected ViewResults createViewResultsInstance(String db, String docName, String functionName, View view) {
		if(memeDB == null)
			throw new RuntimeException("no memeDB");
		String viewResultsClassStr = memeDB.getProperty(CONFIG_VIEWRESULTS_CLASS);
		if(viewResultsClassStr == null)
			throw new RuntimeException("Missing "+ CONFIG_VIEWRESULTS_CLASS + " property in config file");
		try {
			//ViewResults vm = (ViewResults) getClass().getClassLoader().loadClass(viewResultsClassStr).newInstance();

			ViewResults vm = (ViewResults) getClass().getClassLoader().loadClass(viewResultsClassStr).getConstructor(new Class[] {String.class, String.class, String.class, View.class}).newInstance(db,docName,functionName,view);
			vm.init(memeDB);
			return vm;
		} catch (InstantiationException e) {
			e.printStackTrace();
			throw new RuntimeException(e);
		} catch (IllegalAccessException e) {
			e.printStackTrace();
			throw new RuntimeException(e);
		} catch (ClassNotFoundException e) {
			e.printStackTrace();
			throw new RuntimeException(e);
		} catch (NoSuchMethodException e) {
			e.printStackTrace();
			throw new RuntimeException(e);
		} catch (InvocationTargetException e) {
			e.printStackTrace();
			throw new RuntimeException(e);
		}
	}

	/**
	* Returns an existing ViewResults object, or creates a new one for
	* the given view definition document and function name. The object
	* returned will have init() already called.
	* @throws ViewException if the ViewResults class is not found
	*/
	protected ViewResults updateOrCreateViewResults(String db, String docName, String functionName, View view) throws ViewException
	{
		log.debug("updateOrCreateViewResults");
		ViewResults vr = getResultEntry(db, docName, functionName);
		if(vr != null) {
			log.debug("updateOrCreateViewResults : had existing instance {}/{}/{}",db,docName,functionName);
			try {
				vr.setView(view);
				return vr;
			} catch(ViewException e) {}
			vr.destroyResults();
			vr = null;
		}

		ViewResults vrTmp = createViewResultsInstance(db, docName, functionName, view);

		File objSer = vrTmp.getInstanceFile();
		log.debug("updateOrCreateViewResults : creating new instance {}/{}/{} for path {}",db,docName,functionName, vrTmp.getInstanceFile());
		ObjectInputStream ois = null;
		try {
			ois = new ObjectInputStream(new FileInputStream(objSer));
			vr = (ViewResults) ois.readObject();
			log.debug("INSTANCE LOADED");
		} catch (ClassNotFoundException e) {
			throw new ViewException(e);
		} catch (Exception e) {
			vr = vrTmp;
		} finally {
			if (ois!=null) {
				try {
					ois.close();
				} catch (IOException e) {
				}
			}
		}
		vr.init(memeDB);
		ViewResults old = putResultEntryIfAbsent(db, docName, functionName, vr);
		return vr;
	}



	// still abstract
	abstract protected void addView(String db, String docId, String functionName, View instance) throws ViewException;
	abstract public boolean doesViewExist(String db, String view, String function);
	abstract public JSONObject getViewResults(String db, String view, String function, Map<String,String> options);
	abstract public void init(MemeDB memeDB) throws ViewException;
	abstract public void onDatabaseCreated(String db, long seq) throws ViewException;
	abstract public void onDatabaseDeleted(String db, long seq);
	abstract public void recalculateDocument(Document doc);
	abstract public void deletingDocument(String db, String id, long seqNo);
	abstract public void shutdown();

}