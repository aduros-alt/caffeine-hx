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

package memedb.httpd;

import java.io.IOException;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.json.JSONObject;
import org.json.JSONException;

import memedb.auth.Credentials;
import memedb.fulltext.FulltextException;

/**
 *
 * Handles GET with no leading _ for db, id == _text_query
 *
 */
public class FulltextQuery extends BaseRequestHandler {

	@SuppressWarnings("unchecked")
	public void handleInner(Credentials credentials, HttpServletRequest request, HttpServletResponse response, String db, String id, String rev/*, String[] fields*/) throws IOException{
		if(!credentials.canRunAdhoc(db)) {
			this.sendNotAuth(response);
			return;
		}

		JSONObject status = new JSONObject();
		status.put("db",db);
		status.put("view","_text_query");

		JSONObject jo;
		try {
			request.setCharacterEncoding("UTF-8");
			jo = JSONObject.read(request.getInputStream());
		} catch(IOException e) {
			sendError(response, "Query not in JSON object",status,HttpServletResponse.SC_BAD_REQUEST);
			log.info("Query not in JSON object");
			return;
		}

		String defaultField = null;
		String queryStr = null;
		boolean ok = true;
		try {
			defaultField = jo.getString("default_field");
			queryStr = jo.getString("query");
		} catch(JSONException e) {
			ok = false;
		}

		if (!ok || queryStr == null || queryStr.length() == 0) {
			sendError(response, "Query format error", HttpServletResponse.SC_BAD_REQUEST);
			log.info("Query format error {}", jo.toString());
			return;
		}

		try {
			log.debug("Running fulltext query on default field {} : {}", defaultField, queryStr);
//			memeDB.getFulltextEngine().runQuery(db, defaultField, queryStr, makeViewOptions(request.getParameterMap()));
			boolean pretty="true".equals(request.getParameter("pretty"));
			if (pretty) {
				sendJSONString(response, memeDB.getFulltextEngine().runQuery(db, defaultField, queryStr, makeViewOptions(request.getParameterMap())));
			} else {
				sendJSONString(response, memeDB.getFulltextEngine().runQuery(db, defaultField, queryStr, makeViewOptions(request.getParameterMap())).toString());
			}
//			this.sendJSONString;
		} catch (FulltextException e) {
			sendError(response, "Query error", e.getMessage());
			log.error("Error processing Query code: {} {}", queryStr, e);
		}
	}

	public boolean match(Credentials credentials, HttpServletRequest request, String db, String id) {
		return (
				db!=null  && 
				!db.startsWith("_") && 
				id!=null && 
				id.equals("_text_query") && 
				request.getMethod().equals("POST"));
	}
}
