/*   perlshr.c
 * 
 *   Small stub to create object module containing global variables
 *   for use in PerlShr.C.  Written as a separate file because some
 *   old Make implementations won't deal correctly with DCL Open/Write
 *   statements in the makefile.
 *
 */

#include "INTERN.h"
#include "perl.h"

/* That's it. */
