/* $Header: version.c,v 2.0 88/06/05 00:15:21 root Exp $
 *
 * $Log:	version.c,v $
 * Revision 2.0  88/06/05  00:15:21  root
 * Baseline version 2.0.
 * 
 */

#include "patchlevel.h"

/* Print out the version number. */

version()
{
    extern char rcsid[];

    printf("%s\r\nPatch level: %d\r\n", rcsid, PATCHLEVEL);
}
