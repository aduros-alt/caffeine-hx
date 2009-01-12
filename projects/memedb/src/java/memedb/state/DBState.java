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

package memedb.state;

import java.util.List;
import java.io.IOException;

import memedb.MemeDB;
import memedb.document.Document;

/**
 * The DBState keeps track of documents by their sequence number,
 * providing iterators for all documents or documents starting at
 * a specified starting sequence number.
 * @author Russell Weir
 **/
abstract public class DBState {
	abstract public void init(MemeDB memeDB);
	abstract public void shutdown();

	/**
	* Records database add event
	* @return sequence number
	*/
	abstract public long addDatabase(String name);
	/**
	* Records database delete event
	* @return sequence number
	*/
	abstract public long deleteDatabase(String name);

	/**
	* Returns the current (last) sequence number
	*/
	abstract public long getCurrentSequenceNumber();

	/**
	* Must be called from the backend when a document
	* is added or modified. This method will update the _seq on the
	* provided document.
	*/
	abstract public void updateDocument(Document doc);

	/**
	* Once the backend has completed the document save process,
	* the state is called and must start any view recalculation
	* for the newly saved document.
	*/
	abstract public void finalizeDocument(Document doc);

	/**
	* Must be called from the backend when a document
	* is deleted.
	*/
	abstract public void deleteDocument(Document doc);
	abstract public void deleteDocument(String db, String id);

	/**
	* Returns a list of events that have happened beginning
	* with the specified sequence number.
	* @param startSeq starting sequence number
	* @param maxCount max records to return. <0 means all
	*/
	abstract public Iterable<StateEvent> eventsFromSequence(long seq, long maxCount);

// 	abstract public Iterable<Document> documentsBySequence(String db, long startSeq);
}