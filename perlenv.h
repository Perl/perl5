#ifndef H_PERLENV
#define H_PERLENV 1

#ifdef PERL_OBJECT
#else
#define PerlENV_putenv(str) putenv((str))
#define PerlENV_getenv(str) getenv((str))
#endif	/* PERL_OBJECT */

#endif /* Include guard */
