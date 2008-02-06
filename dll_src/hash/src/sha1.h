#ifndef _L_SHA1_H
#define _L_SHA1_H

#include <stdlib.h>

/* digest is pointer to 20 byte buffer */
int SHA1(const char *message, size_t length, unsigned char *digest);

#endif // _L_SHA1_H
