#include "../premake_internal.h"


/**
 * Like `loadfile()`, but returns nil if the file does not exist rather
 * than raising an error.
 */
int g_loadFileOpt(lua_State* L)
{
	const char* filename = luaL_optstring(L, 1, NULL);
	const char* mode = luaL_optstring(L, 2, NULL);

	int status = (filename != NULL)
		? pmk_loadFile(L, filename)
		: luaL_loadfilex(L, filename, mode);

	if (status == LUA_ERRFILE) {
		return (0);
	}
	else if (status != LUA_OK) {
		lua_pushnil(L);
		lua_insert(L, -2);  /* error message pushed by loadfile */
		return (2);
	}
	else {
		return (1);
	}
}
