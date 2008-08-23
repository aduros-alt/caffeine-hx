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

package memedb.backend;

import java.io.File;
import java.lang.ref.WeakReference;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Queue;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentLinkedQueue;

import org.json.JSONArray;

import memedb.MemeDB;
import memedb.document.Document;
import memedb.utils.Lock;


/**
 * Caching backend that operates on a Least Recently Used basis.  It will store X number of Documents
 * by revision.  Only one revision per document is stored.  This class must be backed by a persistent
 * Backend that this class can use to save / retrieve uncached entries.  When necessary, this class will
 * access the backing store using the RootCredentials, otherwise access is based upon the calling
 * credentials.
 * <p>
 * The use of a ConcurrentLinkedQueue to store the LRU data and a ConcurrentHashMap to store the cached Documents
 * makes this class thread-safe.
 * <p>
 * Cached items are stored as weak references, allowing them to be garbage collected if needed.  This will let
 * the JVM adjust the size of the cache if more memory is needed.
 * <p>
 * Configuration settings in memedb.properties:<br>
 * backend.cache.class - the fully qualified class name of the backing class<br>
 * backend.cache.size - the number of documents to cache (default: 5000)<br>
 * sa.username - the username for ROOT access (req'd if not default)<br>
 * sa.password - the password for ROOT access (req'd if not default)<br>
 * @author mbreese
 * @author Russell Weir
 */
public class LRUCachingBackend implements Backend {
	public static final String BACKEND_CACHE_SIZE = "backend.cache.size";
	public static final String BACKING_CLASS = "backend.cache.class";

	protected Backend backend;

	protected Set<String> databaseNames = null;

	protected int cacheMax = 5000;

	protected Queue<String> lru = new ConcurrentLinkedQueue<String> ();
	protected Map<String,WeakReference<Document>> cache = new ConcurrentHashMap<String,WeakReference<Document>>();

	public LRUCachingBackend() {
	}

	public void init(MemeDB memeDB) {
		backend.init(memeDB);
		String backendClassName=memeDB.getProperty(BACKING_CLASS);
		if (backendClassName == null) {
			throw new RuntimeException("Missing "+BACKING_CLASS+" value");
		}
		Class backendClass;
		try {
			backendClass = getClass().getClassLoader().loadClass(backendClassName);
			this.backend = (Backend) backendClass.newInstance();
		} catch (ClassNotFoundException e) {
			throw new RuntimeException(e);
		} catch (InstantiationException e) {
			throw new RuntimeException(e);
		} catch (IllegalAccessException e) {
			throw new RuntimeException(e);
		}

		if (memeDB.getProperty(BACKEND_CACHE_SIZE)!=null) {
			try {
				this.cacheMax=Integer.parseInt(memeDB.getProperty(BACKEND_CACHE_SIZE));
			} catch (NumberFormatException e) {
				throw new RuntimeException("Error in "+BACKEND_CACHE_SIZE+" setting",e);
			}
		}

		this.databaseNames = backend.getDatabaseNames();
	}

	public void shutdown() {
		backend.shutdown();
	}



	public long addDatabase(String name) throws BackendException{
		long rv = backend.addDatabase(name);
		databaseNames = backend.getDatabaseNames();
		return rv;
	}

	public Iterable<Document> allDocuments(final String db){
		return getDocuments(db,null);
	}

	public long deleteDatabase(String name) throws BackendException {
		long rv = backend.deleteDatabase(name);
		List<String> keysToRemove = new ArrayList<String>();
		for (String key: lru)
		{
			if (key.startsWith(name+"/")) {
				keysToRemove.add(key);
			}
		}
		for (String key: keysToRemove) {
			lru.remove(key);
			cache.remove(key);
		}
 		databaseNames = backend.getDatabaseNames();
		return rv;
	}

	public void deleteDocument(String db, String id) throws BackendException {
		try {
			backend.deleteDocument(db, id);
			remove(db,id);
		} catch (BackendException e) {
			throw e;
		}
	}

	public boolean doesDatabaseExist(String db) {
		return backend.doesDatabaseExist(db);
	}

	public boolean doesDocumentExist(String db, String id) {
		if (lru.contains(key(db,id))) {
			return true;
		}
		return backend.doesDocumentExist(db, id);
	}

	public boolean doesDocumentRevisionExist(String db, String id, String revision) {
		if (lru.contains(key(db,id))) {
			WeakReference<Document> ref =cache.get(key(db,id));
			if (ref!=null && ref.get()!=null) {
				if (ref.get().getRevision().equals(revision)) {
					return true;
				}
			}
		}
		return backend.doesDocumentRevisionExist(db, id,revision);
	}

	public Long getDatabaseCreationSequenceNumber(String db) {
		return backend.getDatabaseCreationSequenceNumber(db);
	}
		
	public Set<String> getDatabaseNames(){
		return databaseNames;
	}

	public Map<String, Object> getDatabaseStats(String name) {
		return backend.getDatabaseStats(name);
	}

	public Document getDocument(String db, String id){
		return getDocument(db,id,null);
	}

	public Document getDocument(String db, String id, String rev){
		return get(db,id,rev);
	}

	public Long getDocumentCount(String db) {
		return backend.getDocumentCount(db);
	}
	
	public JSONArray getDocumentRevisions(String db, String id){
		return backend.getDocumentRevisions(db,id); // no way to cache them all :)
	}

	public Iterable<Document> getDocuments(final String db, final String[] ids) {
		return backend.allDocuments(db); // no way to cache them all :)
	}

	public MemeDB getMeme() {
		return backend.getMeme();
	}

	public File getRevisionFilePath(Document doc) throws BackendException {
		return backend.getRevisionFilePath(doc);
	}

	public Lock lockForUpdate(String db,String id) throws BackendException {
		return backend.lockForUpdate(db, id);
	}

	public Document saveDocument(Document doc) throws BackendException{
		Document saved = backend.saveDocument(doc);
		add(saved);
		return saved;
	}

	public Document saveDocument(Document doc, Lock lock) throws BackendException
	{
		Document saved = backend.saveDocument(doc, lock);
		add(saved);
		return saved;
	}

	public boolean touchRevision(String database, String id, String rev) {
		return backend.touchRevision(database, id, rev);
	}





	protected void add(Document doc) {
		lru.add(key(doc.getDatabase(),doc.getId()));
		cache.put(key(doc.getDatabase(),doc.getId()),new WeakReference<Document>(doc));
		trim();
	}

	protected Document get(String db, String id, String revision) {
		if (lru.contains(key(db,id))) {
			WeakReference<Document> ref=cache.get(key(db,id));
			if (ref!=null && ref.get()!=null) {
				Document doc = ref.get();
				if (revision == null) {
					lru.remove(key(db,id));
					lru.add(key(db,id));
					return doc;
				} else if (doc.getRevision().equals(revision)) {
					lru.remove(key(db,id));
					lru.add(key(db,id));
					return doc;
				} else {
					// do nothing... if we don't have the proper revision, we need to retrieve it below
					// this is just a cache miss.
				}
			}
		}

		Document doc = backend.getDocument(db, id,revision);
		add(doc);
		return doc;
	}

	protected String key(String db, String id) {
		return db+"/"+id;
	}

	protected void remove(String db, String id) {
		lru.remove(key(db,id));
		cache.remove(key(db,id));
	}

	protected void trim() {
		while (lru.size()>cacheMax) {
			String key = lru.remove();
			cache.remove(key);
		}
	}

}
