/* Beginning of modification history */
/* Written 02-01-02 by Nick Ing-Simmons (nick@ing-simmons.net) */
/* Modified 02-03-27 by Paul Green (Paul.Green@stratus.com) to
     add socketpair() dummy. */
/* End of modification history */

#include <errno.h>
#include <fcntl.h>
#include <sys/types.h>
#include <unistd.h>

/* VOS doesn't supply a truncate function, so we build one up
   from the available POSIX functions.  */

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

/* VOS doesn't implement AF_UNIX (AF_LOCAL) style sockets, and
   the perl emulation of them hangs on VOS (due to stcp-1257),
   so we supply this version that always fails.  */

int
socketpair (int family, int type, int protocol, int fd[2]) {
 fd[0] = 0;
 fd[1] = 0;
 errno = ENOSYS;
 return -1;
}
