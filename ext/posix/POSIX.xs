#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

MODULE = POSIX	PACKAGE = POSIX

FILE *
fdopen(fildes, type)
	fd		fildes
	char *		type
