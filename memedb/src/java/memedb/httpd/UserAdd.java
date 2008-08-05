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
import java.util.HashMap;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import memedb.auth.Credentials;
// import memedb.backend.BackendException;
import memedb.auth.NotAuthorizedException;

import org.json.JSONObject;
import org.json.JSONException;

/**
 * Add a user to the authentication database. The
 *
 * Handles POST with database name _adduser
 * @author Russell Weir
 */
public class UserAdd extends BaseRequestHandler {

	public void handleInner(Credentials credentials, HttpServletRequest request, HttpServletResponse response, String db, String id, String rev) throws IOException {
		HashMap<String, String> dbPerms = new HashMap<String, String>();
		JSONObject data;

		try {
			request.setCharacterEncoding("UTF-8");
			data = JSONObject.read(request.getInputStream());
		} catch(IOException e) {
			sendError(response, "User information not in valid JSON object",HttpServletResponse.SC_BAD_REQUEST);
			log.info("Adhoc view not in JSON object");
			return;
		}

		try {
			JSONObject perms = data.getJSONObject("db_access");
			for(String v : perms.keySet()) {
				dbPerms.put(v, perms.getString(v));
			}
		} catch(Exception e) {
			sendError(response, "No database permissions (db_access)");
		}

		try {
			memeDB.getAuthentication().addUser(
				credentials,
				data.getString("username"),
				data.getString("password"),
				dbPerms,
				data.optBoolean("is_sa", false));
		}
		catch(NotAuthorizedException e) {
			sendNotAuth(response);
			return;
		}
		catch(JSONException e) {
			sendError(response, "Error parsing user information",HttpServletResponse.SC_BAD_REQUEST);
			return;
		}

		sendOK(response, "added");
	}

	public boolean match(Credentials credentials, HttpServletRequest request, String db, String id) {
		return (db!=null && db.startsWith("_useradd") && id==null && request.getMethod().equals("POST") && credentials.isSA());
	}

}
