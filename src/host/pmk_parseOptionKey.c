#include "../premake_internal.h"
#include <string.h>


/**
 * Parse out the key portion of a command line option key-value pair.
 *
 * @param value
 *    The full command line option, e.g. "--scripts=value".
 * @param buffer
 *    A buffer to receive the parsed key; must be at least `PMK_OPTION_KEY_MAX`
 *    characters wide.
 * @returns
 *    If successful, copies the key value into `buffer` and returns it. If
 *    `value` is not a valid option, returns `NULL`.
 */
const char* pmk_parseOptionKey(const char* value, char* buffer)
{
	/* options must be prefixed with "-" or "/" */
	if (value[0] != '-' && value[0] != '/') {
		return (NULL);
	}

	/* skip over the prefix, one of "-", "--", or "/" */
	if (value[0] == '-' && value[1] == '-') {
		value += 2;
	} else {
		value++;
	}

	/* "=" is used to split the key from the value */
	int len = strlen(value);
	const char* splitAt = strchr(value, '=');
	if (splitAt != NULL) {
		len = (splitAt - value);
	}

	/* option keys have a length limit, to make parsing easier */
	if (len >= PMK_OPTION_KEY_MAX) {
		return (NULL);
	}

	strncpy(buffer, value, len);
	buffer[len] = '\0';

	return (buffer);
}
