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

package memedb.auth;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Random;
import java.util.HashMap;

import memedb.MemeDB;
import memedb.backend.BackendException;
import memedb.document.Document;
import memedb.document.DocumentCreationException;
import memedb.document.JSONDocument;
import memedb.utils.BCrypt;
//import memedb.utils.Lock;
import memedb.utils.Logger;

import org.json.JSONObject;

/**
 * <p>
 * This authentication backend does two things for checking a username/password. First, it loads an administrator
 * (sa) username and password from the properties file.   Second, it checks to see if a system document
 * "_users/username" exists.
 * <p>
 * The user document must contain a "password" entry, and _can_ contain a boolean "is_sa" flag.
 *
 * @author mbreese
 *
 */
public class BasicAuthentication implements Authentication {
	protected Logger log = Logger.get(BasicAuthentication.class);

	protected List<Credentials> credentials = Collections.synchronizedList(new ArrayList<Credentials>());

	protected static Random random = new java.util.Random();
	protected Thread monitor = null;

	protected String saUsername;
	protected String saPasswordHash;
	protected MemeDB memeDB;
	protected int timeout;

	private boolean allowAnonymous;

	public BasicAuthentication () {
	}

	public void init(MemeDB memeDB) {
		this.memeDB = memeDB;
		if (!memeDB.getBackend().doesDatabaseExist(MemeDB.USERS_DB)) {
			try {
				memeDB.addDatabase(MemeDB.USERS_DB);
			} catch (Exception e) {
				e.printStackTrace();
				log.error(e);
				throw new RuntimeException(e);
			}
		}
		String u = memeDB.getProperty("sa.username");
		String p = memeDB.getProperty("sa.password");
		this.saUsername=u;
		this.saPasswordHash=BCrypt.hashpw(p, BCrypt.gensalt());
		this.allowAnonymous = memeDB.getProperty("auth.anonymous","false").toLowerCase().equals("true");
		this.timeout=Integer.parseInt(memeDB.getProperty("auth.timeout.seconds","300"));

		JSONDocument userdoc = (JSONDocument) memeDB.getBackend().getDocument(MemeDB.USERS_DB, "anonymous");
		if (userdoc==null) {
			log.warn("Creating default anonymous user");
			try {
				JSONObject o = new JSONObject(AnonCredentials.defaultJSON());
				this.addUser(new SACredentials("system","system",0), o);
			} catch(NotAuthorizedException e) {
				throw new RuntimeException("Unable to create user 'anonymous'", e);
			}
		} else {
			AnonCredentials.setDefaultAnonDocument(userdoc);
		}
		monitor = new Thread() {
			boolean stop = false;
			@Override
			public void run() {
				log.debug("Starting authentication cache monitoring thread");
				while (!stop) {
					List<Credentials> expired = new ArrayList<Credentials>();
					for (Credentials cred:credentials) {
						if (cred.isExpired()) {
							expired.add(cred);
						}
					}
					for (Credentials cred: expired) {
						log.debug("Invalidating credentials {} (timeout)", cred.getUsername());
						invalidate(cred);
					}
					try {
						Thread.sleep(5000);
					} catch (InterruptedException e) {
						stop = true;
					}
				}
				log.debug("Stopping authentication cache monitoring thread");
			}

			@Override
			public void interrupt() {
				this.stop = true;
				super.interrupt();
			}
		};
		monitor.start();
	}

	public void shutdown() {
		monitor.interrupt();
	}

	public Credentials addCredentials(Credentials cred) {
		log.debug("Adding credentials {} to cache", cred.getUsername());
		credentials.add(cred);
		return cred;
	}
	
	/*
	public void addUser(Credentials cred, String username, String password, HashMap<String, String> dbPerms, boolean sa) throws NotAuthorizedException {
		if (cred.isSA()) {
			try {
				JSONDocument userdoc = (JSONDocument) Document.newDocument(memeDB.getBackend(),MemeDB.USERS_DB, username, MemeDB.CONTENT_JSON, cred.getUsername());
				userdoc.put("username", username);
				userdoc.put("is_sa", sa);
				userdoc.put("password", BCrypt.hashpw(password, BCrypt.gensalt()));
				userdoc.put("db_access", dbPerms);
				memeDB.getBackend().saveDocument(userdoc);
			} catch (BackendException e) {
				log.error("Backend exception adding user: {}",e,username);
			} catch (DocumentCreationException e) {
				log.error("Backend exception adding user: {}",e,username);
			}
		} else {
			throw new NotAuthorizedException("Only sa users can add new users");
		}
	}
	*/
			
	public void addUser(Credentials cred, JSONObject definition) throws NotAuthorizedException
	{
		if(cred.isSA()) {
			try {
				JSONDocument userdoc = makeDoc(cred, definition, false);
				removeUser(cred, (String)userdoc.get("username"));
				memeDB.getBackend().saveDocument(userdoc);
				if("anonymous".equals((String)userdoc.get("username"))) {
					AnonCredentials.setDefaultAnonDocument(userdoc);
				}
			} catch(BackendException e) {
				log.error("Backend exception adding user : {}", e);
			} catch (DocumentCreationException e) {
				log.error("Backend exception adding user : {}", e);
			}
		} else {
			throw new NotAuthorizedException("Only sa users can add new users");
		}
	}
	
	public Credentials authenticate(String username, String password) {
		if (password==null) {
			password="";
		}
		log.debug("Attempting authentication: {}", username);

		if (username.equals(saUsername) && BCrypt.checkpw(password,saPasswordHash)) {
			return addCredentials(new SACredentials(username,generateToken(),timeout));
		} else {
			if (!allowAnonymous && "anonymous".equals(username)) {
				return null;
			}
			JSONDocument userdoc = (JSONDocument) memeDB.getBackend().getDocument(MemeDB.USERS_DB,username);
			if (userdoc!=null) {
				String hashedPassword = (String) userdoc.get("password");
				if (hashedPassword == null) {
					hashedPassword = BCrypt.hashpw("", BCrypt.gensalt());
				}
				if (BCrypt.checkpw(password,hashedPassword)) {
					if("anonymous".equals(username))
						return addCredentials(new AnonCredentials(userdoc,generateToken(),timeout));
					return addCredentials(new UserCredentials(userdoc,generateToken(),timeout));
				} else {
					log.debug("Invalid password for user {}",username);
				}
			} else {
				log.debug("No document for user {} found",username);
			}
		}
		return null;
	}

	public synchronized String generateToken() {
		String token = null;
		while (token==null || getCredentialsFromToken(token)!=null) {
			token = Long.toHexString(random.nextLong())+Long.toHexString(random.nextLong());
		}
		return token;
	}

	public List<Credentials> getCredentials() {
		return credentials;
	}
		
	public Credentials getCredentialsFromToken(String token) {
		for (Credentials cred:credentials) {
			if (cred.getToken().equals(token)) {
				if (!cred.isExpired()) {
					cred.resetTimeout();
					return cred;
				} else {
					invalidate(cred);
				}
			}
		}
		return null;
	}

	public void invalidate(Credentials cred) {
		if (credentials.contains(cred)) {
			credentials.remove(cred);
		}
	}

	public void removeUser(Credentials cred, String username) throws NotAuthorizedException {
		if (cred.isSA()) {
			try {
				memeDB.getBackend().deleteDocument(MemeDB.USERS_DB,username);
			} catch (BackendException e) {
				//log.error("Backend exception removing user: {}",e,username);
			}
		} else {
			throw new NotAuthorizedException("Only sa users can remove users");
		}
	}
	
	public void updateUser(Credentials cred, JSONObject definition) throws NotAuthorizedException
	{
		if(cred.isSA()) {
			try {
				JSONDocument userdoc = makeDoc(cred, definition, true);
				removeUser(cred, (String)userdoc.get("username"));
				memeDB.getBackend().saveDocument(userdoc);
				if("anonymous".equals((String)userdoc.get("username"))) {
					AnonCredentials.setDefaultAnonDocument(userdoc);
				}
			} catch(BackendException e) {
				log.error("Backend exception adding user : {}", e);
			} catch (DocumentCreationException e) {
				log.error("Backend exception adding user : {}", e);
			}
		} else {
			throw new NotAuthorizedException("Only sa users can add new users");
		}
	}
	
	/**
	 * Creates a JSONDocument from the user rights definition.
	 * @param definition JSONObject with user rights
	 * @param forUpdate Set to true to not rehash the user's password
	 * @return New JSONDocument ready to be saved to the backend
	 */
	private JSONDocument makeDoc(Credentials cred, JSONObject definition, boolean forUpdate) throws DocumentCreationException {
		String username = definition.getString("username");
		String password = definition.getString("password");
		boolean sa = definition.optBoolean("is_sa", false);
		if(username.equals("anonymous"))
			sa = false;
		JSONDocument userdoc = 
				(JSONDocument) Document.newDocument(
					memeDB.getBackend(), 
					MemeDB.USERS_DB, 
					username, 
					MemeDB.CONTENT_JSON, 
					cred.getUsername());

		userdoc.setRevisionData(definition);
		if(!forUpdate)
			userdoc.put("password", BCrypt.hashpw(password, BCrypt.gensalt()));
		userdoc.put("is_sa", sa);
		return userdoc;
	}
}
