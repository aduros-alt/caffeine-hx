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
package memedb.state;

import memedb.document.Document;
import memedb.backend.Backend;

/**
* An event as stored in the DBState
* @author Russell Weir
*/
public class StateEvent {
	public static final String STR_DOC_UPDATE = "update_doc";
	public static final String STR_DOC_DELETE = "delete_doc";
	public static final String STR_DB_CREATE = "db_create";
	public static final String STR_DB_DELETE = "db_delete";
	public static final String STR_EVENT_UNKNOWN = "unknown";

	public static final int EVENT_DOC_UPDATE_ID =	1;
	public static final int EVENT_DOC_DELETE_ID =	1<<1;
	public static final int EVENT_DB_CREATE_ID =	1<<2;
	public static final int EVENT_DB_DELETE_ID =	1<<3;

	private long sequence = -1;
	private String description = "unknown";
	private int type_id = 0;
	private String db;
	private String id;
	private String rev;
	private boolean hasChainedData;
	private Document doc;

	public StateEvent(long seqNo, int type_id, String db ) {
		this.sequence = seqNo;
		this.type_id = type_id;
		this.db = db;
		updateDescription();
	}

	public StateEvent(long seqNo, int type_id, String db, String id ) {
		this.sequence = seqNo;
		this.type_id = type_id;
		this.db = db;
		this.id = id;
		updateDescription();
	}

	public StateEvent(long seqNo, int type_id, String db, String id, String rev ) {
		this.sequence = seqNo;
		this.type_id = type_id;
		this.db = db;
		this.id = id;
		this.rev = rev;
		updateDescription();
	}

	public StateEvent(long seqNo, int type_id, String db, String id, String rev, Document doc ) {
		this.sequence = seqNo;
		this.type_id = type_id;
		this.db = db;
		this.id = id;
		this.rev = rev;
		this.doc = doc;
		this.hasChainedData = doc != null;
		updateDescription();
	}


	public String getDatabase() {
		return db;
	}

	public String getDescription() {
		return description;
	}

	/**
	* Will retrieve the document at the revision that this event represents
	*/
	public Document getDocumentAtRevision(Backend be) {
		return be.getDocument(db, id, rev);
	}

	/**
	* Will return the current document that this event represents, from the backend
	* @return The current document, or null if it no longer exists
	*/
	public Document getDocumentCurrent(Backend be) {
		return be.getDocument(db, id);
	}

	public String getDocumentId() {
		return id;
	}

	/**
	* Returns the attached chained data
	* @see hasChainedData
	**/
	public Document getChainedData() {
		return doc;
	}

	public long getSequence() {
		return sequence;
	}

	public int getTypeId() {
		return type_id;
	}

	public String getRevision() {
		return rev;
	}

	/**
	* If the DBState stored the full document, this will return true
	**/
	public boolean hasChainedData() {
		return hasChainedData && doc != null;
	}

	public boolean isForDatabase(String dbName) {
		if(dbName == null) return false;
		return dbName.equals(db);
	}

	public boolean isDatabaseEvent() {
		return (type_id == EVENT_DB_CREATE_ID || type_id == EVENT_DB_DELETE_ID);
	}

	public boolean isDatabaseDelete() {
		return type_id == EVENT_DB_DELETE_ID;
	}

	public boolean isDatabaseCreate() {
		return type_id == EVENT_DB_CREATE_ID;
	}

	public boolean isDocumentEvent() {
		return (type_id == EVENT_DOC_UPDATE_ID || type_id == EVENT_DOC_DELETE_ID);
	}

	public boolean isDocumentDelete() {
		return type_id == EVENT_DOC_DELETE_ID;
	}

	public boolean isDocumentUpdate() {
		return type_id == EVENT_DOC_UPDATE_ID;
	}

	public String toString() {
		String rv = "{ seq: " +sequence+ ", description: " + description;
		rv += " type_id: " + type_id + " db: " + db ;
		if(id != null) {
			rv += " id: " + id;
		}
		if(rev != null)
			rv += " rev: " + rev;
		if(hasChainedData) {
			rv += " hasChainedData=true";
			if(doc == null) {
				rv += " chained data bad";
			} else {
				rv += doc.toString();
			}
		}
		rv += " }";
		return rv;
	}

	public String toString(int i) {
		return toString();
	}

	private void updateDescription() {
		switch(type_id) {
		case EVENT_DOC_UPDATE_ID: description = STR_DOC_UPDATE; break;
		case EVENT_DOC_DELETE_ID: description = STR_DOC_DELETE; break;
		case EVENT_DB_CREATE_ID: description = STR_DB_CREATE; break;
		case EVENT_DB_DELETE_ID: description = STR_DB_DELETE; break;
		default:
			description = STR_EVENT_UNKNOWN; break;
		}
	}
}