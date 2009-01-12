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

import java.io.File;
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.lang.ProcessBuilder;
import java.lang.Process;

import memedb.MemeDB;
import memedb.utils.Logger;

import org.json.JSONWriter;

/**
* StdoutEventConsumers are the processes that are sent events on stdin
* from the database. The process is started when MemeDB starts up, and is alive
* until MemeDB shuts down. If the process dies, it will be restarted
* @author Russell Weir
*/
public class StdoutEventConsumer implements ExternalEventConsumer {
	protected final static String HANDLER = "eventhandler.stdout.handler";

	protected MemeDB memeDB;
	protected ProcessBuilder pb;
	protected Process proc;
	protected String neko;
	protected String processFile;
	protected BufferedWriter stdout; // from our point of view
// 	protected BufferedReader stdin;
	protected int tries = 0;
	final private Logger log = Logger.get(StdoutEventConsumer.class);

	public void init(MemeDB memeDB) {
		this.memeDB = memeDB;
		processFile = memeDB.getProperty(HANDLER);
		try {
			createProcess();
		} catch(Exception e) {
			throw new RuntimeException(e);
		}
	}

	public void onDatabaseCreated(String db, long seqNo) {
		if(tries++ > 5)
			throw new RuntimeException("Error writing to process "+processFile);
		try {
			new JSONWriter(stdout)
			.object()
				.key("type")
				.value("create")
				.key("transaction")
				.value(null)
				.key("_seq")
				.value(seqNo)
				.key("db")
				.value(db)
			.endObject();
			stdout.write("\n");
			stdout.flush();
		} catch(IOException e) {
			try {
				createProcess();
			} catch ( Exception e2 ) {
				throw new RuntimeException("Error restarting process "+processFile);
			}
			onDatabaseCreated(db, seqNo);
		} finally {
			tries--;
		}
	}

	public void onDatabaseDeleted(String db, long seqNo) {
		if(tries++ > 5)
			throw new RuntimeException("Error writing to process "+processFile);
		try {
			new JSONWriter(stdout)
			.object()
				.key("type")
				.value("drop")
				.key("transaction")
				.value(null)
				.key("_seq")
				.value(seqNo)
				.key("db")
				.value(db)
			.endObject();
			stdout.write("\n");
			stdout.flush();
		} catch(IOException e) {
			try {
				createProcess();
			} catch ( Exception e2 ) {
				throw new RuntimeException("Error restarting process "+processFile);
			}
			onDatabaseDeleted(db, seqNo);
		} finally {
			tries--;
		}
	}

	public void onDocumentUpdated(String db, String docId, String rev, long seqNo) {
		if(tries++ > 5)
			throw new RuntimeException("Error writing to process "+processFile);
		try {
			new JSONWriter(stdout)
			.object()
				.key("type")
				.value("update")
				.key("transaction")
				.value(null)
				.key("_seq")
				.value(seqNo)
				.key("db")
				.value(db)
				.key("_id")
				.value(docId)
				.key("_rev")
				.value(rev)
			.endObject();
			stdout.write("\n");
			stdout.flush();
		} catch(IOException e) {
			try {
				createProcess();
			} catch ( Exception e2 ) {
				throw new RuntimeException("Error restarting process "+processFile);
			}
			onDocumentUpdated(db,docId,rev,seqNo);
		} finally {
			tries--;
		}
	}

	public void onDocumentDeleted(String db, String docId, long seqNo) {
		if(tries++ > 5)
			throw new RuntimeException("Error writing to process "+processFile);
		try {
			new JSONWriter(stdout)
			.object()
				.key("type")
				.value("delete")
				.key("transaction")
				.value(null)
				.key("_seq")
				.value(seqNo)
				.key("db")
				.value(db)
				.key("_id")
				.value(docId)
			.endObject();
			stdout.write("\n");
			stdout.flush();
		} catch(IOException e) {
			try {
				createProcess();
			} catch ( Exception e2 ) {
				throw new RuntimeException("Error restarting process "+processFile);
			}
			onDocumentDeleted(db,docId,seqNo);
		} finally {
			tries--;
		}
	}

	private void createProcess() throws IOException {
		if(proc != null) {
			proc.destroy();
			proc = null;
		}
		try {
			pb = new ProcessBuilder(processFile);
// 			pb.directory(baseDir);
			proc = pb.start();
			//stdin = new BufferedReader(new InputStreamReader(proc.getInputStream()));
			stdout = new BufferedWriter(new OutputStreamWriter(proc.getOutputStream()));
		} catch( Exception e ) {
			throw new IOException(e.getMessage());
		}
	}

	public void shutdown() {
		try {
			new JSONWriter(stdout)
			.object()
				.key("type")
				.value("shutdown")
			.endObject();
			stdout.write("\n");
			stdout.flush();
		} catch(IOException e) {}
		if(proc != null) {
			try {
				Thread.sleep(1500);
			} catch ( Exception e ) {}
			proc.destroy();
		}
	}

}
