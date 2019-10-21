#include "../premake_internal.h"


/**
 * Replacement for Lua's built-in `loadfile()` which knows how to look for
 * files along Premake's search paths.
 */
int g_loadFile(lua_State* L)
{
	const char* filename = luaL_optstring(L, 1, NULL);
	const char* mode = luaL_optstring(L, 2, NULL);

	int status = (filename != NULL)
		? pmk_loadFile(L, filename)
		: luaL_loadfilex(L, filename, mode);

	if (status != LUA_OK) {
		lua_pushnil(L);
		lua_insert(L, -2);  /* error message pushed by loadfile */
		return (2);
	}

	return (1);
}
