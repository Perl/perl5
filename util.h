/* $Header: util.h,v 2.0 88/06/05 00:15:15 root Exp $
 *
 * $Log:	util.h,v $
 * Revision 2.0  88/06/05  00:15:15  root
 * Baseline version 2.0.
 * 
 */

int *screamfirst INIT(Null(int*));
int *screamnext INIT(Null(int*));
int *screamcount INIT(Null(int*));

char	*safemalloc();
char	*saferealloc();
char	*cpytill();
char	*instr();
char	*bminstr();
char	*fbminstr();
char	*screaminstr();
void	bmcompile();
void	fbmcompile();
char	*get_a_line();
char	*savestr();
void	setenv();
int	envix();
void	growstr();
