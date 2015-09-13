#ifndef _AMIGAOS_H
#define _AMIGAOS_H

/* prototypes and defines missing from current OS4 SDK; */

/* netinet/in.h */

// #define INADDR_LOOPBACK   0x7f00001UL

/* unistd.h */

#include <stdio.h>

#if defined(__CLIB2__)
#include <dos.h>
#endif
#if defined(__NEWLIB__)
#include <amiga_platform.h>
#endif

#if 1
int myexecve(bool isperlthread, const char *path, char *argv[], char *env[]);
int myexecvp(bool isperlthread, const char *filename, char *argv[]);
int myexecv(bool isperlthread, const char *path, char *argv[]);
int myexecl(bool isperlthread, const char *path, ...);
#endif

#define execve(path, argv, env) myexecve(TRUE, path, argv, env)
#define execvp(filename, argv) myexecvp(TRUE, filename, argv)
#define execv(path, argv) myexecv(TRUE, path, argv)
#define execl(path, ...) myexecl(TRUE, path, __VA_ARGS__)

int pipe(int filedes[2]);

FILE *amigaos_popen(const char *cmd, const char *mode);
void amigaos4_obtain_environ();
void amigaos4_release_environ();

char *mystrdup(const char *s);

char *convert_path_u2a(const char *filename);
char *convert_path_a2u(const char *filename);

/* signal.h */

// #define SIGQUIT SIGABRT

void ___makeenviron() __attribute__((constructor));
void ___freeenviron() __attribute__((destructor));

long amigaos_get_file(int fd);

// BOOL constructed;

#endif
