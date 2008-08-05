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

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.Serializable;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

import org.json.JSONObject;

import memedb.backend.Backend;
import memedb.document.Document;
import memedb.document.DocumentCreationException;

public class InMemoryDocument implements Serializable{
	/**
	 *
	 */
	private static final long serialVersionUID = -8164429846100317197L;
	final private String id;
	private String currentRevision;
	private JSONObject common = new JSONObject();

	private Map<String,byte[]> revisions = new ConcurrentHashMap<String,byte[]>();
	private Map<String,JSONObject> metaData = new ConcurrentHashMap<String,JSONObject>();

	transient protected Backend backend;

	public InMemoryDocument(String id, Backend backend) {
		this.id=id;
		this.backend = backend;
	}
	public InMemoryDocument(Document doc, Backend backend) {
		this.id=doc.getId();
		this.backend = backend;
		update(doc);
	}
	public String getId() {
		return id;
	}

	public void init(Backend backend) {
		this.backend = backend;
	}

	public void update(Document doc) {
		this.common = new JSONObject();
		this.currentRevision = doc.getRevision();

		common.putAll(doc.getCommonData());

		if (doc.writesRevisionData()) {
			ByteArrayOutputStream baos = new ByteArrayOutputStream();
			try {
				doc.writeRevisionData(baos);
			} catch (IOException e) {
				e.printStackTrace();
			}
			revisions.put(doc.getRevision(), baos.toByteArray());
		}
		// write out all "_name" keys to common file (exclude backend/id/revision)
		metaData.put(doc.getRevision(), doc.getMetaData());
	}

	public Document getRevision() throws DocumentCreationException {
		return getRevision(null);
	}
	public JSONObject getCommon() {
		JSONObject newCommon = new JSONObject(common);
		newCommon.put("_current_rev", currentRevision);
		return newCommon;
	}
	public Document getRevision(String revision) throws DocumentCreationException {
		if (revision==null) {
			revision=currentRevision;
		}
		Document d = Document.loadDocument(backend, common, metaData.get(revision));
		if (d.writesRevisionData()) {
			d.setRevisionData(new ByteArrayInputStream(revisions.get(revision)));
		}
		return d;
	}
	public String getCurrentRevision() {
		return currentRevision;
	}
	public Set<String> getRevisions() {
		return revisions.keySet();
	}
	public void touchRevision(String rev) {
		revisions.put(rev, null);
	}
}
