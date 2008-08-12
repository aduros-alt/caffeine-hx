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
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
import java.util.Deque;
import java.util.List;
import java.util.HashMap;
import java.util.Map;
import java.util.Iterator;
import java.util.concurrent.ConcurrentHashMap;
// import java.util.concurrent.atomic.AtomicLong;
import javax.servlet.http.HttpServletResponse;

import org.json.JSONObject;
import org.json.JSONArray;

import memedb.MemeDB;
import memedb.document.Document;
import memedb.document.JSONDocument;
import memedb.utils.Logger;
import memedb.utils.FileUtils;

/**
* The AdvancedViewManager is able to use a variety of plugin ViewResults
* managers, with any type of provided Views.
* @author Russell Weir
*/
public class AdvancedViewManager extends BaseViewManager {
	protected static final String TEXT_PLAIN_MIMETYPE = "text/plain;charset=utf-8";
	protected final static String PATH_PROPERTY = "view.inmemory.path";
	protected final static String VIEW_INSTANCE_NAME = "view.obj";

	protected File baseDir;

	public AdvancedViewManager(){
	}

	synchronized public void deletingDocument(String db, String id, long seqNo) {
		log.debug("deletingDocument {}/{} seq {}",db,id,seqNo);
		if(!inOrder(seqNo)) {
			postEvent(new deleteDocEvent(this, db, id, seqNo));
			return;
		}

		if(id.startsWith("_")) {
			if(!id.equals("_all_docs"))
				removeView(db, id);
		}
		for(String docName: getDbViewEntries(db).keySet()) {
			for(String k: getViewEntries(db, docName).keySet()) {
				ViewResults vr = getResultEntry(db, docName, k);
				if(vr != null) {
					if(!vr.getView().isLazy())
						vr.removeResult(id, seqNo);
				}
			}
		}
	}

	public boolean doesViewExist(String db, String view, String function) {
		return getViewEntry(db, view, function) != null;
	}

	public JSONObject getViewResults(String db, String docId, String functionName, Map<String,String> options) throws ViewException {
		log.debug("getViewResults {}/{}", docId, functionName);
		if(docId.equals("_all_docs")) {
			log.debug("Running adHocView");
			return AdHocViewRunner.runView(memeDB,db,docId,functionName,getViewEntry(db,docId,functionName),options);
		}
		JSONObject o = new JSONObject();
		JSONArray rows = new JSONArray();
		long count = 0;

		View v = getViewEntry(db, docId, functionName);
		if(v == null)
			throw new ViewException("View object does not exist");
		
		ViewResults vr = getResultEntry(db,docId,functionName);
		if(vr == null)
			throw new ViewException("ViewResults object does not exist");
		
		List<JSONObject> d = vr.subList(options);
		count = d.size();
		rows = new JSONArray(d);

		if(v.hasReduce() && !"true".equals(options.get("skip_reduce"))) {
			Object vo = v.reduce(rows);
			if(vo != null) {
				count = 1;
				o.put("ok", true);
				o.put("result", vo);
			} else {
				o.put("ok", false);
				o.put("result", JSONObject.NULL);
			}
			o.put("rows", new JSONArray());
			o.put("reduced_rows", d.size());
		} else
			o.put("rows", rows);
		
		o.put("total_rows", count);
//		o.put("offset", 0);


		log.debug("AdvancedViewManager::getViewResults : {}", o.toString(2));
		return o;
	}

	public void getViewResults(HttpServletResponse response, String db, 
			String docId, String functionName, Map<String,String> options) 
			throws ViewException
	{
		log.debug("getViewResults {}/{}", docId, functionName);
		java.io.Writer writer = null;
		try {
			writer = response.getWriter();
		} catch(IOException e) {
			throw new ViewException("response writer invalid");
		}
		if(docId.equals("_all_docs")) {
			log.debug("Running adHocView");
			return;
			//return AdHocViewRunner.runView(memeDB,db,view,functionName,getViewEntry(db,docId,functionName),options);
		}

		int count = 0;
		View v = getViewEntry(db, docId, functionName);
		if(v == null)
			throw new ViewException("View object does not exist");
		
		ViewResults vr = getResultEntry(db,docId,functionName);
		if(vr == null)
			throw new ViewException("ViewResults object does not exist");
		
		try {
			response.setStatus(200);
			response.setContentType(TEXT_PLAIN_MIMETYPE);
			if(!v.hasReduce() || "true".equals(options.get("skip_reduce"))) {
				writer.write("{ \"ok\": true, \"rows\": [");
				count = vr.writeRows(response.getWriter(), options);
				writer.write("], \"total_rows\": " + count + "}");
			}
			else {
				JSONObject o = new JSONObject();
				o.put("ok", true);
				o.put("result", vr.reduce(options));
				o.put("rows", new JSONArray());
				o.write(writer);
			}
		} catch (IOException e) {
			log.error(e);
		} 
	}
	
	/* (non-Javadoc)
	 * @see memedb.views.ViewManager#init()
	 */
	public void init(MemeDB fdb) throws ViewException {
		log = Logger.get(AdvancedViewManager.class);
		log.debug("************************* InMemoryViewResults initialize");
		memeDB=fdb;
		baseDir = new File(memeDB.getProperty(PATH_PROPERTY));
		if (baseDir==null) {
			throw new RuntimeException("Could not open AdvancedViewManager path (view.simple.dir)");
		}
		if (!baseDir.exists()) {
			baseDir.mkdirs();
		}
		startMonitor();

		for (String db : memeDB.getBackend().getDatabaseNames()) {
			log.debug("Loading views for: {}", db);
			loadViewsForDatabase(db);
		}

		nextSequenceNumber.set(memeDB.getState().getCurrentSequenceNumber() + 1);

		log.debug("************************* InMemoryViewResults initialize complete");
	}

	/*
	 * Database was created.
	 */
	public synchronized void onDatabaseCreated(String db, long seqNo) throws ViewException {
		if(!inOrder(seqNo)) {
			postEvent(new addDbEvent(this, db, seqNo));
			return;
		}
		File viewDir = viewDbDir(db);
		viewDir.mkdirs();
		addView(db,"_all_docs",DEFAULT_FUNCTION_NAME,new AllDocuments(db));
	}

	public synchronized void onDatabaseDeleted(String db, long seqNo) {
		if(!inOrder(seqNo)) {
			postEvent(new deleteDbEvent(this, db, seqNo));
			return;
		}
		removeResultEntries(db);
		removeViewEntries(db);
		recursivelyDeleteFiles(viewDbDir(db));
	}

/*
	protected void postEvent(BaseEvent be) {
		log.info("Event with seqNo {} does not match {}", be.getSequence(), nextSequenceNumber);
		super.postEvent(be);
		throw new RuntimeException("Arg");
	}
*/

	synchronized public void recalculateDocument(Document doc) {
		log.info("recalculateDocument {} seqNo: {}", doc.getId(), doc.getSequence());

		if(!inOrder(doc.getSequence())) {
			postEvent(new addDocEvent(this, doc));
			return;
		}

		if (doc.getId().startsWith("_") && doc instanceof JSONDocument) {
			try {
				addView((JSONDocument) doc);
			} catch (ViewException e) {
				log.error("Error adding new view: {}",doc.getId(),e);
			}
		}

		String db = doc.getDatabase();
		for(String docName: getDbViewEntries(db).keySet()) {
			for(String k: getViewEntries(db, docName).keySet()) {
				View view = getViewEntry(db, docName, k);
				if(view == null)
					continue;

				if(view.isLazy()) {
					log.debug("\tNot indexing view {}. Lazy execution.", k);
					continue;
				}
				ViewResults vr = getResultEntry(db, docName, k);
				vr.addResult(doc);
			}
		}
	}

	/* (non-Javadoc)
	 * @see memedb.views.ViewManager#shutdown()
	 */
	public synchronized void shutdown() {
		log.info("Shutting down ViewManager");
		if(monitor != null)
			monitor.interrupt();
		for(String db: views.keySet()) {
			for(String docName: getDbViewEntries(db).keySet()) {
				Map<String,View> ve = getViewEntries(db, docName);
				for(String functionName: ve.keySet()) {
					View view = ve.get(functionName);
					ViewResults vr = getResultEntry(db, docName, functionName);
					if(view == null) continue;
					File viewDir = new File(viewDir(db,docName), functionName);
					vr.shutdown();
					try {
						writeViewObject(viewDir, view);
					} catch(Exception e) {
						log.error("Error saving view defs for {}/{}/{} {}", db, docName, functionName, e.getMessage());
					}
				}
			}
		}
	}


	/////////////////////////////////////
	//      Protected methods          //
	/////////////////////////////////////

	protected synchronized void addView(String db, String docName, String functionName, View view) throws ViewException {
		log.debug("Adding new view {} {} {}", db, docName, functionName);
		ViewResults vr = updateOrCreateViewResults(db, docName, functionName, view);
		if(vr == null)
			throw new ViewException("Unable to create ViewResults");
		File functionDir = new File(viewDir(db,docName), functionName);

		writeViewObject(functionDir, view);
		view.setBackend(memeDB.getBackend());
		putViewEntry(db, docName, functionName, view);
		putResultEntry(db, docName, functionName, vr);

		if(!vr.isAlive())
			vr.start();
	}

	protected final boolean inOrder(long seqNo) {
		log.debug("next: {} seqNo: {}", nextSequenceNumber, seqNo);
		return nextSequenceNumber.compareAndSet(seqNo, seqNo+1);
	}

	protected void loadViewsForDatabase(String db) throws ViewException {
		File viewDbDir = viewDbDir(db);
		if (!viewDbDir.exists()) {
			onDatabaseCreated(db, -1);
		} else {
			for(File instanceDir:viewDbDir.listFiles()) {
				if (instanceDir.isDirectory()) {
					for (File functionDir: instanceDir.listFiles()) {
						ObjectInputStream ois =null;
						String docName = null;
						String functionName = null;
						View v = null;
						try {
							docName = FileUtils.fsDecode(instanceDir.getName());
							functionName = FileUtils.fsDecode(functionDir.getName());
						} catch(Exception e) {
							throw new RuntimeException(e);
						}
						try {
							log.debug("Loading view {}/{}/{} ", db, docName, functionName);
							ois = new ObjectInputStream(new FileInputStream(new File(functionDir,VIEW_INSTANCE_NAME)));
							v = (View) ois.readObject();
							v.setBackend(memeDB.getBackend());

							ViewResults vr = updateOrCreateViewResults(db, docName, functionName, v);
							vr.init(memeDB);
							putResultEntry(db, docName, functionName, vr);
							putViewEntry(db, docName, functionName, v);
							vr.start();
						} catch (FileNotFoundException e) {
							throw new ViewException(e);
						} catch (IOException e) {
							throw new ViewException(e);
						} catch (ClassNotFoundException e) {
							throw new ViewException(e);
						} finally {
							if (ois!=null) {
								try {
									ois.close();
								} catch (IOException e) {
								}
							}
						}
					}
				}
			}
		}
	}

	protected synchronized void removeView(String db, String id) {
		File viewDir = viewDir(db, id);
		removeViewEntries(db, id);
		removeResultEntries(db, id);
		recursivelyDeleteFiles(viewDir);
		log.info("View {}/{} removed from {}: {} : {}", db, id, viewDir.toString(), views, viewResults);
	}



	private void recursivelyDeleteFiles(File file) {
		if (file.isDirectory()) {
			for (File f:file.listFiles()) {
				recursivelyDeleteFiles(f);
			}
		}
		file.delete();
	}

	protected File viewDbDir(String db) {
		return new File(baseDir, FileUtils.fsEncode(db));
	}

	protected File viewDir(String db, String viewName) {
		return new File(viewDbDir(db), FileUtils.fsEncode(viewName));
	}

	protected void writeViewObject(File viewDir, View view) throws ViewException
	{
		if (!viewDir.exists()) {
			viewDir.mkdirs();
		}
		ObjectOutputStream oos =null;
		File fv = new File(viewDir,VIEW_INSTANCE_NAME);
		try {
			oos = new ObjectOutputStream(new FileOutputStream(fv));
			oos.writeObject(view);
			oos.close();
		} catch (FileNotFoundException e) {
			try { fv.delete(); } catch(Exception ed) {}
			throw new ViewException(e);
		} catch (IOException e) {
			try { fv.delete(); } catch(Exception ed) {}
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
}
