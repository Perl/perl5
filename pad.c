/*    pad.c
 *
 *    Copyright (C) 2002, 2003, 2004, 2005, 2006, 2007, 2008
 *    by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 */

/*
 *  'Anyway: there was this Mr. Frodo left an orphan and stranded, as you
 *   might say, among those queer Bucklanders, being brought up anyhow in
 *   Brandy Hall.  A regular warren, by all accounts.  Old Master Gorbadoc
 *   never had fewer than a couple of hundred relations in the place.
 *   Mr. Bilbo never did a kinder deed than when he brought the lad back
 *   to live among decent folk.'                           --the Gaffer
 *
 *     [p.23 of _The Lord of the Rings_, I/i: "A Long-Expected Party"]
 */

/* XXX DAPM
 * As of Sept 2002, this file is new and may be in a state of flux for
 * a while. I've marked things I intent to come back and look at further
 * with an 'XXX DAPM' comment.
 */

/*
=head1 Pad Data Structures

=for apidoc Amx|PADLIST *|CvPADLIST|CV *cv

CV's can have CvPADLIST(cv) set to point to a PADLIST.  This is the CV's
scratchpad, which stores lexical variables and opcode temporary and
per-thread values.

For these purposes "formats" are a kind-of CV; eval""s are too (except they're
not callable at will and are always thrown away after the eval"" is done
executing).  Require'd files are simply evals without any outer lexical
scope.

XSUBs don't have CvPADLIST set - dXSTARG fetches values from PL_curpad,
but that is really the callers pad (a slot of which is allocated by
every entersub).

The PADLIST has a C array where pads are stored.

The 0th entry of the PADLIST is a PADNAMELIST (which is actually just an
AV, but that may change) which represents the "names" or rather
the "static type information" for lexicals.  The individual elements of a
PADNAMELIST are PADNAMEs (just SVs; but, again, that may change).  Future
refactorings might stop the PADNAMELIST from being stored in the PADLIST's
array, so don't rely on it.  See L</PadlistNAMES>.

The CvDEPTH'th entry of a PADLIST is a PAD (an AV) which is the stack frame
at that depth of recursion into the CV.  The 0th slot of a frame AV is an
AV which is @_.  Other entries are storage for variables and op targets.

Iterating over the PADNAMELIST iterates over all possible pad
items.  Pad slots for targets (SVs_PADTMP) and GVs end up having &PL_sv_no
"names", while slots for constants have &PL_sv_no "names" (see
pad_alloc()).  That &PL_sv_no is used is an implementation detail subject
to change.  To test for it, use C<PadnamePV(name) && !PadnameLEN(name)>.

Only my/our variable (SvPADMY/PADNAME_isOUR) slots get valid names.
The rest are op targets/GVs/constants which are statically allocated
or resolved at compile time.  These don't have names by which they
can be looked up from Perl code at run time through eval"" the way
my/our variables can be.  Since they can't be looked up by "name"
but only by their index allocated at compile time (which is usually
in PL_op->op_targ), wasting a name SV for them doesn't make sense.

The SVs in the names AV have their PV being the name of the variable.
xlow+1..xhigh inclusive in the NV union is a range of cop_seq numbers for
which the name is valid (accessed through the macros COP_SEQ_RANGE_LOW and
_HIGH).  During compilation, these fields may hold the special value
PERL_PADSEQ_INTRO to indicate various stages:

   COP_SEQ_RANGE_LOW        _HIGH
   -----------------        -----
   PERL_PADSEQ_INTRO            0   variable not yet introduced:   { my ($x
   valid-seq#   PERL_PADSEQ_INTRO   variable in scope:             { my ($x)
   valid-seq#          valid-seq#   compilation of scope complete: { my ($x) }

For typed lexicals name SV is SVt_PVMG and SvSTASH
points at the type.  For C<our> lexicals, the type is also SVt_PVMG, with the
SvOURSTASH slot pointing at the stash of the associated global (so that
duplicate C<our> declarations in the same package can be detected).  SvUVX is
sometimes hijacked to store the generation number during compilation.

If PADNAME_OUTER (SvFAKE) is set on the
name SV, then that slot in the frame AV is
a REFCNT'ed reference to a lexical from "outside".  In this case,
the name SV does not use xlow and xhigh to store a cop_seq range, since it is
in scope throughout.  Instead xhigh stores some flags containing info about
the real lexical (is it declared in an anon, and is it capable of being
instantiated multiple times?), and for fake ANONs, xlow contains the index
within the parent's pad where the lexical's value is stored, to make
cloning quicker.

If the 'name' is '&' the corresponding entry in the PAD
is a CV representing a possible closure.
(PADNAME_OUTER and name of '&' is not a
meaningful combination currently but could
become so if C<my sub foo {}> is implemented.)

Note that formats are treated as anon subs, and are cloned each time
write is called (if necessary).

The flag SVs_PADSTALE is cleared on lexicals each time the my() is executed,
and set on scope exit.  This allows the
'Variable $x is not available' warning
to be generated in evals, such as

    { my $x = 1; sub f { eval '$x'} } f();

For state vars, SVs_PADSTALE is overloaded to mean 'not yet initialised'.

=for apidoc AmxU|PADNAMELIST *|PL_comppad_name

During compilation, this points to the array containing the names part
of the pad for the currently-compiling code.

=for apidoc AmxU|PAD *|PL_comppad

During compilation, this points to the array containing the values
part of the pad for the currently-compiling code.  (At runtime a CV may
have many such value arrays; at compile time just one is constructed.)
At runtime, this points to the array containing the currently-relevant
values for the pad for the currently-executing code.

=for apidoc AmxU|SV **|PL_curpad

Points directly to the body of the L</PL_comppad> array.
(I.e., this is C<PAD_ARRAY(PL_comppad)>.)

=cut
*/


#include "EXTERN.h"
#define PERL_IN_PAD_C
#include "perl.h"
#include "keywords.h"

#define COP_SEQ_RANGE_LOW_set(sv,val)		\
  STMT_START { ((XPVNV*)SvANY(sv))->xnv_u.xpad_cop_seq.xlow = (val); } STMT_END
#define COP_SEQ_RANGE_HIGH_set(sv,val)		\
  STMT_START { ((XPVNV*)SvANY(sv))->xnv_u.xpad_cop_seq.xhigh = (val); } STMT_END

#define PARENT_PAD_INDEX_set(sv,val)		\
  STMT_START { ((XPVNV*)SvANY(sv))->xnv_u.xpad_cop_seq.xlow = (val); } STMT_END
#define PARENT_FAKELEX_FLAGS_set(sv,val)	\
  STMT_START { ((XPVNV*)SvANY(sv))->xnv_u.xpad_cop_seq.xhigh = (val); } STMT_END

/*
=for apidoc mx|void|pad_peg|const char *s

When PERL_MAD is enabled, this is a small no-op function that gets called
at the start of each pad-related function.  It can be breakpointed to
track all pad operations.  The parameter is a string indicating the type
of pad operation being performed.

=cut
*/

#ifdef PERL_MAD
void pad_peg(const char* s) {
    static int pegcnt; /* XXX not threadsafe */
    PERL_UNUSED_ARG(s);

    PERL_ARGS_ASSERT_PAD_PEG;

    pegcnt++;
}
#endif

/*
This is basically sv_eq_flags() in sv.c, but we avoid the magic
and bytes checking.
*/

static bool
sv_eq_pvn_flags(pTHX_ const SV *sv, const char* pv, const STRLEN pvlen, const U32 flags) {
    if ( (SvUTF8(sv) & SVf_UTF8 ) != (flags & SVf_UTF8) ) {
        const char *pv1 = SvPVX_const(sv);
        STRLEN cur1     = SvCUR(sv);
        const char *pv2 = pv;
        STRLEN cur2     = pvlen;
	if (PL_encoding) {
              SV* svrecode = NULL;
	      if (SvUTF8(sv)) {
		   svrecode = newSVpvn(pv2, cur2);
		   sv_recode_to_utf8(svrecode, PL_encoding);
		   pv2      = SvPV_const(svrecode, cur2);
	      }
	      else {
		   svrecode = newSVpvn(pv1, cur1);
		   sv_recode_to_utf8(svrecode, PL_encoding);
		   pv1      = SvPV_const(svrecode, cur1);
	      }
              SvREFCNT_dec_NN(svrecode);
        }
        if (flags & SVf_UTF8)
            return (bytes_cmp_utf8(
                        (const U8*)pv1, cur1,
		        (const U8*)pv2, cur2) == 0);
        else
            return (bytes_cmp_utf8(
                        (const U8*)pv2, cur2,
		        (const U8*)pv1, cur1) == 0);
    }
    else
        return ((SvPVX_const(sv) == pv)
                    || memEQ(SvPVX_const(sv), pv, pvlen));
}


/*
=for apidoc Am|PADLIST *|pad_new|int flags

Create a new padlist, updating the global variables for the
currently-compiling padlist to point to the new padlist.  The following
flags can be OR'ed together:

    padnew_CLONE	this pad is for a cloned CV
    padnew_SAVE		save old globals on the save stack
    padnew_SAVESUB	also save extra stuff for start of sub

=cut
*/

PADLIST *
Perl_pad_new(pTHX_ int flags)
{
    dVAR;
    PADLIST *padlist;
    PAD *padname, *pad;
    PAD **ary;

    ASSERT_CURPAD_LEGAL("pad_new");

    /* XXX DAPM really need a new SAVEt_PAD which restores all or most
     * vars (based on flags) rather than storing vals + addresses for
     * each individually. Also see pad_block_start.
     * XXX DAPM Try to see whether all these conditionals are required
     */

    /* save existing state, ... */

    if (flags & padnew_SAVE) {
	SAVECOMPPAD();
	if (! (flags & padnew_CLONE)) {
	    SAVESPTR(PL_comppad_name);
	    SAVEI32(PL_padix);
	    SAVEI32(PL_comppad_name_fill);
	    SAVEI32(PL_min_intro_pending);
	    SAVEI32(PL_max_intro_pending);
	    SAVEBOOL(PL_cv_has_eval);
	    if (flags & padnew_SAVESUB) {
		SAVEBOOL(PL_pad_reset_pending);
	    }
	}
    }
    /* XXX DAPM interestingly, PL_comppad_name_floor never seems to be
     * saved - check at some pt that this is okay */

    /* ... create new pad ... */

    Newxz(padlist, 1, PADLIST);
    pad		= newAV();

    if (flags & padnew_CLONE) {
	/* XXX DAPM  I dont know why cv_clone needs it
	 * doing differently yet - perhaps this separate branch can be
	 * dispensed with eventually ???
	 */

        AV * const a0 = newAV();			/* will be @_ */
	av_store(pad, 0, MUTABLE_SV(a0));
	AvREIFY_only(a0);

	padname = (PAD *)SvREFCNT_inc_simple_NN(PL_comppad_name);
    }
    else {
	av_store(pad, 0, NULL);
	padname = newAV();
	AvPAD_NAMELIST_on(padname);
	av_store(padname, 0, &PL_sv_undef);
    }

    /* Most subroutines never recurse, hence only need 2 entries in the padlist
       array - names, and depth=1.  The default for av_store() is to allocate
       0..3, and even an explicit call to av_extend() with <3 will be rounded
       up, so we inline the allocation of the array here.  */
    Newx(ary, 2, PAD *);
    PadlistMAX(padlist) = 1;
    PadlistARRAY(padlist) = ary;
    ary[0] = padname;
    ary[1] = pad;

    /* ... then update state variables */

    PL_comppad		= pad;
    PL_curpad		= AvARRAY(pad);

    if (! (flags & padnew_CLONE)) {
	PL_comppad_name	     = padname;
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
=head1 Embedding Functions

=for apidoc cv_undef

Clear out all the active components of a CV.  This can happen either
by an explicit C<undef &foo>, or by the reference count going to zero.
In the former case, we keep the CvOUTSIDE pointer, so that any anonymous
children can still follow the full lexical scope chain.

=cut
*/

void
Perl_cv_undef(pTHX_ CV *cv)
{
    dVAR;
    const PADLIST *padlist = CvPADLIST(cv);
    bool const slabbed = !!CvSLABBED(cv);

    PERL_ARGS_ASSERT_CV_UNDEF;

    DEBUG_X(PerlIO_printf(Perl_debug_log,
	  "CV undef: cv=0x%"UVxf" comppad=0x%"UVxf"\n",
	    PTR2UV(cv), PTR2UV(PL_comppad))
    );

    if (CvFILE(cv) && CvDYNFILE(cv)) {
	Safefree(CvFILE(cv));
    }
    CvFILE(cv) = NULL;

    CvSLABBED_off(cv);
    if (!CvISXSUB(cv) && CvROOT(cv)) {
	if (SvTYPE(cv) == SVt_PVCV && CvDEPTH(cv))
	    Perl_croak(aTHX_ "Can't undef active subroutine");
	ENTER;

	PAD_SAVE_SETNULLPAD();

	if (slabbed) OpslabREFCNT_dec_padok(OpSLAB(CvROOT(cv)));
	op_free(CvROOT(cv));
	CvROOT(cv) = NULL;
	CvSTART(cv) = NULL;
	LEAVE;
    }
    else if (slabbed && CvSTART(cv)) {
	ENTER;
	PAD_SAVE_SETNULLPAD();

	/* discard any leaked ops */
	if (PL_parser)
	    parser_free_nexttoke_ops(PL_parser, (OPSLAB *)CvSTART(cv));
	opslab_force_free((OPSLAB *)CvSTART(cv));
	CvSTART(cv) = NULL;

	LEAVE;
    }
#ifdef DEBUGGING
    else if (slabbed) Perl_warn(aTHX_ "Slab leaked from cv %p", cv);
#endif
    SvPOK_off(MUTABLE_SV(cv));		/* forget prototype */
    sv_unmagic((SV *)cv, PERL_MAGIC_checkcall);
    if (CvNAMED(cv)) CvNAME_HEK_set(cv, NULL);
    else	     CvGV_set(cv, NULL);

    /* This statement and the subsequence if block was pad_undef().  */
    pad_peg("pad_undef");

    if (padlist) {
	I32 ix;

	/* Free the padlist associated with a CV.
	   If parts of it happen to be current, we null the relevant PL_*pad*
	   global vars so that we don't have any dangling references left.
	   We also repoint the CvOUTSIDE of any about-to-be-orphaned inner
	   subs to the outer of this cv.  */

	DEBUG_X(PerlIO_printf(Perl_debug_log,
			      "Pad undef: cv=0x%"UVxf" padlist=0x%"UVxf" comppad=0x%"UVxf"\n",
			      PTR2UV(cv), PTR2UV(padlist), PTR2UV(PL_comppad))
		);

	/* detach any '&' anon children in the pad; if afterwards they
	 * are still live, fix up their CvOUTSIDEs to point to our outside,
	 * bypassing us. */
	/* XXX DAPM for efficiency, we should only do this if we know we have
	 * children, or integrate this loop with general cleanup */

	if (PL_phase != PERL_PHASE_DESTRUCT) { /* don't bother during global destruction */
	    CV * const outercv = CvOUTSIDE(cv);
	    const U32 seq = CvOUTSIDE_SEQ(cv);
	    PAD * const comppad_name = PadlistARRAY(padlist)[0];
	    SV ** const namepad = AvARRAY(comppad_name);
	    PAD * const comppad = PadlistARRAY(padlist)[1];
	    SV ** const curpad = AvARRAY(comppad);
	    for (ix = AvFILLp(comppad_name); ix > 0; ix--) {
		SV * const namesv = namepad[ix];
		if (namesv && namesv != &PL_sv_undef
		    && *SvPVX_const(namesv) == '&')
		    {
			CV * const innercv = MUTABLE_CV(curpad[ix]);
			U32 inner_rc = SvREFCNT(innercv);
			assert(inner_rc);
			assert(SvTYPE(innercv) != SVt_PVFM);

			if (SvREFCNT(comppad) < 2) { /* allow for /(?{ sub{} })/  */
			    curpad[ix] = NULL;
			    SvREFCNT_dec_NN(innercv);
			    inner_rc--;
			}

			/* in use, not just a prototype */
			if (inner_rc && (CvOUTSIDE(innercv) == cv)) {
			    assert(CvWEAKOUTSIDE(innercv));
			    /* don't relink to grandfather if he's being freed */
			    if (outercv && SvREFCNT(outercv)) {
				CvWEAKOUTSIDE_off(innercv);
				CvOUTSIDE(innercv) = outercv;
				CvOUTSIDE_SEQ(innercv) = seq;
				SvREFCNT_inc_simple_void_NN(outercv);
			    }
			    else {
				CvOUTSIDE(innercv) = NULL;
			    }
			}
		    }
	    }
	}

	ix = PadlistMAX(padlist);
	while (ix > 0) {
	    PAD * const sv = PadlistARRAY(padlist)[ix--];
	    if (sv) {
		if (sv == PL_comppad) {
		    PL_comppad = NULL;
		    PL_curpad = NULL;
		}
		SvREFCNT_dec_NN(sv);
	    }
	}
	{
	    PAD * const sv = PadlistARRAY(padlist)[0];
	    if (sv == PL_comppad_name && SvREFCNT(sv) == 1)
		PL_comppad_name = NULL;
	    SvREFCNT_dec(sv);
	}
	if (PadlistARRAY(padlist)) Safefree(PadlistARRAY(padlist));
	Safefree(padlist);
	CvPADLIST(cv) = NULL;
    }


    /* remove CvOUTSIDE unless this is an undef rather than a free */
    if (!SvREFCNT(cv) && CvOUTSIDE(cv)) {
	if (!CvWEAKOUTSIDE(cv))
	    SvREFCNT_dec(CvOUTSIDE(cv));
	CvOUTSIDE(cv) = NULL;
    }
    if (CvCONST(cv)) {
	SvREFCNT_dec(MUTABLE_SV(CvXSUBANY(cv).any_ptr));
	CvCONST_off(cv);
    }
    if (CvISXSUB(cv) && CvXSUB(cv)) {
	CvXSUB(cv) = NULL;
    }
    /* delete all flags except WEAKOUTSIDE and CVGV_RC, which indicate the
     * ref status of CvOUTSIDE and CvGV, and ANON, which pp_entersub uses
     * to choose an error message */
    CvFLAGS(cv) &= (CVf_WEAKOUTSIDE|CVf_CVGV_RC|CVf_ANON);
}

/*
=for apidoc cv_forget_slab

When a CV has a reference count on its slab (CvSLABBED), it is responsible
for making sure it is freed.  (Hence, no two CVs should ever have a
reference count on the same slab.)  The CV only needs to reference the slab
during compilation.  Once it is compiled and CvROOT attached, it has
finished its job, so it can forget the slab.

=cut
*/

void
Perl_cv_forget_slab(pTHX_ CV *cv)
{
    const bool slabbed = !!CvSLABBED(cv);
    OPSLAB *slab = NULL;

    PERL_ARGS_ASSERT_CV_FORGET_SLAB;

    if (!slabbed) return;

    CvSLABBED_off(cv);

    if      (CvROOT(cv))  slab = OpSLAB(CvROOT(cv));
    else if (CvSTART(cv)) slab = (OPSLAB *)CvSTART(cv);
#ifdef DEBUGGING
    else if (slabbed)     Perl_warn(aTHX_ "Slab leaked from cv %p", cv);
#endif

    if (slab) {
#ifdef PERL_DEBUG_READONLY_OPS
	const size_t refcnt = slab->opslab_refcnt;
#endif
	OpslabREFCNT_dec(slab);
#ifdef PERL_DEBUG_READONLY_OPS
	if (refcnt > 1) Slab_to_ro(slab);
#endif
    }
}

/*
=for apidoc m|PADOFFSET|pad_alloc_name|SV *namesv|U32 flags|HV *typestash|HV *ourstash

Allocates a place in the currently-compiling
pad (via L<perlapi/pad_alloc>) and
then stores a name for that entry.  I<namesv> is adopted and becomes the
name entry; it must already contain the name string and be sufficiently
upgraded.  I<typestash> and I<ourstash> and the C<padadd_STATE> flag get
added to I<namesv>.  None of the other
processing of L<perlapi/pad_add_name_pvn>
is done.  Returns the offset of the allocated pad slot.

=cut
*/

static PADOFFSET
S_pad_alloc_name(pTHX_ SV *namesv, U32 flags, HV *typestash, HV *ourstash)
{
    dVAR;
    const PADOFFSET offset = pad_alloc(OP_PADSV, SVs_PADMY);

    PERL_ARGS_ASSERT_PAD_ALLOC_NAME;

    ASSERT_CURPAD_ACTIVE("pad_alloc_name");

    if (typestash) {
	assert(SvTYPE(namesv) == SVt_PVMG);
	SvPAD_TYPED_on(namesv);
	SvSTASH_set(namesv, MUTABLE_HV(SvREFCNT_inc_simple_NN(MUTABLE_SV(typestash))));
    }
    if (ourstash) {
	SvPAD_OUR_on(namesv);
	SvOURSTASH_set(namesv, ourstash);
	SvREFCNT_inc_simple_void_NN(ourstash);
    }
    else if (flags & padadd_STATE) {
	SvPAD_STATE_on(namesv);
    }

    av_store(PL_comppad_name, offset, namesv);
    PadnamelistMAXNAMED(PL_comppad_name) = offset;
    return offset;
}

/*
=for apidoc Am|PADOFFSET|pad_add_name_pvn|const char *namepv|STRLEN namelen|U32 flags|HV *typestash|HV *ourstash

Allocates a place in the currently-compiling pad for a named lexical
variable.  Stores the name and other metadata in the name part of the
pad, and makes preparations to manage the variable's lexical scoping.
Returns the offset of the allocated pad slot.

I<namepv>/I<namelen> specify the variable's name, including leading sigil.
If I<typestash> is non-null, the name is for a typed lexical, and this
identifies the type.  If I<ourstash> is non-null, it's a lexical reference
to a package variable, and this identifies the package.  The following
flags can be OR'ed together:

    padadd_OUR          redundantly specifies if it's a package var
    padadd_STATE        variable will retain value persistently
    padadd_NO_DUP_CHECK skip check for lexical shadowing

=cut
*/

PADOFFSET
Perl_pad_add_name_pvn(pTHX_ const char *namepv, STRLEN namelen,
		U32 flags, HV *typestash, HV *ourstash)
{
    dVAR;
    PADOFFSET offset;
    SV *namesv;
    bool is_utf8;

    PERL_ARGS_ASSERT_PAD_ADD_NAME_PVN;

    if (flags & ~(padadd_OUR|padadd_STATE|padadd_NO_DUP_CHECK|padadd_UTF8_NAME))
	Perl_croak(aTHX_ "panic: pad_add_name_pvn illegal flag bits 0x%" UVxf,
		   (UV)flags);

    namesv = newSV_type((ourstash || typestash) ? SVt_PVMG : SVt_PVNV);

    if ((is_utf8 = ((flags & padadd_UTF8_NAME) != 0))) {
        namepv = (const char*)bytes_from_utf8((U8*)namepv, &namelen, &is_utf8);
    }

    sv_setpvn(namesv, namepv, namelen);

    if (is_utf8) {
        flags |= padadd_UTF8_NAME;
        SvUTF8_on(namesv);
    }
    else
        flags &= ~padadd_UTF8_NAME;

    if ((flags & padadd_NO_DUP_CHECK) == 0) {
	ENTER;
	SAVEFREESV(namesv); /* in case of fatal warnings */
	/* check for duplicate declaration */
	pad_check_dup(namesv, flags & padadd_OUR, ourstash);
	SvREFCNT_inc_simple_void_NN(namesv);
	LEAVE;
    }

    offset = pad_alloc_name(namesv, flags & ~padadd_UTF8_NAME, typestash, ourstash);

    /* not yet introduced */
    COP_SEQ_RANGE_LOW_set(namesv, PERL_PADSEQ_INTRO);
    COP_SEQ_RANGE_HIGH_set(namesv, 0);

    if (!PL_min_intro_pending)
	PL_min_intro_pending = offset;
    PL_max_intro_pending = offset;
    /* if it's not a simple scalar, replace with an AV or HV */
    assert(SvTYPE(PL_curpad[offset]) == SVt_NULL);
    assert(SvREFCNT(PL_curpad[offset]) == 1);
    if (namelen != 0 && *namepv == '@')
	sv_upgrade(PL_curpad[offset], SVt_PVAV);
    else if (namelen != 0 && *namepv == '%')
	sv_upgrade(PL_curpad[offset], SVt_PVHV);
    else if (namelen != 0 && *namepv == '&')
	sv_upgrade(PL_curpad[offset], SVt_PVCV);
    assert(SvPADMY(PL_curpad[offset]));
    DEBUG_Xv(PerlIO_printf(Perl_debug_log,
			   "Pad addname: %ld \"%s\" new lex=0x%"UVxf"\n",
			   (long)offset, SvPVX(namesv),
			   PTR2UV(PL_curpad[offset])));

    return offset;
}

/*
=for apidoc Am|PADOFFSET|pad_add_name_pv|const char *name|U32 flags|HV *typestash|HV *ourstash

Exactly like L</pad_add_name_pvn>, but takes a nul-terminated string
instead of a string/length pair.

=cut
*/

PADOFFSET
Perl_pad_add_name_pv(pTHX_ const char *name,
		     const U32 flags, HV *typestash, HV *ourstash)
{
    PERL_ARGS_ASSERT_PAD_ADD_NAME_PV;
    return pad_add_name_pvn(name, strlen(name), flags, typestash, ourstash);
}

/*
=for apidoc Am|PADOFFSET|pad_add_name_sv|SV *name|U32 flags|HV *typestash|HV *ourstash

Exactly like L</pad_add_name_pvn>, but takes the name string in the form
of an SV instead of a string/length pair.

=cut
*/

PADOFFSET
Perl_pad_add_name_sv(pTHX_ SV *name, U32 flags, HV *typestash, HV *ourstash)
{
    char *namepv;
    STRLEN namelen;
    PERL_ARGS_ASSERT_PAD_ADD_NAME_SV;
    namepv = SvPV(name, namelen);
    if (SvUTF8(name))
        flags |= padadd_UTF8_NAME;
    return pad_add_name_pvn(namepv, namelen, flags, typestash, ourstash);
}

/*
=for apidoc Amx|PADOFFSET|pad_alloc|I32 optype|U32 tmptype

Allocates a place in the currently-compiling pad,
returning the offset of the allocated pad slot.
No name is initially attached to the pad slot.
I<tmptype> is a set of flags indicating the kind of pad entry required,
which will be set in the value SV for the allocated pad entry:

    SVs_PADMY    named lexical variable ("my", "our", "state")
    SVs_PADTMP   unnamed temporary store
    SVf_READONLY constant shared between recursion levels

C<SVf_READONLY> has been supported here only since perl 5.20.  To work with
earlier versions as well, use C<SVf_READONLY|SVs_PADTMP>.  C<SVf_READONLY>
does not cause the SV in the pad slot to be marked read-only, but simply
tells C<pad_alloc> that it I<will> be made read-only (by the caller), or at
least should be treated as such.

I<optype> should be an opcode indicating the type of operation that the
pad entry is to support.  This doesn't affect operational semantics,
but is used for debugging.

=cut
*/

/* XXX DAPM integrate alloc(), add_name() and add_anon(),
 * or at least rationalise ??? */

PADOFFSET
Perl_pad_alloc(pTHX_ I32 optype, U32 tmptype)
{
    dVAR;
    SV *sv;
    I32 retval;

    PERL_UNUSED_ARG(optype);
    ASSERT_CURPAD_ACTIVE("pad_alloc");

    if (AvARRAY(PL_comppad) != PL_curpad)
	Perl_croak(aTHX_ "panic: pad_alloc, %p!=%p",
		   AvARRAY(PL_comppad), PL_curpad);
    if (PL_pad_reset_pending)
	pad_reset();
    if (tmptype & SVs_PADMY) {
	/* For a my, simply push a null SV onto the end of PL_comppad. */
	sv = *av_fetch(PL_comppad, AvFILLp(PL_comppad) + 1, TRUE);
	retval = AvFILLp(PL_comppad);
    }
    else {
	/* For a tmp, scan the pad from PL_padix upwards
	 * for a slot which has no name and no active value.
	 */
	SV * const * const names = AvARRAY(PL_comppad_name);
        const SSize_t names_fill = AvFILLp(PL_comppad_name);
	for (;;) {
	    /*
	     * Entries that close over unavailable variables
	     * in outer subs contain values not marked PADMY.
	     * Thus we must skip, not just pad values that are
	     * marked as current pad values, but also those with names.
	     */
	    if (++PL_padix <= names_fill &&
		   (sv = names[PL_padix]) && sv != &PL_sv_undef)
		continue;
	    sv = *av_fetch(PL_comppad, PL_padix, TRUE);
	    if (!(SvFLAGS(sv) & (SVs_PADTMP | SVs_PADMY)) &&
		!IS_PADGV(sv))
		break;
	}
	if (tmptype & SVf_READONLY) {
	    av_store(PL_comppad_name, PL_padix, &PL_sv_no);
	    tmptype &= ~SVf_READONLY;
	    tmptype |= SVs_PADTMP;
	}
	retval = PL_padix;
    }
    SvFLAGS(sv) |= tmptype;
    PL_curpad = AvARRAY(PL_comppad);

    DEBUG_X(PerlIO_printf(Perl_debug_log,
	  "Pad 0x%"UVxf"[0x%"UVxf"] alloc:   %ld for %s\n",
	  PTR2UV(PL_comppad), PTR2UV(PL_curpad), (long) retval,
	  PL_op_name[optype]));
#ifdef DEBUG_LEAKING_SCALARS
    sv->sv_debug_optype = optype;
    sv->sv_debug_inpad = 1;
#endif
    return (PADOFFSET)retval;
}

/*
=for apidoc Am|PADOFFSET|pad_add_anon|CV *func|I32 optype

Allocates a place in the currently-compiling pad (via L</pad_alloc>)
for an anonymous function that is lexically scoped inside the
currently-compiling function.
The function I<func> is linked into the pad, and its C<CvOUTSIDE> link
to the outer scope is weakened to avoid a reference loop.

One reference count is stolen, so you may need to do C<SvREFCNT_inc(func)>.

I<optype> should be an opcode indicating the type of operation that the
pad entry is to support.  This doesn't affect operational semantics,
but is used for debugging.

=cut
*/

PADOFFSET
Perl_pad_add_anon(pTHX_ CV* func, I32 optype)
{
    dVAR;
    PADOFFSET ix;
    SV* const name = newSV_type(SVt_PVNV);

    PERL_ARGS_ASSERT_PAD_ADD_ANON;

    pad_peg("add_anon");
    sv_setpvs(name, "&");
    /* These two aren't used; just make sure they're not equal to
     * PERL_PADSEQ_INTRO */
    COP_SEQ_RANGE_LOW_set(name, 0);
    COP_SEQ_RANGE_HIGH_set(name, 0);
    ix = pad_alloc(optype, SVs_PADMY);
    av_store(PL_comppad_name, ix, name);
    /* XXX DAPM use PL_curpad[] ? */
    if (SvTYPE(func) == SVt_PVCV || !CvOUTSIDE(func))
	av_store(PL_comppad, ix, (SV*)func);
    else {
	SV *rv = newRV_noinc((SV *)func);
	sv_rvweaken(rv);
	assert (SvTYPE(func) == SVt_PVFM);
	av_store(PL_comppad, ix, rv);
    }
    SvPADMY_on((SV*)func);

    /* to avoid ref loops, we never have parent + child referencing each
     * other simultaneously */
    if (CvOUTSIDE(func) && SvTYPE(func) == SVt_PVCV) {
	assert(!CvWEAKOUTSIDE(func));
	CvWEAKOUTSIDE_on(func);
	SvREFCNT_dec_NN(CvOUTSIDE(func));
    }
    return ix;
}

/*
=for apidoc pad_check_dup

Check for duplicate declarations: report any of:

     * a my in the current scope with the same name;
     * an our (anywhere in the pad) with the same name and the
       same stash as C<ourstash>

C<is_our> indicates that the name to check is an 'our' declaration.

=cut
*/

STATIC void
S_pad_check_dup(pTHX_ SV *name, U32 flags, const HV *ourstash)
{
    dVAR;
    SV		**svp;
    PADOFFSET	top, off;
    const U32	is_our = flags & padadd_OUR;

    PERL_ARGS_ASSERT_PAD_CHECK_DUP;

    ASSERT_CURPAD_ACTIVE("pad_check_dup");

    assert((flags & ~padadd_OUR) == 0);

    if (AvFILLp(PL_comppad_name) < 0 || !ckWARN(WARN_MISC))
	return; /* nothing to check */

    svp = AvARRAY(PL_comppad_name);
    top = AvFILLp(PL_comppad_name);
    /* check the current scope */
    /* XXX DAPM - why the (I32) cast - shouldn't we ensure they're the same
     * type ? */
    for (off = top; (I32)off > PL_comppad_name_floor; off--) {
	SV * const sv = svp[off];
	if (sv
	    && PadnameLEN(sv)
	    && !SvFAKE(sv)
	    && (   COP_SEQ_RANGE_LOW(sv)  == PERL_PADSEQ_INTRO
		|| COP_SEQ_RANGE_HIGH(sv) == PERL_PADSEQ_INTRO)
	    && sv_eq(name, sv))
	{
	    if (is_our && (SvPAD_OUR(sv)))
		break; /* "our" masking "our" */
	    /* diag_listed_as: "%s" variable %s masks earlier declaration in same %s */
	    Perl_warner(aTHX_ packWARN(WARN_MISC),
		"\"%s\" %s %"SVf" masks earlier declaration in same %s",
		(is_our ? "our" : PL_parser->in_my == KEY_my ? "my" : "state"),
		*SvPVX(sv) == '&' ? "subroutine" : "variable",
		sv,
		(COP_SEQ_RANGE_HIGH(sv) == PERL_PADSEQ_INTRO
		    ? "scope" : "statement"));
	    --off;
	    break;
	}
    }
    /* check the rest of the pad */
    if (is_our) {
	while (off > 0) {
	    SV * const sv = svp[off];
	    if (sv
		&& PadnameLEN(sv)
		&& !SvFAKE(sv)
		&& (   COP_SEQ_RANGE_LOW(sv)  == PERL_PADSEQ_INTRO
		    || COP_SEQ_RANGE_HIGH(sv) == PERL_PADSEQ_INTRO)
		&& SvOURSTASH(sv) == ourstash
		&& sv_eq(name, sv))
	    {
		Perl_warner(aTHX_ packWARN(WARN_MISC),
		    "\"our\" variable %"SVf" redeclared", sv);
		if ((I32)off <= PL_comppad_name_floor)
		    Perl_warner(aTHX_ packWARN(WARN_MISC),
			"\t(Did you mean \"local\" instead of \"our\"?)\n");
		break;
	    }
	    --off;
	}
    }
}


/*
=for apidoc Am|PADOFFSET|pad_findmy_pvn|const char *namepv|STRLEN namelen|U32 flags

Given the name of a lexical variable, find its position in the
currently-compiling pad.
I<namepv>/I<namelen> specify the variable's name, including leading sigil.
I<flags> is reserved and must be zero.
If it is not in the current pad but appears in the pad of any lexically
enclosing scope, then a pseudo-entry for it is added in the current pad.
Returns the offset in the current pad,
or C<NOT_IN_PAD> if no such lexical is in scope.

=cut
*/

PADOFFSET
Perl_pad_findmy_pvn(pTHX_ const char *namepv, STRLEN namelen, U32 flags)
{
    dVAR;
    SV *out_sv;
    int out_flags;
    I32 offset;
    const AV *nameav;
    SV **name_svp;

    PERL_ARGS_ASSERT_PAD_FINDMY_PVN;

    pad_peg("pad_findmy_pvn");

    if (flags & ~padadd_UTF8_NAME)
	Perl_croak(aTHX_ "panic: pad_findmy_pvn illegal flag bits 0x%" UVxf,
		   (UV)flags);

    if (flags & padadd_UTF8_NAME) {
        bool is_utf8 = TRUE;
        namepv = (const char*)bytes_from_utf8((U8*)namepv, &namelen, &is_utf8);

        if (is_utf8)
            flags |= padadd_UTF8_NAME;
        else
            flags &= ~padadd_UTF8_NAME;
    }

    offset = pad_findlex(namepv, namelen, flags,
                PL_compcv, PL_cop_seqmax, 1, NULL, &out_sv, &out_flags);
    if ((PADOFFSET)offset != NOT_IN_PAD)
	return offset;

    /* look for an our that's being introduced; this allows
     *    our $foo = 0 unless defined $foo;
     * to not give a warning. (Yes, this is a hack) */

    nameav = PadlistARRAY(CvPADLIST(PL_compcv))[0];
    name_svp = AvARRAY(nameav);
    for (offset = AvFILLp(nameav); offset > 0; offset--) {
        const SV * const namesv = name_svp[offset];
	if (namesv && PadnameLEN(namesv) == namelen
	    && !SvFAKE(namesv)
	    && (SvPAD_OUR(namesv))
            && sv_eq_pvn_flags(aTHX_ namesv, namepv, namelen,
                                flags & padadd_UTF8_NAME ? SVf_UTF8 : 0 )
	    && COP_SEQ_RANGE_LOW(namesv) == PERL_PADSEQ_INTRO
	)
	    return offset;
    }
    return NOT_IN_PAD;
}

/*
=for apidoc Am|PADOFFSET|pad_findmy_pv|const char *name|U32 flags

Exactly like L</pad_findmy_pvn>, but takes a nul-terminated string
instead of a string/length pair.

=cut
*/

PADOFFSET
Perl_pad_findmy_pv(pTHX_ const char *name, U32 flags)
{
    PERL_ARGS_ASSERT_PAD_FINDMY_PV;
    return pad_findmy_pvn(name, strlen(name), flags);
}

/*
=for apidoc Am|PADOFFSET|pad_findmy_sv|SV *name|U32 flags

Exactly like L</pad_findmy_pvn>, but takes the name string in the form
of an SV instead of a string/length pair.

=cut
*/

PADOFFSET
Perl_pad_findmy_sv(pTHX_ SV *name, U32 flags)
{
    char *namepv;
    STRLEN namelen;
    PERL_ARGS_ASSERT_PAD_FINDMY_SV;
    namepv = SvPV(name, namelen);
    if (SvUTF8(name))
        flags |= padadd_UTF8_NAME;
    return pad_findmy_pvn(namepv, namelen, flags);
}

/*
=for apidoc Amp|PADOFFSET|find_rundefsvoffset

Find the position of the lexical C<$_> in the pad of the
currently-executing function.  Returns the offset in the current pad,
or C<NOT_IN_PAD> if there is no lexical C<$_> in scope (in which case
the global one should be used instead).
L</find_rundefsv> is likely to be more convenient.

=cut
*/

PADOFFSET
Perl_find_rundefsvoffset(pTHX)
{
    dVAR;
    SV *out_sv;
    int out_flags;
    return pad_findlex("$_", 2, 0, find_runcv(NULL), PL_curcop->cop_seq, 1,
	    NULL, &out_sv, &out_flags);
}

/*
=for apidoc Am|SV *|find_rundefsv

Find and return the variable that is named C<$_> in the lexical scope
of the currently-executing function.  This may be a lexical C<$_>,
or will otherwise be the global one.

=cut
*/

SV *
Perl_find_rundefsv(pTHX)
{
    SV *namesv;
    int flags;
    PADOFFSET po;

    po = pad_findlex("$_", 2, 0, find_runcv(NULL), PL_curcop->cop_seq, 1,
	    NULL, &namesv, &flags);

    if (po == NOT_IN_PAD || SvPAD_OUR(namesv))
	return DEFSV;

    return PAD_SVl(po);
}

SV *
Perl_find_rundefsv2(pTHX_ CV *cv, U32 seq)
{
    SV *namesv;
    int flags;
    PADOFFSET po;

    PERL_ARGS_ASSERT_FIND_RUNDEFSV2;

    po = pad_findlex("$_", 2, 0, cv, seq, 1,
	    NULL, &namesv, &flags);

    if (po == NOT_IN_PAD || SvPAD_OUR(namesv))
	return DEFSV;

    return AvARRAY(PadlistARRAY(CvPADLIST(cv))[CvDEPTH(cv)])[po];
}

/*
=for apidoc m|PADOFFSET|pad_findlex|const char *namepv|STRLEN namelen|U32 flags|const CV* cv|U32 seq|int warn|SV** out_capture|SV** out_name_sv|int *out_flags

Find a named lexical anywhere in a chain of nested pads.  Add fake entries
in the inner pads if it's found in an outer one.

Returns the offset in the bottom pad of the lex or the fake lex.
cv is the CV in which to start the search, and seq is the current cop_seq
to match against.  If warn is true, print appropriate warnings.  The out_*
vars return values, and so are pointers to where the returned values
should be stored.  out_capture, if non-null, requests that the innermost
instance of the lexical is captured; out_name_sv is set to the innermost
matched namesv or fake namesv; out_flags returns the flags normally
associated with the IVX field of a fake namesv.

Note that pad_findlex() is recursive; it recurses up the chain of CVs,
then comes back down, adding fake entries
as it goes.  It has to be this way
because fake namesvs in anon protoypes have to store in xlow the index into
the parent pad.

=cut
*/

/* the CV has finished being compiled. This is not a sufficient test for
 * all CVs (eg XSUBs), but suffices for the CVs found in a lexical chain */
#define CvCOMPILED(cv)	CvROOT(cv)

/* the CV does late binding of its lexicals */
#define CvLATE(cv) (CvANON(cv) || CvCLONE(cv) || SvTYPE(cv) == SVt_PVFM)

static void
S_unavailable(pTHX_ SV *namesv)
{
    /* diag_listed_as: Variable "%s" is not available */
    Perl_ck_warner(aTHX_ packWARN(WARN_CLOSURE),
			"%se \"%"SVf"\" is not available",
			 *SvPVX_const(namesv) == '&'
					 ? "Subroutin"
					 : "Variabl",
			 namesv);
}

STATIC PADOFFSET
S_pad_findlex(pTHX_ const char *namepv, STRLEN namelen, U32 flags, const CV* cv, U32 seq,
	int warn, SV** out_capture, SV** out_name_sv, int *out_flags)
{
    dVAR;
    I32 offset, new_offset;
    SV *new_capture;
    SV **new_capturep;
    const PADLIST * const padlist = CvPADLIST(cv);
    const bool staleok = !!(flags & padadd_STALEOK);

    PERL_ARGS_ASSERT_PAD_FINDLEX;

    if (flags & ~(padadd_UTF8_NAME|padadd_STALEOK))
	Perl_croak(aTHX_ "panic: pad_findlex illegal flag bits 0x%" UVxf,
		   (UV)flags);
    flags &= ~ padadd_STALEOK; /* one-shot flag */

    *out_flags = 0;

    DEBUG_Xv(PerlIO_printf(Perl_debug_log,
	"Pad findlex cv=0x%"UVxf" searching \"%.*s\" seq=%d%s\n",
			   PTR2UV(cv), (int)namelen, namepv, (int)seq,
	out_capture ? " capturing" : "" ));

    /* first, search this pad */

    if (padlist) { /* not an undef CV */
	I32 fake_offset = 0;
        const AV * const nameav = PadlistARRAY(padlist)[0];
	SV * const * const name_svp = AvARRAY(nameav);

	for (offset = PadnamelistMAXNAMED(nameav); offset > 0; offset--) {
            const SV * const namesv = name_svp[offset];
	    if (namesv && PadnameLEN(namesv) == namelen
                    && sv_eq_pvn_flags(aTHX_ namesv, namepv, namelen,
                                    flags & padadd_UTF8_NAME ? SVf_UTF8 : 0))
	    {
		if (SvFAKE(namesv)) {
		    fake_offset = offset; /* in case we don't find a real one */
		    continue;
		}
		/* is seq within the range _LOW to _HIGH ?
		 * This is complicated by the fact that PL_cop_seqmax
		 * may have wrapped around at some point */
		if (COP_SEQ_RANGE_LOW(namesv) == PERL_PADSEQ_INTRO)
		    continue; /* not yet introduced */

		if (COP_SEQ_RANGE_HIGH(namesv) == PERL_PADSEQ_INTRO) {
		    /* in compiling scope */
		    if (
			(seq >  COP_SEQ_RANGE_LOW(namesv))
			? (seq - COP_SEQ_RANGE_LOW(namesv) < (U32_MAX >> 1))
			: (COP_SEQ_RANGE_LOW(namesv) - seq > (U32_MAX >> 1))
		    )
		       break;
		}
		else if (
		    (COP_SEQ_RANGE_LOW(namesv) > COP_SEQ_RANGE_HIGH(namesv))
		    ?
			(  seq >  COP_SEQ_RANGE_LOW(namesv)
			|| seq <= COP_SEQ_RANGE_HIGH(namesv))

		    :    (  seq >  COP_SEQ_RANGE_LOW(namesv)
			 && seq <= COP_SEQ_RANGE_HIGH(namesv))
		)
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
		 * shared' warnings. We also treated already-compiled
		 * lexes as not multi as viewed from evals. */

		*out_flags = CvANON(cv) ?
			PAD_FAKELEX_ANON :
			    (!CvUNIQUE(cv) && ! CvCOMPILED(cv))
				? PAD_FAKELEX_MULTI : 0;

		DEBUG_Xv(PerlIO_printf(Perl_debug_log,
		    "Pad findlex cv=0x%"UVxf" matched: offset=%ld (%lu,%lu)\n",
		    PTR2UV(cv), (long)offset,
		    (unsigned long)COP_SEQ_RANGE_LOW(*out_name_sv),
		    (unsigned long)COP_SEQ_RANGE_HIGH(*out_name_sv)));
	    }
	    else { /* fake match */
		offset = fake_offset;
		*out_name_sv = name_svp[offset]; /* return the namesv */
		*out_flags = PARENT_FAKELEX_FLAGS(*out_name_sv);
		DEBUG_Xv(PerlIO_printf(Perl_debug_log,
		    "Pad findlex cv=0x%"UVxf" matched: offset=%ld flags=0x%lx index=%lu\n",
		    PTR2UV(cv), (long)offset, (unsigned long)*out_flags,
		    (unsigned long) PARENT_PAD_INDEX(*out_name_sv)
		));
	    }

	    /* return the lex? */

	    if (out_capture) {

		/* our ? */
		if (SvPAD_OUR(*out_name_sv)) {
		    *out_capture = NULL;
		    return offset;
		}

		/* trying to capture from an anon prototype? */
		if (CvCOMPILED(cv)
			? CvANON(cv) && CvCLONE(cv) && !CvCLONED(cv)
			: *out_flags & PAD_FAKELEX_ANON)
		{
		    if (warn)
			S_unavailable(aTHX_
                                       newSVpvn_flags(namepv, namelen,
                                           SVs_TEMP |
                                           (flags & padadd_UTF8_NAME ? SVf_UTF8 : 0)));

		    *out_capture = NULL;
		}

		/* real value */
		else {
		    int newwarn = warn;
		    if (!CvCOMPILED(cv) && (*out_flags & PAD_FAKELEX_MULTI)
			 && !SvPAD_STATE(name_svp[offset])
			 && warn && ckWARN(WARN_CLOSURE)) {
			newwarn = 0;
			Perl_warner(aTHX_ packWARN(WARN_CLOSURE),
			    "Variable \"%"SVf"\" will not stay shared",
                            newSVpvn_flags(namepv, namelen,
                                SVs_TEMP |
                                (flags & padadd_UTF8_NAME ? SVf_UTF8 : 0)));
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
			(void) pad_findlex(namepv, namelen, flags, CvOUTSIDE(cv),
			    CvOUTSIDE_SEQ(cv),
			    newwarn, out_capture, out_name_sv, out_flags);
			*out_name_sv = n;
			return offset;
		    }

		    *out_capture = AvARRAY(PadlistARRAY(padlist)[
				    CvDEPTH(cv) ? CvDEPTH(cv) : 1])[offset];
		    DEBUG_Xv(PerlIO_printf(Perl_debug_log,
			"Pad findlex cv=0x%"UVxf" found lex=0x%"UVxf"\n",
			PTR2UV(cv), PTR2UV(*out_capture)));

		    if (SvPADSTALE(*out_capture)
			&& (!CvDEPTH(cv) || !staleok)
			&& !SvPAD_STATE(name_svp[offset]))
		    {
			S_unavailable(aTHX_
                                       newSVpvn_flags(namepv, namelen,
                                           SVs_TEMP |
                                           (flags & padadd_UTF8_NAME ? SVf_UTF8 : 0)));
			*out_capture = NULL;
		    }
		}
		if (!*out_capture) {
		    if (namelen != 0 && *namepv == '@')
			*out_capture = sv_2mortal(MUTABLE_SV(newAV()));
		    else if (namelen != 0 && *namepv == '%')
			*out_capture = sv_2mortal(MUTABLE_SV(newHV()));
		    else if (namelen != 0 && *namepv == '&')
			*out_capture = sv_2mortal(newSV_type(SVt_PVCV));
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
		CvLATE(cv) ? NULL : &new_capture;

    offset = pad_findlex(namepv, namelen,
		flags | padadd_STALEOK*(new_capturep == &new_capture),
		CvOUTSIDE(cv), CvOUTSIDE_SEQ(cv), 1,
		new_capturep, out_name_sv, out_flags);
    if ((PADOFFSET)offset == NOT_IN_PAD)
	return NOT_IN_PAD;

    /* found in an outer CV. Add appropriate fake entry to this pad */

    /* don't add new fake entries (via eval) to CVs that we have already
     * finished compiling, or to undef CVs */
    if (CvCOMPILED(cv) || !padlist)
	return 0; /* this dummy (and invalid) value isnt used by the caller */

    {
	/* This relies on sv_setsv_flags() upgrading the destination to the same
	   type as the source, independent of the flags set, and on it being
	   "good" and only copying flag bits and pointers that it understands.
	*/
	SV *new_namesv = newSVsv(*out_name_sv);
	AV *  const ocomppad_name = PL_comppad_name;
	PAD * const ocomppad = PL_comppad;
	PL_comppad_name = PadlistARRAY(padlist)[0];
	PL_comppad = PadlistARRAY(padlist)[1];
	PL_curpad = AvARRAY(PL_comppad);

	new_offset
	    = pad_alloc_name(new_namesv,
			      (SvPAD_STATE(*out_name_sv) ? padadd_STATE : 0),
			      SvPAD_TYPED(*out_name_sv)
			      ? SvSTASH(*out_name_sv) : NULL,
			      SvOURSTASH(*out_name_sv)
			      );

	SvFAKE_on(new_namesv);
	DEBUG_Xv(PerlIO_printf(Perl_debug_log,
			       "Pad addname: %ld \"%.*s\" FAKE\n",
			       (long)new_offset,
			       (int) SvCUR(new_namesv), SvPVX(new_namesv)));
	PARENT_FAKELEX_FLAGS_set(new_namesv, *out_flags);

	PARENT_PAD_INDEX_set(new_namesv, 0);
	if (SvPAD_OUR(new_namesv)) {
	    NOOP;   /* do nothing */
	}
	else if (CvLATE(cv)) {
	    /* delayed creation - just note the offset within parent pad */
	    PARENT_PAD_INDEX_set(new_namesv, offset);
	    CvCLONE_on(cv);
	}
	else {
	    /* immediate creation - capture outer value right now */
	    av_store(PL_comppad, new_offset, SvREFCNT_inc(*new_capturep));
	    /* But also note the offset, as newMYSUB needs it */
	    PARENT_PAD_INDEX_set(new_namesv, offset);
	    DEBUG_Xv(PerlIO_printf(Perl_debug_log,
		"Pad findlex cv=0x%"UVxf" saved captured sv 0x%"UVxf" at offset %ld\n",
		PTR2UV(cv), PTR2UV(*new_capturep), (long)new_offset));
	}
	*out_name_sv = new_namesv;
	*out_flags = PARENT_FAKELEX_FLAGS(new_namesv);

	PL_comppad_name = ocomppad_name;
	PL_comppad = ocomppad;
	PL_curpad = ocomppad ? AvARRAY(ocomppad) : NULL;
    }
    return new_offset;
}

#ifdef DEBUGGING

/*
=for apidoc Am|SV *|pad_sv|PADOFFSET po

Get the value at offset I<po> in the current (compiling or executing) pad.
Use macro PAD_SV instead of calling this function directly.

=cut
*/

SV *
Perl_pad_sv(pTHX_ PADOFFSET po)
{
    dVAR;
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
=for apidoc Am|void|pad_setsv|PADOFFSET po|SV *sv

Set the value at offset I<po> in the current (compiling or executing) pad.
Use the macro PAD_SETSV() rather than calling this function directly.

=cut
*/

void
Perl_pad_setsv(pTHX_ PADOFFSET po, SV* sv)
{
    dVAR;

    PERL_ARGS_ASSERT_PAD_SETSV;

    ASSERT_CURPAD_ACTIVE("pad_setsv");

    DEBUG_X(PerlIO_printf(Perl_debug_log,
	"Pad 0x%"UVxf"[0x%"UVxf"] setsv:   %ld sv=0x%"UVxf"\n",
	PTR2UV(PL_comppad), PTR2UV(PL_curpad), (long)po, PTR2UV(sv))
    );
    PL_curpad[po] = sv;
}

#endif /* DEBUGGING */

/*
=for apidoc m|void|pad_block_start|int full

Update the pad compilation state variables on entry to a new block.

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
    dVAR;
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
=for apidoc m|U32|intro_my

"Introduce" my variables to visible status.  This is called during parsing
at the end of each statement to make lexical variables visible to
subsequent statements.

=cut
*/

U32
Perl_intro_my(pTHX)
{
    dVAR;
    SV **svp;
    I32 i;
    U32 seq;

    ASSERT_CURPAD_ACTIVE("intro_my");
    if (! PL_min_intro_pending)
	return PL_cop_seqmax;

    svp = AvARRAY(PL_comppad_name);
    for (i = PL_min_intro_pending; i <= PL_max_intro_pending; i++) {
	SV * const sv = svp[i];

	if (sv && PadnameLEN(sv) && !SvFAKE(sv)
	    && COP_SEQ_RANGE_LOW(sv) == PERL_PADSEQ_INTRO)
	{
	    COP_SEQ_RANGE_HIGH_set(sv, PERL_PADSEQ_INTRO); /* Don't know scope end yet. */
	    COP_SEQ_RANGE_LOW_set(sv, PL_cop_seqmax);
	    DEBUG_Xv(PerlIO_printf(Perl_debug_log,
		"Pad intromy: %ld \"%s\", (%lu,%lu)\n",
		(long)i, SvPVX_const(sv),
		(unsigned long)COP_SEQ_RANGE_LOW(sv),
		(unsigned long)COP_SEQ_RANGE_HIGH(sv))
	    );
	}
    }
    seq = PL_cop_seqmax;
    PL_cop_seqmax++;
    if (PL_cop_seqmax == PERL_PADSEQ_INTRO) /* not a legal value */
	PL_cop_seqmax++;
    PL_min_intro_pending = 0;
    PL_comppad_name_fill = PL_max_intro_pending; /* Needn't search higher */
    DEBUG_Xv(PerlIO_printf(Perl_debug_log,
		"Pad intromy: seq -> %ld\n", (long)(PL_cop_seqmax)));

    return seq;
}

/*
=for apidoc m|void|pad_leavemy

Cleanup at end of scope during compilation: set the max seq number for
lexicals in this scope and warn of any lexicals that never got introduced.

=cut
*/

OP *
Perl_pad_leavemy(pTHX)
{
    dVAR;
    I32 off;
    OP *o = NULL;
    SV * const * const svp = AvARRAY(PL_comppad_name);

    PL_pad_reset_pending = FALSE;

    ASSERT_CURPAD_ACTIVE("pad_leavemy");
    if (PL_min_intro_pending && PL_comppad_name_fill < PL_min_intro_pending) {
	for (off = PL_max_intro_pending; off >= PL_min_intro_pending; off--) {
	    const SV * const sv = svp[off];
	    if (sv && PadnameLEN(sv) && !SvFAKE(sv))
		Perl_ck_warner_d(aTHX_ packWARN(WARN_INTERNAL),
				 "%"SVf" never introduced",
				 SVfARG(sv));
	}
    }
    /* "Deintroduce" my variables that are leaving with this scope. */
    for (off = AvFILLp(PL_comppad_name); off > PL_comppad_name_fill; off--) {
	SV * const sv = svp[off];
	if (sv && PadnameLEN(sv) && !SvFAKE(sv)
	    && COP_SEQ_RANGE_HIGH(sv) == PERL_PADSEQ_INTRO)
	{
	    COP_SEQ_RANGE_HIGH_set(sv, PL_cop_seqmax);
	    DEBUG_Xv(PerlIO_printf(Perl_debug_log,
		"Pad leavemy: %ld \"%s\", (%lu,%lu)\n",
		(long)off, SvPVX_const(sv),
		(unsigned long)COP_SEQ_RANGE_LOW(sv),
		(unsigned long)COP_SEQ_RANGE_HIGH(sv))
	    );
	    if (!PadnameIsSTATE(sv) && !PadnameIsOUR(sv)
	     && *PadnamePV(sv) == '&' && PadnameLEN(sv) > 1) {
		OP *kid = newOP(OP_INTROCV, 0);
		kid->op_targ = off;
		o = op_prepend_elem(OP_LINESEQ, kid, o);
	    }
	}
    }
    PL_cop_seqmax++;
    if (PL_cop_seqmax == PERL_PADSEQ_INTRO) /* not a legal value */
	PL_cop_seqmax++;
    DEBUG_Xv(PerlIO_printf(Perl_debug_log,
	    "Pad leavemy: seq = %ld\n", (long)PL_cop_seqmax));
    return o;
}

/*
=for apidoc m|void|pad_swipe|PADOFFSET po|bool refadjust

Abandon the tmp in the current pad at offset po and replace with a
new one.

=cut
*/

void
Perl_pad_swipe(pTHX_ PADOFFSET po, bool refadjust)
{
    dVAR;
    ASSERT_CURPAD_LEGAL("pad_swipe");
    if (!PL_curpad)
	return;
    if (AvARRAY(PL_comppad) != PL_curpad)
	Perl_croak(aTHX_ "panic: pad_swipe curpad, %p!=%p",
		   AvARRAY(PL_comppad), PL_curpad);
    if (!po || ((SSize_t)po) > AvFILLp(PL_comppad))
	Perl_croak(aTHX_ "panic: pad_swipe po=%ld, fill=%ld",
		   (long)po, (long)AvFILLp(PL_comppad));

    DEBUG_X(PerlIO_printf(Perl_debug_log,
		"Pad 0x%"UVxf"[0x%"UVxf"] swipe:   %ld\n",
		PTR2UV(PL_comppad), PTR2UV(PL_curpad), (long)po));

    if (refadjust)
	SvREFCNT_dec(PL_curpad[po]);


    /* if pad tmps aren't shared between ops, then there's no need to
     * create a new tmp when an existing op is freed */
#ifdef USE_BROKEN_PAD_RESET
    PL_curpad[po] = newSV(0);
    SvPADTMP_on(PL_curpad[po]);
#else
    PL_curpad[po] = NULL;
#endif
    if (PadnamelistMAX(PL_comppad_name) != -1
     && (PADOFFSET)PadnamelistMAX(PL_comppad_name) >= po) {
	if (PadnamelistARRAY(PL_comppad_name)[po]) {
	    assert(!PadnameLEN(PadnamelistARRAY(PL_comppad_name)[po]));
	}
	PadnamelistARRAY(PL_comppad_name)[po] = &PL_sv_undef;
    }
    if ((I32)po < PL_padix)
	PL_padix = po - 1;
}

/*
=for apidoc m|void|pad_reset

Mark all the current temporaries for reuse

=cut
*/

/* XXX pad_reset() is currently disabled because it results in serious bugs.
 * It causes pad temp TARGs to be shared between OPs. Since TARGs are pushed
 * on the stack by OPs that use them, there are several ways to get an alias
 * to  a shared TARG.  Such an alias will change randomly and unpredictably.
 * We avoid doing this until we can think of a Better Way.
 * GSAR 97-10-29 */
static void
S_pad_reset(pTHX)
{
    dVAR;
#ifdef USE_BROKEN_PAD_RESET
    if (AvARRAY(PL_comppad) != PL_curpad)
	Perl_croak(aTHX_ "panic: pad_reset curpad, %p!=%p",
		   AvARRAY(PL_comppad), PL_curpad);

    DEBUG_X(PerlIO_printf(Perl_debug_log,
	    "Pad 0x%"UVxf"[0x%"UVxf"] reset:     padix %ld -> %ld",
	    PTR2UV(PL_comppad), PTR2UV(PL_curpad),
		(long)PL_padix, (long)PL_padix_floor
	    )
    );

    if (!TAINTING_get) {	/* Can't mix tainted and non-tainted temporaries. */
        I32 po;
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
=for apidoc Amx|void|pad_tidy|padtidy_type type

Tidy up a pad at the end of compilation of the code to which it belongs.
Jobs performed here are: remove most stuff from the pads of anonsub
prototypes; give it a @_; mark temporaries as such.  I<type> indicates
the kind of subroutine:

    padtidy_SUB        ordinary subroutine
    padtidy_SUBCLONE   prototype for lexical closure
    padtidy_FORMAT     format

=cut
*/

/* XXX DAPM surely most of this stuff should be done properly
 * at the right time beforehand, rather than going around afterwards
 * cleaning up our mistakes ???
 */

void
Perl_pad_tidy(pTHX_ padtidy_type type)
{
    dVAR;

    ASSERT_CURPAD_ACTIVE("pad_tidy");

    /* If this CV has had any 'eval-capable' ops planted in it:
     * i.e. it contains any of:
     *
     *     * eval '...',
     *     * //ee,
     *     * use re 'eval'; /$var/
     *     * /(?{..})/),
     *
     * Then any anon prototypes in the chain of CVs should be marked as
     * cloneable, so that for example the eval's CV in
     *
     *    sub { eval '$x' }
     *
     * gets the right CvOUTSIDE.  If running with -d, *any* sub may
     * potentially have an eval executed within it.
     */

    if (PL_cv_has_eval || PL_perldb) {
        const CV *cv;
	for (cv = PL_compcv ;cv; cv = CvOUTSIDE(cv)) {
	    if (cv != PL_compcv && CvCOMPILED(cv))
		break; /* no need to mark already-compiled code */
	    if (CvANON(cv)) {
		DEBUG_Xv(PerlIO_printf(Perl_debug_log,
		    "Pad clone on cv=0x%"UVxf"\n", PTR2UV(cv)));
		CvCLONE_on(cv);
	    }
	    CvHASEVAL_on(cv);
	}
    }

    /* extend namepad to match curpad */
    if (AvFILLp(PL_comppad_name) < AvFILLp(PL_comppad))
	av_store(PL_comppad_name, AvFILLp(PL_comppad), NULL);

    if (type == padtidy_SUBCLONE) {
	SV ** const namep = AvARRAY(PL_comppad_name);
	PADOFFSET ix;

	for (ix = AvFILLp(PL_comppad); ix > 0; ix--) {
	    SV *namesv;
	    if (!namep[ix]) namep[ix] = &PL_sv_undef;

	    /*
	     * The only things that a clonable function needs in its
	     * pad are anonymous subs, constants and GVs.
	     * The rest are created anew during cloning.
	     */
	    if (!PL_curpad[ix] || SvIMMORTAL(PL_curpad[ix])
		 || IS_PADGV(PL_curpad[ix]))
		continue;
	    namesv = namep[ix];
	    if (!(PadnamePV(namesv) &&
		   (!PadnameLEN(namesv) || *SvPVX_const(namesv) == '&')))
	    {
		SvREFCNT_dec(PL_curpad[ix]);
		PL_curpad[ix] = NULL;
	    }
	}
    }
    else if (type == padtidy_SUB) {
	/* XXX DAPM this same bit of code keeps appearing !!! Rationalise? */
	AV * const av = newAV();			/* Will be @_ */
	av_store(PL_comppad, 0, MUTABLE_SV(av));
	AvREIFY_only(av);
    }

    if (type == padtidy_SUB || type == padtidy_FORMAT) {
	SV ** const namep = AvARRAY(PL_comppad_name);
	PADOFFSET ix;
	for (ix = AvFILLp(PL_comppad); ix > 0; ix--) {
	    if (!namep[ix]) namep[ix] = &PL_sv_undef;
	    if (!PL_curpad[ix] || SvIMMORTAL(PL_curpad[ix])
		 || IS_PADGV(PL_curpad[ix]) || IS_PADCONST(PL_curpad[ix]))
		continue;
	    if (!SvPADMY(PL_curpad[ix])) {
		SvPADTMP_on(PL_curpad[ix]);
	    } else if (!SvFAKE(namep[ix])) {
		/* This is a work around for how the current implementation of
		   ?{ } blocks in regexps interacts with lexicals.

		   One of our lexicals.
		   Can't do this on all lexicals, otherwise sub baz() won't
		   compile in

		   my $foo;

		   sub bar { ++$foo; }

		   sub baz { ++$foo; }

		   because completion of compiling &bar calling pad_tidy()
		   would cause (top level) $foo to be marked as stale, and
		   "no longer available".  */
		SvPADSTALE_on(PL_curpad[ix]);
	    }
	}
    }
    PL_curpad = AvARRAY(PL_comppad);
}

/*
=for apidoc m|void|pad_free|PADOFFSET po

Free the SV at offset po in the current pad.

=cut
*/

/* XXX DAPM integrate with pad_swipe ???? */
void
Perl_pad_free(pTHX_ PADOFFSET po)
{
    dVAR;
    SV *sv;
    ASSERT_CURPAD_LEGAL("pad_free");
    if (!PL_curpad)
	return;
    if (AvARRAY(PL_comppad) != PL_curpad)
	Perl_croak(aTHX_ "panic: pad_free curpad, %p!=%p",
		   AvARRAY(PL_comppad), PL_curpad);
    if (!po)
	Perl_croak(aTHX_ "panic: pad_free po");

    DEBUG_X(PerlIO_printf(Perl_debug_log,
	    "Pad 0x%"UVxf"[0x%"UVxf"] free:    %ld\n",
	    PTR2UV(PL_comppad), PTR2UV(PL_curpad), (long)po)
    );


    sv = PL_curpad[po];
    if (sv && sv != &PL_sv_undef && !SvPADMY(sv))
	SvFLAGS(sv) &= ~SVs_PADTMP;

    if ((I32)po < PL_padix)
	PL_padix = po - 1;
}

/*
=for apidoc m|void|do_dump_pad|I32 level|PerlIO *file|PADLIST *padlist|int full

Dump the contents of a padlist

=cut
*/

void
Perl_do_dump_pad(pTHX_ I32 level, PerlIO *file, PADLIST *padlist, int full)
{
    dVAR;
    const AV *pad_name;
    const AV *pad;
    SV **pname;
    SV **ppad;
    I32 ix;

    PERL_ARGS_ASSERT_DO_DUMP_PAD;

    if (!padlist) {
	return;
    }
    pad_name = *PadlistARRAY(padlist);
    pad = PadlistARRAY(padlist)[1];
    pname = AvARRAY(pad_name);
    ppad = AvARRAY(pad);
    Perl_dump_indent(aTHX_ level, file,
	    "PADNAME = 0x%"UVxf"(0x%"UVxf") PAD = 0x%"UVxf"(0x%"UVxf")\n",
	    PTR2UV(pad_name), PTR2UV(pname), PTR2UV(pad), PTR2UV(ppad)
    );

    for (ix = 1; ix <= AvFILLp(pad_name); ix++) {
        const SV *namesv = pname[ix];
	if (namesv && !PadnameLEN(namesv)) {
	    namesv = NULL;
	}
	if (namesv) {
	    if (SvFAKE(namesv))
		Perl_dump_indent(aTHX_ level+1, file,
		    "%2d. 0x%"UVxf"<%lu> FAKE \"%s\" flags=0x%lx index=%lu\n",
		    (int) ix,
		    PTR2UV(ppad[ix]),
		    (unsigned long) (ppad[ix] ? SvREFCNT(ppad[ix]) : 0),
		    SvPVX_const(namesv),
		    (unsigned long)PARENT_FAKELEX_FLAGS(namesv),
		    (unsigned long)PARENT_PAD_INDEX(namesv)

		);
	    else
		Perl_dump_indent(aTHX_ level+1, file,
		    "%2d. 0x%"UVxf"<%lu> (%lu,%lu) \"%s\"\n",
		    (int) ix,
		    PTR2UV(ppad[ix]),
		    (unsigned long) (ppad[ix] ? SvREFCNT(ppad[ix]) : 0),
		    (unsigned long)COP_SEQ_RANGE_LOW(namesv),
		    (unsigned long)COP_SEQ_RANGE_HIGH(namesv),
		    SvPVX_const(namesv)
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

#ifdef DEBUGGING

/*
=for apidoc m|void|cv_dump|CV *cv|const char *title

dump the contents of a CV

=cut
*/

STATIC void
S_cv_dump(pTHX_ const CV *cv, const char *title)
{
    dVAR;
    const CV * const outside = CvOUTSIDE(cv);
    PADLIST* const padlist = CvPADLIST(cv);

    PERL_ARGS_ASSERT_CV_DUMP;

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
=for apidoc Am|CV *|cv_clone|CV *proto

Clone a CV, making a lexical closure.  I<proto> supplies the prototype
of the function: its code, pad structure, and other attributes.
The prototype is combined with a capture of outer lexicals to which the
code refers, which are taken from the currently-executing instance of
the immediately surrounding code.

=cut
*/

static CV *S_cv_clone(pTHX_ CV *proto, CV *cv, CV *outside);

static void
S_cv_clone_pad(pTHX_ CV *proto, CV *cv, CV *outside, bool newcv)
{
    dVAR;
    I32 ix;
    PADLIST* const protopadlist = CvPADLIST(proto);
    PAD *const protopad_name = *PadlistARRAY(protopadlist);
    const PAD *const protopad = PadlistARRAY(protopadlist)[1];
    SV** const pname = AvARRAY(protopad_name);
    SV** const ppad = AvARRAY(protopad);
    const I32 fname = AvFILLp(protopad_name);
    const I32 fpad = AvFILLp(protopad);
    SV** outpad;
    long depth;
    bool subclones = FALSE;

    assert(!CvUNIQUE(proto));

    /* Anonymous subs have a weak CvOUTSIDE pointer, so its value is not
     * reliable.  The currently-running sub is always the one we need to
     * close over.
     * For my subs, the currently-running sub may not be the one we want.
     * We have to check whether it is a clone of CvOUTSIDE.
     * Note that in general for formats, CvOUTSIDE != find_runcv.
     * Since formats may be nested inside closures, CvOUTSIDE may point
     * to a prototype; we instead want the cloned parent who called us.
     */

    if (!outside) {
      if (CvWEAKOUTSIDE(proto))
	outside = find_runcv(NULL);
      else {
	outside = CvOUTSIDE(proto);
	if ((CvCLONE(outside) && ! CvCLONED(outside))
	    || !CvPADLIST(outside)
	    || PadlistNAMES(CvPADLIST(outside))
		 != protopadlist->xpadl_outid) {
	    outside = find_runcv_where(
		FIND_RUNCV_padid_eq, PTR2IV(protopadlist->xpadl_outid), NULL
	    );
	    /* outside could be null */
	}
      }
    }
    depth = outside ? CvDEPTH(outside) : 0;
    if (!depth)
	depth = 1;

    ENTER;
    SAVESPTR(PL_compcv);
    PL_compcv = cv;
    if (newcv) SAVEFREESV(cv); /* in case of fatal warnings */

    if (CvHASEVAL(cv))
	CvOUTSIDE(cv)	= MUTABLE_CV(SvREFCNT_inc_simple(outside));

    SAVESPTR(PL_comppad_name);
    PL_comppad_name = protopad_name;
    CvPADLIST(cv) = pad_new(padnew_CLONE|padnew_SAVE);

    av_fill(PL_comppad, fpad);

    PL_curpad = AvARRAY(PL_comppad);

    outpad = outside && CvPADLIST(outside)
	? AvARRAY(PadlistARRAY(CvPADLIST(outside))[depth])
	: NULL;
    if (outpad)
	CvPADLIST(cv)->xpadl_outid = PadlistNAMES(CvPADLIST(outside));

    for (ix = fpad; ix > 0; ix--) {
	SV* const namesv = (ix <= fname) ? pname[ix] : NULL;
	SV *sv = NULL;
	if (namesv && PadnameLEN(namesv)) { /* lexical */
	  if (PadnameIsOUR(namesv)) { /* or maybe not so lexical */
		NOOP;
	  }
	  else {
	    if (SvFAKE(namesv)) {   /* lexical from outside? */
		/* formats may have an inactive, or even undefined, parent;
		   but state vars are always available. */
		if (!outpad || !(sv = outpad[PARENT_PAD_INDEX(namesv)])
		 || (  SvPADSTALE(sv) && !SvPAD_STATE(namesv)
		    && (!outside || !CvDEPTH(outside)))  ) {
		    S_unavailable(aTHX_ namesv);
		    sv = NULL;
		}
		else
		    SvREFCNT_inc_simple_void_NN(sv);
	    }
	    if (!sv) {
                const char sigil = SvPVX_const(namesv)[0];
                if (sigil == '&')
		    /* If there are state subs, we need to clone them, too.
		       But they may need to close over variables we have
		       not cloned yet.  So we will have to do a second
		       pass.  Furthermore, there may be state subs clos-
		       ing over other state subs’ entries, so we have
		       to put a stub here and then clone into it on the
		       second pass. */
		    if (SvPAD_STATE(namesv) && !CvCLONED(ppad[ix])) {
			assert(SvTYPE(ppad[ix]) == SVt_PVCV);
			subclones = 1;
			sv = newSV_type(SVt_PVCV);
		    }
		    else if (PadnameLEN(namesv)>1 && !PadnameIsOUR(namesv))
		    {
			/* my sub */
			/* Just provide a stub, but name it.  It will be
			   upgrade to the real thing on scope entry. */
			sv = newSV_type(SVt_PVCV);
			CvNAME_HEK_set(
			    sv,
			    share_hek(SvPVX_const(namesv)+1,
				      SvCUR(namesv) - 1
					 * (SvUTF8(namesv) ? -1 : 1),
				      0)
			);
		    }
		    else sv = SvREFCNT_inc(ppad[ix]);
                else if (sigil == '@')
		    sv = MUTABLE_SV(newAV());
                else if (sigil == '%')
		    sv = MUTABLE_SV(newHV());
		else
		    sv = newSV(0);
		SvPADMY_on(sv);
		/* reset the 'assign only once' flag on each state var */
		if (sigil != '&' && SvPAD_STATE(namesv))
		    SvPADSTALE_on(sv);
	    }
	  }
	}
	else if (IS_PADGV(ppad[ix]) || (namesv && PadnamePV(namesv))) {
	    sv = SvREFCNT_inc_NN(ppad[ix]);
	}
	else {
	    sv = newSV(0);
	    SvPADTMP_on(sv);
	}
	PL_curpad[ix] = sv;
    }

    if (subclones)
	for (ix = fpad; ix > 0; ix--) {
	    SV* const namesv = (ix <= fname) ? pname[ix] : NULL;
	    if (namesv && namesv != &PL_sv_undef && !SvFAKE(namesv)
	     && SvPVX_const(namesv)[0] == '&' && SvPAD_STATE(namesv))
		S_cv_clone(aTHX_ (CV *)ppad[ix], (CV *)PL_curpad[ix], cv);
	}

    if (newcv) SvREFCNT_inc_simple_void_NN(cv);
    LEAVE;
}

static CV *
S_cv_clone(pTHX_ CV *proto, CV *cv, CV *outside)
{
    dVAR;
    const bool newcv = !cv;

    assert(!CvUNIQUE(proto));

    if (!cv) cv = MUTABLE_CV(newSV_type(SvTYPE(proto)));
    CvFLAGS(cv) = CvFLAGS(proto) & ~(CVf_CLONE|CVf_WEAKOUTSIDE|CVf_CVGV_RC
				    |CVf_SLABBED);
    CvCLONED_on(cv);

    CvFILE(cv)		= CvDYNFILE(proto) ? savepv(CvFILE(proto))
					   : CvFILE(proto);
    if (CvNAMED(proto))
	 CvNAME_HEK_set(cv, share_hek_hek(CvNAME_HEK(proto)));
    else CvGV_set(cv,CvGV(proto));
    CvSTASH_set(cv, CvSTASH(proto));
    OP_REFCNT_LOCK;
    CvROOT(cv)		= OpREFCNT_inc(CvROOT(proto));
    OP_REFCNT_UNLOCK;
    CvSTART(cv)		= CvSTART(proto);
    CvOUTSIDE_SEQ(cv) = CvOUTSIDE_SEQ(proto);

    if (SvPOK(proto)) {
	sv_setpvn(MUTABLE_SV(cv), SvPVX_const(proto), SvCUR(proto));
        if (SvUTF8(proto))
           SvUTF8_on(MUTABLE_SV(cv));
    }
    if (SvMAGIC(proto))
	mg_copy((SV *)proto, (SV *)cv, 0, 0);

    if (CvPADLIST(proto)) S_cv_clone_pad(aTHX_ proto, cv, outside, newcv);

    DEBUG_Xv(
	PerlIO_printf(Perl_debug_log, "\nPad CV clone\n");
	if (CvOUTSIDE(cv)) cv_dump(CvOUTSIDE(cv), "Outside");
	cv_dump(proto,	 "Proto");
	cv_dump(cv,	 "To");
    );

    return cv;
}

CV *
Perl_cv_clone(pTHX_ CV *proto)
{
    PERL_ARGS_ASSERT_CV_CLONE;

    if (!CvPADLIST(proto)) Perl_croak(aTHX_ "panic: no pad in cv_clone");
    return S_cv_clone(aTHX_ proto, NULL, NULL);
}

/* Called only by pp_clonecv */
CV *
Perl_cv_clone_into(pTHX_ CV *proto, CV *target)
{
    PERL_ARGS_ASSERT_CV_CLONE_INTO;
    cv_undef(target);
    return S_cv_clone(aTHX_ proto, target, NULL);
}

/*
=for apidoc m|void|pad_fixup_inner_anons|PADLIST *padlist|CV *old_cv|CV *new_cv

For any anon CVs in the pad, change CvOUTSIDE of that CV from
old_cv to new_cv if necessary.  Needed when a newly-compiled CV has to be
moved to a pre-existing CV struct.

=cut
*/

void
Perl_pad_fixup_inner_anons(pTHX_ PADLIST *padlist, CV *old_cv, CV *new_cv)
{
    dVAR;
    I32 ix;
    AV * const comppad_name = PadlistARRAY(padlist)[0];
    AV * const comppad = PadlistARRAY(padlist)[1];
    SV ** const namepad = AvARRAY(comppad_name);
    SV ** const curpad = AvARRAY(comppad);

    PERL_ARGS_ASSERT_PAD_FIXUP_INNER_ANONS;
    PERL_UNUSED_ARG(old_cv);

    for (ix = AvFILLp(comppad_name); ix > 0; ix--) {
        const SV * const namesv = namepad[ix];
	if (namesv && namesv != &PL_sv_undef && !SvPAD_STATE(namesv)
	    && *SvPVX_const(namesv) == '&')
	{
	  if (SvTYPE(curpad[ix]) == SVt_PVCV) {
	    MAGIC * const mg =
		SvMAGICAL(curpad[ix])
		    ? mg_find(curpad[ix], PERL_MAGIC_proto)
		    : NULL;
	    CV * const innercv = MUTABLE_CV(mg ? mg->mg_obj : curpad[ix]);
	    if (CvOUTSIDE(innercv) == old_cv) {
		if (!CvWEAKOUTSIDE(innercv)) {
		    SvREFCNT_dec(old_cv);
		    SvREFCNT_inc_simple_void_NN(new_cv);
		}
		CvOUTSIDE(innercv) = new_cv;
	    }
	  }
	  else { /* format reference */
	    SV * const rv = curpad[ix];
	    CV *innercv;
	    if (!SvOK(rv)) continue;
	    assert(SvROK(rv));
	    assert(SvWEAKREF(rv));
	    innercv = (CV *)SvRV(rv);
	    assert(!CvWEAKOUTSIDE(innercv));
	    SvREFCNT_dec(CvOUTSIDE(innercv));
	    CvOUTSIDE(innercv) = (CV *)SvREFCNT_inc_simple_NN(new_cv);
	  }
	}
    }
}

/*
=for apidoc m|void|pad_push|PADLIST *padlist|int depth

Push a new pad frame onto the padlist, unless there's already a pad at
this depth, in which case don't bother creating a new one.  Then give
the new pad an @_ in slot zero.

=cut
*/

void
Perl_pad_push(pTHX_ PADLIST *padlist, int depth)
{
    dVAR;

    PERL_ARGS_ASSERT_PAD_PUSH;

    if (depth > PadlistMAX(padlist) || !PadlistARRAY(padlist)[depth]) {
	PAD** const svp = PadlistARRAY(padlist);
	AV* const newpad = newAV();
	SV** const oldpad = AvARRAY(svp[depth-1]);
	I32 ix = AvFILLp((const AV *)svp[1]);
        const I32 names_fill = AvFILLp((const AV *)svp[0]);
	SV** const names = AvARRAY(svp[0]);
	AV *av;

	for ( ;ix > 0; ix--) {
	    if (names_fill >= ix && PadnameLEN(names[ix])) {
		const char sigil = SvPVX_const(names[ix])[0];
		if ((SvFLAGS(names[ix]) & SVf_FAKE)
			|| (SvFLAGS(names[ix]) & SVpad_STATE)
			|| sigil == '&')
		{
		    /* outer lexical or anon code */
		    av_store(newpad, ix, SvREFCNT_inc(oldpad[ix]));
		}
		else {		/* our own lexical */
		    SV *sv;
		    if (sigil == '@')
			sv = MUTABLE_SV(newAV());
		    else if (sigil == '%')
			sv = MUTABLE_SV(newHV());
		    else
			sv = newSV(0);
		    av_store(newpad, ix, sv);
		    SvPADMY_on(sv);
		}
	    }
	    else if (IS_PADGV(oldpad[ix]) || PadnamePV(names[ix])) {
		av_store(newpad, ix, SvREFCNT_inc_NN(oldpad[ix]));
	    }
	    else {
		/* save temporaries on recursion? */
		SV * const sv = newSV(0);
		av_store(newpad, ix, sv);
		SvPADTMP_on(sv);
	    }
	}
	av = newAV();
	av_store(newpad, 0, MUTABLE_SV(av));
	AvREIFY_only(av);

	padlist_store(padlist, depth, newpad);
    }
}

/*
=for apidoc Am|HV *|pad_compname_type|PADOFFSET po

Looks up the type of the lexical variable at position I<po> in the
currently-compiling pad.  If the variable is typed, the stash of the
class to which it is typed is returned.  If not, C<NULL> is returned.

=cut
*/

HV *
Perl_pad_compname_type(pTHX_ const PADOFFSET po)
{
    dVAR;
    SV* const * const av = av_fetch(PL_comppad_name, po, FALSE);
    if ( SvPAD_TYPED(*av) ) {
        return SvSTASH(*av);
    }
    return NULL;
}

#if defined(USE_ITHREADS)

#  define av_dup_inc(s,t)	MUTABLE_AV(sv_dup_inc((const SV *)s,t))

/*
=for apidoc padlist_dup

Duplicates a pad.

=cut
*/

PADLIST *
Perl_padlist_dup(pTHX_ PADLIST *srcpad, CLONE_PARAMS *param)
{
    PADLIST *dstpad;
    bool cloneall;
    PADOFFSET max;

    PERL_ARGS_ASSERT_PADLIST_DUP;

    if (!srcpad)
	return NULL;

    cloneall = param->flags & CLONEf_COPY_STACKS
	|| SvREFCNT(PadlistARRAY(srcpad)[1]) > 1;
    assert (SvREFCNT(PadlistARRAY(srcpad)[1]) == 1);

    max = cloneall ? PadlistMAX(srcpad) : 1;

    Newx(dstpad, 1, PADLIST);
    ptr_table_store(PL_ptr_table, srcpad, dstpad);
    PadlistMAX(dstpad) = max;
    Newx(PadlistARRAY(dstpad), max + 1, PAD *);

    if (cloneall) {
	PADOFFSET depth;
	for (depth = 0; depth <= max; ++depth)
	    PadlistARRAY(dstpad)[depth] =
		av_dup_inc(PadlistARRAY(srcpad)[depth], param);
    } else {
	/* CvDEPTH() on our subroutine will be set to 0, so there's no need
	   to build anything other than the first level of pads.  */
	I32 ix = AvFILLp(PadlistARRAY(srcpad)[1]);
	AV *pad1;
	const I32 names_fill = AvFILLp(PadlistARRAY(srcpad)[0]);
	const PAD *const srcpad1 = PadlistARRAY(srcpad)[1];
	SV **oldpad = AvARRAY(srcpad1);
	SV **names;
	SV **pad1a;
	AV *args;

	PadlistARRAY(dstpad)[0] =
	    av_dup_inc(PadlistARRAY(srcpad)[0], param);
	names = AvARRAY(PadlistARRAY(dstpad)[0]);

	pad1 = newAV();

	av_extend(pad1, ix);
	PadlistARRAY(dstpad)[1] = pad1;
	pad1a = AvARRAY(pad1);

	if (ix > -1) {
	    AvFILLp(pad1) = ix;

	    for ( ;ix > 0; ix--) {
		if (!oldpad[ix]) {
		    pad1a[ix] = NULL;
		} else if (names_fill >= ix && names[ix] &&
			   PadnameLEN(names[ix])) {
		    const char sigil = SvPVX_const(names[ix])[0];
		    if ((SvFLAGS(names[ix]) & SVf_FAKE)
			|| (SvFLAGS(names[ix]) & SVpad_STATE)
			|| sigil == '&')
			{
			    /* outer lexical or anon code */
			    pad1a[ix] = sv_dup_inc(oldpad[ix], param);
			}
		    else {		/* our own lexical */
			if(SvPADSTALE(oldpad[ix]) && SvREFCNT(oldpad[ix]) > 1) {
			    /* This is a work around for how the current
			       implementation of ?{ } blocks in regexps
			       interacts with lexicals.  */
			    pad1a[ix] = sv_dup_inc(oldpad[ix], param);
			} else {
			    SV *sv;

			    if (sigil == '@')
				sv = MUTABLE_SV(newAV());
			    else if (sigil == '%')
				sv = MUTABLE_SV(newHV());
			    else
				sv = newSV(0);
			    pad1a[ix] = sv;
			    SvPADMY_on(sv);
			}
		    }
		}
		else if (IS_PADGV(oldpad[ix])
		      || (  names_fill >= ix && names[ix]
			 && PadnamePV(names[ix])  )) {
		    pad1a[ix] = sv_dup_inc(oldpad[ix], param);
		}
		else {
		    /* save temporaries on recursion? */
		    SV * const sv = newSV(0);
		    pad1a[ix] = sv;

		    /* SvREFCNT(oldpad[ix]) != 1 for some code in threads.xs
		       FIXTHAT before merging this branch.
		       (And I know how to) */
		    if (SvPADMY(oldpad[ix]))
			SvPADMY_on(sv);
		    else
			SvPADTMP_on(sv);
		}
	    }

	    if (oldpad[0]) {
		args = newAV();			/* Will be @_ */
		AvREIFY_only(args);
		pad1a[0] = (SV *)args;
	    }
	}
    }

    return dstpad;
}

#endif /* USE_ITHREADS */

PAD **
Perl_padlist_store(pTHX_ PADLIST *padlist, I32 key, PAD *val)
{
    dVAR;
    PAD **ary;
    SSize_t const oldmax = PadlistMAX(padlist);

    PERL_ARGS_ASSERT_PADLIST_STORE;

    assert(key >= 0);

    if (key > PadlistMAX(padlist)) {
	av_extend_guts(NULL,key,&PadlistMAX(padlist),
		       (SV ***)&PadlistARRAY(padlist),
		       (SV ***)&PadlistARRAY(padlist));
	Zero(PadlistARRAY(padlist)+oldmax+1, PadlistMAX(padlist)-oldmax,
	     PAD *);
    }
    ary = PadlistARRAY(padlist);
    SvREFCNT_dec(ary[key]);
    ary[key] = val;
    return &ary[key];
}

/*
 * Local variables:
 * c-indentation-style: bsd
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 *
 * ex: set ts=8 sts=4 sw=4 et:
 */
