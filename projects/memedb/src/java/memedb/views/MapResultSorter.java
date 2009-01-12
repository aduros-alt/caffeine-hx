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

import java.lang.Long;
import java.util.Collections;
import java.util.Comparator;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.NavigableSet;
import java.util.TreeSet;

import org.json.JSONArray;
import org.json.JSONObject;
import org.json.JSONException;

import memedb.utils.Logger;

/**
 * This class sorts JSON map results from View.map(). The
 * objects being compared must have a "key" and a "value"
 * field.<pre>
 * {
 *    "key": anytype
 *    "value": anytype
 * }
 *</pre>
 * Refer to Collate for actual ordering
 * @see Collate
 * @author Russell Weir
 */
public final class MapResultSorter implements Comparator<JSONObject> {
	protected Logger log = Logger.get(MapResultSorter.class);
	protected Collate collator = new Collate();

	public MapResultSorter() {
	}

	/**
	* Compare two view entries, which must be JSON objects with the
	* 'key' field set.
	*/
	public int compare(JSONObject j1, JSONObject j2) {
		Object k1;
		Object k2;
		try {
			if(j1 == null)
				k1 = JSONObject.NULL;
			else
				k1 = j1.get("key");
		} catch(JSONException e) {
			k1 = JSONObject.NULL;
		}
		try {
			if(j2 == null)
				k2 = JSONObject.NULL;
			else
				k2 = j2.get("key");
		} catch(JSONException e) {
			k2 = JSONObject.NULL;
		}
		return collator.compare(k1, k2);
	}

	static public List sort(List<JSONObject> v, boolean reverse) {
		Collections.sort(v, new MapResultSorter());
		if(reverse)
			Collections.reverse(v);
// 		return new JSONArray(v);
		return v;
	}

	/**
	* In order of how they are applied
	* <ul>
	* <li>key - single key filter. If specified, no startkey or endkey matters
	* <li>startkey - starting key
	* <li>startkey_inclusive - starting key included in results (default true)
	* <li>endkey - ending key
	* <li>endkey_inclusive - ending key included in result (default true)
	* <li>descending - descending results (default false)
	* <li>skip - number of results to ignore
	* <li>count - maximum number of rows to return
	* <li>
	*/
	static public NavigableSet<JSONObject> filter(NavigableSet<JSONObject> v, Map<String,String> options) {


		JSONObject key = keyOrNull("key", options);
		JSONObject startkey = keyOrNull("startkey", options);
		JSONObject endkey = keyOrNull("endkey", options);
		boolean startInclusive = "false".equals(options.get("startkey_inclusive")) ? false : true;
		boolean endInclusive = "false".equals(options.get("endkey_inclusive")) ? false : true;
		boolean descending = "true".equals(options.get("descending"));

		NavigableSet<JSONObject> rv = v;
		if(key != null) {
			rv = v.subSet(key, true, key, true);
		}
		else {
			if(startkey != null) {
				if(endkey != null) {
					rv = v.subSet(startkey, startInclusive, endkey, endInclusive);
				} else {
					rv = v.tailSet(startkey, startInclusive);
				}
			}
			else if(endkey != null) {
				rv = v.headSet(endkey, endInclusive);
			}
		}

		if(descending)
			rv = rv.descendingSet();

		Long skip = null;
		try {
			skip = new Long(options.get("skip"));
		} catch ( Exception e ) {}
		if(skip != null) {
			long start = skip.longValue();
			TreeSet<JSONObject> t = new TreeSet<JSONObject>(new MapResultSorter());
			Iterator<JSONObject> it = rv.iterator();
			while(start-- > 0 && it.hasNext()) {
			}
			while(it.hasNext())
				t.add(it.next());
			rv = t;
		}

		Long count = null;
		try {
			count = new Long(options.get("count"));
		} catch ( Exception e ) {}

		if(count != null) {
			long max = count.longValue();
			long x = 0;
			TreeSet<JSONObject> t = new TreeSet<JSONObject>(new MapResultSorter());
			Iterator<JSONObject> it = null;
			if(count >= 0)
				it = rv.iterator();
			else
				it = rv.descendingIterator();
			while(x++ < max && it.hasNext()) {
				t.add(it.next());
			}
			rv = t;
		}

		return rv;
	}



	static private JSONObject keyOrNull(String opt, Map<String,String> options) {
		if(!options.containsKey(opt))
			return null;
		try {
			String val = options.get(opt);
			return makeKey(val);
		} catch (ClassCastException e) {
		}
		return null;
	}

	/**
	* Makes a JSONObject key structure from the String provided. The String
	* must be valid JSON, that is strings wrapped with quotations, arrays
	* in brackets, ie. ["one", 2, [3, "four"]]
	*/
	static public JSONObject makeKey(String value) {
		return new JSONObject("{ key: " +value+ "}");
	}


}