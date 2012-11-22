/*
 *	symbian_stubs.h
 *
 *	Copyright (c) Nokia 2004-2005.  All rights reserved.
 *      This code is licensed under the same terms as Perl itself.
 *
 */

#ifndef PERL_SYMBIAN_STUBS_H
#define PERL_SYMBIAN_STUBS_H

int execv(const char* path, char* const argv []);
int execvp(const char* path, char* const argv []);

int   pipe(int fd[2]);

#endif /* PERL_SYMBIAN_STUBS_H */

