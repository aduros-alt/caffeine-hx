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

import java.io.Writer;
import java.util.HashMap;
import java.util.Map;

import memedb.MemeDB;
import memedb.document.Document;
import memedb.document.JSONDocument;
import memedb.utils.Logger;

import org.json.JSONObject;

/**
 *
 * View urls are in the form of: /db/_view/viewname
 *
 * View results are generated for each document when it is updated.
 * The main engine is notified about the update and the engine notifies the ViewManager.
 *
 * The view manager then processes the document through all the views for the enclosing database.
 * If the view returns a result, that result is appended to the cached results file for that view.
 *
 * Oh yeah, there is a cached results file for all views.
 *
 * There is also an index for all views that contains two things:
 * 1) a sorted list of keys
 * 2) the position in the cached results file where the cached data is located.
 *
 * This allows for appending of data to the cached results file, while only having to re-sort the index.
 * This is a much lighter weight operation.  The newly sorted index is only written if there are no pending
 * requests... basically, requests for results will place a Lock on the View.  The cached results can be optimized
 * for sequential access, but this isn't required.
 *
 * Views can be handled by anything that implements the View interface.  This includes javascript
 * CouchDB style views.  If the "type" of view is 'text/javascript', then the javascript handler is used.
 * Otherwise, the 'type' is assumed to be a fully-qualified class name.
 * @author mbreese
 * @author Russell Weir
 */
abstract public class ViewManager {
	protected final Logger log = Logger.get(getClass());
	public final static String DEFAULT_FUNCTION_NAME = "default";

	protected Map<String,ViewFactory> factories = new HashMap<String,ViewFactory> ();
	{
		factories.put("java", new JavaViewFactory());
		factories.put("javascript", new JavaScriptViewFactory());
	}

	/**
	* Add a view set
	*/
	public void addView(JSONDocument doc) throws ViewException {
		log.info("addView {}", doc.getId());
		String language = (String) doc.get("language");
		for (String key:factories.keySet()) {
			if (key.equals(language)) {
				Map<String,View> views = factories.get(key).buildViews(doc);
				for (String viewFunction:views.keySet()) {
					addView(doc.getDatabase(),doc.getId(),viewFunction,views.get(viewFunction));
				}
				return;
			}
		}
		throw new ViewException("Don't know how to handle view type: "+language+" =>"+doc.toString(2));
	}

	/**
	* Internal handler for each function set in a JSONDocument.
	*/
	abstract protected void addView(String db, String docId, String functionName, View instance) throws ViewException;

	/**
	*	Called when a document is being deleted from the database. The
	*	Document should still exist if it existed to begin with.
	*/
	abstract public void deletingDocument(String db, String id, long seq);

	/**
	* Returns true if the view.function pair exists
	*/
	abstract public boolean doesViewExist(String db, String view, String function);

	/*
	 * Returns the current results the view.
	 * @param db Database name
	 * @param view View document name (_exampleview)
	 * @param function Function name within view doc
	 * @param options View filtering options
	 * @return JSONObject populated with results of map or map/reduce
	 * @throws memedb.views.ViewException If the view does not exist, or there is an error processing
	 * @deprecated Out of memory error possible on huge sets
	 */
//	abstract public JSONObject getViewResults(String db, String view, String function, Map<String,String> options) throws ViewException;
	
	/**
	 * Writes view results as a JSON string directly to Writer target
	 * @param writer Writer target
	 * @param db Database name
	 * @param view View document name (_exampleview)
	 * @param function Function name within view doc
	 * @param options View filtering options
	 * @throws memedb.views.ViewException If the view does not exist, or there is an error processing
	 */
	abstract public void getViewResults(Writer writer, String db, String view, String function, Map<String,String> options) throws ViewException;
	
	/**
	* System startup initialization phase.
	*/
	abstract public void init(MemeDB memeDB) throws ViewException;

	/**
	*	Called when a database is created
	*/
	abstract public void onDatabaseCreated(String db, long seq) throws ViewException;

	/**
	*	Called when a database is dropped
	*/
	abstract public void onDatabaseDeleted(String db, long seq);


	/**
	*	Called after a document has been added to the database.
	*/
	abstract public void onDocumentUpdate(Document doc);


	/**
	* Cleanup/save any data before MemeDB goes offline
	*/
	abstract public void shutdown();


}
