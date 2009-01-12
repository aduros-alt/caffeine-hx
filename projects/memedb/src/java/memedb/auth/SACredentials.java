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

package memedb.auth;

public class SACredentials extends Credentials {
	public SACredentials(String username, String token, int timeout) {
		super(username,token,true,timeout);
	}

	@Override
	public boolean canDropDatabase(String db) {
		return true;
	}
	
	@Override
	public boolean canCreateDatabase(String db) {
		return true;
	}
	
	@Override
	public boolean canReadDocuments(String db) {
		return true;
	}
	
	@Override
	public boolean canCreateDocuments(String db) {
		return true;
	}
	
	@Override
	public boolean canDeleteDocuments(String db) {
		return true;
	}
	
	@Override
	public boolean canUpdateDocuments(String db) {
		return true;
	}
	
	@Override
	public boolean canCreateView(String db, String id) {
		return true;
	}
	
	@Override
	public boolean canRunView(String db, String id) {
		return true;
	}
	
	@Override
	public boolean canRunAdhoc(String db) {
		return true;
	}
	
	@Override
	public boolean canSeeDbStats(String db) {
		return true;
	}
	
	@Override
	public boolean canSeeDbNames() {
		return true;
	}
}
