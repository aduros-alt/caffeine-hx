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

package memedb;

import java.io.File;
import java.util.Properties;

import memedb.auth.Authentication;
import memedb.backend.Backend;
import memedb.backend.BackendException;
import memedb.document.Document;
import memedb.events.ExternalEventConsumer;
import memedb.fulltext.FulltextEngine;
import memedb.httpd.HTTPDServer;
import memedb.state.DBState;
import memedb.utils.Logger;
import memedb.views.ViewException;
import memedb.views.ViewManager;

/*
<fponticelli> meme (n) : any unit of cultural information, such as a practice or idea, that is transmitted verbally or by repeated action from one mind to another. Examples include thoughts, ideas, theories, practices, habits, songs, dances and moods and terms such as race, culture, and ethnicity; a self-propagating unit of cultural evolution having a resemblance to the gene (the unit of genetics)
*/
/**
* The main database server
* @author mbreese
* @author Russell Weir
*/
public class MemeDB {
	public static final String USERS_DB = "_users";
	public static final String SYS_DB = "_sys";
	public static final String CONTENT_JSON = "application/json";

	private boolean shutdown = false;

	protected Logger log;

	protected final DBState state;
	protected final Backend backend;
	protected final ExternalEventConsumer eventConsumer;
	protected final HTTPDServer httpd;
	protected final Authentication auth;
	protected final ViewManager viewManager;
	protected final FulltextEngine fulltextManager;
	
	protected final Properties properties;

	public MemeDB () {
		this.properties = MemeDBProperties.getProperties();
		initLogging();
		this.state = buildState();
		this.backend = buildBackend();
		this.auth = buildAuthentication();
		this.eventConsumer = buildEventConsumer();
		this.fulltextManager = buildFulltextManager();
		this.httpd = buildHTTPD();
		this.viewManager = buildViewManager();
	}
	public MemeDB (Backend backend) {
		this.properties = MemeDBProperties.getProperties();
		initLogging();
		this.state = buildState();
		this.backend=backend;
		this.auth = buildAuthentication();
		this.eventConsumer = buildEventConsumer();
		this.fulltextManager = buildFulltextManager();
		this.httpd = buildHTTPD();
		this.viewManager = buildViewManager();
	}
	public MemeDB (Properties properties) {
		this.properties = MemeDBProperties.getProperties();
		initLogging();
		this.properties.putAll(properties);
		this.state = buildState();
		this.backend = buildBackend();
		this.auth = buildAuthentication();
		this.eventConsumer = buildEventConsumer();
		this.fulltextManager = buildFulltextManager();
		this.httpd = buildHTTPD();
		this.viewManager = buildViewManager();
	}
	public MemeDB (Backend backend, Properties properties) {
		this.properties = MemeDBProperties.getProperties();
		initLogging();
		this.properties.putAll(properties);
		this.state = buildState();
		this.backend=backend;
		this.auth = buildAuthentication();
		this.eventConsumer = buildEventConsumer();
		this.fulltextManager = buildFulltextManager();
		this.httpd = buildHTTPD();
		this.viewManager = buildViewManager();
	}

	protected void initLogging() {
		Logger.setDefaultLevel(getProperty("log.level", "warn"));
		log = Logger.get(MemeDB.class);
	}

	protected DBState buildState() {
		String stateClassStr = getProperty("state.class");
		try {
			return (DBState) getClass().getClassLoader().loadClass(stateClassStr).newInstance();
		} catch (InstantiationException e) {
			e.printStackTrace();
			throw new RuntimeException(e);
		} catch (IllegalAccessException e) {
			e.printStackTrace();
			throw new RuntimeException(e);
		} catch (ClassNotFoundException e) {
			e.printStackTrace();
			throw new RuntimeException(e);
		}
	}

	protected Backend buildBackend() {
		String backendClassStr = getProperty("backend.class");
		try {
			return (Backend) getClass().getClassLoader().loadClass(backendClassStr).newInstance();
		} catch (InstantiationException e) {
			e.printStackTrace();
			throw new RuntimeException(e);
		} catch (IllegalAccessException e) {
			e.printStackTrace();
			throw new RuntimeException(e);
		} catch (ClassNotFoundException e) {
			e.printStackTrace();
			throw new RuntimeException(e);
		}
	}

	protected ViewManager buildViewManager() {
		String viewClassStr = getProperty("view.class");
		try {
			ViewManager vm = (ViewManager) getClass().getClassLoader().loadClass(viewClassStr).newInstance();
			return vm;
		} catch (InstantiationException e) {
			e.printStackTrace();
			throw new RuntimeException(e);
		} catch (IllegalAccessException e) {
			e.printStackTrace();
			throw new RuntimeException(e);
		} catch (ClassNotFoundException e) {
			e.printStackTrace();
			throw new RuntimeException(e);
		}
	}

	protected Authentication buildAuthentication() {
		String authClassName = getProperty("auth.class");
		try {
			return (Authentication) getClass().getClassLoader().loadClass(authClassName).newInstance();
		} catch (InstantiationException e) {
			e.printStackTrace();
			throw new RuntimeException(e);
		} catch (IllegalAccessException e) {
			e.printStackTrace();
			throw new RuntimeException(e);
		} catch (ClassNotFoundException e) {
			e.printStackTrace();
			throw new RuntimeException(e);
		}
	}

	protected ExternalEventConsumer buildEventConsumer() {
		String evtClassStr = getProperty("eventhandler.class");
		try {
			return (ExternalEventConsumer) getClass().getClassLoader().loadClass(evtClassStr).newInstance();
		} catch (InstantiationException e) {
			e.printStackTrace();
			throw new RuntimeException(e);
		} catch (IllegalAccessException e) {
			e.printStackTrace();
			throw new RuntimeException(e);
		} catch (ClassNotFoundException e) {
			e.printStackTrace();
			throw new RuntimeException(e);
		}
	}

	protected FulltextEngine buildFulltextManager() {
		String fulltextClassStr = getProperty("fulltext.class");
		try {
			return (FulltextEngine) getClass().getClassLoader().loadClass(fulltextClassStr).newInstance();
		} catch (InstantiationException e) {
			e.printStackTrace();
			throw new RuntimeException(e);
		} catch (IllegalAccessException e) {
			e.printStackTrace();
			throw new RuntimeException(e);
		} catch (ClassNotFoundException e) {
			e.printStackTrace();
			throw new RuntimeException(e);
		}
	}
		
	protected HTTPDServer buildHTTPD() {
		if (getProperty("server.start").equals("true")) {
			return new HTTPDServer(this);
		} else {
			return null;
		}
	}

	public void init() {
		log.info("Initializing engine");
		try {
			state.init(this);
			backend.init(this);
			fulltextManager.init(this);
			viewManager.init(this);
			if (auth != null)
				auth.init(this);
			eventConsumer.init(this);
			if (httpd != null)
				httpd.init();
		} catch (Exception e) {
			log.error("Startup error " + e.toString());
			e.printStackTrace();
			internalShutdown();
			throw new RuntimeException(e);
		}
	}

	public void shutdown() {
		shutdown=true;
	}

	private void internalShutdown() {
		log.info("Shutting down engine");
		if (httpd!=null) {
			httpd.shutdown();
		}
		eventConsumer.shutdown();
		if (auth!=null) {
			auth.shutdown();
		}
		viewManager.shutdown();
		fulltextManager.shutdown();
		backend.shutdown();
		state.shutdown();
		log.info("Shutdown complete");
	}

	public static void main(String[] args) {
		final MemeDB app = new MemeDB();

		final Thread hook = new Thread() {
			@Override
			public void run() {
				app.internalShutdown();
			}
		};

		Runtime.getRuntime().addShutdownHook(hook);

		app.run();

		Runtime.getRuntime().removeShutdownHook(hook);
	}

	private void run() {
		init();
		while (!shutdown) {
			try {
				Thread.sleep(1000);
			} catch (InterruptedException e) {
				shutdown = true;
			}
		}
		try { Thread.sleep(1000); } catch (InterruptedException e) {}
		internalShutdown();
	}

	/**
	* This should only be called from a DBState implementation.
	*/
	public void onDocumentUpdate(Document doc) {
		try {
			viewManager.recalculateDocument(doc);
		}
		catch(Exception e) {
			if(e instanceof javax.script.ScriptException) { }
			else {
				log.warn("Uncaught exception in viewManager.recalculateDocument : {}", e);
				e.printStackTrace();
			}
		}
		try {
			eventConsumer.onDocumentUpdated(doc.getDatabase(), doc.getId(), doc.getRevision(), doc.getSequence());
		}
		catch(Exception e) {
			log.warn("Uncaught exception in viewManager.recalculateDocument : {}", e);
			e.printStackTrace();
		}
	}

	/**
	* This should only be called from a DBState implementation.
	*/
	public void onDocumentDeleting(String db, String id, long seq) {
		try {
			viewManager.deletingDocument(db, id, seq);
		}
		catch(Exception e) {
			log.warn("Uncaught exception in viewManager.deletingDocument : {}", e);
			e.printStackTrace();
		}
		try {
			eventConsumer.onDocumentDeleted(db, id, seq);
		}
		catch(Exception e) {
			log.warn("Uncaught exception in eventConsumer.onDocumentDeleted : {}", e);
			e.printStackTrace();
		}
		try {
			fulltextManager.onDocumentDeleted(db, id, seq);
		}
		catch(Exception e) {
			log.warn("Uncaught exception in fulltextManager.onDocumentDeleted : {}", e);
			e.printStackTrace();
		}
	}

	public void addDatabase(String db) throws BackendException, ViewException {
		long seq = backend.addDatabase(db);
		viewManager.onDatabaseCreated(db, seq);
		eventConsumer.onDatabaseCreated(db, seq);
		fulltextManager.onDatabaseCreated(db, seq);
	}

	public void deleteDatabase(String db) throws BackendException, ViewException {
		long seq = backend.deleteDatabase(db);
		viewManager.onDatabaseDeleted(db, seq);
		eventConsumer.onDatabaseDeleted(db, seq);
		fulltextManager.onDatabaseDeleted(db, seq);
	}

	public ViewManager getViewManager() {
		return viewManager;
	}

	public Authentication getAuthentication() {
		return auth;
	}

	public Backend getBackend() {
		return backend;
	}

	public FulltextEngine getFulltextEngine() {
		return fulltextManager;
	}

	public String getProperty(String key, String def) {
		return properties.getProperty(key,def);
	}

	public String getProperty(String key) {
		return properties.getProperty(key);
	}
	
	public DBState getState() {
		return state;
	}

	/**
	* Returns true if the named database is a special (not deletable)
	* database.
	*/
	public boolean isSystemDb(String name) {
		return (name == USERS_DB || name == SYS_DB);
	}
}
