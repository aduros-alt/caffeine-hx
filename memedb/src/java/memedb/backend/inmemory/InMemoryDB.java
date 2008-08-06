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
	transient protected Backend backend;

	public InMemoryDB(String name, Backend backend) {
		this.name = name;
		this.backend = backend;
	}

	public void init(Backend backend) {
		this.backend = backend;
		for(InMemoryDocument doc: docs.values())
			doc.init(backend);
	}

	public InMemoryDocument get(String id) {
		return docs.get(id);
	}

	public void save(Document doc) {
		if (docs.containsKey(doc.getId())) {
			docs.get(doc.getId()).update(doc);
		} else {
			docs.put(doc.getId(), new InMemoryDocument(doc, backend));
		}
	}

	public void remove(String id) {
		docs.remove(id);
	}

	public String getName() {
		return name;
	}

	public Collection<InMemoryDocument> getAllDocuments() {
		return docs.values();
	}
	public int size() {
		return docs.size();
	}
}
