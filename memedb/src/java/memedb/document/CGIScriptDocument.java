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

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.lang.ProcessBuilder;
import java.lang.Process;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;

/**
* Base class for documents that are displayed using processes
* @author Russell Weir
*/
public class CGIScriptDocument extends TextDocument {
	protected Process proc;

	protected void createEnvironment(ProcessBuilder pb, HttpServletRequest request) throws IOException {
		Map<String,String[]> params = request.getParameterMap();

		Map<String, String> env = pb.environment();
		env.put("SERVER_SOFTWARE", "MemeDB/0.2");
		env.put("SERVER_NAME", "127.0.0.1");
		env.put("GATEWAY_INTERFACE", "CGI/1.1");

// 		#  SERVER_PROTOCOL
// 		The name and revision of the information protcol this request came in with. Format: protocol/revision
		env.put("SERVER_PROTOCOL", request.getProtocol());

// 		# SERVER_PORT
// 		The port number to which the request was sent.
		env.put("SERVER_PORT", new Long(request.getLocalPort()).toString());

// 		# REQUEST_METHOD
// 		The method with which the request was made. For HTTP, this is "GET", "HEAD", "POST", etc.
		env.put("REQUEST_METHOD", request.getMethod());

// 		# PATH_INFO
// 		The extra path information, as given by the client. In other words, scripts can be accessed by their virtual pathname, followed by extra information at the end of this path. The extra information is sent as PATH_INFO. This information should be decoded by the server if it comes from a URL before it is passed to the CGI script.
		env.put("PATH_INFO", request.getPathInfo());

// 		# PATH_TRANSLATED
// 		The server provides a translated version of PATH_INFO, which takes the path and does any virtual-to-physical mapping to it.
		if(request.getPathTranslated() != null)
			env.put("PATH_TRANSLATED", request.getPathTranslated());


// 		# SCRIPT_NAME
// 		A virtual path to the script being executed, used for self-referencing URLs.
// 		env.put("SCRIPT_NAME", request.getServletPath());
		env.put("SCRIPT_NAME", getDatabase() + "/" + getId());

// 		QUERY_STRING
// 		The information which follows the ? in the URL which referenced this script. This is the query information. It should not be decoded in any fashion. This variable should always be set when there is query information, regardless of command line decoding.
		if(request.getQueryString() != null)
			env.put("QUERY_STRING", request.getQueryString());
		else
			env.put("QUERY_STRING", "");


// 		#  REMOTE_HOST
// 		The hostname making the request. If the server does not have this information, it should set REMOTE_ADDR and leave this unset.
		env.put("REMOTE_HOST", request.getRemoteHost());


// 		# REMOTE_ADDR
// 		The IP address of the remote host making the request.
		env.put("REMOTE_ADDR", request.getRemoteAddr());

// 		# AUTH_TYPE
// 		If the server supports user authentication, and the script is protects, this is the protocol-specific authentication method used to validate the user.
		if(request.getAuthType() != null) {
			env.put("AUTH_TYPE", request.getAuthType());

// 		# REMOTE_USER
// 		If the server supports user authentication, and the script is protected, this is the username they have authenticated as.
			env.put("REMOTE_USER", request.getRemoteUser());
		}


// 		# REMOTE_IDENT
// 		If the HTTP server supports RFC 931 identification, then this variable will be set to the remote user name retrieved from the server. Usage of this variable should be limited to logging only.
// 		env.put("", request.());

// 		# CONTENT_TYPE
// 		For queries which have attached information, such as HTTP POST and PUT, this is the content type of the data.
		if(request.getContentType() != null)
			env.put("CONTENT_TYPE", request.getContentType());
		else
			env.put("CONTENT_TYPE", "text/plain");


// 		# CONTENT_LENGTH
// 		The length of the said content as given by the client.
		if(request.getContentLength() >= 0)
			env.put("CONTENT_LENGTH", new Long(request.getContentLength()).toString());



	}

	protected void runProcess(ProcessBuilder pb, OutputStream dataOutput) throws IOException {
		pb.redirectErrorStream(true);
// 		try
		Process proc = pb.start();

		BufferedReader reader = new BufferedReader(new InputStreamReader(proc.getInputStream()));

		BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(dataOutput));
// 		OutputStreamWriter writer = new OutputStreamWriter(dataOutput);
		int c;
		while((c = reader.read()) != -1) {
			writer.write(c);
		}
		writer.flush();

		try {
			proc.waitFor();
		} catch (InterruptedException e) {
		}

/*
		InputStream is = p.getInputStream();
		BufferedReader br = new BufferedReader(new InputStreamReader(is));
		String line;
		while ((line = br.readLine()) != null) {
			System.out.println(line);
		}
*/

	}
}