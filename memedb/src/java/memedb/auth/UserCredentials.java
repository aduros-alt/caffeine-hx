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

import org.json.JSONObject;

import memedb.document.Document;
import memedb.document.JSONDocument;

/**
 * User credentials.  The user credentials should contain a JSONObject named "db_access".
 * This JSONObject will contain a list of database names with either "ro", "wo", or "rw".
 *
 * Example document:<pre>
 * {
 *   _id = "username",
 *   _rev = "...",
 *   _db = "_users"
 *   password="hash of password",
 *   is_sa = false,
 *   db_access = {
 *          "foo" = "ro",
 *          "bar" = "rw"
 *        }
 * }
 * </pre>
 *
 * @author mbreese
 * @author Russell Weir
 */
public class UserCredentials extends Credentials{
	protected final Document doc;
	protected JSONObject dbs;
	public UserCredentials(JSONDocument doc, String token, int timeout) {
		super(doc.getId(),token,(Boolean)doc.get("is_sa"),timeout);
		this.doc=doc;
		dbs = (JSONObject) doc.get("db_access");
	}

	@Override
	public boolean isAuthorizedRead(String db) {
		if (isSA()) { return true; }
		if (dbs.get(db)!=null) {
			return dbs.getString(db).contains("r");
		}
		return false;
	}

	@Override
	public boolean isAuthorizedWrite(String db) {
		if (isSA()) { return true; }
		if (dbs.get(db)!=null) {
			return dbs.getString(db).contains("w");
		}
		return false;
	}

	@Override
	public boolean isAuthorizedReadDocument(String db, String id) {
		return isAuthorizedRead(db);
	}

	@Override
	public boolean isAuthorizedUpdateDocument(String db, String id) {
		return isAuthorizedWrite(db);
	}

	@Override
	public boolean isAuthorizedDeleteDocument(String db, String id) {
		return isAuthorizedRead(db);
	}

	@Override
	public boolean isAuthorizedSeeView(String db, String viewPath) {
		return isAuthorizedRead(db);
	}

}
