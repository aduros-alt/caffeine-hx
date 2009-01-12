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

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Map;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpServletRequest;

@ContentTypes({
	"application/octet-stream",
	"image/png",
	"image/jpeg",
	"images/gif",
	"*"
})
public class BinaryDocument extends Document {
	protected byte[] contents = null;

	@Override
	public void setRevisionData(InputStream dataInput) {

		ByteArrayOutputStream baos = new ByteArrayOutputStream();
		MessageDigest md = null;
		try {
			md = MessageDigest.getInstance("MD5");
		} catch (NoSuchAlgorithmException e1) {
			log.error(e1, "Missing MD5 digester");
		}

		byte[] buffer = new byte[16*1024]; // 16k buffer... should be tunable
		int read = 0;
		try {
			while ((read=dataInput.read(buffer)) > -1) {
				baos.write(buffer, 0, read);
				if (md!=null) {
					md.update(buffer,0,read);
				}
			}
		} catch (IOException e) {
			e.printStackTrace();
		} finally {
			try {
				baos.close();
			} catch (IOException e) {
			}
		}
		contents = baos.toByteArray();
		metaData.put("size", contents.length);
		if (md!=null) {
			metaData.put("md5", bytesToHex(md.digest()));
		}
	}

	public static String bytesToHex(byte[] bytes) {
		StringBuilder sb = new StringBuilder();
		for (byte b:bytes) {
			String s = Integer.toHexString(b & 0xFF);
			if (s.length()<2) {
				sb.append("0");
			}
			sb.append(s);
		}
		return sb.toString();
	}

	@Override
	public void writeRevisionData(OutputStream dataOutput) throws IOException {
		ByteArrayInputStream is = new ByteArrayInputStream(contents);
		byte[] buffer = new byte[16*1024]; // 16k buffer... should be tunable
		int read = -1;
		while ((read=is.read(buffer)) > -1) {
			dataOutput.write(buffer, 0, read);
		}
		is.close();
		dataOutput.flush();
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
