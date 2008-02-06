#include <stdlib.h>
#include "sha1.h"

#ifdef NEKO

#include <neko/neko.h>
static value nsha1(value msg) {
	unsigned char digest[20];
	size_t length;
	SHA1(val_string(msg), val_strlen(msg), digest);
	return copy_string(digest, 20);
}
DEFINE_PRIM(nsha1,1);

#elif defined(LUA)
#include "lua.h"
#include "lauxlib.h"

/**
*  Hash function. Returns a hash for a given string.
*  @param message: arbitrary binary string.
*  @return  A 160-bit hash string.
*/
static int lsha1 (lua_State *L) {
	unsigned char digest[20];
	size_t length;
	const char *message = luaL_checklstring(L, 1, &length);
	SHA1(message, length, digest);
	lua_pushlstring(L, (const char *)digest, 20L);
	return 1;
}


static struct luaL_reg sha1lib[] = {
  {"sum", lsha1},
  {NULL, NULL}
};


int luaopen_sha1 (lua_State *L) {
  luaL_openlib(L, "sha1", sha1lib, 0);
  return 1;
}

#endif
