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

package memedb.backend;

import java.io.File;
import java.util.Map;
import java.util.Set;

import org.json.JSONArray;

import memedb.MemeDB;
import memedb.document.Document;
import memedb.utils.Lock;

public interface Backend {
	public void init(MemeDB memeDB);
	public void shutdown();

	public Set<String> getDatabaseNames();

	/**
	* This method must not be called directly, use
	* MemeDB.addDatabase().
	* The backend must contact the DBState to sequence the
	* database deletion <u>before</u> attempting to add
	* the database.
	* @return sequence number obtained from the DBState
	*/
	public long addDatabase(String name) throws BackendException;

	/**
	* Iterable for all documents in database
	*/
	public Iterable<Document> allDocuments(String db);

	/**
	* This method must not be called directly, use
	* MemeDB.deleteDatabase().
	* The backend must contact the DBState to sequence the
	* database deletion <u>before</u> attempting to remove
	* the database.
	* @return sequence number obtained from the DBState
	*/
	public long deleteDatabase(String name) throws BackendException;

	/**
	* Before actually deleting a database document, the backend must
	* call DBState.deleteDocument().
	*/
	public void deleteDocument(String db,String id) throws BackendException;

	public boolean doesDatabaseExist(String db);
	public boolean doesDocumentExist(String db, String id);
	public boolean doesDocumentRevisionExist(String db, String id, String revision);

	public Map<String,Object> getDatabaseStats(String name);

	/**
	* Iterable for documents in an array of ids
	*/
	public Iterable<Document> getDocuments(String db, String[] ids);

	public Document getDocument(String db,String id);
	public Document getDocument(String db,String id, String rev);
	public JSONArray getDocumentRevisions(String db,String id);

	/**
	* Returns the MemeDB instance
	*/
	public MemeDB getMeme();

	/**
	* Some content types (scripts) may need access to the actual
	* revision file path. If the backend is not backed on disk, this
	* should create a tempory file that can be used instead.
	* @throws BackendException if this is not possible or not implemented.
	**/
	public File getRevisionFilePath(Document doc) throws BackendException;

	/**
	* Retrieves a lock on the specified document
	**/
	public Lock lockForUpdate(String db,String id) throws BackendException;

	/**
	* Before saving a Document, the backend must call DBState.updateDocument()
	* and once the Document is physically committed, DBState.finalizeDocument().
	* If the Document has not been modifed, both should be skipped.
	*/
	public Document saveDocument(Document doc) throws BackendException;
	public Document saveDocument(Document doc, Lock lock) throws BackendException;


	public void touchRevision(String database, String id, String rev);

}
