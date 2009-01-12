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

import memedb.document.JSONDocument;

/**
 * User credentials.
 * Example document: <pre>
 * {
 *	"username": "foouser",	// (required)
 *	"password": "password",	// (required) must be > 4 chars other 
 *							// than the special 'anonymous' user.
 *	"is_sa": false,			// is System Administrator
 *	"defaults": {			// defaults for all dbs
 *		"drop_db": false,	// can drop databases
 *		"create_db": false	// can create databases
 *		"read": true,		// can read a document
 *		"create": true,		// can create new documents
 *		"update": true,		// can update existing documents
 *		"run_views": true,  // can run stored views
 *		"create_views":true,// can create stored views
 *		"adhoc": true
 *		"view_access": {
 *			"_all_docs" : true
 *		}
 *	},
 *	"db_access": {
 *		"foo": {
 *			"drop_db": true,
 *			"create_db": true,
 *			"read": true,
 *			"create": true,
 *			"update": true,
 *			"run_views": true,
 *			"create_views":true,
 *			"adhoc": false,
 *			"view_access": {
 *				"_privateView" : false,
 *				"_publicView" : true
 *			}
 *		}
 *	}
 * }
 * </pre>
 *
 * @author Russell Weir
 **/  
public class UserCredentials extends JSONCredentials{

	public UserCredentials(JSONDocument doc, String token, int timeout) {
		super(doc, token, timeout);
	}

	@Override
	public boolean canDropDatabase(String db) {
		if (isSA()) { return true; }
		return getPerm(db, "drop_db", false);
	}
	
	@Override
	public boolean canCreateDatabase(String db) {
		if (isSA()) { return true; }
		return getPerm(db, "create_db", false);
	}
	
	@Override
	public boolean canReadDocuments(String db) {
		if (isSA()) { return true; }
		return getPerm(db, "read", true);
	}
	
	@Override
	public boolean canCreateDocuments(String db) {
		if (isSA()) { return true; }
		return getPerm(db, "create", true);
	}
	
	@Override
	public boolean canDeleteDocuments(String db) {
		if (isSA()) { return true; }
		return getPerm(db, "delete", true);
	}
	
	@Override
	public boolean canUpdateDocuments(String db) {
		if (isSA()) { return true; }
		return getPerm(db, "update", true);
	}
	
	@Override
	public boolean canCreateView(String db, String id) {
		if (isSA()) { return true; }
		boolean defaultValue = getPerm(db, "create_views", true);
		return getViewPerm(db, id, defaultValue);
	}
	
	@Override
	public boolean canRunView(String db, String id) {
		if (isSA()) { return true; }
		boolean defaultValue = getPerm(db, "run_views", true);
		return getViewPerm(db, id, defaultValue);
	}
	
	@Override
	public boolean canRunAdhoc(String db) {
		if (isSA()) { return true; }
		return getPerm(db, "adhoc", true);
	}
	
	@Override
	public boolean canSeeDbStats(String db) {
		return getPerm(db, "view_db_stats", true);
	}
	
	@Override
	public boolean canSeeDbNames() {
		return getDefaultPerm("view_db_names", false);
	}

}
