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

import memedb.auth.Credentials;
import memedb.views.ViewManager;

/**
 *
 * Handles GET with (dbname)/_view/(viewname)
 *
 */
public class GetView extends BaseRequestHandler {

	@SuppressWarnings("unchecked")
	public void handleInner(Credentials credentials, HttpServletRequest request, HttpServletResponse response, String db, String id, String rev/*, String[] fields*/) throws IOException{

		String viewName = id.substring(6);
		String functionName = null;

		if (memeDB.getViewManager().doesViewExist(db, viewName,ViewManager.DEFAULT_FUNCTION_NAME)) {
			functionName=ViewManager.DEFAULT_FUNCTION_NAME;
		} else {
			int idx = viewName.lastIndexOf("/");
			if (idx>-1) {
				functionName = viewName.substring(idx+1);
				viewName = viewName.substring(0,idx);
			} else {
				JSONObject status = new JSONObject();
				status.put("db",db);
				status.put("view",viewName);
				status.put("function",functionName);
				sendError(response, "View not found",status,HttpServletResponse.SC_NOT_FOUND);
			}
 		}

		if (memeDB.getViewManager().doesViewExist(db, viewName, functionName)) {
			boolean pretty="true".equals(request.getParameter("pretty"));
			if (pretty) {
				sendJSONString(response, memeDB.getViewManager().getViewResults(db, viewName, functionName,makeViewOptions(request.getParameterMap())));
			} else {
				sendJSONString(response, memeDB.getViewManager().getViewResults(db, viewName, functionName,makeViewOptions(request.getParameterMap())).toString());
			}
		} else {
			JSONObject status = new JSONObject();
			status.put("db",db);
			status.put("view",viewName);
			status.put("function",functionName);
			sendError(response, "View not found",status,HttpServletResponse.SC_NOT_FOUND);
		}
	}

	public boolean match(Credentials credentials, HttpServletRequest request, String db, String id) {
		return (db!=null  && !db.startsWith("_") && id!=null && id.startsWith("_view/") && request.getMethod().equals("GET") && credentials.isAuthorizedRead(db));
	}

}
