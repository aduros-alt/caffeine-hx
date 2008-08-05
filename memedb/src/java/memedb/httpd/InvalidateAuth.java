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

import javax.servlet.http.Cookie;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import memedb.auth.Credentials;

/**
 *
 * Handles ANY with no _invalidate as db
 *
 */
public class InvalidateAuth extends BaseRequestHandler {

	public void handleInner(Credentials credentials, HttpServletRequest request, HttpServletResponse response, String db, String id, String rev) throws IOException{
		memeDB.getAuthentication().invalidate(credentials);
		Cookie[] cookies = request.getCookies();
		if (cookies !=null) {
			for (Cookie cookie: cookies) {
				if (cookie.getName().equals(MemeDBHandler.COOKIE_ID)) {
					cookie.setMaxAge(0); // TODO: check this
				}
			}
		}
		sendOK(response, "Authentication invalidated");
	}

	public boolean match(Credentials credentials, HttpServletRequest request, String db, String id) {
		return (db.equals("_invalidate"));
	}

}
