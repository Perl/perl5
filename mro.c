/*    mro.c
 *
 *    Copyright (c) 2007 Brandon L Black
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

/*
 * "Which order shall we go in?" said Frodo. "Eldest first, or quickest first?
 *  You'll be last either way, Master Peregrin."
 */

/*
=head1 MRO Functions

These functions are related to the method resolution order of perl classes

=cut
*/

#include "EXTERN.h"
#include "perl.h"

struct mro_meta*
Perl_mro_meta_init(pTHX_ HV* stash)
{
    struct mro_meta* newmeta;

    assert(stash);
    assert(HvAUX(stash));
    assert(!(HvAUX(stash)->xhv_mro_meta));
    Newxz(newmeta, 1, struct mro_meta);
    HvAUX(stash)->xhv_mro_meta = newmeta;
    newmeta->sub_generation = 1;

    /* Manually flag UNIVERSAL as being universal.
       This happens early in perl booting (when universal.c
       does the newXS calls for UNIVERSAL::*), and infects
       other packages as they are added to UNIVERSAL's MRO
    */
    if(HvNAMELEN_get(stash) == 9
       && strEQ(HEK_KEY(HvAUX(stash)->xhv_name), "UNIVERSAL")) {
            HvMROMETA(stash)->is_universal = 1;
    }

    return newmeta;
}

#if defined(USE_ITHREADS)

/* for sv_dup on new threads */
struct mro_meta*
Perl_mro_meta_dup(pTHX_ struct mro_meta* smeta, CLONE_PARAMS* param)
{
    struct mro_meta* newmeta;

    assert(smeta);

    Newx(newmeta, 1, struct mro_meta);
    Copy(smeta, newmeta, 1, struct mro_meta);

    if (newmeta->mro_linear_dfs)
	newmeta->mro_linear_dfs
	    = (AV*) SvREFCNT_inc(sv_dup((SV*)newmeta->mro_linear_dfs, param));
    if (newmeta->mro_linear_c3)
	newmeta->mro_linear_c3
	    = (AV*) SvREFCNT_inc(sv_dup((SV*)newmeta->mro_linear_c3, param));
    if (newmeta->mro_isarev)
	newmeta->mro_isarev
	    = (HV*) SvREFCNT_inc(sv_dup((SV*)newmeta->mro_isarev, param));
    if (newmeta->mro_nextmethod)
	newmeta->mro_nextmethod
	    = (HV*) SvREFCNT_inc(sv_dup((SV*)newmeta->mro_nextmethod, param));

    return newmeta;
}

#endif /* USE_ITHREADS */

/*
=for apidoc mro_get_linear_isa_dfs

Returns the Depth-First Search linearization of @ISA
the given stash.  The return value is a read-only AV*.
C<level> should be 0 (it is used internally in this
function's recursion).

You are responsible for C<SvREFCNT_inc()> on the
return value if you plan to store it anywhere
semi-permanently (otherwise it might be deleted
out from under you the next time the cache is
invalidated).

=cut
*/
AV*
Perl_mro_get_linear_isa_dfs(pTHX_ HV *stash, I32 level)
{
    AV* retval;
    GV** gvp;
    GV* gv;
    AV* av;
    const char* stashname;
    struct mro_meta* meta;

    assert(stash);
    assert(HvAUX(stash));

    stashname = HvNAME_get(stash);
    if (!stashname)
      Perl_croak(aTHX_
                 "Can't linearize anonymous symbol table");

    if (level > 100)
        Perl_croak(aTHX_ "Recursive inheritance detected in package '%s'",
              stashname);

    meta = HvMROMETA(stash);

    /* return cache if valid */
    if((retval = meta->mro_linear_dfs)) {
        return retval;
    }

    /* not in cache, make a new one */

    retval = newAV();
    av_push(retval, newSVpv(stashname, 0)); /* add ourselves at the top */

    /* fetch our @ISA */
    gvp = (GV**)hv_fetchs(stash, "ISA", FALSE);
    av = (gvp && (gv = *gvp) && isGV_with_GP(gv)) ? GvAV(gv) : NULL;

    if(av && AvFILLp(av) >= 0) {

        /* "stored" is used to keep track of all of the classnames
           we have added to the MRO so far, so we can do a quick
           exists check and avoid adding duplicate classnames to
           the MRO as we go. */

        HV* stored = (HV*)sv_2mortal((SV*)newHV());
        SV **svp = AvARRAY(av);
        I32 items = AvFILLp(av) + 1;

        /* foreach(@ISA) */
        while (items--) {
            SV* const sv = *svp++;
            HV* const basestash = gv_stashsv(sv, 0);
	    SV *const *subrv_p;
	    I32 subrv_items;

            if (!basestash) {
                /* if no stash exists for this @ISA member,
                   simply add it to the MRO and move on */
		subrv_p = &sv;
		subrv_items = 1;
            }
            else {
                /* otherwise, recurse into ourselves for the MRO
                   of this @ISA member, and append their MRO to ours */
		const AV *const subrv
		    = mro_get_linear_isa_dfs(basestash, level + 1);

		subrv_p = AvARRAY(subrv);
		subrv_items = AvFILLp(subrv) + 1;
	    }
	    while(subrv_items--) {
		SV *const subsv = *subrv_p++;
		if(!hv_exists_ent(stored, subsv, 0)) {
		    av_push(retval, newSVsv(subsv));
		    hv_store_ent(stored, subsv, &PL_sv_undef, 0);
		}
            }
        }
    }

    /* we don't want anyone modifying the cache entry but us,
       and we do so by replacing it completely */
    SvREADONLY_on(retval);

    meta->mro_linear_dfs = retval;
    return retval;
}

/*
=for apidoc mro_get_linear_isa_c3

Returns the C3 linearization of @ISA
the given stash.  The return value is a read-only AV*.
C<level> should be 0 (it is used internally in this
function's recursion).

You are responsible for C<SvREFCNT_inc()> on the
return value if you plan to store it anywhere
semi-permanently (otherwise it might be deleted
out from under you the next time the cache is
invalidated).

=cut
*/

AV*
Perl_mro_get_linear_isa_c3(pTHX_ HV* stash, I32 level)
{
    AV* retval;
    GV** gvp;
    GV* gv;
    AV* isa;
    const char* stashname;
    STRLEN stashname_len;
    struct mro_meta* meta;

    assert(stash);
    assert(HvAUX(stash));

    stashname = HvNAME_get(stash);
    stashname_len = HvNAMELEN_get(stash);
    if (!stashname)
      Perl_croak(aTHX_
                 "Can't linearize anonymous symbol table");

    if (level > 100)
        Perl_croak(aTHX_ "Recursive inheritance detected in package '%s'",
              stashname);

    meta = HvMROMETA(stash);

    /* return cache if valid */
    if((retval = meta->mro_linear_c3)) {
        return retval;
    }

    /* not in cache, make a new one */

    retval = newAV();
    av_push(retval, newSVpvn(stashname, stashname_len)); /* us first */

    gvp = (GV**)hv_fetchs(stash, "ISA", FALSE);
    isa = (gvp && (gv = *gvp) && isGV_with_GP(gv)) ? GvAV(gv) : NULL;

    /* For a better idea how the rest of this works, see the much clearer
       pure perl version in Algorithm::C3 0.01:
       http://search.cpan.org/src/STEVAN/Algorithm-C3-0.01/lib/Algorithm/C3.pm
       (later versions go about it differently than this code for speed reasons)
    */
    if(isa && AvFILLp(isa) >= 0) {
        SV** seqs_ptr;
        I32 seqs_items;
        HV* tails = (HV*)sv_2mortal((SV*)newHV());
        AV* seqs = (AV*)sv_2mortal((SV*)newAV());
        I32 items = AvFILLp(isa) + 1;
        SV** isa_ptr = AvARRAY(isa);
        while(items--) {
            AV* isa_lin;
            SV* isa_item = *isa_ptr++;
            HV* isa_item_stash = gv_stashsv(isa_item, 0);
            if(!isa_item_stash) {
                isa_lin = newAV();
                av_push(isa_lin, newSVsv(isa_item));
            }
            else {
                isa_lin = mro_get_linear_isa_c3(isa_item_stash, level + 1); /* recursion */
            }
            av_push(seqs, (SV*)av_make(AvFILLp(isa_lin)+1, AvARRAY(isa_lin)));
        }
        av_push(seqs, (SV*)av_make(AvFILLp(isa)+1, AvARRAY(isa)));

        seqs_ptr = AvARRAY(seqs);
        seqs_items = AvFILLp(seqs) + 1;
        while(seqs_items--) {
            AV* seq = (AV*)*seqs_ptr++;
            I32 seq_items = AvFILLp(seq);
            if(seq_items > 0) {
                SV** seq_ptr = AvARRAY(seq) + 1;
                while(seq_items--) {
                    SV* seqitem = *seq_ptr++;
                    HE* he = hv_fetch_ent(tails, seqitem, 0, 0);
                    if(!he) {
                        hv_store_ent(tails, seqitem, newSViv(1), 0);
                    }
                    else {
                        SV* val = HeVAL(he);
                        sv_inc(val);
                    }
                }
            }
        }

        while(1) {
            SV* seqhead = NULL;
            SV* cand = NULL;
            SV* winner = NULL;
            SV* val;
            HE* tail_entry;
            AV* seq;
            SV** avptr = AvARRAY(seqs);
            items = AvFILLp(seqs)+1;
            while(items--) {
                SV** svp;
                seq = (AV*)*avptr++;
                if(AvFILLp(seq) < 0) continue;
                svp = av_fetch(seq, 0, 0);
                seqhead = *svp;
                if(!winner) {
                    cand = seqhead;
                    if((tail_entry = hv_fetch_ent(tails, cand, 0, 0))
                       && (val = HeVAL(tail_entry))
                       && (SvIVx(val) > 0))
                           continue;
                    winner = newSVsv(cand);
                    av_push(retval, winner);
                }
                if(!sv_cmp(seqhead, winner)) {

                    /* this is basically shift(@seq) in void context */
                    SvREFCNT_dec(*AvARRAY(seq));
                    *AvARRAY(seq) = &PL_sv_undef;
                    AvARRAY(seq) = AvARRAY(seq) + 1;
                    AvMAX(seq)--;
                    AvFILLp(seq)--;

                    if(AvFILLp(seq) < 0) continue;
                    svp = av_fetch(seq, 0, 0);
                    seqhead = *svp;
                    tail_entry = hv_fetch_ent(tails, seqhead, 0, 0);
                    val = HeVAL(tail_entry);
                    sv_dec(val);
                }
            }
            if(!cand) break;
            if(!winner) {
                SvREFCNT_dec(retval);
                Perl_croak(aTHX_ "Inconsistent hierarchy during C3 merge of class '%s': "
                    "merging failed on parent '%"SVf"'", stashname, SVfARG(cand));
            }
        }
    }

    /* we don't want anyone modifying the cache entry but us,
       and we do so by replacing it completely */
    SvREADONLY_on(retval);

    meta->mro_linear_c3 = retval;
    return retval;
}

/*
=for apidoc mro_get_linear_isa

Returns either C<mro_get_linear_isa_c3> or
C<mro_get_linear_isa_dfs> for the given stash,
dependant upon which MRO is in effect
for that stash.  The return value is a
read-only AV*.

You are responsible for C<SvREFCNT_inc()> on the
return value if you plan to store it anywhere
semi-permanently (otherwise it might be deleted
out from under you the next time the cache is
invalidated).

=cut
*/
AV*
Perl_mro_get_linear_isa(pTHX_ HV *stash)
{
    struct mro_meta* meta;
    assert(stash);
    assert(HvAUX(stash));

    meta = HvMROMETA(stash);
    if(meta->mro_which == MRO_DFS) {
        return mro_get_linear_isa_dfs(stash, 0);
    } else if(meta->mro_which == MRO_C3) {
        return mro_get_linear_isa_c3(stash, 0);
    } else {
        Perl_croak(aTHX_ "panic: invalid MRO!");
    }
}

/*
=for apidoc mro_isa_changed_in

Takes the necessary steps (cache invalidations, mostly)
when the @ISA of the given package has changed.  Invoked
by the C<setisa> magic, should not need to invoke directly.

=cut
*/
void
Perl_mro_isa_changed_in(pTHX_ HV* stash)
{
    dVAR;
    HV* isarev;
    AV* linear_mro;
    HE* iter;
    SV** svp;
    I32 items;
    struct mro_meta* meta;
    char* stashname;

    stashname = HvNAME_get(stash);

    /* wipe out the cached linearizations for this stash */
    meta = HvMROMETA(stash);
    SvREFCNT_dec((SV*)meta->mro_linear_dfs);
    SvREFCNT_dec((SV*)meta->mro_linear_c3);
    meta->mro_linear_dfs = NULL;
    meta->mro_linear_c3 = NULL;

    /* Wipe the global method cache if this package
       is UNIVERSAL or one of its parents */
    if(meta->is_universal)
        PL_sub_generation++;

    /* Wipe the local method cache otherwise */
    else
        meta->sub_generation++;

    /* wipe next::method cache too */
    if(meta->mro_nextmethod) hv_clear(meta->mro_nextmethod);
    
    /* Iterate the isarev (classes that are our children),
       wiping out their linearization and method caches */
    if((isarev = meta->mro_isarev)) {
        hv_iterinit(isarev);
        while((iter = hv_iternext(isarev))) {
            SV* revkey = hv_iterkeysv(iter);
            HV* revstash = gv_stashsv(revkey, 0);
            struct mro_meta* revmeta = HvMROMETA(revstash);
            SvREFCNT_dec((SV*)revmeta->mro_linear_dfs);
            SvREFCNT_dec((SV*)revmeta->mro_linear_c3);
            revmeta->mro_linear_dfs = NULL;
            revmeta->mro_linear_c3 = NULL;
            if(!meta->is_universal)
                revmeta->sub_generation++;
            if(revmeta->mro_nextmethod)
                hv_clear(revmeta->mro_nextmethod);
        }
    }

    /* Now iterate our MRO (parents), and do a few things:
         1) instantiate with the "fake" flag if they don't exist
         2) flag them as universal if we are universal
         3) Add everything from our isarev to their isarev
    */

    /* We're starting at the 2nd element, skipping ourselves here */
    linear_mro = mro_get_linear_isa(stash);
    svp = AvARRAY(linear_mro) + 1;
    items = AvFILLp(linear_mro);

    while (items--) {
        SV* const sv = *svp++;
        struct mro_meta* mrometa;
        HV* mroisarev;

        HV* mrostash = gv_stashsv(sv, 0);
        if(!mrostash) {
            mrostash = gv_stashsv(sv, GV_ADD);
            /*
               We created the package on the fly, so
               that we could store isarev information.
               This flag lets gv_fetchmeth know about it,
               so that it can still generate the very useful
               "Can't locate package Foo for @Bar::ISA" warning.
            */
            HvMROMETA(mrostash)->fake = 1;
        }

        mrometa = HvMROMETA(mrostash);
        mroisarev = mrometa->mro_isarev;

        /* is_universal is viral */
        if(meta->is_universal)
            mrometa->is_universal = 1;

        if(!mroisarev)
            mroisarev = mrometa->mro_isarev = newHV();

        if(!hv_exists(mroisarev, stashname, strlen(stashname)))
            hv_store(mroisarev, stashname, strlen(stashname), &PL_sv_yes, 0);

        if(isarev) {
            hv_iterinit(isarev);
            while((iter = hv_iternext(isarev))) {
                SV* revkey = hv_iterkeysv(iter);
                if(!hv_exists_ent(mroisarev, revkey, 0))
                    hv_store_ent(mroisarev, revkey, &PL_sv_yes, 0);
            }
        }
    }
}

/*
=for apidoc mro_method_changed_in

Like C<mro_isa_changed_in>, but invalidates method
caching on any child classes of the given stash, so
that they might notice the changes in this one.

Ideally, all instances of C<PL_sub_generation++> in
the perl source should be replaced by calls to this.
Some already are, but some are more difficult to
replace.

Perl has always had problems with method caches
getting out of sync when one directly manipulates
stashes via things like C<%{Foo::} = %{Bar::}> or 
C<${Foo::}{bar} = ...> or the equivalent.  If
you do this in core or XS code, call this afterwards
on the destination stash to get things back in sync.

If you're doing such a thing from pure perl, use
C<mro::method_changed_in(classname)>, which
just calls this.

=cut
*/
void
Perl_mro_method_changed_in(pTHX_ HV *stash)
{
    struct mro_meta* meta = HvMROMETA(stash);
    HV* isarev;
    HE* iter;

    /* If stash is UNIVERSAL, or one of UNIVERSAL's parents,
       invalidate all method caches globally */
    if(meta->is_universal) {
        PL_sub_generation++;
        return;
    }

    /* else, invalidate the method caches of all child classes,
       but not itself */
    if((isarev = meta->mro_isarev)) {
        hv_iterinit(isarev);
        while((iter = hv_iternext(isarev))) {
            SV* revkey = hv_iterkeysv(iter);
            HV* revstash = gv_stashsv(revkey, 0);
            struct mro_meta* mrometa = HvMROMETA(revstash);
            mrometa->sub_generation++;
            if(mrometa->mro_nextmethod)
                hv_clear(mrometa->mro_nextmethod);
        }
    }
}

/* These two are static helpers for next::method and friends,
   and re-implement a bunch of the code from pp_caller() in
   a more efficient manner for this particular usage.
*/

STATIC I32
__dopoptosub_at(const PERL_CONTEXT *cxstk, I32 startingblock) {
    I32 i;
    for (i = startingblock; i >= 0; i--) {
        if(CxTYPE((PERL_CONTEXT*)(&cxstk[i])) == CXt_SUB) return i;
    }
    return i;
}

STATIC SV*
__nextcan(pTHX_ SV* self, I32 throw_nomethod)
{
    register I32 cxix;
    register const PERL_CONTEXT *ccstack = cxstack;
    const PERL_SI *top_si = PL_curstackinfo;
    HV* selfstash;
    GV* cvgv;
    SV *stashname;
    const char *fq_subname;
    const char *subname;
    STRLEN fq_subname_len;
    STRLEN stashname_len;
    STRLEN subname_len;
    SV* sv;
    GV** gvp;
    AV* linear_av;
    SV** linear_svp;
    SV* linear_sv;
    HV* curstash;
    GV* candidate = NULL;
    CV* cand_cv = NULL;
    const char *hvname;
    I32 items;
    struct mro_meta* selfmeta;
    HV* nmcache;
    HE* cache_entry;

    if(sv_isobject(self))
        selfstash = SvSTASH(SvRV(self));
    else
        selfstash = gv_stashsv(self, 0);

    assert(selfstash);

    hvname = HvNAME_get(selfstash);
    if (!hvname)
        Perl_croak(aTHX_ "Can't use anonymous symbol table for method lookup");

    cxix = __dopoptosub_at(cxstack, cxstack_ix);

    /* This block finds the contextually-enclosing fully-qualified subname,
       much like looking at (caller($i))[3] until you find a real sub that
       isn't ANON, etc */
    for (;;) {
        /* we may be in a higher stacklevel, so dig down deeper */
        while (cxix < 0) {
            if(top_si->si_type == PERLSI_MAIN)
                Perl_croak(aTHX_ "next::method/next::can/maybe::next::method must be used in method context");
            top_si = top_si->si_prev;
            ccstack = top_si->si_cxstack;
            cxix = __dopoptosub_at(ccstack, top_si->si_cxix);
        }

        if(CxTYPE((PERL_CONTEXT*)(&ccstack[cxix])) != CXt_SUB
          || (PL_DBsub && GvCV(PL_DBsub) && ccstack[cxix].blk_sub.cv == GvCV(PL_DBsub))) {
            cxix = __dopoptosub_at(ccstack, cxix - 1);
            continue;
        }

        {
            const I32 dbcxix = __dopoptosub_at(ccstack, cxix - 1);
            if (PL_DBsub && GvCV(PL_DBsub) && dbcxix >= 0 && ccstack[dbcxix].blk_sub.cv == GvCV(PL_DBsub)) {
                if(CxTYPE((PERL_CONTEXT*)(&ccstack[dbcxix])) != CXt_SUB) {
                    cxix = dbcxix;
                    continue;
                }
            }
        }

        cvgv = CvGV(ccstack[cxix].blk_sub.cv);

        if(!isGV(cvgv)) {
            cxix = __dopoptosub_at(ccstack, cxix - 1);
            continue;
        }

        /* we found a real sub here */
        sv = sv_2mortal(newSV(0));

        gv_efullname3(sv, cvgv, NULL);

        fq_subname = SvPVX(sv);
        fq_subname_len = SvCUR(sv);

        subname = strrchr(fq_subname, ':');
        if(!subname)
            Perl_croak(aTHX_ "next::method/next::can/maybe::next::method cannot find enclosing method");

        subname++;
        subname_len = fq_subname_len - (subname - fq_subname);
        if(subname_len == 8 && strEQ(subname, "__ANON__")) {
            cxix = __dopoptosub_at(ccstack, cxix - 1);
            continue;
        }
        break;
    }

    /* If we made it to here, we found our context */

    /* Initialize the next::method cache for this stash
       if necessary */
    selfmeta = HvMROMETA(selfstash);
    if(!(nmcache = selfmeta->mro_nextmethod)) {
        nmcache = selfmeta->mro_nextmethod = newHV();
    }

    /* Use the cached coderef if it exists */
    else if((cache_entry = hv_fetch_ent(nmcache, sv, 0, 0))) {
        SV* val = HeVAL(cache_entry);
        if(val == &PL_sv_undef) {
            if(throw_nomethod)
                Perl_croak(aTHX_ "No next::method '%s' found for %s", subname, hvname);
        }
        return val;
    }

    /* beyond here is just for cache misses, so perf isn't as critical */

    stashname_len = subname - fq_subname - 2;
    stashname = sv_2mortal(newSVpvn(fq_subname, stashname_len));

    linear_av = mro_get_linear_isa_c3(selfstash, 0); /* has ourselves at the top of the list */

    linear_svp = AvARRAY(linear_av);
    items = AvFILLp(linear_av) + 1;

    /* Walk down our MRO, skipping everything up
       to the contextually enclosing class */
    while (items--) {
        linear_sv = *linear_svp++;
        assert(linear_sv);
        if(sv_eq(linear_sv, stashname))
            break;
    }

    /* Now search the remainder of the MRO for the
       same method name as the contextually enclosing
       method */
    if(items > 0) {
        while (items--) {
            linear_sv = *linear_svp++;
            assert(linear_sv);
            curstash = gv_stashsv(linear_sv, FALSE);

            if (!curstash || (HvMROMETA(curstash)->fake && !HvFILL(curstash))) {
                if (ckWARN(WARN_SYNTAX))
                    Perl_warner(aTHX_ packWARN(WARN_SYNTAX), "Can't locate package %"SVf" for @%s::ISA",
                        (void*)linear_sv, hvname);
                continue;
            }

            assert(curstash);

            gvp = (GV**)hv_fetch(curstash, subname, subname_len, 0);
            if (!gvp) continue;

            candidate = *gvp;
            assert(candidate);

            if (SvTYPE(candidate) != SVt_PVGV)
                gv_init(candidate, curstash, subname, subname_len, TRUE);

            /* Notably, we only look for real entries, not method cache
               entries, because in C3 the method cache of a parent is not
               valid for the child */
            if (SvTYPE(candidate) == SVt_PVGV && (cand_cv = GvCV(candidate)) && !GvCVGEN(candidate)) {
                SvREFCNT_inc_simple_void_NN((SV*)cand_cv);
                hv_store_ent(nmcache, newSVsv(sv), (SV*)cand_cv, 0);
                return (SV*)cand_cv;
            }
        }
    }

    hv_store_ent(nmcache, newSVsv(sv), &PL_sv_undef, 0);
    if(throw_nomethod)
        Perl_croak(aTHX_ "No next::method '%s' found for %s", subname, hvname);
    return &PL_sv_undef;
}

#include "XSUB.h"

XS(XS_mro_get_linear_isa);
XS(XS_mro_set_mro);
XS(XS_mro_get_mro);
XS(XS_mro_get_isarev);
XS(XS_mro_is_universal);
XS(XS_mro_get_global_sub_generation);
XS(XS_mro_invalidate_all_method_caches);
XS(XS_mro_get_sub_generation);
XS(XS_mro_method_changed_in);
XS(XS_next_can);
XS(XS_next_method);
XS(XS_maybe_next_method);

void
Perl_boot_core_mro(pTHX)
{
    dVAR;
    static const char file[] = __FILE__;

    newXSproto("mro::get_linear_isa", XS_mro_get_linear_isa, file, "$;$");
    newXSproto("mro::set_mro", XS_mro_set_mro, file, "$$");
    newXSproto("mro::get_mro", XS_mro_get_mro, file, "$");
    newXSproto("mro::get_isarev", XS_mro_get_isarev, file, "$");
    newXSproto("mro::is_universal", XS_mro_is_universal, file, "$");
    newXSproto("mro::get_global_sub_generation", XS_mro_get_global_sub_generation, file, "");
    newXSproto("mro::invalidate_all_method_caches", XS_mro_invalidate_all_method_caches, file, "");
    newXSproto("mro::get_sub_generation", XS_mro_get_sub_generation, file, "$");
    newXSproto("mro::method_changed_in", XS_mro_method_changed_in, file, "$");
    newXS("next::can", XS_next_can, file);
    newXS("next::method", XS_next_method, file);
    newXS("maybe::next::method", XS_maybe_next_method, file);
}

XS(XS_mro_get_linear_isa) {
    dVAR;
    dXSARGS;
    AV* RETVAL;
    HV* class_stash;
    SV* classname;

    PERL_UNUSED_ARG(cv);

    if(items < 1 || items > 2)
       Perl_croak(aTHX_ "Usage: mro::get_linear_isa(classname [, type ])");

    classname = ST(0);
    class_stash = gv_stashsv(classname, 0);
    if(!class_stash) Perl_croak(aTHX_ "No such class: '%"SVf"'!", SVfARG(classname));

    if(items > 1) {
        char* which = SvPV_nolen(ST(1));
        if(strEQ(which, "dfs"))
            RETVAL = mro_get_linear_isa_dfs(class_stash, 0);
        else if(strEQ(which, "c3"))
            RETVAL = mro_get_linear_isa_c3(class_stash, 0);
        else
            Perl_croak(aTHX_ "Invalid mro name: '%s'", which);
    }
    else {
        RETVAL = mro_get_linear_isa(class_stash);
    }

    ST(0) = newRV_inc((SV*)RETVAL);
    sv_2mortal(ST(0));
    XSRETURN(1);
}

XS(XS_mro_set_mro)
{
    dVAR;
    dXSARGS;
    SV* classname;
    char* whichstr;
    mro_alg which;
    HV* class_stash;
    struct mro_meta* meta;

    PERL_UNUSED_ARG(cv);

    if (items != 2)
       Perl_croak(aTHX_ "Usage: mro::set_mro(classname, type)");

    classname = ST(0);
    whichstr = SvPV_nolen(ST(1));
    class_stash = gv_stashsv(classname, GV_ADD);
    if(!class_stash) Perl_croak(aTHX_ "Cannot create class: '%"SVf"'!", SVfARG(classname));
    meta = HvMROMETA(class_stash);

    if(strEQ(whichstr, "dfs"))
        which = MRO_DFS;
    else if(strEQ(whichstr, "c3"))
        which = MRO_C3;
    else
        Perl_croak(aTHX_ "Invalid mro name: '%s'", whichstr);

    if(meta->mro_which != which) {
        meta->mro_which = which;
        /* Only affects local method cache, not
           even child classes */
        meta->sub_generation++;
        if(meta->mro_nextmethod)
            hv_clear(meta->mro_nextmethod);
    }

    XSRETURN_EMPTY;
}


XS(XS_mro_get_mro)
{
    dVAR;
    dXSARGS;
    SV* classname;
    HV* class_stash;
    struct mro_meta* meta;

    PERL_UNUSED_ARG(cv);

    if (items != 1)
       Perl_croak(aTHX_ "Usage: mro::get_mro(classname)");

    classname = ST(0);
    class_stash = gv_stashsv(classname, 0);
    if(!class_stash) Perl_croak(aTHX_ "No such class: '%"SVf"'!", SVfARG(classname));
    meta = HvMROMETA(class_stash);

    if(meta->mro_which == MRO_DFS)
        ST(0) = sv_2mortal(newSVpvn("dfs", 3));
    else
        ST(0) = sv_2mortal(newSVpvn("c3", 2));

    XSRETURN(1);
}

XS(XS_mro_get_isarev)
{
    dVAR;
    dXSARGS;
    SV* classname;
    HV* class_stash;
    HV* isarev;

    PERL_UNUSED_ARG(cv);

    if (items != 1)
       Perl_croak(aTHX_ "Usage: mro::get_isarev(classname)");

    classname = ST(0);

    class_stash = gv_stashsv(classname, 0);
    if(!class_stash) Perl_croak(aTHX_ "No such class: '%"SVf"'!", SVfARG(classname));

    SP -= items;
   
    if((isarev = HvMROMETA(class_stash)->mro_isarev)) {
        HE* iter;
        hv_iterinit(isarev);
        while((iter = hv_iternext(isarev)))
            XPUSHs(hv_iterkeysv(iter));
    }

    PUTBACK;
    return;
}

XS(XS_mro_is_universal)
{
    dVAR;
    dXSARGS;
    SV* classname;
    HV* class_stash;

    PERL_UNUSED_ARG(cv);

    if (items != 1)
       Perl_croak(aTHX_ "Usage: mro::get_mro(classname)");

    classname = ST(0);
    class_stash = gv_stashsv(classname, 0);
    if(!class_stash) Perl_croak(aTHX_ "No such class: '%"SVf"'!", SVfARG(classname));

    if (HvMROMETA(class_stash)->is_universal)
        XSRETURN_YES;
    else
        XSRETURN_NO;
}

XS(XS_mro_get_global_sub_generation)
{
    dVAR;
    dXSARGS;

    PERL_UNUSED_ARG(cv);

    if (items != 0)
        Perl_croak(aTHX_ "Usage: mro::get_global_sub_generation()");

    ST(0) = sv_2mortal(newSViv(PL_sub_generation));
    XSRETURN(1);
}

XS(XS_mro_invalidate_all_method_caches)
{
    dVAR;
    dXSARGS;

    PERL_UNUSED_ARG(cv);

    if (items != 0)
        Perl_croak(aTHX_ "Usage: mro::invalidate_all_method_caches()");

    PL_sub_generation++;

    XSRETURN_EMPTY;
}

XS(XS_mro_get_sub_generation)
{
    dVAR;
    dXSARGS;
    SV* classname;
    HV* class_stash;

    PERL_UNUSED_ARG(cv);

    if(items != 1)
        Perl_croak(aTHX_ "Usage: mro::get_sub_generation(classname)");

    classname = ST(0);
    class_stash = gv_stashsv(classname, 0);
    if(!class_stash) Perl_croak(aTHX_ "No such class: '%"SVf"'!", SVfARG(classname));

    ST(0) = sv_2mortal(newSViv(HvMROMETA(class_stash)->sub_generation));
    XSRETURN(1);
}

XS(XS_mro_method_changed_in)
{
    dVAR;
    dXSARGS;
    SV* classname;
    HV* class_stash;

    PERL_UNUSED_ARG(cv);

    if(items != 1)
        Perl_croak(aTHX_ "Usage: mro::method_changed_in(classname)");
    
    classname = ST(0);

    class_stash = gv_stashsv(classname, 0);
    if(!class_stash) Perl_croak(aTHX_ "No such class: '%"SVf"'!", SVfARG(classname));

    mro_method_changed_in(class_stash);

    XSRETURN_EMPTY;
}

XS(XS_next_can)
{
    dVAR;
    dXSARGS;
    SV* self = ST(0);
    SV* methcv = __nextcan(aTHX_ self, 0);

    PERL_UNUSED_ARG(cv);
    PERL_UNUSED_VAR(items);

    if(methcv == &PL_sv_undef) {
        ST(0) = &PL_sv_undef;
    }
    else {
        ST(0) = sv_2mortal(newRV_inc(methcv));
    }

    XSRETURN(1);
}

XS(XS_next_method)
{
    dMARK;
    dAX;
    SV* self = ST(0);
    SV* methcv = __nextcan(aTHX_ self, 1);

    PERL_UNUSED_ARG(cv);

    PL_markstack_ptr++;
    call_sv(methcv, GIMME_V);
}

XS(XS_maybe_next_method)
{
    dMARK;
    dAX;
    SV* self = ST(0);
    SV* methcv = __nextcan(aTHX_ self, 0);

    PERL_UNUSED_ARG(cv);

    if(methcv == &PL_sv_undef) {
        ST(0) = &PL_sv_undef;
        XSRETURN(1);
    }

    PL_markstack_ptr++;
    call_sv(methcv, GIMME_V);
}

/*
 * Local variables:
 * c-indentation-style: bsd
 * c-basic-offset: 4
 * indent-tabs-mode: t
 * End:
 *
 * ex: set ts=8 sts=4 sw=4 noet:
 */
