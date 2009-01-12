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
 * Add a user to the authentication database.
 *
 * Handles POST with database name _adduser
 * @author Russell Weir
 */
public class UserAdd extends BaseRequestHandler {

	public void handleInner(Credentials credentials, HttpServletRequest request, HttpServletResponse response, String db, String id, String rev) throws IOException {
		if(!credentials.isSA()) {
			this.sendNotAuth(response);
			return;
		}

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
			memeDB.getAuthentication().addUser(
				credentials,
				data);
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
		return ("_useradd".equals(db) && id==null && request.getMethod().equals("POST"));
	}

}
