/*
 * Copyright (c) 2008-2012, The Caffeine-hx project contributors
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

#include <stdio.h>
#include <string.h>
#include <string>
#include "neko_cpp_compat.h"

#define NULL_PTR_ERROR		-1111
#define CHECK_NULL_IO() if(io == NULL) { \
	lastError = NULL_PTR_ERROR; \
	return NULL_PTR_ERROR; }


struct fio
{
	std::string name;
	std::string mode;
	int lastError;
	FILE *io;
	
	fio(FILE *pFP = NULL) : io(pFP), lastError(0) {
	}

	bool open(value nname, value nmode) {
		val_check(nname, string);
		val_check(nmode, string);
		close();
		this->name = std::string(val_string(nname));
		this->mode = std::string(val_string(nmode));
		const char *cn = val_string(nname);
		const char *cm = val_string(nmode);
		this->io = fopen(cn, cm);
		if(io == NULL)
			lastError = errno;
		return (io != NULL);
	}

	bool open_tmpfile() {
		close();
		io = tmpfile();
		name = std::string("TMPFILE");
		mode = std::string("w+");
		if(io == NULL)
			lastError = errno;
		return (io != NULL);
	}
	
	void close() {
		if(io != NULL)
			fclose(io);
		io = NULL;
	}

	/**
	 * @return bytes read or <0 on error
	 **/
	int read(char *buf, int pos, int len) {
		CHECK_NULL_IO();
		int bytes = 0;
		int b = 0;
		while( len > 0 ) {
			resume:
			b = (int)fread(buf+pos, 1, len, io);
			if( b <= 0 ) {
				if( ferror(io) ) {
					lastError = errno;
					if( errno == EINTR )
						goto resume;
					else
						return -1;
				}
				return bytes;
			}
			len -= b;
			pos += b;
			bytes += b;
		}
		return bytes;
	}

	int write(char *buf, int pos, int len) {
		CHECK_NULL_IO();
		int bytes = 0;
		int b = 0;
		while( len > 0 ) {
			resume:
			b = (int)fwrite(buf+pos, 1, len, io);
			if( b <= 0 ) {
				lastError = errno;
				if( ferror(io) && errno == EINTR )
					goto resume;
				// all other errors are really bad
				return -1;
			}
			len -= b;
			pos += b;
			bytes += b;
		}
		return bytes;
	}

	/**
	 * @return 0 on success
	 **/
	int flush() {
		CHECK_NULL_IO();
		int rv = fflush(io);
		if(rv)
			lastError = errno;
		return rv;
	}

	/**
	 * @return >=0 on success
	 **/
	int tell() {
		CHECK_NULL_IO();
		int rv = ftell(io);
		if(rv < 0)
			lastError = errno;
		return rv;
	}

	/**
	 * @return >=0 on success
	 **/
	int seek(int offset, int whence) {
		CHECK_NULL_IO();
		int rv = fseek(io, offset, whence);
		if(rv < 0)
			lastError = errno;
		return rv;
	}

	/**
	 * @return >=0 on success
	 **/
	int rewind() {
		return(seek(0, SEEK_SET));
	}

	bool eof() {
		CHECK_NULL_IO();
		return feof(io);
	}
	
	const char* err_string() {
		if(lastError == 0)
			return "";
		if(lastError == NULL_PTR_ERROR)
			return "IO not initialized";
		return (const char*)strerror(lastError);
	}

	void reset_error() {
		lastError = 0;
	}
};

#define val_file(o)	((fio*)val_data(o))

DEFINE_KIND(k_file_ext);

DECLARE_KIND(k_file_ext);

#define MAKE_FP(v)	val_check_kind(v,k_file_ext); \
	fio* f = val_file(v); \
	if(f == NULL) fileext_error("Null file pointer")

static void fileext_error( const char *msg, fio *f = NULL, bool deleteFp = false ) {
	std::string s = std::string(msg);
	if(f != NULL) {
		s += ": ";
		s += f->err_string();
		f->reset_error();
	}
	if(deleteFp && f != NULL) {
		f->close();
		delete f;
	}
	val_throw(alloc_string(msg));
}

static void fileext_free_file( value o ) {
	fio *f = val_file(o);
	if(f != NULL)
		f->close();
	delete f;
	val_gc(o, NULL);
}

/**
 * Open a file
 * @param name File name including path
 * @param mode File mode (r, rw, w etc)
 * @return value file handle
 **/
static value fileext_open(value name, value mode) {
	val_check(name, string);
	val_check(mode, string);
	fio* f = new fio();

	if(!f->open(name, mode))
		fileext_error("Unable to open file", f, true);

	value v = alloc_abstract(k_file_ext,f);
	val_gc(v, fileext_free_file);
	return v;
}

/**
 * Create a temporary file which will be destroyed automatically when it is closed
 * @return value file handle
 **/
static value fileext_tmpfile_open() {
	fio* f = new fio();
	if( !f->open_tmpfile() )
		fileext_error("Unable to create temporary file", f, true);

	value v = alloc_abstract(k_file_ext,f);
	val_gc(v, fileext_free_file);
	return v;
}

/**
 * Close a file
 * @param nfp File handle
 **/
static value fileext_close( value nfp ) {
	MAKE_FP(nfp);
	f->close();
	return alloc_bool(true);
}

/**
 * Read from file handle into buffer
 * @param nfp File handle
 * @param nbuf Buffer to read into
 * @param npos Starting pos in buffer
 * @param ncount Number of bytes to read
 **/
static value fileext_read( value nfp, value buf, value npos, value ncount ) {
	MAKE_FP(nfp);
	BYTES_TO_NEKO(buf);
	val_check(npos,int);
	val_check(ncount,int);
	
	int pos = val_int(npos);
	int len = val_int(ncount);

	if( pos < 0 || len < 0 || pos > buf_len || pos + len > buf_len )
		return alloc_null();

	int r = f->read(buf_ptr, pos, len);
	if(r < 0)
		fileext_error("File read error", f);
	return alloc_int(r);
}

static value fileext_read_char( value nfp ) {
	MAKE_FP(nfp);
	unsigned char c;
	int r = f->read((char *)&c, 0, 1);
	if(r < 0)
		fileext_error("File read error", f);
	return alloc_int(c);
}

static value fileext_write( value nfp, value buf, value npos, value ncount ) {
	MAKE_FP(nfp);
	BYTES_TO_NEKO(buf);
	val_check(npos,int);
	val_check(ncount,int);

	int pos = val_int(npos);
	int len = val_int(ncount);

	if( pos < 0 || len < 0 || pos > buf_len || pos + len > buf_len )
		return alloc_null();
	int r = f->write(buf_ptr, pos, len);
	if(r < 0)
		fileext_error("File write error", f);
	return alloc_int(r);
}

static value fileext_write_char( value nfp, value nc ) {
	MAKE_FP(nfp);
	val_check(nc, int);
	if(val_int(nc) > 255 || val_int(nc) < 0)
		fileext_error("byte out of range 0...255");
	unsigned char c = (unsigned char)val_int(nc);
	int r = f->write((char *)&c, 0, 1);
	if(r < 0)
		fileext_error("File write error", f);
	return alloc_int(r);
}

/**
 * @return true on success
 **/
static value fileext_flush( value nfp ) {
	MAKE_FP(nfp);
	if(f->flush() != 0)
		fileext_error("File flush error", f);
	return alloc_bool(true);
}

/**
 * @return current offset
 **/
static value fileext_tell( value nfp ) {
	MAKE_FP(nfp);
	int r = f->tell();
	if(r < 0)
		fileext_error("File tell error", f);
	return alloc_int(r);
}

/**
 * @return true on success
 **/
static value fileext_seek( value nfp, value offset, value whence ) {
	MAKE_FP(nfp);
	val_check(offset, int);
	val_check(whence, int);
	int w = val_int(whence);
	switch(w) {
		case 0: w = SEEK_SET; break;
		case 1: w = SEEK_CUR; break;
		case 2: w = SEEK_END; break;
		default:
			fileext_error("Whence out of range", f);
	}
	if(f->seek(val_int(offset), val_int(whence)) < 0)
		fileext_error("File seek error", f);
	return alloc_bool(true);
}

/**
 * @return true on success
 **/
static value fileext_rewind( value nfp ) {
	MAKE_FP(nfp);
	if(f->rewind() < 0)
		fileext_error("File rewind error", f);
	return alloc_bool(true);
}

/**
 * @return 'true' if eof, 'false' otherwise
 **/
static value fileext_feof( value nfp ) {
	MAKE_FP(nfp);
	return alloc_bool(f->eof());
}

/**
 * Read whole file into ram
 **/
static value fileext_contents( value fname ) {
	val_check(fname, string);
	fio f;
	f.open(fname,alloc_string("r"));
	if(f.io == NULL)
		fileext_error("Unable to open file");
	f.seek(0, SEEK_END);
	int len = f.tell();
	f.seek(0, SEEK_SET);
	char *cb = (char *)malloc(len);
	if(cb == NULL)
		fileext_error("Out of memory");
	int res = f.read(cb, 0, len);
	value s = alloc_string_len((const char *)cb,len);
	free(cb);
	return s;
}

static void fileext_free_stdio( value o ) {
	fio *f = val_file(o);
	delete f;
	val_gc(o, NULL);
}

#define MAKE_STDIO(k) \
static value fileext_##k() { \
	fio *f = new fio(); \
	f->io = k; \
	f->name = std::string(#k); \
	value rv = alloc_abstract(k_file_ext,f); \
	val_gc(rv,fileext_free_stdio); \
	return rv; \
} \
DEFINE_PRIM(fileext_##k,0);

MAKE_STDIO(stdin);
MAKE_STDIO(stdout);
MAKE_STDIO(stderr);


DEFINE_PRIM(fileext_open,2);
DEFINE_PRIM(fileext_tmpfile_open,0);
DEFINE_PRIM(fileext_close,1);
DEFINE_PRIM(fileext_read,4);
DEFINE_PRIM(fileext_read_char,1);
DEFINE_PRIM(fileext_write,4);
DEFINE_PRIM(fileext_write_char,2);
DEFINE_PRIM(fileext_contents,1);

DEFINE_PRIM(fileext_tell,1);
DEFINE_PRIM(fileext_seek,3);
DEFINE_PRIM(fileext_rewind,1);
DEFINE_PRIM(fileext_feof,1);
DEFINE_PRIM(fileext_flush,1);
