/*
 * Copyright (c) 2008, The Caffeine-hx project contributors
 * Original author : Russell Weir
 * Contributors:
 * All rights reserved.
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 *   - Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   - Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE CAFFEINE-HX PROJECT CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE CAFFEINE-HX PROJECT CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

package servers.http.hive;

enum ClientState {
	/** during connection before the server has received a complete header */
	STATE_WAITING;
	/** While waiting for complete application/x-www-form-urlencoded content */
	STATE_DATA;
	/** Input data complete. Process on next interval */
	STATE_READY;
	/** Sending a file **/
	STATE_FILE;
	/** during response processing */
	STATE_PROCESSING;
	/** After initial response completed */
	STATE_KEEPALIVE;
	/** No keepalive, we're closing */
	STATE_CLOSING;
	/** Done **/
	STATE_CLOSED;
}

enum HttpMethod {
	METHOD_UNKNOWN;
	METHOD_GET;
	METHOD_POST;
	METHOD_HEAD;
}

// application/x-www-form-urlencoded (FORM)
//
enum PostType {
	POST_NONE;
	POST_FORM;
	POST_MULTIPART;
}


typedef VarList = {
	key: String,
	value: String
}

enum ResponseType {
	TYPE_UNKNOWN;
	TYPE_FILE;
	TYPE_CGI;
}

/**
  RangeType description
**/
enum RangeType {
	RANGE;
	HEAD;
	OFFSET_END;
}

enum PluginState {
	ERROR;
	SKIP;
	COMPLETE;
	PROCESSING;
}

typedef ReqHandler = {
	hnd: Class<Dynamic>,
	pattern: String,
	options: String,
	ereg : EReg
};