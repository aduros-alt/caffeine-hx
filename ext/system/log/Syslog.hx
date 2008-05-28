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


package system.log;

import system.log.LogLevel;

#if (neko || hllua)
class Syslog implements EventLog {
	public static var loggerCmd : String = "logger";
	public var level : LogLevel;

	var PROGNAME : String;

	public function new(service: String, file : String, level:LogLevel) {
		PROGNAME = service;
		this.level = level;
	}

	public function debug(s:String) : Void { log(s,"user.debug"); }
	public function info(s:String) : Void { log(s,"user.info"); }
	public function notice(s : String) : Void { log(s,"user.notice"); }
	public function warn(s : String) : Void { log(s,"user.warning"); }
	public function error(s : String) : Void { log(s,"user.err" ); }
	public function critical(s : String) : Void { log(s,"user.crit"); }
	public function alert(s : String) : Void { log(s,"user.alert"); }
	public function emerg(s : String) : Void { log(s,"user.emerg"); }

	function log(s:String, lvl:String) {
		neko.Sys.command(loggerCmd, ["-i", "-p", lvl, "-t", StringTools.urlEncode(PROGNAME), s]);
	}
}
#end