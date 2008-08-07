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

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.util.Map;
import java.util.Set;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpServletRequest;

import org.json.JSONObject;

/**
* JSON Object Document
* @author mbreese
* @author Russell Weir
*/
@ContentTypes({"application/json"})
public class JSONDocument extends Document {
	public static final String TEXT_PLAIN_MIMETYPE = "text/plain;charset=utf-8";
	public JSONDocument() {}

	public JSONDocument(JSONObject source) throws DocumentCreationException {
		setRevisionData(source);
	}

	@Override
	public void setRevisionData(InputStream dataInput) throws DocumentCreationException {
		try {
			JSONObject newMetaData = JSONObject.read(dataInput);
			setRevisionData(newMetaData);
		} catch (IOException e) {
			throw new DocumentCreationException(e);
		}
	}

	/**
	* setRevisionData for JSONDocument is only called when
	* streaming in new revision information, so the reserved fields
	* (see README.common_data) are dropped from the
	* incoming object
	**/
	public void setRevisionData(JSONObject source) throws DocumentCreationException {
		for (String key:source.keySet()) {
			if (key.startsWith("_")) {
				if(
					!key.equals(DB) &&
					!key.equals(CONTENT_TYPE) &&
					!key.equals(CREATED_DATE) &&
					!key.equals(CURRENT_REVISION) &&
					!key.equals(ID) &&
					!key.equals(REV) &&
					!key.equals(REV_DATE) &&
					!key.equals(REV_USER) &&
					!key.equals(SEQ)
				) {
					commonData.put(key, source.get(key));
				}
			}
			else {
				metaData.put(key, source.get(key));
			}
		}
	}

	@Override
	public void writeRevisionData(OutputStream dataOutput) throws IOException {
		// does nothing since all JSON data is stored in the MetaData stream
	}

	@Override
	public void sendBody(OutputStream dataOutput, HttpServletRequest request, HttpServletResponse response) throws IOException {
		Map<String,String[]> params = request.getParameterMap();
		boolean pretty=false;
		if (params.containsKey("pretty")) {
			String[] values = params.get("pretty");
			for (String value:values) {
				if (value.equals("true")) {
					pretty=true;
				}
			}
		}
		for (String key: params.keySet()) {
			log.debug("{} => {}",key,params.get(key));
			int i=0;
			for (String value:params.get(key)) {
				log.debug("[{}] => ", i++,value);
			}
		}
		log.info("pretty? = {}", pretty);
		Writer writer = new OutputStreamWriter(dataOutput);
		if (pretty) {
			writer.write(toString(2));
		} else {
			writer.write(toString());
		}
		writer.close();
	}

	public void put(String key,Object value) {
		if (key.startsWith("_")) {
			commonDirty=true;
			commonData.put(key, value);
		} else {
			dataDirty=true;
			metaData.put(key, value);
		}
	}

	public Object get(String key) {
		if (key.startsWith("_")) {
			return commonData.get(key);
		}
		return metaData.get(key);
	}

	public Set<String> keys() {
		return metaData.keySet();
	}

	/**
	* @return boolean false JSONDocument write everything to the MetaData
	*/
	@Override
	public boolean writesRevisionData() {
		return false;
	}

	@Override
	public String getBrowserContentType() {
		return TEXT_PLAIN_MIMETYPE;
	}
}
