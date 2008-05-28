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

/**
	Log to a text file. The class is started with a logging level
**/

#if (neko || hllua)

class File implements EventLog {
	var PROGNAME : String;
	var STDOUT : neko.io.FileOutput;
	public var level : LogLevel;

	public function new(service: String, file : String, level:LogLevel) {
		PROGNAME = service;
		STDOUT = neko.io.File.append(file, false);
		if(STDOUT == null)
			throw "Can not open logfile.";
		this.level = level;
	}

	public function debug(s:String) { log(s, DEBUG); }
	public function info(s:String) { log(s, INFO); }
	public function notice(s : String) { log(s, NOTICE); }
	public function warn(s : String) { log(s, WARN); }
	public function error(s : String) { log(s, ERROR); }
	public function critical(s : String) { log(s, CRITICAL); }
	public function alert(s : String) { log(s, ALERT); }
	public function emerg(s : String) { log(s, EMERG); }

	function log(s : String, lvl:LogLevel) {
		var doLog = false;
		if(Type.enumIndex(lvl) >= Type.enumIndex(level)) {
			STDOUT.write(PROGNAME + ": "+Std.string(lvl)+" : "+ s + "\n");
			STDOUT.flush();
		}
	}
}

#end
