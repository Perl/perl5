/* $Header: util.h,v 2.0 88/06/05 00:16:10 root Exp $
 *
 * $Log:	util.h,v $
 * Revision 2.0  88/06/05  00:16:10  root
 * Baseline version 2.0.
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
