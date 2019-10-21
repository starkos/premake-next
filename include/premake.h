#define lua_c
#include "lua/src/lua.h"
#include "lua/src/lauxlib.h"
#include "lua/src/lualib.h"

/* A Premake context object */
typedef struct Premake Premake;

/* A success return code */
#define OKAY   (0)

/**
 * Error handling function; provide your own to `premake_init`.
 */
typedef void (*premake_ErrorHandler)(const char* message, const char* traceback);

/**
 * Initialize the Premake engine and embedded Lua runtime.
 */
Premake* premake_init(premake_ErrorHandler onError);

/**
 * Shut down the Premake engine and Lua runtime and clean everything up.
 */
void premake_close(Premake* pmk);

/**
 * Evaluate a set of command line options and do what they say. See
 * the Premake usage documentation online for a full description of
 * the command line options.
 */
int premake_execute(Premake* pmk, int argc, const char** argv);

/**
 * Returns a reference to Premake's embedded Lua runtime state.
 */
lua_State* premake_runtime(Premake* pmk);
