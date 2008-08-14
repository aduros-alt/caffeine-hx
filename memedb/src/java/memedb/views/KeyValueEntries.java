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
import java.util.ArrayList;
import java.util.ListIterator;
import java.util.Iterator;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.locks.ReentrantLock;

import org.json.JSONArray;
import org.json.JSONObject;

/**
 * Represents a keyed list of values that are the result of mapping documents.
 * Exposed methods all take a JSONObject { key: Object, value: Object } 
 * @author Russell Weir
**/
public class KeyValueEntries implements Serializable {
		private static final long serialVersionUID = -6690638542954909335L;
		private Object key = null;
		
		// ListSet[ JSON Data] results entries {key:, value: }
		private CopyOnWriteArrayList<Object> results ;

		// Reduce result Object
		private Object reduced = null;
		
		transient private ReentrantLock lock;
		transient private View view;
		
//		public KeyValueEntries() {
//			this.lock = new ReentrantLock(true);
//		}

		/**
		 * When using this constuctor, the KeyValueEntries object will
		 * have to be initialized with a call to init() 
		 * @param key
		 */
		public KeyValueEntries(Object key) {
			this.key = key;
			this.lock = new ReentrantLock(true);
			this.results = new CopyOnWriteArrayList<Object>();
			this.lock = new ReentrantLock(true);
		}
		
		public KeyValueEntries(Object key, View view) {
			this(key);			
			this.view = view;
		}
		
		/**
		 * Add a result from a view map()
		 * @param o JSONObject key,value pair
		 */
		public void add(JSONObject o) {
			Object value = o.opt("value");
			if(value == null || value == JSONObject.NULL)
				return;
			lock.lock();
			try {
				results.add(value);
				reduced = null;
			} finally {
				lock.unlock();
			}
		}
		
		/**
		 * Add an array of JSONObject { key:, value:}
		 * @param ar JSONArray of JSONObjects
		 */
		public void addAll(JSONArray ar) {
			lock.lock();
			try {
				int max = ar.length();
				for(int i=0; i < max; i++) {
					JSONObject o = ar.getJSONObject(i);
					Object value = o.opt("value");
					if(value == null || value == JSONObject.NULL)
						continue;
					results.add(value);
				}
				reduced = null;
			} finally {
				lock.unlock();
			}
		}
		
		/**
		 * Clears the list.
		 */
		public void clear() {
			lock.lock();
			try {
				results.clear();
				reduced = null;
			} finally {
				lock.unlock();
			}
		}
		
		/**
		 * Returns an ArrayList copy of all the current key,value pairs.
		 * @return Modifiable snapshot of {key:,value:} JSONObjects
		 */
		public ArrayList<JSONObject> getAll() {
			ArrayList<JSONObject> ar = new ArrayList<JSONObject>();
			for(Object o: results) {
				JSONObject j = new JSONObject();
				j.put("key", key);
				j.put("value", o);
				ar.add(j);
			}
			return ar;
		}
		
		public void init(View view) {
			if(this.key == null)
				throw new RuntimeException("Key field is null");
			if(this.view != null)
				throw new RuntimeException("Must not init a constructed KeyValueEntries class");
			this.lock = new ReentrantLock(true);
			this.view = view;
			this.reduced = null;
		}
		
		/**
		 * Returns the number of entries in the list
		 * @return size of results
		 */
		public int length() {
			return results.size();
		}
		
		/**
		 * Returns a snapshot iterator over the value list. The list
		 * may not be modified in any way while iterating.
		 * @return
		 */
		public Iterable<Object> objectIterator() {
			final ListIterator<Object> i = results.listIterator();
			return new Iterable<Object>() {
				public Iterator<Object> iterator() {
					return i;
				}
			};
		}
		
		/**
		 * Returns the current reduced value of the value list.
		 * @return Object reduced value
		 */
		public Object reduced() {
			if(!view.hasReduce())
				return null;
			Object r = reduced;
			if(r != null)
				return r;
			lock.lock();
			try {				
				JSONArray ja = new JSONArray();
				for(Object o: results) {
					JSONObject j = new JSONObject();
					j.put("key", key);
					j.put("value", o);
					ja.put(j);
				}
				reduced = view.reduce(ja);
				r = reduced;
			} finally {
				lock.unlock();
			}
			return r;
		}
		
		/**
		 * Remove the specified result from the value list
		 * @param o key,value JSONObject
		 */
		public void remove(JSONObject j) {
			Object value = j.opt("value");
			Collate c = new Collate();
			if(value == null || value == JSONObject.NULL)
				return;
			lock.lock();
			try {
				for(Object o: results) {
					if(c.compare(o, value) == 0) {
						results.remove(o);
						break;
					}
				}
				reduced = null;
			} finally {
				lock.unlock();
			}
		}
	}
