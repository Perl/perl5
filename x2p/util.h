/* $RCSfile: util.h,v $$Revision: 4.1 $$Date: 92/08/07 18:29:30 $
 *
 *    Copyright (c) 1991, Larry Wall
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 * $Log:	util.h,v $
 */

/* is the string for makedir a directory name or a filename? */

#define fatal Myfatal

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
