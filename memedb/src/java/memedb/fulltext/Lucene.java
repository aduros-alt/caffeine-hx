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
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

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
import org.apache.lucene.store.Directory;
import org.apache.lucene.store.FSDirectory;
import org.apache.lucene.store.LockObtainFailedException;
import org.apache.lucene.queryParser.QueryParser;
import org.apache.lucene.queryParser.ParseException;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import memedb.utils.Logger;

/**
 * @todo The analyzer should be configurable for language in the memedb.properties
 * @author Russell Weir
 */
public class Lucene extends FulltextEngine {
	public static final String STATE_PATH = "fulltext.lucene.path";

	final private Logger log = Logger.get(Lucene.class);
	private HashMap<String, IndexWriter> writers = new HashMap<String, IndexWriter>();
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
			Directory directory = FSDirectory.getDirectory(path.getPath());
			writers.put(db, new IndexWriter(directory,true,new StandardAnalyzer(), true));
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
		log.debug("onFulltextResult : {} luceneDoc {}", doc.getDatabase(), luceneDoc.toString());
		String db = doc.getDatabase();
		IndexWriter writer = writers.get(db);
		if(writer == null) {
			log.error("Missing IndexWriter for database {}", db);
			return;
		}
		try {
			writer.addDocument(luceneDoc);
			writer.flush();
		} catch( CorruptIndexException e ) {
			throw new IndexCorruptException(db);
		} catch( IOException e ) {
			throw new FulltextException(db);
		} 
	}
	
	protected Hits query(String db, String defaultField, String queryString) throws IOException, CorruptIndexException, ParseException {
		Directory directory = FSDirectory.getDirectory(indexPath(db));
		IndexReader reader = IndexReader.open(directory);

		Searcher searcher = new IndexSearcher(reader);
		Analyzer analyzer = new StandardAnalyzer();
		QueryParser qp = new QueryParser(defaultField, analyzer);
		Query query = qp.parse(queryString);
		return searcher.search(query);
	}
	
	protected ArrayList<JSONObject> queryFilter(Hits hits, Map<String,String> options) throws CorruptIndexException, IOException {
		Long key = findLongValue("key", options);
		Long startkey = findLongValue("startkey", options);
		Long endkey = findLongValue("endkey", options);
		boolean startInclusive = "false".equals(options.get("startkey_inclusive")) ? false : true;
		boolean endInclusive = "false".equals(options.get("endkey_inclusive")) ? false : true;
		boolean descending = "true".equals(options.get("descending"));
		Long skip = findLongValue("skip",options);
		Long count = findLongValue("count", options);
		
		ArrayList<JSONObject> rv = new ArrayList<JSONObject>();
		if(hits.length() == 0)
			return rv;
		int start = 0;
		int end = hits.length();
		
		if(key != null) {
			int v = key.intValue();
			startkey = key;
			endkey = key;
			startInclusive = true;
			endInclusive = true;
			skip = new Long(0);
			count = new Long(0);
		}
		if(startkey != null)
			start = startkey.intValue();
		if(endkey != null)
			end = endkey.intValue();
		if(!descending) {
			if(!startInclusive)
				start++;
			if(!endInclusive)
				end--;
			if(skip != null)
				start += skip.intValue();
			if(count != null) {
				int c = count.intValue();
				if(c >= 0) {
					if(start + c < end)
						end = start + c;
				} else {
					start = end + c;
				}
			}
			if(start < 0) start = 0;
			if(start >= hits.length())
				return rv;
			if(end < 0) end = 0;
			if(end > hits.length())
				end = hits.length();
			for(int c=start; c<end; c++) {
				Document doc = hits.doc(c);
				JSONObject o = new JSONObject();
				try {
					o.put("key", c);
					o.put("id", doc.get("_id"));
					o.put("rev", doc.get("_rev"));
					rv.add(o);
				} catch(JSONException e) {}	
			}	
		}
		else {
			int c = start;
			start = end;
			end = c;
			if(!startInclusive)
				start--;
			if(!endInclusive)
				end++;
			if(skip != null)
				start -= skip.intValue();
			if(count != null) {
				c = count.intValue();
				if(c >= 0) {
					if(start - c > end)
						end = start - c;
				} else {
					start = end - c;
				}
			}
			if(start >= hits.length())
				start = hits.length() -1;
			if(start < 0 || end >= start)
				return rv;

			if(end < -1) end = -1;
			if(end >= hits.length())
				end = hits.length() - 1;
			for(c=start; c>end; c--) {
				Document doc = hits.doc(c);
				JSONObject o = new JSONObject();
				try {
					o.put("key", c);
					o.put("id", doc.get("_id"));
					o.put("rev", doc.get("_rev"));
					rv.add(o);
				} catch(JSONException e) {}				
			}
		}
		return rv;
	}
	
	public synchronized JSONObject runQuery(String db, String defaultField, String queryString, Map<String,String> options) {
		log.debug("runQuery {} {} {}", db, defaultField, queryString);
		JSONObject o = new JSONObject();
		o.put("ok", false);
		JSONArray rows = new JSONArray();
		long count = 0;
		try {
			Hits hits = query(db, defaultField, queryString);
			log.debug("Query returned {} results", hits.length());
			ArrayList<JSONObject> d = queryFilter(hits, options);
			
			
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
			/*
//			for(Object o : reader.getFieldNames(IndexReader.FieldOption.ALL)) {
//				log.warn("FIELD: {}", o);
//			}
			*/
			count = d.size();
			rows = new JSONArray(d);
			o.put("ok", true);
		} catch(ParseException pe) {
			log.warn("Query parse exception {}", pe);
			o.put("error", "Query parse error");
		} catch(IOException e) {
			log.warn("Query IO error {}", e);
			o.put("error", "Internal error");
		} finally {
			o.put("rows", rows);
			o.put("total_rows", count);
			return o;
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
				writer.close();
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
	}
	
	static private Long findLongValue(String opt, Map<String,String> options) {
		if(!options.containsKey(opt))
			return null;
		try {
			return new Long(options.get(opt));
		} catch (Exception e) {
		}
		return null;
	}
}
