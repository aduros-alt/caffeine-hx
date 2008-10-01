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

package system;

#if (neko || php)
class Posix {
	public static function ctermid() : String {
#if neko
		return cast neko.Lib.nekoToHaxe(posix_ctermid());
#elseif php
#end
	}

	public static function getegid() : Int32 {
#if neko
		return untyped posix_getegid();
#elseif php
#end
	}

	public static function geteuid() : Int32 {
#if neko
		return untyped posix_geteuid();
#elseif php
#end
	}

	public static function getgid() : Int32 {
#if neko
		return untyped posix_getgid();
#elseif php
#end
	}

	public static function getpid() : Int32 {
#if neko
		return untyped posix_getpid();
#elseif php
#end
	}

	public static function getuid() : Int32 {
#if neko
		return untyped posix_getuid();
#elseif php
#end
	}

	public static function getLastError() : Int32 {
#if neko
		return untyped posix_get_last_error();
#elseif php
#end
	}

	public static function kill(pid:Int32, signal:Int) : Bool {
#if neko
		return untyped posix_kill(pid, signal);
#elseif php
#end
	}

	public static function setgid(v:Int32) : Bool {
#if neko
		return untyped posix_setgid(v);
#elseif php
#end
	}

	public static function setuid(v:Int32) : Bool {
#if neko
		return untyped posix_setuid(v);
#elseif php
#end
	}

	public static function strerror(v:Int32) : String {
#if neko
		return nekoToHaxe(posix_strerror(v));
#elseif php
#end
	}

	/**
		Gets system uname information. Returns an object
		with the fields sysname, nodename, release, version,
		machine and optionally dommainname.
	**/
	public static function uname() : Dynamic {
#if neko
		return neko.Lib.nekoToHaxe(posix_uname());
#elseif php
#end
	}

#if neko
	private static var posix_ctermid = neko.Lib.load("sys_posix","posix_ctermid",0);
	private static var posix_getegid = neko.Lib.load("sys_posix","posix_getegid",0);
	private static var posix_geteuid = neko.Lib.load("sys_posix","posix_geteuid",0);
	private static var posix_getgid = neko.Lib.load("sys_posix","posix_getgid",0);
	private static var posix_getpid = neko.Lib.load("sys_posix","posix_getpid",0);
	private static var posix_getuid = neko.Lib.load("sys_posix","posix_getuid",0);
	private static var posix_get_last_error = neko.Lib.load("sys_posix","posix_get_last_error",0);
	private static var posix_kill = neko.Lib.load("sys_posix","posix_kill",2);
	private static var posix_setgid = neko.Lib.load("sys_posix","posix_setgid",1);
	private static var posix_setuid = neko.Lib.load("sys_posix","posix_setuid",1);
	private static var posix_strerror = neko.Lib.load("sys_posix","posix_strerror",1);
	private static var posix_uname = neko.Lib.load("sys_posix","posix_uname",0);
// 	private static var  = neko.Lib.load("sys_posix","",);
#end

}
#end