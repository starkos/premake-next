#include "../premake_internal.h"
#include <string.h>

/**
 * Translates the separators in a path to the specied path.
 *
 * @param result
 *    A buffer to hold the translated path.
 * @param path
 *    The path to be translated.
 * @param separator
 *    A new path separator.
 */
void pmk_translatePath(char* result, const char* path, const char separator)
{
	strcpy(result, path);
	pmk_translatePathInPlace(result, separator);
}


void pmk_translatePathInPlace(char* path, const char separator)
{
	for (char* ch = path; *ch != '\0'; ++ch) {
		if (*ch == '/' || *ch == '\\') {
			*ch = separator;
		}
	}
}
