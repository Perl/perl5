/* Server required for the flock() emulation under BeOS. */
#include <stdio.h>
#include <string.h>
#include <unistd.h>

#include <hash_map.h>

#include "beos_flock_server.h"

/* debugging... */
//#define PRINT(x) { printf x; }
#define PRINT(x) ;

/* flock() operation flags */
#define LOCK_SH (0x00)
#define LOCK_EX (0x01)
#define LOCK_UN (0x02)
#define LOCK_NB (0x04)

enum {
    MAX_WAITERS = 1024,
    MAX_REPLY_SIZE = sizeof(flock_server_reply) + MAX_WAITERS * sizeof(sem_id)
};

/* A node_ref equivalent, so we don't need to link against libbe.so. */
struct NodeRef {
    NodeRef() : device(-1), node(-1) {}
    NodeRef(dev_t device, ino_t node) : device(device), node(node) {}

    NodeRef& operator=(const NodeRef& other)
    {
        device = other.device;
        node = other.node;
        return *this;
    }

    bool operator==(const NodeRef& other) const
    {
        return (device == other.device && node == other.node);
    }

    dev_t device;
    ino_t node;
};

/* Class representing a (potential) lock. */
struct FlockEntry {

    FlockEntry(team_id team, sem_id lockSem, int fd, bool shared)
        : team(team),
          lockSem(lockSem),
          fd(fd),
          shared(shared),
          next(NULL)
    {
    }

    ~FlockEntry()
    {
        if (lockSem >= 0)
            delete_sem(lockSem);
    }

    team_id team;
    sem_id lockSem;
    int fd;
    bool shared;

    FlockEntry *next;
};

struct NodeRefHash
{
    size_t operator()(const NodeRef &nodeRef) const
    {
        uint32 hash = nodeRef.device;
        hash = hash * 17 + (uint32)nodeRef.node;
        hash = hash * 17 + (uint32)(nodeRef.node >> 32);
        return hash;
    }
};

typedef hash_map<NodeRef, FlockEntry*, NodeRefHash> FlockEntryMap;
static FlockEntryMap sFlockEntries;


static status_t remove_lock(team_id team, flock_server_request &request,
    flock_server_reply &reply);

static void put_flock_entry(const NodeRef &nodeRef, FlockEntry *entry)
{
    sFlockEntries[nodeRef] = entry;
}

static void remove_flock_entry(const NodeRef &nodeRef)
{
    sFlockEntries.erase(nodeRef);
}


static FlockEntry *get_flock_entry(const NodeRef &nodeRef)
{
    FlockEntryMap::iterator it = sFlockEntries.find(nodeRef);
    if (it == sFlockEntries.end())
        return NULL;
    FlockEntry *entry = it->second;

    /* remove all entries that are obsolete */
    FlockEntry *firstEntry = entry;
    FlockEntry *previousEntry = NULL;
    sem_info semInfo;
    while (entry) {
        if (get_sem_info(entry->lockSem, &semInfo) != B_OK) {
            FlockEntry *oldEntry = entry;
            entry = entry->next;
            if (previousEntry)
                previousEntry->next = oldEntry->next;
            else
                firstEntry = entry;
            delete oldEntry;
        } else {
            previousEntry = entry;
            entry = entry->next;
        }
    }
    if (firstEntry)
        put_flock_entry(nodeRef, firstEntry);
    else
        remove_flock_entry(nodeRef);

    return firstEntry;
}

static FlockEntry *find_flock_entry(FlockEntry *entry, team_id team, int fd,
    FlockEntry **_previousEntry = NULL)
{
    FlockEntry *previousEntry = NULL;
    while (entry) {
        if (entry->team == team && entry->fd == fd) {
            /* found it */
            if (_previousEntry)
                *_previousEntry = previousEntry;
            return entry;
        }

        previousEntry = entry;
        entry = entry->next;
    }
    return entry;
}

static status_t add_lock(team_id team, flock_server_request &request,
    flock_server_reply &reply)
{
    bool shared = (request.operation == LOCK_SH);

    PRINT(("add_lock(): shared: %d, blocking: %d, file: (%ld, %lld), "
        "team: %ld, fd: %d\n", shared, request.blocking, request.device,
        request.node, team, request.fd));

    // get the flock entry list
    NodeRef nodeRef(request.device, request.node);

    FlockEntry *entry = get_flock_entry(nodeRef);

    reply.semaphoreCount = 0;

    /* special case: the caller already has the lock */
    if (entry && entry->team == team && entry->fd == request.fd) {
        if (shared == entry->shared)
            return B_OK;

        FlockEntry *nextEntry = entry->next;
        if (!nextEntry) {
            /* noone is waiting: just relabel the entry */
            entry->shared = shared;
            delete_sem(request.lockSem); /* re-use the old semaphore */
            return B_OK;
        } else if (shared) {
            /* downgrade to shared lock: this is simple, if only share or
             * exclusive lockers were waiting, but in mixed case we can
             * neither just replace the semaphore nor just relabel the entry,
             * but if mixed we have to surrender the exclusive lock and apply
             * for a new one */

            /* check, if there are only exclusive lockers waiting */
            FlockEntry *waiting = nextEntry;
            bool onlyExclusiveWaiters = true;
            while (waiting && onlyExclusiveWaiters) {
                onlyExclusiveWaiters &= !waiting->shared;
                waiting = waiting->next;
            }

            if (onlyExclusiveWaiters) {
                /* just relabel the entry */
                entry->shared = shared;
                delete_sem(request.lockSem); /* re-use the old semaphore */
                return B_OK;
            }

            /* check, if there are only shared lockers waiting */
            waiting = nextEntry;
            bool onlySharedWaiters = true;
            while (waiting && onlySharedWaiters) {
                onlySharedWaiters &= waiting->shared;
                waiting = waiting->next;
            }

            if (onlySharedWaiters) {
                /* replace the semaphore */
                delete_sem(entry->lockSem);
                entry->lockSem = request.lockSem;
                entry->shared = shared;
                return B_OK;
            }

            /* mixed waiters: fall through... */
        } else {
            /* upgrade to exclusive lock: fall through... */
        }

        /* surrender the lock and re-lock */
        if (!request.blocking)
            return B_WOULD_BLOCK;
        flock_server_reply dummyReply;
        remove_lock(team, request, dummyReply);
        entry = nextEntry;

        /* fall through... */
    }

    /* add the semaphores of the preceding exclusive locks to the reply */
    FlockEntry* lastEntry = entry;
    while (entry) {
        if (!shared || !entry->shared) {
            if (!request.blocking)
                return B_WOULD_BLOCK;

            reply.semaphores[reply.semaphoreCount++] = entry->lockSem;
        }

        lastEntry = entry;
        entry = entry->next;
    }

    /* create a flock entry and add it */
    FlockEntry *newEntry = new FlockEntry(team, request.lockSem, request.fd,
        shared);
    if (lastEntry)
        lastEntry->next = newEntry;
    else
        put_flock_entry(nodeRef, newEntry);
        
    return B_OK;
}

static status_t remove_lock(team_id team, flock_server_request &request,
    flock_server_reply &reply)
{
    // get the flock entry list
    NodeRef nodeRef(request.device, request.node);

    PRINT(("remove_lock(): file: (%ld, %lld), team: %ld, fd: %d\n",
        request.device, request.node, team, request.fd));

    // find the entry to be removed
    FlockEntry *previousEntry = NULL;
    FlockEntry *entry = find_flock_entry(get_flock_entry(nodeRef), team,
        request.fd, &previousEntry);
    
    if (!entry)
        return B_BAD_VALUE;

    /* remove the entry */
    if (previousEntry) {
        previousEntry->next = entry->next;
    } else {
        if (entry->next) {
            put_flock_entry(nodeRef, entry->next);
        } else {
            remove_flock_entry(nodeRef);
        }
    }
    delete entry;
    return B_OK;

}

int main(int argc, char** argv) {
    /* get independent of our creator */
    setpgid(0, 0);

    /* create the request port */
    port_id requestPort = create_port(10, FLOCK_SERVER_PORT_NAME);
    if (requestPort < 0) {
        fprintf(stderr, "Failed to create request port: %s\n",
            strerror(requestPort));
        exit(1);
    }

    /* Check whether we are the first instance of the server. We do this by
     * iterating through all teams and check, whether another team has a
     * port with the respective port name. */
    {
        /* get our team ID */
        thread_info threadInfo;
        get_thread_info(find_thread(NULL), &threadInfo);
        team_id thisTeam = threadInfo.team;

        /* iterate through all existing teams */
        int32 teamCookie = 0;
        team_info teamInfo;
        while (get_next_team_info(&teamCookie, &teamInfo) == B_OK) {
            /* skip our own team */
            team_id team = teamInfo.team;
            if (team == thisTeam)
                continue;

            /* iterate through the team's ports */
            int32 portCookie = 0;
            port_info portInfo;
            while (get_next_port_info(team, &portCookie, &portInfo) == B_OK) {
                if (strcmp(portInfo.name, FLOCK_SERVER_PORT_NAME) == 0) {
                    fprintf(stderr, "There's already a flock server running: "
                        "team: %ld\n", team);
                    delete_port(requestPort);
                    exit(1);
                }
            }
        }

        /* Our creator might have supplied a semaphore we shall delete, when
         * we're initialized. Note that this is still supported here, but
         * due to problems with pipes the server is no longer started from
         * our flock() in libperl.so, so it is not really used anymore. */
        if (argc >= 2) {
            sem_id creatorSem = (argc >= 2 ? atol(argv[1]) : -1);
    
            /* check whether the semaphore really exists and belongs to our team
               (our creator has transferred it to us) */
            sem_info semInfo;
            if (creatorSem > 0 && get_sem_info(creatorSem, &semInfo) == B_OK
                && semInfo.team == thisTeam) {
                delete_sem(creatorSem);
            }
        }
    }

    /* main request handling loop */
    while (true) {
        /* read the request */
        flock_server_request request;
        int32 code;
        ssize_t bytesRead = read_port(requestPort, &code, &request,
            sizeof(request));
        if (bytesRead != (int32)sizeof(request))
            continue;

        /* get the team */
        port_info portInfo;
        if (get_port_info(request.replyPort, &portInfo) != B_OK)
            continue;
        team_id team = portInfo.team;

        char replyBuffer[MAX_REPLY_SIZE];
        flock_server_reply &reply = *(flock_server_reply*)replyBuffer;

        /* handle the request */
        status_t error = B_ERROR;
        switch (request.operation) {
            case LOCK_SH:
            case LOCK_EX:
                error = add_lock(team, request, reply);
                break;
            case LOCK_UN:
                error = remove_lock(team, request, reply);
                break;
        }

        if (error == B_OK) {
            PRINT(("  -> successful\n"));
        } else {
            PRINT(("  -> failed: %s\n", strerror(error)));
        }

        /* prepare the reply */
        reply.error = error;
        int32 replySize = sizeof(flock_server_reply);
        if (error == B_OK)
            replySize += reply.semaphoreCount * sizeof(sem_id) ;

        /* send the reply */
        write_port(request.replyPort, 0, &reply, replySize);
    }

    return 0;
}
