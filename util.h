/* $Header: util.h,v 1.0 87/12/18 13:06:33 root Exp $
 *
 * $Log:	util.h,v $
 * Revision 1.0  87/12/18  13:06:33  root
 * Initial revision
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
void	PL_setenv();
int	envix();
void	notincl();
char	*getval();
void	growstr();
void	setdef();
