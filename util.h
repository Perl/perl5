/* $Header: util.h,v 4.0 91/03/20 01:56:48 lwall Locked $
 *
 *    Copyright (c) 1989, Larry Wall
 *
 *    You may distribute under the terms of the GNU General Public License
 *    as specified in the README file that comes with the perl 3.0 kit.
 *
 * $Log:	util.h,v $
 * Revision 4.0  91/03/20  01:56:48  lwall
 * 4.0 baseline.
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
#ifndef HAS_MEMCPY
#ifndef HAS_BCOPY
char	*bcopy();
#endif
#ifndef HAS_BZERO
char	*bzero();
#endif
#endif
unsigned long scanoct();
unsigned long scanhex();
