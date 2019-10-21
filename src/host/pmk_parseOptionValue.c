#include "../premake_internal.h"
#include <string.h>


/**
 * Parse out the value portion of a command line option key-value pair.
 *
 * @param value
 *    The full command line option, e.g. "--scripts=value".
 * @returns
 *    If successful, return the value portion of the option. If no value is
 *    present, returns `NULL`.
 */
const char* pmk_parseOptionValue(const char* value)
{
	const char* splitAt = strchr(value, '=');

	if (splitAt != NULL) {
		return (splitAt + 1);
	}

	return (NULL);
}
