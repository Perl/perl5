#include "beos/beosish.h"

#undef waitpid

#include <sys/wait.h>

/* In BeOS 5.0 the waitpid() seems to misbehave in that the status
 * is _not_ shifted left by eight (multiplied by 256), as it is in
 * POSIX/UNIX.  To undo the surpise effect to the rest of Perl we
 * need this wrapper.  (The rest of BeOS might be surprised because
 * of this, though.) */

pid_t beos_waitpid(pid_t process_id, int *status_location, int options) {
    pid_t got = waitpid(process_id, status_location, options);
    if (status_location)
      *status_location <<= 8; /* What about the POSIX low bits? */
    return got;
}
