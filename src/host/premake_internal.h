#include "premake.h"

struct Premake {
	lua_State* L;
	premake_ErrorHandler onError;
};


int premake_pcall(Premake* pmk, int nargs, int nresults);
