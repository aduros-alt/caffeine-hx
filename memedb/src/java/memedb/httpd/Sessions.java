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

import org.json.JSONException;
import org.json.JSONWriter;

import memedb.auth.Credentials;

/**
 *
 * Handles ANY with _sessions as db
 *
 */
public class Sessions extends BaseRequestHandler {

	public void handleInner(Credentials credentials, HttpServletRequest request, HttpServletResponse response, String db, String id, String rev) throws IOException{
		response.setStatus(HttpServletResponse.SC_OK);
		response.setContentType(JSON_MIMETYPE);
		try {
			JSONWriter w = new JSONWriter(response.getWriter());
			w.array();
			for (Credentials cred:memeDB.getAuthentication().getCredentials()) {
				w.object()
					.key("username")
					.value(cred.getUsername())
					.key("token")
					.value(cred.getToken())
					.endObject();
			}
			w.endArray();

		} catch (JSONException e) {
			throw new IOException(e);
		}
	}

	public boolean match(Credentials credentials, HttpServletRequest request, String db, String id) {
		return (db.equals("_sessions") && credentials.isSA());
	}

}
