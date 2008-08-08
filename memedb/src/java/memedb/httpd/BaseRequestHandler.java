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
import javax.servlet.ServletException;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;
import org.json.JSONWriter;

import memedb.MemeDB;
import memedb.auth.Credentials;
import memedb.backend.BackendException;
import memedb.document.Document;
import memedb.document.DocumentCreationException;
import memedb.utils.Logger;
import memedb.views.ViewException;

/**
* Base class for each http request handler
* @author mbreese
* @author Russell Weir
*/
public abstract class BaseRequestHandler {
	protected static final String JSON_MIMETYPE = "application/json";
	protected static final String TEXT_PLAIN_MIMETYPE = "text/plain;charset=utf-8";
	protected MemeDB memeDB;
	protected boolean allowHtml;

	abstract public boolean match(Credentials credentials, HttpServletRequest request, String db, String id);
	abstract protected void handleInner(Credentials credentials, HttpServletRequest request, HttpServletResponse response, String db, String id, String rev) throws BackendException, IOException, DocumentCreationException, ViewException, ServletException;

	protected Logger log = Logger.get(getClass());


	public void handle(Credentials credentials, HttpServletRequest request, HttpServletResponse response, String db, String id, String rev){
		try {
			handleInner(credentials,request,response,db,id,rev);//,fields);
		} catch (JSONException e) {
			sendError(response, "JSON processing error");
			log.error(e,"JSON error");
		} catch (ViewException e) {
			sendError(response, "View processing error");
			log.error(e,"View error");
		} catch (BackendException e) {
			sendError(response, "Backend storage error");
			log.error(e,"Backend error");
			e.printStackTrace();
		} catch (IOException e) {
			sendError(response, "IO error");
			log.error(e,"Backend error");
			e.printStackTrace();
		} catch (ServletException e) {
			sendError(response, "Servlet error");
			log.error(e,"Servlet error");
			e.printStackTrace();
		} catch (DocumentCreationException e) {
			sendError(response, "IO error");
			log.error(e,"Backend error");
			e.printStackTrace();
		}
	}


	public void setMemeDB(MemeDB memeDB) {
		this.memeDB=memeDB;
		allowHtml = memeDB.getProperty("server.www.allow","true").toLowerCase().equalsIgnoreCase("true");
	}

 	protected Map<String, String> makeViewOptions(Map<String,String[]> params) {
		Map<String,String> map = new java.util.HashMap<String,String>();
		for(String k: params.keySet()) {
			String[] value = params.get(k);
			map.put(k, value[0]);
		}
		//log.debug("%%%%% {}",map);
		return map;
	}


	protected void sendNotAuth(HttpServletResponse response) {
		sendError(response,"Not authorized to perform requested action", HttpServletResponse.SC_UNAUTHORIZED);
	}

	protected void sendError(HttpServletResponse response, String errMsg, String reason, JSONObject status, int statusCode) {
		try {
			MemeDBHandler.sendError(response, errMsg, reason, status, statusCode, log);
		} catch(IOException e) {}
	}

	protected void sendError(HttpServletResponse response, String errMsg) {
		sendError(response,errMsg,errMsg,null,HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
	}
	protected void sendError(HttpServletResponse response, String errMsg, int statusCode) {
		sendError(response, errMsg, errMsg,null, statusCode);
	}
	protected void sendError(HttpServletResponse response, String errMsg, String reason) {
		sendError(response,errMsg,reason,null,HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
	}
	protected void sendError(HttpServletResponse response, String errMsg, String reason, int statusCode) {
		sendError(response,errMsg,reason,null,statusCode);
	}
	protected void sendError(HttpServletResponse response, String errMsg, JSONObject status) {
		sendError(response,errMsg,errMsg,status,HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
	}
	protected void sendError(HttpServletResponse response, String errMsg, JSONObject status, int statusCode) {
		sendError(response,errMsg,errMsg,status,statusCode);
	}

	protected void sendOK(HttpServletResponse response, String string){
		response.setStatus(HttpServletResponse.SC_OK);
		response.setContentType(TEXT_PLAIN_MIMETYPE);
		try {
			new JSONWriter(response.getWriter())
				.object()
					.key("ok")
					.value(true)
					.key("reason")
					.value(string)
				.endObject();
		} catch (JSONException e) {
			log.error(e);
		} catch (IOException e) {
			log.error(e);
		}
	}
	protected void sendDocumentOK(HttpServletResponse response, String id, String rev, int statusCode){
		response.setStatus(statusCode);
		response.setContentType(TEXT_PLAIN_MIMETYPE);
		try {
			new JSONWriter(response.getWriter())
				.object()
					.key("ok")
					.value(true)
					.key("id")
					.value(id)
					.key("rev")
					.value(rev)
				.endObject();
		} catch (JSONException e) {
			log.error(e);
		} catch (IOException e) {
			log.error(e);
		}
	}

	protected void sendJSONString(HttpServletResponse response, JSONArray ar) {
		try {
			response.setStatus(HttpServletResponse.SC_OK);
			response.setContentType(TEXT_PLAIN_MIMETYPE);
			response.getWriter().write(ar.toString(4));
		} catch (JSONException e) {
			log.error(e);
		} catch (IOException e) {
			log.error(e);
		}
	}
	protected void sendJSONString(HttpServletResponse response, JSONObject json) {
		try {
			response.setStatus(HttpServletResponse.SC_OK);
			response.setContentType(TEXT_PLAIN_MIMETYPE);
			response.getWriter().write(json.toString(2));
		} catch (JSONException e) {
			log.error(e);
		} catch (IOException e) {
			log.error(e);
		}
	}
	protected void sendJSONString(HttpServletResponse response, JSONObject json, int statusCode) {
		try {
			response.setStatus(statusCode);
			response.setContentType(TEXT_PLAIN_MIMETYPE);
			response.getWriter().write(json.toString(2));
		} catch (JSONException e) {
			log.error(e);
		} catch (IOException e) {
			log.error(e);
		}
	}
	protected void sendJSONString(HttpServletResponse response, String s) {
		try {
			response.setStatus(HttpServletResponse.SC_OK);
			response.setContentType(TEXT_PLAIN_MIMETYPE);
			response.getWriter().write(s);
		} catch (JSONException e) {
			log.error(e);
		} catch (IOException e) {
			log.error(e);
		}
	}

	protected void sendDocument(Document doc, HttpServletRequest request, HttpServletResponse response) {
		try {
			doc.sendDocument(request, response);
		} catch (JSONException e) {
			log.error(e);
		} catch (IOException e) {
			log.error(e);
		}
	}

	protected void sendMetaData(Document doc, HttpServletResponse response, Map<String,String[]> params) {
		try {
			response.setStatus(HttpServletResponse.SC_OK);
			response.setContentType(TEXT_PLAIN_MIMETYPE);
			doc.writeMetaData(response.getWriter(),params);
		} catch (JSONException e) {
			log.error(e);
		} catch (IOException e) {
			log.error(e);
		}
	}
}
