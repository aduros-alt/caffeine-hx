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

#include <neko/neko.h>
#include <unistd.h>
#include <sys/types.h>
#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <sys/utsname.h>


/**
	Returns path to controlling terminal name
**/
static value posix_ctermid() {
	return alloc_string(ctermid(NULL));
}
DEFINE_PRIM(posix_ctermid,0);


/**
	Return effective group id of current process
**/
static value posix_getegid() {
	return alloc_int32(getegid());
}
DEFINE_PRIM(posix_getegid,0);


/**
	Return effective user id of current process
	@returns Int32
**/
static value posix_geteuid() {
	return alloc_int32(geteuid());
}
DEFINE_PRIM(posix_geteuid,0);


/**
	Return real group id of current process. This is at the time of
	lauching the program.
**/
static value posix_getgid() {
	return alloc_int32(getgid());
}
DEFINE_PRIM(posix_getgid,0);


/**
	Return process id of current process
	@returns Int32
**/
static value posix_getpid() {
	return alloc_int32(getpid());
}
DEFINE_PRIM(posix_getpid,0);


/**
	Return real user id of current process.  This is at the time of
	lauching the program.
	@returns Int32
**/
static value posix_getuid() {
	return alloc_int32(getuid());
}
DEFINE_PRIM(posix_getuid,0);


/**
	Return last error number
	@returns Int32 error number
**/
static value posix_get_last_error() {
	return alloc_int32(errno);
}
DEFINE_PRIM(posix_get_last_error,0);


/**
	Send a kill signal to a process
	@param pid Int32/Int process id
	@param sig Int signal
	@returns Boolean true on success
**/
static value posix_kill(value pid, value sig) {
	if(!val_is_int32(pid))
		neko_error();
	if(!val_is_int32(sig))
		neko_error();
	int rv = kill(val_int32(pid), val_int32(sig));
	return alloc_bool(!rv);
}
DEFINE_PRIM(posix_kill,2);


/**
	Sets the group id for the current process.
	@param gid Int/Int32 group id
	@returns true on success
**/
static value posix_setgid(value gid) {
	if(!val_is_int32(gid))
		neko_error();
	int rv = setgid(val_int32(gid));
	return alloc_bool(!rv);
}
DEFINE_PRIM(posix_setgid,1);


/**
	Sets the user id for the current process.
	@param uid Int/Int32 user id
**/
static value posix_setuid(value uid) {
	if(!val_is_int32(uid))
		neko_error();
	int rv = setuid(val_int32(uid));
	return alloc_bool(!rv);
}
DEFINE_PRIM(posix_setuid,1);


/**
	Return descriptive string for error code
	@param v Int32 errno
	@returns string
**/
static value posix_strerror(value v) {
	if(!val_is_int32(v))
		neko_error();
	return alloc_string(strerror(val_int32(v)));
}
DEFINE_PRIM(posix_strerror,1);


/**
	Return system name
	@returns Int32 error number
**/
static value posix_uname() {
	struct utsname u;
	if (uname(&u) < 0) {
		return val_null;
	}
	value o = alloc_object(NULL);
	alloc_field(o, val_id("sysname"),  alloc_string(u.sysname));
	alloc_field(o, val_id("nodename"), alloc_string(u.nodename));
	alloc_field(o, val_id("release"),  alloc_string(u.release));
	alloc_field(o, val_id("version"),  alloc_string(u.version));
	alloc_field(o, val_id("machine"),  alloc_string(u.machine));
#ifdef _GNU_SOURCE
	alloc_field(o, val_id("domainname"), alloc_string(u.domainname));
#endif
	return o;
}
DEFINE_PRIM(posix_uname,0);

