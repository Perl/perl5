#if defined(PERL_EXT_RE_DEBUG) && !defined(DEBUGGING)
#  define DEBUGGING
#endif

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


START_EXTERN_C

extern regexp*	my_regcomp (pTHX_ char* exp, char* xend, PMOP* pm);
extern I32	my_regexec (pTHX_ regexp* prog, char* stringarg, char* strend,
			    char* strbeg, I32 minend, SV* screamer,
			    void* data, U32 flags);
extern void	my_regfree (pTHX_ struct regexp* r);
extern char*	my_re_intuit_start (pTHX_ regexp *prog, SV *sv, char *strpos,
				    char *strend, U32 flags,
				    struct re_scream_pos_data_s *data);
extern SV*	my_re_intuit_string (pTHX_ regexp *prog);

#if defined(USE_ITHREADS)
extern regexp*	my_regdupe (pTHX_ const regexp *r, CLONE_PARAMS *param);
#endif

const struct regexp_engine my_reg_engine = { 
        my_regcomp, 
        my_regexec, 
        my_re_intuit_start, 
        my_re_intuit_string, 
        my_regfree, 
#if defined(USE_ITHREADS)
        my_regdupe 
#endif
};

END_EXTERN_C

MODULE = re	PACKAGE = re

void
install()
    PPCODE:
        PL_colorset = 0;	/* Allow reinspection of ENV. */
        /* PL_debug |= DEBUG_r_FLAG; */
	XPUSHs(sv_2mortal(newSViv(PTR2IV(&my_reg_engine))));
	
