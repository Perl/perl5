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

#ifdef OS2
    _response(&argc, &argv);
    _wildcard(&argc, &argv);
#endif

#ifdef VMS
    getredirection(&argc,&argv);
#endif

#if defined(HAS_SETLOCALE) && defined(LC_CTYPE)
    if (setlocale(LC_CTYPE, "") == NULL) {
        fprintf(stderr,
               "setlocale(LC_CTYPE, \"\") failed (LC_CTYPE = \"%s\").\n",
               getenv("LC_CTYPE"));
       exit(1);
    }
#endif

    if (!do_undump) {
	my_perl = perl_alloc();
	if (!my_perl)
	    exit(1);
	perl_construct( my_perl );
    }

    exitstatus = perl_parse( my_perl, xs_init, argc, argv, NULL );
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
