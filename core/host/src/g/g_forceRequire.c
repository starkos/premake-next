#include "../premake_internal.h"


/**
 * Force a module to be loaded, even it was loaded previously.
 */
int g_forceRequire(lua_State* L)
{
	char buffer[PATH_MAX];

	const char* module = luaL_checkstring(L, 1);

	const char* locatedAt = pmk_locateModule(buffer, L, module);
	if (!locatedAt) {
		lua_pushfstring(L, "no such module `%s`", module);
		lua_error(L);
	}

	pmk_doFile(L, locatedAt);
	return (0);
}
