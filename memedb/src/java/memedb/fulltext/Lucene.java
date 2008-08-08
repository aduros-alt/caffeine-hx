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

package memedb.fulltext;

import memedb.MemeDB;

import java.io.File;
import java.io.IOException;
import java.util.HashMap;

import org.apache.lucene.analysis.Analyzer;
import org.apache.lucene.analysis.standard.StandardAnalyzer;
import org.apache.lucene.document.Document;
import org.apache.lucene.index.CorruptIndexException;
import org.apache.lucene.index.IndexReader;
import org.apache.lucene.index.IndexWriter;
import org.apache.lucene.index.Term;
import org.apache.lucene.search.Hits;
import org.apache.lucene.search.IndexSearcher;
import org.apache.lucene.search.Searcher;
import org.apache.lucene.search.Query;
import org.apache.lucene.store.LockObtainFailedException;
import org.apache.lucene.queryParser.QueryParser;
import org.apache.lucene.queryParser.ParseException;



import memedb.utils.Logger;

/**
 * @todo The analyzer should be configurable for language in the memedb.properties
 * @author Russell Weir
 */
public class Lucene extends FulltextEngine {
	public static final String STATE_PATH = "fulltext.lucene.path";

	final private Logger log = Logger.get(Lucene.class);
	private HashMap<String, IndexWriter> writers = new HashMap<String, IndexWriter>();
	private HashMap<String, IndexReader> readers = new HashMap<String, IndexReader>();
	private File stateDir;
	
	@Override
	public void init(MemeDB memeDB) {
		super.init(memeDB);
		
		String path = memeDB.getProperty(STATE_PATH);
		if (path == null) {
			throw new RuntimeException(
				"You must include a "+STATE_PATH+" element in memedb.properties");
		}
		this.stateDir = new File(path);
		if(!stateDir.exists()) {
			log.info("Creating lucene directory " + path);
			stateDir.mkdirs();
		} else if (!stateDir.isDirectory()) {
			log.error("Path: {} not valid!", path);
			throw new RuntimeException("Path: " + path + " not valid!");
		}
	}
	
	public void onDatabaseDeleted(String db, long seq) {
		this.abort(db);
		File path = this.indexPath(db);
		memedb.utils.FileUtils.deleteRecursive(path);
	}
	
	public void onDatabaseCreated(String db, long seq) {
		this.abort(db);
		File path = indexPath(db);
		if(!path.exists()) {
			log.info("Creating lucene directory {} for db {}", path.getPath(), db);
			path.mkdirs();
		}
		try {
			writers.put(db, new IndexWriter(path, new StandardAnalyzer(), true));
			readers.put(db, IndexReader.open(path));
		} catch(CorruptIndexException e) {
		} catch(LockObtainFailedException e) {
		} catch(IOException e) {
		}
	}
	
	public void onDocumentDeleted(String db, String id, long seq) {
		removeResult(db, id);
	}
	
	public void removeResult(String db, String id) {
		IndexWriter writer = writers.get(db);
		if(writer == null) {
			log.error("Missing IndexWriter for database {}", db);
			return;
		}
		try {
			writer.deleteDocuments(new Term("_id", id));		
		} catch(CorruptIndexException e) {
		} catch(IOException e) {
		}
	}
	
	public void onFulltextResult(
			memedb.document.Document doc, 
			org.apache.lucene.document.Document luceneDoc) throws FulltextException
	{
		if(luceneDoc == null)
			return;
		String db = doc.getDatabase();
		IndexWriter writer = writers.get(db);
		if(writer == null) {
			log.error("Missing IndexWriter for database {}", db);
			return;
		}
		try {
			writer.addDocument(luceneDoc);
		} catch( CorruptIndexException e ) {
			throw new IndexCorruptException(db);
		} catch( IOException e ) {
			throw new FulltextException(db);
		} 
	}
	
	public synchronized void runQuery(String db, String defaultField, String queryString) {
		IndexReader reader = readers.get(db);
		Searcher searcher = new IndexSearcher(reader);
		Analyzer analyzer = new StandardAnalyzer();

		QueryParser qp = new QueryParser(defaultField, analyzer);
		try {
			Query query = qp.parse(queryString);
			Hits hits = searcher.search(query);
			for (int i = 0; i < hits.length(); i ++) {
				Document doc = hits.doc(i);
				String id = doc.get("_id");
				if(id != null) {
					String rev = doc.get("_rev");
					System.out.println("Query found doc " + id + "/"+ rev);
				} else {
					log.warn("No id field for Lucene document");
				}
			}
		} catch(ParseException pe) {
			log.warn("Query parse exception {}", pe);
		} catch(IOException e) {
			log.warn("Query IO error {}", e);
		}
	}
	
	public void shutdown() {
		for(String db: writers.keySet()) {
			close(db);
		}
	}
	
	/**
	 * Returns the base path for the indexing results for the database specified
	 * @param db Database name, unencoded
	 * @return new File object
	 */
	protected File indexPath(String db) {
		return new File(stateDir, memedb.utils.FileUtils.fsEncode(db));
	}
	
	/**
	 * Forcibly shuts down readers and writers for a db and removes the
	 * results path
	 * @param db Database name
	 */
	protected void abort(String db) {
		File path = indexPath(db);
		IndexWriter writer = writers.get(db);
		try {
			if(writer != null)
				writer.abort();
		} catch(IOException e) {}
		IndexReader reader = readers.get(db);
		try {
			if(reader != null)
				reader.close();
		} catch(IOException e) {}
		memedb.utils.FileUtils.deleteRecursive(path);
	}
	
	/**
	 * Gracefully shuts down readers and writers for a db
	 * @param db Database name
	 */
	protected void close(String db) {
		IndexWriter writer = writers.get(db);
		try {
			if(writer != null)
				writer.close();
		} catch(IOException e) {}
		IndexReader reader = readers.get(db);
		try {
			if(reader != null)
				reader.close();
		} catch(IOException e) {}
	}
}
