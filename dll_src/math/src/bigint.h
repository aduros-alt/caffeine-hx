#ifndef LN_BIG_INTEGER_H
#define LN_BIG_INTEGER_H

#ifndef MAX
#define MAX(a,b) ((a > b)?a:b)
#define MIN(a,b) ((a < b)?a:b)
#endif

typedef struct {
	int DB;
	int DM; // = ((1<<DB)-1);
	int DV; // = (1<<DB);
	int BI_FP; // = 52;
	double FV; // = Math.pow(2,BI_FP);
	int F1; // = BI_FP-DB;
	int F2; // = 2*DB-BI_FP;
} bi_settings;

// get settings based on bits/chunk value
bi_settings *bi_get_settings(int db);

#if NEKO

#include <neko/neko.h>

typedef struct {
	int DB; // significant bits
	int t;  // significant chunks
	int sign;
	value chunks;
} bigInteger;

// create n chunks
static void bip_alloc_chunks(bigInteger *bi, int n);
// realloc to n chunks
static void bip_realloc_chunks(bigInteger *bi, int n);
static void bip_clamp(bigInteger *a, int DM);
static void bip_clear(bigInteger *a);

// free bigInteger struct
static void destroy_biginteger( value c );

// free BI
static value bi_free(value BI);
// create BI. Chunks can be null
static value bi_create(value DB, value T, value SIGN, value CHUNKS);
// ZERO
static value bi_zero(value DB);
// ONE
static value bi_one(value DB);
// translate to neko array for import to haxe
static value bi_to_array(value BI);
static value bi_am3(value A, value W, value args);
static value bi_divide(value A, value M);
static value bi_subtract(value A, value B);
static value bi_subtract_to(value A, value B, value R);
static value bi_dl_shift(value A, value n);
static value bi_dr_shift(value A, value n);
static value bi_compare(value A, value B);
static value bi_abs(value A);
static value bi_negate(value A);
static value bi_clone(value A);
static value bi_copy_to(value A, value B);
static value bi_shl(value A, value N);
static value bi_shr(value A, value N);
static value bi_shl_to(value A, value N, value R);
static value bi_shr_to(value A, value N, value R);

#define GET_CHUNK(bi,n) 	val_int(val_array_ptr(bi->chunks)[n])
#define SET_CHUNK(bi,n,v) 	{bip_realloc_chunks(bi, n+1); \
							val_array_ptr(bi->chunks)[n] = alloc_int(v); }
#define NEW_PTR(v,BI) 		v = val_biginteger(BI)
#define BI_CLEAR(bi)		bip_clear(bi)
#define BI_REALLOC(bi,n)	bip_realloc_chunks(bi, n)
#define BI_DESTROY(BI) 		destroy_biginteger(BI)

#endif // NEKO
#endif // LN_BIG_INTEGER_H

