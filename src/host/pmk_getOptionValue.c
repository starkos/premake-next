#include "../premake_internal.h"
#include <string.h>

/**
 * Retrieve the value for a specific command line option. The host uses this
 * to retrieve the value of the "--scripts" option on startup, which it needs
 * to locate the main entry point script.
 *
 * @param flag
 *    The flag name for the option to retrieve, i.e. "scripts".
 * @param argc
 *    The command line argument count, as received by `main()`.
 * @param argv
 *    The command line argument list, as received by `main()`.
 * @return
 *    The option value, if found, or `NULL` otherwise.
 */
const char* pmk_getOptionValue(const char* flag, int argc, const char** argv)
{
	char buffer[PMK_OPTION_KEY_MAX];

	for (int i = 0; i < argc; ++i) {
		const char* arg = argv[i];

		const char* key = pmk_parseOptionKey(arg, buffer);
		if (key != NULL && strcmp(flag, key) == 0) {
			const char* value = pmk_parseOptionValue(arg);

			if (value == NULL) {
				value = argv[i + 1];
			}

			return (value);
		}
	}

	return (NULL);
}
