/* Beginning of modification history */
/* Written 02-01-02 by Nick Ing-Simmons (nick@ing-simmons.net) */
/* End of modification history */

/* VOS doesn't supply a truncate function, so we build one up
   from the available POSIX functions.  */

#include <fcntl.h>
#include <sys/types.h>
#include <unistd.h>

int
truncate(const char *path, off_t len)
{
 int fd = open(path,O_WRONLY);
 int code = -1;
 if (fd >= 0) {
   code = ftruncate(fd,len);
   close(fd); 
 }
 return code;
}
