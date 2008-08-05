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
import java.util.HashMap;
import java.util.Map;
import java.util.Iterator;

import org.json.JSONObject;

import memedb.MemeDB;
import memedb.document.Document;
import memedb.document.JSONDocument;
import memedb.utils.Logger;

/**
 * This view manager is very simple... it reruns each view upon request (basically adhoc style)
 * It also serializes each Java view object (named /basedir/_view_name/function_name/view.obj),
 * which is how it persists whether or not a view exists...
 * @author mbreese
 */
public class SimpleViewManager extends ViewManager {
	protected MemeDB memeDB;
	protected Logger log = Logger.get(SimpleViewManager.class);

	protected File baseDir;
	protected Map<String,View> views = new HashMap<String,View>();

	protected final static String VIEW_INSTANCE_NAME = "view.obj";

	public SimpleViewManager(){
	}

	/* (non-Javadoc)
	 * @see memedb.views.ViewManager#init()
	 */
	public void init(MemeDB memeDB) throws ViewException {
		this.memeDB=memeDB;
		baseDir = new File(memeDB.getProperty("view.simple.path"));
		if (baseDir==null) {
			throw new RuntimeException("Could not open SimpleViewManager path (view.simple.dir)");
		}
		if (!baseDir.exists()) {
			baseDir.mkdirs();
		}
		//Document d = memeDB.getBackend().getDocument("_views", "list");
		for (String db : memeDB.getBackend().getDatabaseNames()) {
			log.debug("Loading views for: {}", db);
			loadViewsForDatabase(db);
		}
	}

	/* (non-Javadoc)
	 * @see memedb.views.ViewManager#shutdown()
	 */
	public void shutdown() {

	}

	protected File viewDbDir(String db) {
		return new File(baseDir,db);
	}

	protected File viewDir(String db, String viewName) {
		return new File(viewDbDir(db),viewName);
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
						try {
							ois = new ObjectInputStream(new FileInputStream(new File(functionDir,VIEW_INSTANCE_NAME)));
							log.debug("Loading view {}/{}/{} ",db,instanceDir.getName(),functionDir.getName());
							views.put(db+"/"+instanceDir.getName()+"/"+functionDir.getName(),(View) ois.readObject());
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

	/* (non-Javadoc)
	 * @see memedb.views.ViewManager#addView(memedb.document.Document)
	 */
	public void addView(JSONDocument jsondoc) throws ViewException {
			String language = (String) jsondoc.get("language");
			JSONObject joviews = (JSONObject) jsondoc.get("views");
			if(joviews == null)
				throw new ViewException("views field not properly formatted");

			if (language == null || language.equals("javascript")) {
				Iterator it = joviews.keys();
				while (it.hasNext()) {
					String name = (String)it.next();
					JSONObject funcs = (JSONObject) joviews.get(name);
					String map = funcs.optString("map", null);
					String reduce = funcs.optString("reduce", null);
					boolean isLazy = funcs.optBoolean("lazy", false);
					if(map == null || !map.startsWith("function"))
						throw new ViewException("View "+name+" has no reduce function");
					if(reduce != null && !reduce.startsWith("function"))
						throw new ViewException("View "+name+" map function error");

					log.debug("Adding javascript view: {}/{}/{} => {}",
								jsondoc.getDatabase(),
								jsondoc.getId(),
								name,
								jsondoc.get(name)
					);
					addView(jsondoc.getDatabase(),
							jsondoc.getId(),
							name,
							new JavaScriptView(jsondoc.getDatabase(), map, reduce, isLazy)
					);
				}
			} else if (language.startsWith("java:")){
				log.debug("Adding java view: {}/{} => {}", jsondoc.getDatabase(),jsondoc.getId(),language);
				try {
					Class clazz = Thread.currentThread().getContextClassLoader().loadClass(language.substring(5));
					addView(jsondoc.getDatabase(),jsondoc.getId(),DEFAULT_FUNCTION_NAME,(View) clazz.newInstance());
				} catch (ClassNotFoundException e) {
					throw new ViewException(e);
				} catch (ViewException e) {
					throw new ViewException(e);
				} catch (InstantiationException e) {
					throw new ViewException(e);
				} catch (IllegalAccessException e) {
					throw new ViewException(e);
				}
			} else {
				log.warn("Don't know how to handle view type: {}\n{}", language,jsondoc.toString());
			}
	}

	protected View getView(String db, String view, String function) {
		return views.get(db+"/"+view+"/"+function);
	}

	public JSONObject getViewResults(String db, String viewName, String function, Map<String,String> options)
	{
		return AdHocViewRunner.runView(memeDB,db,viewName,function,getView(db,viewName,function),options);
	}

	public void recalculateDocument(Document doc) {
		// this manager recalculates all views on the fly... so this isn't needed.
		// but we still need to add new views!

		if (doc.getId().startsWith("_") && doc instanceof JSONDocument) {
			try {
				addView((JSONDocument) doc);
			} catch (ViewException e) {
				log.error("Error adding new view: {}",doc.getId(),e);
			}
		}
	}

	public void deletingDocument(String db, String id, long seqNo) {
		if(id.startsWith("_"))
			removeView(db, id);
	}

	public void onDatabaseCreated(String db, long seqNo) throws ViewException {
		File viewDir = viewDbDir(db);
		viewDir.mkdirs();
		addView(db,"_all_docs",DEFAULT_FUNCTION_NAME,new AllDocuments(db));
	}

	protected void addView(String db, String view, String function,View instance) throws ViewException {
		File viewDir = new File(viewDir(db,view), function);
		if (!viewDir.exists()) {
			viewDir.mkdirs();
		}
		ObjectOutputStream oos =null;
		try {
			oos = new ObjectOutputStream(new FileOutputStream(new File(viewDir,VIEW_INSTANCE_NAME)));
			oos.writeObject(instance);
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
		views.put(db+"/"+view+"/"+function,instance);
	}


	public void onDatabaseDeleted(String db, long seqNo) {
		recursivelyDeleteFiles(viewDbDir(db));
	}

	private void recursivelyDeleteFiles(File file) {
		if (file.isDirectory()) {
			for (File f:file.listFiles()) {
				recursivelyDeleteFiles(f);
			}
		}
		file.delete();
	}

	public boolean doesViewExist(String db, String view, String function) {
		return views.containsKey(db+"/"+view+"/"+function);
	}

	public void removeView(String db, String id) {
	}

}
