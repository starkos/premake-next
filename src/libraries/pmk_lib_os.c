/**
 * Implementations for Premake's `os.*` functions.
 */
#include "../premake_internal.h"


int pmk_os_chdir(lua_State* L)
{
	const char* path = luaL_checkstring(L, 1);

	if (pmk_chdir(path)) {
		lua_pushboolean(L, 1);
		return (1);
	} else {
		lua_pushnil(L);
		lua_pushfstring(L, "unable to switch to directory '%s'", path);
		return (2);
	}
}


int pmk_os_getCwd(lua_State* L)
{
	char buffer[PATH_MAX];

	if (pmk_getCwd(buffer)) {
		lua_pushstring(L, buffer);
		return (1);
	}

	return (0);
}


int pmk_os_isFile(lua_State* L)
{
	const char* filename = luaL_checkstring(L, 1);
	lua_pushboolean(L, pmk_isFile(filename));
	return (1);
}
