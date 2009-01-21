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
	This is the base EventLog class. If a default logger is not created,
	the static function log() will create one based on the target platform
**/
class EventLog implements IEventLog {
	public static var defaultLogger : IEventLog;
	public static var defaultServiceName : String;
	public static var defaultLevel : LogLevel;

	public var serviceName : String;
	public var level : LogLevel;

	/**
		Create a logger under the program name [service], which
		will only log events that are greater than or equal to
		LogLevel [level]
	**/
	public function new(service : String, level : LogLevel) {
		if(defaultServiceName == null)
			defaultServiceName = service;
		if(defaultLevel == null)
			defaultLevel = NOTICE;
		this.serviceName = service;
		this.level = level;

	}

	public function debug(s:String) : Void { _log(s,DEBUG); }
	public function info(s:String) : Void { _log(s,INFO); }
	public function notice(s : String) : Void { _log(s,NOTICE); }
	public function warn(s : String) : Void { _log(s,WARN); }
	public function error(s : String) : Void { _log(s,ERROR); }
	public function critical(s : String) : Void { _log(s,CRITICAL); }
	public function alert(s : String) : Void { _log(s,ALERT); }
	public function emerg(s : String) : Void { _log(s,EMERG); }

	public function _log(s : String, ?lvl:LogLevel) {
		if(defaultLogger == this)
			throw "override";
		else
			log(s, lvl);
	}

	/**
		Logs to the default logger, at the error level specified by
		[lvl]. If [lvl] is not specified, the level NOTICE will be used.
	**/
	public static function log(s : String, ?lvl:LogLevel) {
		if(lvl == null)
			lvl = NOTICE;
		if(defaultLogger == null) {
			#if neko
				defaultLogger = new File(defaultServiceName, defaultLevel, null);
			#else
				defaultLogger = new TraceLog(defaultServiceName, defaultLevel);
			#end
		}
		defaultLogger._log(s, lvl);
	}
}