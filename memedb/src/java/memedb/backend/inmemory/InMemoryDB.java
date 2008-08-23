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

package memedb.backend.inmemory;

import java.io.Serializable;
import java.util.Collection;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

import memedb.backend.Backend;
import memedb.document.Document;

public class InMemoryDB implements Serializable {
	/**
	 *
	 */
	private static final long serialVersionUID = 3305138416001352871L;
	final private String name;
	final private Map<String,InMemoryDocument> docs = new ConcurrentHashMap<String,InMemoryDocument>();
	final private Long creationSequenceNumber;
	
	transient protected Backend backend;

	/**
	 * Creates a new database at sequence number seqNo tied to the
	 * backend provided
	 * @param name Database name
	 * @param backend Backend instance
	 * @param seqNo Datbase creation sequence number
	 */
	public InMemoryDB(String name, Backend backend, long seqNo) {
		this.name = name;
		this.backend = backend;
		this.creationSequenceNumber = new Long(seqNo);
	}

	public InMemoryDocument get(String id) {
		return docs.get(id);
	}

	public Collection<InMemoryDocument> getAllDocuments() {
		return docs.values();
	}

	public Long getDatabaseCreationSequenceNumber() {
		return creationSequenceNumber;
	}
	
	public Long getDocumentCount() {
		return new Long(docs.size());
	}
	
	public String getName() {
		return name;
	}
	
	public void init(Backend backend) {
		this.backend = backend;
		for(InMemoryDocument doc: docs.values())
			doc.init(backend);
	}
		
	public void remove(String id) {
		docs.remove(id);
	}
		
	public void save(Document doc) {
		if (docs.containsKey(doc.getId())) {
			docs.get(doc.getId()).update(doc);
		} else {
			docs.put(doc.getId(), new InMemoryDocument(doc, backend));
		}
	}

	public int size() {
		return docs.size();
	}
}
