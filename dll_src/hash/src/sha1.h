#ifndef _L_SHA1_H
#define _L_SHA1_H

#include <stdlib.h>
#include <sys/types.h>

#ifdef __cplusplus
extern "C" {
#endif

#define SHA1_DIGEST_SIZE ( 160 / 8)

typedef struct {
    u_int32_t state[5];
    u_int32_t count[2];
    unsigned char buffer[64];
    unsigned char le;
} SHA1_CTX;

void SHA1Init(SHA1_CTX* context);
void SHA1Update(SHA1_CTX* context, u_char* data, u_int32_t len);
void SHA1Final(u_char digest[20], SHA1_CTX* context);
/* digest is pointer to 20 byte buffer */
int SHA1(const char *message, size_t length, u_char* digest);

#ifdef __cplusplus
}
#endif
#endif // _L_SHA1_H
