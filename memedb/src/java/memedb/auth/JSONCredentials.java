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

package memedb.auth;

import memedb.document.Document;
import memedb.document.JSONDocument;

import org.json.JSONException;
import org.json.JSONObject;

/**
 *
 * @author Russell Weir
 */
public abstract class JSONCredentials extends Credentials {
	protected final Document doc;
	protected final JSONObject defaults;
	protected final JSONObject db_access;
	
	public JSONCredentials(JSONDocument doc, String token, int timeout) {
		super(doc.getId(), token, (Boolean)doc.get("is_sa"), timeout);
		this.doc = doc;
		JSONObject defj = null;
		JSONObject dbj = null;
		try {
			defj = (JSONObject) doc.get("defaults");
		} catch(JSONException e) {			
		}
		try {
			dbj = (JSONObject) doc.get("db_access");
		} catch(JSONException e) {
		}
		this.defaults = defj;
		this.db_access = dbj;
	}
	
	public JSONCredentials(JSONDocument doc, String token, boolean isSA, int timeout) {
		super(doc.getId(), token, isSA, timeout);
		this.doc = doc;
		JSONObject defj = null;
		JSONObject dbj = null;
		try {
			defj = (JSONObject) doc.get("defaults");
		} catch(JSONException e) {			
		}
		try {
			dbj = (JSONObject) doc.get("db_access");
		} catch(JSONException e) {
		}
		this.defaults = defj;
		this.db_access = dbj;		
	}
	
	protected boolean getPerm(String db, String tag, boolean defaultValue) {
		return getDbPerm(db, tag, getDefaultPerm(tag, defaultValue));
	}
	
	protected boolean getDefaultPerm(String tag, boolean defaultValue) {
		if(defaults == null)
			return defaultValue;
		return defaults.optBoolean(tag, defaultValue);
	}
	
	protected boolean getDbPerm(String db, String tag, boolean defaultValue) {
		if(db_access == null)
			return defaultValue;
		JSONObject dbo = db_access.optJSONObject(db);
		if(dbo == null)
			return defaultValue;
		return dbo.optBoolean(tag, defaultValue);
	}
	
	protected boolean getViewPerm(String db, String id, boolean defaultValue) {
		return getDbViewPerm(db, id, getDefaultViewPerm(id, defaultValue));
	}
	
	protected boolean getDefaultViewPerm(String id, boolean defaultValue) {
		if(defaults == null)
			return defaultValue;
		JSONObject va = defaults.optJSONObject("view_access");
		if(va == null) 
			return defaultValue;
		return va.optBoolean(id, defaultValue);
	}
	
	protected boolean getDbViewPerm(String db, String id, boolean defaultValue) {
		if(db_access == null)
			return defaultValue;
		JSONObject dbo = db_access.optJSONObject(db);
		if(dbo == null)
			return defaultValue;
		JSONObject va = dbo.optJSONObject("view_access");
		return va.optBoolean(id, defaultValue);
	}
}
