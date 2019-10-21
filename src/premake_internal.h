#include "premake.h"
#include <stdlib.h>

/* Identify the current platform. I'm not sure how to reliably detect
 * Windows, but since it is the most common I use it as the default */
#if defined(__linux__)
#define PLATFORM_LINUX (1)
#define PLATFORM_STRING "linux"
#elif defined(__FreeBSD__) || defined(__FreeBSD_kernel__) || defined(__NetBSD__) || defined(__OpenBSD__) || defined(__DragonFly__)
#define PLATFORM_BSD (1)
#define PLATFORM_STRING "bsd"
#elif defined(__APPLE__) && defined(__MACH__)
#define PLATFORM_MACOS (1)
#define PLATFORM_STRING "macosx"
#elif defined(__sun__) && defined(__svr4__)
#define PLATFORM_SOLARIS (1)
#define PLATFORM_STRING "solaris"
#elif defined(__HAIKU__)
#define PLATFORM_HAIKU (1)
#define PLATFORM_STRING "haiku"
#elif defined (_AIX)
#define PLATFORM_AIX (1)
#define PLATFORM_STRING "aix"
#elif defined (__GNU__)
#define PLATFORM_HURD (1)
#define PLATFORM_STRING "hurd"
#else
#define PLATFORM_WINDOWS (1)
#define PLATFORM_STRING "windows"
#endif

#define PLATFORM_POSIX  (PLATFORM_LINUX || PLATFORM_BSD || PLATFORM_MACOS || PLATFORM_SOLARIS)


/* Pull in platform-specific headers required by built-in functions */
#if PLATFORM_WINDOWS
#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#else
#include <unistd.h>
#endif
#include <stdint.h>

/* Not all platforms define this */
#ifndef FALSE
#define FALSE (0)
#endif
#ifndef TRUE
#define TRUE (1)
#endif

/* Fill in any missing bits */
#ifndef PATH_MAX
#define PATH_MAX   (4096)
#endif

/* Engine interface */

#define PMK_OPTION_KEY_MAX    (64)
#define PMK_PATH_KIND_UNKNOWN (0)
#define PMK_PATH_ABSOLUTE     (1)
#define PMK_PATH_RELATIVE     (2)

struct Premake {
	lua_State* L;
	premake_ErrorHandler onError;
};

typedef int (*LuaLoader)(lua_State* L, const char* filename, const char* mode);


int  pmk_chdir(const char* path);
int  pmk_doFile(lua_State* L, const char* filename);
void pmk_getAbsolutePath(char* result, const char* value, const char* relativeTo);
int  pmk_getCwd(char* result);
void pmk_getDirectory(char* result, const char* value);
const char* pmk_getOptionValue(const char* flag, int argc, const char** argv);
int  pmk_isAbsolutePath(const char* path);
int  pmk_isFile(const char* filename);
int  pmk_load(lua_State* L, const char* filename);
int  pmk_loadFile(lua_State* L, const char* filename);
int  pmk_loader(lua_State* L, const char* filename, const char* mode, LuaLoader lua_loader);
const char* pmk_locate(char* result, const char* name, const char* paths[], const char* patterns[]);
void pmk_locateExecutable(char* result, const char* argv0);
const char* pmk_locateModule(char* result, lua_State* L, const char* moduleName);
const char* pmk_locateScript(char* result, lua_State* L, const char* filename);
int  pmk_moduleLoader(lua_State* L);
int  pmk_pathKind(const char* path);
const char* pmk_parseOptionKey(const char* value, char* buffer);
const char* pmk_parseOptionValue(const char* value);
int  pmk_pcall(lua_State* L, int nargs, int nresults);
const char** pmk_searchPaths(lua_State* L);
void pmk_translatePath(char* result, const char* value, const char separator);
void pmk_translatePathInPlace(char* value, const char sep);

/* Global extensions */

int g_doFile(lua_State* L);
int g_loadFile(lua_State* L);
int g_loadFileOpt(lua_State* L);

/* OS library extensions */

int pmk_os_chdir(lua_State* L);
int pmk_os_getCwd(lua_State* L);
int pmk_os_isFile(lua_State* L);

/* String library extensions */

int pmk_string_startsWith(lua_State* L);

/* Path module functions */

int pmk_path_getAbsolute(lua_State* L);
int pmk_path_getDirectory(lua_State* L);
int pmk_path_isAbsolute(lua_State* L);
int pmk_path_kind(lua_State* L);
int pmk_path_translate(lua_State* L);

/* Premake module function */

int pmk_premake_locateScript(lua_State* L);
