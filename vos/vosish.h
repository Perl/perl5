#ifdef __GNUC__
#include "../unixish.h"
#else
#include "unixish.h"
#endif

/* The following declaration is an avoidance for posix-950. */
extern int ioctl (int fd, int request, ...);
