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

import java.io.Serializable;
import java.util.Comparator;
import java.util.Set;
import java.util.Arrays;

import org.json.JSONObject;
import org.json.JSONArray;

import memedb.utils.Logger;

/**
 * This is the comparator for sorting view keys. The sort order is
 * <ul>
 * <li> null
 * <li> false
 * <li> true
 * <li> numbers 1, 2, 4.2
 * <li> text, case sensitive "a", "A", "aa"
 * <li> arrays compared by each element until different
 * <li> objects, compared by sorted keys until different
 * </ul>
 * @author Russell Weir
 */

public final class Collate implements Comparator<Object>, Serializable {
	transient protected Logger log = Logger.get(Collate.class);
	/**
	* Performs the actual comparison of objects.
	*
	*/
	public int compare(Object k1, Object k2) {
		if(k1 == null) k1 = JSONObject.NULL;
		if(k2 == null) k2 = JSONObject.NULL;
		if(k1 == JSONObject.NULL || k2 == JSONObject.NULL) {
			if(k1 == JSONObject.NULL && k2 == JSONObject.NULL) return 0;
			if(k1 == JSONObject.NULL) return -1;
			return 1;
		}

		if(k1 instanceof Boolean) {
			if(!(k2 instanceof Boolean))
				return -1;
			Boolean b1 = (Boolean) k1;
			Boolean b2 = (Boolean) k2;
			if(b1 == true) {
				if(b2 == false)
					return 1;
				return 0;
			}
			if(b2 == true)
				return -1;
			return 0;
		}

		if(k1 instanceof Number) {
			if(!(k2 instanceof Number))
				return -1;
			double v1 = ((Number) k1).doubleValue();
			double v2 = ((Number) k2).doubleValue();
			if(v1 == v2) return 0;
			return (v1 < v2) ? -1 : 1;
		}

		if(k1 instanceof String) {
			if(!(k2 instanceof String))
				return -1;
			return ((String) k1).compareTo((String) k2);
		}

		if(k1.getClass().isArray() || (k1 instanceof JSONArray)) {
			int len1, len2;
			boolean k1j;
			boolean k2j;
			JSONArray kja1=null, kja2=null;
			Object[] a1=null, a2=null;
			if(k2 instanceof JSONArray)
			{
				k2j = true;
				kja2 = (JSONArray) k2;
				len2 = kja2.length();
			}
			else if(k2.getClass().isArray())  {
				k2j = false;
				a2 = (Object []) k2;
				len2 = a2.length;
			}
			else
				return -1;
			if(k1 instanceof JSONArray) {
				k1j = true;
				kja1 = (JSONArray) k1;
				len1 = kja1.length();
			}
			else {
				k1j = false;
				a1 = (Object []) k1;
				len1 = a1.length;
			}

			//Compare cmp = new Compare();

			for(int x = 0; x < len1; x++) {
				Object v1, v2;
				if(x >= len2)
					return -1;
				if(k1j)
					v1 = kja1.opt(x);
				else
					v1 = a1[x];
				if(k2j)
					v2 = kja2.opt(x);
				else
					v2 = a2[x];
				int r = compare(v1, v2); //cmp.compare
				if(r != 0)
					return r;
			}
			if(len1 == len2)
				return 0;
			return -1;
		}

		if(k1 instanceof JSONObject) {
			if(!(k2 instanceof JSONObject))
				return -1;
			JSONObject j1 = (JSONObject) k1;
			JSONObject j2 = (JSONObject) k2;
			Object[] s1 = j1.keySet().toArray();
			Arrays.sort(s1);
			int len1 = s1.length;
			int len2 = j2.keySet().toArray().length;
			for(int x = 0; x < len1; x++) {
				if(x >= len2)
					return -1;
				Object o1 = null;
				Object o2 = null;
				try {
					o1 = j1.get((String) s1[x]);
				} catch(Exception e) {
					o1 = null;
				}
				try {
					o2 = j2.get((String) s1[x]);
				} catch(Exception e) {
					o2 = null;
				}
				int r = compare(o1, o2); // cmp.compare
				if(r != 0)
					return r;
			}
			if(len1 == len2)
				return 0;
			return -1;
		}
		if(log == null)
			log = Logger.get(Collate.class);
		log.error("Did not compare {} to {}", k1.getClass().getName(), k2.getClass().getName());
		return 0;
	}
}