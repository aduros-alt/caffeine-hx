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

package memedb.views;

import org.apache.lucene.document.Document;
import org.apache.lucene.document.Field;
import org.apache.lucene.document.Field.Index;
import org.apache.lucene.document.Field.Store;

/**
 *
 * @author Russell Weir
 */
public class FulltextResult {
	protected final String id;
	protected final String rev;
	protected final Document doc;
	protected boolean hasResult=false;
	
	public FulltextResult(String id, String rev) {
		this.doc = new Document();
		this.id = id;
		this.rev = rev;
		
		doc.add(new Field("_id", id, Field.Store.YES, Field.Index.UN_TOKENIZED));
		doc.add(new Field("_rev", rev, Field.Store.YES, Field.Index.NO));
	}
	
	public void tokenize(String key, String str) {
		if(key == null || "_id".equals(key) || "_rev".equals(key) || str == null || "".equals(str))
			return;
		doc.add(new Field(key, str, Store.NO, Index.TOKENIZED));
		hasResult = true;
	}
	
	public boolean hasResult() {
		return hasResult;
	}
	
	public Document getDocument() {
		return this.doc;
	}
}
