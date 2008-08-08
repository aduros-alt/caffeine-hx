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

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.json.JSONObject;
import org.json.JSONException;

import memedb.auth.Credentials;
import memedb.views.AdHocViewRunner;
import memedb.views.ViewException;

/**
 *
 * Handles GET with no leading _ for db, id == _temp_view
 *
 */
public class AdHocView extends BaseRequestHandler {

	@SuppressWarnings("unchecked")
	public void handleInner(Credentials credentials, HttpServletRequest request, HttpServletResponse response, String db, String id, String rev/*, String[] fields*/) throws IOException{
		if(!credentials.canRunAdhoc(db)) {
			this.sendNotAuth(response);
			return;
		}
		
		String line;
		/*
		StringBuilder sb = new StringBuilder();
		BufferedReader reader = null;

		request.setCharacterEncoding("UTF-8");
		try {
			reader = new BufferedReader(new InputStreamReader(request.getInputStream()));
			while ((line=reader.readLine())!=null) {
				log.debug(line);
				sb.append(line);
				sb.append("\n");
			}
		} finally {
			if (reader!=null) {
				reader.close();
			}
		}
		String src = sb.toString();
		*/

		JSONObject status = new JSONObject();
		status.put("db",db);
		status.put("view","_temp_view");

		JSONObject funcs;
		try {
			request.setCharacterEncoding("UTF-8");
			funcs = JSONObject.read(request.getInputStream());
		} catch(IOException e) {
			sendError(response, "Adhoc view not in JSON object",status,HttpServletResponse.SC_BAD_REQUEST);
			log.info("Adhoc view not in JSON object");
			return;
		}

		String map_src = null;
		try {
			map_src = funcs.getString("map");
		} catch(JSONException e) {
			sendError(response, "View missing map function",status,HttpServletResponse.SC_BAD_REQUEST);
			log.info("View missing map function");
			return;
		}
		String reduce_src = funcs.optString("reduce", null);


		if (map_src == null || map_src.length() == 0) {
			sendError(response, "View javascript source not sent",status,HttpServletResponse.SC_BAD_REQUEST);
			log.info("Bad adhoc view: {} {}", map_src, reduce_src);
			return;
		}

		try {
			sendJSONString(response,AdHocViewRunner.adHocView(memeDB,db,map_src,reduce_src,makeViewOptions(request.getParameterMap())));

		} catch (ViewException e) {
			sendError(response,"View error",e.getMessage());
			log.error("Error processing view code: map: {}  reduce: {}",map_src,reduce_src,e);
		}
	}

	public boolean match(Credentials credentials, HttpServletRequest request, String db, String id) {
		return (db!=null  && !db.startsWith("_") && id!=null && id.equals("_temp_view") && request.getMethod().equals("POST"));
	}
}
