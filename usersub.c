/* $Header: usersub.c,v 3.0.1.2 90/10/16 11:22:04 lwall Locked $
 *
 *  This file contains stubs for routines that the user may define to
 *  set up glue routines for C libraries or to decrypt encrypted scripts
 *  for execution.
 *
 * $Log:	usersub.c,v $
 * Revision 3.0.1.2  90/10/16  11:22:04  lwall
 * patch29: added waitpid
 * 
 * Revision 3.0.1.1  90/08/09  05:40:45  lwall
 * patch19: Initial revision
 * 
 */

#include "EXTERN.h"
#include "perl.h"

userinit()
{
    return 0;
}

/*
 * The following is supplied by John MacDonald as a means of decrypting
 * and executing (presumably proprietary) scripts that have been encrypted
 * by a (presumably secret) method.  The idea is that you supply your own
 * routine in place of cryptfilter (which is purposefully a very weak
 * encryption).  If an encrypted script is detected, a process is forked
 * off to run the cryptfilter routine as input to perl.
 */

#ifdef CRYPTSCRIPT

#include <signal.h>
#ifdef I_VFORK
#include <vfork.h>
#endif

#define	CRYPT_MAGIC_1	0xfb
#define	CRYPT_MAGIC_2	0xf1

cryptfilter( fil )
FILE *	fil;
{
    int    ch;

    while( (ch = getc( fil )) != EOF ) {
	putchar( (ch ^ 0x80) );
    }
}

#ifndef MSDOS
static FILE	*lastpipefile;
static int	pipepid;

#ifdef VOIDSIG
#  define	VOID	void
#else
#  define	VOID	int
#endif

FILE *
mypfiopen(fil,func)		/* open a pipe to function call for input */
FILE	*fil;
VOID	(*func)();
{
    int p[2];
    STR *str;

    if (pipe(p) < 0) {
	fclose( fil );
	fatal("Can't get pipe for decrypt");
    }

    /* make sure that the child doesn't get anything extra */
    fflush(stdout);
    fflush(stderr);

    while ((pipepid = fork()) < 0) {
	if (errno != EAGAIN) {
	    close(p[0]);
	    close(p[1]);
	    fclose( fil );
	    fatal("Can't fork for decrypt");
	}
	sleep(5);
    }
    if (pipepid == 0) {
	close(p[0]);
	if (p[1] != 1) {
	    dup2(p[1], 1);
	    close(p[1]);
	}
	(*func)(fil);
	fflush(stdout);
	fflush(stderr);
	_exit(0);
    }
    close(p[1]);
    fclose(fil);
    str = afetch(fdpid,p[0],TRUE);
    str->str_u.str_useful = pipepid;
    return fdopen(p[0], "r");
}

cryptswitch()
{
    int ch;
#ifdef STDSTDIO
    /* cheat on stdio if possible */
    if (rsfp->_cnt > 0 && (*rsfp->_ptr & 0xff) != CRYPT_MAGIC_1)
	return;
#endif
    ch = getc(rsfp);
    if (ch == CRYPT_MAGIC_1) {
	if (getc(rsfp) == CRYPT_MAGIC_2) {
	    rsfp = mypfiopen( rsfp, cryptfilter );
	    preprocess = 1;	/* force call to pclose when done */
	}
	else
	    fatal( "bad encryption format" );
    }
    else
	ungetc(ch,rsfp);
}

FILE *
cryptopen(cmd)		/* open a (possibly encrypted) program for input */
char	*cmd;
{
    FILE	*fil = fopen( cmd, "r" );

    lastpipefile = Nullfp;
    pipepid = 0;

    if( fil ) {
	int	ch = getc( fil );
	int	lines = 0;
	int	chars = 0;

	/* Search for the magic cookie that starts the encrypted script,
	** while still allowing a few lines of unencrypted text to let
	** '#!' and the nih hack both continue to work.  (These lines
	** will end up being ignored.)
	*/
	while( ch != CRYPT_MAGIC_1 && ch != EOF && lines < 5 && chars < 300 ) {
	    if( ch == '\n' )
		++lines;
	    ch = getc( fil );
	    ++chars;
	}

	if( ch == CRYPT_MAGIC_1 ) {
	    if( (ch = getc( fil ) ) == CRYPT_MAGIC_2 ) {
		if( perldb ) fatal("can't debug an encrypted script");
		/* we found it, decrypt the rest of the file */
		fil = mypfiopen( fil, cryptfilter );
		return( lastpipefile = fil );
	    } else
		/* if its got MAGIC 1 without MAGIC 2, too bad */
		fatal( "bad encryption format" );
	}

	/* this file is not encrypted - rewind and process it normally */
	rewind( fil );
    }

    return( fil );
}

VOID
cryptclose(fil)
FILE	*fil;
{
    if( fil == Nullfp )
	return;

    if( fil == lastpipefile )
	mypclose( fil );
    else
	fclose( fil );
}
#endif /* !MSDOS */

#endif /* CRYPTSCRIPT */
