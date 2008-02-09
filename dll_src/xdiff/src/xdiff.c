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

#include <stdlib.h>
#include <string.h>
#include <neko/neko.h>
#include <xdiff.h>
#include <cfhxdef.h>
#include <stdio.h>

// ref: http://www.xmailserver.org/xdiff.html

MUTEX_CREATE(m_xdiff);

DEFINE_ENTRY_POINT(xdiff_main);
DEFINE_KIND(k_xdiffmmfile);

#define val_mmfile(o)     ((mmfile_t*)val_data(o))

typedef struct {
	int initialized;
} xdiff_data;

typedef struct s_outbuf {
	char *p;
	int has_data;
	unsigned long len;
} outbuf_t;

static xdiff_data data = { 0 };


static void *xdiff_malloc(void *priv, unsigned int size)
{
#if MALLOC_BOEHM
#endif
	return malloc(size);
}

static void xdiff_free(void *priv, void *p)
{
	free(p);
}

static void *xdiff_realloc(void *priv, void *p, unsigned int size)
{
	return realloc(p, size);
}

void xdiff_main() {
	MUTEX_INIT(m_xdiff);
	MUTEX_LOCK(m_xdiff);

	if(data.initialized) {
		MUTEX_UNLOCK(m_xdiff);
		return;
	}
	data.initialized = true;

	memallocator_t mem;
	mem.priv = NULL;
	mem.malloc = xdiff_malloc;
	mem.free = xdiff_free;
	mem.realloc = xdiff_realloc;
	xdl_set_allocator(&mem);

	MUTEX_UNLOCK(m_xdiff);
}

static void xdiff_throw(const char *msg) {
	value a = alloc_string(msg);
	val_throw(a);
}

static int copy_to_mmfile(const char *src, mmfile_t *dest, long size)
{
	void *p;
	if(!src || !dest || size < 0)
		return 0;
	if(xdl_init_mmfile(dest, size, XDL_MMF_ATOMIC))
		return 0;
	p = xdl_mmfile_writeallocate(dest, size);
	if(p == NULL) {
		xdl_free_mmfile(dest);
		return 0;
	}
	memcpy(p, src, size);
	return 1;
}

static int init_outbuf(outbuf_t *buf, unsigned int bytes)
{
	buf->len = bytes;
	buf->has_data = 0;
	buf->p = malloc(bytes);
	if (!buf->p) {
		return 0;
	}
	memset(buf->p, 0, bytes);
	return 1;
}

static void free_outbuf(outbuf_t *buf)
{
	if(buf->p != NULL) {
		free(buf->p);
		buf->p = NULL;
		buf->len = 0;
		buf->has_data = 0;
	}
}

/*
The first parameter of the callback is the same priv field specified inside the xdemitcb_t structure. The second parameter point to an array of mmbuffer_t (see above for a definition of the structure) whose element count is specified inside the last parameter of the callback itself. The callback will always be called with entire records (lines) and never a record (line) will be emitted using two different callback calls. This is important because if the called will use another memory file to store the result, by creating the target memory file with XDL_MMF_ATOMIC will guarantee the "atomicity" of the memory file itself. The function returns 0 if succeeded or -1 if an error occurred.
*/
static int append_data(void *p, mmbuffer_t *data, int count)
{
	outbuf_t *buf = p;
	int x;
	unsigned long len;

	if(!buf->p)
		return -1;

	if(buf->has_data)
		len = buf->len;
	else
		len = 0;

	for (x = 0; x < count; x++) {
		buf->p = xdl_realloc(buf->p, len + data[x].size + 1);
		if(!buf->p) {
			buf->len = 0;
			buf->has_data = 0;
			return -1;
		}

		memcpy(buf->p + len, data[x].ptr, data[x].size);
		len += data[x].size;
	}
	buf->len = len;
	if(x > 0)
		buf->has_data = 1;
	return 0;
}

static int init_callback(xdemitcb_t *cb, outbuf_t *buf)
{
	if(buf == NULL || cb == NULL)
		return 0;
	cb->priv = buf;
	cb->outf = append_data;
	return 1;
}

/**
	Diff two neko text strings.
**/
static value xdiff_string(value orig, value modified, value context, value minimal)
{
	outbuf_t buf;
	mmfile_t f1, f2;
	xpparam_t params;
	xdemitconf_t config;
	xdemitcb_t cb;
	char *s1, *s2;
	long slen1, slen2;
	value v;

	val_check(orig, string);
	val_check(modified, string);
	val_check(context, int);
	val_check(minimal, bool);

	s1 = val_string(orig);
	s2 = val_string(modified);
	slen1 = (long)val_strlen(orig);
	slen2 = (long)val_strlen(modified);

	if(val_int(context) < 0)
		return NULL;
	if(!init_outbuf(&buf, 1))
		xdiff_throw("Buffer init error");
	if(!init_callback(&cb, &buf))
		xdiff_throw("Callback init error");
	params.flags = (val_bool(minimal)) ? XDF_NEED_MINIMAL : 0;

	if(!copy_to_mmfile(s1, &f1, slen1))
		xdiff_throw("Buf copy error - original");
	if(!copy_to_mmfile(s2, &f2, slen2)) {
		xdl_free_mmfile(&f1);
		xdiff_throw("Buf copy error - modified");
	}
	config.ctxlen = val_int(context);

	int rv = xdl_diff(&f1, &f2, &params, &config, &cb);

	xdl_free_mmfile(&f1);
	xdl_free_mmfile(&f2);

	if(rv) {
		free_outbuf(&buf);
		xdiff_throw("Diff error");
	}
	if(buf.has_data)
		v = copy_string(buf.p, buf.len);
	else
		v = alloc_string("");
	free_outbuf(&buf);
	return v;
}
DEFINE_PRIM(xdiff_string,4);

/**
	Create an mmfile_t from a string value.
**/
static value xdiff_make_buf(value s) {
	mmfile_t *mmfp;
	val_check(s, string);

	mmfp = malloc(sizeof(mmfile_t));
	if(!mmfp)
		return NULL;

	if(!copy_to_mmfile(val_string(s), mmfp, (long)val_strlen(s)))
		xdiff_throw("Buf copy error");

	value v = alloc_abstract(k_xdiffmmfile, mmfp);
	return v;
}
DEFINE_PRIM(xdiff_make_buf,1);
