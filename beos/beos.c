#include "beos/beosish.h"
#include "beos/beos_flock_server.h"

#undef waitpid
#undef close
#undef kill

#include <errno.h>
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>

#include <OS.h>

/* We cache, for which FDs we got a lock. This will especially speed up close(),
   since we won't have to contact the server. */
#define FLOCK_TABLE_SIZE 256
static int flockTable[FLOCK_TABLE_SIZE];

/* In BeOS 5.0 the waitpid() seems to misbehave in that the status
 * has the upper and lower bytes swapped compared with the usual
 * POSIX/UNIX implementations.  To undo the surpise effect to the
 * rest of Perl we need this wrapper.  (The rest of BeOS might be
 * surprised because of this, though.) */

pid_t beos_waitpid(pid_t process_id, int *status_location, int options) {
    pid_t got = waitpid(process_id, status_location, options);
    if (status_location)
      *status_location =
	(*status_location & 0x00FF) << 8 |
	(*status_location & 0xFF00) >> 8;
    return got;
}

/* The flock() emulation worker function. */

static status_t beos_flock(int fd, int operation) {
    static int serverPortInitialized = 0;
    static port_id serverPort = -1;

    struct stat st;
    int blocking;
    port_id replyPort;
    sem_id lockSem = -1;
    status_t error;
    flock_server_request request;
    flock_server_reply *reply = NULL;

    if (fd < 0)
        return B_BAD_VALUE;

    blocking = !(operation & LOCK_NB);
    operation &= LOCK_SH | LOCK_EX | LOCK_UN;

    /* don't try to unlock something that isn't locked */
    if (operation == LOCK_UN && fd < FLOCK_TABLE_SIZE && !flockTable[fd])
        return B_OK;

    /* if not yet initialized, get the server port */
    if (!serverPortInitialized) {
        serverPort = find_port(FLOCK_SERVER_PORT_NAME);
        /* bonefish: If the port wasn't present at this point, we could start
         * the server. In fact, I tried this and in works, but unfortunately
         * it also seems to confuse our pipes (with both load_image() and
         * system()). So, we can't help it, the server has to be started
         * manually. */
        serverPortInitialized = ~0;
    }
    if (serverPort < 0)
        return B_ERROR;

    /* stat() the file to get the node_ref */
    if (fstat(fd, &st) < 0)
        return errno;

    /* create a reply port */
    replyPort = create_port(1, "flock reply port");
    if (replyPort < 0)
        return replyPort;

    /* create a semaphore others will wait on while we own the lock */
    if (operation != LOCK_UN) {
        char semName[64];
        sprintf(semName, "flock %ld:%lld\n", st.st_dev, st.st_ino);
        lockSem = create_sem(0, semName);
        if (lockSem < 0) {
            delete_port(replyPort);
            return lockSem;
        }
    }

    /* prepare the request */
    request.replyPort = replyPort;
    request.lockSem = lockSem;
    request.device = st.st_dev;
    request.node = st.st_ino;
    request.fd = fd;
    request.operation = operation;
    request.blocking = blocking;

    /* We ask the server to get us the requested lock for the file.
     * The server returns semaphores for all existing locks (or will exist
     * before it's our turn) that prevent us from getting the lock just now.
     * We block on them one after the other and after that officially own the
     * lock. If we told the server that we don't want to block, it will send
     * an error code, if that is not possible. */

    /* send the request */
    error = write_port(serverPort, 0, &request, sizeof(request));

    if (error == B_OK) {
        /* get the reply size */
        int replySize = port_buffer_size(replyPort);
        if (replySize < 0)
            error = replySize;

        /* allocate reply buffer */
        if (error == B_OK) {
            reply = (flock_server_reply*)malloc(replySize);
            if (!reply)
                error = B_NO_MEMORY;
        }

        /* read the reply */
        if (error == B_OK) {
            int32 code;
            ssize_t bytesRead = read_port(replyPort, &code, reply, replySize);
            if (bytesRead < 0) {
                error = bytesRead;
            } else if (bytesRead != replySize) {
                error = B_ERROR;
            }
        }
    }

    /* get the error returned by the server */
    if (error == B_OK)
        error = reply->error;

    /* wait for all lockers before us */
    if (error == B_OK) {
        int i;
        for (i = 0; i < reply->semaphoreCount; i++)
            while (acquire_sem(reply->semaphores[i]) == B_INTERRUPTED);
    }

    /* free the reply buffer */
    free(reply);

    /* delete the reply port */
    delete_port(replyPort);

    /* on failure delete the semaphore */
    if (error != B_OK)
        delete_sem(lockSem);

    /* update the entry in the flock table */
    if (error == B_OK && fd < FLOCK_TABLE_SIZE) {
        if (operation == LOCK_UN)
            flockTable[fd] = 0;
        else
            flockTable[fd] = 1;
    }

    return error;
}

/* We implement flock() using a server. It is not really compliant with, since
 * it would be very hard to track dup()ed FDs and those cloned as side-effect
 * of fork(). Our locks are bound to the process (team) and a particular FD.
 * I.e. a lock acquired by a team using a FD can only be unlocked by the same
 * team using exactly the same FD (no other one pointing to the same file, not
 * even when dup()ed from the original one). close()ing the FD releases the
 * lock (that's why we need to override close()). On termination of the team
 * all locks owned by the team will automatically be released. */

int flock(int fd, int operation) {
    status_t error = beos_flock(fd, operation);
    return (error == B_OK ? 0 : (errno = error, -1));
}

/* We need to override close() to release a potential lock on the FD. See
   flock() for details */

int beos_close(int fd) {
    flock(fd, LOCK_UN);

    return close(fd);
}


/* BeOS kill() doesn't like the combination of the pseudo-signal 0 and
 * specifying a process group (i.e. pid < -1 || pid == 0). We work around
 * by changing pid to the respective process group leader. That should work
 * well enough in most cases. */

int beos_kill(pid_t pid, int sig)
{
    if (sig == 0) {
        if (pid == 0) {
            /* it's our process group */
            pid = getpgrp();
        } else if (pid < -1) {
            /* just address the process group leader */
            pid = -pid;
        }
    }

    return kill(pid, sig);
}
