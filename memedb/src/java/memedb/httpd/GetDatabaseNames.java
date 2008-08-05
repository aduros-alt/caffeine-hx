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

import java.util.Set;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.json.JSONArray;

import memedb.auth.Credentials;

/**
 *
 * Handles GET with _all_dbs for db
 *
 */
public class GetDatabaseNames extends BaseRequestHandler {

	public void handleInner(Credentials credentials, HttpServletRequest request, HttpServletResponse response, String db, String id, String rev) {
		Set<String> dbs = memeDB.getBackend().getDatabaseNames();
		JSONArray ar = new JSONArray();
		for (String d:dbs) {
			if (!d.startsWith("_")) {
				ar.put(d);
			}
		}
		sendJSONString(response, ar);
	}

	public boolean match(Credentials credentials, HttpServletRequest request, String db, String id) {
		return (db.equals("_all_dbs") && request.getMethod().equals("GET") && credentials!=null);
	}

}
