#include <stdio.h>
#include <win32io.h>

extern WIN32_IOSUBSYSTEM	win32stdio;
extern int RunPerl(int argc, char **argv, char **env, void *iosubsystem);

main(int argc, char **argv, char **env)
{
	return (RunPerl(argc, argv, env, &win32stdio));
}
