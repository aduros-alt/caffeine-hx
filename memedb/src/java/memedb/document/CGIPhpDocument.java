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
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Map;

import javax.servlet.http.HttpServletRequest;

@ContentTypes({
	"application/php"
})
/**
* CGIPhpDocument generates results by running a PHP process
* @author Russell Weir
*/
public class CGIPhpDocument extends CGIScriptDocument {
	protected ProcessBuilder pb;

	@Override
	public void sendDocument(OutputStream dataOutput,HttpServletRequest request) throws IOException {
		try {
			pb = new ProcessBuilder(new String[]{"/bin/sh", "-c",
				"/bin/echo \""+content.replace("\"","\\\"")+"\" | /usr/bin/php"});
			log.warn("{}", pb.command());
		} catch( Exception e ) {
			log.error("{}", e.getMessage());
		}
		try {
//	 		pb.directory(new File("myDir"));
// 			pb.directory(null);
			createEnvironment(pb, request);
		} catch( Exception e ) {
			log.error("{}", e.getMessage());
		}
		try {
			runProcess(pb, dataOutput);
		} catch( Exception e ) {
			log.error("{}", e.getMessage());
		}
	}

	@Override
	protected void runProcess(ProcessBuilder pb, OutputStream dataOutput) throws IOException {
		pb.redirectErrorStream(true);
// 		try
		Process proc = pb.start();

		OutputStreamWriter stdout = new OutputStreamWriter(proc.getOutputStream());


		BufferedReader reader = new BufferedReader(new InputStreamReader(proc.getInputStream()));

		BufferedWriter writer = new BufferedWriter(new OutputStreamWriter(dataOutput));

		stdout.write(content);

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

	@Override
	public String getBrowserContentType() {
		return "text/html";
	}

}