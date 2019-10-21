/**
 * Implementations for Premake's `string.*` functions.
 */
#include "../premake_internal.h"
#include <string.h>


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
