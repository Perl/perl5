/* $Header: version.c,v 1.0 87/12/18 13:06:41 root Exp $
 *
 * $Log:	version.c,v $
 * Revision 1.0  87/12/18  13:06:41  root
 * Initial revision
 * 
 */

#include "patchlevel.h"

/* Print out the version number. */

version()
{
    extern char rcsid[];

    printf("%s\r\nPatch level: %d\r\n", rcsid, PATCHLEVEL);
}
