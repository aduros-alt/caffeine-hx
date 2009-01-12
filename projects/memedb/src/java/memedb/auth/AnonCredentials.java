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
 * Default permissions for the special user 'anonymous'
 * @author Russell Weir
 */
public class AnonCredentials extends JSONCredentials {

	protected static JSONDocument defaultDoc;
	
	public static void setDefaultAnonDocument(JSONDocument doc) {
		defaultDoc = doc;
	}
	
	public AnonCredentials(JSONDocument doc, String token, int timeout) {
		super(doc, token, false, timeout);
	}
	
	public AnonCredentials(String token, int timeout) {
		super(defaultDoc, token, false, timeout);
	}
	
	@Override
	public boolean canDropDatabase(String db) {
		return getPerm(db, "drop_db", false);
	}
	
	@Override
	public boolean canCreateDatabase(String db) {
		return getPerm(db, "create_db", false);
	}
	
	@Override
	public boolean canReadDocuments(String db) {
		return getPerm(db, "read", false);
	}
	
	@Override
	public boolean canCreateDocuments(String db) {
		return getPerm(db, "create", false);
	}
	
	@Override
	public boolean canDeleteDocuments(String db) {
		if (isSA()) { return true; }
		return getPerm(db, "delete", true);
	}
	
	@Override
	public boolean canUpdateDocuments(String db) {
		return getPerm(db, "update", false);
	}
	
	@Override
	public boolean canCreateView(String db, String id) {
		boolean defaultValue = getPerm(db, "create_views", false);
		return getViewPerm(db, id, defaultValue);
	}
	
	@Override
	public boolean canRunView(String db, String id) {
		boolean defaultValue = getPerm(db, "run_views", true);
		return getViewPerm(db, id, defaultValue);
	}
	
	@Override
	public boolean canRunAdhoc(String db) {
		return getPerm(db, "adhoc", false);
	}
	
	@Override
	public boolean canSeeDbStats(String db) {
		return getPerm(db, "view_db_stats", false);
	}
	
	@Override
	public boolean canSeeDbNames() {
		return getDefaultPerm("view_db_names", false);
	}
	
	public static String defaultJSON() {
		return 
		"{" + 
			"\"username\": \"anonymous\"," +
			"\"password\": \"\"," +
			"\"is_sa\": false," +
			"\"defaults\": {" +
			"	\"drop_db\": false," +
			"	\"create_db\": false," +
			"	\"read\": false," +
			"	\"create\": false," +
			"	\"update\": false," +
			"	\"delete\": false," +
			"	\"run_views\": true," +
			"	\"create_views\":false," +
			"	\"adhoc\": false," +
			"	\"view_db_stats\": false," +
			"	\"view_db_names\": false," +
			"	\"view_access\": {" +
			"		\"_all_docs\" : false" +
			"	}" +
			"}," +
			"\"db_access\": {" +
			"}" +
		"}";
	}
	
	public static String allAccessJSON() {
		return 
		"{" + 
			"\"username\": \"anonymous\"," +
			"\"password\": \"\"," +
			"\"is_sa\": false," +
			"\"defaults\": {" +
			"	\"drop_db\": true," +
			"	\"create_db\": true," +
			"	\"read\": true," +
			"	\"create\": true," +
			"	\"update\": true," +
			"	\"delete\": true," +
			"	\"run_views\": true," +
			"	\"create_views\":true," +
			"	\"adhoc\": true," +
			"	\"view_db_stats\": true," +
			"	\"view_db_names\": true," +
			"	\"view_access\": {" +
			"		\"_all_docs\" : true" +
			"	}" +
			"}," +
			"\"db_access\": {" +
			"}" +
		"}";
	}
}
