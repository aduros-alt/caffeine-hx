#ifndef _BN_NEKO_H
#define _BN_NEKO_H

#include <openssl/bn.h>
#ifdef TARGET_HXCPP
#	define IMPLEMENT_API
#	include <hx/CFFI.h>
#elif defined(NEKO)
#	include <neko/neko.h>
#elif defined(LUA)
#	include "lua.h"
#	include "lauxlib.h"
#endif

#ifdef NEKO
#ifndef val_array_ptr
#define val_array_ptr(v)        (&((varray*)(v))->ptr)
#endif
#endif

// Bitwise operators for bi_bitwise_to
#define BW_AND			1
#define BW_AND_NOT		2
#define BW_OR			3
#define BW_XOR			4

static void status_ignore(int i,int j,void *p);
static value bi_allocate(BIGNUM *bi);
static value bi_new();
static void destroy_biginteger( value bi );
static value bi_ZERO();
static value bi_ONE();
static value bi_copy(value TO, value FROM);
// primes
static value bi_generate_prime(value NBITS, value SAFE);
static value bi_is_prime(value A, value ITERATIONS, value DIV_TRIAL);
// math
static value bi_abs(value A);
static value bi_add_to(value A, value B, value R);
static value bi_sub_to(value A, value B, value R);
static value bi_mul_to(value A, value B, value R);
static value bi_sqr_to(value A, value R);
static value bi_div(value A, value B);
static value bi_div_rem_to(value A, value B, value DV, value REM);
static value bi_mod(value A, value B);
static value bi_mod_exp(value A, value P, value M);
static value bi_mod_inverse(value A, value M);
static value bi_pow(value A, value B);
static value bi_gcd(value A, value B);
static value bi_signum(value A);
static value bi_cmp(value A, value B);
static value bi_ucmp(value A, value B);
static value bi_is_zero(value A);
static value bi_is_one(value A);
static value bi_is_odd(value A);
// random
static value bi_rand_seed(value data);
static value bi_rand(value bits, value top, value bottom);
static value bi_pseudo_rand(value bits, value top, value bottom);
// conversion
static const char *bi_dec_string(char *v);
static value bi_to_hex(value A);
static value bi_from_hex(value s);
static value bi_to_decimal(value A);
static value bi_from_decimal(value s);
static value bi_to_bin(value A);
static value bi_from_bin(value S);
static value bi_to_mpi(value A);
static value bi_from_mpi(value S);
static value bi_from_int(value A, value I);
static value bi_to_int(value A);
// bitwise
static value bi_shl_to(value A, value N, value R);
static value bi_shr_to(value A, value N, value R);
static value bi_bitlength(value A);
static value bi_bytelength(value A);
static value bi_bits_set(value A);
static value bi_lowest_bit_set(value A);
static value bi_set_bit(value A, value N);
static value bi_clear_bit(value A, value N);
static value bi_flip_bit(value A, value N);
static value bi_bitwise_to(value A, value B, value FUNC, value R);
static value bi_not(value A);
static value bi_test_bit(value A, value N);

#endif

