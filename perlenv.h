#ifndef H_PERLENV
#define H_PERLENV 1

#ifdef PERL_OBJECT

#include "ipenv.h"

#define PerlEnv_putenv(str)	    piENV->Putenv((str), ErrorNo())
#define PerlEnv_getenv(str)	    piENV->Getenv((str), ErrorNo())
#ifdef WIN32
#define PerlEnv_lib_path(str)	    piENV->LibPath((str))
#define PerlEnv_sitelib_path(str)   piENV->SiteLibPath((str))
#endif
#else
#define PerlEnv_putenv(str) putenv((str))
#define PerlEnv_getenv(str) getenv((str))
#endif	/* PERL_OBJECT */

#endif /* Include guard */
