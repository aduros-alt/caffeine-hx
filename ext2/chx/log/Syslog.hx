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

#if (neko || cpp)

class Syslog extends EventLog, implements IEventLog {
	/** the system command needed to add entries to the syslog service **/
	public static var loggerCmd : String = "logger";

	override public function _log(s:String, ?lvl:LogLevel) {
		if(lvl == null)
			lvl = NOTICE;
		if(Type.enumIndex(lvl) >= Type.enumIndex(level)) {
			var priority : String = switch(lvl) {
			case DEBUG: "user.debug";
			case INFO: "user.info";
			case NOTICE: "user.notice";
			case WARN: "user.warning";
			case ERROR: "user.err";
			case CRITICAL: "user.crit";
			case ALERT: "user.alert";
			case EMERG: "user.emerg";
			}
			neko.Sys.command(loggerCmd, ["-i", "-p", priority, "-t", StringTools.urlEncode(serviceName), s]);
		}
	}
}
#end
