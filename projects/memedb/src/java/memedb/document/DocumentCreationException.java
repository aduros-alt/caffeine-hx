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
package memedb.document;

public class DocumentCreationException extends Exception {

	/**
	 *
	 */
	private static final long serialVersionUID = 1833989511252667605L;
	private String reason = "unknown";

	public DocumentCreationException() {
	}

	public DocumentCreationException(String message) {
		super(message);
		this.reason = message;
	}

	public DocumentCreationException(String message, String reason) {
		super(message);
		this.reason = reason;
	}

	public DocumentCreationException(Throwable cause) {
		super(cause);
		this.reason = cause.getMessage();
	}

	public DocumentCreationException(String message, Throwable cause) {
		super(message, cause);
	}

	public String getReason() {
		return reason;
	}

}
