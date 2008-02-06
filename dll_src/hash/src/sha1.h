#ifndef _L_SHA1_H
#define _L_SHA1_H

#include <stdlib.h>

typedef struct {
    unsigned long state[5];
    unsigned long count[2];
    unsigned char buffer[64];
    unsigned char le;
} SHA1_CTX;

void SHA1Init(SHA1_CTX* context);
void SHA1Update(SHA1_CTX* context, unsigned char* data, unsigned int len);
void SHA1Final(unsigned char digest[20], SHA1_CTX* context);
/* digest is pointer to 20 byte buffer */
int SHA1(const char *message, size_t length, unsigned char *digest);

#endif // _L_SHA1_H
