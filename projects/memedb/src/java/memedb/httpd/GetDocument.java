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

import org.json.JSONArray;
import org.json.JSONObject;

import memedb.MemeDB;
import memedb.auth.Credentials;
import memedb.document.Document;
import memedb.backend.BackendException;

/**
 *
 * Handles GET with no _ in db or id
 * @author mbreese
 * @author Russell Weir
 */
public class GetDocument extends BaseRequestHandler {

	protected String indexFile = "index.html";

	@Override
	public void setMemeDB(MemeDB memeDB) {
		super.setMemeDB(memeDB);
		indexFile = memeDB.getProperty("index.name");

	}

	@SuppressWarnings("unchecked")
	public void handleInner(Credentials credentials, HttpServletRequest request, HttpServletResponse response, String db, String id, String rev/*, String[] fields*/) throws IOException, BackendException {
		if(!credentials.canReadDocuments(db)) {
			this.sendNotAuth(response);
			return;
		}
		/*
		 *  display the document, optionally revision (or _current), and optionaly
		 *  traverse the JSONObject by field names
		 */
		Document d = memeDB.getBackend().getDocument(db, id, rev);
		if (d==null && memeDB.getBackend().doesDocumentExist(db, id+"/"+indexFile)) {
			d = memeDB.getBackend().getDocument(db, id+"/"+indexFile);
		}
		if (d!=null) {
			log.debug("Got doc {} class={}",d.getId(),d.getClass());

			boolean showMeta = "true".equals(request.getParameter("meta"));
			boolean showRevisions = "true".equals(request.getParameter("revisions"));

			if (showRevisions && (showMeta || !d.writesRevisionData())) {
				JSONArray revs = memeDB.getBackend().getDocumentRevisions(db, id);
				d.setRevisions(revs);
			}

			if (showMeta && d.writesRevisionData()) { // only show meta data if the document doesn't write it by default
				log.debug("sending meta data for {}",id);
				sendMetaData(d, response,request.getParameterMap());
			} else {
				sendDocument(d, request, response);
			}
		} else {
			JSONObject status = new JSONObject();
			status.put("db",db);
			status.put("id",id);
			status.put("revision",rev);
			sendError(response, "Document not found",status, HttpServletResponse.SC_NOT_FOUND);
		}
	}

	public boolean match(Credentials credentials, HttpServletRequest request, String db, String id) {
		return (
				db!=null  && 
				!db.startsWith("_") && 
				id!=null && 
				!id.startsWith("_") &&
				request.getMethod().equals("GET") &&
				(!allowHtml || memeDB.getBackend().doesDatabaseExist(db)));
	}

}
