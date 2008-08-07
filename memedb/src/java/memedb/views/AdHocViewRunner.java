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

import java.util.Map;
import java.util.TreeSet;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import memedb.MemeDB;
import memedb.document.Document;
import memedb.utils.Logger;

class AdHocViewRunnerCollector implements MapResultConsumer {
	public TreeSet<JSONObject> results = new TreeSet<JSONObject>(new MapResultSorter());
	public int total = 0;
	public void onMapResult(Document doc, JSONObject result) {
		if(result == null || result == JSONObject.NULL)
			return;

		try {
			result.put("id", doc.getId());
			results.add(result);
			total++;
		} catch ( JSONException e ) {
		}
	}
}

/**
* Runs JavaScript views on the fly
* @author mbreese
* @author Russell Weir
**/
public class AdHocViewRunner {
	protected static Logger log = Logger.get("AdHocViewRunner");

	public static JSONObject adHocView(
			MemeDB memeDB,
			String db,
			String javaScriptMap,
			String javaScriptReduce,
			Map<String, String> options
			)
			throws ViewException
	{
		View view=new JavaScriptView(db, javaScriptMap, javaScriptReduce, false);
		log.debug("*** AdHocViewRunner Running map {}  reduce {}", javaScriptMap, javaScriptReduce);
		return runView(memeDB,db,null,null,view,options);
	}

	public static JSONObject runView(
			MemeDB memeDB,
			String db,
			String viewName,
			String functionName,
			View view,
			Map<String, String> options
			)
	{
		if (view==null) {
			return null;
		}
		view.setBackend(memeDB.getBackend());
		AdHocViewRunnerCollector c = new AdHocViewRunnerCollector();

		for (Document doc: memeDB.getBackend().allDocuments(db)) {
			view.map(c, doc);
		}

		if(options == null)
			options = new java.util.HashMap<String,String>();
// 		options.put("key", "cathy");
// 		options.put("startkey","\"apple\"");
// 		options.put("endkey", "\"cathy\"");
// 		options.put("endkey_inclusive", "true");
// 		options.put("descending", "true");
// 		options.put("count", "3");
		JSONArray results = new JSONArray(MapResultSorter.filter(c.results, options));

		JSONObject out = new JSONObject();
		if (viewName!=null) {
			out.put("view", viewName+"/"+functionName);
		}
		if(view.hasReduce() && !"true".equals(options.get("skip_reduce"))) {
			Object rv = view.reduce(results);
			out.put("ok", true);
			out.put("result", rv);
			out.put("total_rows", 0);
			out.put("rows", new JSONArray());
			out.put("reduced_rows", c.total);
		}
		else {
			out.put("total_rows", results.length());
			out.put("rows",results);
		}
		log.debug("*** AdHocViewRunner complete");
		return out;
	}
}
