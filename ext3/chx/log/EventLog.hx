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

package chx.log;

import chx.log.LogLevel;

/**
*  This is the base EventLog class. If a default logger is not created,
*  the static function log() will create one based on the target platform.
*  Multiple IEventLogs can be added to the
**/
class EventLog {
	/** The list of loggers that will record events */
	public static var loggers : List<IEventLog> = new List<IEventLog>();
	public static var defaultServiceName : String;
	public static var defaultLevel : LogLevel = NOTICE;

	/**
	 * Adds an IEventLog instance to the logging chain
	 * @param	l
	 */
	public static function add(l:IEventLog) {
		var found = false;
		for (i in loggers) {
			if (i == l) {
				found = true;
				break;
			}
		}
		if (!found)
			loggers.add(l);		
	}
	
	public static function close() : Void {
		for (i in loggers) {
			i.close();
		}
		loggers.clear();
	}
	
	public static function debug(s:String) : Void { log(s,DEBUG); }
	public static function info(s:String) : Void { log(s,INFO); }
	public static function notice(s : String) : Void { log(s,NOTICE); }
	public static function warn(s : String) : Void { log(s,WARN); }
	public static function error(s : String) : Void { log(s,ERROR); }
	public static function critical(s : String) : Void { log(s,CRITICAL); }
	public static function alert(s : String) : Void { log(s,ALERT); }
	public static function emerg(s : String) : Void { log(s,EMERG); }

	/**
		Logs to the default logger, at the error level specified by
		[lvl]. If [lvl] is not specified, the level NOTICE will be used.
	**/
	public static function log(s : String, ?lvl:LogLevel) {
		if(lvl == null)
			lvl = NOTICE;
		if(loggers.length == 0) {
			#if (neko||php||cpp)
				new File(defaultServiceName, defaultLevel, null).addToLogChain();
			#else
				new TraceLog(defaultServiceName, defaultLevel).addToLogChain();
			#end
		}
		for (i in loggers) {
			i.log(s, lvl);
		}
	}
}