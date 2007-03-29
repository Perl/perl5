#if defined(PERL_EXT_RE_DEBUG) && !defined(DEBUGGING)
#  define DEBUGGING
#endif

#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "re_comp.h"


START_EXTERN_C

extern regexp*	my_re_compile (pTHX_ char* exp, char* xend, U32 pm_flags);
extern I32	my_regexec (pTHX_ regexp* prog, char* stringarg, char* strend,
			    char* strbeg, I32 minend, SV* screamer,
			    void* data, U32 flags);

extern char*	my_re_intuit_start (pTHX_ regexp *prog, SV *sv, char *strpos,
				    char *strend, U32 flags,
				    struct re_scream_pos_data_s *data);
extern SV*	my_re_intuit_string (pTHX_ regexp *prog);

extern void	my_regfree (pTHX_ struct regexp* r);
extern SV*      my_reg_numbered_buff_get(pTHX_ const REGEXP * const rx, I32 paren, SV* usesv);
extern SV*      my_reg_named_buff_get(pTHX_ const REGEXP * const rx, SV* namesv, U32 flags);
extern SV*      my_reg_qr_pkg(pTHX_ const REGEXP * const rx);
#if defined(USE_ITHREADS)
extern void*	my_regdupe (pTHX_ const regexp *r, CLONE_PARAMS *param);
#endif

EXTERN_C const struct regexp_engine my_reg_engine;

END_EXTERN_C

const struct regexp_engine my_reg_engine = { 
        my_re_compile, 
        my_regexec, 
        my_re_intuit_start, 
        my_re_intuit_string, 
        my_regfree, 
        my_reg_numbered_buff_get,
        my_reg_named_buff_get,
        my_reg_qr_pkg,
#if defined(USE_ITHREADS)
        my_regdupe 
#endif
};

regexp *
get_re_arg( pTHX_ SV *sv, U32 flags, MAGIC **mgp) {
    MAGIC *mg;
    if (sv) {
        if (SvMAGICAL(sv))
            mg_get(sv);
        if (SvROK(sv) &&
            (sv = (SV*)SvRV(sv)) &&     /* assign deliberate */
            SvTYPE(sv) == SVt_PVMG &&
            (mg = mg_find(sv, PERL_MAGIC_qr))) /* assign deliberate */
        {        
            if (mgp) *mgp = mg;
            return (regexp *)mg->mg_obj;       
        }
    }    
    if (mgp) *mgp = NULL;
    return ((flags && PL_curpm) ? PM_GETRE(PL_curpm) : NULL);
}

MODULE = re	PACKAGE = re

void
install()
    PPCODE:
        PL_colorset = 0;	/* Allow reinspection of ENV. */
        /* PL_debug |= DEBUG_r_FLAG; */
	XPUSHs(sv_2mortal(newSViv(PTR2IV(&my_reg_engine))));
	

void
regexp_pattern(sv)
    SV * sv
PROTOTYPE: $
PREINIT:
    MAGIC *mg;
    regexp *re;
PPCODE:
{
    /*
       Checks if a reference is a regex or not. If the parameter is
       not a ref, or is not the result of a qr// then returns false
       in scalar context and an empty list in list context.
       Otherwise in list context it returns the pattern and the
       modifiers, in scalar context it returns the pattern just as it
       would if the qr// was stringified normally, regardless as
       to the class of the variable and any strigification overloads
       on the object. 
    */

    if ( re = get_re_arg( aTHX_ sv, 0, &mg) ) /* assign deliberate */
    {
        /* Housten, we have a regex! */
        SV *pattern;
        STRLEN patlen = 0;
        STRLEN left = 0;
        char reflags[6];
        
        if ( GIMME_V == G_ARRAY ) {
            /*
               we are in list context so stringify
               the modifiers that apply. We ignore "negative
               modifiers" in this scenario. 
            */

            char *fptr = INT_PAT_MODS;
            char ch;
            U16 match_flags = (U16)((re->extflags & PMf_COMPILETIME) >> 12);

            while((ch = *fptr++)) {
                if(match_flags & 1) {
                    reflags[left++] = ch;
                }
                match_flags >>= 1;
            }

            pattern = sv_2mortal(newSVpvn(re->precomp,re->prelen));
            if (re->extflags & RXf_UTF8) SvUTF8_on(pattern);

            /* return the pattern and the modifiers */
            XPUSHs(pattern);
            XPUSHs(sv_2mortal(newSVpvn(reflags,left)));
            XSRETURN(2);
        } else {
            /* Scalar, so use the string that Perl would return */
            /* return the pattern in (?msix:..) format */
            pattern = sv_2mortal(newSVpvn(re->wrapped,re->wraplen));
            if (re->extflags & RXf_UTF8) 
                SvUTF8_on(pattern);
            XPUSHs(pattern);
            XSRETURN(1);
        }
    } else {
        /* It ain't a regexp folks */
        if ( GIMME_V == G_ARRAY ) {
            /* return the empty list */
            XSRETURN_UNDEF;
        } else {
            /* Because of the (?:..) wrapping involved in a 
               stringified pattern it is impossible to get a 
               result for a real regexp that would evaluate to 
               false. Therefore we can return PL_sv_no to signify
               that the object is not a regex, this means that one 
               can say
               
                 if (regex($might_be_a_regex) eq '(?:foo)') { }
               
               and not worry about undefined values.
            */
            XSRETURN_NO;
        }    
    }
    /* NOT-REACHED */
}


void
regmust(sv)
    SV * sv
PROTOTYPE: $
PREINIT:
    regexp *re;
PPCODE:
{
    if ( re = get_re_arg( aTHX_ sv, 0, 0) ) /* assign deliberate */
    {
        SV *an = &PL_sv_no;
        SV *fl = &PL_sv_no;
        if (re->anchored_substr) {
            an = newSVsv(re->anchored_substr);
        } else if (re->anchored_utf8) {
            an = newSVsv(re->anchored_utf8);
        }
        if (re->float_substr) {
            fl = newSVsv(re->float_substr);
        } else if (re->float_utf8) {
            fl = newSVsv(re->float_utf8);
        }
        XPUSHs(an);
        XPUSHs(fl);
        XSRETURN(2);
    }
    XSRETURN_UNDEF;
}

