/**
TEA implementation
Released into the public domain by David Wheeler and Roger Needham
This version is the block corrected or 'xxtea'
**/
#include <assert.h>
#include <stdlib.h>
#include <math.h>
#include <arpa/inet.h>
#include <string.h>
#include <sys/types.h>

#include "tea.h"





#ifdef NEKO
#       include <neko/neko.h>

#define E_NO_MEM() val_throw(alloc_string("out of memory"))
#define THROW(x) val_throw(alloc_string(x))

DEFINE_KIND(k_xxteakey);

#define val_xxteakey(o)	(u_int32_t *)val_data(o)

static void destroy_key(value nekoKey) {
	u_int32_t *key;
	if(!val_is_kind(nekoKey, k_xxteakey))
		return;
	key = val_xxteakey(nekoKey);
	memset(key, 0, 4 * sizeof(u_int32_t));
	free(key);
	val_kind(nekoKey) = NULL;
}

static value xxtea_create_key(value Int32Array) {
	u_int32_t* k;
	int x;

	if( !val_is_array(Int32Array) )
		THROW("key is not array");
	if( val_array_size(Int32Array) != 4)
		THROW("key must be 16 bytes");
	k = (u_int32_t*)malloc(val_array_size(Int32Array) * sizeof(u_int32_t));
	for(x = 0; x<val_array_size(Int32Array); x++) {
		value i = val_array_ptr(Int32Array)[x];
		if( !val_is_int32(i) )
			THROW("not int32");
		k[x] = val_int32(i);
	}
	value v = alloc_abstract(k_xxteakey, k);
	val_gc(v, destroy_key);
	return v;
}
DEFINE_PRIM(xxtea_create_key,1);

#define W_NOT_ARRAY 1
#define W_COUNT_MISMATCH 2
#define W_NOT_INT32 3
#define W_NO_MEM 4
#define W_DATA_LEN 5

static int xxtea_make_array(value Words, value Count, u_int32_t** v) {
	u_int32_t x;
	u_int32_t n;
	if(! val_is_array(Words))
		return W_NOT_ARRAY;
		//THROW("xxtea_encrypt_block: v is not array");
	n = val_array_size(Words);
	if( n != val_int(Count))
		return W_COUNT_MISMATCH;
	if( n < 2 )
		return W_DATA_LEN;
	if(v == NULL)
		return W_NO_MEM;

	u_int32_t *mem = (u_int32_t*)malloc(n * sizeof(u_int32_t));
	if(mem == NULL)
		return W_NO_MEM;
	for(x=0; x<n; x++) {
		value i = val_array_ptr(Words)[x];
		if( !val_is_int32(i) ) {
			free(mem);
			return W_NOT_INT32;
		}
		mem[x] = val_int32(i);
	}
	*v = mem;
	return 0;
}

/**
*  Block encrypt function
*  @param Words: LE packed plaintext
*  @param Count: length of Words array
*  @param Key: LE packed key
*  @return LE packed string.
*/
static value xxtea_encrypt_block(value Words, value Count, value Key)
{
	u_int32_t* v;
	u_int32_t  n;
	u_int32_t* k;
	u_int32_t  x;
	val_check(Count, int);
	val_check_kind(Key, k_xxteakey);

	//v is the n word data vector, k is the 4 word key,
	//n is # of words, negative for decoding
	n = val_array_size(Words);
	if(n == 0)
		return alloc_string("");
	k = val_xxteakey(Key);
	x = xxtea_make_array( Words, Count, &v);
	if(x) {
		switch(x) {
		case W_NOT_ARRAY: THROW("not array"); break;
		case W_COUNT_MISMATCH: THROW("array count mismatch"); break;
		case W_NOT_INT32: THROW("not int32"); break;
		case W_DATA_LEN: THROW("array count < 2"); break;
		case W_NO_MEM: E_NO_MEM(); break;
		default: THROW("unhandled error"); break;
		}
	}
	xxtea(v, n, k);
	value rv = copy_string((const char *)v, n * sizeof(u_int32_t));
	free(v);
	return rv;
}
DEFINE_PRIM(xxtea_encrypt_block,3);

/**
*  Block decrypt function
*  @param Words: LE packed ciphertext
*  @param Count: length of Words array
*  @param Key: LE packed key
*  @return LE packed string.
*/
static value xxtea_decrypt_block(value Words, value Count, value Key)
{
	u_int32_t* v;
	u_int32_t  n;
	u_int32_t* k;
	u_int32_t  x;
	val_check(Count, int);
	val_check_kind(Key, k_xxteakey);

	//v is the n word data vector, k is the 4 word key,
	//n is # of words, negative for decoding
	n = val_array_size(Words);
	if(n == 0)
		return alloc_string("");
	k = val_xxteakey(Key);
	x = xxtea_make_array( Words, Count, &v);
	if(x) {
		switch(x) {
		case W_NOT_ARRAY: THROW("not array"); break;
		case W_COUNT_MISMATCH: THROW("array count mismatch"); break;
		case W_NOT_INT32: THROW("not int32"); break;
		case W_DATA_LEN: THROW("array count < 2"); break;
		case W_NO_MEM: E_NO_MEM(); break;
		default: THROW("unhandled error"); break;
		}
	}
	xxtea(v, 0-n, k);
	value rv = copy_string((const char *)v, n * sizeof(u_int32_t));
	free(v);
	return rv;
}
DEFINE_PRIM(xxtea_decrypt_block,3);


#elif defined(LUA)
#       include "lua.h"
#       include "lauxlib.h"
#error "not complete"
#endif

#define blk0(i) block->l[i]
#define blk0le(i) (block->l[i] = (rol(block->l[i],24)&0xFF00FF00) \
    |(rol(block->l[i],8)&0x00FF00FF))

void tea_copy(const BYTE* orig, BYTE *dest, u_int32_t len) {
    union {
        u_int32_t l;
        char c[4];
    } u;
    u.l = 1;
    //return (u.c[sizeof (long) - 1] == 1);
}

/*
v is the n word data vector,
k is the 4 word key.
n is negative for decoding,
if n is zero result is 1 and no coding or decoding takes place,
otherwise the result is zero.
assumes 32 bit long and same endian coding and decoding
*/
//#define MX (z>>5^y<<2) + (y>>3^z<<4)^(sum^y) + (k[p&3^e]^z);
#define MX (((z>>5)^(y<<2)) + ((y>>3)^(z<<4))) ^ ((sum^y) + (k[(p&3)^e]^z));

int32_t xxtea(u_int32_t* v, u_int32_t n, u_int32_t* k) {
	u_int32_t z, y=v[0], sum=0, e, DELTA=0x9e3779b9;
	int32_t p, q ;

	if((int32_t)n > 1) {
		z=v[n-1];
		q = 6+52/n ;
 		while (q-- > 0) {
			sum += DELTA;
			e = sum >> 2&3 ;
			for (p=0; p<n-1; p++) {
				y = v[p+1];
				z = v[p] += MX;
			}
			y = v[0];
			z = v[n-1] += MX;
		}
		return 0;
	}
	else if((int32_t)n < -1) {
		n = -n ;
		q = 6+52/n ;
		sum = q*DELTA ;
		while (sum != 0) {
			e = sum>>2 & 3;
			for (p=n-1; p>0; p--) {
				z = v[p-1];
				y = v[p] -= MX;
			}
			z = v[n-1];
			y = v[0] -= MX;
			sum -= DELTA;
		}
		return 0;
	}
	return 1;
}


/*
v gives the plain text of 2 words,
k gives the key of 4 words,
N gives the number of cycles, 32 are recommended,
if negative causes decoding, N must be the same as for coding, if zero causes no coding or decoding.
assumes 32 bit \long" and same endian coding or decoding
*/
/*
tean( int32_t * v, int32_t * k, int32_t N) {
	u_int32_t y=v[0], z=v[1], DELTA=0x9e3779b9 ;
	if (N>0) {
		// coding
		u_int32_t limit=DELTA*N, sum=0 ;
		while (sum!=limit)
			y+= (z<<4 ^ z>>5) + z ^ sum + k[sum&3],
			sum+=DELTA,
			z+= (y<<4 ^ y>>5) + y ^ sum + k[sum>>11 &3] ;
	}
	else {
		// decoding
		u_int32_t sum=DELTA*(-N) ;
		while (sum)
		z-= (y<<4 ^ y>>5) + y ^ sum + k[sum>>11 &3],
		sum-=DELTA,
		y-= (z<<4 ^ z>>5) + z ^ sum + k[sum&3] ;
	}
	v[0]=y, v[1]=z ;
	return ;
}
*/
