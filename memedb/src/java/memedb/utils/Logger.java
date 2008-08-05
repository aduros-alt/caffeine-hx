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

import java.util.HashMap;
import java.util.Map;
import java.util.logging.Level;

public class Logger {
	final protected static Map<String,Logger> cache = new HashMap<String,Logger>();

	private static Level defaultLevel;

	public static void setDefaultLevel(String lvl) {
		String level = lvl;
		System.out.println("****** " + level);
		if(level.equalsIgnoreCase("debug"))
			defaultLevel = Level.FINE;
		else if(level.equalsIgnoreCase("info"))
			defaultLevel = Level.INFO;
		else if(level.equalsIgnoreCase("warn"))
			defaultLevel = Level.WARNING;
		else if(level.equalsIgnoreCase("error"))
			defaultLevel = Level.SEVERE;
		else
			defaultLevel = Level.WARNING;
	}

	public static Logger get(Class clazz) {
		return get(clazz.getCanonicalName());
	}

	public static Logger get(String id) {
		if (!cache.containsKey(id)) {
			cache.put(id,new Logger(id));
		}
		return cache.get(id);
	}

	private java.util.logging.Logger logger;
	private String id;

	private Logger(String id) {
		logger=java.util.logging.Logger.getLogger(id);
		logger.setLevel(defaultLevel);
		this.id = id;
	}

	protected String msg(String msg, Object...objs) {
		for (Object obj:objs) {
			if (msg.indexOf("{}")>-1) {
				String objStr;
				if (obj==null) {
					objStr = "null";
				} else {
					objStr = obj.toString();
				}
				int idx = msg.indexOf("{}");
				msg = msg.substring(0,idx) + objStr + msg.substring(idx+2);
			}
		}
		return id + "\n" + msg;
	}

	public void debug(String msg, Object...objs) {
		if (logger.isLoggable(Level.FINE)) {
			msg = msg(msg,objs);
			logger.log(Level.INFO,msg);
		}
	}

	public void warn(String msg, Object...objs) {
		if (logger.isLoggable(Level.WARNING)) {
			msg = msg(msg,objs);
			logger.log(Level.WARNING,msg);
		}
	}

	public void info(String msg, Object...objs) {
		if (logger.isLoggable(Level.INFO)) {
			msg = msg(msg,objs);
			logger.log(Level.INFO,msg);
		}
	}

	public void error(String msg, Object...objs) {
		if (logger.isLoggable(Level.SEVERE)) {
			msg = msg(msg,objs);
			logger.log(Level.SEVERE,msg);
		}
	}

	public void error(Exception e, String msg, Object...objs) {
		if (logger.isLoggable(Level.SEVERE)) {
			msg = msg(msg,objs);
			e.printStackTrace();
			logger.log(Level.SEVERE,msg,e);
		}
	}

	public void error(Exception e) {
		if (logger.isLoggable(Level.SEVERE)) {
			e.printStackTrace();
			logger.log(Level.SEVERE,e.getLocalizedMessage(),e);
		}
	}
}
