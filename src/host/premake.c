#include "premake_internal.h"

static int onRuntimeError(lua_State* L);
static void reportScriptError(Premake* pmk);


Premake* premake_init(premake_ErrorHandler onError)
{
	Premake* pmk = (Premake*)malloc(sizeof(struct Premake));
	pmk->L = luaL_newstate();
	pmk->onError = onError;

	luaL_openlibs(pmk->L);

	return (pmk);
}


void premake_close(Premake* pmk)
{
	lua_close(pmk->L);
	free(pmk);
}


int premake_execute(Premake* pmk, int argc, const char** argv, const char* script)
{
	(void) argc;
	(void) argv;

	/* Run the engine bootstrapping script */
	if (luaL_dofile(pmk->L, script) != OKAY) {
		reportScriptError(pmk);
		return (!OKAY);
	}

	/* Call the main entry point */
	lua_getglobal(pmk->L, "_premake_main");
	if (premake_pcall(pmk, 0, 1) != OKAY) {
		reportScriptError(pmk);
		return (!OKAY);
	}
	else {
		int exitCode = (int)lua_tonumber(pmk->L, -1);
		return (exitCode);
	}
}


int premake_pcall(Premake* pmk, int nargs, int nresults)
{
	lua_pushcfunction(pmk->L, onRuntimeError);

	/* insert error handler before call parameters */
	int errorHandlerIndex = lua_gettop(pmk->L) - nargs - 1;
	lua_insert(pmk->L, errorHandlerIndex);

	/* make the call */
	int result = lua_pcall(pmk->L, nargs, nresults, errorHandlerIndex);

	lua_remove(pmk->L, errorHandlerIndex);
	return (result);
}


lua_State* premake_runtime(Premake* pmk)
{
	return (pmk->L);
}


static int onRuntimeError(lua_State* L)
{
	/* get the error message */
	const char* message = lua_tostring(L, -1);

	/* retrieve the stack trace via a call to debug.traceback() */
	lua_getglobal(L, "debug");
	lua_getfield(L, -1, "traceback");
	lua_remove(L, -2);      /* remove debug table */
	lua_insert(L, -2);      /* insert traceback() function before message */
	lua_pushinteger(L, 3);  /* push the starting level for traceback() */
	lua_call(L, 2, 1);
	const char* traceback = lua_tostring(L, -1);
	lua_pop(L, 1);

	/* put message and traceback in a table */
	lua_newtable(L);

	lua_pushstring(L, "message");
	lua_pushstring(L, message);
	lua_settable(L, -3);

	lua_pushstring(L, "traceback");
	lua_pushstring(L, traceback);
	lua_settable(L, -3);

	/* send it back to reportScriptError */
	return (1);
}


static void reportScriptError(Premake* pmk)
{
	const char* message;
	const char* traceback;

	if (lua_istable(pmk->L, -1)) {
		/* received a { message, traceback } pair from onRuntimeError() */
		lua_getfield(pmk->L, -1, "message");
		lua_getfield(pmk->L, -2, "traceback");
		message = lua_tostring(pmk->L, -2);
		traceback = lua_tostring(pmk->L, -1);
		lua_pop(pmk->L, 2);
	}
	else {
		/* received a simple syntax error message */
		message = lua_tostring(pmk->L, -1);
		traceback = NULL;
	}

	if (pmk->onError != NULL) {
		pmk->onError(message, traceback);
	}
}
