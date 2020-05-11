/**
 * Implementations for Premake's `terminal.*` functions.
 */

#include "../premake_internal.h"


int pmk_terminal_textColor(lua_State* L)
{
	int color = luaL_optinteger(L, 1, -1);
	if (color > 0) {
		pmk_setTextColor(color);
	}

	color = pmk_getTextColor();
	lua_pushinteger(L, color);
	return (1);
}
