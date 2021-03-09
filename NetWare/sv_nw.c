#include <EXTERN.h>
#define PERL_IN_SV_C
#include <perl.h>
#include <regcomp.h>

#define SV_CHECK_THINKFIRST(sv) if (SvTHINKFIRST(sv)) sv_force_normal_flags(sv, 0)



void
Perl_sv_catsv(pTHX_ SV *dstr, SV *sstr)
{
    sv_catsv_flags(dstr, sstr, SV_GMAGIC);
}

void
Perl_sv_catpvn(pTHX_ SV *dsv, const char* sstr, STRLEN slen)
{

    sv_catpvn_flags(dsv, sstr, slen, SV_GMAGIC);
}

void
Perl_sv_setsv(pTHX_ SV *dstr, SV *sstr)
{
    sv_setsv_flags(dstr, sstr, SV_GMAGIC);
}

char *
Perl_sv_2pv(pTHX_ SV *sv, STRLEN *lp)
{
    return sv_2pv_flags(sv, lp, SV_GMAGIC);
}

