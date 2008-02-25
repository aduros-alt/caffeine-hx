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

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <cfhxdef.h>
#include <math.h>
#include "bigint.h"
#include <assert.h>

#ifndef uint32
#define uint32 unsigned long int
#endif

#ifndef ASSERT
#define ASSERT(v) assert(v)
#endif

//#define PRINT(n) printf(n);
#define PRINT(n)
#define DESTROY(n) destroy_biginteger(n)

bi_settings *bi_get_settings(int db) {
	bi_settings *rv = malloc(sizeof(bi_settings));
	rv->DB = db;
	rv->DM = ((1<<db)-1);
	rv->DV = (1<<db);
	rv->BI_FP = 52;
	rv->FV = pow(2,52);
	rv->F1 = 52 - db;
	rv->F2 = 2 * db - 52;
	return rv;
}

static int bi_nbits( int i ) {
	int r = 1;
	unsigned int x = (unsigned int) i;
	int t;
	if((t=x>>16) != 0) { x = t; r += 16; }
	if((t=x>>8) != 0) { x = t; r += 8; }
	if((t=x>>4) != 0) { x = t; r += 4; }
	if((t=x>>2) != 0) { x = t; r += 2; }
	if((t=x>>1) != 0) { x = t; r += 1; }
	return r;
}

static int am3(bigInteger *a, int i, int x, bigInteger *w, int j, int c, int n) {
	ASSERT(a != NULL);
	ASSERT(w != NULL);
	int xl = x&0x3fff;
	int xh = x>>14;
	int l, h, m;
	int cv;
	while(--n >= 0) {
		l = GET_CHUNK(a,i);
		l &= 0x3fff;
		h = GET_CHUNK(a,i);
		h >>= 14;
		i++;
		m = xh*l + h*xl;
		cv = GET_CHUNK(w,j);
		l = (xl*l) + ((m&0x3fff)<<14) + cv + c;
		c = (l>>28) + (m>>14) + (xh*h);
		//w.chunks[j++] = l&0xfffffff;
		l &= 0xfffffff;
		SET_CHUNK(w, j, l);
		j++;
	}
	return c;
}

#ifdef NEKO


DEFINE_KIND(k_biginteger);
#define val_biginteger(o) (bigInteger *)val_data(o)

/**
	Allocate n number of chunks. Any existing will be destroyed.
	@param bi bigInteger structure
	@param n # of chunks
**/
static void bip_alloc_chunks(bigInteger *bi, int n) {
	ASSERT(bi != NULL);
	if(n <= 0) {
		printf("Trying to allocate %d chunks\n", n);
		ASSERT(n>0);
		return;
	}
	if(n >= max_array_size - 2) {
		printf("Trying to allocate %d chunks\n", n);
		ASSERT(n<max_array_size);
		return;
	}
	bi->chunks = alloc_array(n);
	int x;
	for(x=0; x<n; x++) {
		SET_CHUNK(bi,x,0);
	}
}

/**
	Reallocate to n number of chunks. Any existing will be
	copied to new array. Will not reduce chunk count, only
	increases.
	@param bi bigInteger structure
	@param n # of chunks
**/
static void bip_realloc_chunks(bigInteger *bi, int n) {
	ASSERT(bi != NULL);
	int x;
	int max;

	if(n >= max_array_size - 2) {
		printf("Trying to allocate %d chunks\n", n);
		ASSERT(n<max_array_size);
		return;
	}
	if(bi->chunks == NULL) {
		bip_alloc_chunks(bi, n);
		return;
	}
	if(n <= (int)val_array_size(bi->chunks))
		return;
	value newarray = alloc_array(n);
	max = (int)val_array_size(bi->chunks);
	for(x=0; x < max; x++) {
		val_array_ptr(newarray)[x] =
			alloc_int(val_int(val_array_ptr(bi->chunks)[x]));
	}
	bi->chunks = newarray;
}

static void bip_clear(bigInteger *a) {
	if(a->chunks == NULL)
		bip_alloc_chunks(a, 1);
	int max = (int)val_array_size(a->chunks);
	int x;
	for(x =0; x < max; x++) {
		SET_CHUNK(a,x,0);
	}
	a->t = 0;
}

static void bip_clamp(bigInteger *a, int DM) {
	int c = a->sign&DM;
ASSERT(c == 0);
	while(a->t > 0 && GET_CHUNK(a, a->t-1) == c) --a->t;
}

/**
	Neko garbage collection for bigInteger struct.
	@param bi bigInteger structure
**/
static void destroy_biginteger( value c ) {
	bigInteger *bi;
	if(!val_is_kind(c, k_biginteger))
		return;
	bi = val_biginteger(c);
	bi->chunks = NULL;
	free(bi);
	val_kind(c) = NULL;
}

/////////////////////////////////////////////////////////
//                  Neko Methods                       //
/////////////////////////////////////////////////////////


static value bi_free(value BI) {
	destroy_biginteger(BI);
	return val_true;
}

static value bi_create(value DB, value T, value SIGN, value CHUNKS)
{
	int x = 0;
	bigInteger *bi = malloc(sizeof(bigInteger));
	bi->DB = val_int(DB);
	bi->t = val_int(T);
	bi->sign = val_int(SIGN);
	bi->chunks = val_null;
	if(CHUNKS != val_null) {
		BI_REALLOC(bi, (int)val_array_size(CHUNKS));
		for(x=0; x < (int)val_array_size(CHUNKS); x++) {
			val_array_ptr(bi->chunks)[x] =
			  alloc_int(val_int(val_array_ptr(CHUNKS)[x]));
		}
	}
	else {
		bi->t = 0;
		SET_CHUNK(bi,0,0);
	}

	value v = alloc_abstract(k_biginteger, bi);
	val_gc(v, destroy_biginteger);
	return v;
}

static value bi_zero(value DB) {
	value chunks = alloc_array(1);
	val_array_ptr(chunks)[0] = alloc_int(0);
	return bi_create(DB, alloc_int(1), alloc_int(0), chunks);
}

static value bi_one(value DB) {
	value chunks = alloc_array(1);
	val_array_ptr(chunks)[0] = alloc_int(1);
	return bi_create(DB, alloc_int(1), alloc_int(0), chunks);
}

/**
	Change bigInteger structure to serialized neko array.
	@return array [t,sign,[chunks...]]
**/
static value bi_to_array(value BI) {
	val_check_kind(BI, k_biginteger);
	bigInteger *a = val_biginteger(BI);
	int x = 2;
	x += (int)val_array_size(a->chunks);
	value rv = alloc_array(x);
	val_array_ptr(rv)[0] = alloc_int(a->t);
	val_array_ptr(rv)[1] = alloc_int(a->sign);
	for(x=0;x<(int)val_array_size(a->chunks);x++) {
		val_array_ptr(rv)[2+x] =
				alloc_int(val_int(
					val_array_ptr(a->chunks)[x]
				));
	}
	return rv;
}

static value bi_am3(value A, value W, value args) {
	PRINT("bi_am3\n");
	val_check_kind(A, k_biginteger);
	val_check_kind(W, k_biginteger);
	val_check(args, array);
	if(val_array_size(args) != 5)
		return NULL;
	int res = am3(
		val_biginteger(A),
		val_int(val_array_ptr(args)[0]),
		val_int(val_array_ptr(args)[1]),
		val_biginteger(W),
		val_int(val_array_ptr(args)[2]),
		val_int(val_array_ptr(args)[3]),
		val_int(val_array_ptr(args)[4]));

	bigInteger *w = val_biginteger(W);
	return alloc_int(res);
}

/**
	q = (int)A/B, r = A%B
	@param A BigInteger
	@param B
	@return Array [Q: BigInteger, R: BigInteger]
**/
static value bi_divide(value A, value M) {
	PRINT("bi_divide\n");
	bigInteger *a = val_biginteger(A);
	bigInteger *m = val_biginteger(M);
	bigInteger *t;

	bi_settings *bis = bi_get_settings(a->DB);
	int DB = bis->DB;
	value VDB = alloc_int(DB);
	int DM = bis->DM;
	int F1 = bis->F1;
	int F2 = bis->F2;
	double FV = bis->FV;
	free(bis);
	int qd;
	int cv;
	int x;
	value rv = alloc_array(2);

	value PM = bi_abs(M); bigInteger *pm = val_biginteger(PM);
	if(pm->t <= 0) return val_null;
	value PT = bi_abs(A); bigInteger *pt = val_biginteger(PT);
	if(pt->t < pm->t) {
		val_array_ptr(rv)[0] = bi_zero(VDB);
		val_array_ptr(rv)[1] = bi_clone(A);
		return rv;
	}
	int ts = a->sign;
	int ms = m->sign;
	int nsh = DB - bi_nbits(val_int(val_array_ptr(pm->chunks)[pm->t-1]));

	value R = bi_zero(VDB);
	value Y = bi_zero(VDB);
	value NSH = alloc_int(nsh);
	if(nsh > 0) {
		bi_shl_to(PT, NSH, R);
		bi_shl_to(PM, NSH, Y);
	}
	else {
		bi_copy_to(PT, R);
		bi_copy_to(PM, Y);
	}
	bigInteger *r = val_biginteger(R);
	bigInteger *y = val_biginteger(Y);

	int ys = y->t;
	int y0 = GET_CHUNK(y,ys-1);
	if(y0 == 0) return val_true;
	double yt = (double) y0;
	yt *= (double)(1<<F1);
	yt += ((ys>1)?
				(double)(val_int(val_array_ptr(y->chunks)[ys-2])>>F2)
				:0.0
			);

	double d1 = FV/yt;
	double d2 = (1<<F1)/yt;
	double e = (1<<F2);
	int i = r->t;
	int j = i-ys;

	value T = bi_dl_shift(Y, alloc_int(j)); // Q in return val
	NEW_PTR(t, T);
	if(bi_compare(R, T) >= 0) {
		//r.chunks[r.t++] = 1;
		SET_CHUNK(r, r->t, 1);
		r->t++;
		BI_REALLOC(r, r->t);
		bi_subtract_to(R,T,R); //r.subTo(t,r);
	}

	value ONE = bi_one(VDB);
	DESTROY(T); T = bi_dl_shift(ONE, alloc_int(ys)); NEW_PTR(t,T);

	// t.subTo(y,y);
	//Y = bi_subtract(T,Y); NEW_PTR(y,Y);
	bi_subtract_to(T,Y,Y);

	while(y->t < ys) {
		// y.chunks[y.t++] = 0;
		SET_CHUNK(y, y->t, 0);
		y->t++;
		BI_REALLOC(y, y->t);
	}
	while(--j >= 0) {
		--i;
		qd = (GET_CHUNK(r,i)==y0) ?
			DM :
			floor(GET_CHUNK(r,i)*d1+(GET_CHUNK(r,i-1)+e)*d2);

		cv = GET_CHUNK(r, i);
		x = am3(y,0,qd,r,j,0,ys);
		SET_CHUNK(r, i, cv + x);
		if(GET_CHUNK(r, i) < qd) {
			//y.dlShiftTo(j,t);
			DESTROY(T); T = bi_dl_shift(Y, alloc_int(j)); NEW_PTR(t,T);
			//r.subTo(t,r);
			//R = bi_subtract(R, T); NEW_PTR(r,R);
			bi_subtract_to(R,T,R);
			while(GET_CHUNK(r, i) < --qd) {
				bi_subtract_to(R, T, R);
			}
		}
	}

	//if(q != NULL) {
	//		r.drShiftTo(ys,q);
	//		if(ts != ms) ZERO.subTo(q,q);
	//}
	value Q = bi_dr_shift(R, alloc_int(ys));
	value ZERO = bi_zero(VDB);
	if(ts != ms) {
		bi_subtract_to(ZERO,Q,Q);
	}

	r->t = ys;
	bip_clamp(r, DM);
	if(nsh > 0) {
		//r.rShiftTo(nsh,r);	// Denormalize remainder
		bi_shr_to(R,NSH,R);
	}
	if(ts < 0) {
		//ZERO.subTo(r,r);
		bi_subtract_to(ZERO, R, R);
	}
	val_array_ptr(rv)[0] = Q;
	val_array_ptr(rv)[1] = R;
	return rv;
}

static value bi_subtract_to(value A, value B, value R) {
	PRINT("bi_subtract_to\n");
	bigInteger *a = val_biginteger(A);
	bigInteger *b = val_biginteger(B);
	bigInteger *r = val_biginteger(R);

	bi_settings *bis = bi_get_settings(a->DB);
	int DB = bis->DB;
	value VDB = alloc_int(DB);
	int DV = bis->DV;
	int DM = bis->DM;
	int F1 = bis->F1;
	int F2 = bis->F2;
	double FV = bis->FV;
	free(bis);


	int i = 0;
	int c = 0;
	int m = MIN(a->t,b->t);
	int va, vb;

	bip_realloc_chunks(r, MAX(a->t,b->t) + 1);

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
	return val_true;
}

/**
	A:BigInteger - B:BigInteger -> BigInteger
**/
static value bi_subtract(value A, value B) {
	bigInteger *a = val_biginteger(A);
	value vr = bi_zero(alloc_int(a->DB));
	bi_subtract_to(A, B, vr);
	return vr;
}


/**
	r = this << n*DB
	@param A BigInteger
	@param n left shift count
	@return BigInteger result
**/
static value bi_dl_shift(value A, value N) {
	PRINT("bi_dl_shift\n");
	bigInteger *a = val_biginteger(A);
	int n = val_int(N);
	ASSERT(n >= 0);
	value VDB = alloc_int(a->DB);
	value R = bi_zero(VDB);
	bigInteger *r = val_biginteger(R);
	bi_settings *bis = bi_get_settings(a->DB);

	int i = a->t-1;
	//BI_REALLOC(r, i+n);
	bip_realloc_chunks(r, i+n);
	while(i >= 0) {
		SET_CHUNK(r,i+n, GET_CHUNK(a,i));
		//val_array_ptr(r->chunks)[i+n] = val_array_ptr(a->chunks)[i];
		i--;
	}
	i = n-1;
	while(i >= 0) {
		SET_CHUNK(r,i,0);
		//val_array_ptr(r->chunks)[i] = 0;
		i--;
	}
	r->t = a->t+n;
	r->sign = a->sign;
	free(bis);
	return R;
}


/**
	r = this >> n*DB
	@param A BigInteger
	@param n left shift count
	@return BigInteger result
**/
static value bi_dr_shift(value A, value N) {
	bigInteger *a = val_biginteger(A);
	int n = val_int(N);
	value VDB = alloc_int(a->DB);
	value R = bi_zero(VDB);
	bigInteger *r = val_biginteger(R);
	bi_settings *bis = bi_get_settings(a->DB);

	int i = n;
	bip_alloc_chunks(r, a->t);
	while(i < a->t) {
		val_array_ptr(r->chunks)[i-n] = val_array_ptr(a->chunks)[i];
		i++;
	}
	r->t = MAX(a->t-n,0);
	r->sign = a->sign;
	free(bis);
	return R;
}

/**
	return + if a > b, - if a < b, 0 if equal
**/
static value bi_compare(value A, value B) {
	bigInteger *a = val_biginteger(A);
	bigInteger *b = val_biginteger(B);
	int r = a->sign - b->sign;
	if(r != 0) return alloc_int(r);
	int i = a->t;
	r = i - b->t;
	if(r != 0) return alloc_int(r);
	while(--i >= 0) {
		r=val_array_ptr(a->chunks)[i] - val_array_ptr(b->chunks)[i];
		if(r != 0) return alloc_int(r);
	}
	return alloc_int(0);
}

/**
	abs(a)
	@param A BigInteger
	@return BigInteger
**/
static value bi_abs(value A) {
	bigInteger *a = val_biginteger(A);
	return (a->sign<0)?bi_negate(A):A;
}

/**
	-a (negate)
	@param A BigInteger
	@return BigInteger
**/
static value bi_negate(value A) {
	bigInteger *a = val_biginteger(A);
	value ZERO = bi_zero(alloc_int(a->DB));
	return bi_subtract(ZERO, A);
}

/**
	Clone a BI
	@param A BigInteger
	@return BigInteger
**/
static value bi_clone(value A) {
	bigInteger *a = val_biginteger(A);
	value RV = bi_zero(alloc_int(a->DB));
	bi_copy_to(A,RV);
	return RV;
}

/**
	copy src A to dst B
	@param A BigInteger src
	@param A BigInteger dst
	@return true
**/
static value bi_copy_to(value A, value B) {
	bigInteger *a = val_biginteger(A);
	bigInteger *b = val_biginteger(B);
	int x;

	BI_CLEAR(b);
	b->DB = a->DB;
	b->t = a->t;
	b->sign = a->sign;
	BI_REALLOC(b,b->t);
	for(x = 0; x<b->t; x++) {
		SET_CHUNK(b,x,GET_CHUNK(a,x));
	}
	return val_true;
}

static value bi_shl(value A, value N) {
	bigInteger *a = val_biginteger(A);
	int n = val_int(N);
	value R = bi_zero(alloc_int(a->DB));
	if(n < 0) bi_shr_to(A,alloc_int(-n),R);
	else bi_shl_to(A,N,R);
	return R;
}


static value bi_shr(value A, value N) {
	bigInteger *a = val_biginteger(A);
	int n = val_int(N);
	value R = bi_zero(alloc_int(a->DB));
	if(n < 0) bi_shl_to(A,alloc_int(-n),R);
	else bi_shr_to(A,N,R);
	return R;
}

static value bi_shl_to(value A, value N, value R) {
	PRINT("bi_shl_to\n");
	val_check_kind(A, k_biginteger);
	val_check_kind(R, k_biginteger);
	bigInteger *a = val_biginteger(A);
	bigInteger *r = val_biginteger(R);
	int n = val_int(N);
	int DB = a->DB;
	int DM = ((1<<DB)-1);
	ASSERT(DB == 28);
	ASSERT(a != NULL);
	ASSERT(r != NULL);

	int bs = n%DB; // 1
	int cbs = DB-bs; // 27
	int bm = (1<<cbs)-1; // 7ffffff
	int ds = floor(n/DB); // 0
	int c = (a->sign<<bs)&DM; // 0
	int i;
	int cv;

	for(i = a->t-1; i >= 0; --i) {
		// r.chunks[i+ds+1] = (chunks[i]>>cbs)|c;
		cv = (GET_CHUNK(a,i)>>cbs)|c;
		SET_CHUNK(r,(i+ds+1),cv);
		// c = (chunks[i]&bm)<<bs;
		c = GET_CHUNK(a, i);
		c &= bm;
		c <<= bs;
	}
	for(i = ds-1; i >= 0; --i) SET_CHUNK(r,i,0);
	SET_CHUNK(r,ds,c);
	r->t = a->t + ds + 1;
	r->sign = a->sign;
	BI_REALLOC(r,r->t);
	bip_clamp(r,DB);
	return val_true;
}

static value bi_shr_to(value A, value N, value R) {
	bigInteger *a = val_biginteger(A);
	bigInteger *r = val_biginteger(R);
	int DB = a->DB;
	int n = val_int(N);
	int ds = floor(n/DB);

	r->sign = a->sign;
	if(ds >= a->t) { r->t = 0; return val_true; }
	int bs = n%DB;
	int cbs = DB-bs;
	int bm = (1<<bs)-1;
	int i;
	int cv;
	int cv2;

	cv = GET_CHUNK(a,ds) >> bs;
	SET_CHUNK(r,0,cv);
	for(i = ds+1; i < a->t; ++i) {
		//r.chunks[i-ds-1] |= (chunks[i]&bm)<<cbs;
		cv = GET_CHUNK(r, i-ds-1);
		cv2 = GET_CHUNK(a,i);
		cv |= (cv2 & bm)<<cbs;
		assert(cv < (1<<DB));
		SET_CHUNK(r, i-ds-1, cv);

		//r.chunks[i-ds] = chunks[i]>>bs;
		cv = GET_CHUNK(a,i);
		cv >>= bs;
		SET_CHUNK(r, i-ds, cv);
	}
	if(bs > 0) {
		//r.chunks[t-ds-1] |= (sign&bm)<<cbs;
		cv = GET_CHUNK(r, a->t-ds-1);
		cv |= (a->sign&bm)<<cbs;
		SET_CHUNK(r, a->t-ds-1, cv);
	}
	r->t = a->t-ds;
	bip_clamp(r,DB);
	return val_true;
}

DEFINE_PRIM(bi_free,1);
DEFINE_PRIM(bi_create,4);
DEFINE_PRIM(bi_zero,1);
DEFINE_PRIM(bi_one,1);
DEFINE_PRIM(bi_to_array,1);
DEFINE_PRIM(bi_am3,3);
DEFINE_PRIM(bi_divide,2);
DEFINE_PRIM(bi_subtract,2);
DEFINE_PRIM(bi_subtract_to,3);
DEFINE_PRIM(bi_dl_shift, 2);
DEFINE_PRIM(bi_dr_shift, 2);
DEFINE_PRIM(bi_compare, 2);
DEFINE_PRIM(bi_abs,1);
DEFINE_PRIM(bi_negate,1);
DEFINE_PRIM(bi_clone,1);
DEFINE_PRIM(bi_copy_to,2);
DEFINE_PRIM(bi_shl,2);
DEFINE_PRIM(bi_shr,2);
DEFINE_PRIM(bi_shl_to,3);
DEFINE_PRIM(bi_shr_to,3);


#endif
