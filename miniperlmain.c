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
i18nl14n()
{
  char * lang = getenv("LANG");
#if defined(HAS_SETLOCALE) && defined(LC_CTYPE)
  {
    char * lc_ctype = getenv("LC_CTYPE");
    int i;

    if (setlocale(LC_CTYPE, "") == NULL && (lc_ctype || lang)) {
      fprintf(stderr,
	      "warning: setlocale(LC_CTYPE, \"\") failed, LC_CTYPE = \"%s\", LANG = \"%s\",\n",
	      lc_ctype ? lc_ctype : "(null)",
	      lang     ? lang     : "(null)"
	      );
      fprintf(stderr,
	      "warning: falling back to the \"C\" locale.\n");
      setlocale(LC_CTYPE, "C");
    }

    for (i = 0; i < 256; i++) {
      if (isUPPER(i)) fold[i] = toLOWER(i);
      else if (isLOWER(i)) fold[i] = toUPPER(i);
      else fold[i] = i;
    }

  }
#endif
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

#ifdef OS2
    _response(&argc, &argv);
    _wildcard(&argc, &argv);
#endif

#ifdef VMS
    getredirection(&argc,&argv);
#endif

/* here a union of the cpp #if:s inside i18nl14n() */
#if (defined(HAS_SETLOCALE) && defined(LC_CTYPE))
    i18nl14n();
#endif

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
