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

package memedb;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.StringWriter;
import java.util.Properties;

import memedb.utils.Logger;

public class MemeDBProperties {
	private static final String CONFIG_FILE = "memedb.properties";
	private static final String DEFAULT_CONFIG_FILE = "default.properties";
	private static final Logger log = Logger.get(MemeDBProperties.class);

	private static void loadPropertyFromStream(Properties props, InputStream in) throws IOException {
		try {
			if (in!=null) {
				props.load(in);
			}
		} finally {
			if (in!=null) {
				in.close();
			}
		}
	}

	public static Properties getProperties() {
		Properties props = new Properties();
		try {
			// load the defaults from the classpath (package level file)
			loadPropertyFromStream(props,MemeDBProperties.class.getResourceAsStream(DEFAULT_CONFIG_FILE));

			// load the config from the classpath
			loadPropertyFromStream(props,Thread.currentThread().getContextClassLoader().getResourceAsStream(CONFIG_FILE));

			// load additional config from the current working directory
			File f = new File(CONFIG_FILE);
			if (f.exists()) {
				loadPropertyFromStream(props, new FileInputStream(f));
			}

			StringWriter sw = new StringWriter();
			props.store(sw, "Running configuration");
			sw.close();
			log.info(sw.toString());
		} catch (IOException e) {
			log.error("Error loading properties file",e);
			throw new RuntimeException(e);
		}
		return props;
	}
}
