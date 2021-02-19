#include "../premake_internal.h"


/**
 * Walks arguments on the Lua stack, recursing into arrays as needed, and calls
 * the supplied function for each string value found.
 */
int pmk_unrollStrings(lua_State* L, int (*func)(const char*, const char*))
{
	const char* haystack = luaL_optstring(L, 1, NULL);
	if (haystack == NULL)
		return (0);

	int t = lua_type(L, 2);
	if (t == LUA_TTABLE) {
		int n = lua_rawlen(L, 2);
		for (int i = 1; i <= n; ++i) {
			lua_rawgeti(L, 2, i);
			const char* needle = lua_tostring(L, -1);
			if (needle && func(haystack, needle))
				return (1);
			lua_pop(L, 1);
		}
	}
	else {
		int n = lua_gettop(L);
		for (int i = 2; i <= n; ++i) {
			const char* needle = lua_tostring(L, i);
			if (needle && func(haystack, needle)) {
				lua_pushvalue(L, i);
				return (1);
			}
		}
	}

	return (0);
}
