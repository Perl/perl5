/* $Header: usersub.c,v 3.0.1.1 90/08/09 04:06:10 lwall Locked $
 *
 * $Log:	usersub.c,v $
 * Revision 3.0.1.1  90/08/09  04:06:10  lwall
 * patch19: Initial revision
 * 
 */

#include "EXTERN.h"
#include "perl.h"

int
userinit()
{
    init_curses();
}

