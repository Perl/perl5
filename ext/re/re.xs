#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

extern regexp*	my_regcomp _((char* exp, char* xend, PMOP* pm));
extern I32	my_regexec _((regexp* prog, char* stringarg, char* strend,
			      char* strbeg, I32 minend, SV* screamer,
			      void* data, U32 flags));

static int oldfl;

#define R_DB 512

static void
deinstall(void)
{
    regexecp = &regexec_flags;
    regcompp = &pregcomp;
    if (!oldfl)
	debug &= ~R_DB;
}

static void
install(void)
{
    regexecp = &my_regexec;
    regcompp = &my_regcomp;
    oldfl = debug & R_DB;
    debug |= R_DB;
}

MODULE = re	PACKAGE = re

void
install()

void
deinstall()
