/* $Header: util.h,v 3.0.1.1 89/10/26 23:28:25 lwall Locked $
 *
 *    Copyright (c) 1989, Larry Wall
 *
 *    You may distribute under the terms of the GNU General Public License
 *    as specified in the README file that comes with the perl 3.0 kit.
 *
 * $Log:	util.h,v $
 * Revision 3.0.1.1  89/10/26  23:28:25  lwall
 * patch1: declared bcopy if necessary
 * 
 * Revision 3.0  89/10/18  15:33:18  lwall
 * 3.0 baseline
 * 
 */

EXT int *screamfirst INIT(Null(int*));
EXT int *screamnext INIT(Null(int*));

char	*safemalloc();
char	*saferealloc();
char	*cpytill();
char	*instr();
char	*fbminstr();
char	*screaminstr();
void	fbmcompile();
char	*savestr();
void	setenv();
int	envix();
void	growstr();
char	*ninstr();
char	*rninstr();
char	*nsavestr();
FILE	*mypopen();
int	mypclose();
#ifndef BCOPY
#ifndef MEMCPY
char	*bcopy();
#endif
#endif
