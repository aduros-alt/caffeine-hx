/* Copyright 2007, Ritchie Turner (blackdog)
 * http://www.blackdog-haxe.com
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * http://www.apache.org/licenses/LICENSE-2.0
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 *limitations under the License.
 */

#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <string.h>
#include <ctype.h>
#include <neko/neko.h>

#include "http11_parser.h"

void httpp_internal_free(value d);

DEFINE_KIND(k_HttpParser) ;

void http_field(void *parser,void *data,  char *field, size_t flen,  char *val, size_t vlen){
	*(field+flen) = '\0';
	*(val+vlen) = '\0';
	http_parser *p = (http_parser *)parser;
	if (strncmp(field,"Content-Length",14) == 0) {
		// special case Content-Length as it's used on every
		// request
		int cl = atoi(val) ;
		alloc_field(p->neko_val,val_id(field),alloc_int(cl));
	} else
		alloc_field(p->neko_val,val_id(field),alloc_string(val));
	//printf("got FIELD %s=%s\n",field,value);
}

void request_method(void *parser,void *data, char *at, size_t length) {
	*(at+length)='\0';
	http_parser *p = (http_parser *)parser;
	alloc_field(p->neko_val,val_id("REQUEST_METHOD"),alloc_string(at));
	//printf("got REQUESTMETHOD:%s\n",qs);
}

void request_uri(void *parser,void *data, char *at, size_t length) {
	*(at+length)='\0';
	http_parser *p = (http_parser *)parser;
	alloc_field(p->neko_val,val_id("REQUEST_URI"),alloc_string(at));
	//printf("got REQUESTURI:%s\n",qs);
}

void request_path(void *parser,void *data, char *at, size_t length) {
	*(at+length)='\0';
	http_parser *p = (http_parser *)parser;
	alloc_field(p->neko_val,val_id("REQUEST_PATH"),alloc_string(at));
	//printf("got REQUESTPATH:%s\n",qs);
}

void query_string(void *parser,void *data, char *at, size_t length) {
	*(at+length)='\0';
	http_parser *p = (http_parser *)parser;
	alloc_field(p->neko_val,val_id("QUERY_STRING"),alloc_string(at));
	//printf("got QSTRING:%s\n",at);
}

void http_version(void *parser,void *data, char *at, size_t length) {
	*(at+length)='\0';
	http_parser *p = (http_parser *)parser;
	alloc_field(p->neko_val,val_id("HTTP_VERSION"),alloc_string(at));
	//printf("got HTTPVERSION:%s\n",qs);
}

/** Finalizes the request header to have a bunch of stuff that's
  needed. */

void header_done(void *parser,void *data, char *at, size_t length) {
	http_parser *p = (http_parser *)parser;
	val_call1(*(p->neko_cb),p->neko_val);
}

void httpp_internal_free(value d) {
	http_parser *p= val_data(d);
	if (p != NULL) {
		free_root(p->neko_cb);
		free(p);
		val_kind(d) = NULL;
	}
}

value httpp_init() {
	http_parser *hp = calloc(1,sizeof(http_parser));

	hp->http_field = http_field;
	hp->request_method = request_method;
	hp->request_uri = request_uri;
	hp->request_path = request_path;
	hp->query_string = query_string;
	hp->http_version = http_version;
	hp->header_done = header_done;
	hp->neko_cb = alloc_root(1);

	http_parser_init(hp);

	value tmp_av = alloc_abstract(k_HttpParser,hp);
	val_gc(tmp_av,httpp_internal_free);
	return tmp_av;
}

value httpp_reset(value parser) {
	val_check_kind(parser,k_HttpParser);
	http_parser *http = val_data(parser);
	http_parser_init(http);
	return val_true;
}

value httpp_finish(value parser) {
	val_check_kind(parser,k_HttpParser);
	http_parser *http = val_data(parser);
	http_parser_finish(http);
  	return alloc_bool(http_parser_is_finished(http));
}

value httpp_execute(value parser,value data,value len,value func) {
	val_check_kind(parser,k_HttpParser);
	val_check_function(func,1);
	http_parser *http = val_data(parser);
	*(http->neko_cb) = func;
	http->neko_val = alloc_object(NULL);
	http_parser_init(http);
	http_parser_execute(http, val_string(data), val_int(len), 0);
	http->neko_val = NULL;
	return val_true;
}

static value httpp_has_error(value parser)
{
	val_check_kind(parser,k_HttpParser);
	http_parser *http = val_data(parser);
	if(http_parser_has_error(http))
		return val_true;
	return val_false;
}

void httpp_is_finished(){
}

void httpp_nread() {
}

DEFINE_PRIM(httpp_init,0);
DEFINE_PRIM(httpp_reset,1);
DEFINE_PRIM(httpp_finish,0);
DEFINE_PRIM(httpp_execute,4);
DEFINE_PRIM(httpp_has_error,0);
DEFINE_PRIM(httpp_is_finished,0);
DEFINE_PRIM(httpp_nread,0);
