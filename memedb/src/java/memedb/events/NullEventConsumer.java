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

package memedb.events;

import memedb.MemeDB;

/**
* No external event consumer
* @author Russell Weir
*/
public class NullEventConsumer implements ExternalEventConsumer {

	public final void init(MemeDB memeDB) {}
	public final void onDatabaseCreated(String db, long seqNo) {}
	public final void onDatabaseDeleted(String db, long seqNo) {}
	public final void onDocumentUpdated(String db, String docId, String rev, long seqNo) {}
	public final void onDocumentDeleted(String db, String docId, long seqNo) {}
	public final void shutdown() {}
}