#ifndef PERL_BEOS_BEOSISH_H
#define PERL_BEOS_BEOSISH_H

#include "unixish.h"

#undef  waitpid
#define waitpid beos_waitpid

/* This seems to be protoless. */
char *gcvt(double value, int num_digits, char *buffer);

#endif

