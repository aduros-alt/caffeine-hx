#include "rijndael-api-fst.h"

#define TEA_BLOCK_SIZE  4       // bytes, sizeof int32

int32_t xxtea(u_int32_t* v, u_int32_t n, u_int32_t* k);
