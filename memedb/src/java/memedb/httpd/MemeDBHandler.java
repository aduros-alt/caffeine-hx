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
import java.util.ArrayList;
import java.util.List;

import javax.servlet.ServletException;
import javax.servlet.http.Cookie;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.commons.codec.binary.Base64;
import org.json.JSONException;
import org.json.JSONWriter;
import org.json.JSONObject;
import org.mortbay.jetty.HttpConnection;
import org.mortbay.jetty.Request;
import org.mortbay.jetty.handler.AbstractHandler;

import memedb.MemeDB;
import memedb.auth.Credentials;
import memedb.auth.SACredentials;
import memedb.auth.AnonCredentials;
import memedb.utils.Logger;

/**
 * This is very <b>ugly</b> and should be refactored into multiple handlers...
 *
 * @author mbreese
 * @author Russell Weir
 */
public class MemeDBHandler extends AbstractHandler {
	public static final String JSON_MIMETYPE = "application/json";
	public static final String TEXT_PLAIN_MIMETYPE = "text/plain;charset=utf-8";
	public static final String COOKIE_ID = "MEMEDB_ID";
	final protected MemeDB memeDB;
	final protected boolean allowAnonymous;
	final protected boolean allowAnonymousAsSa;
	final protected String realm;
	final protected boolean allowHtml;
	protected int timeout;

	protected List<BaseRequestHandler> baseRequestHandlers = new ArrayList<BaseRequestHandler>();

	protected Logger log = Logger.get(getClass());
	public MemeDBHandler(MemeDB memeDB) {
		this.memeDB = memeDB;
		baseRequestHandlers.add(new Admin());
		baseRequestHandlers.add(new GetDocument());
		baseRequestHandlers.add(new AdHocView());
		baseRequestHandlers.add(new GetView());
		baseRequestHandlers.add(new Auth());
		baseRequestHandlers.add(new InvalidateAuth());
		baseRequestHandlers.add(new GetDatabaseNames());
		baseRequestHandlers.add(new GetDBStats());
		baseRequestHandlers.add(new AddDB());
		baseRequestHandlers.add(new UpdateDocument());
		baseRequestHandlers.add(new Sessions());
		baseRequestHandlers.add(new Shutdown());
		baseRequestHandlers.add(new DeleteDocument());
		baseRequestHandlers.add(new DeleteDB());
		baseRequestHandlers.add(new UserAdd());
		for (BaseRequestHandler handler:baseRequestHandlers) {
			handler.setMemeDB(memeDB);
		}
		this.allowAnonymous = memeDB.getProperty("auth.anonymous","false").toLowerCase().equals("true");
		this.allowAnonymousAsSa = memeDB.getProperty("auth.anonymous.sa","false").toLowerCase().equals("true");
		this.realm = memeDB.getProperty("auth.realm","MemeDB");
		this.timeout=Integer.parseInt(memeDB.getProperty("auth.timeout.seconds","300"));
		this.allowHtml = memeDB.getProperty("server.www.allow","true").toLowerCase().equalsIgnoreCase("true");

	}

	public void handle(String target, HttpServletRequest request, HttpServletResponse response, int dispatch) throws IOException, ServletException
	{
		Request base_request = (request instanceof Request) ? (Request)request:HttpConnection.getCurrentConnection().getRequest();

		log.debug("Requested URI: {} target: {}",request.getRequestURI(), target);


		Credentials cred=getCredentials(request,response);
		if( cred == null || response.isCommitted()) {
			base_request.setHandled(true);
			return;
		}

		String path = request.getRequestURI().substring(1);
		if (path.startsWith(MemeDB.SYS_DB) || path.startsWith(MemeDB.USERS_DB)) {
			log.warn("Attempted access to {}", path);
			sendError(response, "not_allowed", "system db", 405);
			base_request.setHandled(true);
			return;
		}
		if (path.endsWith("/")) {
			path=path.substring(0,path.length()-1);
		}

		String db = null;
		String id = null;
		String rev = null;

		int slashIndex = path.indexOf("/");
		if (slashIndex>-1) {
			db = path.substring(0,slashIndex);
			if (slashIndex<path.length()) {
				id = path.substring(slashIndex+1);
			}
			rev = request.getParameter("rev");
		} else {
			db=path;
		}
		if(db.length() == 0)
			db = null;

		boolean handled = false;
		for (BaseRequestHandler handler:baseRequestHandlers) {
			if (handler.match(cred, request, db, id)) {
				if(handler instanceof Admin) {
					Admin a = (Admin) handler;
					a.setDispatch(dispatch);
				}
				handler.handle(cred, request, response, db, id, rev);
				handled = true;
				break;
			}
		}
		if (!handled && !allowHtml) {
			sendError(response,"Could not process request");
			handled = true;
		}
		if(handled)
			base_request.setHandled(true);
		return;
	}

	protected void sendNoAuthError(HttpServletResponse response, String reason) throws IOException {
		sendError(response, "Not authorized", reason, null, HttpServletResponse.SC_UNAUTHORIZED, log);
	}

	protected void sendError(HttpServletResponse response, String errMsg) throws IOException {
		sendError(response, errMsg, errMsg, null, HttpServletResponse.SC_BAD_REQUEST, log);
	}

	protected void sendError(HttpServletResponse response, String errMsg, String reason, int statusCode) throws IOException {
		sendError(response, errMsg, reason, null, statusCode, log);
	}

	public static void sendError(HttpServletResponse response, String errMsg, String reason, JSONObject status, int statusCode, Logger log) throws IOException {
		response.setStatus(statusCode);
		response.setContentType(TEXT_PLAIN_MIMETYPE);
		try {
			new JSONWriter(response.getWriter())
				.object()
					.key("ok")
					.value(false)
					.key("error")
					.value(errMsg)
					.key("reason")
					.value(reason)
					.key("status")
					.value(status)
				.endObject();
		} catch (JSONException e) {
			if(log != null)
				log.error(e);
			throw new IOException(e);
		}
	}

	protected Credentials getCredentials(HttpServletRequest request, HttpServletResponse response) throws IOException {
		Credentials cred=null;

		if (request.getRequestURI().equals("/_auth")) {
			String username = request.getParameter("username");
			String password = request.getParameter("password");
			log.warn("login attempt for {}", username);
			if (!allowAnonymous && "anonymous".equals(username)) {
				sendNoAuthError(response, "Bad username / password combination");
				return null;
			}
			if (username!=null) {
				if (password == null) {
					password = "";
				}
				cred = memeDB.getAuthentication().authenticate(username, password);
				if (cred!=null) {
					if (request.getParameter("setcookie") ==null || request.getParameter("setcookie").toLowerCase().equals("false")) {
						Cookie cookie = new Cookie(COOKIE_ID, cred.getToken());
						cookie.setMaxAge(timeout);
						response.addCookie(cookie);
					}
					return cred;
				} else {
					log.warn("Bad login attempt for {}", username);
					sendNoAuthError(response, "Bad username / password combination");
					return null;
				}
			}
		}

		Cookie[] cookies = request.getCookies();
		if (cookies !=null) {
			for (Cookie cookie: cookies) {
				if (cookie.getName().equals(COOKIE_ID)) {
					cred = memeDB.getAuthentication().getCredentialsFromToken(cookie.getValue());
					if (cred!=null) {
						log.debug("Got credentials from cookie token: {}", cookie.getValue());
						return cred;
					}
				}
			}
		}

		String param = request.getParameter("token");
		if (param!=null && !param.equals("")) {
			cred = memeDB.getAuthentication().getCredentialsFromToken(param);
			if (cred!=null) {
				log.debug("Authenticated as {} => {} via Req param",cred.getUsername(), cred.getToken());
				addCredentialedCookie(response,cred);
				return cred;
			}
		}

		String headerparam = request.getHeader("MemeDB-Token");
		if (headerparam!=null && !headerparam.equals("")) {
			log.info("Attempting authentication with token {}", headerparam);
			cred = memeDB.getAuthentication().getCredentialsFromToken(headerparam);
			if (cred!=null) {
				log.info("Got credentials!");
				log.debug("Authenticated as {} => {} via HTTP-Header",cred.getUsername(), cred.getToken());
				addCredentialedCookie(response,cred);
				return cred;
			}
		}

		String authHeader = request.getHeader("Authorization");
		if (authHeader!=null) {
			String[] authSplit = authHeader.split(" ");
			if (authSplit.length==2) {
				String userpass = new String(Base64.decodeBase64(authSplit[1].getBytes()));
				if (userpass!=null) {
					String[] ar = userpass.split(":");
					if(ar.length>0) {
						String u = ar[0];
						String p="";
						if (ar.length>1) {
							p = ar[1];
						}
						if (!allowAnonymous && "anonymous".equals(u)) {
						} else {
							cred = memeDB.getAuthentication().authenticate(u,p);

							if (cred!=null) {
								log.debug("Authenticated as {} => {} via HTTP-AUTH",cred.getUsername(), cred.getToken());
								addCredentialedCookie(response,cred);
							}
							return cred;
						}
					}
				}
			}
			response.addHeader("WWW-Authenticate"," Basic realm=\"" + realm + "\"");
			sendNoAuthError(response,"You need a username and password");
			return null;
		}
		
		if(allowAnonymous) {
			if(allowAnonymousAsSa)
				return new SACredentials("anonymous","",timeout);
			return new AnonCredentials("", timeout);
		}
		
		log.warn("Error authenticating");
		response.addHeader("WWW-Authenticate"," Basic realm=\"" + realm + "\"");
		sendNoAuthError(response,"You need a username and password");
		return null;
	}

	private void addCredentialedCookie(HttpServletResponse response, Credentials cred) {
		Cookie cookie = new Cookie(COOKIE_ID, cred.getToken());
		cookie.setMaxAge(24*60*60); // max time is one day... afterwhich, it needs to reauth.
		response.addCookie(cookie);
	}
}
