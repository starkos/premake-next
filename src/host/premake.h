#define lua_c
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

/* A success return code */
#define OKAY   (0)

int premake_init();
void premake_close();
int premake_execute(int argc, const char** argv, const char* script);
lua_State* premake_runtime();
