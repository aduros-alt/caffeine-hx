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
import java.util.Map;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpServletRequest;

@ContentTypes({
	"text/plain",
	"text/html",
	"text/xml",
	"text/css",
	"text/javascript",
	"text/x-javascript",
	"application/javascript",
	"application/x-javascript"
})
/**
* @author mbreese
*/
public class TextDocument extends Document {
	protected String content=null;

	@Override
	public void setRevisionData(InputStream dataInput) throws DocumentCreationException {
		BufferedReader reader = new BufferedReader(new InputStreamReader(dataInput));
		StringBuilder sb = new StringBuilder();

		char[] buffer = new char[4*1024];
		int read=-1;
		try {
			while ((read=reader.read(buffer,0,buffer.length))>-1) {
				sb.append(buffer,0,read);
			}
		} catch (IOException e) {
			throw new DocumentCreationException(e);
		}
		content = sb.toString();
	}

	@Override
	public void writeRevisionData(OutputStream dataOutput) throws IOException {
		BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(dataOutput));
		writer.write(content);
		writer.flush();
	}

	@Override
	public void sendBody(OutputStream dataOutput, HttpServletRequest request, HttpServletResponse response) throws IOException {
		writeRevisionData(dataOutput);
	}

	@Override
	public boolean writesRevisionData() {
		return true;
	}
}
