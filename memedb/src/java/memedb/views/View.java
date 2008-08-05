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

import org.json.JSONObject;
import org.json.JSONArray;

import memedb.backend.Backend;
import memedb.document.Document;

public interface View extends Serializable {
	/**
	* Perform the 'map' portion of the view
	*/
	public void map(MapResultConsumer listener, Document doc);

	/**
	* Returns true if the View has a 'reduce' member function
	*/
	public boolean hasReduce();

	public String getMapSrc();
	public String getReduceSrc();

	/**
	* Returns true if the View is not updated until it is run
	*/
	public boolean isLazy();

	/**
	* Perform the 'reduce' portion of the view, working on
	* a supplied JSONArray of key, value pairs built from
	* the filter method<pre>
	* {
	*   key: obj
	*   value: obj
	* }
	*</pre>
	*/
	public Object reduce(JSONArray results);

	/**
	* Sets the backend to the system default
	*/
	public void setBackend(Backend backend);


}
