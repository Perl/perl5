#define PERL_NO_GET_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "bsd_glob.h"

#define MY_CXT_KEY "File::Glob::_guts" XS_VERSION

typedef struct {
    int		x_GLOB_ERROR;
    HV *	x_GLOB_ITER;
    HV *	x_GLOB_ENTRIES;
} my_cxt_t;

START_MY_CXT

#define GLOB_ERROR	(MY_CXT.x_GLOB_ERROR)

#include "const-c.inc"

#ifdef WIN32
#define errfunc		NULL
#else
static int
errfunc(const char *foo, int bar) {
  PERL_UNUSED_ARG(foo);
  return !(bar == EACCES || bar == ENOENT || bar == ENOTDIR);
}
#endif

static void
doglob(pTHX_ const char *pattern, int flags)
{
    dSP;
    glob_t pglob;
    int i;
    int retval;
    SV *tmp;
    {
	dMY_CXT;

	/* call glob */
	memset(&pglob, 0, sizeof(glob_t));
	retval = bsd_glob(pattern, flags, errfunc, &pglob);
	GLOB_ERROR = retval;

	/* return any matches found */
	EXTEND(sp, pglob.gl_pathc);
	for (i = 0; i < pglob.gl_pathc; i++) {
	    /* printf("# bsd_glob: %s\n", pglob.gl_pathv[i]); */
	    tmp = newSVpvn_flags(pglob.gl_pathv[i], strlen(pglob.gl_pathv[i]),
				 SVs_TEMP);
	    TAINT;
	    SvTAINT(tmp);
	    PUSHs(tmp);
	}
	PUTBACK;

	bsd_globfree(&pglob);
    }
}

/* borrowed heavily from gsar's File::DosGlob, but translated into C */
static void
csh_glob(pTHX)
{
    dSP;
    dMY_CXT;

    SV *cxixsv = POPs;
    const char *cxixpv;
    STRLEN cxixlen;
    STRLEN len;
    const char *s = NULL;
    SV *itersv;
    SV *entriesv;
    AV *entries = NULL;
    U32 gimme = GIMME_V;
    SV *patsv = POPs;

    /* assume global context if not provided one */
    SvGETMAGIC(cxixsv);
    if (SvOK(cxixsv)) cxixpv = SvPV_nomg(cxixsv, cxixlen);
    else cxixpv = "_G_", cxixlen = 3;

    if (!MY_CXT.x_GLOB_ITER) MY_CXT.x_GLOB_ITER = newHV();
    itersv = *(hv_fetch(MY_CXT.x_GLOB_ITER, cxixpv, cxixlen, 1));
    if (!SvOK(itersv)) sv_setiv(itersv,0);

    if (!MY_CXT.x_GLOB_ENTRIES) MY_CXT.x_GLOB_ENTRIES = newHV();
    entriesv = *(hv_fetch(MY_CXT.x_GLOB_ENTRIES, cxixpv, cxixlen, 1));

    /* if we're just beginning, do it all first */
    if (!SvIV(itersv)) {
	const char *pat;
	AV *patav = NULL;
	const char *patend;
	const char *piece = NULL;
	SV *word = NULL;
	int const flags =
	    (int)SvIV(get_sv("File::Glob::DEFAULT_FLAGS", GV_ADD));
	bool is_utf8;

	/* glob without args defaults to $_ */
	SvGETMAGIC(patsv);
	if (
	    !SvOK(patsv)
	 && (patsv = DEFSV, SvGETMAGIC(patsv), !SvOK(patsv))
	)
	     pat = "", len = 0, is_utf8 = 0;
	else pat = SvPV_nomg(patsv,len), is_utf8 = !!SvUTF8(patsv);
	patend = pat + len;

	/* extract patterns */
	/* XXX this is needed for compatibility with the csh
	 * implementation in Perl.  Need to support a flag
	 * to disable this behavior.
	 */
	s = pat-1;
	while (++s < patend) {
	    switch (*s) {
	    case '\'':
	    case '"' :
	      {
		bool found = FALSE;
		if (!word) {
		    word = newSVpvs("");
		    if (is_utf8) SvUTF8_on(word);
		}
		if (piece) sv_catpvn(word, piece, s-piece);
		piece = s+1;
		while (++s <= patend)
		    if (*s == '\\') s++;
		    else if (*s == *(piece-1)) {
			sv_catpvn(word, piece, s-piece);
			piece = NULL;
			found = TRUE;
			break;
		    }
		if (!found) { /* unmatched quote */
		    /* Give up on tokenisation and treat the whole string
		       as a single token, but with whitespace stripped. */
		    piece = pat;
		    while (isSPACE(*pat)) pat++;
		    while (isSPACE(*(patend-1))) patend--;
		    /* bsd_glob expects a trailing null, but we cannot mod-
		       ify the original */
		    if (patend < SvEND(patsv)) {
			if (word) sv_setpvn(word, pat, patend-pat);
			else
			    word = newSVpvn_flags(
				pat, patend-pat, SVf_UTF8*is_utf8
			    );
			piece = NULL;
		    }
		    else {
			if (word) SvREFCNT_dec(word), word=NULL;
			piece = pat;
			s = patend;
		    }
		    goto end_of_parsing;
		}
		break;
	      }
	    case '\\': if (!piece) piece = s; s++; break;
	    default:
		if (isSPACE(*s)) {
		    if (piece) {
			if (!word) {
			    word = newSVpvn(piece,s-piece);
			    if (is_utf8) SvUTF8_on(word);
			}
			else sv_catpvn(word, piece, s-piece);
		    }
		    if (!word) break;
		    if (!patav) patav = (AV *)sv_2mortal((SV *)newAV());
		    av_push(patav, word);
		    word = NULL;
		    piece = NULL;
		}
		else if (!piece) piece = s;
		break;
	    }
	}
      end_of_parsing:

	assert(!SvROK(entriesv));
	entries = (AV *)newSVrv(entriesv,NULL);
	sv_upgrade((SV *)entries, SVt_PVAV);
	
	if (patav) {
	    I32 items = AvFILLp(patav) + 1;
	    SV **svp = AvARRAY(patav);
	    while (items--) {
		PUSHMARK(SP);
		PUTBACK;
		doglob(aTHX_ SvPVXx(*svp++), flags);
		SPAGAIN;
		{
		    dMARK;
		    dORIGMARK;
		    while (++MARK <= SP)
			av_push(entries, SvREFCNT_inc_simple_NN(*MARK));
		    SP = ORIGMARK;
		}
	    }
	}
	/* piece is set at this point if there is no trailing whitespace.
	   It is the beginning of the last token or quote-delimited
	   piece thereof.  word is set at this point if the last token has
	   multiple quoted pieces. */
	if (piece || word) {
	    if (word) {
		if (piece) sv_catpvn(word, piece, s-piece);
		piece = SvPVX(word);
	    }
	    PUSHMARK(SP);
	    PUTBACK;
	    doglob(aTHX_ piece, flags);
	    if (word) SvREFCNT_dec(word);
	    SPAGAIN;
	    {
		dMARK;
		dORIGMARK;
		/* short-circuit here for a fairly common case */
		if (!patav && gimme == G_ARRAY) goto return_list;
		while (++MARK <= SP)
		    av_push(entries, SvREFCNT_inc_simple_NN(*MARK));

		SP = ORIGMARK;
	    }
	}
    }

    /* chuck it all out, quick or slow */
    assert(SvROK(entriesv));
    if (!entries) entries = (AV *)SvRV(entriesv);
    if (gimme == G_ARRAY) {
	Copy(AvARRAY(entries), SP+1, AvFILLp(entries)+1, SV *);
	SP += AvFILLp(entries)+1;
      return_list:
	hv_delete(MY_CXT.x_GLOB_ITER, cxixpv, cxixlen, G_DISCARD);
	/* No G_DISCARD here!  It will free the stack items. */
	hv_delete(MY_CXT.x_GLOB_ENTRIES, cxixpv, cxixlen, 0);
    }
    else {
	if (AvFILLp(entries) + 1) {
	    sv_setiv(itersv, AvFILLp(entries) + 1);
	    mPUSHs(av_shift(entries));
	}
	else {
	    /* return undef for EOL */
	    hv_delete(MY_CXT.x_GLOB_ITER, cxixpv, cxixlen, G_DISCARD);
	    hv_delete(MY_CXT.x_GLOB_ENTRIES, cxixpv, cxixlen, G_DISCARD);
	    PUSHs(&PL_sv_undef);
	}
    }
    PUTBACK;
}

MODULE = File::Glob		PACKAGE = File::Glob

int
GLOB_ERROR()
    PREINIT:
	dMY_CXT;
    CODE:
	RETVAL = GLOB_ERROR;
    OUTPUT:
	RETVAL

void
bsd_glob(pattern,...)
    char *pattern
PREINIT:
    glob_t pglob;
    int i;
    int retval;
    int flags = 0;
    SV *tmp;
PPCODE:
    {
	dMY_CXT;

	/* allow for optional flags argument */
	if (items > 1) {
	    flags = (int) SvIV(ST(1));
	    /* remove unsupported flags */
	    flags &= ~(GLOB_APPEND | GLOB_DOOFFS | GLOB_ALTDIRFUNC | GLOB_MAGCHAR);
	} else {
	    flags = (int) SvIV(get_sv("File::Glob::DEFAULT_FLAGS", GV_ADD));
	}
	
	PUTBACK;
	doglob(aTHX_ pattern, flags);
	SPAGAIN;
    }

PROTOTYPES: DISABLE
void
csh_glob(...)
PPCODE:
    /* For backward-compatibility with the original Perl function, we sim-
     * ply take the first two arguments, regardless of how many there are.
     */
    if (items >= 2) SP += 2;
    else {
	SP += items;
	XPUSHs(&PL_sv_undef);
	if (!items) XPUSHs(&PL_sv_undef);
    }
    PUTBACK;
    csh_glob(aTHX);
    SPAGAIN;

BOOT:
{
#ifndef PERL_EXTERNAL_GLOB
    /* Don’t do this at home! The globhook interface is highly volatile. */
    PL_globhook = csh_glob;
#endif
}

BOOT:
{
    MY_CXT_INIT;
    {
	dMY_CXT;
	MY_CXT.x_GLOB_ITER = MY_CXT.x_GLOB_ENTRIES = NULL;
    }  
}

INCLUDE: const-xs.inc
