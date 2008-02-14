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
 * THIS SOFTWARE IS PROVIDED BY THE HAXE PROJECT CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE HAXE PROJECT CONTRIBUTORS BE LIABLE FOR
 * ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
 * DAMAGE.
 */

#include <stdlib.h>
#include <time.h>
#include <string.h>
#include <assert.h>
#include "rijndael-api-fst.h"

#define AES_ENC 1
#define AES_DEC 2
#define AES_BLOCK_SIZE 16

#ifndef NEKO
#	ifndef LUA
#		error "Define LUA or NEKO"
#	endif
#endif

#ifdef NEKO
#	include <neko/neko.h>
#elif defined(LUA)
#	include "lua.h"
#	include "lauxlib.h"
#endif

// iv can be NULL
int aes_generic(char *in, size_t in_size, char *out, size_t key_length, const char *passwd, size_t pass_len, int mode, BYTE direction, char *iv, int padded) {
	keyInstance key;
	cipherInstance cipher;
	int retval = 0;

	memToKey(&key, direction, key_length, passwd, pass_len);

	if(cipherInit(&cipher, mode, iv) != 1) {
		return 0;
	}

	if(direction == DIR_ENCRYPT) {
		// blockEncrypt takes the inputLen as number of bits
		if(padded)
			retval = padEncrypt(&cipher, &key, (BYTE *)in, in_size, (BYTE *)out);
		else
			retval = blockEncrypt(&cipher, &key, (BYTE *)in, in_size * 8, (BYTE *)out);
		if(retval < 0) return 0;
	}
	else if(direction == DIR_DECRYPT) {
		if(padded)
			retval = padDecrypt(&cipher, &key, (BYTE *)in, in_size, (BYTE *)out);
		else
			retval = blockDecrypt(&cipher, &key, (BYTE *)in, in_size * 8, (BYTE *)out);
		if(retval < 0) {
			return 0;
		}
	}

	return retval;
}

char *aes_prepare_pad_buffer(const char *message, size_t msg_len, size_t *buflen) {
	char *buf;

	if(msg_len == 0)
		return NULL;
	//*buflen = (size_t) (AES_BLOCK_SIZE * ((msg_len / AES_BLOCK_SIZE) + 1));
	*buflen = (size_t) (AES_BLOCK_SIZE * ((msg_len / AES_BLOCK_SIZE) + 2));
	//if(msg_len % AES_BLOCK_SIZE > 0)
	///	*buflen += AES_BLOCK_SIZE;

	buf = (char *)malloc(*buflen);
	if(buf == NULL)
		return NULL;

	//memset(buf + msg_len, 0, *buflen - msg_len);
	memset(buf, 0, *buflen);
	return buf;
}

// returns a char pointer that must be freed by the caller.
// buflen is a pointer to a returned final buffer length
char *aes_prepare_encrypt_buffer(const char *message, size_t msg_len, size_t *buflen) {
	char *buf;
	*buflen = 0;
	int r1, r2, x;

	srand((unsigned int)time(NULL));
	// this rand is subject to a rounding error that could overflow
	// 253 to 254. Could use 1+(int) (nMax*rand()/(RAND_MAX+nMin)) when nMin >=1
	r1 = rand()/(int)(((unsigned)RAND_MAX + 1) / 253);
	r2 = rand()/(int)(((unsigned)RAND_MAX + 1) / 253);
	*buflen = (size_t) (AES_BLOCK_SIZE + (AES_BLOCK_SIZE * (msg_len / AES_BLOCK_SIZE)));
	if(msg_len % AES_BLOCK_SIZE)
		*buflen += AES_BLOCK_SIZE;

	assert(*buflen >= msg_len + AES_BLOCK_SIZE);

	buf = (char *)malloc(*buflen);
	if(buf == NULL) return NULL;

	buf[0] = (char)(r1 & 0xFF);
	buf[1] = (char)(r2 & 0xFF);
	buf[2] = (char)((msg_len >> 24) & 0xFF);
	buf[3] = (char)((msg_len >> 16) & 0xFF);
	buf[4] = (char)((msg_len >> 8) & 0xFF);
	buf[5] = (char)(msg_len & 0xFF);
	buf[6] = (char)(r1 & 0xFF);
	buf[7] = (char)(r2 & 0xFF);
	buf[8] = rand()/(int)(((unsigned)RAND_MAX + 1) / 253);
	buf[9] = rand()/(int)(((unsigned)RAND_MAX + 1) / 253);
	buf[10] = rand()/(int)(((unsigned)RAND_MAX + 1) / 253);
	buf[11] = rand()/(int)(((unsigned)RAND_MAX + 1) / 253);
	buf[12] = rand()/(int)(((unsigned)RAND_MAX + 1) / 253);
	buf[13] = rand()/(int)(((unsigned)RAND_MAX + 1) / 253);
	buf[14] = rand()/(int)(((unsigned)RAND_MAX + 1) / 253);
	buf[15] = rand()/(int)(((unsigned)RAND_MAX + 1) / 253);

	for(x=0; x< 16; x++) {
		buf[*buflen-AES_BLOCK_SIZE+x] = rand()/(int)(((unsigned)RAND_MAX + 1) / 253);
	}
	memcpy(buf+AES_BLOCK_SIZE, message, msg_len);
	return buf;
}

char *aes_decode_decrypt_buffer(char *buf, size_t buf_len, size_t *rec_len) {
	*rec_len = 0;
	if(buf == NULL || buf_len < AES_BLOCK_SIZE)
		return NULL;

	//printf("%02X %02x\n",buf[0], buf[1]);
	if(buf[0] != buf[6] || buf[1] != buf[7])
		return NULL;


	*rec_len = ( ((size_t)buf[2]) << 24 & 0xff000000);
	*rec_len|= ( ((size_t)buf[3]) << 16 & 0x00ff0000);
	*rec_len|= ( ((size_t)buf[4]) << 8  & 0x0000ff00);
	*rec_len|= ( ((size_t)buf[5]) & 0x000000ff);


	//printf("Record length returned is %u  from %02X %02X %02X %02X\n", *rec_len, buf[2],buf[3],buf[4],buf[5]);
	if(*rec_len > buf_len - AES_BLOCK_SIZE) {
		*rec_len = 0;
		return NULL;
	}

	return(buf + AES_BLOCK_SIZE);
}

#ifdef NEKO

DEFINE_KIND(k_aeskey);
DEFINE_KIND(k_aescipher);

#define E_NO_MEM() val_throw(alloc_string("out of memory"))
#define THROW(x) val_throw(alloc_string(x))

#define val_aeskey(o)	(keyInstance *)val_data(o)

static void destroy_key(value nekoKey) {
	keyInstance *key;
	if(!val_is_kind(nekoKey, k_aeskey))
		return;
	key = val_aeskey(nekoKey);
	memset(key, 0, sizeof(keyInstance));
	free(key);
	val_kind(nekoKey) = NULL;
}

static value aes_create_key(value forEncrypt, value keyLen, value keyMaterial) {
	keyInstance *key;
	const char *key_material;
	int key_length = 128;
	value v;
	BYTE direction;

	val_check(forEncrypt, bool);
	val_check(keyLen, int);
	val_check(keyMaterial, string);

	if( val_bool(forEncrypt) ) {
		direction = DIR_ENCRYPT;
	}
	else {
		direction = DIR_DECRYPT;
	}

	key = (keyInstance *)malloc(sizeof(keyInstance));
	if(key == NULL)
		E_NO_MEM();

	if(!val_is_null(keyLen)) {
		key_length = val_int(keyLen);
	}
	if(key_length != 128 && key_length != 192 && key_length != 256)
		THROW("Invalid key length");

	if(val_strlen(keyMaterial) < 1)
		THROW("No key material");

	memToKey(key, direction, key_length, val_string(keyMaterial), val_strlen(keyMaterial));

	v = alloc_abstract(k_aeskey, key);
	val_gc(v, destroy_key);
	return v;
}
DEFINE_PRIM(aes_create_key,3);

static value aes_encrypt_block(value nekoKey, value sBlock) {
	keyInstance *key;
	BYTE outBuffer[AES_BLOCK_SIZE];

	val_check_kind(nekoKey, k_aeskey);
	val_check(sBlock, string);
	key = val_aeskey(nekoKey);

	if(val_strlen(sBlock) != AES_BLOCK_SIZE)
		THROW("block size incorrect");
	if(key->direction != DIR_ENCRYPT)
		THROW("not an encryption key");
	rijndaelEncrypt(key->rk, key->Nr, (BYTE *)val_string(sBlock), outBuffer);
	return copy_string(outBuffer, AES_BLOCK_SIZE);
}
DEFINE_PRIM(aes_encrypt_block, 2);

static value aes_decrypt_block(value nekoKey, value sBlock) {
	keyInstance *key;
	BYTE outBuffer[AES_BLOCK_SIZE];

	val_check_kind(nekoKey, k_aeskey);
	val_check(sBlock, string);
	key = val_aeskey(nekoKey);

	if(val_strlen(sBlock) != AES_BLOCK_SIZE)
		THROW("block size incorrect");
	if(key->direction != DIR_DECRYPT)
		THROW("not a decryption key");
	rijndaelDecrypt(key->rk, key->Nr, (BYTE *)val_string(sBlock), outBuffer);
	return copy_string(outBuffer, AES_BLOCK_SIZE);
}
DEFINE_PRIM(aes_decrypt_block, 2);

#endif

/**
*  Encrypt function
*  @param password: arbitrary binary string.
*  @param message: arbitrary binary string.
*  @param key_length: int == 128 || 192 || 256
*  @return  A encrypted buffer in an arbitrary length string.
*  MODE_ECB MODE_CBC MODE_CFB1
*/
#ifdef NEKO


static value naes_encrypt(value pass, value msg, value key_len, int mode) {
	size_t msg_length;
	size_t pwd_length;
	size_t buf_length = 0;
	char *buf = NULL;
	char *out_buf = NULL;
	int key_length = 128;
	const char *errstr;

	val_check(pass, string);
	val_check(msg, string);
	if(!val_is_null(key_len))
			val_check(key_len, int);
	pwd_length = val_strlen(pass);
	msg_length = val_strlen(msg);
	const char *password= val_string(pass);
	const char *message = val_string(msg);

	if(pwd_length == 0)
		val_throw(alloc_string("Key is null"));
	if(msg_length == 0)
		val_throw(alloc_string("Message is null"));
	if(!val_is_null(key_len)) {
		key_length = val_int(key_len);
		if(key_length != 128 && key_length != 192 && key_length != 256)
			val_throw(alloc_string("Invalid key length"));
	}
	//buf = aes_prepare_encrypt_buffer(message, msg_length, &buf_length);
	buf = aes_prepare_pad_buffer(message, msg_length, &buf_length);
	if( buf == NULL || buf_length == 0 ) {
		if(buf) free(buf);
		return val_null;
	}
	assert(buf_length % AES_BLOCK_SIZE == 0);
	memcpy(buf, message, msg_length);

	out_buf = (char *)malloc(buf_length);
	if(out_buf == NULL) {
		if(buf) free(buf);
		val_throw(alloc_string("out of memory"));
	}

//printf("7 buf_length %d (likely 16 bytes larger than required)\n",buf_length);
	buf_length = aes_generic(buf, msg_length, out_buf, key_length, password, pwd_length, mode, DIR_ENCRYPT, NULL,1);
	assert(buf_length % AES_BLOCK_SIZE == 0);
//printf("8 buf_length %d\n",buf_length);
	if(buf_length <= 0) {
		val_throw(alloc_string("encryption failure"));
	}
	if(buf) free(buf);
	//if(out_buf) free(out_buf);
	value rv = copy_string((const char*)out_buf, buf_length); // frees out_buf
	return rv;
}
#endif

#ifdef LUA
static int laes_encrypt (lua_State *L, int mode) {
	size_t msg_length;
	size_t pwd_length;
	size_t buf_length = 0;
	char *buf = NULL;
	char *out_buf = NULL;
	int key_length = 128;
	const char *errstr;

	const char *password= luaL_checklstring(L, 1, &pwd_length);
	const char *message = luaL_checklstring(L, 2, &msg_length);

	if(pwd_length == 0) {
		errstr = "Key is null";
		lua_pushnil(L);
		lua_pushlstring(L, errstr, strlen(errstr));
		return 2;
	}
	if(msg_length == 0) {
		errstr = "Message is null";
		lua_pushnil(L);
		lua_pushlstring(L, errstr, strlen(errstr));
		return 2;
	}
	if(!lua_isnil(L, 3)) {
		key_length = (int)lua_tonumber(L, 3);
		if(key_length != 128 && key_length != 192 && key_length != 256) {
			lua_pushnil(L);
			errstr = "Key length invalid";
			lua_pushlstring(L, errstr, strlen(errstr));
			return 2;
		}
	}
	//buf = aes_prepare_encrypt_buffer(message, msg_length, &buf_length);
	buf = aes_prepare_pad_buffer(message, msg_length, &buf_length);
	if( buf == NULL || buf_length == 0 ) {
		if(buf) free(buf);
		lua_pushnil(L);
		return 1;
	}
	assert(buf_length % AES_BLOCK_SIZE == 0);
	memcpy(buf, message, msg_length);
//printf("7 buf_length %d\n",buf_length);

	out_buf = (char *)malloc(buf_length);
	if(out_buf == NULL) {
		if(buf) free(buf);
		lua_pushnil(L);
		errstr = "Out of memory";
		lua_pushlstring(L, errstr, strlen(errstr));
		return 2;
	}

	buf_length = aes_generic(buf, msg_length, out_buf, key_length, password, pwd_length, mode, DIR_ENCRYPT, NULL,1);
	if(buf_length <= 0) {
		errstr = "Encryption failure";
		lua_pushnil(L);
		lua_pushlstring(L, errstr, strlen(errstr));
	}
	else {
		lua_pushlstring(L, (const char*)out_buf, buf_length);
		lua_pushnil(L);
	}
	if(buf) free(buf);
	if(out_buf) free(out_buf);
	return 2;
}
#endif


#ifdef NEKO
static value naes_decrypt(value pass, value msg, value key_len, int mode) {
	size_t msg_length;
	size_t pwd_length;
	size_t rec_length;
	char *out_buf = NULL;
	int key_length = 128;
	const char *errstr;

	value rv;
	val_check(pass, string);
	val_check(msg, string);
	if(!val_is_null(key_len))
			val_check(key_len, int);
	pwd_length = val_strlen(pass);
	msg_length = val_strlen(msg);
	const char *password= val_string(pass);
	const char *message = val_string(msg);

	if(pwd_length == 0)
		val_throw(alloc_string("Key is null"));
	if(msg_length == 0)
		val_throw(alloc_string("Message is null"));
	if(msg_length % AES_BLOCK_SIZE != 0)
		val_throw(alloc_string("Buffer is not a multiple of the aes block size"));
	if(!val_is_null(key_len)) {
		key_length = val_int(key_len);
		if(key_length != 128 && key_length != 192 && key_length != 256)
			val_throw(alloc_string("Invalid key length"));
	}

	out_buf = (char *)malloc(msg_length);
	if(out_buf == NULL) {
		val_throw(alloc_string("Out of memory"));
	}
	memcpy(out_buf, message, msg_length);

	// now decrypt it
	rec_length = aes_generic(out_buf, msg_length, out_buf, key_length, password, pwd_length, mode, DIR_DECRYPT, NULL,1);
	if(rec_length <= 0) {
		if(out_buf) free(out_buf);
		val_throw(alloc_string("Decryption failure"));
	}
	rv = copy_string(out_buf, rec_length);
	if(out_buf) free(out_buf);
	return rv;
}
#endif

#ifdef LUA
static int laes_decrypt(lua_State *L, int mode) {
	size_t msg_length;
	size_t pwd_length;
	size_t rec_length;
	char *out_buf = NULL;
	int key_length = 128;
	const char *errstr;

	const char *password= luaL_checklstring(L, 1, &pwd_length);
	const char *message = luaL_checklstring(L, 2, &msg_length);
	if(pwd_length == 0) {
		errstr = "Key is null";
		lua_pushnil(L);
		lua_pushlstring(L, errstr, strlen(errstr));
		return 2;
	}
	if(msg_length == 0) {
		errstr = "Message is null";
		lua_pushnil(L);
		lua_pushlstring(L, errstr, strlen(errstr));
		return 2;
	}
	if(msg_length % AES_BLOCK_SIZE != 0) {
		lua_pushnil(L);
		errstr = "Buffer is not a multiple of the aes block size";
		lua_pushlstring(L, errstr, strlen(errstr));
		return 2;
	}
	if(!lua_isnil(L, 3)) {
		key_length = (int)lua_tonumber(L, 3);
		if(key_length != 128 && key_length != 192 && key_length != 256) {
			lua_pushnil(L);
			errstr = "Key length invalid";
			lua_pushlstring(L, errstr, strlen(errstr));
			return 2;
		}
	}

	out_buf = (char *)malloc(msg_length);
	if(out_buf == NULL) {
		lua_pushnil(L);
		errstr = "Out of memory";
		lua_pushlstring(L, errstr, strlen(errstr));
		return 2;
	}
	memcpy(out_buf, message, msg_length);

	// now decrypt it
	rec_length = aes_generic(out_buf, msg_length, out_buf, key_length, password, pwd_length, mode, DIR_DECRYPT, NULL,1);
	if(rec_length >= 0) {
		lua_pushlstring(L, out_buf, rec_length);
		lua_pushnil(L);
	}
	else {
		errstr = "Decryption failure";
		lua_pushnil(L);
		lua_pushlstring(L, errstr, strlen(errstr));
	}
	if(out_buf) free(out_buf);
	return 2;
}
#endif

////////////////////////////// break
#ifdef OLDWAYTODOTHINGS
	if(rec_length) {
		size_t rec_len = 0;
		// this pointer does not have to be freed, the buf does
		char *text = aes_decode_decrypt_buffer(out_buf, msg_length, &rec_len);
//printf("Recovered %u bytes. %.*s\n", rec_len, rec_len, text);
#		ifdef NEKO
		rv = copy_string(text, rec_len);
#		elif defined(LUA)
		lua_pushlstring(L, text, rec_len);
		lua_pushnil(L);
#		endif
	}
#endif




///////////////////////
// Library exports   //
///////////////////////
#ifdef NEKO

static value naes_ecb_encrypt (value pass, value msg, value key_len) {
	return naes_encrypt(pass, msg, key_len, MODE_ECB);
}
static value naes_ecb_decrypt (value pass, value msg, value key_len) {
	return naes_decrypt(pass, msg, key_len, MODE_ECB);
}
static value naes_cbc_encrypt (value pass, value msg, value key_len) {
	return naes_encrypt(pass, msg, key_len, MODE_CBC);
}
static value naes_cbc_decrypt (value pass, value msg, value key_len) {
	return naes_decrypt(pass, msg, key_len, MODE_CBC);
}
DEFINE_PRIM(naes_ecb_encrypt,3);
DEFINE_PRIM(naes_ecb_decrypt,3);
DEFINE_PRIM(naes_cbc_encrypt,3);
DEFINE_PRIM(naes_cbc_decrypt,3);

#elif defined(LUA)

static int laes_ecb_encrypt (lua_State *L) {
	return laes_encrypt(L, MODE_ECB);
}

static int laes_ecb_decrypt (lua_State *L) {
	return laes_decrypt(L, MODE_ECB);
}

static int laes_cbc_encrypt (lua_State *L) {
	return laes_encrypt(L, MODE_CBC);
}

static int laes_cbc_decrypt (lua_State *L) {
	return laes_decrypt(L, MODE_CBC);
}


static struct luaL_reg aeslib[] = {
  {"ecb_encrypt", laes_ecb_encrypt},
  {"ecb_decrypt", laes_ecb_decrypt},
  {"cbc_encrypt", laes_cbc_encrypt},
  {"cbc_decrypt", laes_cbc_decrypt},
  {NULL, NULL}
};


int luaopen_aes (lua_State *L) {
  luaL_openlib(L, "aes", aeslib, 0);
  return 1;
}

#endif
