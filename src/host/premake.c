#include "../premake_internal.h"
#include <string.h>

#define PREMAKE_MAIN_SCRIPT_PATH   "src/_premake_main.lua"
#define PREMAKE_MAIN_ENTRY_NAME    "_premake_main"

static int  getCurrentScriptDir(lua_State* L);
static void installModuleLoader(lua_State* L);
static void registerGlobalLibrary(lua_State* L, const char* name, const luaL_Reg* functions);
static void registerInternalLibrary(lua_State* L, const char* name, const luaL_Reg* functions);
static void setArgsGlobal(lua_State* L, int argc, const char** argv);
static void setCommandGlobals(lua_State* L, const char* argv0);
static void setSearchPath(lua_State* L, int argc, const char** argv);
static void reportScriptError(Premake* pmk);


static const luaL_Reg g_functions[] = {
	{ "dofile", g_doFile },
	{ "doFile", g_doFile },
	{ "loadfile", g_loadFile },
	{ "loadFile", g_loadFile },
	{ "loadFileOpt", g_loadFileOpt },
	{ NULL, NULL }
};

static const luaL_Reg os_functions[] = {
	{ "chdir", pmk_os_chdir },
	{ "getCwd", pmk_os_getCwd },
	{ "isFile", pmk_os_isFile },
	{ NULL, NULL }
};

static const luaL_Reg path_functions[] = {
	{ "getAbsolute", pmk_path_getAbsolute },
	{ "getDirectory", pmk_path_getDirectory },
	{ "getKind", pmk_path_getKind },
	{ "isAbsolute", pmk_path_isAbsolute },
	{ "translate", pmk_path_translate },
	{ NULL, NULL }
};

static const luaL_Reg premake_functions[] = {
	{ "locateScript", pmk_premake_locateScript },
	{ NULL, NULL }
};

static const luaL_Reg string_functions[] = {
	{ "startsWith", pmk_string_startsWith },
	{ NULL, NULL }
};


Premake* premake_init(premake_ErrorHandler onError)
{
	lua_State* L = luaL_newstate();

	/* Set up a state object to keep track of things */
	Premake* pmk = (Premake*)malloc(sizeof(struct Premake));
	pmk->L = L;
	pmk->onError = onError;

	/* Find the user's home directory */
	const char* value = getenv("HOME");
	if (!value) value = getenv("USERPROFILE");
	if (!value) value = "~";
	lua_pushstring(L, value);
	lua_setglobal(L, "_USER_HOME_DIR");

	/* Create a "_PREMAKE" global to hold meta about the run */
	lua_newtable(L);
	lua_setglobal(L, "_PREMAKE");

	/* Publish Premake's extensions to the standard libraries */
	luaL_openlibs(L);

	registerGlobalLibrary(L, "_G", g_functions);
	registerGlobalLibrary(L, "os", os_functions);
	registerGlobalLibrary(L, "string", string_functions);

	registerInternalLibrary(L, "path", path_functions);
	registerInternalLibrary(L, "premake", premake_functions);

	/* Install Premake's module locator */
	installModuleLoader(L);

	return (pmk);
}


void premake_close(Premake* pmk)
{
	lua_close(pmk->L);
	free(pmk);
}


int premake_execute(Premake* pmk, int argc, const char** argv)
{
	lua_State* L = pmk->L;

	/* Copy command line arguments into _ARGS global */
	setArgsGlobal(L, argc, argv);

	/* Set _COMMAND and _COMMAND_DIR to the path to the executable */
	setCommandGlobals(L, argv[0]);

	/* Set up the script search path */
	setSearchPath(L, argc, argv);

	/* Run the entry point script */
	if (pmk_doFile(L, PREMAKE_MAIN_SCRIPT_PATH) != OKAY) {
		reportScriptError(pmk);
		return (!OKAY);
	}

	/* Initialization is complete; call the main entry point */
	lua_getglobal(L, PREMAKE_MAIN_ENTRY_NAME);
	if (pmk_pcall(L, 0, 1) != OKAY) {
		reportScriptError(pmk);
		return (!OKAY);
	} else {
		int exitCode = (int)lua_tonumber(pmk->L, -1);
		return (exitCode);
	}
}


lua_State* premake_runtime(Premake* pmk)
{
	return (pmk->L);
}


/**
 * Adds functions to one of Lua's global libraries, e.g. `string`, `table`.
 */
static void registerGlobalLibrary(lua_State* L, const char* name, const luaL_Reg* functions)
{
	lua_getglobal(L, name);
	luaL_setfuncs(L, functions, 0);
	lua_pop(L, 1);
}


/**
 * Publishes the internally implemented part of one of the Premake modules, e.g.
 * `premake`, `path`. These are placed into the `_PREMAKE` global, where they are
 * later picked up by the scripted portion of the module.
 */
static void registerInternalLibrary(lua_State* L, const char* name, const luaL_Reg* functions)
{
	lua_getglobal(L, "_PREMAKE");
	lua_newtable(L);
	luaL_setfuncs(L, functions, 0);
	lua_setfield(L, -2, name);
	lua_pop(L, 1);
}


/**
 * Push all command line arguments into _ARGS global.
 */
static void setArgsGlobal(lua_State* L, int argc, const char** argv)
{
	lua_newtable(L);

	for (int i = 1; i < argc; ++i) {
		lua_pushstring(L, argv[i]);
		lua_rawseti(L, -2, luaL_len(L, -2) + 1);
	}

	lua_setglobal(L, "_ARGS");
}


/**
 * Set the _PREMAKE.COMMAND and _PREMAKE.COMMAND_DIR globals.
 */
static void setCommandGlobals(lua_State* L, const char* argv0)
{
	char buffer[PATH_MAX];

	lua_getglobal(L, "_PREMAKE");

	pmk_locateExecutable(buffer, argv0);
	lua_pushstring(L, buffer);
	lua_setfield(L, -2, "COMMAND");

	pmk_getDirectory(buffer, buffer);
	lua_pushstring(L, buffer);
	lua_setfield(L, -2, "COMMAND_DIR");

	lua_pop(L, 1);
}


/**
 * Initializes the _PREMAKE.PATH search path use to locate scripts. This
 * needs to be done in the host to help it find the entry point script.
 */
static void setSearchPath(lua_State* L, int argc, const char** argv)
{
	int n = 0;

	lua_getglobal(L, "_PREMAKE");
	lua_newtable(L);

	/* the current value of _SCRIPT_DIR; enables script-relative paths */
	lua_pushcfunction(L, getCurrentScriptDir);
	lua_rawseti(L, -2, ++n);

	/* the path specified by --scripts, if present */
	const char* scripts = pmk_getOptionValue("scripts", argc, argv);
	if (scripts != NULL) {
		lua_pushstring(L, scripts);
		lua_rawseti(L, -2, ++n);
	}

	/* TODO: if release build, look in embedded files */

	/* the current working directory */
	lua_pushstring(L, ".");
	lua_rawseti(L, -2, ++n);

	/* any locations specified on PREMAKE6_PATH */
	char* path = getenv("PREMAKE6_PATH");
	if (path != NULL) {
		const char* segment;
		while ((segment = strsep(&path, ";")) != NULL) {
			lua_pushstring(L, segment);
			lua_rawseti(L, -2, ++n);
		}
	}

	/* the user's ~/.premake folder */
	lua_getglobal(L, "_USER_HOME_DIR");
	lua_pushstring(L, "/.premake");
	lua_concat(L, 2);
	lua_rawseti(L, -2, ++n);

	/* the user's Application Support folder */
#if PLATFORM_MACOSX
	lua_getglobal(L, "_USER_HOME_DIR");
	lua_pushstring(L, "/Library/Application Support/Premake");
	lua_concat(L, 2);
	lua_rawseti(L, -2, ++n);
#endif

	/* system and user "share" folders */
#if PLATFORM_POSIX
	lua_pushstring(L, "/usr/local/share/premake");
	lua_rawseti(L, -2, ++n);

	lua_pushstring(L, "/usr/share/premake");
	lua_rawseti(L, -2, ++n);
#endif

	/* the directory containing the Premake executable */
	lua_getglobal(L, "_PREMAKE");
	lua_getfield(L, -1, "COMMAND_DIR");
	lua_rawseti(L, -3, ++n);
	lua_pop(L, 1);

	lua_setfield(L, -2, "PATH");
	lua_pop(L, 1);
}


/**
 * Retrieve the current value of the _SCRIPT_DIR global and return it on
 * the stack. This is placed early in the script search path and allows for
 * loading things relative to the currently running script.
 */
static int getCurrentScriptDir(lua_State* L)
{
	lua_getglobal(L, "_SCRIPT_DIR");
	return (1);
}


/**
 * Install a new module "searcher" that knows how to use Premake's search
 * paths and loaders.
 */
static void installModuleLoader(lua_State* L)
{
	/* get the `package.searchers` table */
	lua_getglobal(L, "package");
	lua_getfield(L, -1, "searchers");

	/* insert our custom searcher at the first position */
	lua_getglobal(L, "table");
	lua_getfield(L, -1, "insert");
	lua_pushvalue(L, -3);
	lua_pushinteger(L, 1);
	lua_pushcfunction(L, pmk_moduleLoader);
	lua_call(L, 3, 0);

	lua_pop(L, 3);
}


/**
 * Called when a fatal error occurs in a script. Collects information
 * about the error and reports it to the host to handle.
 */
static void reportScriptError(Premake* pmk)
{
	const char* message;
	const char* traceback;

	lua_State* L = pmk->L;

	if (lua_istable(L, -1)) {
		/* received a { message, traceback } pair from onRuntimeError() */
		lua_getfield(L, -1, "message");
		lua_getfield(L, -2, "traceback");
		message = lua_tostring(L, -2);
		traceback = lua_tostring(L, -1);
		lua_pop(L, 2);
	} else {
		/* received a simple syntax error message */
		message = lua_tostring(L, -1);
		traceback = NULL;
	}

	if (pmk->onError != NULL) {
		pmk->onError(message, traceback);
	}
}
