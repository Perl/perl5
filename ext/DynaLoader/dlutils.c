/* dlutils.c - handy functions and definitions for dl_*.xs files
 *
 * Currently this file is simply #included into dl_*.xs/.c files.
 * It should really be split into a dlutils.h and dlutils.c
 *
 */


/* pointer to allocated memory for last error message */
static char *LastError  = (char*)NULL;



#ifdef DEBUGGING
/* currently not connected to $DynaLoader::dl_error but should be */
static int dl_debug = 0;
#define DLDEBUG(level,code)	if(dl_debug>=level){ code; }
#else
#define DLDEBUG(level,code)
#endif


static void
dl_generic_private_init()	/* called by dl_*.xs dl_private_init() */
{
#ifdef DEBUGGING
    char *perl_dl_debug = getenv("PERL_DL_DEBUG");
    if (perl_dl_debug)
	dl_debug = atoi(perl_dl_debug);
#endif
}


/* SaveError() takes printf style args and saves the result in LastError */
#ifdef STANDARD_C
static void
SaveError(char* pat, ...)
#else
/*VARARGS0*/
static void
SaveError(pat, va_alist)
    char *pat;
    va_dcl
#endif
{
    va_list args;
    char *message;
    int len;

    /* This code is based on croak/warn but I'm not sure where mess() */
    /* gets its buffer space from! */

#ifdef I_STDARG
    va_start(args, pat);
#else
    va_start(args);
#endif
    message = mess(pat, &args);
    va_end(args);

    len = strlen(message) + 1 ;	/* include terminating null char */

    /* Allocate some memory for the error message */
    if (LastError)
        LastError = (char*)saferealloc(LastError, len) ;
    else
        LastError = safemalloc(len) ;

    /* Copy message into LastError (including terminating null char)	*/
    strncpy(LastError, message, len) ;
    DLDEBUG(2,fprintf(stderr,"DynaLoader: stored error msg '%s'\n",LastError));
}


/* prepend underscore to s. write into buf. return buf. */
char *
dl_add_underscore(s, buf)
char *s;
char *buf;
{
    *buf = '_';
    (void)strcpy(buf + 1, s);
    return buf;
}

