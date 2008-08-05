package memedb.httpd;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import memedb.auth.Credentials;

/**
 *
 * Handles ANY with no _shutdown as db
 *
 */
public class Shutdown extends BaseRequestHandler {

	public void handleInner(Credentials credentials, HttpServletRequest request, HttpServletResponse response, String db, String id, String rev){
		memeDB.shutdown();
		sendOK(response, "Shutting down");
	}

	public boolean match(Credentials credentials, HttpServletRequest request, String db, String id) {
		return (db.equals("_shutdown") && credentials.isSA());
	}

}
