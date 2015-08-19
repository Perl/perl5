#ifndef _AMIGAOS_H
#define _AMIGAOS_H

/* prototypes and defines missing from current OS4 SDK; */

/* netinet/in.h */

// #define INADDR_LOOPBACK   0x7f00001UL

/* unistd.h */

#include <stdio.h>

#if defined(__CLIB2__)
#  include <dos.h>
#endif
#if defined(__NEWLIB__)
#  include <amiga_platform.h>
#endif

#if 1
int myexecve(const char *path, char *argv[], char *env[]);
int myexecvp(const char *filename, char *argv[]);
int myexecv(const char *path, char *argv[]);
int myexecl(const char *path, ...);
#endif

#define execve(path, argv, env) myexecve(path, argv, env)
#define execvp(filename, argv) myexecvp(filename, argv)
#define execv(path, argv) myexecv(path, argv)
#define execl(path, ...) myexecl(path, __VA_ARGS__)

int pipe(int filedes[2]);

FILE *amigaos_popen(const char *cmd, const char *mode);
void amigaos4_obtain_environ();
void amigaos4_release_environ();

/* signal.h */

// #define SIGQUIT SIGABRT

void ___makeenviron() __attribute__((constructor));
void ___freeenviron() __attribute__((destructor));

long amigaos_get_file(int fd);

// BOOL constructed;



#endif
