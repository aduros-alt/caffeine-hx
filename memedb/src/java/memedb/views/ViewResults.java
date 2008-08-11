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

import java.io.File;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import memedb.MemeDB;
import memedb.document.Document;

import org.json.JSONObject;

/**
* ViewResults represent the current state of all mapped Documents. The
* interface allows for the ViewResults class to be a thread.
* @author Russell Weir
*/
public interface ViewResults {

	// The required constructor
	//public ViewResults(String db, String docName, String functionName, View view);

	/**
	* Adds a result from a document map run. JSON object will be<pre>
	* {
	*    "id": docId
	*    "key": anytype
	*    "value": anytype
	* }</pre>
	*/
	public void addResult(Document doc);

	/**
	* Return all the current map results, already sorted
	*/
	//public Deque all();
	public List<JSONObject> all();


	/**
	* Clears the result set
	**/
	public void clear();

	/**
	* Called when the view itself is removed
	*/
	public void destroyResults();

	/**
	* Return the sequence number that has not yet been mapped.
	*/
	public long getCurrentSequenceNumber();

	/**
	* Returns a full path to locate any existing instance of ViewResults
	*/
	public File getInstanceFile();

	/**
	* Returns the arbitrary object attached to the ViewResults instance
	* @see setManagerObject
	**/
	public Object getManagerObject();

	/**
	* Returns the View the results are based on
	**/
	public View getView();

	/**
	* Initializes the results passing the MemeDB instance
	*/
	public void init(MemeDB memeDB);

	/**
	* If ViewResult is not alive, start() will be called.
	*/
	public boolean isAlive();

	/**
	* Remove a Document id from the result set
	*/
	public void removeResult(String id, long seqNo);

	/**
	* Attaches an object to the ViewResults instance
	* @see getManagerObject
	**/
	public void setManagerObject(Object o);

	/**
	* Should validate that the source has not changed from the provided view
	* @throws ViewException if the object should just be recreated.
	**/
	public void setView(View view) throws ViewException;

	/**
	* Called after init in case the ViewResults is a thread
	*/
	public void start();

	/**
	* Shutdown sequnce
	*/
	public void shutdown();

	/**
	* Get a sublist of the results.
	*/
	public ArrayList<JSONObject> subList(Map<String,String> options);

}
