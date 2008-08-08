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

import memedb.auth.Credentials;
import memedb.backend.BackendException;
import memedb.views.ViewException;

import org.json.JSONObject;

/**
 *
 * Handles PUT with no _ in db and id null
 *
 */
public class AddDB extends BaseRequestHandler {

	public void handleInner(Credentials credentials, HttpServletRequest request, HttpServletResponse response, String db, String id, String rev) throws IOException, BackendException, ViewException
	{
		if(!credentials.canCreateDatabase(db)) {
			this.sendNotAuth(response);
			return;
		}
		try {
			memeDB.addDatabase(db);
		}
		catch (BackendException e) {
			JSONObject status = new JSONObject();
			status.put("db",db);
			status.put("id",id);
			status.put("revision",rev);
			sendError(response, "Database already exists",status, HttpServletResponse.SC_CONFLICT);
			return;
		}
		sendOK(response, db+" added");
	}

	public boolean match(Credentials credentials, HttpServletRequest request, String db, String id) {
		return (db!=null && !db.startsWith("_") && id==null && request.getMethod().equals("PUT"));
	}

}
