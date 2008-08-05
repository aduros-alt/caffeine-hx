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

import java.util.HashMap;
import java.util.Map;

import org.json.JSONObject;

import memedb.document.JSONDocument;

/*
{
	"language": "java",
	"views": {
		"default": "fully.qualified class name",
		"by_age": "fully.qualified.class.name"
	}
}
*/
public class JavaViewFactory implements ViewFactory {

	public Map<String, View> buildViews(JSONDocument doc) throws ViewException {
		Map<String,View> m = new HashMap<String,View>();
		if (doc.getMetaData().has("views")) {
			JSONObject views = doc.getMetaData().getJSONObject("views");
			for (String k:views.keySet()) {
				m.put(k, getInstance(views.getString(k)));
			}
		}
		return m;
	}

	protected View getInstance(String className) throws ViewException {
		try {
			Class clazz = Thread.currentThread().getContextClassLoader().loadClass(className);
			return (View) clazz.newInstance();
		} catch (ClassNotFoundException e) {
			throw new ViewException(e);
		} catch (InstantiationException e) {
			throw new ViewException(e);
		} catch (IllegalAccessException e) {
			throw new ViewException(e);
		}
	}

}
