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

/*
static value ntea_encrypt (value pass, value msg) 
{
        val_check(pass, string);
        val_check(msg, string);

        pwd_length = val_strlen(pass);
        msg_length = val_strlen(msg);
        const char *password= val_string(pass);
        const char *message = val_string(msg);

	//v is the n word data vector, k is the 4 word key, 
	//n is # of words, negative for decoding
	xxtea(int32_t* v, int32_t n, int32_t* k);
}
DEFINE_PRIM(ntea_encrypt,2);
DEFINE_PRIM(ntea_decrypt,2);
*/

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

/*
	int be = be_test();
	if(be) {
	}
	else {
	}
*/
}

BYTE* tea_prepare_source_buffer(const BYTE* orig, u_int32_t len, u_int32_t *outBufLen) {
	BYTE padbytes;
	int rem;
	u_int32_t blocks;

	if(len == 0) {
		*outBufLen = 0;
		return NULL;
	}
	blocks = len/TEA_BLOCK_SIZE;
	rem = len % TEA_BLOCK_SIZE;
	padbytes = 0;

	if(rem == 0) {
		padbytes = TEA_BLOCK_SIZE;
		blocks++;
	}
	else
		padbytes = TEA_BLOCK_SIZE - rem;

	if(blocks == 0) {
		blocks = 2;
		padbytes += TEA_BLOCK_SIZE;
	}
	else if(blocks == 1) {
		blocks = 2;
	}

	if(blocks * TEA_BLOCK_SIZE < len) {
		*outBufLen = 0;
		return NULL;
	}
	assert(padbytes <= (2 * TEA_BLOCK_SIZE));
	assert(blocks >= 2);

	BYTE *buf = (BYTE *)malloc(blocks * TEA_BLOCK_SIZE);
	memset(buf, padbytes, blocks * TEA_BLOCK_SIZE);
	memcpy(buf, orig, (size_t)len);

	*outBufLen = blocks * TEA_BLOCK_SIZE;
	return buf;
}

BYTE *xxtea_encrypt(const BYTE* orig, size_t inputLen, size_t *finallen, int32_t *key) {
	BYTE *buf;
	u_int32_t outLen;

	buf = tea_prepare_source_buffer(orig, inputLen, &outLen);
	if(buf == NULL)
		return NULL;
	assert(outLen % TEA_BLOCK_SIZE == 0);

	if(xxtea((u_int32_t*)buf, outLen % TEA_BLOCK_SIZE, key)) {
		free(buf);
		*finallen = 0;
		return NULL;		
	}
	*finallen = outLen;
	return (BYTE *)buf;
}

BYTE *xxtea_decrypt(const BYTE* orig, size_t len, size_t *finallen, int32_t *key) {
	int32_t blocks = len / TEA_BLOCK_SIZE;
	if(len % TEA_BLOCK_SIZE != 0 || blocks < 2) {
		return NULL;
	}


	int32_t *buf = (int32_t *)malloc(blocks * TEA_BLOCK_SIZE);
	memset((void *)buf,0,blocks*TEA_BLOCK_SIZE);

	memcpy((BYTE *)buf, orig+TEA_BLOCK_SIZE, len - TEA_BLOCK_SIZE);
	if(xxtea(buf, 0-blocks, key)) {
		free(buf);
		*finallen = 0;
		return NULL;
	}
}


/*
btea is a block version of tean. MUST BE at least 2 words long
It will encode or decode n words as a single block where n > 1.
v is the n word data vector,
k is the 4 word key.
n is negative for decoding,
if n is zero result is 1 and no coding or decoding takes place,
otherwise the result is zero.
assumes 32 bit long and same endian coding and decoding
*/
#define MX (z>>5^y<<2) + (y>>3^z<<4)^(sum^y) + (k[p&3^e]^z);

int32_t xxtea(u_int32_t* v, u_int32_t n, u_int32_t* k) {
	u_int32_t z=v[n-1], y=v[0], sum=0, e, DELTA=0x9e3779b9;
	int32_t m, p, q ;
	int be = be_test();

	if(n > 1) {
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
	else if(n < -1) {
		n = -n ;
		q = 6+52/n ;
		sum = q*DELTA ;
		while (sum != 0) {
			e = sum>>2 & 3;
			for (p=n-1; p>0; p--) z = v[p-1], y = v[p] -= MX;
			z = v[n-1];
			y = v[0] -= MX;
			sum -= DELTA;
		}
		return 0;
	}
	return 1;
}


/*
void tea_encrypt (unsigned int32_t* v, unsigned int32_t* k) {
     u_int32_t v0=v[0], v1=v[1], sum=0, i;           // set up 
     u_int32_t delta=0x9e3779b9;                     // a key schedule constant 
     u_int32_t k0=k[0], k1=k[1], k2=k[2], k3=k[3];   // cache key 
     for (i=0; i < 32; i++) {                            // basic cycle start 
         sum += delta;
         v0 += ((v1<<4) + k0) ^ (v1 + sum) ^ ((v1>>5) + k1);
         v1 += ((v0<<4) + k2) ^ (v0 + sum) ^ ((v0>>5) + k3);   // end cycle 
     }
     v[0]=v0; v[1]=v1;
 }
 

void tea_decrypt (u_int32_t* v, u_int32_t* k) {
     u_int32_t v0=v[0], v1=v[1], sum=0xC6EF3720, i;  // set up 
     u_int32_t delta=0x9e3779b9;                     // a key schedule constant 
     u_int32_t k0=k[0], k1=k[1], k2=k[2], k3=k[3];   // cache key 
     for (i=0; i<32; i++) {                               // basic cycle start 
         v1 -= ((v0<<4) + k2) ^ (v0 + sum) ^ ((v0>>5) + k3);
         v0 -= ((v1<<4) + k0) ^ (v1 + sum) ^ ((v1>>5) + k1);
         sum -= delta;                                   // end cycle 
     }
     v[0]=v0; v[1]=v1;
 }
*/

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
