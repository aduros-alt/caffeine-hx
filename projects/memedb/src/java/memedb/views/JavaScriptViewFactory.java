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

import java.util.HashMap;
import java.util.Map;

import org.json.JSONObject;

import memedb.document.JSONDocument;

/**
* JavaScriptViews are created from JSONDocuments structured like:<pre>
* {
*	"language": "java",
*	"views": {
*		"default": {
*			"map":"function(doc)..."
*		},
*		"sum_age": {
*			"map": "function(doc)...",
*			"reduce": "function(keyValue[])..."
*		}
*		"monthly_report" {
*			"map": "function(doc)...",
*			"lazy": true
*		}
*	}
* }
* </pre>
* @author Russell Weir
*/
@ViewType("javascript")
public class JavaScriptViewFactory implements ViewFactory {

	public Map<String, View> buildViews(JSONDocument doc) throws ViewException {

		JSONObject viewDefs = doc.getMetaData().getJSONObject("views");
		Map<String,View> views = new HashMap<String,View>();

		for (String k:viewDefs.keySet()) {
			boolean lazy = viewDefs.getJSONObject(k).optBoolean("lazy", false);
			String map = viewDefs.getJSONObject(k).getString("map");
			String reduce = viewDefs.getJSONObject(k).optString("reduce", null);

			if(map == null || !map.startsWith("function"))
				throw new ViewException("View "+k+" has no reduce function");
			if(reduce != null && !reduce.startsWith("function"))
				throw new ViewException("View "+k+" map function error");


			views.put(k, new JavaScriptView(doc.getDatabase(), map, reduce, lazy));
		}

		return views;
	}

}
