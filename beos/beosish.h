#ifndef PERL_BEOS_BEOSISH_H
#define PERL_BEOS_BEOSISH_H

#include "../unixish.h"

#undef  waitpid
#define waitpid beos_waitpid

pid_t beos_waitpid(pid_t process_id, int *status_location, int options);

/* This seems to be protoless. */
char *gcvt(double value, int num_digits, char *buffer);


/* flock() operation flags */
#define LOCK_SH	(0x00)
#define LOCK_EX	(0x01)
#define LOCK_UN	(0x02)
#define LOCK_NB	(0x04)

int flock(int fd, int operation);

#undef close
#define close beos_close

int beos_close(int fd);


#undef kill
#define kill beos_kill
int beos_kill(pid_t pid, int sig);

#endif

