#include "premake.h"

int main(int argc, const char** argv)
{
	int z = premake_init();

	if (z == OKAY)
		z = premake_execute(argc, argv, "src/main.lua");

	return (0);
}
