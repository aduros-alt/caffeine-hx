#include <stdlib.h>
#include "sha1.h"

#ifndef uint32
#define uint32 unsigned long int
#endif

typedef struct stack {
        uint32 pos;
        value v;
        SHA1_CTX *context;
        struct stack *next;
} stack;


static void sha1_string(SHA1_CTX *context, const char *message, size_t length)
{
    size_t j;
    unsigned char buffer[16384];
    unsigned int i = 16384;
    const char *c = message;

    for(j=length; j; j -= i) {
        if(j < i) i = j;
        memcpy(buffer, c, i);
        SHA1Update(context, buffer, i);
        c += i;
    }
}

static void sha1_uint32(SHA1_CTX *context, uint32 val)
{
	SHA1Update(context, (unsigned char*)&val, 4);
}


#ifdef NEKO

#include <neko/neko.h>

/**
This is coded to the same structure as haxe/neko md5.
see libs/std/md5.c
**/

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
		sha1_uint32(context, val_bool(v)?8:16;
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
