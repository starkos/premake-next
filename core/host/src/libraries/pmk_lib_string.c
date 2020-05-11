/**
 * Implementations for Premake's `string.*` functions.
 */

#include "../premake_internal.h"
#include <string.h>


int pmk_string_patternFromWildcards(lua_State* L)
{
	char buffer[PATH_MAX];

	const char* value = luaL_checkstring(L, 1);
	if (!pmk_patternFromWildcards(buffer, PATH_MAX, value, 0)) {
		lua_pushstring(L, "wildcard expansion is too large");
		lua_error(L);
	}

	lua_pushstring(L, buffer);
	return (1);
}


int pmk_string_startsWith(lua_State* L)
{
	const char* haystack = luaL_optstring(L, 1, NULL);
	const char* needle = luaL_optstring(L, 2, NULL);

	if (haystack && needle) {
		size_t nlen = strlen(needle);
		lua_pushboolean(L, strncmp(haystack, needle, nlen) == 0);
		return (1);
	}

	return (0);
}