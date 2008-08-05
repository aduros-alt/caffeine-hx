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


import java.io.File;
import java.io.IOException;
import java.io.OutputStream;
import javax.servlet.http.HttpServletRequest;

import memedb.MemeDB;
import memedb.backend.Backend;

@ContentTypes({
	"application/neko"
})
/**
* CGI document that is displayed using Neko VM (nekovm.org, haxe.org)
* @author Russell Weir
*/
public class CGINekoDocument extends CGIScriptDocument {
	protected final static String NEKO_BIN = "handler.bin.neko";
	protected final static String NEKO_BASEDIR = "handler.basedir.neko";

	protected ProcessBuilder pb;
	protected String neko;
// 	protected File baseDir;

	@Override
	public void sendDocument(OutputStream dataOutput,HttpServletRequest request) throws IOException {
		MemeDB memeDb = backend.getMeme();
		String sh = memeDb.getProperty("handler.sh.bin");
		String sw = memeDb.getProperty("handler.sh.switch");
		neko = memeDb.getProperty(NEKO_BIN);
// 		baseDir = backend.getMeme().getProperty(NEKO_BASEDIR);
		try {
			pb = new ProcessBuilder(new String[]{sh, sw,
				neko + " " + backend.getRevisionFilePath(this)});
			log.warn("{}", pb.command());
// 			pb.directory(baseDir);
			createEnvironment(pb, request);
			runProcess(pb, dataOutput);
		} catch( Exception e ) {
			log.error("{}", e.getMessage());
			throw new IOException(e.getMessage());
		}
	}

	@Override
	public String getBrowserContentType() {
		return "text/html";
	}

	@Override
	public final boolean requiresRevisionExtension() {
		return true;
	}

	@Override
	public final String getRevisionExtension() {
		return "n";
	}
}
