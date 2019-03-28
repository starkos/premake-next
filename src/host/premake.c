#include "premake.h"

static lua_State* L = NULL;


int premake_init()
{
	L = luaL_newstate();
	luaL_openlibs(L);

	return (OKAY);
}


void premake_close()
{
	lua_close(L);
	L = NULL;
}


int premake_execute(int argc, const char** argv, const char* script)
{
	luaL_dofile(L, script);
	return (OKAY);
}


lua_State* premake_runtime()
{
	return (L);
}
