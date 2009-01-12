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

import org.json.JSONException;
import org.json.JSONObject;
import org.json.JSONArray;

import memedb.backend.Backend;
import memedb.document.Document;
import memedb.utils.Logger;

public class AllDocuments implements View {
	transient Logger log = Logger.get(AllDocuments.class);
	/**
	 *
	 */
	private static final long serialVersionUID = -7212009333888358060L;
	protected String db;
	public AllDocuments(String db) {
		log.debug("Creating AllDocuments view for db: {}", db);
		this.db=db;
	}

	public boolean isLazy() { return false; }
	
	public void map(Document doc, MapResultConsumer listener, FulltextResultConsumer fulltextListener) {
		JSONArray ja = new JSONArray();
		JSONArray res = new JSONArray();
		try {
			res.put(doc.getId());
			JSONObject v = new JSONObject();
			v.put("_id", doc.getId());
			v.put("_rev", doc.getRevision());
			res.put(v);
			ja.put(res);
		} catch (JSONException e) {
			e.printStackTrace();
		}
		listener.onMapResult(doc, ja);
	}

	public void setBackend(Backend backend) {
		// not needed
	}

	public boolean hasReduce() { return false; }
	public Object reduce(JSONArray results) {
		return new Long(results.length());
	}

	public String getMapSrc() {
		return "";
	}

	public String getReduceSrc() {
		return "";
	}
}
