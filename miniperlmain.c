/*
 * "The Road goes ever on and on, down from the door where it began."
 */

#ifdef __cplusplus
extern "C" {
#endif

#include "EXTERN.h"
#include "perl.h"

#ifdef __cplusplus
}
#  define EXTERN_C extern "C"
#else
#  define EXTERN_C extern
#endif

static void xs_init _((void));
static PerlInterpreter *my_perl;

int
perl_init_i18nl14n(printwarn)	/* XXX move to perl.c */
    int printwarn;
{
    int ok = 1;
    /* returns
     *    1 = set ok or not applicable,
     *    0 = fallback to C locale,
     *   -1 = fallback to C locale failed
     */
#if defined(HAS_SETLOCALE) && defined(LC_CTYPE)
    char * lang     = getenv("LANG");
    char * lc_all   = getenv("LC_ALL");
    char * lc_ctype = getenv("LC_CTYPE");
    int i;

    if (setlocale(LC_CTYPE, "") == NULL && (lc_all || lc_ctype || lang)) {
	if (printwarn) {
	    fprintf(stderr, "warning: setlocale(LC_CTYPE, \"\") failed.\n");
	    fprintf(stderr,
	      "warning: LC_ALL = \"%s\", LC_CTYPE = \"%s\", LANG = \"%s\",\n",
	      lc_all   ? lc_all   : "(null)",
	      lc_ctype ? lc_ctype : "(null)",
	      lang     ? lang     : "(null)"
	      );
	    fprintf(stderr, "warning: falling back to the \"C\" locale.\n");
	}
	ok = 0;
	if (setlocale(LC_CTYPE, "C") == NULL)
	    ok = -1;
    }

    for (i = 0; i < 256; i++) {
	if (isUPPER(i)) fold[i] = toLOWER(i);
	else if (isLOWER(i)) fold[i] = toUPPER(i);
	else fold[i] = i;
    }
#endif
    return ok;
}


int
#ifndef CAN_PROTOTYPE
main(argc, argv, env)
int argc;
char **argv;
char **env;
#else  /* def(CAN_PROTOTYPE) */
main(int argc, char **argv, char **env)
#endif  /* def(CAN_PROTOTYPE) */
{
    int exitstatus;

    PERL_SYS_INIT(&argc,&argv);

    perl_init_i18nl14n(1);

    if (!do_undump) {
	my_perl = perl_alloc();
	if (!my_perl)
	    exit(1);
	perl_construct( my_perl );
    }

    exitstatus = perl_parse( my_perl, xs_init, argc, argv, (char **) NULL );
    if (exitstatus)
	exit( exitstatus );

    exitstatus = perl_run( my_perl );

    perl_destruct( my_perl );
    perl_free( my_perl );

    exit( exitstatus );
}

/* Register any extra external extensions */

/* Do not delete this line--writemain depends on it */

static void
xs_init()
{
}
