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

package memedb.utils;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.net.URLEncoder;
import java.net.URLDecoder;
import java.io.UnsupportedEncodingException;

public class FileUtils {
	public static void writeToFile(File file, String str) throws IOException {
		writeToFile(file,str,false);
	}

	public static void writeToFile(File file, String str, boolean append) throws IOException {
		BufferedWriter writer = null;
		try {
			writer = new BufferedWriter(new FileWriter(file,append));
			writer.write(str);
		} finally {
			if (writer!=null) {
				try {
					writer.close();
				} catch (Exception e) {
				}
			}
		}
	}

	public static String readFileAsString(File file) throws IOException {
		final StringBuilder buffer = new StringBuilder("");
		readFileByLine(file, new LineCallback() {
			public void process(String line) {
				buffer.append(line);
				buffer.append("\n");
			}});
		return buffer.toString();
	}

	public static void readFileByLine(File file, LineCallback callback) throws IOException {
		String line = null;
		BufferedReader reader=null;
		try {
			reader = new BufferedReader(new FileReader(file));
			while ((line=reader.readLine())!=null) {
				callback.process(line);
			}
		} finally {
			if (reader!=null) {
				try {
					reader.close();
				} catch (IOException e) {
				}
			}
		}
	}

	public static boolean isFileGZIP(File file) {
		boolean gzip = false;
		FileInputStream fis =null;
		try {
			byte[] gzipbuf = new byte[2];
			fis = new FileInputStream(file);
			fis.read(gzipbuf);
			if (gzipbuf[0]==0x1f && gzipbuf[1]==0xffffff8b) { // gzip file header (magic is 0x8b1f)
				gzip=true;
			}
		} catch (Exception e) {
			e.printStackTrace();
		} finally {
			if (fis!=null) {
				try { fis.close(); } catch (Exception e) {}
			}
		}
		return gzip;
	}

	/**
	* Takes a database name or Document id and encodes it to a safe
	* version that can be used to create directories. This avoids
	* the problem of ids with embedded ../../
	* @author rweir
	*/
	public static String fsEncode(String name)
	{
		try {
			String rv = URLEncoder.encode(name, "UTF-8");
			rv = rv.replace("*", "%2A");
			rv = rv.replace(".", "%2E");
			rv = rv.replace("?", "%3F");
			return rv;
		} catch(UnsupportedEncodingException e) {
			throw new RuntimeException("UTF Support not present");
		}
	}

	public static String fsDecode(String name)
	{
		try {
			return URLDecoder.decode(name, "UTF-8");
		} catch(UnsupportedEncodingException e) {
			throw new RuntimeException("UTF Support not present");
		}
	}

	/**
	 * Delete a filesystem directory and all it's subdirectories
	 * @param dir The root path to remove
	 */
	public static void deleteRecursive(File dir) {
		if (dir.isDirectory()) {
			for (File child : dir.listFiles()) {
				if (child.isDirectory()) {
					deleteRecursive(child);
				}
				child.delete();
			}
		}
		if (dir.exists()) {
			dir.delete();
		}
	}
}
