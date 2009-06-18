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

package memedb.document;

//import com.sun.org.apache.xalan.internal.xsltc.cmdline.getopt.GetOpt;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.Writer;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;
import java.util.Random;
import java.util.UUID;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import memedb.backend.Backend;
import memedb.utils.Logger;

/**
 * Base class for any type of document that can be stored in MemeDB
 * @author mbreese
 * @author Russell Weir
 */
abstract public class Document {
	// build list of document content-type handling classes
	private static Map<String,Class<? extends Document>> docTypes = new HashMap<String,Class<?extends Document>> ();

	static {
		loadType(JSONDocument.class);
		loadType(BinaryDocument.class);
		loadType(TextDocument.class);
		loadType(CGIPhpDocument.class);
		loadType(CGINekoDocument.class);
	}
	private static void loadType(Class<? extends Document> clazz) {
		ContentTypes contentTypes = clazz.getAnnotation(ContentTypes.class);
		for (String type:contentTypes.value()) {
// 			System.out.println(type+" => "+clazz);
			docTypes.put(type.toLowerCase(), clazz);
		}
	}

	private static Random random = new Random();

	// constants
	public static final String DB = "_db";
	public static final String CONTENT_TYPE = "_content_type";
	public static final String CREATED_DATE = "_created_date";
	public static final String CURRENT_REVISION = "_current_revision";
	public static final String ID = "_id";
	public static final String REV = "_rev";
	public static final String REV_USER = "_rev_by";
	public static final String REV_DATE = "_rev_date";
	public static final String SEQ = "_seq";

	public static final String DEFAULT_CONTENT_TYPE = "application/json";

	// factory methods
	/**
	 * Creates a new document based on an existing document, copying in the
	 * id, contentType, class type and common data.
	 * @param parent	Existing database document
	 */
	public static Document newRevision(Backend backend, Document parent, String username) throws DocumentCreationException {
		return newDocument(backend, parent.getDatabase(), parent.getId(), parent.getContentType(), parent.getClass(), parent.commonData, username);
	}

	public static Document newDocument(Backend backend,String database, String id, String contentType, String username) throws DocumentCreationException {
		Class<? extends Document> clazz = docTypes.get(contentType.toLowerCase());
		if (clazz==null) {
			clazz = docTypes.get("*");
		}
		if (clazz==null) {
			throw new DocumentCreationException("Could not find backing class for content type: "+contentType);
		}
		return newDocument(backend,database,id,contentType,clazz,username);
	}

	/**
	* Creates a new Document with the default content type {@value #DEFAULT_CONTENT_TYPE}
	*/
	public static Document newDocument(Backend backend,String database, String id, String username) throws DocumentCreationException {
		return newDocument(backend,database,id,DEFAULT_CONTENT_TYPE,username);
	}

	public static Document newDocument(Backend backend,String database, String id, String contentType, Class<? extends Document> clazz,String username) throws DocumentCreationException  {
		return newDocument(backend,database,id,contentType,clazz,null,username);
	}

	protected static Document newDocument(Backend backend,String database, String id, String contentType, Class<? extends Document> clazz, JSONObject commonData, String username) throws DocumentCreationException  {
		if (id==null) {
			id=generateId(backend,database);
		}
		String revision=generateRevision(backend,database,id);
		Document d;
		try {
			if (contentType==null) {
				contentType = Document.DEFAULT_CONTENT_TYPE;
			} else {
				contentType = contentType.split(";")[0];
			}
			d = clazz.newInstance();
			d.backend = backend;
			if (commonData==null) {
				d.commonData = new JSONObject();
				d.commonData.put(ID,id);
				d.commonData.put(DB,database);
				d.commonData.put(CREATED_DATE,new Date().getTime());
				d.commonData.put(CONTENT_TYPE, contentType.toLowerCase());
				d.commonDirty = true;
			} else {
				d.commonData= new JSONObject(commonData);
			}
			d.metaData = new JSONObject();
			d.setRevision(revision);
			d.setRevisionDate(new Date());
			d.setRevisionUser(username);

			d.dataDirty=true;
			return d;
		} catch (InstantiationException e) {
			throw new DocumentCreationException(e);
		} catch (IllegalAccessException e) {
			throw new DocumentCreationException(e);
		}
	}

	protected static final String generateId(Backend backend, String database) {
		String id = null;
		while (id==null || backend.doesDocumentExist(database, id)) {
			UUID uuid = java.util.UUID.randomUUID();
			id = Long.toHexString(uuid.getLeastSignificantBits())+ Long.toHexString(uuid.getMostSignificantBits());
		}
		return id;
	}

	protected static final String generateRevision(Backend backend,String database, String id) {
		String rev = null;
		while (rev==null || !backend.touchRevision(database,id,rev)) {
			rev = Long.toHexString(random.nextLong());
		}
		return rev;
	}

	public static Document loadDocument(Backend backend, JSONObject commonJSON, JSONObject metaJSON) throws DocumentCreationException {
		Class<? extends Document> clazz = docTypes.get(commonJSON.get(CONTENT_TYPE));
		if (clazz==null) {
			clazz = docTypes.get("*");
		}
		if (clazz==null) {
			throw new DocumentCreationException("Could not find backing class for content type: "+commonJSON.get(CONTENT_TYPE));
		}
		try {
			Document d = clazz.newInstance();
			d.commonData=commonJSON;
			d.metaData=metaJSON;
			d.backend = backend;
			return d;
		} catch (InstantiationException e) {
			throw new DocumentCreationException(e);
		} catch (IllegalAccessException e) {
			throw new DocumentCreationException(e);
		}
	}


	// end statics

	protected Backend backend;
	protected JSONObject commonData  =null;
	protected JSONObject metaData = null;
	protected boolean commonDirty = false;
	protected boolean dataDirty = false;
	protected Logger log = Logger.get(getClass());

	/**
	 * Override if content type to send to browser is different than the document content type.
	 * @return Mime type for HTTP response
	 */
	public String getBrowserContentType() {
		return getContentType();
	}

	/**
	 * Returns the data that is common to all revisions of this document
	 * @return JSON object with common data information
	 */
	public JSONObject getCommonData() {
		return commonData;
	}

	/**
	 * Gets the MemeDB content type for this document. This is the content type
	 * that must be used by clients to create or update documents of this type.
	 * @return mime type
	 */
	public String getContentType() {
		try {
			return commonData.getString(CONTENT_TYPE);
		} catch (JSONException e) {
			//e.printStackTrace();
		}
		return null;
	}

	/**
	 * Retrieves the date that the document was originally created.
	 * @return date of first document instance
	 * @see GetRevisionDate
	 */
	public Date getCreated() {
		Long l = commonData.optLong(CREATED_DATE);
		if (l!=null) {
			return new Date(l);
		}
		return null;
	}

	/**
	 * Gets the database this document belongs to.
	 * @return Plain text database name
	 */
	public String getDatabase() {
		try {
			return commonData.getString(DB);
		} catch (JSONException e) {
			e.printStackTrace();
		}
		return null;
	}

	/**
	 * Returns the plain text id of the document.
	 * @return Then unencoded id
	 */
	public String getId() {
		try {
			return commonData.getString(ID);
		} catch (JSONException e) {
			e.printStackTrace();
		}
		return null;
	}

	/**
	 * Returns the meta data, which is all the revision specific information
	 * @return JSONObject of meta data revision information
	 */
	public JSONObject getMetaData() {
		return metaData;
	}

	/**
	 * The sequence number of the document revision
	 * @return long sequence number
	 */
	final public long getSequence() {
		return metaData.getLong(SEQ);
	}

	/**
	 * Returns the revision id for the document.
	 * @return string revision id
	 */
	public String getRevision() {
		return metaData.getString(REV);
	}

	/**
	 * Date of revision creation
	 * @return date revision was created
	 */
	public Date getRevisionDate() {
		return new Date(metaData.getLong(REV_DATE));
	}

	/**
	* Returns the required file extension (without the .) for the revision data
	* @see requiresRevisionExtension
	**/
	public String getRevisionExtension() {
		return "";
	}

	/**
	 * Returns the username that created this revision of the document. The
	 * user is that which is logged in through the _auth mechanism.
	 * @return string username
	 */
	public String getRevisionUser() {
		return metaData.getString(REV_USER);
	}

	/**
	 * Checks if the document common data has changed.
	 * @return true if the common data has been changed
	 */
	public boolean isCommonDirty() {
		return commonDirty;
	}

	/**
	 * Checks if the document meta data has changed.
	 * @return true if the meta data has been changed
	 */
	public boolean isDataDirty() {
		return dataDirty;
	}
	/**
	 * If the document requires a specific file extension for the revision data
	 * file, this must return true. This is necessary for at least CGINekoDocument
	 * @return True if the database must store a file with the given extension on disk
	 * @see getRevisionExtension
	 */
	public boolean requiresRevisionExtension() {
		return false;
	}

	/**
	 * Handler for sending document over HTTP. The default implementation sets the response code to SC_OK,
	 * the output Content-Type to getBrowserContentType, then calls sendBody.
	 * @param request Client HTTP request
	 * @param response Client HTTP response
	 * @throws java.io.IOException
	 */
	public void sendDocument(HttpServletRequest request, HttpServletResponse response) throws IOException {
		response.setStatus(HttpServletResponse.SC_OK);
		response.setContentType(getBrowserContentType());
		sendBody(response.getOutputStream(),request,response);
	}

	/**
	 * Abstract method that must be used if not overriding the sendDocument method. This is the method that should write to the dataOutput
	 * OutputStream.
	 * @param dataOutput Data stream to http client
	 * @param request Client request
	 * @param response Client response which already has headers set by sendDocument
	 * @throws java.io.IOException
	 * @see sendDocument
	 */
	abstract public void sendBody(OutputStream dataOutput, HttpServletRequest request, HttpServletResponse response) throws IOException;
	/*
	abstract public void sendDocument(OutputStream dataOutput, Map<String,String[]> params) throws IOException;
	*/

	/**
	 * Sets a flag to indicate that the meta data has been changed.
	 * @param dataDirty true if document meta data has changed
	 */
	public void setDataDirty(boolean dataDirty) {
		this.dataDirty = dataDirty;
	}

	/**
	 * Sets a flag to indicate that the common data has been changed.
	 * @param commonDirty true if document common data has changed
	 */
	public void setCommonDirty(boolean commonDirty) {
		this.commonDirty = commonDirty;
	}

	/**
	 * Set the revision history information. Internal use.
	 * @param revs
	 */
	public void setRevisions(JSONArray revs) {
		commonData.put("_revisions",revs);
	}

	/**
	 * Called from the DBState implementation to set the document sequence number.
	 * @param seq Database sequence number
	 */
	public void setSequence(long seq) {
		metaData.put(SEQ, seq);
		dataDirty = true;
	}

	/**
	 * Non-indented version of toString which returns the common and meta JSON data
	 * @return unformatted json string of document
	 */
	@Override
	public String toString() {
		String jsonString = commonData.toString();
		jsonString = jsonString.substring(0,jsonString.length()-1);

		String revJSON = metaData.toString();
		if (!"".equals(revJSON)) {
			revJSON = revJSON.substring(1);
			jsonString = jsonString + "," +revJSON;
		} else {
			jsonString+="}";
		}
		return jsonString;
	}

	/**
	 * Indented version of toString which returns the common and meta JSON data
	 * @param indent spaces of indent per level
	 * @return formatted string version of document
	 */
	public String toString(int indent) {
		String jsonString = commonData.toString(indent);
		jsonString = jsonString.substring(0,jsonString.length()-2);

		String revJSON = metaData.toString(indent);
		if (!"".equals(revJSON)) {
			revJSON = revJSON.substring(1);
			jsonString = jsonString + "," +revJSON;
		} else {
			jsonString+="}";
		}
		return jsonString;
	}

	/**
	 * If the document requires revision data, on loading and creating this method will be called.
	 * @param dataInput Source for revision data stream
	 * @throws memedb.document.DocumentCreationException
	 */
	abstract public void setRevisionData(InputStream dataInput) throws DocumentCreationException;

	/**
	 * Writes the JSON common data to the specified writer.
	 * @param writer The writer that recieves commond data
	 * @throws java.io.IOException
	 */
	public void writeCommonData(Writer writer) throws IOException {
		commonData.write(writer);
	}

	/**
	 * Write out the document to the specified writer.
	 * @param params Options. "pretty" => ["true"] will format with 2 space indent
	 */
	public void writeMetaData(Writer writer, Map<String, String[]> params) throws IOException {
		boolean pretty=false;
		if (params.containsKey("pretty")) {
			String[] values = params.get("pretty");
			for (String value:values) {
				if (value.equals("true")) {
					pretty=true;
				}
			}
		}
		if (pretty) {
			writer.write(toString(2));
		} else {
			writer.write(toString());
		}
	}

	/**
	 * Return true if there is data that does not go into the _common or .meta file. Used for example in Binary and Text Document types.
	 * @return true if revision data must be appended to document
	 */
	abstract public boolean writesRevisionData();

	/**
	 * Must return true if the document requires an additional file to store revision data in. Revision
	 * data is that which is not common or meta information, for example image data for image/png
	 * @param dataOutput Sink to write revision data to
	 * @throws java.io.IOException
	 */
	abstract public void writeRevisionData(OutputStream dataOutput) throws IOException;


	////////////////////////////////////////
	//         Protected methods          //
	////////////////////////////////////////

	protected void setRevision(String rev) {
		metaData.put(REV,rev);
	}

	protected void setRevisionDate(Date date) {
		metaData.put(REV_DATE,date.getTime());
	}

	protected void setRevisionDate(long timestamp) {
		metaData.put(REV_DATE,timestamp);
	}

	protected void setRevisionUser(String revUser) {
		metaData.put(REV_USER, revUser);
	}

}

