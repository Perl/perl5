/*    pad.c
 *
 *    Copyright (C) 2002,2003 by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 *  "Anyway: there was this Mr Frodo left an orphan and stranded, as you
 *  might say, among those queer Bucklanders, being brought up anyhow in
 *  Brandy Hall. A regular warren, by all accounts. Old Master Gorbadoc
 *  never had fewer than a couple of hundred relations in the place. Mr
 *  Bilbo never did a kinder deed than when he brought the lad back to
 *  live among decent folk." --the Gaffer
 */

/* XXX DAPM
 * As of Sept 2002, this file is new and may be in a state of flux for
 * a while. I've marked things I intent to come back and look at further
 * with an 'XXX DAPM' comment.
 */

/*
=head1 Pad Data Structures

=for apidoc m|AV *|CvPADLIST|CV *cv
CV's can have CvPADLIST(cv) set to point to an AV.

For these purposes "forms" are a kind-of CV, eval""s are too (except they're
not callable at will and are always thrown away after the eval"" is done
executing). Require'd files are simply evals without any outer lexical
scope.

XSUBs don't have CvPADLIST set - dXSTARG fetches values from PL_curpad,
but that is really the callers pad (a slot of which is allocated by
every entersub).

The CvPADLIST AV has does not have AvREAL set, so REFCNT of component items
is managed "manual" (mostly in pad.c) rather than normal av.c rules.
The items in the AV are not SVs as for a normal AV, but other AVs:

0'th Entry of the CvPADLIST is an AV which represents the "names" or rather
the "static type information" for lexicals.

The CvDEPTH'th entry of CvPADLIST AV is an AV which is the stack frame at that
depth of recursion into the CV.
The 0'th slot of a frame AV is an AV which is @_.
other entries are storage for variables and op targets.

During compilation:
C<PL_comppad_name> is set to the names AV.
C<PL_comppad> is set to the frame AV for the frame CvDEPTH == 1.
C<PL_curpad> is set to the body of the frame AV (i.e. AvARRAY(PL_comppad)).

During execution, C<PL_comppad> and C<PL_curpad> refer to the live
frame of the currently executing sub.

Iterating over the names AV iterates over all possible pad
items. Pad slots that are SVs_PADTMP (targets/GVs/constants) end up having
&PL_sv_undef "names" (see pad_alloc()).

Only my/our variable (SVs_PADMY/SVs_PADOUR) slots get valid names.
The rest are op targets/GVs/constants which are statically allocated
or resolved at compile time.  These don't have names by which they
can be looked up from Perl code at run time through eval"" like
my/our variables can be.  Since they can't be looked up by "name"
but only by their index allocated at compile time (which is usually
in PL_op->op_targ), wasting a name SV for them doesn't make sense.

The SVs in the names AV have their PV being the name of the variable.
NV+1..IV inclusive is a range of cop_seq numbers for which the name is
valid.  For typed lexicals name SV is SVt_PVMG and SvSTASH points at the
type.  For C<our> lexicals, the type is SVt_PVGV, and GvSTASH points at the
stash of the associated global (so that duplicate C<our> delarations in the
same package can be detected).  SvCUR is sometimes hijacked to
store the generation number during compilation.

If SvFAKE is set on the name SV, then that slot in the frame AV is
a REFCNT'ed reference to a lexical from "outside". In this case,
the name SV does not use NVX and IVX to store a cop_seq range, since it is
in scope throughout. Instead IVX stores some flags containing info about
the real lexical (is it declared in an anon, and is it capable of being
instantiated multiple times?), and for fake ANONs, NVX contains the index
within the parent's pad where the lexical's value is stored, to make
cloning quicker.

If the 'name' is '&' the corresponding entry in frame AV
is a CV representing a possible closure.
(SvFAKE and name of '&' is not a meaningful combination currently but could
become so if C<my sub foo {}> is implemented.)

Note that formats are treated as anon subs, and are cloned each time
write is called (if necessary).

=cut
*/


#include "EXTERN.h"
#define PERL_IN_PAD_C
#include "perl.h"


#define PAD_MAX 999999999



/*
=for apidoc pad_new

Create a new compiling padlist, saving and updating the various global
vars at the same time as creating the pad itself. The following flags
can be OR'ed together:

    padnew_CLONE	this pad is for a cloned CV
    padnew_SAVE		save old globals
    padnew_SAVESUB	also save extra stuff for start of sub

=cut
*/

PADLIST *
Perl_pad_new(pTHX_ int flags)
{
    AV *padlist, *padname, *pad, *a0;

    ASSERT_CURPAD_LEGAL("pad_new");

    /* XXX DAPM really need a new SAVEt_PAD which restores all or most
     * vars (based on flags) rather than storing vals + addresses for
     * each individually. Also see pad_block_start.
     * XXX DAPM Try to see whether all these conditionals are required
     */

    /* save existing state, ... */

    if (flags & padnew_SAVE) {
	SAVECOMPPAD();
	SAVESPTR(PL_comppad_name);
	if (! (flags & padnew_CLONE)) {
	    SAVEI32(PL_padix);
	    SAVEI32(PL_comppad_name_fill);
	    SAVEI32(PL_min_intro_pending);
	    SAVEI32(PL_max_intro_pending);
	    SAVEI32(PL_cv_has_eval);
	    if (flags & padnew_SAVESUB) {
		SAVEI32(PL_pad_reset_pending);
	    }
	}
    }
    /* XXX DAPM interestingly, PL_comppad_name_floor never seems to be
     * saved - check at some pt that this is okay */

    /* ... create new pad ... */

    padlist	= newAV();
    padname	= newAV();
    pad		= newAV();

    if (flags & padnew_CLONE) {
	/* XXX DAPM  I dont know why cv_clone needs it
	 * doing differently yet - perhaps this separate branch can be
	 * dispensed with eventually ???
	 */

	a0 = newAV();			/* will be @_ */
	av_extend(a0, 0);
	av_store(pad, 0, (SV*)a0);
	AvFLAGS(a0) = AVf_REIFY;
    }
    else {
	av_store(pad, 0, Nullsv);
    }

    AvREAL_off(padlist);
    av_store(padlist, 0, (SV*)padname);
    av_store(padlist, 1, (SV*)pad);

    /* ... then update state variables */

    PL_comppad_name	= (AV*)(*av_fetch(padlist, 0, FALSE));
    PL_comppad		= (AV*)(*av_fetch(padlist, 1, FALSE));
    PL_curpad		= AvARRAY(PL_comppad);

    if (! (flags & padnew_CLONE)) {
	PL_comppad_name_fill = 0;
	PL_min_intro_pending = 0;
	PL_padix	     = 0;
	PL_cv_has_eval	     = 0;
    }

    DEBUG_X(PerlIO_printf(Perl_debug_log,
	  "Pad 0x%"UVxf"[0x%"UVxf"] new:       compcv=0x%"UVxf
	      " name=0x%"UVxf" flags=0x%"UVxf"\n",
	  PTR2UV(PL_comppad), PTR2UV(PL_curpad), PTR2UV(PL_compcv),
	      PTR2UV(padname), (UV)flags
	)
    );

    return (PADLIST*)padlist;
}

/*
=for apidoc pad_undef

Free the padlist associated with a CV.
If parts of it happen to be current, we null the relevant
PL_*pad* global vars so that we don't have any dangling references left.
We also repoint the CvOUTSIDE of any about-to-be-orphaned
inner subs to the outer of this cv.

(This function should really be called pad_free, but the name was already
taken)

=cut
*/

void
Perl_pad_undef(pTHX_ CV* cv)
{
    I32 ix;
    PADLIST *padlist = CvPADLIST(cv);

    if (!padlist)
	return;
    if (!SvREFCNT(CvPADLIST(cv))) /* may be during global destruction */
	return;

    DEBUG_X(PerlIO_printf(Perl_debug_log,
	  "Pad undef: cv=0x%"UVxf" padlist=0x%"UVxf"\n",
	    PTR2UV(cv), PTR2UV(padlist))
    );

    /* detach any '&' anon children in the pad; if afterwards they
     * are still live, fix up their CvOUTSIDEs to point to our outside,
     * bypassing us. */
    /* XXX DAPM for efficiency, we should only do this if we know we have
     * children, or integrate this loop with general cleanup */

    if (!PL_dirty) { /* don't bother during global destruction */
	CV *outercv = CvOUTSIDE(cv);
	U32 seq = CvOUTSIDE_SEQ(cv);
	AV *comppad_name = (AV*)AvARRAY(padlist)[0];
	SV **namepad = AvARRAY(comppad_name);
	AV *comppad = (AV*)AvARRAY(padlist)[1];
	SV **curpad = AvARRAY(comppad);
	for (ix = AvFILLp(comppad_name); ix > 0; ix--) {
	    SV *namesv = namepad[ix];
	    if (namesv && namesv != &PL_sv_undef
		&& *SvPVX(namesv) == '&')
	    {
		CV *innercv = (CV*)curpad[ix];
		namepad[ix] = Nullsv;
		SvREFCNT_dec(namesv);
		curpad[ix] = Nullsv;
		SvREFCNT_dec(innercv);
		if (SvREFCNT(innercv) /* in use, not just a prototype */
		    && CvOUTSIDE(innercv) == cv)
		{
		    assert(CvWEAKOUTSIDE(innercv));
		    /* don't relink to grandfather if he's being freed */
		    if (outercv && SvREFCNT(outercv)) {
			CvWEAKOUTSIDE_off(innercv);
			CvOUTSIDE(innercv) = outercv;
			CvOUTSIDE_SEQ(innercv) = seq;
			SvREFCNT_inc(outercv);
		    }
		    else {
			CvOUTSIDE(innercv) = Nullcv;
		    }

		}

	    }
	}
    }

    ix = AvFILLp(padlist);
    while (ix >= 0) {
	SV* sv = AvARRAY(padlist)[ix--];
	if (!sv)
	    continue;
	if (sv == (SV*)PL_comppad_name)
	    PL_comppad_name = Nullav;
	else if (sv == (SV*)PL_comppad) {
	    PL_comppad = Null(PAD*);
	    PL_curpad = Null(SV**);
	}
	SvREFCNT_dec(sv);
    }
    SvREFCNT_dec((SV*)CvPADLIST(cv));
    CvPADLIST(cv) = Null(PADLIST*);
}




/*
=for apidoc pad_add_name

Create a new name and associated PADMY SV in the current pad; return the
offset.
If C<typestash> is valid, the name is for a typed lexical; set the
name's stash to that value.
If C<ourstash> is valid, it's an our lexical, set the name's
GvSTASH to that value

If fake, it means we're cloning an existing entry

=cut
*/

PADOFFSET
Perl_pad_add_name(pTHX_ char *name, HV* typestash, HV* ourstash, bool fake)
{
    PADOFFSET offset = pad_alloc(OP_PADSV, SVs_PADMY);
    SV* namesv = NEWSV(1102, 0);

    ASSERT_CURPAD_ACTIVE("pad_add_name");


    sv_upgrade(namesv, ourstash ? SVt_PVGV : typestash ? SVt_PVMG : SVt_PVNV);
    sv_setpv(namesv, name);

    if (typestash) {
	SvFLAGS(namesv) |= SVpad_TYPED;
	SvSTASH(namesv) = (HV*)SvREFCNT_inc((SV*) typestash);
    }
    if (ourstash) {
	SvFLAGS(namesv) |= SVpad_OUR;
	GvSTASH(namesv) = (HV*)SvREFCNT_inc((SV*) ourstash);
    }

    av_store(PL_comppad_name, offset, namesv);
    if (fake) {
	SvFAKE_on(namesv);
	DEBUG_Xv(PerlIO_printf(Perl_debug_log,
	    "Pad addname: %ld \"%s\" FAKE\n", (long)offset, name));
    }
    else {
	/* not yet introduced */
	SvNVX(namesv) = (NV)PAD_MAX;	/* min */
	SvIVX(namesv) = 0;		/* max */

	if (!PL_min_intro_pending)
	    PL_min_intro_pending = offset;
	PL_max_intro_pending = offset;
	/* if it's not a simple scalar, replace with an AV or HV */
	/* XXX DAPM since slot has been allocated, replace
	 * av_store with PL_curpad[offset] ? */
	if (*name == '@')
	    av_store(PL_comppad, offset, (SV*)newAV());
	else if (*name == '%')
	    av_store(PL_comppad, offset, (SV*)newHV());
	SvPADMY_on(PL_curpad[offset]);
	DEBUG_Xv(PerlIO_printf(Perl_debug_log,
	    "Pad addname: %ld \"%s\" new lex=0x%"UVxf"\n",
	    (long)offset, name, PTR2UV(PL_curpad[offset])));
    }

    return offset;
}




/*
=for apidoc pad_alloc

Allocate a new my or tmp pad entry. For a my, simply push a null SV onto
the end of PL_comppad, but for a tmp, scan the pad from PL_padix upwards
for a slot which has no name and and no active value.

=cut
*/

/* XXX DAPM integrate alloc(), add_name() and add_anon(),
 * or at least rationalise ??? */


PADOFFSET
Perl_pad_alloc(pTHX_ I32 optype, U32 tmptype)
{
    SV *sv;
    I32 retval;

    ASSERT_CURPAD_ACTIVE("pad_alloc");

    if (AvARRAY(PL_comppad) != PL_curpad)
	Perl_croak(aTHX_ "panic: pad_alloc");
    if (PL_pad_reset_pending)
	pad_reset();
    if (tmptype & SVs_PADMY) {
	sv = *av_fetch(PL_comppad, AvFILLp(PL_comppad) + 1, TRUE);
	retval = AvFILLp(PL_comppad);
    }
    else {
	SV **names = AvARRAY(PL_comppad_name);
	SSize_t names_fill = AvFILLp(PL_comppad_name);
	for (;;) {
	    /*
	     * "foreach" index vars temporarily become aliases to non-"my"
	     * values.  Thus we must skip, not just pad values that are
	     * marked as current pad values, but also those with names.
	     */
	    /* HVDS why copy to sv here? we don't seem to use it */
	    if (++PL_padix <= names_fill &&
		   (sv = names[PL_padix]) && sv != &PL_sv_undef)
		continue;
	    sv = *av_fetch(PL_comppad, PL_padix, TRUE);
	    if (!(SvFLAGS(sv) & (SVs_PADTMP | SVs_PADMY)) &&
		!IS_PADGV(sv) && !IS_PADCONST(sv))
		break;
	}
	retval = PL_padix;
    }
    SvFLAGS(sv) |= tmptype;
    PL_curpad = AvARRAY(PL_comppad);

    DEBUG_X(PerlIO_printf(Perl_debug_log,
	  "Pad 0x%"UVxf"[0x%"UVxf"] alloc:   %ld for %s\n",
	  PTR2UV(PL_comppad), PTR2UV(PL_curpad), (long) retval,
	  PL_op_name[optype]));
    return (PADOFFSET)retval;
}

/*
=for apidoc pad_add_anon

Add an anon code entry to the current compiling pad

=cut
*/

PADOFFSET
Perl_pad_add_anon(pTHX_ SV* sv, OPCODE op_type)
{
    PADOFFSET ix;
    SV* name;

    name = NEWSV(1106, 0);
    sv_upgrade(name, SVt_PVNV);
    sv_setpvn(name, "&", 1);
    SvIVX(name) = -1;
    SvNVX(name) = 1;
    ix = pad_alloc(op_type, SVs_PADMY);
    av_store(PL_comppad_name, ix, name);
    /* XXX DAPM use PL_curpad[] ? */
    av_store(PL_comppad, ix, sv);
    SvPADMY_on(sv);

    /* to avoid ref loops, we never have parent + child referencing each
     * other simultaneously */
    if (CvOUTSIDE((CV*)sv)) {
	assert(!CvWEAKOUTSIDE((CV*)sv));
	CvWEAKOUTSIDE_on((CV*)sv);
	SvREFCNT_dec(CvOUTSIDE((CV*)sv));
    }
    return ix;
}



/*
=for apidoc pad_check_dup

Check for duplicate declarations: report any of:
     * a my in the current scope with the same name;
     * an our (anywhere in the pad) with the same name and the same stash
       as C<ourstash>
C<is_our> indicates that the name to check is an 'our' declaration

=cut
*/

/* XXX DAPM integrate this into pad_add_name ??? */

void
Perl_pad_check_dup(pTHX_ char *name, bool is_our, HV *ourstash)
{
    SV		**svp, *sv;
    PADOFFSET	top, off;

    ASSERT_CURPAD_ACTIVE("pad_check_dup");
    if (!ckWARN(WARN_MISC) || AvFILLp(PL_comppad_name) < 0)
	return; /* nothing to check */

    svp = AvARRAY(PL_comppad_name);
    top = AvFILLp(PL_comppad_name);
    /* check the current scope */
    /* XXX DAPM - why the (I32) cast - shouldn't we ensure they're the same
     * type ? */
    for (off = top; (I32)off > PL_comppad_name_floor; off--) {
	if ((sv = svp[off])
	    && sv != &PL_sv_undef
	    && !SvFAKE(sv)
	    && (SvIVX(sv) == PAD_MAX || SvIVX(sv) == 0)
	    && (!is_our
		|| ((SvFLAGS(sv) & SVpad_OUR) && GvSTASH(sv) == ourstash))
	    && strEQ(name, SvPVX(sv)))
	{
	    Perl_warner(aTHX_ packWARN(WARN_MISC),
		"\"%s\" variable %s masks earlier declaration in same %s",
		(is_our ? "our" : "my"),
		name,
		(SvIVX(sv) == PAD_MAX ? "scope" : "statement"));
	    --off;
	    break;
	}
    }
    /* check the rest of the pad */
    if (is_our) {
	do {
	    if ((sv = svp[off])
		&& sv != &PL_sv_undef
		&& !SvFAKE(sv)
		&& (SvIVX(sv) == PAD_MAX || SvIVX(sv) == 0)
		&& ((SvFLAGS(sv) & SVpad_OUR) && GvSTASH(sv) == ourstash)
		&& strEQ(name, SvPVX(sv)))
	    {
		Perl_warner(aTHX_ packWARN(WARN_MISC),
		    "\"our\" variable %s redeclared", name);
		Perl_warner(aTHX_ packWARN(WARN_MISC),
		    "\t(Did you mean \"local\" instead of \"our\"?)\n");
		break;
	    }
	} while ( off-- > 0 );
    }
}


/*
=for apidoc pad_findmy

Given a lexical name, try to find its offset, first in the current pad,
or failing that, in the pads of any lexically enclosing subs (including
the complications introduced by eval). If the name is found in an outer pad,
then a fake entry is added to the current pad.
Returns the offset in the current pad, or NOT_IN_PAD on failure.

=cut
*/

PADOFFSET
Perl_pad_findmy(pTHX_ char *name)
{
    SV *out_sv;
    int out_flags;
    I32 offset;
    AV *nameav;
    SV **name_svp;

    offset =  pad_findlex(name, PL_compcv, PL_cop_seqmax, 1,
		Null(SV**), &out_sv, &out_flags);
    if (offset != NOT_IN_PAD) 
	return offset;

    /* look for an our that's being introduced; this allows
     *    our $foo = 0 unless defined $foo;
     * to not give a warning. (Yes, this is a hack) */

    nameav = (AV*)AvARRAY(CvPADLIST(PL_compcv))[0];
    name_svp = AvARRAY(nameav);
    for (offset = AvFILLp(nameav); offset > 0; offset--) {
	SV *namesv = name_svp[offset];
	if (namesv && namesv != &PL_sv_undef
	    && !SvFAKE(namesv)
	    && (SvFLAGS(namesv) & SVpad_OUR)
	    && strEQ(SvPVX(namesv), name)
	    && U_32(SvNVX(namesv)) == PAD_MAX /* min */
	)
	    return offset;
    }
    return NOT_IN_PAD;
}


/*
=for apidoc pad_findlex

Find a named lexical anywhere in a chain of nested pads. Add fake entries
in the inner pads if it's found in an outer one.

Returns the offset in the bottom pad of the lex or the fake lex.
cv is the CV in which to start the search, and seq is the current cop_seq
to match against. If warn is true, print appropriate warnings.  The out_*
vars return values, and so are pointers to where the returned values
should be stored. out_capture, if non-null, requests that the innermost
instance of the lexical is captured; out_name_sv is set to the innermost
matched namesv or fake namesv; out_flags returns the flags normally
associated with the IVX field of a fake namesv.

Note that pad_findlex() is recursive; it recurses up the chain of CVs,
then comes back down, adding fake entries as it goes. It has to be this way
because fake namesvs in anon protoypes have to store in NVX the index into
the parent pad.

=cut
*/

/* Flags set in the SvIVX field of FAKE namesvs */

#define PAD_FAKELEX_ANON   1 /* the lex is declared in an ANON, or ... */
#define PAD_FAKELEX_MULTI  2 /* the lex can be instantiated multiple times */

/* the CV has finished being compiled. This is not a sufficient test for
 * all CVs (eg XSUBs), but suffices for the CVs found in a lexical chain */
#define CvCOMPILED(cv)	CvROOT(cv)

/* the CV does late binding of its lexicals */
#define CvLATE(cv) (CvANON(cv) || SvTYPE(cv) == SVt_PVFM)


STATIC PADOFFSET
S_pad_findlex(pTHX_ char *name, CV* cv, U32 seq, int warn,
	SV** out_capture, SV** out_name_sv, int *out_flags)
{
    I32 offset, new_offset;
    SV *new_capture;
    SV **new_capturep;
    AV *padlist = CvPADLIST(cv);

    *out_flags = 0;

    DEBUG_Xv(PerlIO_printf(Perl_debug_log,
	"Pad findlex cv=0x%"UVxf" searching \"%s\" seq=%d%s\n",
	PTR2UV(cv), name, (int)seq, out_capture ? " capturing" : "" ));

    /* first, search this pad */

    if (padlist) { /* not an undef CV */
	I32 fake_offset = 0;
	AV *nameav = (AV*)AvARRAY(padlist)[0];
	SV **name_svp = AvARRAY(nameav);

	for (offset = AvFILLp(nameav); offset > 0; offset--) {
	    SV *namesv = name_svp[offset];
	    if (namesv && namesv != &PL_sv_undef
		    && strEQ(SvPVX(namesv), name))
	    {
		if (SvFAKE(namesv))
		    fake_offset = offset; /* in case we don't find a real one */
		else if (  seq >  U_32(SvNVX(namesv))	/* min */
			&& seq <= (U32)SvIVX(namesv))	/* max */
		    break;
	    }
	}

	if (offset > 0 || fake_offset > 0 ) { /* a match! */
	    if (offset > 0) { /* not fake */
		fake_offset = 0;
		*out_name_sv = name_svp[offset]; /* return the namesv */

		/* set PAD_FAKELEX_MULTI if this lex can have multiple
		 * instances. For now, we just test !CvUNIQUE(cv), but
		 * ideally, we should detect my's declared within loops
		 * etc - this would allow a wider range of 'not stayed
		 * shared' warnings. We also treated alreadly-compiled
		 * lexes as not multi as viewed from evals. */

		*out_flags = CvANON(cv) ?
			PAD_FAKELEX_ANON :
			    (!CvUNIQUE(cv) && ! CvCOMPILED(cv))
				? PAD_FAKELEX_MULTI : 0;

		DEBUG_Xv(PerlIO_printf(Perl_debug_log,
		    "Pad findlex cv=0x%"UVxf" matched: offset=%ld (%ld,%ld)\n",
		    PTR2UV(cv), (long)offset, (long)U_32(SvNVX(*out_name_sv)),
		    (long)SvIVX(*out_name_sv)));
	    }
	    else { /* fake match */
		offset = fake_offset;
		*out_name_sv = name_svp[offset]; /* return the namesv */
		*out_flags = SvIVX(*out_name_sv);
		DEBUG_Xv(PerlIO_printf(Perl_debug_log,
		    "Pad findlex cv=0x%"UVxf" matched: offset=%ld flags=0x%lx index=%lu\n",
		    PTR2UV(cv), (long)offset, (unsigned long)*out_flags,
			(unsigned long)SvNVX(*out_name_sv) 
		));
	    }

	    /* return the lex? */

	    if (out_capture) {

		/* our ? */
		if ((SvFLAGS(*out_name_sv) & SVpad_OUR)) {
		    *out_capture = Nullsv;
		    return offset;
		}

		/* trying to capture from an anon prototype? */
		if (CvCOMPILED(cv)
			? CvANON(cv) && CvCLONE(cv) && !CvCLONED(cv)
			: *out_flags & PAD_FAKELEX_ANON)
		{
		    if (warn && ckWARN(WARN_CLOSURE))
			Perl_warner(aTHX_ packWARN(WARN_CLOSURE),
			    "Variable \"%s\" is not available", name);
		    *out_capture = Nullsv;
		}

		/* real value */
		else {
		    int newwarn = warn;
		    if (!CvCOMPILED(cv) && (*out_flags & PAD_FAKELEX_MULTI)
			 && warn && ckWARN(WARN_CLOSURE)) {
			newwarn = 0;
			Perl_warner(aTHX_ packWARN(WARN_CLOSURE),
			    "Variable \"%s\" will not stay shared", name);
		    }

		    if (fake_offset && CvANON(cv)
			    && CvCLONE(cv) &&!CvCLONED(cv))
		    {
			SV *n;
			/* not yet caught - look further up */
			DEBUG_Xv(PerlIO_printf(Perl_debug_log,
			    "Pad findlex cv=0x%"UVxf" chasing lex in outer pad\n",
			    PTR2UV(cv)));
			n = *out_name_sv;
			pad_findlex(name, CvOUTSIDE(cv), CvOUTSIDE_SEQ(cv),
			    newwarn, out_capture, out_name_sv, out_flags);
			*out_name_sv = n;
			return offset;
		    }

		    *out_capture = AvARRAY((AV*)AvARRAY(padlist)[
				    CvDEPTH(cv) ? CvDEPTH(cv) : 1])[offset];
		    DEBUG_Xv(PerlIO_printf(Perl_debug_log,
			"Pad findlex cv=0x%"UVxf" found lex=0x%"UVxf"\n",
			PTR2UV(cv), PTR2UV(*out_capture)));

		    if (SvPADSTALE(*out_capture)) {
			if (ckWARN(WARN_CLOSURE))
			    Perl_warner(aTHX_ packWARN(WARN_CLOSURE),
				"Variable \"%s\" is not available", name);
			*out_capture = Nullsv;
		    }
		}
		if (!*out_capture) {
		    if (*name == '@')
			*out_capture = sv_2mortal((SV*)newAV());
		    else if (*name == '%')
			*out_capture = sv_2mortal((SV*)newHV());
		    else
			*out_capture = sv_newmortal();
		}
	    }

	    return offset;
	}
    }

    /* it's not in this pad - try above */

    if (!CvOUTSIDE(cv))
	return NOT_IN_PAD;
    
    /* out_capture non-null means caller wants us to capture lex; in
     * addition we capture ourselves unless it's an ANON/format */
    new_capturep = out_capture ? out_capture :
		CvLATE(cv) ? Null(SV**) : &new_capture;

    offset = pad_findlex(name, CvOUTSIDE(cv), CvOUTSIDE_SEQ(cv), 1,
		new_capturep, out_name_sv, out_flags);
    if (offset == NOT_IN_PAD)
	return NOT_IN_PAD;
    
    /* found in an outer CV. Add appropriate fake entry to this pad */

    /* don't add new fake entries (via eval) to CVs that we have already
     * finished compiling, or to undef CVs */
    if (CvCOMPILED(cv) || !padlist)
	return 0; /* this dummy (and invalid) value isnt used by the caller */

    {
	SV *new_namesv;
	AV *ocomppad_name = PL_comppad_name;
	PAD *ocomppad = PL_comppad;
	PL_comppad_name = (AV*)AvARRAY(padlist)[0];
	PL_comppad = (AV*)AvARRAY(padlist)[1];
	PL_curpad = AvARRAY(PL_comppad);

	new_offset = pad_add_name(
	    SvPVX(*out_name_sv),
	    (SvFLAGS(*out_name_sv) & SVpad_TYPED)
		    ? SvSTASH(*out_name_sv) : Nullhv,
	    (SvFLAGS(*out_name_sv) & SVpad_OUR)
		    ? GvSTASH(*out_name_sv) : Nullhv,
	    1  /* fake */
	);

	new_namesv = AvARRAY(PL_comppad_name)[new_offset];
	SvIVX(new_namesv) = *out_flags;

	SvNVX(new_namesv) = (NV)0;
	if (SvFLAGS(new_namesv) & SVpad_OUR) {
	   /* do nothing */
	}
	else if (CvLATE(cv)) {
	    /* delayed creation - just note the offset within parent pad */
	    SvNVX(new_namesv) = (NV)offset;
	    CvCLONE_on(cv);
	}
	else {
	    /* immediate creation - capture outer value right now */
	    av_store(PL_comppad, new_offset, SvREFCNT_inc(*new_capturep));
	    DEBUG_Xv(PerlIO_printf(Perl_debug_log,
		"Pad findlex cv=0x%"UVxf" saved captured sv 0x%"UVxf" at offset %ld\n",
		PTR2UV(cv), PTR2UV(*new_capturep), (long)new_offset));
	}
	*out_name_sv = new_namesv;
	*out_flags = SvIVX(new_namesv);

	PL_comppad_name = ocomppad_name;
	PL_comppad = ocomppad;
	PL_curpad = ocomppad ? AvARRAY(ocomppad) : Null(SV **);
    }
    return new_offset;
}

		
/*
=for apidoc pad_sv

Get the value at offset po in the current pad.
Use macro PAD_SV instead of calling this function directly.

=cut
*/


SV *
Perl_pad_sv(pTHX_ PADOFFSET po)
{
    ASSERT_CURPAD_ACTIVE("pad_sv");

    if (!po)
	Perl_croak(aTHX_ "panic: pad_sv po");
    DEBUG_X(PerlIO_printf(Perl_debug_log,
	"Pad 0x%"UVxf"[0x%"UVxf"] sv:      %ld sv=0x%"UVxf"\n",
	PTR2UV(PL_comppad), PTR2UV(PL_curpad), (long)po, PTR2UV(PL_curpad[po]))
    );
    return PL_curpad[po];
}


/*
=for apidoc pad_setsv

Set the entry at offset po in the current pad to sv.
Use the macro PAD_SETSV() rather than calling this function directly.

=cut
*/

#ifdef DEBUGGING
void
Perl_pad_setsv(pTHX_ PADOFFSET po, SV* sv)
{
    ASSERT_CURPAD_ACTIVE("pad_setsv");

    DEBUG_X(PerlIO_printf(Perl_debug_log,
	"Pad 0x%"UVxf"[0x%"UVxf"] setsv:   %ld sv=0x%"UVxf"\n",
	PTR2UV(PL_comppad), PTR2UV(PL_curpad), (long)po, PTR2UV(sv))
    );
    PL_curpad[po] = sv;
}
#endif



/*
=for apidoc pad_block_start

Update the pad compilation state variables on entry to a new block

=cut
*/

/* XXX DAPM perhaps:
 * 	- integrate this in general state-saving routine ???
 * 	- combine with the state-saving going on in pad_new ???
 * 	- introduce a new SAVE type that does all this in one go ?
 */

void
Perl_pad_block_start(pTHX_ int full)
{
    ASSERT_CURPAD_ACTIVE("pad_block_start");
    SAVEI32(PL_comppad_name_floor);
    PL_comppad_name_floor = AvFILLp(PL_comppad_name);
    if (full)
	PL_comppad_name_fill = PL_comppad_name_floor;
    if (PL_comppad_name_floor < 0)
	PL_comppad_name_floor = 0;
    SAVEI32(PL_min_intro_pending);
    SAVEI32(PL_max_intro_pending);
    PL_min_intro_pending = 0;
    SAVEI32(PL_comppad_name_fill);
    SAVEI32(PL_padix_floor);
    PL_padix_floor = PL_padix;
    PL_pad_reset_pending = FALSE;
}


/*
=for apidoc intro_my

"Introduce" my variables to visible status.

=cut
*/

U32
Perl_intro_my(pTHX)
{
    SV **svp;
    SV *sv;
    I32 i;

    ASSERT_CURPAD_ACTIVE("intro_my");
    if (! PL_min_intro_pending)
	return PL_cop_seqmax;

    svp = AvARRAY(PL_comppad_name);
    for (i = PL_min_intro_pending; i <= PL_max_intro_pending; i++) {
	if ((sv = svp[i]) && sv != &PL_sv_undef
		&& !SvFAKE(sv) && !SvIVX(sv))
	{
	    SvIVX(sv) = PAD_MAX;	/* Don't know scope end yet. */
	    SvNVX(sv) = (NV)PL_cop_seqmax;
	    DEBUG_Xv(PerlIO_printf(Perl_debug_log,
		"Pad intromy: %ld \"%s\", (%ld,%ld)\n",
		(long)i, SvPVX(sv),
		(long)U_32(SvNVX(sv)), (long)SvIVX(sv))
	    );
	}
    }
    PL_min_intro_pending = 0;
    PL_comppad_name_fill = PL_max_intro_pending; /* Needn't search higher */
    DEBUG_Xv(PerlIO_printf(Perl_debug_log,
		"Pad intromy: seq -> %ld\n", (long)(PL_cop_seqmax+1)));

    return PL_cop_seqmax++;
}

/*
=for apidoc pad_leavemy

Cleanup at end of scope during compilation: set the max seq number for
lexicals in this scope and warn of any lexicals that never got introduced.

=cut
*/

void
Perl_pad_leavemy(pTHX)
{
    I32 off;
    SV **svp = AvARRAY(PL_comppad_name);
    SV *sv;

    PL_pad_reset_pending = FALSE;

    ASSERT_CURPAD_ACTIVE("pad_leavemy");
    if (PL_min_intro_pending && PL_comppad_name_fill < PL_min_intro_pending) {
	for (off = PL_max_intro_pending; off >= PL_min_intro_pending; off--) {
	    if ((sv = svp[off]) && sv != &PL_sv_undef
		    && !SvFAKE(sv) && ckWARN_d(WARN_INTERNAL))
		Perl_warner(aTHX_ packWARN(WARN_INTERNAL),
					"%"SVf" never introduced", sv);
	}
    }
    /* "Deintroduce" my variables that are leaving with this scope. */
    for (off = AvFILLp(PL_comppad_name); off > PL_comppad_name_fill; off--) {
	if ((sv = svp[off]) && sv != &PL_sv_undef
		&& !SvFAKE(sv) && SvIVX(sv) == PAD_MAX)
	{
	    SvIVX(sv) = PL_cop_seqmax;
	    DEBUG_Xv(PerlIO_printf(Perl_debug_log,
		"Pad leavemy: %ld \"%s\", (%ld,%ld)\n",
		(long)off, SvPVX(sv),
		(long)U_32(SvNVX(sv)), (long)SvIVX(sv))
	    );
	}
    }
    PL_cop_seqmax++;
    DEBUG_Xv(PerlIO_printf(Perl_debug_log,
	    "Pad leavemy: seq = %ld\n", (long)PL_cop_seqmax));
}


/*
=for apidoc pad_swipe

Abandon the tmp in the current pad at offset po and replace with a
new one.

=cut
*/

void
Perl_pad_swipe(pTHX_ PADOFFSET po, bool refadjust)
{
    ASSERT_CURPAD_LEGAL("pad_swipe");
    if (!PL_curpad)
	return;
    if (AvARRAY(PL_comppad) != PL_curpad)
	Perl_croak(aTHX_ "panic: pad_swipe curpad");
    if (!po)
	Perl_croak(aTHX_ "panic: pad_swipe po");

    DEBUG_X(PerlIO_printf(Perl_debug_log,
		"Pad 0x%"UVxf"[0x%"UVxf"] swipe:   %ld\n",
		PTR2UV(PL_comppad), PTR2UV(PL_curpad), (long)po));

    if (PL_curpad[po])
	SvPADTMP_off(PL_curpad[po]);
    if (refadjust)
	SvREFCNT_dec(PL_curpad[po]);

    PL_curpad[po] = NEWSV(1107,0);
    SvPADTMP_on(PL_curpad[po]);
    if ((I32)po < PL_padix)
	PL_padix = po - 1;
}


/*
=for apidoc pad_reset

Mark all the current temporaries for reuse

=cut
*/

/* XXX pad_reset() is currently disabled because it results in serious bugs.
 * It causes pad temp TARGs to be shared between OPs. Since TARGs are pushed
 * on the stack by OPs that use them, there are several ways to get an alias
 * to  a shared TARG.  Such an alias will change randomly and unpredictably.
 * We avoid doing this until we can think of a Better Way.
 * GSAR 97-10-29 */
void
Perl_pad_reset(pTHX)
{
#ifdef USE_BROKEN_PAD_RESET
    register I32 po;

    if (AvARRAY(PL_comppad) != PL_curpad)
	Perl_croak(aTHX_ "panic: pad_reset curpad");

    DEBUG_X(PerlIO_printf(Perl_debug_log,
	    "Pad 0x%"UVxf"[0x%"UVxf"] reset:     padix %ld -> %ld",
	    PTR2UV(PL_comppad), PTR2UV(PL_curpad),
		(long)PL_padix, (long)PL_padix_floor
	    )
    );

    if (!PL_tainting) {	/* Can't mix tainted and non-tainted temporaries. */
	for (po = AvMAX(PL_comppad); po > PL_padix_floor; po--) {
	    if (PL_curpad[po] && !SvIMMORTAL(PL_curpad[po]))
		SvPADTMP_off(PL_curpad[po]);
	}
	PL_padix = PL_padix_floor;
    }
#endif
    PL_pad_reset_pending = FALSE;
}


/*
=for apidoc pad_tidy

Tidy up a pad after we've finished compiling it:
    * remove most stuff from the pads of anonsub prototypes;
    * give it a @_;
    * mark tmps as such.

=cut
*/

/* XXX DAPM surely most of this stuff should be done properly
 * at the right time beforehand, rather than going around afterwards
 * cleaning up our mistakes ???
 */

void
Perl_pad_tidy(pTHX_ padtidy_type type)
{
    PADOFFSET ix;
    CV *cv;

    ASSERT_CURPAD_ACTIVE("pad_tidy");

    /* If this CV has had any 'eval-capable' ops planted in it
     * (ie it contains eval '...', //ee, /$var/ or /(?{..})/), Then any
     * anon prototypes in the chain of CVs should be marked as cloneable,
     * so that for example the eval's CV in C<< sub { eval '$x' } >> gets
     * the right CvOUTSIDE.
     * If running with -d, *any* sub may potentially have an eval
     * excuted within it.
     */

    if (PL_cv_has_eval || PL_perldb) {
	for (cv = PL_compcv ;cv; cv = CvOUTSIDE(cv)) {
	    if (cv != PL_compcv && CvCOMPILED(cv))
		break; /* no need to mark already-compiled code */
	    if (CvANON(cv)) {
		DEBUG_Xv(PerlIO_printf(Perl_debug_log,
		    "Pad clone on cv=0x%"UVxf"\n", PTR2UV(cv)));
		CvCLONE_on(cv);
	    }
	}
    }

    /* extend curpad to match namepad */
    if (AvFILLp(PL_comppad_name) < AvFILLp(PL_comppad))
	av_store(PL_comppad_name, AvFILLp(PL_comppad), Nullsv);

    if (type == padtidy_SUBCLONE) {
	SV **namep = AvARRAY(PL_comppad_name);

	for (ix = AvFILLp(PL_comppad); ix > 0; ix--) {
	    SV *namesv;

	    if (SvIMMORTAL(PL_curpad[ix]) || IS_PADGV(PL_curpad[ix]) || IS_PADCONST(PL_curpad[ix]))
		continue;
	    /*
	     * The only things that a clonable function needs in its
	     * pad are anonymous subs.
	     * The rest are created anew during cloning.
	     */
	    if (!((namesv = namep[ix]) != Nullsv &&
		  namesv != &PL_sv_undef &&
		   *SvPVX(namesv) == '&'))
	    {
		SvREFCNT_dec(PL_curpad[ix]);
		PL_curpad[ix] = Nullsv;
	    }
	}
    }
    else if (type == padtidy_SUB) {
	/* XXX DAPM this same bit of code keeps appearing !!! Rationalise? */
	AV *av = newAV();			/* Will be @_ */
	av_extend(av, 0);
	av_store(PL_comppad, 0, (SV*)av);
	AvFLAGS(av) = AVf_REIFY;
    }

    /* XXX DAPM rationalise these two similar branches */

    if (type == padtidy_SUB) {
	for (ix = AvFILLp(PL_comppad); ix > 0; ix--) {
	    if (SvIMMORTAL(PL_curpad[ix]) || IS_PADGV(PL_curpad[ix]) || IS_PADCONST(PL_curpad[ix]))
		continue;
	    if (!SvPADMY(PL_curpad[ix]))
		SvPADTMP_on(PL_curpad[ix]);
	}
    }
    else if (type == padtidy_FORMAT) {
	for (ix = AvFILLp(PL_comppad); ix > 0; ix--) {
	    if (!SvPADMY(PL_curpad[ix]) && !SvIMMORTAL(PL_curpad[ix]))
		SvPADTMP_on(PL_curpad[ix]);
	}
    }
    PL_curpad = AvARRAY(PL_comppad);
}


/*
=for apidoc pad_free

Free the SV at offet po in the current pad.

=cut
*/

/* XXX DAPM integrate with pad_swipe ???? */
void
Perl_pad_free(pTHX_ PADOFFSET po)
{
    ASSERT_CURPAD_LEGAL("pad_free");
    if (!PL_curpad)
	return;
    if (AvARRAY(PL_comppad) != PL_curpad)
	Perl_croak(aTHX_ "panic: pad_free curpad");
    if (!po)
	Perl_croak(aTHX_ "panic: pad_free po");

    DEBUG_X(PerlIO_printf(Perl_debug_log,
	    "Pad 0x%"UVxf"[0x%"UVxf"] free:    %ld\n",
	    PTR2UV(PL_comppad), PTR2UV(PL_curpad), (long)po)
    );

    if (PL_curpad[po] && PL_curpad[po] != &PL_sv_undef) {
	SvPADTMP_off(PL_curpad[po]);
#ifdef USE_ITHREADS
	/* SV could be a shared hash key (eg bugid #19022) */
	if (
#ifdef PERL_COPY_ON_WRITE
	    !SvIsCOW(PL_curpad[po])
#else
	    !SvFAKE(PL_curpad[po])
#endif
	    )
	    SvREADONLY_off(PL_curpad[po]);	/* could be a freed constant */
#endif
    }
    if ((I32)po < PL_padix)
	PL_padix = po - 1;
}



/*
=for apidoc do_dump_pad

Dump the contents of a padlist

=cut
*/

void
Perl_do_dump_pad(pTHX_ I32 level, PerlIO *file, PADLIST *padlist, int full)
{
    AV *pad_name;
    AV *pad;
    SV **pname;
    SV **ppad;
    SV *namesv;
    I32 ix;

    if (!padlist) {
	return;
    }
    pad_name = (AV*)*av_fetch((AV*)padlist, 0, FALSE);
    pad = (AV*)*av_fetch((AV*)padlist, 1, FALSE);
    pname = AvARRAY(pad_name);
    ppad = AvARRAY(pad);
    Perl_dump_indent(aTHX_ level, file,
	    "PADNAME = 0x%"UVxf"(0x%"UVxf") PAD = 0x%"UVxf"(0x%"UVxf")\n",
	    PTR2UV(pad_name), PTR2UV(pname), PTR2UV(pad), PTR2UV(ppad)
    );

    for (ix = 1; ix <= AvFILLp(pad_name); ix++) {
	namesv = pname[ix];
	if (namesv && namesv == &PL_sv_undef) {
	    namesv = Nullsv;
	}
	if (namesv) {
	    if (SvFAKE(namesv))
		Perl_dump_indent(aTHX_ level+1, file,
		    "%2d. 0x%"UVxf"<%lu> FAKE \"%s\" flags=0x%x index=%lu\n",
		    (int) ix,
		    PTR2UV(ppad[ix]),
		    (unsigned long) (ppad[ix] ? SvREFCNT(ppad[ix]) : 0),
		    SvPVX(namesv),
		    (unsigned long)SvIVX(namesv),
		    (unsigned long)SvNVX(namesv)

		);
	    else
		Perl_dump_indent(aTHX_ level+1, file,
		    "%2d. 0x%"UVxf"<%lu> (%ld,%ld) \"%s\"\n",
		    (int) ix,
		    PTR2UV(ppad[ix]),
		    (unsigned long) (ppad[ix] ? SvREFCNT(ppad[ix]) : 0),
		    (long)U_32(SvNVX(namesv)),
		    (long)SvIVX(namesv),
		    SvPVX(namesv)
		);
	}
	else if (full) {
	    Perl_dump_indent(aTHX_ level+1, file,
		"%2d. 0x%"UVxf"<%lu>\n",
		(int) ix,
		PTR2UV(ppad[ix]),
		(unsigned long) (ppad[ix] ? SvREFCNT(ppad[ix]) : 0)
	    );
	}
    }
}



/*
=for apidoc cv_dump

dump the contents of a CV

=cut
*/

#ifdef DEBUGGING
STATIC void
S_cv_dump(pTHX_ CV *cv, char *title)
{
    CV *outside = CvOUTSIDE(cv);
    AV* padlist = CvPADLIST(cv);

    PerlIO_printf(Perl_debug_log,
		  "  %s: CV=0x%"UVxf" (%s), OUTSIDE=0x%"UVxf" (%s)\n",
		  title,
		  PTR2UV(cv),
		  (CvANON(cv) ? "ANON"
		   : (SvTYPE(cv) == SVt_PVFM) ? "FORMAT"
		   : (cv == PL_main_cv) ? "MAIN"
		   : CvUNIQUE(cv) ? "UNIQUE"
		   : CvGV(cv) ? GvNAME(CvGV(cv)) : "UNDEFINED"),
		  PTR2UV(outside),
		  (!outside ? "null"
		   : CvANON(outside) ? "ANON"
		   : (outside == PL_main_cv) ? "MAIN"
		   : CvUNIQUE(outside) ? "UNIQUE"
		   : CvGV(outside) ? GvNAME(CvGV(outside)) : "UNDEFINED"));

    PerlIO_printf(Perl_debug_log,
		    "    PADLIST = 0x%"UVxf"\n", PTR2UV(padlist));
    do_dump_pad(1, Perl_debug_log, padlist, 1);
}
#endif /* DEBUGGING */





/*
=for apidoc cv_clone

Clone a CV: make a new CV which points to the same code etc, but which
has a newly-created pad built by copying the prototype pad and capturing
any outer lexicals.

=cut
*/

CV *
Perl_cv_clone(pTHX_ CV *proto)
{
    I32 ix;
    AV* protopadlist = CvPADLIST(proto);
    AV* protopad_name = (AV*)*av_fetch(protopadlist, 0, FALSE);
    AV* protopad = (AV*)*av_fetch(protopadlist, 1, FALSE);
    SV** pname = AvARRAY(protopad_name);
    SV** ppad = AvARRAY(protopad);
    I32 fname = AvFILLp(protopad_name);
    I32 fpad = AvFILLp(protopad);
    AV* comppadlist;
    CV* cv;
    SV** outpad;
    CV* outside;
    long depth;

    assert(!CvUNIQUE(proto));

    /* Since cloneable anon subs can be nested, CvOUTSIDE may point
     * to a prototype; we instead want the cloned parent who called us.
     * Note that in general for formats, CvOUTSIDE != find_runcv */

    outside = CvOUTSIDE(proto);
    if (outside && CvCLONE(outside) && ! CvCLONED(outside))
	outside = find_runcv(NULL);
    depth = CvDEPTH(outside);
    assert(depth || SvTYPE(proto) == SVt_PVFM);
    if (!depth)
	depth = 1;
    assert(CvPADLIST(outside));

    ENTER;
    SAVESPTR(PL_compcv);

    cv = PL_compcv = (CV*)NEWSV(1104, 0);
    sv_upgrade((SV *)cv, SvTYPE(proto));
    CvFLAGS(cv) = CvFLAGS(proto) & ~(CVf_CLONE|CVf_WEAKOUTSIDE);
    CvCLONED_on(cv);

#ifdef USE_ITHREADS
    CvFILE(cv)		= CvXSUB(proto) ? CvFILE(proto)
					: savepv(CvFILE(proto));
#else
    CvFILE(cv)		= CvFILE(proto);
#endif
    CvGV(cv)		= CvGV(proto);
    CvSTASH(cv)		= CvSTASH(proto);
    CvROOT(cv)		= OpREFCNT_inc(CvROOT(proto));
    CvSTART(cv)		= CvSTART(proto);
    CvOUTSIDE(cv)	= (CV*)SvREFCNT_inc(outside);
    CvOUTSIDE_SEQ(cv) = CvOUTSIDE_SEQ(proto);

    if (SvPOK(proto))
	sv_setpvn((SV*)cv, SvPVX(proto), SvCUR(proto));

    CvPADLIST(cv) = comppadlist = pad_new(padnew_CLONE|padnew_SAVE);

    av_fill(PL_comppad, fpad);
    for (ix = fname; ix >= 0; ix--)
	av_store(PL_comppad_name, ix, SvREFCNT_inc(pname[ix]));

    PL_curpad = AvARRAY(PL_comppad);

    outpad = AvARRAY(AvARRAY(CvPADLIST(outside))[depth]);

    for (ix = fpad; ix > 0; ix--) {
	SV* namesv = (ix <= fname) ? pname[ix] : Nullsv;
	SV *sv = Nullsv;
	if (namesv && namesv != &PL_sv_undef) { /* lexical */
	    if (SvFAKE(namesv)) {   /* lexical from outside? */
		sv = outpad[(I32)SvNVX(namesv)];
		assert(sv);
		/* formats may have an inactive parent */
		if (SvTYPE(proto) == SVt_PVFM && SvPADSTALE(sv)) {
		    if (ckWARN(WARN_CLOSURE))
			Perl_warner(aTHX_ packWARN(WARN_CLOSURE),
			    "Variable \"%s\" is not available", SvPVX(namesv));
		    sv = Nullsv;
		}
		else {
		    assert(!SvPADSTALE(sv));
		    sv = SvREFCNT_inc(sv);
		}
	    }
	    if (!sv) {
		char *name = SvPVX(namesv);
		if (*name == '&')
		    sv = SvREFCNT_inc(ppad[ix]);
		else if (*name == '@')
		    sv = (SV*)newAV();
		else if (*name == '%')
		    sv = (SV*)newHV();
		else
		    sv = NEWSV(0, 0);
		SvPADMY_on(sv);
	    }
	}
	else if (IS_PADGV(ppad[ix]) || IS_PADCONST(ppad[ix])) {
	    sv = SvREFCNT_inc(ppad[ix]);
	}
	else {
	    sv = NEWSV(0, 0);
	    SvPADTMP_on(sv);
	}
	PL_curpad[ix] = sv;
    }

    DEBUG_Xv(
	PerlIO_printf(Perl_debug_log, "\nPad CV clone\n");
	cv_dump(outside, "Outside");
	cv_dump(proto,	 "Proto");
	cv_dump(cv,	 "To");
    );

    LEAVE;

    if (CvCONST(cv)) {
	/* Constant sub () { $x } closing over $x - see lib/constant.pm:
	 * The prototype was marked as a candiate for const-ization,
	 * so try to grab the current const value, and if successful,
	 * turn into a const sub:
	 */
	SV* const_sv = op_const_sv(CvSTART(cv), cv);
	if (const_sv) {
	    SvREFCNT_dec(cv);
	    cv = newCONSTSUB(CvSTASH(proto), 0, const_sv);
	}
	else {
	    CvCONST_off(cv);
	}
    }

    return cv;
}


/*
=for apidoc pad_fixup_inner_anons

For any anon CVs in the pad, change CvOUTSIDE of that CV from
old_cv to new_cv if necessary. Needed when a newly-compiled CV has to be
moved to a pre-existing CV struct.

=cut
*/

void
Perl_pad_fixup_inner_anons(pTHX_ PADLIST *padlist, CV *old_cv, CV *new_cv)
{
    I32 ix;
    AV *comppad_name = (AV*)AvARRAY(padlist)[0];
    AV *comppad = (AV*)AvARRAY(padlist)[1];
    SV **namepad = AvARRAY(comppad_name);
    SV **curpad = AvARRAY(comppad);
    for (ix = AvFILLp(comppad_name); ix > 0; ix--) {
	SV *namesv = namepad[ix];
	if (namesv && namesv != &PL_sv_undef
	    && *SvPVX(namesv) == '&')
	{
	    CV *innercv = (CV*)curpad[ix];
	    assert(CvWEAKOUTSIDE(innercv));
	    assert(CvOUTSIDE(innercv) == old_cv);
	    CvOUTSIDE(innercv) = new_cv;
	}
    }
}


/*
=for apidoc pad_push

Push a new pad frame onto the padlist, unless there's already a pad at
this depth, in which case don't bother creating a new one.
If has_args is true, give the new pad an @_ in slot zero.

=cut
*/

void
Perl_pad_push(pTHX_ PADLIST *padlist, int depth, int has_args)
{
    if (depth <= AvFILLp(padlist))
	return;

    {
	SV** svp = AvARRAY(padlist);
	AV *newpad = newAV();
	SV **oldpad = AvARRAY(svp[depth-1]);
	I32 ix = AvFILLp((AV*)svp[1]);
	I32 names_fill = AvFILLp((AV*)svp[0]);
	SV** names = AvARRAY(svp[0]);
	SV* sv;
	for ( ;ix > 0; ix--) {
	    if (names_fill >= ix && names[ix] != &PL_sv_undef) {
		char *name = SvPVX(names[ix]);
		if ((SvFLAGS(names[ix]) & SVf_FAKE) || *name == '&') {
		    /* outer lexical or anon code */
		    av_store(newpad, ix, SvREFCNT_inc(oldpad[ix]));
		}
		else {		/* our own lexical */
		    if (*name == '@')
			av_store(newpad, ix, sv = (SV*)newAV());
		    else if (*name == '%')
			av_store(newpad, ix, sv = (SV*)newHV());
		    else
			av_store(newpad, ix, sv = NEWSV(0, 0));
		    SvPADMY_on(sv);
		}
	    }
	    else if (IS_PADGV(oldpad[ix]) || IS_PADCONST(oldpad[ix])) {
		av_store(newpad, ix, sv = SvREFCNT_inc(oldpad[ix]));
	    }
	    else {
		/* save temporaries on recursion? */
		av_store(newpad, ix, sv = NEWSV(0, 0));
		SvPADTMP_on(sv);
	    }
	}
	if (has_args) {
	    AV* av = newAV();
	    av_extend(av, 0);
	    av_store(newpad, 0, (SV*)av);
	    AvFLAGS(av) = AVf_REIFY;
	}
	av_store(padlist, depth, (SV*)newpad);
	AvFILLp(padlist) = depth;
    }
}
