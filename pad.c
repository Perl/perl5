/*    pad.c
 *
 *    Copyright (c) 2002, Larry Wall
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
executing).

XSUBs don't have CvPADLIST set - dXSTARG fetches values from PL_curpad,
but that is really the callers pad (a slot of which is allocated by
every entersub).

The CvPADLIST AV has does not have AvREAL set, so REFCNT of component items
is managed "manual" (mostly in op.c) rather than normal av.c rules.
The items in the AV are not SVs as for a normal AV, but other AVs:

0'th Entry of the CvPADLIST is an AV which represents the "names" or rather
the "static type information" for lexicals.

The CvDEPTH'th entry of CvPADLIST AV is an AV which is the stack frame at that
depth of recursion into the CV.
The 0'th slot of a frame AV is an AV which is @_.
other entries are storage for variables and op targets.

During compilation:
C<PL_comppad_name> is set the the the names AV.
C<PL_comppad> is set the the frame AV for the frame CvDEPTH == 1.
C<PL_curpad> is set the body of the frame AV (i.e. AvARRAY(PL_comppad)).

Itterating over the names AV itterates over all possible pad
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

If SvFAKE is set on the name SV then slot in the frame AVs are
a REFCNT'ed references to a lexical from "outside".

If the 'name' is '&' the the corresponding entry in frame AV
is a CV representing a possible closure.
(SvFAKE and name of '&' is not a meaningful combination currently but could
become so if C<my sub foo {}> is implemented.)

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
#ifdef USE_5005THREADS
	av_store(padname, 0, newSVpvn("@_", 2));
	a0 = newAV();
	SvPADMY_on((SV*)a0);		/* XXX Needed? */
	av_store(pad, 0, (SV*)a0);
#else
	av_store(pad, 0, Nullsv);
#endif /* USE_THREADS */
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
    }

    DEBUG_X(PerlIO_printf(Perl_debug_log,
	  "Pad 0x%"UVxf"[0x%"UVxf"] new:       padlist=0x%"UVxf
	      " name=0x%"UVxf" flags=0x%"UVxf"\n",
	  PTR2UV(PL_comppad), PTR2UV(PL_curpad), PTR2UV(padlist),
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
inner subs to outercv.

=cut
*/

void
Perl_pad_undef(pTHX_ CV* cv, CV* outercv)
{
    I32 ix;
    PADLIST *padlist = CvPADLIST(cv);

    if (!padlist)
	return;
    if (!SvREFCNT(CvPADLIST(cv))) /* may be during global destruction */
	return;

    DEBUG_X(PerlIO_printf(Perl_debug_log,
	  "Pad undef: padlist=0x%"UVxf"\n" , PTR2UV(padlist))
    );

    /* pads may be cleared out already during global destruction */
    if ((CvEVAL(cv) && !CvGV(cv) /* is this eval"" ? */
	    && !PL_dirty) || CvSPECIAL(cv))
    {
	/* XXX DAPM the following code is very similar to
	 * pad_fixup_inner_anons(). Merge??? */

	/* inner references to eval's cv must be fixed up */
	AV *comppad_name = (AV*)AvARRAY(padlist)[0];
	SV **namepad = AvARRAY(comppad_name);
	AV *comppad = (AV*)AvARRAY(padlist)[1];
	SV **curpad = AvARRAY(comppad);
	for (ix = AvFILLp(comppad_name); ix > 0; ix--) {
	    SV *namesv = namepad[ix];
	    if (namesv && namesv != &PL_sv_undef
		&& *SvPVX(namesv) == '&'
		&& ix <= AvFILLp(comppad))
	    {
		CV *innercv = (CV*)curpad[ix];
		if (innercv && SvTYPE(innercv) == SVt_PVCV
		    && CvOUTSIDE(innercv) == cv)
		{
		    CvOUTSIDE(innercv) = outercv;
		    if (!CvANON(innercv) || CvCLONED(innercv)) {
			(void)SvREFCNT_inc(outercv);
			if (SvREFCNT(cv))
			    SvREFCNT_dec(cv);
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
	    PL_comppad = Nullav;
	    PL_curpad = Null(SV**);
	}
	SvREFCNT_dec(sv);
    }
    SvREFCNT_dec((SV*)CvPADLIST(cv));
    CvPADLIST(cv) = Null(PADLIST*);
}




/*
=for apidoc pad_add_name

Create a new name in the current pad at the specified offset.
If C<typestash> is valid, the name is for a typed lexical; set the
name's stash to that value.
If C<ourstash> is valid, it's an our lexical, set the name's
GvSTASH to that value

Also, if the name is @.. or %.., create a new array or hash for that slot

If fake, it means we're cloning an existing entry

=cut
*/

/*
 * XXX DAPM this doesn't seem the right place to create a new array/hash.
 * Whatever we do, we should be consistent - create scalars too, and
 * create even if fake. Really need to integrate better the whole entry
 * creation business - when + where does the name and value get created?
 */

PADOFFSET
Perl_pad_add_name(pTHX_ char *name, HV* typestash, HV* ourstash, bool fake)
{
    PADOFFSET offset = pad_alloc(OP_PADSV, SVs_PADMY);
    SV* namesv = NEWSV(1102, 0);
    U32 min, max;

    if (fake) {
	min = PL_curcop->cop_seq;
	max = PAD_MAX;
    }
    else {
	/* not yet introduced */
	min = PAD_MAX;
	max = 0;
    }

    DEBUG_Xv(PerlIO_printf(Perl_debug_log,
	  "Pad addname: %ld \"%s\", (%lu,%lu)%s\n",
	   (long)offset, name, (unsigned long)min, (unsigned long)max,
	  (fake ? " FAKE" : "")
	  )
    );

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
    SvNVX(namesv) = (NV)min;
    SvIVX(namesv) = max;
    if (fake)
	SvFAKE_on(namesv);
    else {
	if (!PL_min_intro_pending)
	    PL_min_intro_pending = offset;
	PL_max_intro_pending = offset;
	if (*name == '@')
	    av_store(PL_comppad, offset, (SV*)newAV());
	else if (*name == '%')
	    av_store(PL_comppad, offset, (SV*)newHV());
	SvPADMY_on(PL_curpad[offset]);
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

    if (AvARRAY(PL_comppad) != PL_curpad)
	Perl_croak(aTHX_ "panic: pad_alloc");
    if (PL_pad_reset_pending)
	pad_reset();
    if (tmptype & SVs_PADMY) {
	do {
	    sv = *av_fetch(PL_comppad, AvFILLp(PL_comppad) + 1, TRUE);
	} while (SvPADBUSY(sv));		/* need a fresh one */
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
    av_store(PL_comppad, ix, sv);
    SvPADMY_on(sv);
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
    I32 off;
    I32 pendoff = 0;
    SV *sv;
    SV **svp = AvARRAY(PL_comppad_name);
    U32 seq = PL_cop_seqmax;
    PERL_CONTEXT *cx;
    CV *outside;

    DEBUG_Xv(PerlIO_printf(Perl_debug_log, "Pad findmy:  \"%s\"\n", name));

#ifdef USE_5005THREADS
    /*
     * Special case to get lexical (and hence per-thread) @_.
     * XXX I need to find out how to tell at parse-time whether use
     * of @_ should refer to a lexical (from a sub) or defgv (global
     * scope and maybe weird sub-ish things like formats). See
     * startsub in perly.y.  It's possible that @_ could be lexical
     * (at least from subs) even in non-threaded perl.
     */
    if (strEQ(name, "@_"))
	return 0;		/* success. (NOT_IN_PAD indicates failure) */
#endif /* USE_5005THREADS */

    /* The one we're looking for is probably just before comppad_name_fill. */
    for (off = AvFILLp(PL_comppad_name); off > 0; off--) {
	if ((sv = svp[off]) &&
	    sv != &PL_sv_undef &&
	    (!SvIVX(sv) ||
	     (seq <= (U32)SvIVX(sv) &&
	      seq > (U32)I_32(SvNVX(sv)))) &&
	    strEQ(SvPVX(sv), name))
	{
	    if (SvIVX(sv) || SvFLAGS(sv) & SVpad_OUR)
		return (PADOFFSET)off;
	    pendoff = off;	/* this pending def. will override import */
	}
    }

    outside = CvOUTSIDE(PL_compcv);

    /* Check if if we're compiling an eval'', and adjust seq to be the
     * eval's seq number.  This depends on eval'' having a non-null
     * CvOUTSIDE() while it is being compiled.  The eval'' itself is
     * identified by CvEVAL being true and CvGV being null. */
    if (outside && CvEVAL(PL_compcv) && !CvGV(PL_compcv) && cxstack_ix >= 0) {
	cx = &cxstack[cxstack_ix];
	if (CxREALEVAL(cx))
	    seq = cx->blk_oldcop->cop_seq;
    }

    /* See if it's in a nested scope */
    off = pad_findlex(name, 0, seq, outside, cxstack_ix, 0, 0);
    if (!off)			/* pad_findlex returns 0 for failure...*/
	return NOT_IN_PAD;	/* ...but we return NOT_IN_PAD for failure */

    /* If there is a pending local definition, this new alias must die */
    if (pendoff)
	SvIVX(AvARRAY(PL_comppad_name)[off]) = seq;
    return off;
}



/*
=for apidoc pad_findlex

Find a named lexical anywhere in a chain of nested pads. Add fake entries
in the inner pads if its found in an outer one.

If flags == FINDLEX_NOSEARCH we don't bother searching outer contexts.

=cut
*/

#define FINDLEX_NOSEARCH	1	/* don't search outer contexts */

STATIC PADOFFSET
S_pad_findlex(pTHX_ char *name, PADOFFSET newoff, U32 seq, CV* startcv,
	    I32 cx_ix, I32 saweval, U32 flags)
{
    CV *cv;
    I32 off;
    SV *sv;
    register I32 i;
    register PERL_CONTEXT *cx;

    DEBUG_Xv(PerlIO_printf(Perl_debug_log,
	"Pad findlex: \"%s\" off=%ld seq=%lu cv=0x%"UVxf
	    " ix=%ld saweval=%d flags=%lu\n",
	    name, (long)newoff, (unsigned long)seq, PTR2UV(startcv),
	    (long)cx_ix, (int)saweval, (unsigned long)flags
	)
    );

    for (cv = startcv; cv; cv = CvOUTSIDE(cv)) {
	AV *curlist = CvPADLIST(cv);
	SV **svp = av_fetch(curlist, 0, FALSE);
	AV *curname;

	DEBUG_Xv(PerlIO_printf(Perl_debug_log,
	    "             searching: cv=0x%"UVxf"\n", PTR2UV(cv))
	);

	if (!svp || *svp == &PL_sv_undef)
	    continue;
	curname = (AV*)*svp;
	svp = AvARRAY(curname);
	for (off = AvFILLp(curname); off > 0; off--) {
	    I32 depth;
	    AV *oldpad;
	    SV *oldsv;

	    if ( ! (
		    (sv = svp[off]) &&
		    sv != &PL_sv_undef &&
		    seq <= (U32)SvIVX(sv) &&
		    seq > (U32)I_32(SvNVX(sv)) &&
		    strEQ(SvPVX(sv), name))
	    )
		continue;

	    depth = CvDEPTH(cv);
	    if (!depth) {
		if (newoff) {
		    if (SvFAKE(sv))
			continue;
		    return 0; /* don't clone from inactive stack frame */
		}
		depth = 1;
	    }

	    oldpad = (AV*)AvARRAY(curlist)[depth];
	    oldsv = *av_fetch(oldpad, off, TRUE);

	    DEBUG_Xv(PerlIO_printf(Perl_debug_log,
			"             matched:   offset %ld"
			    " %s(%lu,%lu), sv=0x%"UVxf"\n",
			(long)off,
			SvFAKE(sv) ? "FAKE " : "",
			(unsigned long)I_32(SvNVX(sv)),
			(unsigned long)SvIVX(sv),
			PTR2UV(oldsv)
		    )
	    );

	    if (!newoff) {		/* Not a mere clone operation. */
		newoff = pad_add_name(
		    SvPVX(sv),
		    (SvFLAGS(sv) & SVpad_TYPED) ? SvSTASH(sv) : Nullhv,
		    (SvFLAGS(sv) & SVpad_OUR)   ? GvSTASH(sv) : Nullhv,
		    1  /* fake */
		);

		if (CvANON(PL_compcv) || SvTYPE(PL_compcv) == SVt_PVFM) {
		    /* "It's closures all the way down." */
		    CvCLONE_on(PL_compcv);
		    if (cv == startcv) {
			if (CvANON(PL_compcv))
			    oldsv = Nullsv; /* no need to keep ref */
		    }
		    else {
			CV *bcv;
			for (bcv = startcv;
			     bcv && bcv != cv && !CvCLONE(bcv);
			     bcv = CvOUTSIDE(bcv))
			{
			    if (CvANON(bcv)) {
				/* install the missing pad entry in intervening
				 * nested subs and mark them cloneable. */
				AV *ocomppad_name = PL_comppad_name;
				AV *ocomppad = PL_comppad;
				SV **ocurpad = PL_curpad;
				AV *padlist = CvPADLIST(bcv);
				PL_comppad_name = (AV*)AvARRAY(padlist)[0];
				PL_comppad = (AV*)AvARRAY(padlist)[1];
				PL_curpad = AvARRAY(PL_comppad);
				pad_add_name(
				    SvPVX(sv),
				    (SvFLAGS(sv) & SVpad_TYPED)
					? SvSTASH(sv) : Nullhv,
				    (SvFLAGS(sv) & SVpad_OUR)
					? GvSTASH(sv) : Nullhv,
				    1  /* fake */
				);

				PL_comppad_name = ocomppad_name;
				PL_comppad = ocomppad;
				PL_curpad = ocurpad;
				CvCLONE_on(bcv);
			    }
			    else {
				if (ckWARN(WARN_CLOSURE)
				    && !CvUNIQUE(bcv) && !CvUNIQUE(cv))
				{
				    Perl_warner(aTHX_ packWARN(WARN_CLOSURE),
				      "Variable \"%s\" may be unavailable",
					 name);
				}
				break;
			    }
			}
		    }
		}
		else if (!CvUNIQUE(PL_compcv)) {
		    if (ckWARN(WARN_CLOSURE) && !SvFAKE(sv) && !CvUNIQUE(cv)
			&& !(SvFLAGS(sv) & SVpad_OUR))
		    {
			Perl_warner(aTHX_ packWARN(WARN_CLOSURE),
			    "Variable \"%s\" will not stay shared", name);
		    }
		}
	    }
	    av_store(PL_comppad, newoff, SvREFCNT_inc(oldsv));
	    DEBUG_Xv(PerlIO_printf(Perl_debug_log,
			"Pad findlex: set offset %ld to sv 0x%"UVxf"\n",
			(long)newoff, PTR2UV(oldsv)
		    )
	    );
	    return newoff;
	}
    }

    if (flags & FINDLEX_NOSEARCH)
	return 0;

    /* Nothing in current lexical context--try eval's context, if any.
     * This is necessary to let the perldb get at lexically scoped variables.
     * XXX This will also probably interact badly with eval tree caching.
     */

    for (i = cx_ix; i >= 0; i--) {
	cx = &cxstack[i];
	switch (CxTYPE(cx)) {
	default:
	    if (i == 0 && saweval) {
		return pad_findlex(name, newoff, seq, PL_main_cv, -1, saweval, 0);
	    }
	    break;
	case CXt_EVAL:
	    switch (cx->blk_eval.old_op_type) {
	    case OP_ENTEREVAL:
		if (CxREALEVAL(cx)) {
		    PADOFFSET off;
		    saweval = i;
		    seq = cxstack[i].blk_oldcop->cop_seq;
		    startcv = cxstack[i].blk_eval.cv;
		    if (startcv && CvOUTSIDE(startcv)) {
			off = pad_findlex(name, newoff, seq, CvOUTSIDE(startcv),
					  i - 1, saweval, 0);
			if (off)	/* continue looking if not found here */
			    return off;
		    }
		}
		break;
	    case OP_DOFILE:
	    case OP_REQUIRE:
		/* require/do must have their own scope */
		return 0;
	    }
	    break;
	case CXt_FORMAT:
	case CXt_SUB:
	    if (!saweval)
		return 0;
	    cv = cx->blk_sub.cv;
	    if (PL_debstash && CvSTASH(cv) == PL_debstash) {	/* ignore DB'* scope */
		saweval = i;	/* so we know where we were called from */
		seq = cxstack[i].blk_oldcop->cop_seq;
		continue;
	    }
	    return pad_findlex(name, newoff, seq, cv, i - 1, saweval, FINDLEX_NOSEARCH);
	}
    }

    return 0;
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
#ifdef DEBUGGING
    /* for display purposes, try to guess the AV corresponding to
     * Pl_curpad */
    AV *cp = PL_comppad;
    if (cp && AvARRAY(cp) != PL_curpad)
	cp = Nullav;
#endif

#ifndef USE_5005THREADS
    if (!po)
	Perl_croak(aTHX_ "panic: pad_sv po");
#endif
    DEBUG_X(PerlIO_printf(Perl_debug_log,
	"Pad 0x%"UVxf"[0x%"UVxf"] sv:      %ld sv=0x%"UVxf"\n",
	PTR2UV(cp), PTR2UV(PL_curpad), (long)po, PTR2UV(PL_curpad[po]))
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
    /* for display purposes, try to guess the AV corresponding to
     * Pl_curpad */
    AV *cp = PL_comppad;
    if (cp && AvARRAY(cp) != PL_curpad)
	cp = Nullav;

    DEBUG_X(PerlIO_printf(Perl_debug_log,
	"Pad 0x%"UVxf"[0x%"UVxf"] setsv:   %ld sv=0x%"UVxf"\n",
	PTR2UV(cp), PTR2UV(PL_curpad), (long)po, PTR2UV(sv))
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

    if (! PL_min_intro_pending)
	return PL_cop_seqmax;

    svp = AvARRAY(PL_comppad_name);
    for (i = PL_min_intro_pending; i <= PL_max_intro_pending; i++) {
	if ((sv = svp[i]) && sv != &PL_sv_undef && !SvIVX(sv)) {
	    SvIVX(sv) = PAD_MAX;	/* Don't know scope end yet. */
	    SvNVX(sv) = (NV)PL_cop_seqmax;
	    DEBUG_Xv(PerlIO_printf(Perl_debug_log,
		"Pad intromy: %ld \"%s\", (%lu,%lu)\n",
		(long)i, SvPVX(sv),
		(unsigned long)I_32(SvNVX(sv)), (unsigned long)SvIVX(sv))
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

    if (PL_min_intro_pending && PL_comppad_name_fill < PL_min_intro_pending) {
	for (off = PL_max_intro_pending; off >= PL_min_intro_pending; off--) {
	    if ((sv = svp[off]) && sv != &PL_sv_undef && ckWARN_d(WARN_INTERNAL))
		Perl_warner(aTHX_ packWARN(WARN_INTERNAL),
					"%s never introduced", SvPVX(sv));
	}
    }
    /* "Deintroduce" my variables that are leaving with this scope. */
    for (off = AvFILLp(PL_comppad_name); off > PL_comppad_name_fill; off--) {
	if ((sv = svp[off]) && sv != &PL_sv_undef && SvIVX(sv) == PAD_MAX) {
	    SvIVX(sv) = PL_cop_seqmax;
	    DEBUG_Xv(PerlIO_printf(Perl_debug_log,
		"Pad leavemy: %ld \"%s\", (%lu,%lu)\n",
		(long)off, SvPVX(sv),
		(unsigned long)I_32(SvNVX(sv)), (unsigned long)SvIVX(sv))
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
	     * pad are references to outer lexicals and anonymous subs.
	     * The rest are created anew during cloning.
	     */
	    if (!((namesv = namep[ix]) != Nullsv &&
		  namesv != &PL_sv_undef &&
		  (SvFAKE(namesv) ||
		   *SvPVX(namesv) == '&')))
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
	if (!SvFAKE(PL_curpad[po]))
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
	    Perl_dump_indent(aTHX_ level+1, file,
		"%2d. 0x%"UVxf"<%lu> %s (%lu,%lu) \"%s\"\n",
		(int) ix,
		PTR2UV(ppad[ix]),
		(unsigned long) (ppad[ix] ? SvREFCNT(ppad[ix]) : 0),
		SvFAKE(namesv) ? "FAKE" : "    ",
		(unsigned long)I_32(SvNVX(namesv)),
		(unsigned long)SvIVX(namesv),
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
    CV *cv;

    LOCK_CRED_MUTEX;			/* XXX create separate mutex */
    cv = cv_clone2(proto, CvOUTSIDE(proto));
    UNLOCK_CRED_MUTEX;			/* XXX create separate mutex */
    return cv;
}


/* XXX DAPM separate out cv and paddish bits ???
 * ideally the CV-related stuff shouldn't be in pad.c - how about
 * a cv.c? */

STATIC CV *
S_cv_clone2(pTHX_ CV *proto, CV *outside)
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

    assert(!CvUNIQUE(proto));

    ENTER;
    SAVESPTR(PL_compcv);

    cv = PL_compcv = (CV*)NEWSV(1104, 0);
    sv_upgrade((SV *)cv, SvTYPE(proto));
    CvFLAGS(cv) = CvFLAGS(proto) & ~CVf_CLONE;
    CvCLONED_on(cv);

#ifdef USE_5005THREADS
    New(666, CvMUTEXP(cv), 1, perl_mutex);
    MUTEX_INIT(CvMUTEXP(cv));
    CvOWNER(cv)		= 0;
#endif /* USE_5005THREADS */
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
    if (outside)
	CvOUTSIDE(cv)	= (CV*)SvREFCNT_inc(outside);

    if (SvPOK(proto))
	sv_setpvn((SV*)cv, SvPVX(proto), SvCUR(proto));

    CvPADLIST(cv) = comppadlist = pad_new(padnew_CLONE|padnew_SAVE);

    for (ix = fname; ix >= 0; ix--)
	av_store(PL_comppad_name, ix, SvREFCNT_inc(pname[ix]));

    av_fill(PL_comppad, fpad);
    PL_curpad = AvARRAY(PL_comppad);

    for (ix = fpad; ix > 0; ix--) {
	SV* namesv = (ix <= fname) ? pname[ix] : Nullsv;
	if (namesv && namesv != &PL_sv_undef) {
	    char *name = SvPVX(namesv);    /* XXX */
	    if (SvFLAGS(namesv) & SVf_FAKE) {   /* lexical from outside? */
		I32 off = pad_findlex(name, ix, SvIVX(namesv),
				      CvOUTSIDE(cv), cxstack_ix, 0, 0);
		if (!off)
		    PL_curpad[ix] = SvREFCNT_inc(ppad[ix]);
		else if (off != ix)
		    Perl_croak(aTHX_ "panic: cv_clone: %s", name);
	    }
	    else {				/* our own lexical */
		SV* sv;
		if (*name == '&') {
		    /* anon code -- we'll come back for it */
		    sv = SvREFCNT_inc(ppad[ix]);
		}
		else if (*name == '@')
		    sv = (SV*)newAV();
		else if (*name == '%')
		    sv = (SV*)newHV();
		else
		    sv = NEWSV(0, 0);
		if (!SvPADBUSY(sv))
		    SvPADMY_on(sv);
		PL_curpad[ix] = sv;
	    }
	}
	else if (IS_PADGV(ppad[ix]) || IS_PADCONST(ppad[ix])) {
	    PL_curpad[ix] = SvREFCNT_inc(ppad[ix]);
	}
	else {
	    SV* sv = NEWSV(0, 0);
	    SvPADTMP_on(sv);
	    PL_curpad[ix] = sv;
	}
    }

    /* Now that vars are all in place, clone nested closures. */

    for (ix = fpad; ix > 0; ix--) {
	SV* namesv = (ix <= fname) ? pname[ix] : Nullsv;
	if (namesv
	    && namesv != &PL_sv_undef
	    && !(SvFLAGS(namesv) & SVf_FAKE)
	    && *SvPVX(namesv) == '&'
	    && CvCLONE(ppad[ix]))
	{
	    CV *kid = cv_clone2((CV*)ppad[ix], cv);
	    SvREFCNT_dec(ppad[ix]);
	    CvCLONE_on(kid);
	    SvPADMY_on(kid);
	    PL_curpad[ix] = (SV*)kid;
	}
    }

    DEBUG_Xv(
	PerlIO_printf(Perl_debug_log, "\nPad CV clone\n");
	cv_dump(outside, "Outside");
	cv_dump(proto,	 "Proto");
	cv_dump(cv,	 "To");
    );

    LEAVE;

    if (CvCONST(cv)) {
	SV* const_sv = op_const_sv(CvSTART(cv), cv);
	assert(const_sv);
	/* constant sub () { $x } closing over $x - see lib/constant.pm */
	SvREFCNT_dec(cv);
	cv = newCONSTSUB(CvSTASH(proto), 0, const_sv);
    }

    return cv;
}


/*
=for apidoc pad_fixup_inner_anons

For any anon CVs in the pad, change CvOUTSIDE of that CV from
old_cv to new_cv if necessary.

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
	    if (CvOUTSIDE(innercv) == old_cv) {
		CvOUTSIDE(innercv) = new_cv;
		if (!CvANON(innercv) || CvCLONED(innercv)) {
		    (void)SvREFCNT_inc(new_cv);
		    SvREFCNT_dec(old_cv);
		}
	    }
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
