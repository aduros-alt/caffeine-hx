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

import java.io.InputStreamReader;
import java.io.IOException;

import javax.script.Invocable;
import javax.script.ScriptEngine;
import javax.script.ScriptEngineManager;
import javax.script.ScriptException;

import org.json.JSONException;
import org.json.JSONObject;
import org.json.JSONArray;

import memedb.backend.Backend;
import memedb.document.Document;
import memedb.document.JSONDocument;
import memedb.fulltext.FulltextException;
import memedb.utils.Logger;



/**
 *
 * Creates new JavaScript Views...
 *
 * This will create a new javascript engine for each view instance (not optimal, but without proper nested
 * ScriptContext's I'm not sure how else to do it).  This is <b>not thread-safe</b>.  It must be called from
 * a single ViewRunner to lower the overhead of having a JS Engine instance for each JavaScriptView instance.
 * <p>
 * The alternative is to have an engine (and initialize it) for each document... and that's even worse.
 * @author mbreese
 * @author Russell Weir
 */

@ViewType("javascript")
public class JavaScriptView implements View {
    /**
	 *
	 */
	private static final long serialVersionUID = 713522274681368650L;
	transient protected ScriptEngineManager manager = new ScriptEngineManager();
	transient protected ScriptEngine engine = null;

	transient protected Backend backend;
	transient protected Logger log = Logger.get(JavaScriptView.class);
	transient protected Logger scriptLogger = Logger.get("JavaScriptView:Script");

	protected String db;
	protected String map_src;
	protected String reduce_src;
	protected boolean lazy = false;

	private void readObject(java.io.ObjectInputStream in)
     throws IOException, ClassNotFoundException {
		in.defaultReadObject();
		log = Logger.get(JavaScriptView.class);
		scriptLogger = Logger.get("JavaScriptView:Script");
		try {
			setupEngine();
		} catch (ViewException e) {
			throw new IOException("Error setting up JavaScript engine", e);
		}
	}

	public JavaScriptView(String db, String map, String reduce, boolean isLazy) throws ViewException {
		this.db=db;
		this.map_src = map;
		if(reduce != null && !reduce.equals(""))
			this.reduce_src = reduce;
		else
			this.reduce_src = null;
		this.lazy = isLazy;
		setupEngine();
	}

	protected void setupEngine() throws ViewException {
		if (engine == null) {
			if(manager == null)
				manager = new ScriptEngineManager();
			engine = manager.getEngineByName("js");
			try {
				engine.eval(new InputStreamReader(getClass().getResourceAsStream("json.js")));
				engine.eval(new InputStreamReader(getClass().getResourceAsStream("jsrun.js")));
				engine.eval("_MemeDB_map="+map_src);
				if(reduce_src != null)
					engine.eval("_MemeDB_reduce="+reduce_src);
				engine.put("_MemeDB_JSVIEW",this);
			} catch (ScriptException e) {
				log.error(e);
				engine = null;
				throw new ViewException(e);
			}
		}
	}

	public void scriptLog(String v) {
		scriptLogger.info(v);
	}

	public void setBackend(Backend backend) {
		this.backend=backend;
	}

	public JSONObject get(String mydb, String id, String rev) {
		if (mydb==null) {
			mydb = this.db;
		}
		Document d = null;
		d = backend.getDocument(mydb, id, rev);
		if (d!=null) {
			if (d instanceof JSONDocument) {
				return new JSONObject(d.toString());
			}
			return new JSONObject().put("error", mydb+"/"+id+" is not a JSONDocument");
		}
		return null;
	}

	public boolean isLazy() {
		return lazy;
	}

	public void map(Document doc, MapResultConsumer listener, FulltextResultConsumer fulltextListener) {
		if(doc == null) {
			listener.onMapResult(doc, null);
			return;
		}
		FulltextResult ft = null;
		String json = null;
		try {
			ft = new FulltextResult(doc.getId(), doc.getRevision());
			engine.put("_MemeDB_FULLTEXT", ft);
//			engine.eval("_MemeDB_retval = '' ");
			engine.eval("_MemeDB_retval = new Array() ");

			Object docJSObject = engine.eval("_MemeDB_doc = eval('('+'"+ doc.toString()+"'+')');");

			Invocable invocable = (Invocable) engine;
			Object retval = invocable.invokeFunction("_MemeDB_map",docJSObject);
			if (retval != null) {
				json = (String) invocable.invokeFunction("toJSON",new Object[]{retval});
			} else {
				json = (String) engine.eval("_MemeDB_retval.toJSONString();");
			}
		} catch (ScriptException e) {
			e.printStackTrace();
		} catch (NoSuchMethodException e) {
			e.printStackTrace();
		} catch (JSONException e) {
			e.printStackTrace();
		} finally {
			/*
			if(listener != null) {
				if (json!=null && !json.equals("") && !json.equals("\"\"")) {
					listener.onMapResult(doc, new JSONObject(json));
				} else {
					listener.onMapResult(doc, null);
				}
			}
			*/
			if(listener != null) {
				try {
					log.warn("Map results: {}", json);
					JSONArray ja = new JSONArray(json);
//					if(ja.length() == 0) {
//						listener.onMapResult(doc, null);
//					}
					listener.onMapResult(doc, ja);
				} catch (JSONException e) {
					log.warn("Javascript view returned object that is not an array {}", json);
				}
			}
			if(fulltextListener != null) {
				try {
					if(ft.hasResult()) {
						fulltextListener.onFulltextResult(doc, ft.getDocument());
					} else {
						fulltextListener.onFulltextResult(doc, null);
					}
				} catch(FulltextException e) {
					log.warn("Error running fulltext engine for doc {} : {}", doc.getId(), e);
				}
			}
		}
	}

	public boolean hasReduce() {
		return reduce_src != null;
	}

	public Object reduce(JSONArray results) {
		if(engine == null || results == null)
			return null;
		try {
			Object resultsJSObject = engine.eval("_MemeDB_results = eval('('+'"+ results.toString()+"'+')');");

			Invocable invocable = (Invocable) engine;
			Object retval = invocable.invokeFunction("_MemeDB_reduce",resultsJSObject);
			if (retval != null) {
				return retval;
			}

		} catch (ScriptException e) {
			e.printStackTrace();
		} catch (NoSuchMethodException e) {
			e.printStackTrace();
		} catch (JSONException e) {
			e.printStackTrace();
		}
		return null;
	}

	public String getMapSrc() {
		return map_src;
	}

	public String getReduceSrc() {
		return reduce_src;
	}
}
