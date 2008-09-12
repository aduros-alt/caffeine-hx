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
#include "sha1.h"
#include "sha2.h"
#include <cfhxdef.h>

#ifndef uint32
#define uint32 u_int32_t
#endif

typedef struct {
	u_int16_t type;
	union {
		SHA1_CTX   *text1;
		sha224_ctx *text224;
		sha256_ctx *text256;
		sha384_ctx *text384;
		sha512_ctx *text512;
	} con;
} sha_container;

/*
	switch(sc->type) {
	case 1:
		break;
	case 224:
		break;
	case 256:
		break;
	case 384:
		break;
	case 512:
		break;
	default:
		THROW("invalid sha size");
	}
*/

static void sha1_string(SHA1_CTX *context, const char *message, size_t length)
{
	size_t j;
	unsigned char buffer[16384];
	u_int16_t i = 16384;
	const char *c = message;

	for(j=length; j; j -= i) {
		if(j < i) i = j;
		memcpy(buffer, c, i);
		SHA1Update(context, buffer, i);
		c += i;
	}
}

static void sha_uint32(SHA1_CTX *context, uint32 val)
{
	SHA1Update(context, (unsigned char*)&val, 4);
}

static void sha_string(sha_container *container, const char *message, size_t length)
{
	size_t j;
	unsigned char buffer[16384];
	u_int16_t i = 16384;
	const char *c = message;

	for(j=length; j; j -= i) {
		if(j < i) i = j;
		memcpy(buffer, c, i);
		switch(container->type) {
		case 1:
			SHA1Update(container->con.text1, buffer, i);
			break;
		case 224:
			sha224_update(container->con.text224, buffer, i);
			break;
		case 256: sha256_update(container->con.text256, buffer, i); break;
		case 384: sha384_update(container->con.text384, buffer, i); break;
		case 512: sha512_update(container->con.text512, buffer, i); break;
		}
		c += i;
	}
}

static void sha1_uint32(SHA1_CTX *context, uint32 val)
{
	SHA1Update(context, (unsigned char*)&val, 4);
}

#ifdef NEKO

#include <neko/neko.h>

DEFINE_KIND(k_shacontainer);
#define val_shacontainer(o) (sha_container *)val_data(o)

/**
This is coded to the same structure as haxe/neko md5.
see libs/std/md5.c
**/

typedef struct stack {
	uint32 pos;
	value v;
	SHA1_CTX *context;
	//neko_sha_container *
	struct stack *next;
} stack;
static void neko_sha1( SHA1_CTX *context, value v, stack *cur);


static void make_sha1_fields( value v, field f, void *c ) {
	stack *s = (stack*)c;
	sha1_uint32(s->context, f);
	neko_sha1(s->context, v, s);
}

static void neko_sha1( SHA1_CTX *context, value v, stack *cur) {
	switch(val_type(v)) {
	case VAL_NULL:
		sha1_uint32(context, 0);
		break;
	case VAL_INT:
		sha1_uint32(context, (uint32)(int_val)v);
		break;
	case VAL_BOOL:
		sha1_uint32(context, val_bool(v)?8:16);
		break;
	case VAL_FLOAT:
		{
			tfloat f = val_float(v);
			SHA1Update(context, (unsigned char *)&f, sizeof(tfloat));
		}
		break;
	case VAL_STRING:
		sha1_string(context, (const char *)val_string(v), (size_t)val_strlen(v));
		break;
	case VAL_OBJECT:
	case VAL_ARRAY:
		{
			stack loc;
			stack *s = cur;
			while( s != NULL ) {
				if( s->v == v ) {
					sha1_uint32(context, (s->pos << 3) | 2);
					return;
				}
				s = s->next;
			}
			loc.v = v;
			loc.pos = cur?(cur->pos+1):0;
			loc.next = cur;
			loc.context = context;
			if( val_is_object(v) ) {
				val_iter_fields(v, make_sha1_fields, &loc);
				v = (value)((vobject*)v)->proto;
				if( v != NULL )
					neko_sha1(context, v, &loc);
			} else {
				int len = val_array_size(v);
				sha1_uint32(context, (len << 3) | 6);
				while( len-- > 0 )
					neko_sha1(context, val_array_ptr(v)[len],&loc);
			}
		}
		break;
	case VAL_FUNCTION:
		sha1_uint32(context, (val_fun_nargs(v) << 3) | 4);
		break;
	case VAL_ABSTRACT:
		sha1_uint32(context, 24);
		break;
	}
}

static void destroy_container( value c ) {
	sha_container *sc;
	if(!val_is_kind(c, k_shacontainer))
		return;
	sc = val_shacontainer(c);
	free(sc->con.text1);
	free(sc);
	val_kind(c) = NULL;
}

static value sha_init(value Size) {
	u_int32_t size;
	sha_container *sc;
	val_check(Size, int);
	size = val_int(Size);
	buffer b;

	sc = (sha_container *) malloc(sizeof(sha_container));
	if(sc == NULL)
		E_NO_MEM();
	switch(size) {
	case 1:
		sc->type = 1;
		sc->con.text1 = malloc(sizeof(SHA1_CTX));
		if(sc->con.text1 == NULL) goto err;
		SHA1Init(sc->con.text1);
		break;
	case 224:
		sc->type = 224;
		sc->con.text224 = malloc(sizeof(sha224_ctx));
		if(sc->con.text224 == NULL) goto err;
		sha224_init(sc->con.text224);
		break;
	case 256:
		sc->type = 256;
		sc->con.text256 = malloc(sizeof(sha256_ctx));
		if(sc->con.text256 == NULL) goto err;
		sha256_init(sc->con.text256);
		break;
	case 384:
		sc->type = 384;
		sc->con.text384 = malloc(sizeof(sha384_ctx));
		if(sc->con.text384 == NULL) goto err;
		sha384_init(sc->con.text384);
		break;
	case 512:
		sc->type = 512;
		sc->con.text512 = malloc(sizeof(sha512_ctx));
		if(sc->con.text512 == NULL) goto err;
		sha512_init(sc->con.text512);
		break;
	default:
		free(sc);
		b = alloc_buffer("sha_init: invalid sha size ");
		val_buffer(b, alloc_int(sc->type));
		val_throw(buffer_to_string(b));
	}
	value v = alloc_abstract(k_shacontainer, sc);
	val_gc(v, destroy_container);
	return v;
err:
	free(sc);
	E_NO_MEM();
}
DEFINE_PRIM(sha_init,1);

static value sha_update(value SC, value Msg) {
	sha_container *sc;
	val_check_kind(SC, k_shacontainer);
	val_check(Msg, string);
	buffer b;

	sc = val_shacontainer(SC);
	if(sc == NULL)
		THROW("sha_update: null handle");
	switch(sc->type) {
	case 1:
		SHA1Update(sc->con.text1, val_string(Msg), val_strlen(Msg));
		break;
	case 224:
		sha224_update(sc->con.text224, val_string(Msg), val_strlen(Msg));
		break;
	case 256:
		sha256_update(sc->con.text256, val_string(Msg), val_strlen(Msg));
		break;
	case 384:
		sha384_update(sc->con.text384, val_string(Msg), val_strlen(Msg));
		break;
	case 512:
		sha512_update(sc->con.text512, val_string(Msg), val_strlen(Msg));
		break;
	default:
		b = alloc_buffer("sha_update: invalid sha size ");
		val_buffer(b, alloc_int(sc->type));
		val_throw(buffer_to_string(b));
	}
	return alloc_bool(1);
}
DEFINE_PRIM(sha_update,2);

static value sha_final(value SC) {
	sha_container *sc;
	val_check_kind(SC, k_shacontainer);
	value rv;
	buffer b;

	sc = val_shacontainer(SC);
	if(sc == NULL)
		THROW("sha_final: null handle");
	switch(sc->type) {
	case 1:
		rv = alloc_empty_string(SHA1_DIGEST_SIZE);
		SHA1Final((unsigned char *)val_string(rv), sc->con.text1);
		break;
	case 224:
		rv = alloc_empty_string(SHA224_DIGEST_SIZE);
		sha224_final(sc->con.text224, (unsigned char *)val_string(rv));
		break;
	case 256:
		rv = alloc_empty_string(SHA256_DIGEST_SIZE);
		sha256_final(sc->con.text256, (unsigned char *)val_string(rv));
		break;
	case 384:
		rv = alloc_empty_string(SHA384_DIGEST_SIZE);
		sha384_final(sc->con.text384, (unsigned char *)val_string(rv));
		break;
	case 512:
		rv = alloc_empty_string(SHA512_DIGEST_SIZE);
		sha512_final(sc->con.text512, (unsigned char *)val_string(rv));
		break;
	default:
		b = alloc_buffer("sha_final: invalid sha size ");
		val_buffer(b, alloc_int(sc->type));
		val_throw(buffer_to_string(b));
	}
	return rv;
}
DEFINE_PRIM(sha_final,1);

static value nsha1(value v) {
	SHA1_CTX context;
	SHA1Init(&context);
	neko_sha1( &context, v, NULL);
	value rv = alloc_empty_string(20);
	SHA1Final((unsigned char *)val_string(rv), &context);
	return rv;
}
DEFINE_PRIM(nsha1,1);

#elif defined(LUA)

#include "lua.h"
#include "lauxlib.h"

/**
*  Hash function. Returns a hash for a given string.
*  @param message: arbitrary binary string.
*  @return  A 160-bit hash string.
*/
static int lsha1 (lua_State *L) {
	unsigned char digest[20];
	size_t length;
	const char *message = luaL_checklstring(L, 1, &length);
	SHA1(message, length, digest);
	lua_pushlstring(L, (const char *)digest, 20L);
	return 1;
}


static struct luaL_reg sha1lib[] = {
{"sum", lsha1},
{NULL, NULL}
};


int luaopen_sha1 (lua_State *L) {
luaL_openlib(L, "sha1", sha1lib, 0);
return 1;
}

#endif
