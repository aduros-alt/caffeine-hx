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
 * Actual authentication is handled in MemeDBHandler.java. This
 * class simply outputs the current token and seconds remaining.<pre>
 * {
 *   ok: true,
 *   token: (string)
 *   valid_seconds: (int)
 * }
 * </pre>
 * Handles ANY with _auth for db
 *
 */
public class Auth extends BaseRequestHandler {

	public void handleInner(Credentials credentials, HttpServletRequest request, HttpServletResponse response, String db, String id, String rev) throws IOException{
		response.setStatus(HttpServletResponse.SC_OK);
		response.setContentType(TEXT_PLAIN_MIMETYPE);
		try {
			new JSONWriter(response.getWriter())
			.object()
				.key("ok")
				.value(true)
				.key("token")
				.value(credentials.getToken())
				.key("valid_seconds")
				.value(credentials.secondsRemaining())
			.endObject();
		} catch (JSONException e) {
			throw new IOException(e);
		}
	}

	public boolean match(Credentials credentials, HttpServletRequest request, String db, String id) {
		return ("_auth".equals(db));
	}

}
