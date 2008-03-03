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

extern regexp*	my_regdupe (pTHX_ const regexp *r, CLONE_PARAMS *param);


END_EXTERN_C

/* engine details need to be paired - non debugging, debugging  */
#define NEEDS_DEBUGGING 0x01
struct regexp_engine {
    regexp*	(*regcomp) (pTHX_ char* exp, char* xend, PMOP* pm);
    I32		(*regexec) (pTHX_ regexp* prog, char* stringarg, char* strend,
			    char* strbeg, I32 minend, SV* screamer,
			    void* data, U32 flags);
    char*	(*re_intuit_start) (pTHX_ regexp *prog, SV *sv, char *strpos,
				    char *strend, U32 flags,
				    struct re_scream_pos_data_s *data);
    SV*		(*re_intuit_string) (pTHX_ regexp *prog);
    void	(*regfree) (pTHX_ struct regexp* r);
#if defined(USE_ITHREADS)
    regexp*	(*regdupe) (pTHX_ const regexp *r, CLONE_PARAMS *param);
#endif
};

struct regexp_engine engines[] = {
    { Perl_pregcomp, Perl_regexec_flags, Perl_re_intuit_start,
      Perl_re_intuit_string, Perl_pregfree
#if defined(USE_ITHREADS)
	, Perl_regdupe
#endif
    },
    { my_regcomp, my_regexec, my_re_intuit_start, my_re_intuit_string,
      my_regfree
#if defined(USE_ITHREADS)
      , my_regdupe
#endif
    }
};

#define MY_CXT_KEY "re::_guts" XS_VERSION

typedef struct {
    int		x_oldflag;		/* debug flag */
    unsigned int x_state;
} my_cxt_t;

START_MY_CXT

#define oldflag		(MY_CXT.x_oldflag)

static void
install(pTHX_ unsigned int new_state)
{
    dMY_CXT;
    const unsigned int states 
	= sizeof(engines) / sizeof(struct regexp_engine) -1;
    if(new_state == MY_CXT.x_state)
	return;

    if (new_state > states) {
	Perl_croak(aTHX_ "panic: re::install state %u is illegal - max is %u",
		   new_state, states);
    }

    PL_regexecp = engines[new_state].regexec;
    PL_regcompp = engines[new_state].regcomp;
    PL_regint_start = engines[new_state].re_intuit_start;
    PL_regint_string = engines[new_state].re_intuit_string;
    PL_regfree = engines[new_state].regfree;
#if defined(USE_ITHREADS)
    PL_regdupe = engines[new_state].regdupe;
#endif

    if (new_state & NEEDS_DEBUGGING) {
	PL_colorset = 0;	/* Allow reinspection of ENV. */
	if (!(MY_CXT.x_state & NEEDS_DEBUGGING)) {
	    /* Debugging is turned on for the first time.  */
	    oldflag = PL_debug & DEBUG_r_FLAG;
	    PL_debug |= DEBUG_r_FLAG;
	}
    } else {
	if (!(MY_CXT.x_state & NEEDS_DEBUGGING)) {
	    if (!oldflag)
		PL_debug &= ~DEBUG_r_FLAG;
	}
    }

    MY_CXT.x_state = new_state;
}

MODULE = re	PACKAGE = re

BOOT:
{
   MY_CXT_INIT;
}


void
install(new_state)
  unsigned int new_state;
  CODE:
    install(aTHX_ new_state);
