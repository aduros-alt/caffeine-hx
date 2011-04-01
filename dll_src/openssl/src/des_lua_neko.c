/*
 * Copyright (c) 2011, The Caffeine-hx project contributors
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
#include <openssl/des.h>

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

#ifdef NEKO

DEFINE_KIND(k_deskey);

#define E_NO_MEM() val_throw(alloc_string("out of memory"))
#define THROW(x) val_throw(alloc_string(x))

#define val_deskey(o)		(DES_key_schedule *)val_data(o)
#define val_const_cblock(o)	(const_DES_cblock *)val_string(o)
//#define val_cblock(o)		(DES_cblock *)val_string(o)

#define DES_BLOCK_SIZE		sizeof(DES_cblock)

/**
 * Does not set the pointer to null, but erases the key schedule
 **/
static value des_destroy_key(value nekoKey) {
	DES_key_schedule *schedule;
	if(!val_is_kind(nekoKey, k_deskey))
		return;
	schedule = val_deskey(nekoKey);
	memset(schedule, 0, sizeof(DES_key_schedule));
	return VAL_NULL;
}
DEFINE_PRIM(des_destroy_key,1);

/**
 * Garbage collects key
 **/
static void des_gc_key(value nekoKey) {
	DES_key_schedule *schedule;
	if(!val_is_kind(nekoKey, k_deskey))
		return;
	des_destroy_key(nekoKey);
	schedule = val_deskey(nekoKey);
	free(schedule);
	val_kind(nekoKey) = NULL;
}
// no DEFINE_PRIM, this is a GC function


static value des_create_key(value keyMaterial) {
	DES_key_schedule *schedule;
	const DES_cblock *key_material;
	value v;

	val_check(keyMaterial, string);
	if(val_strlen(keyMaterial) < 8)
		THROW("Key material must be 8 bytes");

	schedule = (DES_key_schedule *)malloc(sizeof(DES_key_schedule));
	if(schedule == NULL)
		E_NO_MEM();

	DES_set_key_unchecked(val_const_cblock(keyMaterial), schedule);

	v = alloc_abstract(k_deskey, schedule);
	val_gc(v, des_gc_key);
	return v;
}
DEFINE_PRIM(des_create_key,1);


static value des_encrypt_block(value nekoKey, value input) {
	DES_cblock *output;
	val_check_kind(nekoKey, k_deskey);
	val_check(input, string);
	if(val_strlen(input) != DES_BLOCK_SIZE)
		THROW("block size incorrect");
	
	output = (DES_cblock *)malloc(sizeof(DES_cblock));
	if(output == NULL)
		E_NO_MEM();
	DES_ecb_encrypt(val_const_cblock(input), output, val_deskey(nekoKey), DES_ENCRYPT);
	value rv = copy_string((const char*)output, sizeof(DES_cblock));
	free(output);
	return rv;
}
DEFINE_PRIM(des_encrypt_block,2);


static value des_decrypt_block(value nekoKey, value input) {
	DES_cblock *output;
	val_check_kind(nekoKey, k_deskey);
	val_check(input, string);
	if(val_strlen(input) != DES_BLOCK_SIZE)
		THROW("block size incorrect");

	output = (DES_cblock *)malloc(sizeof(DES_cblock));
	if(output == NULL)
		E_NO_MEM();
	DES_ecb_encrypt(val_const_cblock(input), output, val_deskey(nekoKey), DES_DECRYPT);
	value rv = copy_string((const char*)output, sizeof(DES_cblock));
	free(output);
	return rv;
}
DEFINE_PRIM(des_decrypt_block,2);


static value des3_encrypt_block(value nekoKey1, value nekoKey2, value nekoKey3, value input) {
	DES_cblock *output;
	val_check_kind(nekoKey1, k_deskey);
	val_check_kind(nekoKey2, k_deskey);
	val_check_kind(nekoKey3, k_deskey);
	val_check(input, string);
	if(val_strlen(input) != DES_BLOCK_SIZE)
		THROW("block size incorrect");

	output = (DES_cblock *)malloc(sizeof(DES_cblock));
	if(output == NULL)
		E_NO_MEM();
	DES_ecb3_encrypt(val_const_cblock(input), output,
        val_deskey(nekoKey1), val_deskey(nekoKey2),
        val_deskey(nekoKey3), DES_ENCRYPT);
	value rv = copy_string((const char*)output, sizeof(DES_cblock));
	free(output);
	return rv;
}
DEFINE_PRIM(des3_encrypt_block,4);


static value des3_decrypt_block(value nekoKey1, value nekoKey2, value nekoKey3, value input) {
	DES_cblock *output;
	val_check_kind(nekoKey1, k_deskey);
	val_check_kind(nekoKey2, k_deskey);
	val_check_kind(nekoKey3, k_deskey);
	val_check(input, string);
	if(val_strlen(input) != DES_BLOCK_SIZE)
		THROW("block size incorrect");

	output = (DES_cblock *)malloc(sizeof(DES_cblock));
	if(output == NULL)
		E_NO_MEM();
	DES_ecb3_encrypt(val_const_cblock(input), output,
        val_deskey(nekoKey1), val_deskey(nekoKey2),
        val_deskey(nekoKey3), DES_DECRYPT);
	value rv = copy_string((const char*)output, sizeof(DES_cblock));
	free(output);
	return rv;
}
DEFINE_PRIM(des3_decrypt_block,4);


#endif // NEKO
