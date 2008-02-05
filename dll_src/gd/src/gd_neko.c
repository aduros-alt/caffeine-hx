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
#include <neko/neko.h>
#include <gd.h>

/**
Imported kinds for files
**/
// these are in from neko/std/file.c
typedef struct {
	value name;
	FILE *io;
} fio;

/**
GD Kinds
**/
// Any arbitrary name, starting with k_
DEFINE_KIND(k_gdimage);

// conveniences
#define val_file(o)     ((fio*)val_data(o))
#define val_image(o)	(gdImagePtr)val_data(o)

// forwards
static void destroy_gdimage( value img );

// 'constuctor'
static value create_gdimage(gdImagePtr im) {
	// Throw an error if gd does
	if(im == NULL)
		return NULL;
	// see comments in gdImgCreate
	value v = alloc_abstract(k_gdimage,im);
	val_gc(v, destroy_gdimage);
	return v;
}

// 'destructor'
static void destroy_gdimage( value img ) {
	// check if the value passed is in fact a k_gdimage
	if(!val_is_kind(img, k_gdimage))
		return;

	// call gdImageDestroy with the dereferenced img value
	gdImageDestroy(val_image(img));

	// make sure GC does not clean up the img pointer, since
	// gdImageDestroy already did that. (We hope here that Pierre
	// actually free()s ram, God knows!)
	val_kind(img) = NULL;
}

static value gdImgCreate(value width, value height)
{
	// this checks that provided arguments are ints
	val_check(width, int);
	val_check(height, int);

	// this checks if either int is null. If so, return NULL
	// which triggers the haxe exception gd@gdImgCreate to be thrown
	if(val_is_null(width) || val_is_null(height))
		return NULL;

	// Good old C
	gdImagePtr im;

	// val_int returns the actual integer value for each param
	// it may return 0 for null values, making the val_is_null
	// checks above superfluous. Check that.
	im = gdImageCreate(val_int(width), val_int(height));

	// Throw an error if gd does
	if(im == NULL)
		return NULL;

	// This is where a Garbage Collectable object of our defined
	// type k_gdimage is created
	value v = alloc_abstract(k_gdimage,im);

	// Since gdImageDestroy needs to be used on a gdImagePtr, we can't
	// let Boehm clean it up. This assigns destroy_gdimage to collect
	// unreferenced k_gdimage's
	val_gc(v, destroy_gdimage);

	return v;
}
// this tells neko that gdImgCreate is exported and requires 2 arguments
DEFINE_PRIM(gdImgCreate,2);

static value gdImgCreateFromJpeg(value fpIn) {
	vkind k_file;
	kind_share(&k_file,"file");
	val_check_kind(fpIn, k_file);

	FILE *in = val_file(fpIn)->io;
	if(in == NULL) {
		value a = alloc_string("FP void");
		val_throw(a);
	}
	gdImagePtr im = gdImageCreateFromJpeg(in);

	// shortened from last example
	return(create_gdimage(im));
}
DEFINE_PRIM(gdImgCreateFromJpeg,1);

