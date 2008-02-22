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
#include <cfhxdef.h>

#ifndef uint32
#define uint32 unsigned long int
#endif



#ifdef NEKO

#include <neko/neko.h>

typedef struct {
	int DB; // significant bits
	int DM;
	int DV;
	int t;
	int sign;
	value chunks;
} bigInteger;

DEFINE_KIND(k_biginteger);

#define MAX(a,b) ((a > b)?a:b)
#define MIN(a,b) ((a < b)?a:b)

#define val_biginteger(o) (bigInteger *)val_data(o)

static void destroy_biginteger( value c ) {
	bigInteger *bi;
	if(!val_is_kind(c, k_biginteger))
		return;
	bi = val_biginteger(c);
	bi->chunks = NULL;
	free(bi);
	val_kind(c) = NULL;
}

static value bi_free(value BI) {
	destroy_biginteger(BI);
	return alloc_bool(1);
}
DEFINE_PRIM(bi_free,1);

static value bi_create(value DB, value T, value SIGN, value CHUNKS)
{
	int x = 0;
	bigInteger *bi = malloc(sizeof(bigInteger));
	bi->DB = val_int(DB);
	bi->DM = ((1<<bi->DB)-1);
	bi->DV = (1<<bi->DB);
	bi->t = val_int(T);
	bi->sign = val_int(SIGN);
	bi->chunks = val_null;
	if(CHUNKS != val_null) {
		bi->chunks = alloc_array(val_array_size(CHUNKS));
		for(x=0; x < val_array_size(CHUNKS); x++) {
			val_array_ptr(bi->chunks)[x] =
			  alloc_int(val_int(val_array_ptr(CHUNKS)[x]));
		}
	}

	value v = alloc_abstract(k_biginteger, bi);
	val_gc(v, destroy_biginteger);
	return v;
}
DEFINE_PRIM(bi_create,4);

/**
	Returns array [t,sign,[chunks...]]
**/
static value bi_to_array(value BI) {
	bigInteger *a = val_biginteger(BI);
	int x = 2;
	x += val_array_size(a->chunks);
	value rv = alloc_array(x);
	val_array_ptr(rv)[0] = alloc_int(a->t);
	val_array_ptr(rv)[1] = alloc_int(a->sign);
	for(x=0;x<val_array_size(a->chunks);x++) {
		val_array_ptr(rv)[2+x] =
				alloc_int(val_int(
					val_array_ptr(a->chunks)[x]
				));
	}
	return rv;
}
DEFINE_PRIM(bi_to_array,1);


/**
	A:BigInteger - B:BigInteger -> BigInteger
**/
static value bi_sub_to(value A, value B) {
	bigInteger *a = val_biginteger(A);
	bigInteger *b = val_biginteger(B);
	bigInteger *r;
	int DB = a->DB;
	int DV = a->DV;
	int DM = a->DM;
	int i = 0;
	int c = 0;
	int m = MIN(a->t,b->t);

	int va, vb;

	value vr = bi_create(alloc_int(DB), alloc_int(0), alloc_int(0), val_null);
	r = val_biginteger(vr);
	r->chunks = alloc_array(MAX(a->t,b->t) + 1);

	while(i < m) {
		va = val_int(val_array_ptr(a->chunks)[i]);
		vb = val_int(val_array_ptr(b->chunks)[i]);
		c += (va-vb);
		val_array_ptr(r->chunks)[i++] = alloc_int(c&DM);
		c >>= DB;
	}
	if(b->t < a->t) {
		c -= b->sign;
		while(i < a->t) {
			c += val_int(val_array_ptr(a->chunks)[i]);
			val_array_ptr(r->chunks)[i++] = alloc_int(c&DM);
			c >>= DB;
		}
		c += a->sign;
	}
	else {
		c += a->sign;
		while(i < b->t) {
			c -= val_int(val_array_ptr(b->chunks)[i]);
			val_array_ptr(r->chunks)[i++] = alloc_int(c&DM);
			c >>= DB;
		}
		c -= b->sign;
	}
	r->sign = (c<0)?-1:0;
	if(c < -1) val_array_ptr(r->chunks)[i++] = alloc_int(DV+c);
	else if(c > 0) val_array_ptr(r->chunks)[i++] = alloc_int(c);
	r->t = i;

	return vr;
}
DEFINE_PRIM(bi_sub_to,2);



#endif
