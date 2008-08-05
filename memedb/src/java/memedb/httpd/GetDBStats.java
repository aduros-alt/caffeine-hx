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
import java.util.Map;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.json.JSONObject;

import memedb.auth.Credentials;

/**
 * Returns information on the database, returned as a JSON Object<pre>
 * {
 *   "db_name": "mytestdb2",
 *   "doc_count": 10
 * }
 * </pre>
 * Handles GET with database name. no leading _ for db, id == null
 */
public class GetDBStats extends BaseRequestHandler {

	public void handleInner(Credentials credentials, HttpServletRequest request, HttpServletResponse response, String db, String id, String rev) throws IOException{
		if( memeDB.getBackend().doesDatabaseExist(db) ) {
			Map<String,Object> m = memeDB.getBackend().getDatabaseStats(db);
			sendJSONString(response, new JSONObject(m));
		}
		else {
			JSONObject status = new JSONObject();
			status.put("db",db);
			sendError(response, "not_found",status, HttpServletResponse.SC_NOT_FOUND);
		}
	}

	public boolean match(Credentials credentials, HttpServletRequest request, String db, String id) {
		return  db!=null &&
				!db.startsWith("_") &&
				id==null &&
				request.getMethod().equals("GET") &&
				credentials.isAuthorizedRead(db);
	}

}
