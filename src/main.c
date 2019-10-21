#include "premake.h"

static void errorHandler(const char* message, const char* traceback);


int main(int argc, const char** argv)
{
	Premake* pmk = premake_init(errorHandler);
	if (pmk == NULL) {
		return (-1);
	}

	if (premake_execute(pmk, argc, argv) != OKAY) {
		return (-1);
	}

	premake_close(pmk);
	return (0);
}


static void errorHandler(const char* message, const char* traceback)
{
#if !defined(NDEBUG)
	if (traceback != NULL) {
		message = traceback;
	}
#else
	(void) traceback;
#endif

	printf("Error: %s\n", message);
}
