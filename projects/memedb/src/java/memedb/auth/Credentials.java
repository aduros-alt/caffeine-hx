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

import java.util.Date;

public abstract class Credentials {

	public abstract boolean canDropDatabase(String db);
	public abstract boolean canCreateDatabase(String db);
	public abstract boolean canReadDocuments(String db);
	public abstract boolean canCreateDocuments(String db);
	public abstract boolean canUpdateDocuments(String db);
	public abstract boolean canDeleteDocuments(String db);
	public abstract boolean canRunView(String db, String id);
	public abstract boolean canCreateView(String db, String id);
	public abstract boolean canRunAdhoc(String db);
	public abstract boolean canSeeDbStats(String db);
	public abstract boolean canSeeDbNames();

	// main class

	final private String username;
	final private String token;
	final private Boolean isSA;
	private long timeoutTimestamp; // default is 300 seconds (300,000 millisec)

	private long timeoutLength = 300000;

	public Credentials(String username, String token, int timeoutInSeconds) {
		this.username = username;
		this.token = token;
		this.isSA = false;
		this.timeoutLength=timeoutInSeconds*1000;
		resetTimeout();
	}

	public Credentials(String username, String token, boolean isSA, int timeoutInSeconds) {
		this.username = username;
		this.token = token;
		this.isSA = isSA;
		this.timeoutLength=timeoutInSeconds*1000;
		resetTimeout();
	}

	public boolean isSA() {
		return isSA;
	}

	public String getToken() {
		return token;
	}

	public String getUsername() {
		return username;
	}

	public boolean isExpired() {
		return ( new Date().getTime() > timeoutTimestamp );
	}

	public void resetTimeout() {
		this.timeoutTimestamp =  new Date().getTime()+ timeoutLength;
	}

	/**
	* Returns seconds remaining before the credentials expire
	* @return int value in seconds
	*/
	public int secondsRemaining() {
		return (int)((timeoutTimestamp - new Date().getTime())/1000);
	}
}
