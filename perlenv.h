#ifndef H_PERLENV
#define H_PERLENV 1

#ifdef PERL_OBJECT
#else
#define PerlEnv_putenv(str) putenv((str))
#define PerlEnv_getenv(str) getenv((str))
#endif	/* PERL_OBJECT */

#endif /* Include guard */
