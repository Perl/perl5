#ifndef PERL_BEOS_FLOCK_SERVER_H
#define PERL_BEOS_FLOCK_SERVER_H

#include <OS.h>

#define FLOCK_SERVER_PORT_NAME "perl flock server"

typedef struct flock_server_request {
    port_id replyPort;
    sem_id lockSem;
    dev_t device;
    ino_t node;
    int fd;
    int operation;
    int blocking;
} flock_server_request;

typedef struct flock_server_reply {
    status_t error;
    int semaphoreCount;
    sem_id semaphores[1];
} flock_server_reply;

#endif
