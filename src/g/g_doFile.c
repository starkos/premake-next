#include "../premake_internal.h"

static int continuation(lua_State* L, int status, lua_KContext context);


/**
 * Replacement for Lua's built-in `dofile()` which knows how to look for
 * files along Premake's search paths.
 */
int g_doFile(lua_State* L)
{
	const char* filename = luaL_optstring(L, 1, NULL);
	lua_settop(L, 1);

	int status = (filename != NULL)
		? pmk_loadFile(L, filename)
		: luaL_loadfile(L, filename);

	if (status != LUA_OK) {
		return lua_error(L);
	}

	lua_callk(L, 0, LUA_MULTRET, 0, continuation);
	return continuation(L, 0, 0);
}


static int continuation(lua_State* L, int status, lua_KContext context)
{
	(void)status;
	(void)context;
	return (lua_gettop(L) - 1);
}
