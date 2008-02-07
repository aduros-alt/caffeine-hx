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

typedef struct {
	int initialized;
} xdiff_data;

typedef struct {
	char *p;
	unsigned long len;
} outBuf;

static xdiff_data data = { 0 };

DEFINE_ENTRY_POINT(xdiff_main);



#if MALLOC_BOEHM

static void *xdiff_malloc(void *priv, unsigned int size)
{
	return malloc(size);
}

static void xdiff_free(void *priv, void *ptr)
{
	free(ptr);
}

static void *xdiff_realloc(void *priv, void *ptr, unsigned int nsize)
{
	return realloc(ptr, nsize);
}
#endif

void xdiff_main() {
	if(data.initialized)
		return;
	data.initialized = true;

#if MALLOC_BOEHM
	memallocator_t malt;
	malt.priv = NULL;
	malt.malloc = xdiff_malloc;
	malt.free = xdiff_free;
	malt.realloc = xdiff_realloc;
	xdl_set_allocator(&malt);
#endif
}


static int copy_to_mmfile(const char *src, long size, mmfile_t *dest)
{
	void *p;
	if(size < 0)
		return 0;
	if(xdl_init_mmfile(dest, size, XDL_MMF_ATOMIC) < 0)
		return 0;
	p = xdl_mmfile_writeallocate(dest, size);
	if (!p) {
		xdl_free_mmfile(dest);
		return 0;
	}
	memcpy(ptr, buffer, size);
	return 1;
}

static int init_outbuf(outBuf *buf, unsigned int bytes)
{
	buf->len = bytes;
	buf->p = xdl_malloc(bytes);
	if (!buf->p)
		return 0;
	memset(buf->p, 0, bytes);
	return 1;
}

static void free_outbuf(outBuf *buf)
{
	if(buf->p != NULL) {
		xdl_free(buf->p);
		buf->p = NULL;
	}
}

/*
The first parameter of the callback is the same priv field specified inside the xdemitcb_t structure. The second parameter point to an array of mmbuffer_t (see above for a definition of the structure) whose element count is specified inside the last parameter of the callback itself. The callback will always be called with entire records (lines) and never a record (line) will be emitted using two different callback calls. This is important because if the called will use another memory file to store the result, by creating the target memory file with XDL_MMF_ATOMIC will guarantee the "atomicity" of the memory file itself. The function returns 0 if succeeded or -1 if an error occurred.
*/
static int append_data(void *p, mmresults_t *results, int count)
{
	struct string_results *string = ptr;
	outBuf *buf = p;
	int x;

	for (x = 0; x < count; x++) {
		buf->p = xdl_realloc(buf->p, buf->len + results[x].size + 1);
		if(!buf->p)
			return -1;
		memcpy(buf->p + buf->len, results[x].ptr, results[x].size);
		buf->len += results[x].size;
	}

	return 0;
}

static int init_callback(xdemitcb_t *cb, outBuf *bufptr)
{
	if(outBuf == NULL || cb == NULL)
		return 0;
	cb->priv = bufptr;
	cb->outf = append_data;
	return 1;
}

static value xdiff_string(value orig, value modified, value context, value minimal)
{
	outBuf buf;
	mmfile_t f1, f2;
	xpparam_t params;
	xdemitconf_t config;
	xdemitcb_t cb;
	char *s1, *s2;
	int slen1, slen2;

	val_check(orig, string);
	val_check(modified, string);
	val_check(context, int);
	val_check(minimal, bool);

	s1 = val_string(orig);
	s2 = val_string(modified);
	slen1 = val_strlen(s1);
	slen2 = val_strlen(s2);

	if(val_int(context) < 0)
		return NULL;
	if(!init_outbuf(&buf))
		return NULL;
	if(!init_callback(&cb, &buf))
		return NULL;
	params.flags = (val_bool(minimal)) ? XDF_NEED_MINIMAL : 0;

	if(!copy_to_mmfile(s1, slen1, &f1))
		return NULL;
	if(!copy_to_mmfile(s2, slen2, &f2)) {
		xdl_free_mmfile(&f1);
		return NULL;
	}
	config.ctxlen = val_int(context);

	int rv = xdl_diff(&f1, &f2, &params, &config, cb);

	xdl_free_mmfile(&f1);
	xdl_free_mmfile(&f2);

	if(rv) {
		free_outbuf(&buf);
		return NULL;
	}
	value v = copy_string(string.ptr, string.size);
	free_outbuf(&buf);
	return v;
}
DEFINE_PRIM(xdiffStringDiff,4);


