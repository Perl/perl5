/* $Header: util.h,v 3.0 89/10/18 15:35:41 lwall Locked $
 *
 *    Copyright (c) 1989, Larry Wall
 *
 *    You may distribute under the terms of the GNU General Public License
 *    as specified in the README file that comes with the perl 3.0 kit.
 *
 * $Log:	util.h,v $
 * Revision 3.0  89/10/18  15:35:41  lwall
 * 3.0 baseline
 * 
 */

/* is the string for makedir a directory name or a filename? */

#define MD_DIR 0
#define MD_FILE 1

void	util_init();
int	doshell();
char	*safemalloc();
char	*saferealloc();
char	*safecpy();
char	*safecat();
char	*cpytill();
char	*cpy2();
char	*instr();
#ifdef SETUIDGID
    int		eaccess();
#endif
char	*getwd();
void	cat();
void	prexit();
char	*get_a_line();
char	*savestr();
int	makedir();
void	setenv();
int	envix();
void	notincl();
char	*getval();
void	growstr();
void	setdef();
