#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

void
xstest_something (char * some_thing)
{
	some_thing = some_thing;
}

void
xstest_something2 (char * some_thing)
{
	some_thing = some_thing;
}


MODULE = XSTest         PACKAGE = XSTest	PREFIX = xstest_

PROTOTYPES: DISABLE

int
is_even(input)
	int     input
    CODE:
	RETVAL = (input % 2 == 0);
    OUTPUT:
	RETVAL

void
xstest_something (class, some_thing)
	char * some_thing
    C_ARGS:
	some_thing

void
xstest_something2 (some_thing)
	char * some_thing

void
xstest_something3 (class, some_thing)
	SV   * class
	char * some_thing
    PREINIT:
    	int i;
    PPCODE:
    	/* it's up to us clear these warnings */
	class = class;
	some_thing = some_thing;
	i = i;
	XSRETURN_UNDEF;
	
int
consts (class)
	SV * class
    ALIAS:
	const_one = 1
	const_two = 2
	const_three = 3
    CODE:
    	/* it's up to us clear these warnings */
    	class = class;
	ix = ix;
    	RETVAL = 1;
    OUTPUT:
	RETVAL

