#include "../premake_internal.h"

#include <string.h>

int pmk_getFileName(char* result, const char* path)
{
	const char* endPtr = strrchr(path, '/');
	if (endPtr == NULL)
		endPtr = strrchr(path, '\\');

	if (endPtr != NULL) {
		strcpy(result, endPtr + 1);
	}

	return (TRUE);
}
