/*    sv.c
 *
 *    Copyright (C) 1991, 1992, 1993, 1994, 1995, 1996, 1997, 1998, 1999, 2000,
 *    2001, 2002, 2003, 2004, 2005, 2006, 2007, 2008 by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 * "I wonder what the Entish is for 'yes' and 'no'," he thought.
 *
 *
 * This file contains the code that creates, manipulates and destroys
 * scalar values (SVs). The other types (AV, HV, GV, etc.) reuse the
 * structure of an SV, so their creation and destruction is handled
 * here; higher-level functions are in av.c, hv.c, and so on. Opcode
 * level functions (eg. substr, split, join) for each of the types are
 * in the pp*.c files.
 */

#include "EXTERN.h"
#define PERL_IN_SV_C
#include "perl.h"
#include "regcomp.h"

#define FCALL *f

#ifdef __Lynx__
/* Missing proto on LynxOS */
  char *gconvert(double, int, int,  char *);
#endif

#ifdef PERL_UTF8_CACHE_ASSERT
/* if adding more checks watch out for the following tests:
 *   t/op/index.t t/op/length.t t/op/pat.t t/op/substr.t
 *   lib/utf8.t lib/Unicode/Collate/t/index.t
 * --jhi
 */
#   define ASSERT_UTF8_CACHE(cache) \
    STMT_START { if (cache) { assert((cache)[0] <= (cache)[1]); \
			      assert((cache)[2] <= (cache)[3]); \
			      assert((cache)[3] <= (cache)[1]);} \
			      } STMT_END
#else
#   define ASSERT_UTF8_CACHE(cache) NOOP
#endif

/* ============================================================================

=head1 Allocation and deallocation of SVs.

An SV (or AV, HV, etc.) is allocated in two parts: the head (struct
sv, av, hv...) contains type and reference count information, and for
many types, a pointer to the body (struct xrv, xpv, xpviv...), which
contains fields specific to each type.  Some types store all they need
in the head, so don't have a body.

In all but the most memory-paranoid configuations (ex: PURIFY), heads
and bodies are allocated out of arenas, which by default are
approximately 4K chunks of memory parcelled up into N heads or bodies.
Sv-bodies are allocated by their sv-type, guaranteeing size
consistency needed to allocate safely from arrays.

For SV-heads, the first slot in each arena is reserved, and holds a
link to the next arena, some flags, and a note of the number of slots.
Snaked through each arena chain is a linked list of free items; when
this becomes empty, an extra arena is allocated and divided up into N
items which are threaded into the free list.

SV-bodies are similar, but they use arena-sets by default, which
separate the link and info from the arena itself, and reclaim the 1st
slot in the arena.  SV-bodies are further described later.

The following global variables are associated with arenas:

    PL_sv_arenaroot	pointer to list of SV arenas
    PL_sv_root		pointer to list of free SV structures

    PL_body_arenas	head of linked-list of body arenas
    PL_body_roots[]	array of pointers to list of free bodies of svtype
			arrays are indexed by the svtype needed

A few special SV heads are not allocated from an arena, but are
instead directly created in the interpreter structure, eg PL_sv_undef.
The size of arenas can be changed from the default by setting
PERL_ARENA_SIZE appropriately at compile time.

The SV arena serves the secondary purpose of allowing still-live SVs
to be located and destroyed during final cleanup.

At the lowest level, the macros new_SV() and del_SV() grab and free
an SV head.  (If debugging with -DD, del_SV() calls the function S_del_sv()
to return the SV to the free list with error checking.) new_SV() calls
more_sv() / sv_add_arena() to add an extra arena if the free list is empty.
SVs in the free list have their SvTYPE field set to all ones.

At the time of very final cleanup, sv_free_arenas() is called from
perl_destruct() to physically free all the arenas allocated since the
start of the interpreter.

Manipulation of any of the PL_*root pointers is protected by enclosing
LOCK_SV_MUTEX; ... UNLOCK_SV_MUTEX calls which should Do the Right Thing
if 5005 threads are enabled.

The function visit() scans the SV arenas list, and calls a specified
function for each SV it finds which is still live - ie which has an SvTYPE
other than all 1's, and a non-zero SvREFCNT. visit() is used by the
following functions (specified as [function that calls visit()] / [function
called by visit() for each SV]):

    sv_report_used() / do_report_used()
			dump all remaining SVs (debugging aid)

    sv_clean_objs() / do_clean_objs(),do_clean_named_objs()
			Attempt to free all objects pointed to by RVs,
			and, unless DISABLE_DESTRUCTOR_KLUDGE is defined,
			try to do the same for all objects indirectly
			referenced by typeglobs too.  Called once from
			perl_destruct(), prior to calling sv_clean_all()
			below.

    sv_clean_all() / do_clean_all()
			SvREFCNT_dec(sv) each remaining SV, possibly
			triggering an sv_free(). It also sets the
			SVf_BREAK flag on the SV to indicate that the
			refcnt has been artificially lowered, and thus
			stopping sv_free() from giving spurious warnings
			about SVs which unexpectedly have a refcnt
			of zero.  called repeatedly from perl_destruct()
			until there are no SVs left.

=head2 Arena allocator API Summary

Private API to rest of sv.c

    new_SV(),  del_SV(),

    new_XIV(), del_XIV(),
    new_XNV(), del_XNV(),
    etc

Public API:

    sv_report_used(), sv_clean_objs(), sv_clean_all(), sv_free_arenas()

=cut

============================================================================ */

/*
 * "A time to plant, and a time to uproot what was planted..."
 */

/*
 * nice_chunk and nice_chunk size need to be set
 * and queried under the protection of sv_mutex for 5005 threads
 */
void
Perl_offer_nice_chunk(pTHX_ void *chunk, U32 chunk_size)
{
    void *new_chunk;
    U32 new_chunk_size;
    LOCK_SV_MUTEX;
    new_chunk = (void *)(chunk);
    new_chunk_size = (chunk_size);
    if (new_chunk_size > PL_nice_chunk_size) {
	Safefree(PL_nice_chunk);
	PL_nice_chunk = (char *) new_chunk;
	PL_nice_chunk_size = new_chunk_size;
    } else {
	Safefree(chunk);
    }
    UNLOCK_SV_MUTEX;
}

/* Mark an SV head as unused, and add to free list.
 *
 * If SVf_BREAK is set, skip adding it to the free list, as this SV had
 * its refcount artificially decremented during global destruction, so
 * there may be dangling pointers to it. The last thing we want in that
 * case is for it to be reused. */

#define plant_SV(p) \
    STMT_START {					\
	const U32 old_flags = SvFLAGS(p);			\
	SvFLAGS(p) = SVTYPEMASK;			\
	if (!(old_flags & SVf_BREAK)) {		\
	    SvANY(p) = (void *)PL_sv_root;		\
	    PL_sv_root = (p);				\
	}						\
	--PL_sv_count;					\
    } STMT_END

/* sv_mutex must be held while calling uproot_SV() for 5005 threads */
#define uproot_SV(p) \
    STMT_START {					\
	(p) = PL_sv_root;				\
	PL_sv_root = (SV*)SvANY(p);			\
	++PL_sv_count;					\
    } STMT_END


/* make some more SVs by adding another arena */

/* sv_mutex must be held while calling more_sv() for 5005 threads */
STATIC SV*
S_more_sv(pTHX)
{
    SV* sv;

    if (PL_nice_chunk) {
	sv_add_arena(PL_nice_chunk, PL_nice_chunk_size, 0);
	PL_nice_chunk = NULL;
        PL_nice_chunk_size = 0;
    }
    else {
	char *chunk;                /* must use New here to match call to */
	Newx(chunk,PERL_ARENA_SIZE,char);  /* Safefree() in sv_free_arenas() */
	sv_add_arena(chunk, PERL_ARENA_SIZE, 0);
    }
    uproot_SV(sv);
    return sv;
}

/* new_SV(): return a new, empty SV head */

#ifdef DEBUG_LEAKING_SCALARS
/* provide a real function for a debugger to play with */
STATIC SV*
S_new_SV(pTHX)
{
    SV* sv;

    LOCK_SV_MUTEX;
    if (PL_sv_root)
	uproot_SV(sv);
    else
	sv = S_more_sv(aTHX);
    UNLOCK_SV_MUTEX;
    SvANY(sv) = 0;
    SvREFCNT(sv) = 1;
    SvFLAGS(sv) = 0;
    return sv;
}
#  define new_SV(p) (p)=S_new_SV(aTHX)

#else
#  define new_SV(p) \
    STMT_START {					\
	LOCK_SV_MUTEX;					\
	if (PL_sv_root)					\
	    uproot_SV(p);				\
	else						\
	    (p) = S_more_sv(aTHX);			\
	UNLOCK_SV_MUTEX;				\
	SvANY(p) = 0;					\
	SvREFCNT(p) = 1;				\
	SvFLAGS(p) = 0;					\
    } STMT_END
#endif


/* del_SV(): return an empty SV head to the free list */

#ifdef DEBUGGING

#define del_SV(p) \
    STMT_START {					\
	LOCK_SV_MUTEX;					\
	if (DEBUG_D_TEST)				\
	    del_sv(p);					\
	else						\
	    plant_SV(p);				\
	UNLOCK_SV_MUTEX;				\
    } STMT_END

STATIC void
S_del_sv(pTHX_ SV *p)
{
    if (DEBUG_D_TEST) {
	SV* sva;
	bool ok = 0;
	for (sva = PL_sv_arenaroot; sva; sva = (SV *) SvANY(sva)) {
	    const SV * const sv = sva + 1;
	    const SV * const svend = &sva[SvREFCNT(sva)];
	    if (p >= sv && p < svend) {
		ok = 1;
		break;
	    }
	}
	if (!ok) {
	    if (ckWARN_d(WARN_INTERNAL))	
	        Perl_warner(aTHX_ packWARN(WARN_INTERNAL),
			    "Attempt to free non-arena SV: 0x%"UVxf
                            pTHX__FORMAT, PTR2UV(p) pTHX__VALUE);
	    return;
	}
    }
    plant_SV(p);
}

#else /* ! DEBUGGING */

#define del_SV(p)   plant_SV(p)

#endif /* DEBUGGING */


/*
=head1 SV Manipulation Functions

=for apidoc sv_add_arena

Given a chunk of memory, link it to the head of the list of arenas,
and split it into a list of free SVs.

=cut
*/

void
Perl_sv_add_arena(pTHX_ char *ptr, U32 size, U32 flags)
{
    SV* const sva = (SV*)ptr;
    register SV* sv;
    register SV* svend;

    /* The first SV in an arena isn't an SV. */
    SvANY(sva) = (void *) PL_sv_arenaroot;		/* ptr to next arena */
    SvREFCNT(sva) = size / sizeof(SV);		/* number of SV slots */
    SvFLAGS(sva) = flags;			/* FAKE if not to be freed */

    PL_sv_arenaroot = sva;
    PL_sv_root = sva + 1;

    svend = &sva[SvREFCNT(sva) - 1];
    sv = sva + 1;
    while (sv < svend) {
	SvANY(sv) = (void *)(SV*)(sv + 1);
#ifdef DEBUGGING
	SvREFCNT(sv) = 0;
#endif
	/* Must always set typemask because it's always checked in on cleanup
	   when the arenas are walked looking for objects.  */
	SvFLAGS(sv) = SVTYPEMASK;
	sv++;
    }
    SvANY(sv) = 0;
#ifdef DEBUGGING
    SvREFCNT(sv) = 0;
#endif
    SvFLAGS(sv) = SVTYPEMASK;
}

/* visit(): call the named function for each non-free SV in the arenas
 * whose flags field matches the flags/mask args. */

STATIC I32
S_visit(pTHX_ SVFUNC_t f, U32 flags, U32 mask)
{
    SV* sva;
    I32 visited = 0;

    for (sva = PL_sv_arenaroot; sva; sva = (SV*)SvANY(sva)) {
	register const SV * const svend = &sva[SvREFCNT(sva)];
	register SV* sv;
	for (sv = sva + 1; sv < svend; ++sv) {
	    if (SvTYPE(sv) != SVTYPEMASK
		    && (sv->sv_flags & mask) == flags
		    && SvREFCNT(sv))
	    {
		(FCALL)(aTHX_ sv);
		++visited;
	    }
	}
    }
    return visited;
}

#ifdef DEBUGGING

/* called by sv_report_used() for each live SV */

static void
do_report_used(pTHX_ SV *sv)
{
    if (SvTYPE(sv) != SVTYPEMASK) {
	PerlIO_printf(Perl_debug_log, "****\n");
	sv_dump(sv);
    }
}
#endif

/*
=for apidoc sv_report_used

Dump the contents of all SVs not yet freed. (Debugging aid).

=cut
*/

void
Perl_sv_report_used(pTHX)
{
#ifdef DEBUGGING
    visit(do_report_used, 0, 0);
#else
    PERL_UNUSED_CONTEXT;
#endif
}

/* called by sv_clean_objs() for each live SV */

static void
do_clean_objs(pTHX_ SV *sv)
{
    SV *const rv = SvRV(sv);

    if (SvOBJECT(rv)) {
	DEBUG_D((PerlIO_printf(Perl_debug_log, "Cleaning object ref:\n "), sv_dump(sv)));
	if (SvWEAKREF(sv)) {
	    sv_del_backref(sv);
	    SvWEAKREF_off(sv);
	    SvRV_set(sv, NULL);
	} else {
	    SvROK_off(sv);
	    SvRV_set(sv, NULL);
	    SvREFCNT_dec(rv);
	}
    }

    /* XXX Might want to check arrays, etc. */
}

/* called by sv_clean_objs() for each live SV */

#ifndef DISABLE_DESTRUCTOR_KLUDGE
static void
do_clean_named_objs(pTHX_ SV *sv)
{
    if (GvGP(sv)) {
	if ((
#ifdef PERL_DONT_CREATE_GVSV
	     GvSV(sv) &&
#endif
	     SvOBJECT(GvSV(sv))) ||
	     (GvAV(sv) && SvOBJECT(GvAV(sv))) ||
	     (GvHV(sv) && SvOBJECT(GvHV(sv))) ||
	     /* In certain rare cases GvIOp(sv) can be NULL, which would make SvOBJECT(GvIO(sv)) dereference NULL. */
	     (GvIO(sv) ? (SvFLAGS(GvIOp(sv)) & SVs_OBJECT) : 0) ||
	     (GvCV(sv) && SvOBJECT(GvCV(sv))) )
	{
	    DEBUG_D((PerlIO_printf(Perl_debug_log, "Cleaning named glob object:\n "), sv_dump(sv)));
	    SvFLAGS(sv) |= SVf_BREAK;
	    SvREFCNT_dec(sv);
	}
    }
}
#endif

/*
=for apidoc sv_clean_objs

Attempt to destroy all objects not yet freed

=cut
*/

void
Perl_sv_clean_objs(pTHX)
{
    PL_in_clean_objs = TRUE;
    visit(do_clean_objs, SVf_ROK, SVf_ROK);
#ifndef DISABLE_DESTRUCTOR_KLUDGE
    /* some barnacles may yet remain, clinging to typeglobs */
    visit(do_clean_named_objs, SVt_PVGV, SVTYPEMASK);
#endif
    PL_in_clean_objs = FALSE;
}

/* called by sv_clean_all() for each live SV */

static void
do_clean_all(pTHX_ SV *sv)
{
    if (sv == (SV*) PL_fdpid || sv == (SV *)PL_strtab) {
	/* don't clean pid table and strtab */
	return;
    }
    DEBUG_D((PerlIO_printf(Perl_debug_log, "Cleaning loops: SV at 0x%"UVxf"\n", PTR2UV(sv)) ));
    SvFLAGS(sv) |= SVf_BREAK;
    SvREFCNT_dec(sv);
}

/*
=for apidoc sv_clean_all

Decrement the refcnt of each remaining SV, possibly triggering a
cleanup. This function may have to be called multiple times to free
SVs which are in complex self-referential hierarchies.

=cut
*/

I32
Perl_sv_clean_all(pTHX)
{
    I32 cleaned;
    PL_in_clean_all = TRUE;
    cleaned = visit(do_clean_all, 0,0);
    PL_in_clean_all = FALSE;
    return cleaned;
}

/*
  ARENASETS: a meta-arena implementation which separates arena-info
  into struct arena_set, which contains an array of struct
  arena_descs, each holding info for a single arena.  By separating
  the meta-info from the arena, we recover the 1st slot, formerly
  borrowed for list management.  The arena_set is about the size of an
  arena, avoiding the needless malloc overhead of a naive linked-list.

  The cost is 1 arena-set malloc per ~320 arena-mallocs, + the unused
  memory in the last arena-set (1/2 on average).  In trade, we get
  back the 1st slot in each arena (ie 1.7% of a CV-arena, less for
  smaller types).  The recovery of the wasted space allows use of
  small arenas for large, rare body types, by changing array* fields
  in body_details_by_type[] below.
*/
struct arena_desc {
    char       *arena;		/* the raw storage, allocated aligned */
    size_t      size;		/* its size ~4k typ */
    U32		misc;		/* type, and in future other things. */
};

struct arena_set;

/* Get the maximum number of elements in set[] such that struct arena_set
   will fit within PERL_ARENA_SIZE, which is probably just under 4K, and
   therefore likely to be 1 aligned memory page.  */

#define ARENAS_PER_SET  ((PERL_ARENA_SIZE - sizeof(struct arena_set*) \
			  - 2 * sizeof(int)) / sizeof (struct arena_desc))

struct arena_set {
    struct arena_set* next;
    unsigned int   set_size;	/* ie ARENAS_PER_SET */
    unsigned int   curr;	/* index of next available arena-desc */
    struct arena_desc set[ARENAS_PER_SET];
};

/*
=for apidoc sv_free_arenas

Deallocate the memory used by all arenas. Note that all the individual SV
heads and bodies within the arenas must already have been freed.

=cut
*/
void
Perl_sv_free_arenas(pTHX)
{
    SV* sva;
    SV* svanext;
    unsigned int i;

    /* Free arenas here, but be careful about fake ones.  (We assume
       contiguity of the fake ones with the corresponding real ones.) */

    for (sva = PL_sv_arenaroot; sva; sva = svanext) {
	svanext = (SV*) SvANY(sva);
	while (svanext && SvFAKE(svanext))
	    svanext = (SV*) SvANY(svanext);

	if (!SvFAKE(sva))
	    Safefree(sva);
    }

    {
	struct arena_set *aroot = (struct arena_set*) PL_body_arenas;

	while (aroot) {
	    struct arena_set *current = aroot;
	    i = aroot->curr;
	    while (i--) {
		assert(aroot->set[i].arena);
		Safefree(aroot->set[i].arena);
	    }
	    aroot = aroot->next;
	    Safefree(current);
	}
    }
    PL_body_arenas = 0;

    i = PERL_ARENA_ROOTS_SIZE;
    while (i--)
	PL_body_roots[i] = 0;

    Safefree(PL_nice_chunk);
    PL_nice_chunk = NULL;
    PL_nice_chunk_size = 0;
    PL_sv_arenaroot = 0;
    PL_sv_root = 0;
}

/*
=for apidoc report_uninit

Print appropriate "Use of uninitialized variable" warning

=cut
*/

void
Perl_report_uninit(pTHX)
{
    if (PL_op)
	Perl_warner(aTHX_ packWARN(WARN_UNINITIALIZED), PL_warn_uninit,
		    " in ", OP_DESC(PL_op));
    else
	Perl_warner(aTHX_ packWARN(WARN_UNINITIALIZED), PL_warn_uninit, "", "");
}

/*
  Here are mid-level routines that manage the allocation of bodies out
  of the various arenas.  There are 5 kinds of arenas:

  1. SV-head arenas, which are discussed and handled above
  2. regular body arenas
  3. arenas for reduced-size bodies
  4. Hash-Entry arenas
  5. pte arenas (thread related)

  Arena types 2 & 3 are chained by body-type off an array of
  arena-root pointers, which is indexed by svtype.  Some of the
  larger/less used body types are malloced singly, since a large
  unused block of them is wasteful.  Also, several svtypes dont have
  bodies; the data fits into the sv-head itself.  The arena-root
  pointer thus has a few unused root-pointers (which may be hijacked
  later for arena types 4,5)

  3 differs from 2 as an optimization; some body types have several
  unused fields in the front of the structure (which are kept in-place
  for consistency).  These bodies can be allocated in smaller chunks,
  because the leading fields arent accessed.  Pointers to such bodies
  are decremented to point at the unused 'ghost' memory, knowing that
  the pointers are used with offsets to the real memory.

  HE, HEK arenas are managed separately, with separate code, but may
  be merge-able later..

  PTE arenas are not sv-bodies, but they share these mid-level
  mechanics, so are considered here.  The new mid-level mechanics rely
  on the sv_type of the body being allocated, so we just reserve one
  of the unused body-slots for PTEs, then use it in those (2) PTE
  contexts below (line ~10k)
*/

/* get_arena(size): this creates custom-sized arenas
   TBD: export properly for hv.c: S_more_he().
*/
void*
Perl_get_arena(pTHX_ size_t arena_size, U32 misc)
{
    struct arena_desc* adesc;
    struct arena_set *aroot = (struct arena_set*) PL_body_arenas;
    unsigned int curr;

    /* shouldnt need this
    if (!arena_size)	arena_size = PERL_ARENA_SIZE;
    */

    /* may need new arena-set to hold new arena */
    if (!aroot || aroot->curr >= aroot->set_size) {
	struct arena_set *newroot;
	Newxz(newroot, 1, struct arena_set);
	newroot->set_size = ARENAS_PER_SET;
	newroot->next = aroot;
	aroot = newroot;
	PL_body_arenas = (void *) newroot;
	DEBUG_m(PerlIO_printf(Perl_debug_log, "new arenaset %p\n", (void*)aroot));
    }

    /* ok, now have arena-set with at least 1 empty/available arena-desc */
    curr = aroot->curr++;
    adesc = &(aroot->set[curr]);
    assert(!adesc->arena);
    
    Newx(adesc->arena, arena_size, char);
    adesc->size = arena_size;
    adesc->misc = misc;
    DEBUG_m(PerlIO_printf(Perl_debug_log, "arena %d added: %p size %"UVuf"\n", 
			  curr, (void*)adesc->arena, (UV)arena_size));

    return adesc->arena;
}


/* return a thing to the free list */

#define del_body(thing, root)			\
    STMT_START {				\
	void ** const thing_copy = (void **)thing;\
	LOCK_SV_MUTEX;				\
	*thing_copy = *root;			\
	*root = (void*)thing_copy;		\
	UNLOCK_SV_MUTEX;			\
    } STMT_END

/* 

=head1 SV-Body Allocation

Allocation of SV-bodies is similar to SV-heads, differing as follows;
the allocation mechanism is used for many body types, so is somewhat
more complicated, it uses arena-sets, and has no need for still-live
SV detection.

At the outermost level, (new|del)_X*V macros return bodies of the
appropriate type.  These macros call either (new|del)_body_type or
(new|del)_body_allocated macro pairs, depending on specifics of the
type.  Most body types use the former pair, the latter pair is used to
allocate body types with "ghost fields".

"ghost fields" are fields that are unused in certain types, and
consequently dont need to actually exist.  They are declared because
they're part of a "base type", which allows use of functions as
methods.  The simplest examples are AVs and HVs, 2 aggregate types
which don't use the fields which support SCALAR semantics.

For these types, the arenas are carved up into *_allocated size
chunks, we thus avoid wasted memory for those unaccessed members.
When bodies are allocated, we adjust the pointer back in memory by the
size of the bit not allocated, so it's as if we allocated the full
structure.  (But things will all go boom if you write to the part that
is "not there", because you'll be overwriting the last members of the
preceding structure in memory.)

We calculate the correction using the STRUCT_OFFSET macro. For
example, if xpv_allocated is the same structure as XPV then the two
OFFSETs sum to zero, and the pointer is unchanged. If the allocated
structure is smaller (no initial NV actually allocated) then the net
effect is to subtract the size of the NV from the pointer, to return a
new pointer as if an initial NV were actually allocated.

This is the same trick as was used for NV and IV bodies. Ironically it
doesn't need to be used for NV bodies any more, because NV is now at
the start of the structure. IV bodies don't need it either, because
they are no longer allocated.

In turn, the new_body_* allocators call S_new_body(), which invokes
new_body_inline macro, which takes a lock, and takes a body off the
linked list at PL_body_roots[sv_type], calling S_more_bodies() if
necessary to refresh an empty list.  Then the lock is released, and
the body is returned.

S_more_bodies calls get_arena(), and carves it up into an array of N
bodies, which it strings into a linked list.  It looks up arena-size
and body-size from the body_details table described below, thus
supporting the multiple body-types.

If PURIFY is defined, or PERL_ARENA_SIZE=0, arenas are not used, and
the (new|del)_X*V macros are mapped directly to malloc/free.

*/

/* 

For each sv-type, struct body_details bodies_by_type[] carries
parameters which control these aspects of SV handling:

Arena_size determines whether arenas are used for this body type, and if
so, how big they are.  PURIFY or PERL_ARENA_SIZE=0 set this field to
zero, forcing individual mallocs and frees.

Body_size determines how big a body is, and therefore how many fit into
each arena.  Offset carries the body-pointer adjustment needed for
*_allocated body types, and is used in *_allocated macros.

But its main purpose is to parameterize info needed in
Perl_sv_upgrade().  The info here dramatically simplifies the function
vs the implementation in 5.8.7, making it table-driven.  All fields
are used for this, except for arena_size.

For the sv-types that have no bodies, arenas are not used, so those
PL_body_roots[sv_type] are unused, and can be overloaded.  In
something of a special case, SVt_NULL is borrowed for HE arenas;
PL_body_roots[HE_SVSLOT=SVt_NULL] is filled by S_more_he, but the
bodies_by_type[SVt_NULL] slot is not used, as the table is not
available in hv.c.

PTEs also use arenas, but are never seen in Perl_sv_upgrade. Nonetheless,
they get their own slot in bodies_by_type[PTE_SVSLOT is after the last real
SV type], so they can just use the same allocation semantics.

At first, PTEs were also overloaded to a non-body sv-type, but this yielded
hard-to-find malloc bugs, so was simplified by claiming a new slot.  This
choice has no consequence at this time.

*/

struct body_details {
    U8 body_size;	/* Size to allocate  */
    U8 copy;		/* Size of structure to copy (may be shorter)  */
    U8 offset;
    unsigned int type : 4;	    /* We have space for a sanity check.  */
    unsigned int cant_upgrade : 1;  /* Cannot upgrade this type */
    unsigned int zero_nv : 1;	    /* zero the NV when upgrading from this */
    unsigned int arena : 1;	    /* Allocated from an arena */
    size_t arena_size;		    /* Size of arena to allocate */
};

#define HADNV FALSE
#define NONV TRUE


#ifdef PURIFY
/* With -DPURFIY we allocate everything directly, and don't use arenas.
   This seems a rather elegant way to simplify some of the code below.  */
#define HASARENA FALSE
#else
#define HASARENA TRUE
#endif
#define NOARENA FALSE

/* Size the arenas to exactly fit a given number of bodies.  A count
   of 0 fits the max number bodies into a PERL_ARENA_SIZE.block,
   simplifying the default.  If count > 0, the arena is sized to fit
   only that many bodies, allowing arenas to be used for large, rare
   bodies (XPVFM, XPVIO) without undue waste.  The arena size is
   limited by PERL_ARENA_SIZE, so we can safely oversize the
   declarations.
 */
#define FIT_ARENA0(body_size)				\
    ((size_t)(PERL_ARENA_SIZE / body_size) * body_size)
#define FIT_ARENAn(count,body_size)			\
    ( count * body_size <= PERL_ARENA_SIZE)		\
    ? count * body_size					\
    : FIT_ARENA0 (body_size)
#define FIT_ARENA(count,body_size)			\
    count 						\
    ? FIT_ARENAn (count, body_size)			\
    : FIT_ARENA0 (body_size)

/* A macro to work out the offset needed to subtract from a pointer to (say)

typedef struct {
    STRLEN	xpv_cur;
    STRLEN	xpv_len;
} xpv_allocated;

to make its members accessible via a pointer to (say)

struct xpv {
    NV		xnv_nv;
    STRLEN	xpv_cur;
    STRLEN	xpv_len;
};

*/

#define relative_STRUCT_OFFSET(longer, shorter, member) \
    (STRUCT_OFFSET(shorter, member) - STRUCT_OFFSET(longer, member))

/* Calculate the length to copy. Specifically work out the length less any
   final padding the compiler needed to add.  See the comment in sv_upgrade
   for why copying the padding proved to be a bug.  */

#define copy_length(type, last_member) \
	STRUCT_OFFSET(type, last_member) \
	+ sizeof (((type*)SvANY((SV*)0))->last_member)

static const struct body_details bodies_by_type[] = {
    {0, 0, 0, SVt_NULL, FALSE, NONV, NOARENA, 0},

    { sizeof(xiv_allocated), sizeof(IV),
      + relative_STRUCT_OFFSET(xiv_allocated, XPVIV, xiv_iv),
      SVt_IV, FALSE, NONV, HASARENA, FIT_ARENA(0, sizeof(xiv_allocated))},

    /* 8 bytes on most ILP32 with IEEE doubles */
    { sizeof(xnv_allocated), sizeof(NV),
      + relative_STRUCT_OFFSET(xnv_allocated, XPVNV, xnv_nv),
      SVt_NV, FALSE, HADNV, HASARENA, FIT_ARENA(0, sizeof(xnv_allocated))},

    { sizeof(XRV), sizeof(XRV), 0, SVt_RV, FALSE, NONV, HASARENA,
      FIT_ARENA(0, sizeof(XRV))},

    { sizeof(xpv_allocated),
      copy_length(XPV, xpv_len)
      - relative_STRUCT_OFFSET(xpv_allocated, XPV, xpv_cur),
      + relative_STRUCT_OFFSET(xpv_allocated, XPV, xpv_cur),
      SVt_PV, FALSE, NONV, HASARENA, FIT_ARENA(0, sizeof(xpv_allocated)) },

    { sizeof(xpviv_allocated),
      copy_length(XPVIV, xiv_iv)
      - relative_STRUCT_OFFSET(xpviv_allocated, XPVIV, xpv_cur),
      + relative_STRUCT_OFFSET(xpviv_allocated, XPVIV, xpv_cur),
      SVt_PVIV, FALSE, NONV, HASARENA, FIT_ARENA(0, sizeof(xpviv_allocated)) },

    { sizeof(XPVNV), copy_length(XPVNV, xnv_nv), 0, SVt_PVNV, FALSE, HADNV,
      HASARENA, FIT_ARENA(0, sizeof(XPVNV)) },

    { sizeof(XPVMG), copy_length(XPVMG, xmg_stash), 0, SVt_PVMG, FALSE, HADNV,
      HASARENA, FIT_ARENA(0, sizeof(XPVMG)) },
    
    { sizeof(XPVBM), sizeof(XPVBM), 0, SVt_PVBM, TRUE, HADNV,
      HASARENA, FIT_ARENA(0, sizeof(XPVBM)) },

    { sizeof(XPVLV), sizeof(XPVLV), 0, SVt_PVLV, TRUE, HADNV,
      HASARENA, FIT_ARENA(0, sizeof(XPVLV)) },

    { sizeof(xpvav_allocated),
      sizeof(xpvav_allocated)
      - relative_STRUCT_OFFSET(xpvav_allocated, XPVAV, xav_fill),
      + relative_STRUCT_OFFSET(xpvav_allocated, XPVAV, xav_fill),
      SVt_PVAV, TRUE, HADNV, HASARENA, FIT_ARENA(0, sizeof(xpvav_allocated)) },

    { sizeof(xpvhv_allocated),
      sizeof(xpvhv_allocated)
      - relative_STRUCT_OFFSET(xpvhv_allocated, XPVHV, xhv_fill),
      + relative_STRUCT_OFFSET(xpvhv_allocated, XPVHV, xhv_fill),
      SVt_PVHV, TRUE, HADNV, HASARENA, FIT_ARENA(0, sizeof(xpvhv_allocated)) },

    { sizeof(XPVCV), sizeof(XPVCV), 0, SVt_PVCV, TRUE, HADNV,
      HASARENA, FIT_ARENA(0, sizeof(XPVCV)) },

    { sizeof(XPVGV), sizeof(XPVGV), 0, SVt_PVGV, TRUE, HADNV,
      HASARENA, FIT_ARENA(0, sizeof(XPVGV)) },

    { sizeof(XPVFM), sizeof(XPVFM), 0, SVt_PVFM, TRUE, HADNV, 
      HASARENA, FIT_ARENA(20, sizeof(XPVFM)) },

    { sizeof(XPVIO), sizeof(XPVIO), 0, SVt_PVIO, TRUE, HADNV,
      HASARENA, FIT_ARENA(24, sizeof(XPVIO)) },

    /* These two are the 17th and 18th entries in the array, so beyond the
       all the regular SV types.  */
    { sizeof(struct ptr_tbl_ent), /* This is used for PTEs.  */
      0, 0, 0, FALSE, NONV, NOARENA,
      FIT_ARENA(0, sizeof(struct ptr_tbl_ent))
    },

    { sizeof(HE), 0, 0, 0, FALSE, NONV, NOARENA,
      FIT_ARENA(0, sizeof(HE)) }
};

#define new_body_type(sv_type)		\
    (void *)((char *)S_new_body(aTHX_ sv_type))

#define del_body_type(p, sv_type)	\
    del_body(p, &PL_body_roots[sv_type])


#define new_body_allocated(sv_type)		\
    (void *)((char *)S_new_body(aTHX_ sv_type)	\
	     - bodies_by_type[sv_type].offset)

#define del_body_allocated(p, sv_type)		\
    del_body(p + bodies_by_type[sv_type].offset, &PL_body_roots[sv_type])


#define my_safemalloc(s)	(void*)safemalloc(s)
#define my_safecalloc(s)	(void*)safecalloc(s, 1)
#define my_safefree(p)	safefree((char*)p)

typedef struct xpviv XIV;
typedef struct xpvnv XNV;

#ifdef PURIFY

#define new_XIV()	my_safemalloc(sizeof(XPVIV))
#define del_XIV(p)	my_safefree(p)

#define new_XNV()	my_safemalloc(sizeof(XPVNV))
#define del_XNV(p)	my_safefree(p)

#define new_XRV()	my_safemalloc(sizeof(XRV))
#define del_XRV(p)	my_safefree(p)

#define new_XPVNV()	my_safemalloc(sizeof(XPVNV))
#define del_XPVNV(p)	my_safefree(p)

#define new_XPVAV()	my_safemalloc(sizeof(XPVAV))
#define del_XPVAV(p)	my_safefree(p)

#define new_XPVHV()	my_safemalloc(sizeof(XPVHV))
#define del_XPVHV(p)	my_safefree(p)

#define new_XPVMG()	my_safemalloc(sizeof(XPVMG))
#define del_XPVMG(p)	my_safefree(p)

#define new_XPVGV()	my_safemalloc(sizeof(XPVGV))
#define del_XPVGV(p)	my_safefree(p)

#else /* !PURIFY */

#define new_XIV()	new_body_allocated(SVt_IV)
#define del_XIV(p)	del_body_allocated(p, SVt_IV)

#define new_XNV()	new_body_allocated(SVt_NV)
#define del_XNV(p)	del_body_allocated(p, SVt_NV)

#define new_XRV()	new_body_type(SVt_RV)
#define del_XRV(p)	del_body_type(SVt_RV)

#define new_XPVNV()	new_body_type(SVt_PVNV)
#define del_XPVNV(p)	del_body_type(p, SVt_PVNV)

#define new_XPVAV()	new_body_allocated(SVt_PVAV)
#define del_XPVAV(p)	del_body_allocated(p, SVt_PVAV)

#define new_XPVHV()	new_body_allocated(SVt_PVHV)
#define del_XPVHV(p)	del_body_allocated(p, SVt_PVHV)

#define new_XPVMG()	new_body_type(SVt_PVMG)
#define del_XPVMG(p)	del_body_type(p, SVt_PVMG)

#define new_XPVGV()	new_body_type(SVt_PVGV)
#define del_XPVGV(p)	del_body_type(p, SVt_PVGV)

#endif /* PURIFY */

/* no arena for you! */

#define new_NOARENA(details) \
	my_safemalloc((details)->body_size + (details)->offset)
#define new_NOARENAZ(details) \
	my_safecalloc((details)->body_size + (details)->offset)

STATIC void *
S_more_bodies (pTHX_ svtype sv_type)
{
    void ** const root = &PL_body_roots[sv_type];
    const struct body_details * const bdp = &bodies_by_type[sv_type];
    const size_t body_size = bdp->body_size;
    char *start;
    const char *end;
#if defined DEBUGGING
    static bool done_sanity_check;

    /* PERL_GLOBAL_STRUCT_PRIVATE cannot coexist with global
     * variables like done_sanity_check. */
    assert(bdp->arena_size);

    if (!done_sanity_check) {
	unsigned int i = SVt_LAST;

	done_sanity_check = TRUE;

	while (i--)
	    assert (bodies_by_type[i].type == i);
    }
#endif

    assert(bdp->arena_size);

    start = (char*) Perl_get_arena(aTHX_ bdp->arena_size, sv_type);

    end = start + bdp->arena_size - body_size;

    /* computed count doesnt reflect the 1st slot reservation */
    DEBUG_m(PerlIO_printf(Perl_debug_log,
			  "arena %p end %p arena-size %d type %d size %d ct %d\n",
			  start, end,
			  (int)bdp->arena_size, sv_type, (int)body_size,
			  (int)bdp->arena_size / (int)body_size));

    *root = (void *)start;

    while (start < end) {
	char * const next = start + body_size;
	*(void**) start = (void *)next;
	start = next;
    }
    *(void **)start = 0;

    return *root;
}

/* grab a new thing from the free list, allocating more if necessary.
   The inline version is used for speed in hot routines, and the
   function using it serves the rest (unless PURIFY).
*/
#define new_body_inline(xpv, sv_type) \
    STMT_START { \
	void ** const r3wt = &PL_body_roots[sv_type]; \
	LOCK_SV_MUTEX; \
	xpv = (PTR_TBL_ENT_t*) (*((void **)(r3wt))      \
	  ? *((void **)(r3wt)) : more_bodies(sv_type)); \
	*(r3wt) = *(void**)(xpv); \
	UNLOCK_SV_MUTEX; \
    } STMT_END

#ifndef PURIFY

STATIC void *
S_new_body(pTHX_ svtype sv_type)
{
    void *xpv;
    new_body_inline(xpv, sv_type);
    return xpv;
}

#endif

/*
=for apidoc sv_upgrade

Upgrade an SV to a more complex form.  Generally adds a new body type to the
SV, then copies across as much information as possible from the old body.
You generally want to use the C<SvUPGRADE> macro wrapper. See also C<svtype>.

=cut
*/

bool
Perl_sv_upgrade(pTHX_ register SV *sv, U32 new_type)
{
    void*	old_body;
    void*	new_body;
    const U32	old_type = SvTYPE(sv);
    const struct body_details *new_type_details;
    const struct body_details *const old_type_details
	= bodies_by_type + old_type;

    if (new_type != SVt_PV && SvIsCOW(sv)) {
	sv_force_normal_flags(sv, 0);
    }

    if (old_type == new_type)
	return TRUE;

    old_body = SvANY(sv);

    /* Copying structures onto other structures that have been neatly zeroed
       has a subtle gotcha. Consider XPVMG

       +------+------+------+------+------+-------+-------+
       |     NV      | CUR  | LEN  |  IV  | MAGIC | STASH |
       +------+------+------+------+------+-------+-------+
       0      4      8     12     16     20      24      28

       where NVs are aligned to 8 bytes, so that sizeof that structure is
       actually 32 bytes long, with 4 bytes of padding at the end:

       +------+------+------+------+------+-------+-------+------+
       |     NV      | CUR  | LEN  |  IV  | MAGIC | STASH | ???  |
       +------+------+------+------+------+-------+-------+------+
       0      4      8     12     16     20      24      28     32

       so what happens if you allocate memory for this structure:

       +------+------+------+------+------+-------+-------+------+------+...
       |     NV      | CUR  | LEN  |  IV  | MAGIC | STASH |  GP  | NAME |
       +------+------+------+------+------+-------+-------+------+------+...
       0      4      8     12     16     20      24      28     32     36

       zero it, then copy sizeof(XPVMG) bytes on top of it? Not quite what you
       expect, because you copy the area marked ??? onto GP. Now, ??? may have
       started out as zero once, but it's quite possible that it isn't. So now,
       rather than a nicely zeroed GP, you have it pointing somewhere random.
       Bugs ensue.

       (In fact, GP ends up pointing at a previous GP structure, because the
       principle cause of the padding in XPVMG getting garbage is a copy of
       sizeof(XPVMG) bytes from a XPVGV structure in sv_unglob)

       So we are careful and work out the size of used parts of all the
       structures.  */

    switch (old_type) {
    case SVt_NULL:
	break;
    case SVt_IV:
	if (new_type < SVt_PVIV) {
	    new_type = (new_type == SVt_NV)
		? SVt_PVNV : SVt_PVIV;
	}
	break;
    case SVt_NV:

	if (new_type < SVt_PVNV) {
	    new_type = SVt_PVNV;
	}
	break;
    case SVt_RV:
	if (new_type == SVt_IV)
	    new_type = SVt_PVIV;
	else if (new_type == SVt_NV)
	    new_type = SVt_PVNV;
	break;
    case SVt_PV:
	if (new_type == SVt_IV)
	    new_type = SVt_PVIV;
	else if (new_type == SVt_NV)
	    new_type = SVt_PVNV;
	break;
    case SVt_PVIV:
	if (new_type == SVt_NV)
	    new_type = SVt_PVNV;
	break;
    case SVt_PVNV:
	break;
    case SVt_PVMG:
	/* Because the XPVMG of PL_mess_sv isn't allocated from the arena,
	   there's no way that it can be safely upgraded, because perl.c
	   expects to Safefree(SvANY(PL_mess_sv))  */
	assert(sv != PL_mess_sv);
	/* This flag bit is used to mean other things in other scalar types.
	   Given that it only has meaning inside the pad, it shouldn't be set
	   on anything that can get upgraded.  */
	assert(!SvPAD_TYPED(sv));
	break;
    default:
	if (old_type_details->cant_upgrade)
	    Perl_croak(aTHX_ "Can't upgrade %s (%" UVuf ") to %" UVuf,
		       sv_reftype(sv, 0), (UV) old_type, (UV) new_type);
    }
    new_type_details = bodies_by_type + new_type;

    if (old_type > new_type) {
	return TRUE;
    }

    SvFLAGS(sv) &= ~SVTYPEMASK;
    SvFLAGS(sv) |= new_type;

    /* This can't happen, as SVt_NULL is <= all values of new_type, so one of
       the return statements above will have triggered.  */
    assert (new_type != SVt_NULL);
    switch (new_type) {
    case SVt_IV:
	assert(old_type == SVt_NULL);
	SvANY(sv) = new_XIV();
	SvIV_set(sv, 0);
	return TRUE;
    case SVt_NV:
	assert(old_type == SVt_NULL);
	SvANY(sv) = new_XNV();
	SvNV_set(sv, 0);
	return TRUE;
    case SVt_RV:
	assert(old_type == SVt_NULL);
	SvANY(sv) = new_XRV();
	SvRV_set(sv, 0);
	return TRUE;
    case SVt_PVHV:
    case SVt_PVAV:
	assert(new_type_details->body_size);

#ifndef PURIFY	
	assert(new_type_details->arena);
	assert(new_type_details->arena_size);
	/* This points to the start of the allocated area.  */
	new_body_inline(new_body, (svtype)new_type);
	Zero(new_body, new_type_details->body_size, char);
	new_body = ((char *)new_body) - new_type_details->offset;
#else
	/* We always allocated the full length item with PURIFY. To do this
	   we fake things so that arena is false for all 16 types..  */
	new_body = new_NOARENAZ(new_type_details);
#endif
	SvANY(sv) = new_body;
	if (new_type == SVt_PVAV) {
	    AvMAX(sv)	= -1;
	    AvFILLp(sv)	= -1;
	    AvFLAGS(sv)	= AVf_REAL;
	}

	/* SVt_NULL isn't the only thing upgraded to AV or HV.
	   The target created by newSVrv also is, and it can have magic.
	   However, it never has SvPVX set.
	*/
	if (old_type >= SVt_RV && ((XPV*)old_body)->xpv_pv) {
	    char *pv = ((XPV*)old_body)->xpv_pv;
	    if (old_type >= SVt_PV) {
		if (SvOOK(sv)) {
		    pv -= ((XPVIV*)old_body)->xiv_iv;
		}
		Safefree(pv);
	    } else {
		/* RV shouldn't be pointing at anything, but just in case.  */
		if (SvROK(sv)) {
		    SvREFCNT_dec((SV*)pv);
		}
	    }
	}

	if (old_type >= SVt_PVMG) {
	    SvMAGIC_set(sv, ((XPVMG*)old_body)->xmg_magic);
	    SvSTASH_set(sv, ((XPVMG*)old_body)->xmg_stash);
	}
	break;


    case SVt_PVIV:
	/* XXX Is this still needed?  Was it ever needed?   Surely as there is
	   no route from NV to PVIV, NOK can never be true  */
	assert(!SvNOKp(sv));
	assert(!SvNOK(sv));
    case SVt_PVIO:
    case SVt_PVFM:
    case SVt_PVBM:
    case SVt_PVGV:
    case SVt_PVCV:
    case SVt_PVLV:
    case SVt_PVMG:
    case SVt_PVNV:
    case SVt_PV:

	assert(new_type_details->body_size);
	/* We always allocated the full length item with PURIFY. To do this
	   we fake things so that arena is false for all 16 types..  */
	if(new_type_details->arena) {
	    /* This points to the start of the allocated area.  */
	    new_body_inline(new_body, (svtype)new_type);
	    Zero(new_body, new_type_details->body_size, char);
	    new_body = ((char *)new_body) - new_type_details->offset;
	} else {
	    new_body = new_NOARENAZ(new_type_details);
	}
	SvANY(sv) = new_body;

	if (old_type_details->copy) {
	    Copy((char *)old_body + old_type_details->offset,
		 (char *)new_body + old_type_details->offset,
		 old_type_details->copy, char);
	}

#ifndef NV_ZERO_IS_ALLBITS_ZERO
	/* If NV 0.0 is stores as all bits 0 then Zero() already creates a
	 * correct 0.0 for us.  Otherwise, if the old body didn't have an
	 * NV slot, but the new one does, then we need to initialise the
	 * freshly created NV slot with whatever the correct bit pattern is
	 * for 0.0  */
	if (old_type_details->zero_nv && !new_type_details->zero_nv
	    && !isGV_with_GP(sv))
	    SvNV_set(sv, 0);
#endif

	if (new_type == SVt_PVIO)
	    IoPAGE_LEN(sv) = 60;
	break;
    default:
	Perl_croak(aTHX_ "panic: sv_upgrade to unknown type %lu",
		   (unsigned long)new_type);
    }

    if (old_type_details->arena) {
	/* If there was an old body, then we need to free it.
	   Note that there is an assumption that all bodies of types that
	   can be upgraded came from arenas. Only the more complex non-
	   upgradable types are allowed to be directly malloc()ed.  */
#ifdef PURIFY
	my_safefree(old_body);
#else
	del_body((void*)((char*)old_body + old_type_details->offset),
		 &PL_body_roots[old_type]);
#endif
    }
    return TRUE;
}

/*
=for apidoc sv_backoff

Remove any string offset. You should normally use the C<SvOOK_off> macro
wrapper instead.

=cut
*/

int
Perl_sv_backoff(pTHX_ register SV *sv)
{
    PERL_UNUSED_CONTEXT;
    assert(SvOOK(sv));
    if (SvIVX(sv)) {
	const char * const s = SvPVX_const(sv);
	SvLEN_set(sv, SvLEN(sv) + SvIVX(sv));
	SvPV_set(sv, SvPVX(sv) - SvIVX(sv));
	SvIV_set(sv, 0);
	Move(s, SvPVX(sv), SvCUR(sv)+1, char);
    }
    SvFLAGS(sv) &= ~SVf_OOK;
    return 0;
}

/*
=for apidoc sv_grow

Expands the character buffer in the SV.  If necessary, uses C<sv_unref> and
upgrades the SV to C<SVt_PV>.  Returns a pointer to the character buffer.
Use the C<SvGROW> wrapper instead.

=cut
*/

char *
Perl_sv_grow(pTHX_ register SV *sv, register STRLEN newlen)
{
    register char *s;



#ifdef HAS_64K_LIMIT
    if (newlen >= 0x10000) {
	PerlIO_printf(Perl_debug_log,
		      "Allocation too large: %"UVxf"\n", (UV)newlen);
	my_exit(1);
    }
#endif /* HAS_64K_LIMIT */
    if (SvROK(sv))
	sv_unref(sv);
    if (SvTYPE(sv) < SVt_PV) {
	sv_upgrade(sv, SVt_PV);
	s = SvPVX_mutable(sv);
    }
    else if (SvOOK(sv)) {	/* pv is offset? */
	sv_backoff(sv);
	s = SvPVX_mutable(sv);
	if (newlen > SvLEN(sv))
	    newlen += 10 * (newlen - SvCUR(sv)); /* avoid copy each time */
#ifdef HAS_64K_LIMIT
	if (newlen >= 0x10000)
	    newlen = 0xFFFF;
#endif
    }
    else
	s = SvPVX_mutable(sv);

    if (newlen > SvLEN(sv)) {		/* need more room? */
	newlen = PERL_STRLEN_ROUNDUP(newlen);
	if (SvLEN(sv) && s) {
#ifdef MYMALLOC
	    const STRLEN l = malloced_size((void*)SvPVX_const(sv));
	    if (newlen <= l) {
		SvLEN_set(sv, l);
		return s;
	    } else
#endif
	    s = (char*)saferealloc(s, newlen);
	}
	else {
	    /* sv_force_normal_flags() must not try to unshare the new
	       PVX we allocate below. AMS 20010713 */
	    if (SvREADONLY(sv) && SvFAKE(sv)) {
		SvFAKE_off(sv);
		SvREADONLY_off(sv);
	    }
	    s = (char*)safemalloc(newlen);
	    if (SvPVX_const(sv) && SvCUR(sv)) {
	        Move(SvPVX_const(sv), s, (newlen < SvCUR(sv)) ? newlen : SvCUR(sv), char);
	    }
	}
	SvPV_set(sv, s);
        SvLEN_set(sv, newlen);
    }
    return s;
}

/*
=for apidoc sv_setiv

Copies an integer into the given SV, upgrading first if necessary.
Does not handle 'set' magic.  See also C<sv_setiv_mg>.

=cut
*/

void
Perl_sv_setiv(pTHX_ register SV *sv, IV i)
{
    SV_CHECK_THINKFIRST(sv);
    switch (SvTYPE(sv)) {
    case SVt_NULL:
	sv_upgrade(sv, SVt_IV);
	break;
    case SVt_NV:
	sv_upgrade(sv, SVt_PVNV);
	break;
    case SVt_RV:
    case SVt_PV:
	sv_upgrade(sv, SVt_PVIV);
	break;

    case SVt_PVGV:
	if (!isGV_with_GP(sv))
	    break;
    case SVt_PVAV:
    case SVt_PVHV:
    case SVt_PVCV:
    case SVt_PVFM:
    case SVt_PVIO:
	Perl_croak(aTHX_ "Can't coerce %s to integer in %s", sv_reftype(sv,0),
		   OP_DESC(PL_op));
    default: NOOP;
    }
    (void)SvIOK_only(sv);			/* validate number */
    SvIV_set(sv, i);
    SvTAINT(sv);
}

/*
=for apidoc sv_setiv_mg

Like C<sv_setiv>, but also handles 'set' magic.

=cut
*/

void
Perl_sv_setiv_mg(pTHX_ register SV *sv, IV i)
{
    sv_setiv(sv,i);
    SvSETMAGIC(sv);
}

/*
=for apidoc sv_setuv

Copies an unsigned integer into the given SV, upgrading first if necessary.
Does not handle 'set' magic.  See also C<sv_setuv_mg>.

=cut
*/

void
Perl_sv_setuv(pTHX_ register SV *sv, UV u)
{
    /* With these two if statements:
       u=1.49  s=0.52  cu=72.49  cs=10.64  scripts=270  tests=20865

       without
       u=1.35  s=0.47  cu=73.45  cs=11.43  scripts=270  tests=20865

       If you wish to remove them, please benchmark to see what the effect is
    */
    if (u <= (UV)IV_MAX) {
       sv_setiv(sv, (IV)u);
       return;
    }
    sv_setiv(sv, 0);
    SvIsUV_on(sv);
    SvUV_set(sv, u);
}

/*
=for apidoc sv_setuv_mg

Like C<sv_setuv>, but also handles 'set' magic.

=cut
*/

void
Perl_sv_setuv_mg(pTHX_ register SV *sv, UV u)
{
    sv_setuv(sv,u);
    SvSETMAGIC(sv);
}

/*
=for apidoc sv_setnv

Copies a double into the given SV, upgrading first if necessary.
Does not handle 'set' magic.  See also C<sv_setnv_mg>.

=cut
*/

void
Perl_sv_setnv(pTHX_ register SV *sv, NV num)
{
    SV_CHECK_THINKFIRST(sv);
    switch (SvTYPE(sv)) {
    case SVt_NULL:
    case SVt_IV:
	sv_upgrade(sv, SVt_NV);
	break;
    case SVt_RV:
    case SVt_PV:
    case SVt_PVIV:
	sv_upgrade(sv, SVt_PVNV);
	break;

    case SVt_PVGV:
	if (!isGV_with_GP(sv))
	    break;
    case SVt_PVAV:
    case SVt_PVHV:
    case SVt_PVCV:
    case SVt_PVFM:
    case SVt_PVIO:
	Perl_croak(aTHX_ "Can't coerce %s to number in %s", sv_reftype(sv,0),
		   OP_NAME(PL_op));
    default: NOOP;
    }
    SvNV_set(sv, num);
    (void)SvNOK_only(sv);			/* validate number */
    SvTAINT(sv);
}

/*
=for apidoc sv_setnv_mg

Like C<sv_setnv>, but also handles 'set' magic.

=cut
*/

void
Perl_sv_setnv_mg(pTHX_ register SV *sv, NV num)
{
    sv_setnv(sv,num);
    SvSETMAGIC(sv);
}

/* Print an "isn't numeric" warning, using a cleaned-up,
 * printable version of the offending string
 */

STATIC void
S_not_a_number(pTHX_ SV *sv)
{
     SV *dsv;
     char tmpbuf[64];
     const char *pv;

     if (DO_UTF8(sv)) {
          dsv = newSVpvs_flags("", SVs_TEMP);
          pv = sv_uni_display(dsv, sv, 10, 0);
     } else {
	  char *d = tmpbuf;
	  const char * const limit = tmpbuf + sizeof(tmpbuf) - 8;
	  /* each *s can expand to 4 chars + "...\0",
	     i.e. need room for 8 chars */
	
	  const char *s = SvPVX_const(sv);
	  const char * const end = s + SvCUR(sv);
	  for ( ; s < end && d < limit; s++ ) {
	       int ch = *s & 0xFF;
	       if (ch & 128 && !isPRINT_LC(ch)) {
		    *d++ = 'M';
		    *d++ = '-';
		    ch &= 127;
	       }
	       if (ch == '\n') {
		    *d++ = '\\';
		    *d++ = 'n';
	       }
	       else if (ch == '\r') {
		    *d++ = '\\';
		    *d++ = 'r';
	       }
	       else if (ch == '\f') {
		    *d++ = '\\';
		    *d++ = 'f';
	       }
	       else if (ch == '\\') {
		    *d++ = '\\';
		    *d++ = '\\';
	       }
	       else if (ch == '\0') {
		    *d++ = '\\';
		    *d++ = '0';
	       }
	       else if (isPRINT_LC(ch))
		    *d++ = ch;
	       else {
		    *d++ = '^';
		    *d++ = toCTRL(ch);
	       }
	  }
	  if (s < end) {
	       *d++ = '.';
	       *d++ = '.';
	       *d++ = '.';
	  }
	  *d = '\0';
	  pv = tmpbuf;
    }

    if (PL_op)
	Perl_warner(aTHX_ packWARN(WARN_NUMERIC),
		    "Argument \"%s\" isn't numeric in %s", pv,
		    OP_DESC(PL_op));
    else
	Perl_warner(aTHX_ packWARN(WARN_NUMERIC),
		    "Argument \"%s\" isn't numeric", pv);
}

/*
=for apidoc looks_like_number

Test if the content of an SV looks like a number (or is a number).
C<Inf> and C<Infinity> are treated as numbers (so will not issue a
non-numeric warning), even if your atof() doesn't grok them.

=cut
*/

I32
Perl_looks_like_number(pTHX_ SV *sv)
{
    register const char *sbegin;
    STRLEN len;

    if (SvPOK(sv)) {
	sbegin = SvPVX_const(sv);
	len = SvCUR(sv);
    }
    else if (SvPOKp(sv))
	sbegin = SvPV_const(sv, len);
    else
	return SvFLAGS(sv) & (SVf_NOK|SVp_NOK|SVf_IOK|SVp_IOK);
    return grok_number(sbegin, len, NULL);
}

/* Actually, ISO C leaves conversion of UV to IV undefined, but
   until proven guilty, assume that things are not that bad... */

/*
   NV_PRESERVES_UV:

   As 64 bit platforms often have an NV that doesn't preserve all bits of
   an IV (an assumption perl has been based on to date) it becomes necessary
   to remove the assumption that the NV always carries enough precision to
   recreate the IV whenever needed, and that the NV is the canonical form.
   Instead, IV/UV and NV need to be given equal rights. So as to not lose
   precision as a side effect of conversion (which would lead to insanity
   and the dragon(s) in t/op/numconvert.t getting very angry) the intent is
   1) to distinguish between IV/UV/NV slots that have cached a valid
      conversion where precision was lost and IV/UV/NV slots that have a
      valid conversion which has lost no precision
   2) to ensure that if a numeric conversion to one form is requested that
      would lose precision, the precise conversion (or differently
      imprecise conversion) is also performed and cached, to prevent
      requests for different numeric formats on the same SV causing
      lossy conversion chains. (lossless conversion chains are perfectly
      acceptable (still))


   flags are used:
   SvIOKp is true if the IV slot contains a valid value
   SvIOK  is true only if the IV value is accurate (UV if SvIOK_UV true)
   SvNOKp is true if the NV slot contains a valid value
   SvNOK  is true only if the NV value is accurate

   so
   while converting from PV to NV, check to see if converting that NV to an
   IV(or UV) would lose accuracy over a direct conversion from PV to
   IV(or UV). If it would, cache both conversions, return NV, but mark
   SV as IOK NOKp (ie not NOK).

   While converting from PV to IV, check to see if converting that IV to an
   NV would lose accuracy over a direct conversion from PV to NV. If it
   would, cache both conversions, flag similarly.

   Before, the SV value "3.2" could become NV=3.2 IV=3 NOK, IOK quite
   correctly because if IV & NV were set NV *always* overruled.
   Now, "3.2" will become NV=3.2 IV=3 NOK, IOKp, because the flag's meaning
   changes - now IV and NV together means that the two are interchangeable:
   SvIVX == (IV) SvNVX && SvNVX == (NV) SvIVX;

   The benefit of this is that operations such as pp_add know that if
   SvIOK is true for both left and right operands, then integer addition
   can be used instead of floating point (for cases where the result won't
   overflow). Before, floating point was always used, which could lead to
   loss of precision compared with integer addition.

   * making IV and NV equal status should make maths accurate on 64 bit
     platforms
   * may speed up maths somewhat if pp_add and friends start to use
     integers when possible instead of fp. (Hopefully the overhead in
     looking for SvIOK and checking for overflow will not outweigh the
     fp to integer speedup)
   * will slow down integer operations (callers of SvIV) on "inaccurate"
     values, as the change from SvIOK to SvIOKp will cause a call into
     sv_2iv each time rather than a macro access direct to the IV slot
   * should speed up number->string conversion on integers as IV is
     favoured when IV and NV are equally accurate

   ####################################################################
   You had better be using SvIOK_notUV if you want an IV for arithmetic:
   SvIOK is true if (IV or UV), so you might be getting (IV)SvUV.
   On the other hand, SvUOK is true iff UV.
   ####################################################################

   Your mileage will vary depending your CPU's relative fp to integer
   performance ratio.
*/

#ifndef NV_PRESERVES_UV
#  define IS_NUMBER_UNDERFLOW_IV 1
#  define IS_NUMBER_UNDERFLOW_UV 2
#  define IS_NUMBER_IV_AND_UV    2
#  define IS_NUMBER_OVERFLOW_IV  4
#  define IS_NUMBER_OVERFLOW_UV  5

/* sv_2iuv_non_preserve(): private routine for use by sv_2iv() and sv_2uv() */

/* For sv_2nv these three cases are "SvNOK and don't bother casting"  */
STATIC int
S_sv_2iuv_non_preserve(pTHX_ register SV *sv
#  ifdef DEBUGGING
		       , I32 numtype
#  endif
		       )
{
    DEBUG_c(PerlIO_printf(Perl_debug_log,"sv_2iuv_non '%s', IV=0x%"UVxf" NV=%"NVgf" inttype=%"UVXf"\n", SvPVX_const(sv), SvIVX(sv), SvNVX(sv), (UV)numtype));
    if (SvNVX(sv) < (NV)IV_MIN) {
	(void)SvIOKp_on(sv);
	(void)SvNOK_on(sv);
	SvIV_set(sv, IV_MIN);
	return IS_NUMBER_UNDERFLOW_IV;
    }
    if (SvNVX(sv) > (NV)UV_MAX) {
	(void)SvIOKp_on(sv);
	(void)SvNOK_on(sv);
	SvIsUV_on(sv);
	SvUV_set(sv, UV_MAX);
	return IS_NUMBER_OVERFLOW_UV;
    }
    (void)SvIOKp_on(sv);
    (void)SvNOK_on(sv);
    /* Can't use strtol etc to convert this string.  (See truth table in
       sv_2iv  */
    if (SvNVX(sv) <= (UV)IV_MAX) {
        SvIV_set(sv, I_V(SvNVX(sv)));
        if ((NV)(SvIVX(sv)) == SvNVX(sv)) {
            SvIOK_on(sv); /* Integer is precise. NOK, IOK */
        } else {
            /* Integer is imprecise. NOK, IOKp */
        }
        return SvNVX(sv) < 0 ? IS_NUMBER_UNDERFLOW_UV : IS_NUMBER_IV_AND_UV;
    }
    SvIsUV_on(sv);
    SvUV_set(sv, U_V(SvNVX(sv)));
    if ((NV)(SvUVX(sv)) == SvNVX(sv)) {
        if (SvUVX(sv) == UV_MAX) {
            /* As we know that NVs don't preserve UVs, UV_MAX cannot
               possibly be preserved by NV. Hence, it must be overflow.
               NOK, IOKp */
            return IS_NUMBER_OVERFLOW_UV;
        }
        SvIOK_on(sv); /* Integer is precise. NOK, UOK */
    } else {
        /* Integer is imprecise. NOK, IOKp */
    }
    return IS_NUMBER_OVERFLOW_IV;
}
#endif /* !NV_PRESERVES_UV*/

STATIC bool
S_sv_2iuv_common(pTHX_ SV *sv) {
    if (SvNOKp(sv)) {
	/* erm. not sure. *should* never get NOKp (without NOK) from sv_2nv
	 * without also getting a cached IV/UV from it at the same time
	 * (ie PV->NV conversion should detect loss of accuracy and cache
	 * IV or UV at same time to avoid this. */
	/* IV-over-UV optimisation - choose to cache IV if possible */

	if (SvTYPE(sv) == SVt_NV)
	    sv_upgrade(sv, SVt_PVNV);

	(void)SvIOKp_on(sv);	/* Must do this first, to clear any SvOOK */
	/* < not <= as for NV doesn't preserve UV, ((NV)IV_MAX+1) will almost
	   certainly cast into the IV range at IV_MAX, whereas the correct
	   answer is the UV IV_MAX +1. Hence < ensures that dodgy boundary
	   cases go to UV */
#if defined(NAN_COMPARE_BROKEN) && defined(Perl_isnan)
	if (Perl_isnan(SvNVX(sv))) {
	    SvUV_set(sv, 0);
	    SvIsUV_on(sv);
	    return FALSE;
	}
#endif
	if (SvNVX(sv) < (NV)IV_MAX + 0.5) {
	    SvIV_set(sv, I_V(SvNVX(sv)));
	    if (SvNVX(sv) == (NV) SvIVX(sv)
#ifndef NV_PRESERVES_UV
		&& (((UV)1 << NV_PRESERVES_UV_BITS) >
		    (UV)(SvIVX(sv) > 0 ? SvIVX(sv) : -SvIVX(sv)))
		/* Don't flag it as "accurately an integer" if the number
		   came from a (by definition imprecise) NV operation, and
		   we're outside the range of NV integer precision */
#endif
		) {
		SvIOK_on(sv);  /* Can this go wrong with rounding? NWC */
		DEBUG_c(PerlIO_printf(Perl_debug_log,
				      "0x%"UVxf" iv(%"NVgf" => %"IVdf") (precise)\n",
				      PTR2UV(sv),
				      SvNVX(sv),
				      SvIVX(sv)));

	    } else {
		/* IV not precise.  No need to convert from PV, as NV
		   conversion would already have cached IV if it detected
		   that PV->IV would be better than PV->NV->IV
		   flags already correct - don't set public IOK.  */
		DEBUG_c(PerlIO_printf(Perl_debug_log,
				      "0x%"UVxf" iv(%"NVgf" => %"IVdf") (imprecise)\n",
				      PTR2UV(sv),
				      SvNVX(sv),
				      SvIVX(sv)));
	    }
	    /* Can the above go wrong if SvIVX == IV_MIN and SvNVX < IV_MIN,
	       but the cast (NV)IV_MIN rounds to a the value less (more
	       negative) than IV_MIN which happens to be equal to SvNVX ??
	       Analogous to 0xFFFFFFFFFFFFFFFF rounding up to NV (2**64) and
	       NV rounding back to 0xFFFFFFFFFFFFFFFF, so UVX == UV(NVX) and
	       (NV)UVX == NVX are both true, but the values differ. :-(
	       Hopefully for 2s complement IV_MIN is something like
	       0x8000000000000000 which will be exact. NWC */
	}
	else {
	    SvUV_set(sv, U_V(SvNVX(sv)));
	    if (
		(SvNVX(sv) == (NV) SvUVX(sv))
#ifndef  NV_PRESERVES_UV
		/* Make sure it's not 0xFFFFFFFFFFFFFFFF */
		/*&& (SvUVX(sv) != UV_MAX) irrelevant with code below */
		&& (((UV)1 << NV_PRESERVES_UV_BITS) > SvUVX(sv))
		/* Don't flag it as "accurately an integer" if the number
		   came from a (by definition imprecise) NV operation, and
		   we're outside the range of NV integer precision */
#endif
		)
		SvIOK_on(sv);
	    SvIsUV_on(sv);
	    DEBUG_c(PerlIO_printf(Perl_debug_log,
				  "0x%"UVxf" 2iv(%"UVuf" => %"IVdf") (as unsigned)\n",
				  PTR2UV(sv),
				  SvUVX(sv),
				  SvUVX(sv)));
	}
    }
    else if (SvPOKp(sv) && SvLEN(sv)) {
	UV value;
	const int numtype = grok_number(SvPVX_const(sv), SvCUR(sv), &value);
	/* We want to avoid a possible problem when we cache an IV/ a UV which
	   may be later translated to an NV, and the resulting NV is not
	   the same as the direct translation of the initial string
	   (eg 123.456 can shortcut to the IV 123 with atol(), but we must
	   be careful to ensure that the value with the .456 is around if the
	   NV value is requested in the future).
	
	   This means that if we cache such an IV/a UV, we need to cache the
	   NV as well.  Moreover, we trade speed for space, and do not
	   cache the NV if we are sure it's not needed.
	 */

	/* SVt_PVNV is one higher than SVt_PVIV, hence this order  */
	if ((numtype & (IS_NUMBER_IN_UV | IS_NUMBER_NOT_INT))
	     == IS_NUMBER_IN_UV) {
	    /* It's definitely an integer, only upgrade to PVIV */
	    if (SvTYPE(sv) < SVt_PVIV)
		sv_upgrade(sv, SVt_PVIV);
	    (void)SvIOK_on(sv);
	} else if (SvTYPE(sv) < SVt_PVNV)
	    sv_upgrade(sv, SVt_PVNV);

	/* If NVs preserve UVs then we only use the UV value if we know that
	   we aren't going to call atof() below. If NVs don't preserve UVs
	   then the value returned may have more precision than atof() will
	   return, even though value isn't perfectly accurate.  */
	if ((numtype & (IS_NUMBER_IN_UV
#ifdef NV_PRESERVES_UV
			| IS_NUMBER_NOT_INT
#endif
	    )) == IS_NUMBER_IN_UV) {
	    /* This won't turn off the public IOK flag if it was set above  */
	    (void)SvIOKp_on(sv);

	    if (!(numtype & IS_NUMBER_NEG)) {
		/* positive */;
		if (value <= (UV)IV_MAX) {
		    SvIV_set(sv, (IV)value);
		} else {
		    /* it didn't overflow, and it was positive. */
		    SvUV_set(sv, value);
		    SvIsUV_on(sv);
		}
	    } else {
		/* 2s complement assumption  */
		if (value <= (UV)IV_MIN) {
		    SvIV_set(sv, -(IV)value);
		} else {
		    /* Too negative for an IV.  This is a double upgrade, but
		       I'm assuming it will be rare.  */
		    if (SvTYPE(sv) < SVt_PVNV)
			sv_upgrade(sv, SVt_PVNV);
		    SvNOK_on(sv);
		    SvIOK_off(sv);
		    SvIOKp_on(sv);
		    SvNV_set(sv, -(NV)value);
		    SvIV_set(sv, IV_MIN);
		}
	    }
	}
	/* For !NV_PRESERVES_UV and IS_NUMBER_IN_UV and IS_NUMBER_NOT_INT we
           will be in the previous block to set the IV slot, and the next
           block to set the NV slot.  So no else here.  */
	
	if ((numtype & (IS_NUMBER_IN_UV | IS_NUMBER_NOT_INT))
	    != IS_NUMBER_IN_UV) {
	    /* It wasn't an (integer that doesn't overflow the UV). */
	    SvNV_set(sv, Atof(SvPVX_const(sv)));

	    if (! numtype && ckWARN(WARN_NUMERIC))
		not_a_number(sv);

#if defined(USE_LONG_DOUBLE)
	    DEBUG_c(PerlIO_printf(Perl_debug_log, "0x%"UVxf" 2iv(%" PERL_PRIgldbl ")\n",
				  PTR2UV(sv), SvNVX(sv)));
#else
	    DEBUG_c(PerlIO_printf(Perl_debug_log, "0x%"UVxf" 2iv(%"NVgf")\n",
				  PTR2UV(sv), SvNVX(sv)));
#endif

#ifdef NV_PRESERVES_UV
            (void)SvIOKp_on(sv);
            (void)SvNOK_on(sv);
            if (SvNVX(sv) < (NV)IV_MAX + 0.5) {
                SvIV_set(sv, I_V(SvNVX(sv)));
                if ((NV)(SvIVX(sv)) == SvNVX(sv)) {
                    SvIOK_on(sv);
                } else {
		    NOOP;  /* Integer is imprecise. NOK, IOKp */
                }
                /* UV will not work better than IV */
            } else {
                if (SvNVX(sv) > (NV)UV_MAX) {
                    SvIsUV_on(sv);
                    /* Integer is inaccurate. NOK, IOKp, is UV */
                    SvUV_set(sv, UV_MAX);
                } else {
                    SvUV_set(sv, U_V(SvNVX(sv)));
                    /* 0xFFFFFFFFFFFFFFFF not an issue in here, NVs
                       NV preservse UV so can do correct comparison.  */
                    if ((NV)(SvUVX(sv)) == SvNVX(sv)) {
                        SvIOK_on(sv);
                    } else {
			NOOP;   /* Integer is imprecise. NOK, IOKp, is UV */
                    }
                }
		SvIsUV_on(sv);
            }
#else /* NV_PRESERVES_UV */
            if ((numtype & (IS_NUMBER_IN_UV | IS_NUMBER_NOT_INT))
                == (IS_NUMBER_IN_UV | IS_NUMBER_NOT_INT)) {
                /* The IV/UV slot will have been set from value returned by
                   grok_number above.  The NV slot has just been set using
                   Atof.  */
	        SvNOK_on(sv);
                assert (SvIOKp(sv));
            } else {
                if (((UV)1 << NV_PRESERVES_UV_BITS) >
                    U_V(SvNVX(sv) > 0 ? SvNVX(sv) : -SvNVX(sv))) {
                    /* Small enough to preserve all bits. */
                    (void)SvIOKp_on(sv);
                    SvNOK_on(sv);
                    SvIV_set(sv, I_V(SvNVX(sv)));
                    if ((NV)(SvIVX(sv)) == SvNVX(sv))
                        SvIOK_on(sv);
                    /* Assumption: first non-preserved integer is < IV_MAX,
                       this NV is in the preserved range, therefore: */
                    if (!(U_V(SvNVX(sv) > 0 ? SvNVX(sv) : -SvNVX(sv))
                          < (UV)IV_MAX)) {
                        Perl_croak(aTHX_ "sv_2iv assumed (U_V(fabs((double)SvNVX(sv))) < (UV)IV_MAX) but SvNVX(sv)=%"NVgf" U_V is 0x%"UVxf", IV_MAX is 0x%"UVxf"\n", SvNVX(sv), U_V(SvNVX(sv)), (UV)IV_MAX);
                    }
                } else {
                    /* IN_UV NOT_INT
                         0      0	already failed to read UV.
                         0      1       already failed to read UV.
                         1      0       you won't get here in this case. IV/UV
                         	        slot set, public IOK, Atof() unneeded.
                         1      1       already read UV.
                       so there's no point in sv_2iuv_non_preserve() attempting
                       to use atol, strtol, strtoul etc.  */
#  ifdef DEBUGGING
                    sv_2iuv_non_preserve (sv, numtype);
#  else
                    sv_2iuv_non_preserve (sv);
#  endif
                }
            }
#endif /* NV_PRESERVES_UV */
	}
    }
    else  {
	if (!(SvFLAGS(sv) & SVs_PADTMP)) {
	    if (!PL_localizing && ckWARN(WARN_UNINITIALIZED))
		report_uninit();
	}
	if (SvTYPE(sv) < SVt_IV)
	    /* Typically the caller expects that sv_any is not NULL now.  */
	    sv_upgrade(sv, SVt_IV);
	/* Return 0 from the caller.  */
	return TRUE;
    }
    return FALSE;
}

/*
=for apidoc sv_2iv_flags

Return the integer value of an SV, doing any necessary string
conversion.  If flags includes SV_GMAGIC, does an mg_get() first.
Normally used via the C<SvIV(sv)> and C<SvIVx(sv)> macros.

=cut
*/

IV
Perl_sv_2iv_flags(pTHX_ register SV *sv, I32 flags)
{
    if (!sv)
	return 0;
    if (SvGMAGICAL(sv) || SvTYPE(sv) == SVt_PVBM) {
	/* PVBMs use the same flag bit as SVf_IVisUV, so must let them
	   cache IVs just in case. In practice it seems that they never
	   actually anywhere accessible by user Perl code, let alone get used
	   in anything other than a string context.  */
	if (flags & SV_GMAGIC)
	    mg_get(sv);
	if (SvIOKp(sv))
	    return SvIVX(sv);
	if (SvNOKp(sv)) {
	    return I_V(SvNVX(sv));
	}
	if (SvPOKp(sv) && SvLEN(sv)) {
	    UV value;
	    const int numtype
		= grok_number(SvPVX_const(sv), SvCUR(sv), &value);

	    if ((numtype & (IS_NUMBER_IN_UV | IS_NUMBER_NOT_INT))
		== IS_NUMBER_IN_UV) {
		/* It's definitely an integer */
		if (numtype & IS_NUMBER_NEG) {
		    if (value < (UV)IV_MIN)
			return -(IV)value;
		} else {
		    if (value < (UV)IV_MAX)
			return (IV)value;
		}
	    }
	    if (!numtype) {
		if (ckWARN(WARN_NUMERIC))
		    not_a_number(sv);
	    }
	    return I_V(Atof(SvPVX_const(sv)));
	}
        if (SvROK(sv)) {
	    goto return_rok;
	}
	assert(SvTYPE(sv) >= SVt_PVMG);
	/* This falls through to the report_uninit inside S_sv_2iuv_common.  */
    } else if (SvTHINKFIRST(sv)) {
	if (SvROK(sv)) {
	return_rok:
	    if (SvAMAGIC(sv)) {
		SV * const tmpstr=AMG_CALLun(sv,numer);
		if (tmpstr && (!SvROK(tmpstr) || (SvRV(tmpstr) != SvRV(sv)))) {
		    return SvIV(tmpstr);
		}
	    }
	    return PTR2IV(SvRV(sv));
	}
	if (SvIsCOW(sv)) {
	    sv_force_normal_flags(sv, 0);
	}
	if (SvREADONLY(sv) && !SvOK(sv)) {
	    if (ckWARN(WARN_UNINITIALIZED))
		report_uninit();
	    return 0;
	}
    }
    if (!SvIOKp(sv)) {
	if (S_sv_2iuv_common(aTHX_ sv))
	    return 0;
    }
    DEBUG_c(PerlIO_printf(Perl_debug_log, "0x%"UVxf" 2iv(%"IVdf")\n",
	PTR2UV(sv),SvIVX(sv)));
    return SvIsUV(sv) ? (IV)SvUVX(sv) : SvIVX(sv);
}

/*
=for apidoc sv_2uv_flags

Return the unsigned integer value of an SV, doing any necessary string
conversion.  If flags includes SV_GMAGIC, does an mg_get() first.
Normally used via the C<SvUV(sv)> and C<SvUVx(sv)> macros.

=cut
*/

UV
Perl_sv_2uv_flags(pTHX_ register SV *sv, I32 flags)
{
    if (!sv)
	return 0;
    if (SvGMAGICAL(sv) || SvTYPE(sv) == SVt_PVBM) {
	/* PVBMs use the same flag bit as SVf_IVisUV, so must let them
	   cache IVs just in case.  */
	if (flags & SV_GMAGIC)
	    mg_get(sv);
	if (SvIOKp(sv))
	    return SvUVX(sv);
	if (SvNOKp(sv))
	    return U_V(SvNVX(sv));
	if (SvPOKp(sv) && SvLEN(sv)) {
	    UV value;
	    const int numtype
		= grok_number(SvPVX_const(sv), SvCUR(sv), &value);

	    if ((numtype & (IS_NUMBER_IN_UV | IS_NUMBER_NOT_INT))
		== IS_NUMBER_IN_UV) {
		/* It's definitely an integer */
		if (!(numtype & IS_NUMBER_NEG))
		    return value;
	    }
	    if (!numtype) {
		if (ckWARN(WARN_NUMERIC))
		    not_a_number(sv);
	    }
	    return U_V(Atof(SvPVX_const(sv)));
	}
        if (SvROK(sv)) {
	    goto return_rok;
	}
	assert(SvTYPE(sv) >= SVt_PVMG);
	/* This falls through to the report_uninit inside S_sv_2iuv_common.  */
    } else if (SvTHINKFIRST(sv)) {
	if (SvROK(sv)) {
	return_rok:
	    if (SvAMAGIC(sv)) {
		SV *const tmpstr = AMG_CALLun(sv,numer);
		if (tmpstr && (!SvROK(tmpstr) || (SvRV(tmpstr) != SvRV(sv)))) {
		    return SvUV(tmpstr);
		}
	    }
	    return PTR2UV(SvRV(sv));
	}
	if (SvREADONLY(sv) && SvFAKE(sv)) {
	    sv_force_normal(sv);
	}
	if (SvREADONLY(sv) && !SvOK(sv)) {
	    if (ckWARN(WARN_UNINITIALIZED))
		report_uninit();
	    return 0;
	}
    }
    if (!SvIOKp(sv)) {
	if (S_sv_2iuv_common(aTHX_ sv))
	    return 0;
    }

    DEBUG_c(PerlIO_printf(Perl_debug_log, "0x%"UVxf" 2uv(%"UVuf")\n",
			  PTR2UV(sv),SvUVX(sv)));
    return SvIsUV(sv) ? SvUVX(sv) : (UV)SvIVX(sv);
}

/*
=for apidoc sv_2nv

Return the num value of an SV, doing any necessary string or integer
conversion, magic etc. Normally used via the C<SvNV(sv)> and C<SvNVx(sv)>
macros.

=cut
*/

NV
Perl_sv_2nv(pTHX_ register SV *sv)
{
    if (!sv)
	return 0.0;
    if (SvGMAGICAL(sv) || SvTYPE(sv) == SVt_PVBM) {
	/* PVBMs use the same flag bit as SVf_IVisUV, so must let them
	   cache IVs just in case.  */
	mg_get(sv);
	if (SvNOKp(sv))
	    return SvNVX(sv);
	if ((SvPOKp(sv) && SvLEN(sv)) && !SvIOKp(sv)) {
	    if (!SvIOKp(sv) && ckWARN(WARN_NUMERIC) &&
		!grok_number(SvPVX_const(sv), SvCUR(sv), NULL))
		not_a_number(sv);
	    return Atof(SvPVX_const(sv));
	}
	if (SvIOKp(sv)) {
	    if (SvIsUV(sv))
		return (NV)SvUVX(sv);
	    else
		return (NV)SvIVX(sv);
	}
        if (SvROK(sv)) {
	    goto return_rok;
	}
	assert(SvTYPE(sv) >= SVt_PVMG);
	/* This falls through to the report_uninit near the end of the
	   function. */
    } else if (SvTHINKFIRST(sv)) {
	if (SvROK(sv)) {
	return_rok:
	    if (SvAMAGIC(sv)) {
		SV *const tmpstr = AMG_CALLun(sv,numer);
                if (tmpstr && (!SvROK(tmpstr) || (SvRV(tmpstr) != SvRV(sv)))) {
		    return SvNV(tmpstr);
		}
	    }
	    return PTR2NV(SvRV(sv));
	}
	if (SvREADONLY(sv) && SvFAKE(sv)) {
	    sv_force_normal(sv);
	}
	if (SvREADONLY(sv) && !SvOK(sv)) {
	    if (ckWARN(WARN_UNINITIALIZED))
		report_uninit();
	    return 0.0;
	}
    }
    if (SvTYPE(sv) < SVt_NV) {
	/* The logic to use SVt_PVNV if necessary is in sv_upgrade.  */
	sv_upgrade(sv, SVt_NV);
#ifdef USE_LONG_DOUBLE
	DEBUG_c({
	    STORE_NUMERIC_LOCAL_SET_STANDARD();
	    PerlIO_printf(Perl_debug_log,
			  "0x%"UVxf" num(%" PERL_PRIgldbl ")\n",
			  PTR2UV(sv), SvNVX(sv));
	    RESTORE_NUMERIC_LOCAL();
	});
#else
	DEBUG_c({
	    STORE_NUMERIC_LOCAL_SET_STANDARD();
	    PerlIO_printf(Perl_debug_log, "0x%"UVxf" num(%"NVgf")\n",
			  PTR2UV(sv), SvNVX(sv));
	    RESTORE_NUMERIC_LOCAL();
	});
#endif
    }
    else if (SvTYPE(sv) < SVt_PVNV)
	sv_upgrade(sv, SVt_PVNV);
    if (SvNOKp(sv)) {
        return SvNVX(sv);
    }
    if (SvIOKp(sv)) {
	SvNV_set(sv, SvIsUV(sv) ? (NV)SvUVX(sv) : (NV)SvIVX(sv));
#ifdef NV_PRESERVES_UV
	SvNOK_on(sv);
#else
	/* Only set the public NV OK flag if this NV preserves the IV  */
	/* Check it's not 0xFFFFFFFFFFFFFFFF */
	if (SvIsUV(sv) ? ((SvUVX(sv) != UV_MAX)&&(SvUVX(sv) == U_V(SvNVX(sv))))
		       : (SvIVX(sv) == I_V(SvNVX(sv))))
	    SvNOK_on(sv);
	else
	    SvNOKp_on(sv);
#endif
    }
    else if (SvPOKp(sv) && SvLEN(sv)) {
	UV value;
	const int numtype = grok_number(SvPVX_const(sv), SvCUR(sv), &value);
	if (!SvIOKp(sv) && !numtype && ckWARN(WARN_NUMERIC))
	    not_a_number(sv);
#ifdef NV_PRESERVES_UV
	if ((numtype & (IS_NUMBER_IN_UV | IS_NUMBER_NOT_INT))
	    == IS_NUMBER_IN_UV) {
	    /* It's definitely an integer */
	    SvNV_set(sv, (numtype & IS_NUMBER_NEG) ? -(NV)value : (NV)value);
	} else
	    SvNV_set(sv, Atof(SvPVX_const(sv)));
	SvNOK_on(sv);
#else
	SvNV_set(sv, Atof(SvPVX_const(sv)));
	/* Only set the public NV OK flag if this NV preserves the value in
	   the PV at least as well as an IV/UV would.
	   Not sure how to do this 100% reliably. */
	/* if that shift count is out of range then Configure's test is
	   wonky. We shouldn't be in here with NV_PRESERVES_UV_BITS ==
	   UV_BITS */
	if (((UV)1 << NV_PRESERVES_UV_BITS) >
	    U_V(SvNVX(sv) > 0 ? SvNVX(sv) : -SvNVX(sv))) {
	    SvNOK_on(sv); /* Definitely small enough to preserve all bits */
	} else if (!(numtype & IS_NUMBER_IN_UV)) {
            /* Can't use strtol etc to convert this string, so don't try.
               sv_2iv and sv_2uv will use the NV to convert, not the PV.  */
            SvNOK_on(sv);
        } else {
            /* value has been set.  It may not be precise.  */
	    if ((numtype & IS_NUMBER_NEG) && (value > (UV)IV_MIN)) {
		/* 2s complement assumption for (UV)IV_MIN  */
                SvNOK_on(sv); /* Integer is too negative.  */
            } else {
                SvNOKp_on(sv);
                SvIOKp_on(sv);

                if (numtype & IS_NUMBER_NEG) {
                    SvIV_set(sv, -(IV)value);
                } else if (value <= (UV)IV_MAX) {
		    SvIV_set(sv, (IV)value);
		} else {
		    SvUV_set(sv, value);
		    SvIsUV_on(sv);
		}

                if (numtype & IS_NUMBER_NOT_INT) {
                    /* I believe that even if the original PV had decimals,
                       they are lost beyond the limit of the FP precision.
                       However, neither is canonical, so both only get p
                       flags.  NWC, 2000/11/25 */
                    /* Both already have p flags, so do nothing */
                } else {
		    const NV nv = SvNVX(sv);
                    if (SvNVX(sv) < (NV)IV_MAX + 0.5) {
                        if (SvIVX(sv) == I_V(nv)) {
                            SvNOK_on(sv);
                        } else {
                            /* It had no "." so it must be integer.  */
                        }
			SvIOK_on(sv);
                    } else {
                        /* between IV_MAX and NV(UV_MAX).
                           Could be slightly > UV_MAX */

                        if (numtype & IS_NUMBER_NOT_INT) {
                            /* UV and NV both imprecise.  */
                        } else {
			    const UV nv_as_uv = U_V(nv);

                            if (value == nv_as_uv && SvUVX(sv) != UV_MAX) {
                                SvNOK_on(sv);
                            }
			    SvIOK_on(sv);
                        }
                    }
                }
            }
        }
#endif /* NV_PRESERVES_UV */
    }
    else  {
	if (!PL_localizing && !(SvFLAGS(sv) & SVs_PADTMP) && ckWARN(WARN_UNINITIALIZED))
	    report_uninit();
	assert (SvTYPE(sv) >= SVt_NV);
	/* Typically the caller expects that sv_any is not NULL now.  */
	/* XXX Ilya implies that this is a bug in callers that assume this
	   and ideally should be fixed.  */
	return 0.0;
    }
#if defined(USE_LONG_DOUBLE)
    DEBUG_c({
	STORE_NUMERIC_LOCAL_SET_STANDARD();
	PerlIO_printf(Perl_debug_log, "0x%"UVxf" 2nv(%" PERL_PRIgldbl ")\n",
		      PTR2UV(sv), SvNVX(sv));
	RESTORE_NUMERIC_LOCAL();
    });
#else
    DEBUG_c({
	STORE_NUMERIC_LOCAL_SET_STANDARD();
	PerlIO_printf(Perl_debug_log, "0x%"UVxf" 1nv(%"NVgf")\n",
		      PTR2UV(sv), SvNVX(sv));
	RESTORE_NUMERIC_LOCAL();
    });
#endif
    return SvNVX(sv);
}

/*
=for apidoc sv_2num

Return an SV with the numeric value of the source SV, doing any necessary
reference or overload conversion.  You must use the C<SvNUM(sv)> macro to
access this function.

=cut
*/

SV *
Perl_sv_2num(pTHX_ register SV *sv)
{
    if (!SvROK(sv))
	return sv;
    if (SvAMAGIC(sv)) {
	SV * const tmpsv = AMG_CALLun(sv,numer);
	if (tmpsv && (!SvROK(tmpsv) || (SvRV(tmpsv) != SvRV(sv))))
	    return sv_2num(tmpsv);
    }
    return sv_2mortal(newSVuv(PTR2UV(SvRV(sv))));
}

/* uiv_2buf(): private routine for use by sv_2pv_flags(): print an IV or
 * UV as a string towards the end of buf, and return pointers to start and
 * end of it.
 *
 * We assume that buf is at least TYPE_CHARS(UV) long.
 */

static char *
S_uiv_2buf(char *buf, IV iv, UV uv, int is_uv, char **peob)
{
    char *ptr = buf + TYPE_CHARS(UV);
    char * const ebuf = ptr;
    int sign;

    if (is_uv)
	sign = 0;
    else if (iv >= 0) {
	uv = iv;
	sign = 0;
    } else {
	uv = -iv;
	sign = 1;
    }
    do {
	*--ptr = '0' + (char)(uv % 10);
    } while (uv /= 10);
    if (sign)
	*--ptr = '-';
    *peob = ebuf;
    return ptr;
}

/* stringify_regexp(): private routine for use by sv_2pv_flags(): converts
 * a regexp to its stringified form.
 */

static char *
S_stringify_regexp(pTHX_ SV *sv, MAGIC *mg, STRLEN *lp) {
    const regexp * const re = (regexp *)mg->mg_obj;

    if (!mg->mg_ptr) {
	const char *fptr = "msix";
	char reflags[6];
	char ch;
	int left = 0;
	int right = 4;
	bool need_newline = 0;
	U16 reganch = (U16)((re->reganch & PMf_COMPILETIME) >> 12);

	while((ch = *fptr++)) {
	    if(reganch & 1) {
		reflags[left++] = ch;
	    }
	    else {
		reflags[right--] = ch;
	    }
	    reganch >>= 1;
	}
	if(left != 4) {
	    reflags[left] = '-';
	    left = 5;
	}

	mg->mg_len = re->prelen + 4 + left;
	/*
	 * If /x was used, we have to worry about a regex ending with a
	 * comment later being embedded within another regex. If so, we don't
	 * want this regex's "commentization" to leak out to the right part of
	 * the enclosing regex, we must cap it with a newline.
	 *
	 * So, if /x was used, we scan backwards from the end of the regex. If
	 * we find a '#' before we find a newline, we need to add a newline
	 * ourself. If we find a '\n' first (or if we don't find '#' or '\n'),
	 * we don't need to add anything.  -jfriedl
	 */
	if (PMf_EXTENDED & re->reganch) {
	    const char *endptr = re->precomp + re->prelen;
	    while (endptr >= re->precomp) {
		const char c = *(endptr--);
		if (c == '\n')
		    break; /* don't need another */
		if (c == '#') {
		    /* we end while in a comment, so we need a newline */
		    mg->mg_len++; /* save space for it */
		    need_newline = 1; /* note to add it */
		    break;
		}
	    }
	}

	Newx(mg->mg_ptr, mg->mg_len + 1 + left, char);
	mg->mg_ptr[0] = '(';
	mg->mg_ptr[1] = '?';
	Copy(reflags, mg->mg_ptr+2, left, char);
	*(mg->mg_ptr+left+2) = ':';
	Copy(re->precomp, mg->mg_ptr+3+left, re->prelen, char);
	if (need_newline)
	    mg->mg_ptr[mg->mg_len - 2] = '\n';
	mg->mg_ptr[mg->mg_len - 1] = ')';
	mg->mg_ptr[mg->mg_len] = 0;
    }
    PL_reginterp_cnt += re->program[0].next_off;
    
    if (re->reganch & ROPT_UTF8)
	SvUTF8_on(sv);
    else
	SvUTF8_off(sv);
    if (lp)
	*lp = mg->mg_len;
    return mg->mg_ptr;
}

/*
=for apidoc sv_2pv_flags

Returns a pointer to the string value of an SV, and sets *lp to its length.
If flags includes SV_GMAGIC, does an mg_get() first. Coerces sv to a string
if necessary.
Normally invoked via the C<SvPV_flags> macro. C<sv_2pv()> and C<sv_2pv_nomg>
usually end up here too.

=cut
*/

char *
Perl_sv_2pv_flags(pTHX_ register SV *sv, STRLEN *lp, I32 flags)
{
    register char *s;

    if (!sv) {
	if (lp)
	    *lp = 0;
	return (char *)"";
    }
    if (SvGMAGICAL(sv)) {
	if (flags & SV_GMAGIC)
	    mg_get(sv);
	if (SvPOKp(sv)) {
	    if (lp)
		*lp = SvCUR(sv);
	    if (flags & SV_MUTABLE_RETURN)
		return SvPVX_mutable(sv);
	    if (flags & SV_CONST_RETURN)
		return (char *)SvPVX_const(sv);
	    return SvPVX(sv);
	}
	if (SvIOKp(sv) || SvNOKp(sv)) {
	    char tbuf[64];  /* Must fit sprintf/Gconvert of longest IV/NV */
	    STRLEN len;

	    if (SvIOKp(sv)) {
		len = SvIsUV(sv)
		    ? my_snprintf(tbuf, sizeof(tbuf), "%"UVuf, (UV)SvUVX(sv))
		    : my_snprintf(tbuf, sizeof(tbuf), "%"IVdf, (IV)SvIVX(sv));
	    } else {
		Gconvert(SvNVX(sv), NV_DIG, 0, tbuf);
		len = strlen(tbuf);
	    }

	    {

#ifdef FIXNEGATIVEZERO
		if (len == 2 && tbuf[0] == '-' && tbuf[1] == '0') {
		    tbuf[0] = '0';
		    tbuf[1] = 0;
		    len = 1;
		}
#endif
		SvUPGRADE(sv, SVt_PV);
		if (lp)
		    *lp = len;
		s = SvGROW_mutable(sv, len + 1);
		SvCUR_set(sv, len);
		SvPOKp_on(sv);
		return (char*)memcpy(s, tbuf, len + 1);
	    }
	}
        if (SvROK(sv)) {
	    goto return_rok;
	}
	assert(SvTYPE(sv) >= SVt_PVMG);
	/* This falls through to the report_uninit near the end of the
	   function. */
    } else if (SvTHINKFIRST(sv)) {
	if (SvROK(sv)) {
	return_rok:
            if (SvAMAGIC(sv)) {
		SV *const tmpstr = AMG_CALLun(sv,string);
		if (tmpstr && (!SvROK(tmpstr) || (SvRV(tmpstr) != SvRV(sv)))) {
		    /* Unwrap this:  */
		    /* char *pv = lp ? SvPV(tmpstr, *lp) : SvPV_nolen(tmpstr);
		     */

		    char *pv;
		    if ((SvFLAGS(tmpstr) & (SVf_POK)) == SVf_POK) {
			if (flags & SV_CONST_RETURN) {
			    pv = (char *) SvPVX_const(tmpstr);
			} else {
			    pv = (flags & SV_MUTABLE_RETURN)
				? SvPVX_mutable(tmpstr) : SvPVX(tmpstr);
			}
			if (lp)
			    *lp = SvCUR(tmpstr);
		    } else {
			pv = sv_2pv_flags(tmpstr, lp, flags);
		    }
		    if (SvUTF8(tmpstr))
			SvUTF8_on(sv);
		    else
			SvUTF8_off(sv);
		    return pv;
		}
	    }
	    {
		STRLEN len;
		char *retval;
		char *buffer;
		MAGIC *mg;
		const SV *const referent = (SV*)SvRV(sv);

		if (!referent) {
		    len = 7;
		    retval = buffer = savepvn("NULLREF", len);
		} else if (SvTYPE(referent) == SVt_PVMG
			   && ((SvFLAGS(referent) &
				(SVs_OBJECT|SVf_OK|SVs_GMG|SVs_SMG|SVs_RMG))
			       == (SVs_OBJECT|SVs_SMG))
			   && (mg = mg_find((SV *) referent, PERL_MAGIC_qr))) {
		    return stringify_regexp(sv, mg, lp);
		} else {
		    const char *const typestr = sv_reftype((SV *) referent, 0);
		    const STRLEN typelen = strlen(typestr);
		    UV addr = PTR2UV(referent);
		    const char *stashname = NULL;
		    STRLEN stashnamelen = 0; /* hush, gcc */
		    const char *buffer_end;

		    if (SvOBJECT(referent)) {
			stashname = HvNAME_get(SvSTASH(referent));

			if (stashname) {
			    stashnamelen = strlen(stashname);
			    SvUTF8_off(sv);
			} else {
			    stashname = "__ANON__";
			    stashnamelen = 8;
			}
			len = stashnamelen + 1 /* = */ + typelen + 3 /* (0x */
			    + 2 * sizeof(UV) + 2 /* )\0 */;
		    } else {
			len = typelen + 3 /* (0x */
			    + 2 * sizeof(UV) + 2 /* )\0 */;
		    }

		    Newx(buffer, len, char);
		    buffer_end = retval = buffer + len;

		    /* Working backwards  */
		    *--retval = '\0';
		    *--retval = ')';
		    do {
			*--retval = PL_hexdigit[addr & 15];
		    } while (addr >>= 4);
		    *--retval = 'x';
		    *--retval = '0';
		    *--retval = '(';

		    retval -= typelen;
		    memcpy(retval, typestr, typelen);

		    if (stashname) {
			*--retval = '=';
			retval -= stashnamelen;
			memcpy(retval, stashname, stashnamelen);
		    }
		    /* retval may not neccesarily have reached the start of the
		       buffer here.  */
		    assert (retval >= buffer);

		    len = buffer_end - retval - 1; /* -1 for that \0  */
		}
		if (lp)
		    *lp = len;
		SAVEFREEPV(buffer);
		return retval;
	    }
	}
	if (SvREADONLY(sv) && !SvOK(sv)) {
	    if (ckWARN(WARN_UNINITIALIZED))
		report_uninit();
	    if (lp)
		*lp = 0;
	    return (char *)"";
	}
    }
    if (SvIOK(sv) || ((SvIOKp(sv) && !SvNOKp(sv)))) {
	/* I'm assuming that if both IV and NV are equally valid then
	   converting the IV is going to be more efficient */
	const U32 isUIOK = SvIsUV(sv);
	char buf[TYPE_CHARS(UV)];
	char *ebuf, *ptr;
	STRLEN len;

	if (SvTYPE(sv) < SVt_PVIV)
	    sv_upgrade(sv, SVt_PVIV);
 	ptr = uiv_2buf(buf, SvIVX(sv), SvUVX(sv), isUIOK, &ebuf);
	len = ebuf - ptr;
	/* inlined from sv_setpvn */
	s = SvGROW_mutable(sv, len + 1);
	Move(ptr, s, len, char);
	s += len;
	*s = '\0';
    }
    else if (SvNOKp(sv)) {
	const int olderrno = errno;
	if (SvTYPE(sv) < SVt_PVNV)
	    sv_upgrade(sv, SVt_PVNV);
	/* The +20 is pure guesswork.  Configure test needed. --jhi */
	s = SvGROW_mutable(sv, NV_DIG + 20);
	/* some Xenix systems wipe out errno here */
#ifdef apollo
	if (SvNVX(sv) == 0.0)
	    my_strlcpy(s, "0", SvLEN(sv));
	else
#endif /*apollo*/
	{
	    Gconvert(SvNVX(sv), NV_DIG, 0, s);
	}
	errno = olderrno;
#ifdef FIXNEGATIVEZERO
        if (*s == '-' && s[1] == '0' && !s[2]) {
	    s[0] = '0';
	    s[1] = 0;
	}
#endif
	while (*s) s++;
#ifdef hcx
	if (s[-1] == '.')
	    *--s = '\0';
#endif
    }
    else {
	if (!PL_localizing && !(SvFLAGS(sv) & SVs_PADTMP) && ckWARN(WARN_UNINITIALIZED))
	    report_uninit();
	if (lp)
	    *lp = 0;
	if (SvTYPE(sv) < SVt_PV)
	    /* Typically the caller expects that sv_any is not NULL now.  */
	    sv_upgrade(sv, SVt_PV);
	return (char *)"";
    }
    {
	const STRLEN len = s - SvPVX_const(sv);
	if (lp) 
	    *lp = len;
	SvCUR_set(sv, len);
    }
    SvPOK_on(sv);
    DEBUG_c(PerlIO_printf(Perl_debug_log, "0x%"UVxf" 2pv(%s)\n",
			  PTR2UV(sv),SvPVX_const(sv)));
    if (flags & SV_CONST_RETURN)
	return (char *)SvPVX_const(sv);
    if (flags & SV_MUTABLE_RETURN)
	return SvPVX_mutable(sv);
    return SvPVX(sv);
}

/*
=for apidoc sv_copypv

Copies a stringified representation of the source SV into the
destination SV.  Automatically performs any necessary mg_get and
coercion of numeric values into strings.  Guaranteed to preserve
UTF8 flag even from overloaded objects.  Similar in nature to
sv_2pv[_flags] but operates directly on an SV instead of just the
string.  Mostly uses sv_2pv_flags to do its work, except when that
would lose the UTF-8'ness of the PV.

=cut
*/

void
Perl_sv_copypv(pTHX_ SV *dsv, register SV *ssv)
{
    STRLEN len;
    const char * const s = SvPV_const(ssv,len);
    sv_setpvn(dsv,s,len);
    if (SvUTF8(ssv))
	SvUTF8_on(dsv);
    else
	SvUTF8_off(dsv);
}

/*
=for apidoc sv_2pvbyte

Return a pointer to the byte-encoded representation of the SV, and set *lp
to its length.  May cause the SV to be downgraded from UTF-8 as a
side-effect.

Usually accessed via the C<SvPVbyte> macro.

=cut
*/

char *
Perl_sv_2pvbyte(pTHX_ register SV *sv, STRLEN *lp)
{
    sv_utf8_downgrade(sv,0);
    return lp ? SvPV(sv,*lp) : SvPV_nolen(sv);
}

/*
=for apidoc sv_2pvutf8

Return a pointer to the UTF-8-encoded representation of the SV, and set *lp
to its length.  May cause the SV to be upgraded to UTF-8 as a side-effect.

Usually accessed via the C<SvPVutf8> macro.

=cut
*/

char *
Perl_sv_2pvutf8(pTHX_ register SV *sv, STRLEN *lp)
{
    sv_utf8_upgrade(sv);
    return lp ? SvPV(sv,*lp) : SvPV_nolen(sv);
}


/*
=for apidoc sv_2bool

This function is only called on magical items, and is only used by
sv_true() or its macro equivalent.

=cut
*/

bool
Perl_sv_2bool(pTHX_ register SV *sv)
{
    SvGETMAGIC(sv);

    if (!SvOK(sv))
	return 0;
    if (SvROK(sv)) {
	if (SvAMAGIC(sv)) {
	    SV * const tmpsv = AMG_CALLun(sv,bool_);
	    if (tmpsv && (!SvROK(tmpsv) || (SvRV(tmpsv) != SvRV(sv))))
		return (bool)SvTRUE(tmpsv);
	}
	return SvRV(sv) != 0;
    }
    if (SvPOKp(sv)) {
	register XPV* const Xpvtmp = (XPV*)SvANY(sv);
	if (Xpvtmp &&
		(*Xpvtmp->xpv_pv > '0' ||
		Xpvtmp->xpv_cur > 1 ||
		(Xpvtmp->xpv_cur && *Xpvtmp->xpv_pv != '0')))
	    return 1;
	else
	    return 0;
    }
    else {
	if (SvIOKp(sv))
	    return SvIVX(sv) != 0;
	else {
	    if (SvNOKp(sv))
		return SvNVX(sv) != 0.0;
	    else
		return FALSE;
	}
    }
}

/*
=for apidoc sv_utf8_upgrade

Converts the PV of an SV to its UTF-8-encoded form.
Forces the SV to string form if it is not already.
Always sets the SvUTF8 flag to avoid future validity checks even
if all the bytes have hibit clear.

This is not as a general purpose byte encoding to Unicode interface:
use the Encode extension for that.

=for apidoc sv_utf8_upgrade_flags

Converts the PV of an SV to its UTF-8-encoded form.
Forces the SV to string form if it is not already.
Always sets the SvUTF8 flag to avoid future validity checks even
if all the bytes have hibit clear. If C<flags> has C<SV_GMAGIC> bit set,
will C<mg_get> on C<sv> if appropriate, else not. C<sv_utf8_upgrade> and
C<sv_utf8_upgrade_nomg> are implemented in terms of this function.

This is not as a general purpose byte encoding to Unicode interface:
use the Encode extension for that.

=cut
*/

STRLEN
Perl_sv_utf8_upgrade_flags(pTHX_ register SV *sv, I32 flags)
{
    if (sv == &PL_sv_undef)
	return 0;
    if (!SvPOK(sv)) {
	STRLEN len = 0;
	if (SvREADONLY(sv) && (SvPOKp(sv) || SvIOKp(sv) || SvNOKp(sv))) {
	    (void) sv_2pv_flags(sv,&len, flags);
	    if (SvUTF8(sv))
		return len;
	} else {
	    (void) SvPV_force(sv,len);
	}
    }

    if (SvUTF8(sv)) {
	return SvCUR(sv);
    }

    if (SvREADONLY(sv) && SvFAKE(sv)) {
	sv_force_normal(sv);
    }

    if (PL_encoding && !(flags & SV_UTF8_NO_ENCODING))
        sv_recode_to_utf8(sv, PL_encoding);
    else { /* Assume Latin-1/EBCDIC */
	/* This function could be much more efficient if we
	 * had a FLAG in SVs to signal if there are any hibit
	 * chars in the PV.  Given that there isn't such a flag
	 * make the loop as fast as possible. */
	const U8 * const s = (U8 *) SvPVX_const(sv);
	const U8 * const e = (U8 *) SvEND(sv);
	const U8 *t = s;
	
	while (t < e) {
	    const U8 ch = *t++;
	    /* Check for hi bit */
	    if (!NATIVE_IS_INVARIANT(ch)) {
		STRLEN len = SvCUR(sv);
		/* *Currently* bytes_to_utf8() adds a '\0' after every string
		   it converts. This isn't documented. It's not clear if it's
		   a bad thing to be doing, and should be changed to do exactly
		   what the documentation says. If so, this code will have to
		   be changed.
		   As is, we mustn't rely on our incoming SV being well formed
		   and having a trailing '\0', as certain code in pp_formline
		   can send us partially built SVs. */
		U8 * const recoded = bytes_to_utf8((U8*)s, &len);

		SvPV_free(sv); /* No longer using what was there before. */
		SvPV_set(sv, (char*)recoded);
		SvCUR_set(sv, len);
		SvLEN_set(sv, len + 1); /* No longer know the real size. */
		break;
	    }
	}
	/* Mark as UTF-8 even if no hibit - saves scanning loop */
	SvUTF8_on(sv);
    }
    return SvCUR(sv);
}

/*
=for apidoc sv_utf8_downgrade

Attempts to convert the PV of an SV from characters to bytes.
If the PV contains a character beyond byte, this conversion will fail;
in this case, either returns false or, if C<fail_ok> is not
true, croaks.

This is not as a general purpose Unicode to byte encoding interface:
use the Encode extension for that.

=cut
*/

bool
Perl_sv_utf8_downgrade(pTHX_ register SV* sv, bool fail_ok)
{
    if (SvPOKp(sv) && SvUTF8(sv)) {
        if (SvCUR(sv)) {
	    U8 *s;
	    STRLEN len;

	    if (SvREADONLY(sv) && SvFAKE(sv))
		sv_force_normal(sv);
	    s = (U8 *) SvPV(sv, len);
	    if (!utf8_to_bytes(s, &len)) {
	        if (fail_ok)
		    return FALSE;
		else {
		    if (PL_op)
		        Perl_croak(aTHX_ "Wide character in %s",
				   OP_DESC(PL_op));
		    else
		        Perl_croak(aTHX_ "Wide character");
		}
	    }
	    SvCUR_set(sv, len);
	}
    }
    SvUTF8_off(sv);
    return TRUE;
}

/*
=for apidoc sv_utf8_encode

Converts the PV of an SV to UTF-8, but then turns the C<SvUTF8>
flag off so that it looks like octets again.

=cut
*/

void
Perl_sv_utf8_encode(pTHX_ register SV *sv)
{
    if (SvIsCOW(sv)) {
        sv_force_normal_flags(sv, 0);
    }
    if (SvREADONLY(sv)) {
	Perl_croak(aTHX_ "%s", PL_no_modify);
    }
    (void) sv_utf8_upgrade(sv);
    SvUTF8_off(sv);
}

/*
=for apidoc sv_utf8_decode

If the PV of the SV is an octet sequence in UTF-8
and contains a multiple-byte character, the C<SvUTF8> flag is turned on
so that it looks like a character. If the PV contains only single-byte
characters, the C<SvUTF8> flag stays being off.
Scans PV for validity and returns false if the PV is invalid UTF-8.

=cut
*/

bool
Perl_sv_utf8_decode(pTHX_ register SV *sv)
{
    if (SvPOKp(sv)) {
        const U8 *c;
        const U8 *e;

	/* The octets may have got themselves encoded - get them back as
	 * bytes
	 */
	if (!sv_utf8_downgrade(sv, TRUE))
	    return FALSE;

        /* it is actually just a matter of turning the utf8 flag on, but
         * we want to make sure everything inside is valid utf8 first.
         */
        c = (const U8 *) SvPVX_const(sv);
	if (!is_utf8_string((U8 *)c, SvCUR(sv)+1))
	    return FALSE;
        e = (const U8 *) SvEND(sv);
        while (c < e) {
	    const U8 ch = *c++;
            if (!UTF8_IS_INVARIANT(ch)) {
		SvUTF8_on(sv);
		break;
	    }
        }
    }
    return TRUE;
}

/*
=for apidoc sv_setsv

Copies the contents of the source SV C<ssv> into the destination SV
C<dsv>.  The source SV may be destroyed if it is mortal, so don't use this
function if the source SV needs to be reused. Does not handle 'set' magic.
Loosely speaking, it performs a copy-by-value, obliterating any previous
content of the destination.

You probably want to use one of the assortment of wrappers, such as
C<SvSetSV>, C<SvSetSV_nosteal>, C<SvSetMagicSV> and
C<SvSetMagicSV_nosteal>.

=for apidoc sv_setsv_flags

Copies the contents of the source SV C<ssv> into the destination SV
C<dsv>.  The source SV may be destroyed if it is mortal, so don't use this
function if the source SV needs to be reused. Does not handle 'set' magic.
Loosely speaking, it performs a copy-by-value, obliterating any previous
content of the destination.
If the C<flags> parameter has the C<SV_GMAGIC> bit set, will C<mg_get> on
C<ssv> if appropriate, else not. If the C<flags> parameter has the
C<NOSTEAL> bit set then the buffers of temps will not be stolen. <sv_setsv>
and C<sv_setsv_nomg> are implemented in terms of this function.

You probably want to use one of the assortment of wrappers, such as
C<SvSetSV>, C<SvSetSV_nosteal>, C<SvSetMagicSV> and
C<SvSetMagicSV_nosteal>.

This is the primary function for copying scalars, and most other
copy-ish functions and macros use this underneath.

=cut
*/

static void
S_glob_assign_glob(pTHX_ SV *dstr, SV *sstr, const int dtype)
{
    if (dtype != SVt_PVGV) {
	const char * const name = GvNAME(sstr);
	const STRLEN len = GvNAMELEN(sstr);
	sv_upgrade(dstr, SVt_PVGV);
	sv_magic(dstr, dstr, PERL_MAGIC_glob, Nullch, 0);
	GvSTASH(dstr) = (HV*)SvREFCNT_inc(GvSTASH(sstr));
	gv_name_set((GV *)dstr, name, len, GV_ADD);
	SvFAKE_on(dstr);	/* can coerce to non-glob */
    }

#ifdef GV_UNIQUE_CHECK
    if (GvUNIQUE((GV*)dstr)) {
	Perl_croak(aTHX_ "%s", PL_no_modify);
    }
#endif

    (void)SvOK_off(dstr);
    GvINTRO_off(dstr);		/* one-shot flag */
    gp_free((GV*)dstr);
    GvGP(dstr) = gp_ref(GvGP(sstr));
    if (SvTAINTED(sstr))
	SvTAINT(dstr);
    if (GvIMPORTED(dstr) != GVf_IMPORTED
	&& CopSTASH_ne(PL_curcop, GvSTASH(dstr)))
	{
	    GvIMPORTED_on(dstr);
	}
    GvMULTI_on(dstr);
    return;
}

static void
S_glob_assign_ref(pTHX_ SV *dstr, SV *sstr) {
    SV * const sref = SvREFCNT_inc(SvRV(sstr));
    SV *dref = NULL;
    const int intro = GvINTRO(dstr);
    SV **location;
    U8 import_flag = 0;
    const U32 stype = SvTYPE(sref);


#ifdef GV_UNIQUE_CHECK
    if (GvUNIQUE((GV*)dstr)) {
	Perl_croak(aTHX_ "%s", PL_no_modify);
    }
#endif

    if (intro) {
	GvINTRO_off(dstr);	/* one-shot flag */
	GvLINE(dstr) = CopLINE(PL_curcop);
	GvEGV(dstr) = (GV*)dstr;
    }
    GvMULTI_on(dstr);
    switch (stype) {
    case SVt_PVCV:
	location = (SV **) &GvCV(dstr);
	import_flag = GVf_IMPORTED_CV;
	goto common;
    case SVt_PVHV:
	location = (SV **) &GvHV(dstr);
	import_flag = GVf_IMPORTED_HV;
	goto common;
    case SVt_PVAV:
	location = (SV **) &GvAV(dstr);
	import_flag = GVf_IMPORTED_AV;
	goto common;
    case SVt_PVIO:
	location = (SV **) &GvIOp(dstr);
	goto common;
    case SVt_PVFM:
	location = (SV **) &GvFORM(dstr);
    default:
	location = &GvSV(dstr);
	import_flag = GVf_IMPORTED_SV;
    common:
	if (intro) {
	    if (stype == SVt_PVCV) {
		if (GvCVGEN(dstr) && GvCV(dstr) != (CV*)sref) {
		    SvREFCNT_dec(GvCV(dstr));
		    GvCV(dstr) = NULL;
		    GvCVGEN(dstr) = 0; /* Switch off cacheness. */
		    PL_sub_generation++;
		}
	    }
	    SAVEGENERICSV(*location);
	}
	else
	    dref = *location;
	if (stype == SVt_PVCV && *location != sref) {
	    CV* const cv = (CV*)*location;
	    if (cv) {
		if (!GvCVGEN((GV*)dstr) &&
		    (CvROOT(cv) || CvXSUB(cv)))
		    {
			/* Redefining a sub - warning is mandatory if
			   it was a const and its value changed. */
			if (CvCONST(cv)	&& CvCONST((CV*)sref)
			    && cv_const_sv(cv) == cv_const_sv((CV*)sref)) {
			    NOOP;
			    /* They are 2 constant subroutines generated from
			       the same constant. This probably means that
			       they are really the "same" proxy subroutine
			       instantiated in 2 places. Most likely this is
			       when a constant is exported twice.  Don't warn.
			    */
			}
			else if (ckWARN(WARN_REDEFINE)
				 || (CvCONST(cv)
				     && (!CvCONST((CV*)sref)
					 || sv_cmp(cv_const_sv(cv),
						   cv_const_sv((CV*)sref))))) {
			    Perl_warner(aTHX_ packWARN(WARN_REDEFINE),
					(const char *)
					(CvCONST(cv)
					 ? "Constant subroutine %s::%s redefined"
					 : "Subroutine %s::%s redefined"),
					HvNAME_get(GvSTASH((GV*)dstr)),
					GvENAME((GV*)dstr));
			}
		    }
		if (!intro)
		    cv_ckproto_len(cv, (GV*)dstr,
				   SvPOK(sref)
				   ? (char *) SvPVX_const(sref) : NULL,
				   SvPOK(sref) ? SvCUR(sref) : 0);
	    }
	    GvCVGEN(dstr) = 0; /* Switch off cacheness. */
	    GvASSUMECV_on(dstr);
	    PL_sub_generation++;
	}
	*location = sref;
	if (import_flag && !(GvFLAGS(dstr) & import_flag)
	    && CopSTASH_ne(PL_curcop, GvSTASH(dstr))) {
	    GvFLAGS(dstr) |= import_flag;
	}
	break;
    }
    if (dref)
	SvREFCNT_dec(dref);
    if (SvTAINTED(sstr))
	SvTAINT(dstr);
    return;
}

void
Perl_sv_setsv_flags(pTHX_ SV *dstr, register SV *sstr, I32 flags)
{
    register U32 sflags;
    register int dtype;
    register svtype stype;

    if (sstr == dstr)
	return;

    if (SvIS_FREED(dstr)) {
	Perl_croak(aTHX_ "panic: attempt to copy value %" SVf
		   " to a freed scalar %p", sstr, dstr);
    }
    SV_CHECK_THINKFIRST(dstr);
    if (!sstr)
	sstr = &PL_sv_undef;
    if (SvIS_FREED(sstr)) {
	Perl_croak(aTHX_ "panic: attempt to copy freed scalar %p to %p", sstr,
		   dstr);
    }
    stype = SvTYPE(sstr);
    dtype = SvTYPE(dstr);

    (void)SvAMAGIC_off(dstr);
    if ( SvVOK(dstr) ) 
    {
	/* need to nuke the magic */
	mg_free(dstr);
    }

    /* There's a lot of redundancy below but we're going for speed here */

    switch (stype) {
    case SVt_NULL:
      undef_sstr:
	if (dtype != SVt_PVGV) {
	    (void)SvOK_off(dstr);
	    return;
	}
	break;
    case SVt_IV:
	if (SvIOK(sstr)) {
	    switch (dtype) {
	    case SVt_NULL:
		sv_upgrade(dstr, SVt_IV);
		break;
	    case SVt_NV:
	    case SVt_RV:
	    case SVt_PV:
		sv_upgrade(dstr, SVt_PVIV);
		break;
	    }
	    (void)SvIOK_only(dstr);
	    SvIV_set(dstr,  SvIVX(sstr));
	    if (SvIsUV(sstr))
		SvIsUV_on(dstr);
	    /* SvTAINTED can only be true if the SV has taint magic, which in
	       turn means that the SV type is PVMG (or greater). This is the
	       case statement for SVt_IV, so this cannot be true (whatever gcov
	       may say).  */
	    return;
	}
	goto undef_sstr;

    case SVt_NV:
	if (SvNOK(sstr)) {
	    switch (dtype) {
	    case SVt_NULL:
	    case SVt_IV:
		sv_upgrade(dstr, SVt_NV);
		break;
	    case SVt_RV:
	    case SVt_PV:
	    case SVt_PVIV:
		sv_upgrade(dstr, SVt_PVNV);
		break;
	    }
	    SvNV_set(dstr, SvNVX(sstr));
	    (void)SvNOK_only(dstr);
	    /* SvTAINTED can only be true if the SV has taint magic, which in
	       turn means that the SV type is PVMG (or greater). This is the
	       case statement for SVt_NV, so this cannot be true (whatever gcov
	       may say).  */
	    return;
	}
	goto undef_sstr;

    case SVt_RV:
	if (dtype < SVt_RV)
	    sv_upgrade(dstr, SVt_RV);
	break;
    case SVt_PV:
    case SVt_PVFM:
	if (dtype < SVt_PV)
	    sv_upgrade(dstr, SVt_PV);
	break;
    case SVt_PVIV:
	if (dtype < SVt_PVIV)
	    sv_upgrade(dstr, SVt_PVIV);
	break;
    case SVt_PVNV:
	if (dtype < SVt_PVNV)
	    sv_upgrade(dstr, SVt_PVNV);
	break;
    default:
	{
	const char * const type = sv_reftype(sstr,0);
	if (PL_op)
	    Perl_croak(aTHX_ "Bizarre copy of %s in %s", type, OP_NAME(PL_op));
	else
	    Perl_croak(aTHX_ "Bizarre copy of %s", type);
	}
	break;

    case SVt_PVGV:
	if (dtype <= SVt_PVGV) {
	    glob_assign_glob(dstr, sstr, dtype);
	    return;
	}
	/*FALLTHROUGH*/

    case SVt_PVMG:
    case SVt_PVLV:
    case SVt_PVBM:
	if (SvGMAGICAL(sstr) && (flags & SV_GMAGIC)) {
	    mg_get(sstr);
	    if (SvTYPE(sstr) != stype) {
		stype = SvTYPE(sstr);
		if (stype == SVt_PVGV && dtype <= SVt_PVGV) {
		    glob_assign_glob(dstr, sstr, dtype);
		    return;
		}
	    }
	}
	if (stype == SVt_PVLV)
	    (void)SvUPGRADE(dstr, SVt_PVNV);
	else
	    (void)SvUPGRADE(dstr, (svtype)stype);
    }

    /* dstr may have been upgraded.  */
    dtype = SvTYPE(dstr);
    sflags = SvFLAGS(sstr);

    if (sflags & SVf_ROK) {
	if (isGV_with_GP(dstr) && dtype == SVt_PVGV
	    && SvTYPE(SvRV(sstr)) == SVt_PVGV && isGV_with_GP(SvRV(sstr))) {
	    sstr = SvRV(sstr);
	    if (sstr == dstr) {
		if (GvIMPORTED(dstr) != GVf_IMPORTED
		    && CopSTASH_ne(PL_curcop, GvSTASH(dstr)))
		{
		    GvIMPORTED_on(dstr);
		}
		GvMULTI_on(dstr);
		return;
	    }
	    glob_assign_glob(dstr, sstr, dtype);
	    return;
	}

	if (dtype >= SVt_PV) {
	    if (dtype == SVt_PVGV && isGV_with_GP(dstr)) {
		glob_assign_ref(dstr, sstr);
		return;
	    }
	    if (SvPVX_const(dstr)) {
		SvPV_free(dstr);
		SvLEN_set(dstr, 0);
                SvCUR_set(dstr, 0);
	    }
	}
	(void)SvOK_off(dstr);
	SvRV_set(dstr, SvREFCNT_inc(SvRV(sstr)));
	SvFLAGS(dstr) |= sflags & (SVf_IOK|SVp_IOK|SVf_NOK|SVp_NOK|SVf_ROK
				   |SVf_AMAGIC);
	if (sflags & SVp_NOK) {
	    SvNV_set(dstr, SvNVX(sstr));
	}
	if (sflags & SVp_IOK) {
	    /* Must do this otherwise some other overloaded use of 0x80000000
	       gets confused. Probably SVprv_WEAKREF */
	    if (sflags & SVf_IVisUV)
		SvIsUV_on(dstr);
	    SvIV_set(dstr, SvIVX(sstr));
	}
    }
    else if (sflags & SVp_POK) {

	/*
	 * Check to see if we can just swipe the string.  If so, it's a
	 * possible small lose on short strings, but a big win on long ones.
	 * It might even be a win on short strings if SvPVX_const(dstr)
	 * has to be allocated and SvPVX_const(sstr) has to be freed.
	 */

	if (SvTEMP(sstr) &&		/* slated for free anyway? */
	    SvREFCNT(sstr) == 1 && 	/* and no other references to it? */
	    (!(flags & SV_NOSTEAL)) &&	/* and we're allowed to steal temps */
	    !(sflags & SVf_OOK) && 	/* and not involved in OOK hack? */
	    SvLEN(sstr) 	&&	/* and really is a string */
	    			/* and won't be needed again, potentially */
	    !(PL_op && PL_op->op_type == OP_AASSIGN))
	{
	    if (SvPVX_const(dstr)) {	/* we know that dtype >= SVt_PV */
		SvPV_free(dstr);
	    }
	    (void)SvPOK_only(dstr);
	    SvPV_set(dstr, SvPVX(sstr));
	    SvLEN_set(dstr, SvLEN(sstr));
	    SvCUR_set(dstr, SvCUR(sstr));

	    SvTEMP_off(dstr);
	    (void)SvOK_off(sstr);	/* NOTE: nukes most SvFLAGS on sstr */
	    SvPV_set(sstr, NULL);
	    SvLEN_set(sstr, 0);
	    SvCUR_set(sstr, 0);
	    SvTEMP_off(sstr);
	}
	else {				/* have to copy actual string */
	    STRLEN len = SvCUR(sstr);
	    SvGROW(dstr, len + 1);	/* inlined from sv_setpvn */
	    Move(SvPVX_const(sstr),SvPVX(dstr),len,char);
	    SvCUR_set(dstr, len);
	    *SvEND(dstr) = '\0';
	    (void)SvPOK_only(dstr);
	}
	if (sflags & SVp_NOK) {
	    SvNV_set(dstr, SvNVX(sstr));
	}
	if (sflags & SVp_IOK) {
	    SvOOK_off(dstr);
	    SvIV_set(dstr, SvIVX(sstr));
	    /* Must do this otherwise some other overloaded use of 0x80000000
	       gets confused. I guess SVpbm_VALID */
	    if (sflags & SVf_IVisUV)
		SvIsUV_on(dstr);
	}
	SvFLAGS(dstr) |= sflags & (SVf_IOK|SVp_IOK|SVf_NOK|SVp_NOK|SVf_UTF8);
	{
	    const MAGIC * const smg = SvVSTRING_mg(sstr);
	    if (smg) {
		sv_magic(dstr, NULL, PERL_MAGIC_vstring,
			 smg->mg_ptr, smg->mg_len);
		SvRMAGICAL_on(dstr);
	    }
	}
    }
    else if (sflags & (SVp_IOK|SVp_NOK)) {
	(void)SvOK_off(dstr);
	SvFLAGS(dstr) |= sflags & (SVf_IOK|SVp_IOK|SVf_IVisUV|SVf_NOK|SVp_NOK);
	if (sflags & SVp_IOK) {
	    /* XXXX Do we want to set IsUV for IV(ROK)?  Be extra safe... */
	    SvIV_set(dstr, SvIVX(sstr));
	}
	if (sflags & SVp_NOK) {
	    SvNV_set(dstr, SvNVX(sstr));
	}
    }
    else {
	if (dtype == SVt_PVGV) {
	    if (ckWARN(WARN_MISC))
		Perl_warner(aTHX_ packWARN(WARN_MISC), "Undefined value assigned to typeglob");
	}
	else
	    (void)SvOK_off(dstr);
    }
    if (SvTAINTED(sstr))
	SvTAINT(dstr);
}

/*
=for apidoc sv_setsv_mg

Like C<sv_setsv>, but also handles 'set' magic.

=cut
*/

void
Perl_sv_setsv_mg(pTHX_ SV *dstr, register SV *sstr)
{
    sv_setsv(dstr,sstr);
    SvSETMAGIC(dstr);
}

/*
=for apidoc sv_setpvn

Copies a string into an SV.  The C<len> parameter indicates the number of
bytes to be copied.  If the C<ptr> argument is NULL the SV will become
undefined.  Does not handle 'set' magic.  See C<sv_setpvn_mg>.

=cut
*/

void
Perl_sv_setpvn(pTHX_ register SV *sv, register const char *ptr, register STRLEN len)
{
    register char *dptr;

    SV_CHECK_THINKFIRST(sv);
    if (!ptr) {
	(void)SvOK_off(sv);
	return;
    }
    else {
        /* len is STRLEN which is unsigned, need to copy to signed */
	const IV iv = len;
	if (iv < 0)
	    Perl_croak(aTHX_ "panic: sv_setpvn called with negative strlen");
    }
    (void)SvUPGRADE(sv, SVt_PV);

    dptr = SvGROW(sv, len + 1);
    Move(ptr,dptr,len,char);
    dptr[len] = '\0';
    SvCUR_set(sv, len);
    (void)SvPOK_only_UTF8(sv);		/* validate pointer */
    SvTAINT(sv);
}

/*
=for apidoc sv_setpvn_mg

Like C<sv_setpvn>, but also handles 'set' magic.

=cut
*/

void
Perl_sv_setpvn_mg(pTHX_ register SV *sv, register const char *ptr, register STRLEN len)
{
    sv_setpvn(sv,ptr,len);
    SvSETMAGIC(sv);
}

/*
=for apidoc sv_setpv

Copies a string into an SV.  The string must be null-terminated.  Does not
handle 'set' magic.  See C<sv_setpv_mg>.

=cut
*/

void
Perl_sv_setpv(pTHX_ register SV *sv, register const char *ptr)
{
    register STRLEN len;

    SV_CHECK_THINKFIRST(sv);
    if (!ptr) {
	(void)SvOK_off(sv);
	return;
    }
    len = strlen(ptr);
    (void)SvUPGRADE(sv, SVt_PV);

    SvGROW(sv, len + 1);
    Move(ptr,SvPVX(sv),len+1,char);
    SvCUR_set(sv, len);
    (void)SvPOK_only_UTF8(sv);		/* validate pointer */
    SvTAINT(sv);
}

/*
=for apidoc sv_setpv_mg

Like C<sv_setpv>, but also handles 'set' magic.

=cut
*/

void
Perl_sv_setpv_mg(pTHX_ register SV *sv, register const char *ptr)
{
    sv_setpv(sv,ptr);
    SvSETMAGIC(sv);
}

/*
=for apidoc sv_usepvn_flags

Tells an SV to use C<ptr> to find its string value.  Normally the
string is stored inside the SV but sv_usepvn allows the SV to use an
outside string.  The C<ptr> should point to memory that was allocated
by C<malloc>.  The string length, C<len>, must be supplied.  By default
this function will realloc (i.e. move) the memory pointed to by C<ptr>,
so that pointer should not be freed or used by the programmer after
giving it to sv_usepvn, and neither should any pointers from "behind"
that pointer (e.g. ptr + 1) be used.

If C<flags> & SV_SMAGIC is true, will call SvSETMAGIC. If C<flags> &
SV_HAS_TRAILING_NUL is true, then C<ptr[len]> must be NUL, and the realloc
will be skipped. (i.e. the buffer is actually at least 1 byte longer than
C<len>, and already meets the requirements for storing in C<SvPVX>)

=cut
*/

void
Perl_sv_usepvn_flags(pTHX_ SV *sv, char *ptr, STRLEN len, U32 flags)
{
    STRLEN allocate;
    SV_CHECK_THINKFIRST(sv);
    (void)SvUPGRADE(sv, SVt_PV);
    if (!ptr) {
	(void)SvOK_off(sv);
	if (flags & SV_SMAGIC)
	    SvSETMAGIC(sv);
	return;
    }
    if (SvPVX_const(sv))
	SvPV_free(sv);

#ifdef DEBUGGING
    if (flags & SV_HAS_TRAILING_NUL)
	assert(ptr[len] == '\0');
#endif

    allocate = (flags & SV_HAS_TRAILING_NUL)
	? len + 1: PERL_STRLEN_ROUNDUP(len + 1);
    if (flags & SV_HAS_TRAILING_NUL) {
	/* It's long enough - do nothing.
	   Specfically Perl_newCONSTSUB is relying on this.  */
    } else {
	ptr = (char*) saferealloc (ptr, allocate);
    }
    SvPV_set(sv, ptr);
    SvCUR_set(sv, len);
    SvLEN_set(sv, allocate);
    if (!(flags & SV_HAS_TRAILING_NUL)) {
	ptr[len] = '\0';
    }
    (void)SvPOK_only_UTF8(sv);		/* validate pointer */
    SvTAINT(sv);
    if (flags & SV_SMAGIC)
	SvSETMAGIC(sv);
}

/*
=for apidoc sv_force_normal_flags

Undo various types of fakery on an SV: if the PV is a shared string, make
a private copy; if we're a ref, stop refing; if we're a glob, downgrade to
an xpvmg. The C<flags> parameter gets passed to  C<sv_unref_flags()>
when unrefing. C<sv_force_normal> calls this function with flags set to 0.

=cut
*/

void
Perl_sv_force_normal_flags(pTHX_ register SV *sv, U32 flags)
{
    if (SvREADONLY(sv)) {
	if (SvFAKE(sv)) {
	    const char * const pvx = SvPVX_const(sv);
	    const STRLEN len = SvCUR(sv);
	    const U32 hash = SvSHARED_HASH(sv);
	    SvFAKE_off(sv);
	    SvREADONLY_off(sv);
	    SvGROW(sv, len + 1);
	    Move(pvx,SvPVX(sv),len,char);
	    *SvEND(sv) = '\0';
	    unsharepvn(pvx, SvUTF8(sv) ? -(I32)len : (I32)len, hash);
	}
	else if (IN_PERL_RUNTIME)
	    Perl_croak(aTHX_ "%s", PL_no_modify);
    }
    if (SvROK(sv))
	sv_unref_flags(sv, flags);
    else if (SvFAKE(sv) && SvTYPE(sv) == SVt_PVGV)
	sv_unglob(sv);
}

/*
=for apidoc sv_chop

Efficient removal of characters from the beginning of the string buffer.
SvPOK(sv) must be true and the C<ptr> must be a pointer to somewhere inside
the string buffer.  The C<ptr> becomes the first character of the adjusted
string. Uses the "OOK hack".
Beware: after this function returns, C<ptr> and SvPVX_const(sv) may no longer
refer to the same chunk of data.

=cut
*/

void
Perl_sv_chop(pTHX_ register SV *sv, register char *ptr)
{
    register STRLEN delta;
    STRLEN max_delta;

    if (!ptr || !SvPOKp(sv))
	return;
    delta = ptr - SvPVX_const(sv);
    if (!delta) {
	/* Nothing to do.  */
	return;
    }
    /* SvPVX(sv) may move in SV_CHECK_THINKFIRST(sv), but after this line,
       nothing uses the value of ptr any more.  */
    max_delta = SvLEN(sv) ? SvLEN(sv) : SvCUR(sv);
    if (ptr <= SvPVX_const(sv))
	Perl_croak(aTHX_ "panic: sv_chop ptr=%p, start=%p, end=%p",
		   ptr, SvPVX_const(sv), SvPVX_const(sv) + max_delta);
    SV_CHECK_THINKFIRST(sv);

    if (SvTYPE(sv) < SVt_PVIV)
	sv_upgrade(sv,SVt_PVIV);

    if (delta > max_delta)
	Perl_croak(aTHX_ "panic: sv_chop ptr=%p (was %p), start=%p, end=%p",
		   SvPVX_const(sv) + delta, ptr, SvPVX_const(sv),
		   SvPVX_const(sv) + max_delta);


    if (!SvOOK(sv)) {
	if (!SvLEN(sv)) { /* make copy of shared string */
	    const char *pvx = SvPVX_const(sv);
	    const STRLEN len = SvCUR(sv);
	    SvGROW(sv, len + 1);
	    Move(pvx,SvPVX(sv),len,char);
	    *SvEND(sv) = '\0';
	}
	SvIV_set(sv, 0);
	/* Same SvOOK_on but SvOOK_on does a SvIOK_off
	   and we do that anyway inside the SvNIOK_off
	*/
	SvFLAGS(sv) |= SVf_OOK; 
    }
    SvNIOK_off(sv);
    SvLEN_set(sv, SvLEN(sv) - delta);
    SvCUR_set(sv, SvCUR(sv) - delta);
    SvPV_set(sv, SvPVX(sv) + delta);
    SvIV_set(sv, SvIVX(sv) + delta);
}

/*
=for apidoc sv_catpvn

Concatenates the string onto the end of the string which is in the SV.  The
C<len> indicates number of bytes to copy.  If the SV has the UTF-8
status set, then the bytes appended should be valid UTF-8.
Handles 'get' magic, but not 'set' magic.  See C<sv_catpvn_mg>.

=for apidoc sv_catpvn_flags

Concatenates the string onto the end of the string which is in the SV.  The
C<len> indicates number of bytes to copy.  If the SV has the UTF-8
status set, then the bytes appended should be valid UTF-8.
If C<flags> has C<SV_GMAGIC> bit set, will C<mg_get> on C<dsv> if
appropriate, else not. C<sv_catpvn> and C<sv_catpvn_nomg> are implemented
in terms of this function.

=cut
*/

void
Perl_sv_catpvn_flags(pTHX_ register SV *dsv, register const char *sstr, register STRLEN slen, I32 flags)
{
    STRLEN dlen;
    const char * const dstr = SvPV_force_flags(dsv, dlen, flags);

    SvGROW(dsv, dlen + slen + 1);
    if (sstr == dstr)
	sstr = SvPVX_const(dsv);
    Move(sstr, SvPVX(dsv) + dlen, slen, char);
    SvCUR_set(dsv, SvCUR(dsv) + slen);
    *SvEND(dsv) = '\0';
    (void)SvPOK_only_UTF8(dsv);		/* validate pointer */
    SvTAINT(dsv);
    if (flags & SV_SMAGIC)
	SvSETMAGIC(dsv);
}

/*
=for apidoc sv_catsv

Concatenates the string from SV C<ssv> onto the end of the string in
SV C<dsv>.  Modifies C<dsv> but not C<ssv>.  Handles 'get' magic, but
not 'set' magic.  See C<sv_catsv_mg>.

=for apidoc sv_catsv_flags

Concatenates the string from SV C<ssv> onto the end of the string in
SV C<dsv>.  Modifies C<dsv> but not C<ssv>.  If C<flags> has C<SV_GMAGIC>
bit set, will C<mg_get> on the SVs if appropriate, else not. C<sv_catsv>
and C<sv_catsv_nomg> are implemented in terms of this function.

=cut */

void
Perl_sv_catsv_flags(pTHX_ SV *dsv, register SV *ssv, I32 flags)
{
    if (ssv) {
	STRLEN slen;
	const char *spv = SvPV_const(ssv, slen);
	if (spv) {
	    /*  sutf8 and dutf8 were type bool, but under USE_ITHREADS,
		gcc version 2.95.2 20000220 (Debian GNU/Linux) for
		Linux xxx 2.2.17 on sparc64 with gcc -O2, we erroneously
		get dutf8 = 0x20000000, (i.e.  SVf_UTF8) even though
		dsv->sv_flags doesn't have that bit set.
		Andy Dougherty  12 Oct 2001
	    */
	    const I32 sutf8 = DO_UTF8(ssv);
	    I32 dutf8;

	    if (SvGMAGICAL(dsv) && (flags & SV_GMAGIC))
		mg_get(dsv);
	    dutf8 = DO_UTF8(dsv);

	    if (dutf8 != sutf8) {
		if (dutf8) {
		    /* Not modifying source SV, so taking a temporary copy. */
		    SV* const csv = newSVpvn_flags(spv, slen, SVs_TEMP);

		    sv_utf8_upgrade(csv);
		    spv = SvPV_const(csv, slen);
		}
		else
		    sv_utf8_upgrade_nomg(dsv);
	    }
	    sv_catpvn_nomg(dsv, spv, slen);
	}
    }
    if (flags & SV_SMAGIC)
	SvSETMAGIC(dsv);
}

/*
=for apidoc sv_catpv

Concatenates the string onto the end of the string which is in the SV.
If the SV has the UTF-8 status set, then the bytes appended should be
valid UTF-8.  Handles 'get' magic, but not 'set' magic.  See C<sv_catpv_mg>.

=cut */

void
Perl_sv_catpv(pTHX_ register SV *sv, register const char *ptr)
{
    register STRLEN len;
    STRLEN tlen;
    char *junk;

    if (!ptr)
	return;
    junk = SvPV_force(sv, tlen);
    len = strlen(ptr);
    SvGROW(sv, tlen + len + 1);
    if (ptr == junk)
	ptr = SvPVX_const(sv);
    Move(ptr,SvPVX(sv)+tlen,len+1,char);
    SvCUR_set(sv, SvCUR(sv) + len);
    (void)SvPOK_only_UTF8(sv);		/* validate pointer */
    SvTAINT(sv);
}

/*
=for apidoc sv_catpv_mg

Like C<sv_catpv>, but also handles 'set' magic.

=cut
*/

void
Perl_sv_catpv_mg(pTHX_ register SV *sv, register const char *ptr)
{
    sv_catpv(sv,ptr);
    SvSETMAGIC(sv);
}

/*
=for apidoc newSV

Creates a new SV.  A non-zero C<len> parameter indicates the number of
bytes of preallocated string space the SV should have.  An extra byte for a
trailing NUL is also reserved.  (SvPOK is not set for the SV even if string
space is allocated.)  The reference count for the new SV is set to 1.

In 5.9.3, newSV() replaces the older NEWSV() API, and drops the first
parameter, I<x>, a debug aid which allowed callers to identify themselves.
This aid has been superseded by a new build option, PERL_MEM_LOG (see
L<perlhack/PERL_MEM_LOG>).  The older API is still there for use in XS
modules supporting older perls.

=cut
*/

SV *
Perl_newSV(pTHX_ STRLEN len)
{
    register SV *sv;

    new_SV(sv);
    if (len) {
	sv_upgrade(sv, SVt_PV);
	SvGROW(sv, len + 1);
    }
    return sv;
}
/*
=for apidoc sv_magicext

Adds magic to an SV, upgrading it if necessary. Applies the
supplied vtable and returns a pointer to the magic added.

Note that C<sv_magicext> will allow things that C<sv_magic> will not.
In particular, you can add magic to SvREADONLY SVs, and add more than
one instance of the same 'how'.

If C<namlen> is greater than zero then a C<savepvn> I<copy> of C<name> is
stored, if C<namlen> is zero then C<name> is stored as-is and - as another
special case - if C<(name && namlen == HEf_SVKEY)> then C<name> is assumed
to contain an C<SV*> and is stored as-is with its REFCNT incremented.

(This is now used as a subroutine by C<sv_magic>.)

=cut
*/
MAGIC *	
Perl_sv_magicext(pTHX_ SV* sv, SV* obj, int how, MGVTBL *vtable,
		 const char* name, I32 namlen)
{
    MAGIC* mg;

    (void)SvUPGRADE(sv, SVt_PVMG);
    Newxz(mg, 1, MAGIC);
    mg->mg_moremagic = SvMAGIC(sv);
    SvMAGIC_set(sv, mg);

    /* Sometimes a magic contains a reference loop, where the sv and
       object refer to each other.  To prevent a reference loop that
       would prevent such objects being freed, we look for such loops
       and if we find one we avoid incrementing the object refcount.

       Note we cannot do this to avoid self-tie loops as intervening RV must
       have its REFCNT incremented to keep it in existence.

    */
    if (!obj || obj == sv ||
	how == PERL_MAGIC_arylen ||
	how == PERL_MAGIC_qr ||
	(SvTYPE(obj) == SVt_PVGV &&
	    (GvSV(obj) == sv || GvHV(obj) == (HV*)sv || GvAV(obj) == (AV*)sv ||
	    GvCV(obj) == (CV*)sv || GvIOp(obj) == (IO*)sv ||
	    GvFORM(obj) == (CV*)sv)))
    {
	mg->mg_obj = obj;
    }
    else {
	mg->mg_obj = SvREFCNT_inc_simple(obj);
	mg->mg_flags |= MGf_REFCOUNTED;
    }

    /* Normal self-ties simply pass a null object, and instead of
       using mg_obj directly, use the SvTIED_obj macro to produce a
       new RV as needed.  For glob "self-ties", we are tieing the PVIO
       with an RV obj pointing to the glob containing the PVIO.  In
       this case, to avoid a reference loop, we need to weaken the
       reference.
    */

    if (how == PERL_MAGIC_tiedscalar && SvTYPE(sv) == SVt_PVIO &&
        obj && SvROK(obj) && GvIO(SvRV(obj)) == (IO*)sv)
    {
      sv_rvweaken(obj);
    }

    mg->mg_type = how;
    mg->mg_len = namlen;
    if (name) {
	if (namlen > 0)
	    mg->mg_ptr = savepvn(name, namlen);
	else if (namlen == HEf_SVKEY)
	    mg->mg_ptr = (char*)SvREFCNT_inc_simple_NN((SV*)name);
	else
	    mg->mg_ptr = (char *) name;
    }
    mg->mg_virtual = vtable;

    mg_magical(sv);
    if (SvGMAGICAL(sv))
	SvFLAGS(sv) &= ~(SVf_IOK|SVf_NOK|SVf_POK);
    return mg;
}

/*
=for apidoc sv_magic

Adds magic to an SV. First upgrades C<sv> to type C<SVt_PVMG> if necessary,
then adds a new magic item of type C<how> to the head of the magic list.

See C<sv_magicext> (which C<sv_magic> now calls) for a description of the
handling of the C<name> and C<namlen> arguments.

You need to use C<sv_magicext> to add magic to SvREADONLY SVs and also
to add more than one instance of the same 'how'.

=cut
*/

void
Perl_sv_magic(pTHX_ register SV *sv, SV *obj, int how, const char *name, I32 namlen)
{
    MGVTBL *vtable;
    MAGIC* mg;

    if (SvREADONLY(sv)) {
	if (
	    /* its okay to attach magic to shared strings; the subsequent
	     * upgrade to PVMG will unshare the string */
	    !(SvFAKE(sv) && SvTYPE(sv) < SVt_PVMG)

	    && IN_PERL_RUNTIME
	    && how != PERL_MAGIC_regex_global
	    && how != PERL_MAGIC_bm
	    && how != PERL_MAGIC_fm
	    && how != PERL_MAGIC_sv
	    && how != PERL_MAGIC_backref
	   )
	{
	    Perl_croak(aTHX_ "%s", PL_no_modify);
	}
    }
    if (SvMAGICAL(sv) || (how == PERL_MAGIC_taint && SvTYPE(sv) >= SVt_PVMG)) {
	if (SvMAGIC(sv) && (mg = mg_find(sv, how))) {
	    /* sv_magic() refuses to add a magic of the same 'how' as an
	       existing one
	     */
	    if (how == PERL_MAGIC_taint) {
		mg->mg_len |= 1;
		/* Any scalar which already had taint magic on which someone
		   (erroneously?) did SvIOK_on() or similar will now be
		   incorrectly sporting public "OK" flags.  */
		SvFLAGS(sv) &= ~(SVf_IOK|SVf_NOK|SVf_POK);
	    }
	    return;
	}
    }

    switch (how) {
    case PERL_MAGIC_sv:
	vtable = &PL_vtbl_sv;
	break;
    case PERL_MAGIC_overload:
        vtable = &PL_vtbl_amagic;
        break;
    case PERL_MAGIC_overload_elem:
        vtable = &PL_vtbl_amagicelem;
        break;
    case PERL_MAGIC_overload_table:
        vtable = &PL_vtbl_ovrld;
        break;
    case PERL_MAGIC_bm:
	vtable = &PL_vtbl_bm;
	break;
    case PERL_MAGIC_regdata:
	vtable = &PL_vtbl_regdata;
	break;
    case PERL_MAGIC_regdatum:
	vtable = &PL_vtbl_regdatum;
	break;
    case PERL_MAGIC_env:
	vtable = &PL_vtbl_env;
	break;
    case PERL_MAGIC_fm:
	vtable = &PL_vtbl_fm;
	break;
    case PERL_MAGIC_envelem:
	vtable = &PL_vtbl_envelem;
	break;
    case PERL_MAGIC_regex_global:
	vtable = &PL_vtbl_mglob;
	break;
    case PERL_MAGIC_isa:
	vtable = &PL_vtbl_isa;
	break;
    case PERL_MAGIC_isaelem:
	vtable = &PL_vtbl_isaelem;
	break;
    case PERL_MAGIC_nkeys:
	vtable = &PL_vtbl_nkeys;
	break;
    case PERL_MAGIC_dbfile:
	vtable = NULL;
	break;
    case PERL_MAGIC_dbline:
	vtable = &PL_vtbl_dbline;
	break;
#ifdef USE_5005THREADS
    case PERL_MAGIC_mutex:
	vtable = &PL_vtbl_mutex;
	break;
#endif /* USE_5005THREADS */
#ifdef USE_LOCALE_COLLATE
    case PERL_MAGIC_collxfrm:
        vtable = &PL_vtbl_collxfrm;
        break;
#endif /* USE_LOCALE_COLLATE */
    case PERL_MAGIC_tied:
	vtable = &PL_vtbl_pack;
	break;
    case PERL_MAGIC_tiedelem:
    case PERL_MAGIC_tiedscalar:
	vtable = &PL_vtbl_packelem;
	break;
    case PERL_MAGIC_qr:
	vtable = &PL_vtbl_regexp;
	break;
    case PERL_MAGIC_sig:
	vtable = &PL_vtbl_sig;
	break;
    case PERL_MAGIC_sigelem:
	vtable = &PL_vtbl_sigelem;
	break;
    case PERL_MAGIC_taint:
	vtable = &PL_vtbl_taint;
	break;
    case PERL_MAGIC_uvar:
	vtable = &PL_vtbl_uvar;
	break;
    case PERL_MAGIC_vec:
	vtable = &PL_vtbl_vec;
	break;
    case PERL_MAGIC_vstring:
	vtable = NULL;
	break;
    case PERL_MAGIC_utf8:
        vtable = &PL_vtbl_utf8;
        break;
    case PERL_MAGIC_substr:
	vtable = &PL_vtbl_substr;
	break;
    case PERL_MAGIC_defelem:
	vtable = &PL_vtbl_defelem;
	break;
    case PERL_MAGIC_glob:
	vtable = &PL_vtbl_glob;
	break;
    case PERL_MAGIC_arylen:
	vtable = &PL_vtbl_arylen;
	break;
    case PERL_MAGIC_pos:
	vtable = &PL_vtbl_pos;
	break;
    case PERL_MAGIC_backref:
	vtable = &PL_vtbl_backref;
	break;
    case PERL_MAGIC_ext:
	/* Reserved for use by extensions not perl internals.	        */
	/* Useful for attaching extension internal data to perl vars.	*/
	/* Note that multiple extensions may clash if magical scalars	*/
	/* etc holding private data from one are passed to another.	*/
	vtable = NULL;
	break;
    default:
	Perl_croak(aTHX_ "Don't know how to handle magic of type \\%o", how);
    }

    /* Rest of work is done else where */
    mg = sv_magicext(sv,obj,how,(MGVTBL*)vtable,name,namlen);

    switch (how) {
    case PERL_MAGIC_taint:
	mg->mg_len = 1;
	break;
    case PERL_MAGIC_ext:
    case PERL_MAGIC_dbfile:
	SvRMAGICAL_on(sv);
	break;
    }
}

/*
=for apidoc sv_unmagic

Removes all magic of type C<type> from an SV.

=cut
*/

int
Perl_sv_unmagic(pTHX_ SV *sv, int type)
{
    MAGIC* mg;
    MAGIC** mgp;
    if (SvTYPE(sv) < SVt_PVMG || !SvMAGIC(sv))
	return 0;
    mgp = &SvMAGIC(sv);
    for (mg = *mgp; mg; mg = *mgp) {
	if (mg->mg_type == type) {
            const MGVTBL* const vtbl = mg->mg_virtual;
	    *mgp = mg->mg_moremagic;
	    if (vtbl && vtbl->svt_free)
		CALL_FPTR(vtbl->svt_free)(aTHX_ sv, mg);
	    if (mg->mg_ptr && mg->mg_type != PERL_MAGIC_regex_global) {
		if (mg->mg_len > 0)
		    Safefree(mg->mg_ptr);
		else if (mg->mg_len == HEf_SVKEY)
		    SvREFCNT_dec((SV*)mg->mg_ptr);
		else if (mg->mg_type == PERL_MAGIC_utf8)
		    Safefree(mg->mg_ptr);
            }
	    if (mg->mg_flags & MGf_REFCOUNTED)
		SvREFCNT_dec(mg->mg_obj);
	    Safefree(mg);
	}
	else
	    mgp = &mg->mg_moremagic;
    }
    if (!SvMAGIC(sv)) {
	SvMAGICAL_off(sv);
	SvFLAGS(sv) |= (SvFLAGS(sv) & (SVp_IOK|SVp_NOK|SVp_POK)) >> PRIVSHIFT;
    }

    return 0;
}

/*
=for apidoc sv_rvweaken

Weaken a reference: set the C<SvWEAKREF> flag on this RV; give the
referred-to SV C<PERL_MAGIC_backref> magic if it hasn't already; and
push a back-reference to this RV onto the array of backreferences
associated with that magic.

=cut
*/

SV *
Perl_sv_rvweaken(pTHX_ SV *sv)
{
    SV *tsv;
    if (!SvOK(sv))  /* let undefs pass */
	return sv;
    if (!SvROK(sv))
	Perl_croak(aTHX_ "Can't weaken a nonreference");
    else if (SvWEAKREF(sv)) {
	if (ckWARN(WARN_MISC))
	    Perl_warner(aTHX_ packWARN(WARN_MISC), "Reference is already weak");
	return sv;
    }
    tsv = SvRV(sv);
    sv_add_backref(tsv, sv);
    SvWEAKREF_on(sv);
    SvREFCNT_dec(tsv);
    return sv;
}

/* Give tsv backref magic if it hasn't already got it, then push a
 * back-reference to sv onto the array associated with the backref magic.
 */

STATIC void
S_sv_add_backref(pTHX_ SV *tsv, SV *sv)
{
    AV *av;
    MAGIC *mg;
    if (SvMAGICAL(tsv) && (mg = mg_find(tsv, PERL_MAGIC_backref)))
	av = (AV*)mg->mg_obj;
    else {
	av = newAV();
	AvREAL_off(av);
	sv_magic(tsv, (SV*)av, PERL_MAGIC_backref, NULL, 0);
	/* av now has a refcnt of 2, which avoids it getting freed
	 * before us during global cleanup. The extra ref is removed
	 * by magic_killbackrefs() when tsv is being freed */
    }
    if (AvFILLp(av) >= AvMAX(av)) {
        av_extend(av, AvFILLp(av)+1);
    }
    AvARRAY(av)[++AvFILLp(av)] = sv; /* av_push() */
}

/* delete a back-reference to ourselves from the backref magic associated
 * with the SV we point to.
 */

STATIC void
S_sv_del_backref(pTHX_ SV *sv)
{
    AV *av;
    SV **svp;
    I32 i;
    SV * const tsv = SvRV(sv);
    MAGIC *mg = NULL;
    if (!SvMAGICAL(tsv) || !(mg = mg_find(tsv, PERL_MAGIC_backref)))
	Perl_croak(aTHX_ "panic: del_backref");
    av = (AV *)mg->mg_obj;
    svp = AvARRAY(av);
    /* We shouldn't be in here more than once, but for paranoia reasons lets
       not assume this.  */
    for (i = AvFILLp(av); i >= 0; i--) {
	if (svp[i] == sv) {
	    const SSize_t fill = AvFILLp(av);
	    if (i != fill) {
		/* We weren't the last entry.
		   An unordered list has this property that you can take the
		   last element off the end to fill the hole, and it's still
		   an unordered list :-)
		*/
		svp[i] = svp[fill];
	    }
	    svp[fill] = NULL;
	    AvFILLp(av) = fill - 1;
	}
    }
}

/*
=for apidoc sv_insert

Inserts a string at the specified offset/length within the SV. Similar to
the Perl substr() function.

=cut
*/

void
Perl_sv_insert(pTHX_ SV *bigstr, STRLEN offset, STRLEN len, char *little, STRLEN littlelen)
{
    register char *big;
    register char *mid;
    register char *midend;
    register char *bigend;
    register I32 i;
    STRLEN curlen;


    if (!bigstr)
	Perl_croak(aTHX_ "Can't modify non-existent substring");
    SvPV_force(bigstr, curlen);
    (void)SvPOK_only_UTF8(bigstr);
    if (offset + len > curlen) {
	SvGROW(bigstr, offset+len+1);
	Zero(SvPVX(bigstr)+curlen, offset+len-curlen, char);
	SvCUR_set(bigstr, offset+len);
    }

    SvTAINT(bigstr);
    i = littlelen - len;
    if (i > 0) {			/* string might grow */
	big = SvGROW(bigstr, SvCUR(bigstr) + i + 1);
	mid = big + offset + len;
	midend = bigend = big + SvCUR(bigstr);
	bigend += i;
	*bigend = '\0';
	while (midend > mid)		/* shove everything down */
	    *--bigend = *--midend;
	Move(little,big+offset,littlelen,char);
	SvCUR_set(bigstr, SvCUR(bigstr) + i);
	SvSETMAGIC(bigstr);
	return;
    }
    else if (i == 0) {
	Move(little,SvPVX(bigstr)+offset,len,char);
	SvSETMAGIC(bigstr);
	return;
    }

    big = SvPVX(bigstr);
    mid = big + offset;
    midend = mid + len;
    bigend = big + SvCUR(bigstr);

    if (midend > bigend)
	Perl_croak(aTHX_ "panic: sv_insert");

    if (mid - big > bigend - midend) {	/* faster to shorten from end */
	if (littlelen) {
	    Move(little, mid, littlelen,char);
	    mid += littlelen;
	}
	i = bigend - midend;
	if (i > 0) {
	    Move(midend, mid, i,char);
	    mid += i;
	}
	*mid = '\0';
	SvCUR_set(bigstr, mid - big);
    }
    else if ((i = mid - big)) {	/* faster from front */
	midend -= littlelen;
	mid = midend;
	Move(big, midend - i, i, char);
	sv_chop(bigstr,midend-i);
	if (littlelen)
	    Move(little, mid, littlelen,char);
    }
    else if (littlelen) {
	midend -= littlelen;
	sv_chop(bigstr,midend);
	Move(little,midend,littlelen,char);
    }
    else {
	sv_chop(bigstr,midend);
    }
    SvSETMAGIC(bigstr);
}

/*
=for apidoc sv_replace

Make the first argument a copy of the second, then delete the original.
The target SV physically takes over ownership of the body of the source SV
and inherits its flags; however, the target keeps any magic it owns,
and any magic in the source is discarded.
Note that this is a rather specialist SV copying operation; most of the
time you'll want to use C<sv_setsv> or one of its many macro front-ends.

=cut
*/

void
Perl_sv_replace(pTHX_ register SV *sv, register SV *nsv)
{
    const U32 refcnt = SvREFCNT(sv);
    SV_CHECK_THINKFIRST(sv);
    if (SvREFCNT(nsv) != 1 && ckWARN_d(WARN_INTERNAL))
	Perl_warner(aTHX_ packWARN(WARN_INTERNAL), "Reference miscount in sv_replace()");
    if (SvMAGICAL(sv)) {
	if (SvMAGICAL(nsv))
	    mg_free(nsv);
	else
	    sv_upgrade(nsv, SVt_PVMG);
	SvMAGIC_set(nsv, SvMAGIC(sv));
	SvFLAGS(nsv) |= SvMAGICAL(sv);
	SvMAGICAL_off(sv);
	SvMAGIC_set(sv, NULL);
    }
    SvREFCNT(sv) = 0;
    sv_clear(sv);
    assert(!SvREFCNT(sv));
    StructCopy(nsv,sv,SV);
    SvREFCNT(sv) = refcnt;
    SvFLAGS(nsv) |= SVTYPEMASK;		/* Mark as freed */
    SvREFCNT(nsv) = 0;
    del_SV(nsv);
}

/*
=for apidoc sv_clear

Clear an SV: call any destructors, free up any memory used by the body,
and free the body itself. The SV's head is I<not> freed, although
its type is set to all 1's so that it won't inadvertently be assumed
to be live during global destruction etc.
This function should only be called when REFCNT is zero. Most of the time
you'll want to call C<sv_free()> (or its macro wrapper C<SvREFCNT_dec>)
instead.

=cut
*/

void
Perl_sv_clear(pTHX_ register SV *sv)
{
    HV* stash;
    const U32 type = SvTYPE(sv);
    const struct body_details *const sv_type_details
	= bodies_by_type + type;

    assert(sv);
    assert(SvREFCNT(sv) == 0);

    if (type < SVt_IV) {
	return;
    }

    if (SvOBJECT(sv)) {
	if (PL_defstash &&	/* Still have a symbol table? */
	    SvDESTROYABLE(sv))
	{
	    dSP;
	    do {	
		CV* destructor;
		stash = SvSTASH(sv);
		destructor = StashHANDLER(stash,DESTROY);
		if (destructor) {
		    SV* const tmpref = newRV(sv);
	            SvREADONLY_on(tmpref);   /* DESTROY() could be naughty */
		    ENTER;
		    PUSHSTACKi(PERLSI_DESTROY);
		    EXTEND(SP, 2);
		    PUSHMARK(SP);
		    PUSHs(tmpref);
		    PUTBACK;
		    call_sv((SV*)destructor, G_DISCARD|G_EVAL|G_KEEPERR|G_VOID);
		   
		    
		    POPSTACK;
		    SPAGAIN;
		    LEAVE;
		    if(SvREFCNT(tmpref) < 2) {
		        /* tmpref is not kept alive! */
		        SvREFCNT(sv)--;
			SvRV_set(tmpref, NULL);
			SvROK_off(tmpref);
		    }
		    SvREFCNT_dec(tmpref);
		}
	    } while (SvOBJECT(sv) && SvSTASH(sv) != stash);


	    if (SvREFCNT(sv)) {
		if (PL_in_clean_objs)
		    Perl_croak(aTHX_ "DESTROY created new reference to dead object '%s'",
			  HvNAME_get(stash));
		/* DESTROY gave object new lease on life */
		return;
	    }
	}

	if (SvOBJECT(sv)) {
	    SvREFCNT_dec(SvSTASH(sv));	/* possibly of changed persuasion */
	    SvOBJECT_off(sv);	/* Curse the object. */
	    if (type != SVt_PVIO)
		--PL_sv_objcount;	/* XXX Might want something more general */
	}
    }
    if (type >= SVt_PVMG) {
    	if (SvMAGIC(sv))
	    mg_free(sv);
	if (type == SVt_PVMG && SvPAD_TYPED(sv))
	    SvREFCNT_dec(SvSTASH(sv));
    }
    stash = NULL;
    switch (type) {
    case SVt_PVIO:
	if (IoIFP(sv) &&
	    IoIFP(sv) != PerlIO_stdin() &&
	    IoIFP(sv) != PerlIO_stdout() &&
	    IoIFP(sv) != PerlIO_stderr())
	{
	    io_close((IO*)sv, FALSE);
	}
	if (IoDIRP(sv) && !(IoFLAGS(sv) & IOf_FAKE_DIRP))
	    PerlDir_close(IoDIRP(sv));
	IoDIRP(sv) = (DIR*)NULL;
	Safefree(IoTOP_NAME(sv));
	Safefree(IoFMT_NAME(sv));
	Safefree(IoBOTTOM_NAME(sv));
	goto freescalar;
    case SVt_PVBM:
	goto freescalar;
    case SVt_PVCV:
    case SVt_PVFM:
	cv_undef((CV*)sv);
	goto freescalar;
    case SVt_PVHV:
	if (PL_last_swash_hv == (HV*)sv) {
	    PL_last_swash_hv = NULL;
	}
	hv_undef((HV*)sv);
	break;
    case SVt_PVAV:
	if (PL_comppad == (AV*)sv) {
	    PL_comppad = NULL;
	    PL_curpad = NULL;
	}
	av_undef((AV*)sv);
	break;
    case SVt_PVLV:
	if (LvTYPE(sv) == 'T') { /* for tie: return HE to pool */
	    SvREFCNT_dec(HeKEY_sv((HE*)LvTARG(sv)));
	    HeNEXT((HE*)LvTARG(sv)) = PL_hv_fetch_ent_mh;
	    PL_hv_fetch_ent_mh = (HE*)LvTARG(sv);
	}
	else if (LvTYPE(sv) != 't') /* unless tie: unrefcnted fake SV**  */
	    SvREFCNT_dec(LvTARG(sv));
	goto freescalar;
    case SVt_PVGV:
	gp_free((GV*)sv);
	Safefree(GvNAME(sv));
	/* cannot decrease stash refcount yet, as we might recursively delete
	   ourselves when the refcnt drops to zero. Delay SvREFCNT_dec
	   of stash until current sv is completely gone.
	   -- JohnPC, 27 Mar 1998 */
	stash = GvSTASH(sv);
	/* FIXME. There are probably more unreferenced pointers to SVs in the
	   interpreter struct that we should check and tidy in a similar
	   fashion to this:  */
	if ((GV*)sv == PL_last_in_gv)
	    PL_last_in_gv = NULL;
    case SVt_PVMG:
    case SVt_PVNV:
    case SVt_PVIV:
      freescalar:
	/* Don't bother with SvOOK_off(sv); as we're only going to free it.  */
	if (SvOOK(sv)) {
	    SvPV_set(sv, SvPVX_mutable(sv) - SvIVX(sv));
	    /* Don't even bother with turning off the OOK flag.  */
	}
    case SVt_PV:
    case SVt_RV:
	if (SvROK(sv)) {
	    if (SvWEAKREF(sv))
	        sv_del_backref(sv);
	    else
	        SvREFCNT_dec(SvRV(sv));
	}
	else if (SvPVX_const(sv) && SvLEN(sv))
	    Safefree(SvPVX_mutable(sv));
	else if (SvPVX_const(sv) && SvREADONLY(sv) && SvFAKE(sv)) {
	    unsharepvn(SvPVX_const(sv),
		       SvUTF8(sv) ? -(I32)SvCUR(sv) : (I32)SvCUR(sv),
		       SvUVX(sv));
	    SvFAKE_off(sv);
	}
	break;
    case SVt_NV:
    case SVt_IV:
	break;
    }

    SvFLAGS(sv) &= SVf_BREAK;
    SvFLAGS(sv) |= SVTYPEMASK;

    if (sv_type_details->arena) {
	del_body(((char *)SvANY(sv) + sv_type_details->offset),
		 &PL_body_roots[type]);
    }
    else if (sv_type_details->body_size) {
	my_safefree(SvANY(sv));
    }

    /* decrease refcount of the stash that owns this GV, if any */
    if (stash)
	SvREFCNT_dec(stash);
    return;
}

/*
=for apidoc sv_newref

Increment an SV's reference count. Use the C<SvREFCNT_inc()> wrapper
instead.

=cut
*/

SV *
Perl_sv_newref(pTHX_ SV *sv)
{
    PERL_UNUSED_CONTEXT;
    if (sv)
	ATOMIC_INC(SvREFCNT(sv));
    return sv;
}

/*
=for apidoc sv_free

Decrement an SV's reference count, and if it drops to zero, call
C<sv_clear> to invoke destructors and free up any memory used by
the body; finally, deallocate the SV's head itself.
Normally called via a wrapper macro C<SvREFCNT_dec>.

=cut
*/

void
Perl_sv_free(pTHX_ SV *sv)
{
    int refcount_is_zero;

    if (!sv)
	return;
    if (SvREFCNT(sv) == 0) {
	if (SvFLAGS(sv) & SVf_BREAK)
	    /* this SV's refcnt has been artificially decremented to
	     * trigger cleanup */
	    return;
	if (PL_in_clean_all) /* All is fair */
	    return;
	if (SvREADONLY(sv) && SvIMMORTAL(sv)) {
	    /* make sure SvREFCNT(sv)==0 happens very seldom */
	    SvREFCNT(sv) = (~(U32)0)/2;
	    return;
	}
	if (ckWARN_d(WARN_INTERNAL)) {
	    Perl_warner(aTHX_ packWARN(WARN_INTERNAL),
                        "Attempt to free unreferenced scalar: SV 0x%"UVxf
                        pTHX__FORMAT, PTR2UV(sv) pTHX__VALUE);
#ifdef DEBUG_LEAKING_SCALARS_FORK_DUMP
	    Perl_dump_sv_child(aTHX_ sv);
#endif
	}
	return;
    }
    ATOMIC_DEC_AND_TEST(refcount_is_zero, SvREFCNT(sv));
    if (!refcount_is_zero)
	return;
#ifdef DEBUGGING
    if (SvTEMP(sv)) {
	if (ckWARN_d(WARN_DEBUGGING))
	    Perl_warner(aTHX_ packWARN(WARN_DEBUGGING),
			"Attempt to free temp prematurely: SV 0x%"UVxf
                        pTHX__FORMAT, PTR2UV(sv) pTHX__VALUE);
	return;
    }
#endif
    if (SvREADONLY(sv) && SvIMMORTAL(sv)) {
	/* make sure SvREFCNT(sv)==0 happens very seldom */
	SvREFCNT(sv) = (~(U32)0)/2;
	return;
    }
    sv_clear(sv);
    if (! SvREFCNT(sv))
	del_SV(sv);
}

/*
=for apidoc sv_len

Returns the length of the string in the SV. Handles magic and type
coercion.  See also C<SvCUR>, which gives raw access to the xpv_cur slot.

=cut
*/

STRLEN
Perl_sv_len(pTHX_ register SV *sv)
{
    STRLEN len;

    if (!sv)
	return 0;

    if (SvGMAGICAL(sv))
	len = mg_length(sv);
    else
        (void)SvPV_const(sv, len);
    return len;
}

/*
=for apidoc sv_len_utf8

Returns the number of characters in the string in an SV, counting wide
UTF-8 bytes as a single character. Handles magic and type coercion.

=cut
*/

/*
 * The length is cached in PERL_UTF8_magic, in the mg_len field.  Also the
 * mg_ptr is used, by sv_pos_u2b() and sv_pos_b2u() - see the comments below.
 * (Note that the mg_len is not the length of the mg_ptr field.
 * This allows the cache to store the character length of the string without
 * needing to malloc() extra storage to attach to the mg_ptr.)
 *
 */

STRLEN
Perl_sv_len_utf8(pTHX_ register SV *sv)
{
    if (!sv)
	return 0;

    if (SvGMAGICAL(sv))
	return mg_length(sv);
    else
    {
	STRLEN len;
	const U8 *s = (U8*)SvPV_const(sv, len);

	if (PL_utf8cache) {
	    STRLEN ulen;
	    MAGIC *mg = SvMAGICAL(sv) ? mg_find(sv, PERL_MAGIC_utf8) : NULL;

	    if (mg && mg->mg_len != -1) {
		ulen = mg->mg_len;
		if (PL_utf8cache < 0) {
		    const STRLEN real = Perl_utf8_length(aTHX_ (U8 *)s,
							 (U8 *)s + len);
		    if (real != ulen) {
			/* Need to turn the assertions off otherwise we may
			   recurse infinitely while printing error messages.
			*/
			SAVEI8(PL_utf8cache);
			PL_utf8cache = 0;
			Perl_croak(aTHX_ "panic: sv_len_utf8 cache %"UVuf
				   " real %"UVuf" for %"SVf,
				   (UV) ulen, (UV) real, (void*)sv);
		    }
		}
	    }
	    else {
		ulen = Perl_utf8_length(aTHX_ (U8 *)s, (U8 *)s + len);
		if (!SvREADONLY(sv)) {
		    if (!mg) {
			mg = sv_magicext(sv, 0, PERL_MAGIC_utf8,
					 &PL_vtbl_utf8, 0, 0);
		    }
		    assert(mg);
		    mg->mg_len = ulen;
		}
	    }
	    return ulen;
	}
	return Perl_utf8_length(aTHX_ (U8 *)s, (U8 *)s + len);
    }
}

/* Walk forwards to find the byte corresponding to the passed in UTF-8
   offset.  */
static STRLEN
S_sv_pos_u2b_forwards(const U8 *const start, const U8 *const send,
		      STRLEN uoffset)
{
    const U8 *s = start;

    while (s < send && uoffset--)
	s += UTF8SKIP(s);
    if (s > send) {
	/* This is the existing behaviour. Possibly it should be a croak, as
	   it's actually a bounds error  */
	s = send;
    }
    return s - start;
}

/* Given the length of the string in both bytes and UTF-8 characters, decide
   whether to walk forwards or backwards to find the byte corresponding to
   the passed in UTF-8 offset.  */
static STRLEN
S_sv_pos_u2b_midway(const U8 *const start, const U8 *send,
		      STRLEN uoffset, STRLEN uend)
{
    STRLEN backw = uend - uoffset;
    if (uoffset < 2 * backw) {
	/* The assumption is that going forwards is twice the speed of going
	   forward (that's where the 2 * backw comes from).
	   (The real figure of course depends on the UTF-8 data.)  */
	return sv_pos_u2b_forwards(start, send, uoffset);
    }

    while (backw--) {
	send--;
	while (UTF8_IS_CONTINUATION(*send))
	    send--;
    }
    return send - start;
}

/* For the string representation of the given scalar, find the byte
   corresponding to the passed in UTF-8 offset.  uoffset0 and boffset0
   give another position in the string, *before* the sought offset, which
   (which is always true, as 0, 0 is a valid pair of positions), which should
   help reduce the amount of linear searching.
   If *mgp is non-NULL, it should point to the UTF-8 cache magic, which
   will be used to reduce the amount of linear searching. The cache will be
   created if necessary, and the found value offered to it for update.  */
static STRLEN
S_sv_pos_u2b_cached(pTHX_ SV *sv, MAGIC **mgp, const U8 *const start,
		    const U8 *const send, STRLEN uoffset,
		    STRLEN uoffset0, STRLEN boffset0) {
    STRLEN boffset = 0; /* Actually always set, but let's keep gcc happy.  */
    bool found = FALSE;

    assert (uoffset >= uoffset0);

    if (SvMAGICAL(sv) && !SvREADONLY(sv) && PL_utf8cache
	&& (*mgp || (*mgp = mg_find(sv, PERL_MAGIC_utf8)))) {
	if ((*mgp)->mg_ptr) {
	    STRLEN *cache = (STRLEN *) (*mgp)->mg_ptr;
	    if (cache[0] == uoffset) {
		/* An exact match. */
		return cache[1];
	    }
	    if (cache[2] == uoffset) {
		/* An exact match. */
		return cache[3];
	    }

	    if (cache[0] < uoffset) {
		/* The cache already knows part of the way.   */
		if (cache[0] > uoffset0) {
		    /* The cache knows more than the passed in pair  */
		    uoffset0 = cache[0];
		    boffset0 = cache[1];
		}
		if ((*mgp)->mg_len != -1) {
		    /* And we know the end too.  */
		    boffset = boffset0
			+ sv_pos_u2b_midway(start + boffset0, send,
					      uoffset - uoffset0,
					      (*mgp)->mg_len - uoffset0);
		} else {
		    boffset = boffset0
			+ sv_pos_u2b_forwards(start + boffset0,
						send, uoffset - uoffset0);
		}
	    }
	    else if (cache[2] < uoffset) {
		/* We're between the two cache entries.  */
		if (cache[2] > uoffset0) {
		    /* and the cache knows more than the passed in pair  */
		    uoffset0 = cache[2];
		    boffset0 = cache[3];
		}

		boffset = boffset0
		    + sv_pos_u2b_midway(start + boffset0,
					  start + cache[1],
					  uoffset - uoffset0,
					  cache[0] - uoffset0);
	    } else {
		boffset = boffset0
		    + sv_pos_u2b_midway(start + boffset0,
					  start + cache[3],
					  uoffset - uoffset0,
					  cache[2] - uoffset0);
	    }
	    found = TRUE;
	}
	else if ((*mgp)->mg_len != -1) {
	    /* If we can take advantage of a passed in offset, do so.  */
	    /* In fact, offset0 is either 0, or less than offset, so don't
	       need to worry about the other possibility.  */
	    boffset = boffset0
		+ sv_pos_u2b_midway(start + boffset0, send,
				      uoffset - uoffset0,
				      (*mgp)->mg_len - uoffset0);
	    found = TRUE;
	}
    }

    if (!found || PL_utf8cache < 0) {
	const STRLEN real_boffset
	    = boffset0 + sv_pos_u2b_forwards(start + boffset0,
					       send, uoffset - uoffset0);

	if (found && PL_utf8cache < 0) {
	    if (real_boffset != boffset) {
		/* Need to turn the assertions off otherwise we may recurse
		   infinitely while printing error messages.  */
		SAVEI8(PL_utf8cache);
		PL_utf8cache = 0;
		Perl_croak(aTHX_ "panic: sv_pos_u2b_cache cache %"UVuf
			   " real %"UVuf" for %"SVf,
			   (UV) boffset, (UV) real_boffset, (void*)sv);
	    }
	}
	boffset = real_boffset;
    }

    if (PL_utf8cache)
	utf8_mg_pos_cache_update(sv, mgp, boffset, uoffset, send - start);
    return boffset;
}


/*
=for apidoc sv_pos_u2b

Converts the value pointed to by offsetp from a count of UTF-8 chars from
the start of the string, to a count of the equivalent number of bytes; if
lenp is non-zero, it does the same to lenp, but this time starting from
the offset, rather than from the start of the string. Handles magic and
type coercion.

=cut
*/

/*
 * sv_pos_u2b() uses, like sv_pos_b2u(), the mg_ptr of the potential
 * PERL_UTF8_magic of the sv to store the mapping between UTF-8 and
 * byte offsets.  See also the comments of S_utf8_mg_pos_cache_update().
 *
 */

void
Perl_sv_pos_u2b(pTHX_ register SV *sv, I32* offsetp, I32* lenp)
{
    const U8 *start;
    STRLEN len;

    if (!sv)
	return;

    start = (U8*)SvPV_const(sv, len);
    if (len) {
	STRLEN uoffset = (STRLEN) *offsetp;
	const U8 * const send = start + len;
	MAGIC *mg = NULL;
	const STRLEN boffset = sv_pos_u2b_cached(sv, &mg, start, send,
					     uoffset, 0, 0);

	*offsetp = (I32) boffset;

	if (lenp) {
	    /* Convert the relative offset to absolute.  */
	    const STRLEN uoffset2 = uoffset + (STRLEN) *lenp;
	    const STRLEN boffset2
		= sv_pos_u2b_cached(sv, &mg, start, send, uoffset2,
				      uoffset, boffset) - boffset;
	    *lenp = boffset2;
	}
    }
    else {
	 *offsetp = 0;
	 if (lenp)
	      *lenp = 0;
    }

    return;
}

/* Create and update the UTF8 magic offset cache, with the proffered utf8/
   byte length pairing. The (byte) length of the total SV is passed in too,
   as blen, because for some (more esoteric) SVs, the call to SvPV_const()
   may not have updated SvCUR, so we can't rely on reading it directly.

   The proffered utf8/byte length pairing isn't used if the cache already has
   two pairs, and swapping either for the proffered pair would increase the
   RMS of the intervals between known byte offsets.

   The cache itself consists of 4 STRLEN values
   0: larger UTF-8 offset
   1: corresponding byte offset
   2: smaller UTF-8 offset
   3: corresponding byte offset

   Unused cache pairs have the value 0, 0.
   Keeping the cache "backwards" means that the invariant of
   cache[0] >= cache[2] is maintained even with empty slots, which means that
   the code that uses it doesn't need to worry if only 1 entry has actually
   been set to non-zero.  It also makes the "position beyond the end of the
   cache" logic much simpler, as the first slot is always the one to start
   from.   
*/
static void
S_utf8_mg_pos_cache_update(pTHX_ SV *sv, MAGIC **mgp, STRLEN byte, STRLEN utf8,
			   STRLEN blen)
{
    STRLEN *cache;
    if (SvREADONLY(sv))
	return;

    if (!*mgp) {
	*mgp = sv_magicext(sv, 0, PERL_MAGIC_utf8, (MGVTBL*)&PL_vtbl_utf8, 0,
			   0);
	(*mgp)->mg_len = -1;
    }
    assert(*mgp);

    if (!(cache = (STRLEN *)(*mgp)->mg_ptr)) {
	Newxz(cache, PERL_MAGIC_UTF8_CACHESIZE * 2, STRLEN);
	(*mgp)->mg_ptr = (char *) cache;
    }
    assert(cache);

    if (PL_utf8cache < 0) {
	const U8 *start = (const U8 *) SvPVX_const(sv);
	const STRLEN realutf8 = utf8_length((U8 *)start, (U8 *)start + byte);

	if (realutf8 != utf8) {
	    /* Need to turn the assertions off otherwise we may recurse
	       infinitely while printing error messages.  */
	    SAVEI8(PL_utf8cache);
	    PL_utf8cache = 0;
	    Perl_croak(aTHX_ "panic: utf8_mg_pos_cache_update cache %"UVuf
		       " real %"UVuf" for %"SVf, (UV) utf8, (UV) realutf8, (void*)sv);
	}
    }

    /* Cache is held with the later position first, to simplify the code
       that deals with unbounded ends.  */
       
    ASSERT_UTF8_CACHE(cache);
    if (cache[1] == 0) {
	/* Cache is totally empty  */
	cache[0] = utf8;
	cache[1] = byte;
    } else if (cache[3] == 0) {
	if (byte > cache[1]) {
	    /* New one is larger, so goes first.  */
	    cache[2] = cache[0];
	    cache[3] = cache[1];
	    cache[0] = utf8;
	    cache[1] = byte;
	} else {
	    cache[2] = utf8;
	    cache[3] = byte;
	}
    } else {
#define THREEWAY_SQUARE(a,b,c,d) \
	    ((float)((d) - (c))) * ((float)((d) - (c))) \
	    + ((float)((c) - (b))) * ((float)((c) - (b))) \
	       + ((float)((b) - (a))) * ((float)((b) - (a)))

	/* Cache has 2 slots in use, and we know three potential pairs.
	   Keep the two that give the lowest RMS distance. Do the
	   calcualation in bytes simply because we always know the byte
	   length.  squareroot has the same ordering as the positive value,
	   so don't bother with the actual square root.  */
	const float existing = THREEWAY_SQUARE(0, cache[3], cache[1], blen);
	if (byte > cache[1]) {
	    /* New position is after the existing pair of pairs.  */
	    const float keep_earlier
		= THREEWAY_SQUARE(0, cache[3], byte, blen);
	    const float keep_later
		= THREEWAY_SQUARE(0, cache[1], byte, blen);

	    if (keep_later < keep_earlier) {
		if (keep_later < existing) {
		    cache[2] = cache[0];
		    cache[3] = cache[1];
		    cache[0] = utf8;
		    cache[1] = byte;
		}
	    }
	    else {
		if (keep_earlier < existing) {
		    cache[0] = utf8;
		    cache[1] = byte;
		}
	    }
	}
	else if (byte > cache[3]) {
	    /* New position is between the existing pair of pairs.  */
	    const float keep_earlier
		= THREEWAY_SQUARE(0, cache[3], byte, blen);
	    const float keep_later
		= THREEWAY_SQUARE(0, byte, cache[1], blen);

	    if (keep_later < keep_earlier) {
		if (keep_later < existing) {
		    cache[2] = utf8;
		    cache[3] = byte;
		}
	    }
	    else {
		if (keep_earlier < existing) {
		    cache[0] = utf8;
		    cache[1] = byte;
		}
	    }
	}
	else {
 	    /* New position is before the existing pair of pairs.  */
	    const float keep_earlier
		= THREEWAY_SQUARE(0, byte, cache[3], blen);
	    const float keep_later
		= THREEWAY_SQUARE(0, byte, cache[1], blen);

	    if (keep_later < keep_earlier) {
		if (keep_later < existing) {
		    cache[2] = utf8;
		    cache[3] = byte;
		}
	    }
	    else {
		if (keep_earlier < existing) {
		    cache[0] = cache[2];
		    cache[1] = cache[3];
		    cache[2] = utf8;
		    cache[3] = byte;
		}
	    }
	}
    }
    ASSERT_UTF8_CACHE(cache);
}

/* We already know all of the way, now we may be able to walk back.  The same
   assumption is made as in S_sv_pos_u2b_midway(), namely that walking
   backward is half the speed of walking forward. */
static STRLEN
S_sv_pos_b2u_midway(pTHX_ const U8 *s, const U8 *const target, const U8 *end,
		    STRLEN endu)
{
    const STRLEN forw = target - s;
    STRLEN backw = end - target;

    if (forw < 2 * backw) {
	return utf8_length((U8 *)s, (U8 *)target);
    }

    while (end > target) {
	end--;
	while (UTF8_IS_CONTINUATION(*end)) {
	    end--;
	}
	endu--;
    }
    return endu;
}

/*
=for apidoc sv_pos_b2u

Converts the value pointed to by offsetp from a count of bytes from the
start of the string, to a count of the equivalent number of UTF-8 chars.
Handles magic and type coercion.

=cut
*/

/*
 * sv_pos_b2u() uses, like sv_pos_u2b(), the mg_ptr of the potential
 * PERL_UTF8_magic of the sv to store the mapping between UTF-8 and
 * byte offsets.
 *
 */
void
Perl_sv_pos_b2u(pTHX_ register SV* sv, I32* offsetp)
{
    const U8* s;
    const STRLEN byte = *offsetp;
    STRLEN len = 0; /* Actually always set, but let's keep gcc happy.  */
    STRLEN blen;
    MAGIC* mg = NULL;
    const U8* send;
    bool found = FALSE;

    if (!sv)
	return;

    s = (const U8*)SvPV_const(sv, blen);

    if (blen < byte)
	Perl_croak(aTHX_ "panic: sv_pos_b2u: bad byte offset");
      
    send = s + byte;

    if (SvMAGICAL(sv) && !SvREADONLY(sv) && PL_utf8cache
	&& (mg = mg_find(sv, PERL_MAGIC_utf8))) {
	if (mg->mg_ptr) {
	    STRLEN * const cache = (STRLEN *) mg->mg_ptr;
	    if (cache[1] == byte) {
		/* An exact match. */
		*offsetp = cache[0];
		return;
	    }
	    if (cache[3] == byte) {
		/* An exact match. */
		*offsetp = cache[2];
		return;
	    }

	    if (cache[1] < byte) {
		/* We already know part of the way. */
		if (mg->mg_len != -1) {
		    /* Actually, we know the end too.  */
		    len = cache[0]
			+ S_sv_pos_b2u_midway(aTHX_ s + cache[1], send,
					      s + blen, mg->mg_len - cache[0]);
		} else {
		    len = cache[0] + utf8_length((U8 *)s + cache[1],
						 (U8 *)send);
		}
	    }
	    else if (cache[3] < byte) {
		/* We're between the two cached pairs, so we do the calculation
		   offset by the byte/utf-8 positions for the earlier pair,
		   then add the utf-8 characters from the string start to
		   there.  */
		len = S_sv_pos_b2u_midway(aTHX_ s + cache[3], send,
					  s + cache[1], cache[0] - cache[2])
		    + cache[2];

	    }
	    else { /* cache[3] > byte */
		len = S_sv_pos_b2u_midway(aTHX_ s, send, s + cache[3],
					  cache[2]);

	    }
	    ASSERT_UTF8_CACHE(cache);
	    found = TRUE;
	} else if (mg->mg_len != -1) {
	    len = S_sv_pos_b2u_midway(aTHX_ s, send, s + blen, mg->mg_len);
	    found = TRUE;
	}
    }
    if (!found || PL_utf8cache < 0) {
	const STRLEN real_len = utf8_length((U8 *)s, (U8 *)send);

	if (found && PL_utf8cache < 0) {
	    if (len != real_len) {
		/* Need to turn the assertions off otherwise we may recurse
		   infinitely while printing error messages.  */
		SAVEI8(PL_utf8cache);
		PL_utf8cache = 0;
		Perl_croak(aTHX_ "panic: sv_pos_b2u cache %"UVuf
			   " real %"UVuf" for %"SVf,
			   (UV) len, (UV) real_len, (void*)sv);
	    }
	}
	len = real_len;
    }
    *offsetp = len;

    if (PL_utf8cache)
	utf8_mg_pos_cache_update(sv, &mg, byte, len, blen);
}

/*
=for apidoc sv_eq

Returns a boolean indicating whether the strings in the two SVs are
identical. Is UTF-8 and 'use bytes' aware, handles get magic, and will
coerce its args to strings if necessary.

=cut
*/

I32
Perl_sv_eq(pTHX_ register SV *sv1, register SV *sv2)
{
    const char *pv1;
    STRLEN cur1;
    const char *pv2;
    STRLEN cur2;
    I32  eq     = 0;
    char *tpv   = NULL;
    SV* svrecode = NULL;

    if (!sv1) {
	pv1 = "";
	cur1 = 0;
    }
    else {
	/* if pv1 and pv2 are the same, second SvPV_const call may
	 * invalidate pv1, so we may need to make a copy */
	if (sv1 == sv2 && (SvTHINKFIRST(sv1) || SvGMAGICAL(sv1))) {
	    pv1 = SvPV_const(sv1, cur1);
	    sv1 = newSVpvn_flags(pv1, cur1, SVs_TEMP | SvUTF8(sv2));
	}
	pv1 = SvPV_const(sv1, cur1);
    }

    if (!sv2){
	pv2 = "";
	cur2 = 0;
    }
    else
	pv2 = SvPV_const(sv2, cur2);

    if (cur1 && cur2 && SvUTF8(sv1) != SvUTF8(sv2) && !IN_BYTES) {
        /* Differing utf8ness.
	 * Do not UTF8size the comparands as a side-effect. */
	 if (PL_encoding) {
	      if (SvUTF8(sv1)) {
		   svrecode = newSVpvn(pv2, cur2);
		   sv_recode_to_utf8(svrecode, PL_encoding);
		   pv2 = SvPV_const(svrecode, cur2);
	      }
	      else {
		   svrecode = newSVpvn(pv1, cur1);
		   sv_recode_to_utf8(svrecode, PL_encoding);
		   pv1 = SvPV_const(svrecode, cur1);
	      }
	      /* Now both are in UTF-8. */
	      if (cur1 != cur2) {
		   SvREFCNT_dec(svrecode);
		   return FALSE;
	      }
	 }
	 else {
	      bool is_utf8 = TRUE;

	      if (SvUTF8(sv1)) {
		   /* sv1 is the UTF-8 one,
		    * if is equal it must be downgrade-able */
		   char * const pv = (char*)bytes_from_utf8((U8*)pv1,
						     &cur1, &is_utf8);
		   if (pv != pv1)
			pv1 = tpv = pv;
	      }
	      else {
		   /* sv2 is the UTF-8 one,
		    * if is equal it must be downgrade-able */
		   char * const pv = (char *)bytes_from_utf8((U8*)pv2,
						      &cur2, &is_utf8);
		   if (pv != pv2)
			pv2 = tpv = pv;
	      }
	      if (is_utf8) {
		   /* Downgrade not possible - cannot be eq */
		   assert (tpv == 0);
		   return FALSE;
	      }
	 }
    }

    if (cur1 == cur2)
	eq = memEQ(pv1, pv2, cur1);
	
    SvREFCNT_dec(svrecode);
    if (tpv)
	Safefree(tpv);

    return eq;
}

/*
=for apidoc sv_cmp

Compares the strings in two SVs.  Returns -1, 0, or 1 indicating whether the
string in C<sv1> is less than, equal to, or greater than the string in
C<sv2>. Is UTF-8 and 'use bytes' aware, handles get magic, and will
coerce its args to strings if necessary.  See also C<sv_cmp_locale>.

=cut
*/

I32
Perl_sv_cmp(pTHX_ register SV *sv1, register SV *sv2)
{
    STRLEN cur1, cur2;
    const char *pv1, *pv2;
    char *tpv = NULL;
    I32  cmp;
    SV *svrecode = NULL;

    if (!sv1) {
	pv1 = "";
	cur1 = 0;
    }
    else
	pv1 = SvPV_const(sv1, cur1);

    if (!sv2) {
	pv2 = "";
	cur2 = 0;
    }
    else
	pv2 = SvPV_const(sv2, cur2);

    if (cur1 && cur2 && SvUTF8(sv1) != SvUTF8(sv2) && !IN_BYTES) {
        /* Differing utf8ness.
	 * Do not UTF8size the comparands as a side-effect. */
	if (SvUTF8(sv1)) {
	    if (PL_encoding) {
		 svrecode = newSVpvn(pv2, cur2);
		 sv_recode_to_utf8(svrecode, PL_encoding);
		 pv2 = SvPV_const(svrecode, cur2);
	    }
	    else {
		 pv2 = tpv = (char*)bytes_to_utf8((U8*)pv2, &cur2);
	    }
	}
	else {
	    if (PL_encoding) {
		 svrecode = newSVpvn(pv1, cur1);
		 sv_recode_to_utf8(svrecode, PL_encoding);
		 pv1 = SvPV_const(svrecode, cur1);
	    }
	    else {
		 pv1 = tpv = (char*)bytes_to_utf8((U8*)pv1, &cur1);
	    }
	}
    }

    if (!cur1) {
	cmp = cur2 ? -1 : 0;
    } else if (!cur2) {
	cmp = 1;
    } else {
        const I32 retval = memcmp((const void*)pv1, (const void*)pv2, cur1 < cur2 ? cur1 : cur2);

	if (retval) {
	    cmp = retval < 0 ? -1 : 1;
	} else if (cur1 == cur2) {
	    cmp = 0;
        } else {
	    cmp = cur1 < cur2 ? -1 : 1;
	}
    }

    SvREFCNT_dec(svrecode);
    if (tpv)
	Safefree(tpv);

    return cmp;
}

/*
=for apidoc sv_cmp_locale

Compares the strings in two SVs in a locale-aware manner. Is UTF-8 and
'use bytes' aware, handles get magic, and will coerce its args to strings
if necessary.  See also C<sv_cmp>.

=cut
*/

I32
Perl_sv_cmp_locale(pTHX_ register SV *sv1, register SV *sv2)
{
#ifdef USE_LOCALE_COLLATE

    char *pv1, *pv2;
    STRLEN len1, len2;
    I32 retval;

    if (PL_collation_standard)
	goto raw_compare;

    len1 = 0;
    pv1 = sv1 ? sv_collxfrm(sv1, &len1) : (char *) NULL;
    len2 = 0;
    pv2 = sv2 ? sv_collxfrm(sv2, &len2) : (char *) NULL;

    if (!pv1 || !len1) {
	if (pv2 && len2)
	    return -1;
	else
	    goto raw_compare;
    }
    else {
	if (!pv2 || !len2)
	    return 1;
    }

    retval = memcmp((void*)pv1, (void*)pv2, len1 < len2 ? len1 : len2);

    if (retval)
	return retval < 0 ? -1 : 1;

    /*
     * When the result of collation is equality, that doesn't mean
     * that there are no differences -- some locales exclude some
     * characters from consideration.  So to avoid false equalities,
     * we use the raw string as a tiebreaker.
     */

  raw_compare:
    /*FALLTHROUGH*/

#endif /* USE_LOCALE_COLLATE */

    return sv_cmp(sv1, sv2);
}


#ifdef USE_LOCALE_COLLATE

/*
=for apidoc sv_collxfrm

Add Collate Transform magic to an SV if it doesn't already have it.

Any scalar variable may carry PERL_MAGIC_collxfrm magic that contains the
scalar data of the variable, but transformed to such a format that a normal
memory comparison can be used to compare the data according to the locale
settings.

=cut
*/

char *
Perl_sv_collxfrm(pTHX_ SV *sv, STRLEN *nxp)
{
    MAGIC *mg;

    mg = SvMAGICAL(sv) ? mg_find(sv, PERL_MAGIC_collxfrm) : (MAGIC *) NULL;
    if (!mg || !mg->mg_ptr || *(U32*)mg->mg_ptr != PL_collation_ix) {
	const char *s;
	char *xf;
	STRLEN len, xlen;

	if (mg)
	    Safefree(mg->mg_ptr);
	s = SvPV_const(sv, len);
	if ((xf = mem_collxfrm(s, len, &xlen))) {
	    if (! mg) {
#ifdef PERL_OLD_COPY_ON_WRITE
		if (SvIsCOW(sv))
		    sv_force_normal_flags(sv, 0);
#endif
		mg = sv_magicext(sv, 0, PERL_MAGIC_collxfrm, &PL_vtbl_collxfrm,
				 0, 0);
		assert(mg);
	    }
	    mg->mg_ptr = xf;
	    mg->mg_len = xlen;
	}
	else {
	    if (mg) {
		mg->mg_ptr = NULL;
		mg->mg_len = -1;
	    }
	}
    }
    if (mg && mg->mg_ptr) {
	*nxp = mg->mg_len;
	return mg->mg_ptr + sizeof(PL_collation_ix);
    }
    else {
	*nxp = 0;
	return NULL;
    }
}

#endif /* USE_LOCALE_COLLATE */

/*
=for apidoc sv_gets

Get a line from the filehandle and store it into the SV, optionally
appending to the currently-stored string.

=cut
*/

char *
Perl_sv_gets(pTHX_ register SV *sv, register PerlIO *fp, I32 append)
{
    const char *rsptr;
    STRLEN rslen;
    register STDCHAR rslast;
    register STDCHAR *bp;
    register I32 cnt;
    I32 i = 0;
    I32 rspara = 0;

    if (SvTHINKFIRST(sv))
	sv_force_normal_flags(sv, append ? 0 : SV_COW_DROP_PV);
    /* XXX. If you make this PVIV, then copy on write can copy scalars read
       from <>.
       However, perlbench says it's slower, because the existing swipe code
       is faster than copy on write.
       Swings and roundabouts.  */
    (void)SvUPGRADE(sv, SVt_PV);

    SvSCREAM_off(sv);

    if (append) {
	if (PerlIO_isutf8(fp)) {
	    if (!SvUTF8(sv)) {
		sv_utf8_upgrade_nomg(sv);
		sv_pos_u2b(sv,&append,0);
	    }
	} else if (SvUTF8(sv)) {
	    SV * const tsv = newSV(0);
	    sv_gets(tsv, fp, 0);
	    sv_utf8_upgrade_nomg(tsv);
	    SvCUR_set(sv,append);
	    sv_catsv(sv,tsv);
	    sv_free(tsv);
	    goto return_string_or_null;
	}
    }

    SvPOK_only(sv);
    if (PerlIO_isutf8(fp))
	SvUTF8_on(sv);

    if (IN_PERL_COMPILETIME) {
	/* we always read code in line mode */
	rsptr = "\n";
	rslen = 1;
    }
    else if (RsSNARF(PL_rs)) {
    	/* If it is a regular disk file use size from stat() as estimate
	   of amount we are going to read -- may result in mallocing
	   more memory than we really need if the layers below reduce
	   the size we read (e.g. CRLF or a gzip layer).
	 */
	Stat_t st;
	if (!PerlLIO_fstat(PerlIO_fileno(fp), &st) && S_ISREG(st.st_mode))  {
	    const Off_t offset = PerlIO_tell(fp);
	    if (offset != (Off_t) -1 && st.st_size + append > offset) {
	     	(void) SvGROW(sv, (STRLEN)((st.st_size - offset) + append + 1));
	    }
	}
	rsptr = NULL;
	rslen = 0;
    }
    else if (RsRECORD(PL_rs)) {
      I32 bytesread;
      char *buffer;
      U32 recsize;
#ifdef VMS
      int fd;
#endif

      /* Grab the size of the record we're getting */
      recsize = SvUV(SvRV(PL_rs)); /* RsRECORD() guarantees > 0. */
      buffer = SvGROW(sv, (STRLEN)(recsize + append + 1)) + append;
      /* Go yank in */
#ifdef VMS
      /* VMS wants read instead of fread, because fread doesn't respect */
      /* RMS record boundaries. This is not necessarily a good thing to be */
      /* doing, but we've got no other real choice - except avoid stdio
         as implementation - perhaps write a :vms layer ?
       */
      fd = PerlIO_fileno(fp);
      if (fd == -1) { /* in-memory file from PerlIO::Scalar */
          bytesread = PerlIO_read(fp, buffer, recsize);
      }
      else {
          bytesread = PerlLIO_read(fd, buffer, recsize);
      }
#else
      bytesread = PerlIO_read(fp, buffer, recsize);
#endif
      if (bytesread < 0)
	  bytesread = 0;
      SvCUR_set(sv, bytesread + append);
      buffer[bytesread] = '\0';
      goto return_string_or_null;
    }
    else if (RsPARA(PL_rs)) {
	rsptr = "\n\n";
	rslen = 2;
	rspara = 1;
    }
    else {
	/* Get $/ i.e. PL_rs into same encoding as stream wants */
	if (PerlIO_isutf8(fp)) {
	    rsptr = SvPVutf8(PL_rs, rslen);
	}
	else {
	    if (SvUTF8(PL_rs)) {
		if (!sv_utf8_downgrade(PL_rs, TRUE)) {
		    Perl_croak(aTHX_ "Wide character in $/");
		}
	    }
	    rsptr = SvPV_const(PL_rs, rslen);
	}
    }

    rslast = rslen ? rsptr[rslen - 1] : '\0';

    if (rspara) {		/* have to do this both before and after */
	do {			/* to make sure file boundaries work right */
	    if (PerlIO_eof(fp))
		return 0;
	    i = PerlIO_getc(fp);
	    if (i != '\n') {
		if (i == -1)
		    return 0;
		PerlIO_ungetc(fp,i);
		break;
	    }
	} while (i != EOF);
    }

    /* See if we know enough about I/O mechanism to cheat it ! */

    /* This used to be #ifdef test - it is made run-time test for ease
       of abstracting out stdio interface. One call should be cheap
       enough here - and may even be a macro allowing compile
       time optimization.
     */

    if (PerlIO_fast_gets(fp)) {

    /*
     * We're going to steal some values from the stdio struct
     * and put EVERYTHING in the innermost loop into registers.
     */
    register STDCHAR *ptr;
    STRLEN bpx;
    I32 shortbuffered;

#if defined(VMS) && defined(PERLIO_IS_STDIO)
    /* An ungetc()d char is handled separately from the regular
     * buffer, so we getc() it back out and stuff it in the buffer.
     */
    i = PerlIO_getc(fp);
    if (i == EOF) return 0;
    *(--((*fp)->_ptr)) = (unsigned char) i;
    (*fp)->_cnt++;
#endif

    /* Here is some breathtakingly efficient cheating */

    cnt = PerlIO_get_cnt(fp);			/* get count into register */
    /* make sure we have the room */
    if ((I32)(SvLEN(sv) - append) <= cnt + 1) { 
    	/* Not room for all of it
	   if we are looking for a separator and room for some 
	 */
	if (rslen && cnt > 80 && (I32)SvLEN(sv) > append) {
	    /* just process what we have room for */ 
	    shortbuffered = cnt - SvLEN(sv) + append + 1;
	    cnt -= shortbuffered;
	}
	else {
	    shortbuffered = 0;
	    /* remember that cnt can be negative */
	    SvGROW(sv, (STRLEN)(append + (cnt <= 0 ? 2 : (cnt + 1))));
	}
    }
    else 
	shortbuffered = 0;
    bp = (STDCHAR*)SvPVX_const(sv) + append;  /* move these two too to registers */
    ptr = (STDCHAR*)PerlIO_get_ptr(fp);
    DEBUG_P(PerlIO_printf(Perl_debug_log,
	"Screamer: entering, ptr=%"UVuf", cnt=%ld\n",PTR2UV(ptr),(long)cnt));
    DEBUG_P(PerlIO_printf(Perl_debug_log,
	"Screamer: entering: PerlIO * thinks ptr=%"UVuf", cnt=%ld, base=%"UVuf"\n",
	       PTR2UV(PerlIO_get_ptr(fp)), (long)PerlIO_get_cnt(fp),
	       PTR2UV(PerlIO_has_base(fp) ? PerlIO_get_base(fp) : 0)));
    for (;;) {
      screamer:
	if (cnt > 0) {
	    if (rslen) {
		while (cnt > 0) {		     /* this     |  eat */
		    cnt--;
		    if ((*bp++ = *ptr++) == rslast)  /* really   |  dust */
			goto thats_all_folks;	     /* screams  |  sed :-) */
		}
	    }
	    else {
	        Copy(ptr, bp, cnt, char);	     /* this     |  eat */
		bp += cnt;			     /* screams  |  dust */
		ptr += cnt;			     /* louder   |  sed :-) */
		cnt = 0;
	    }
	}
	
	if (shortbuffered) {		/* oh well, must extend */
	    cnt = shortbuffered;
	    shortbuffered = 0;
	    bpx = bp - (STDCHAR*)SvPVX_const(sv); /* box up before relocation */
	    SvCUR_set(sv, bpx);
	    SvGROW(sv, SvLEN(sv) + append + cnt + 2);
	    bp = (STDCHAR*)SvPVX_const(sv) + bpx; /* unbox after relocation */
	    continue;
	}

	DEBUG_P(PerlIO_printf(Perl_debug_log,
			      "Screamer: going to getc, ptr=%"UVuf", cnt=%ld\n",
			      PTR2UV(ptr),(long)cnt));
	PerlIO_set_ptrcnt(fp, (STDCHAR*)ptr, cnt); /* deregisterize cnt and ptr */
#if 0
	DEBUG_P(PerlIO_printf(Perl_debug_log,
	    "Screamer: pre: FILE * thinks ptr=%"UVuf", cnt=%ld, base=%"UVuf"\n",
	    PTR2UV(PerlIO_get_ptr(fp)), (long)PerlIO_get_cnt(fp),
	    PTR2UV(PerlIO_has_base (fp) ? PerlIO_get_base(fp) : 0)));
#endif
	/* This used to call 'filbuf' in stdio form, but as that behaves like
	   getc when cnt <= 0 we use PerlIO_getc here to avoid introducing
	   another abstraction.  */
	i   = PerlIO_getc(fp);		/* get more characters */
#if 0
	DEBUG_P(PerlIO_printf(Perl_debug_log,
	    "Screamer: post: FILE * thinks ptr=%"UVuf", cnt=%ld, base=%"UVuf"\n",
	    PTR2UV(PerlIO_get_ptr(fp)), (long)PerlIO_get_cnt(fp),
	    PTR2UV(PerlIO_has_base (fp) ? PerlIO_get_base(fp) : 0)));
#endif
	cnt = PerlIO_get_cnt(fp);
	ptr = (STDCHAR*)PerlIO_get_ptr(fp);	/* reregisterize cnt and ptr */
	DEBUG_P(PerlIO_printf(Perl_debug_log,
	    "Screamer: after getc, ptr=%"UVuf", cnt=%ld\n",PTR2UV(ptr),(long)cnt));

	if (i == EOF)			/* all done for ever? */
	    goto thats_really_all_folks;

	bpx = bp - (STDCHAR*)SvPVX_const(sv);	/* box up before relocation */
	SvCUR_set(sv, bpx);
	SvGROW(sv, bpx + cnt + 2);
	bp = (STDCHAR*)SvPVX_const(sv) + bpx;	/* unbox after relocation */

	*bp++ = (STDCHAR)i;		/* store character from PerlIO_getc */

	if (rslen && (STDCHAR)i == rslast)  /* all done for now? */
	    goto thats_all_folks;
    }

thats_all_folks:
    if ((rslen > 1 && (STRLEN)(bp - (STDCHAR*)SvPVX_const(sv)) < rslen) ||
	  memNE((char*)bp - rslen, rsptr, rslen))
	goto screamer;				/* go back to the fray */
thats_really_all_folks:
    if (shortbuffered)
	cnt += shortbuffered;
	DEBUG_P(PerlIO_printf(Perl_debug_log,
	    "Screamer: quitting, ptr=%"UVuf", cnt=%ld\n",PTR2UV(ptr),(long)cnt));
    PerlIO_set_ptrcnt(fp, (STDCHAR*)ptr, cnt);	/* put these back or we're in trouble */
    DEBUG_P(PerlIO_printf(Perl_debug_log,
	"Screamer: end: FILE * thinks ptr=%"UVuf", cnt=%ld, base=%"UVuf"\n",
	PTR2UV(PerlIO_get_ptr(fp)), (long)PerlIO_get_cnt(fp),
	PTR2UV(PerlIO_has_base (fp) ? PerlIO_get_base(fp) : 0)));
    *bp = '\0';
    SvCUR_set(sv, bp - (STDCHAR*)SvPVX_const(sv));	/* set length */
    DEBUG_P(PerlIO_printf(Perl_debug_log,
	"Screamer: done, len=%ld, string=|%.*s|\n",
	(long)SvCUR(sv),(int)SvCUR(sv),SvPVX_const(sv)));
    }
   else
    {
       /*The big, slow, and stupid way. */
#ifdef USE_HEAP_INSTEAD_OF_STACK	/* Even slower way. */
	STDCHAR *buf = NULL;
	Newx(buf, 8192, STDCHAR);
	assert(buf);
#else
	STDCHAR buf[8192];
#endif

screamer2:
	if (rslen) {
            register const STDCHAR * const bpe = buf + sizeof(buf);
	    bp = buf;
	    while ((i = PerlIO_getc(fp)) != EOF && (*bp++ = (STDCHAR)i) != rslast && bp < bpe)
		; /* keep reading */
	    cnt = bp - buf;
	}
	else {
	    cnt = PerlIO_read(fp,(char*)buf, sizeof(buf));
	    /* Accomodate broken VAXC compiler, which applies U8 cast to
	     * both args of ?: operator, causing EOF to change into 255
	     */
	    if (cnt > 0)
		 i = (U8)buf[cnt - 1];
	    else
		 i = EOF;
	}

	if (cnt < 0)
	    cnt = 0;  /* we do need to re-set the sv even when cnt <= 0 */
	if (append)
	     sv_catpvn(sv, (char *) buf, cnt);
	else
	     sv_setpvn(sv, (char *) buf, cnt);

	if (i != EOF &&			/* joy */
	    (!rslen ||
	     SvCUR(sv) < rslen ||
	     memNE(SvPVX_const(sv) + SvCUR(sv) - rslen, rsptr, rslen)))
	{
	    append = -1;
	    /*
	     * If we're reading from a TTY and we get a short read,
	     * indicating that the user hit his EOF character, we need
	     * to notice it now, because if we try to read from the TTY
	     * again, the EOF condition will disappear.
	     *
	     * The comparison of cnt to sizeof(buf) is an optimization
	     * that prevents unnecessary calls to feof().
	     *
	     * - jik 9/25/96
	     */
	    if (!(cnt < (I32)sizeof(buf) && PerlIO_eof(fp)))
		goto screamer2;
	}

#ifdef USE_HEAP_INSTEAD_OF_STACK
	Safefree(buf);
#endif
    }

    if (rspara) {		/* have to do this both before and after */
        while (i != EOF) {	/* to make sure file boundaries work right */
	    i = PerlIO_getc(fp);
	    if (i != '\n') {
		PerlIO_ungetc(fp,i);
		break;
	    }
	}
    }

return_string_or_null:
    return (SvCUR(sv) - append) ? SvPVX(sv) : NULL;
}

/*
=for apidoc sv_inc

Auto-increment of the value in the SV, doing string to numeric conversion
if necessary. Handles 'get' magic.

=cut
*/

void
Perl_sv_inc(pTHX_ register SV *sv)
{
    register char *d;
    int flags;

    if (!sv)
	return;
    SvGETMAGIC(sv);
    if (SvTHINKFIRST(sv)) {
	if (SvREADONLY(sv) && SvFAKE(sv))
	    sv_force_normal(sv);
	if (SvREADONLY(sv)) {
	    if (IN_PERL_RUNTIME)
		Perl_croak(aTHX_ "%s", PL_no_modify);
	}
	if (SvROK(sv)) {
	    IV i;
	    if (SvAMAGIC(sv) && AMG_CALLun(sv,inc))
		return;
	    i = PTR2IV(SvRV(sv));
	    sv_unref(sv);
	    sv_setiv(sv, i);
	}
    }
    flags = SvFLAGS(sv);
    if ((flags & (SVp_NOK|SVp_IOK)) == SVp_NOK) {
	/* It's (privately or publicly) a float, but not tested as an
	   integer, so test it to see. */
	(void) SvIV(sv);
	flags = SvFLAGS(sv);
    }
    if ((flags & SVf_IOK) || ((flags & (SVp_IOK | SVp_NOK)) == SVp_IOK)) {
	/* It's publicly an integer, or privately an integer-not-float */
#ifdef PERL_PRESERVE_IVUV
      oops_its_int:
#endif
	if (SvIsUV(sv)) {
	    if (SvUVX(sv) == UV_MAX)
		sv_setnv(sv, UV_MAX_P1);
	    else
		(void)SvIOK_only_UV(sv);
		SvUV_set(sv, SvUVX(sv) + 1);
	} else {
	    if (SvIVX(sv) == IV_MAX)
		sv_setuv(sv, (UV)IV_MAX + 1);
	    else {
		(void)SvIOK_only(sv);
		SvIV_set(sv, SvIVX(sv) + 1);
	    }	
	}
	return;
    }
    if (flags & SVp_NOK) {
	(void)SvNOK_only(sv);
        SvNV_set(sv, SvNVX(sv) + 1.0);
	return;
    }

    if (!(flags & SVp_POK) || !*SvPVX_const(sv)) {
	if ((flags & SVTYPEMASK) < SVt_PVIV)
	    sv_upgrade(sv, ((flags & SVTYPEMASK) > SVt_IV ? SVt_PVIV : SVt_IV));
	(void)SvIOK_only(sv);
	SvIV_set(sv, 1);
	return;
    }
    d = SvPVX(sv);
    while (isALPHA(*d)) d++;
    while (isDIGIT(*d)) d++;
    if (*d) {
#ifdef PERL_PRESERVE_IVUV
	/* Got to punt this as an integer if needs be, but we don't issue
	   warnings. Probably ought to make the sv_iv_please() that does
	   the conversion if possible, and silently.  */
	const int numtype = grok_number(SvPVX_const(sv), SvCUR(sv), NULL);
	if (numtype && !(numtype & IS_NUMBER_INFINITY)) {
	    /* Need to try really hard to see if it's an integer.
	       9.22337203685478e+18 is an integer.
	       but "9.22337203685478e+18" + 0 is UV=9223372036854779904
	       so $a="9.22337203685478e+18"; $a+0; $a++
	       needs to be the same as $a="9.22337203685478e+18"; $a++
	       or we go insane. */
	
	    (void) sv_2iv(sv);
	    if (SvIOK(sv))
		goto oops_its_int;

	    /* sv_2iv *should* have made this an NV */
	    if (flags & SVp_NOK) {
		(void)SvNOK_only(sv);
                SvNV_set(sv, SvNVX(sv) + 1.0);
		return;
	    }
	    /* I don't think we can get here. Maybe I should assert this
	       And if we do get here I suspect that sv_setnv will croak. NWC
	       Fall through. */
#if defined(USE_LONG_DOUBLE)
	    DEBUG_c(PerlIO_printf(Perl_debug_log,"sv_inc punt failed to convert '%s' to IOK or NOKp, UV=0x%"UVxf" NV=%"PERL_PRIgldbl"\n",
				  SvPVX_const(sv), SvIVX(sv), SvNVX(sv)));
#else
	    DEBUG_c(PerlIO_printf(Perl_debug_log,"sv_inc punt failed to convert '%s' to IOK or NOKp, UV=0x%"UVxf" NV=%"NVgf"\n",
				  SvPVX_const(sv), SvIVX(sv), SvNVX(sv)));
#endif
	}
#endif /* PERL_PRESERVE_IVUV */
	sv_setnv(sv,Atof(SvPVX_const(sv)) + 1.0);
	return;
    }
    d--;
    while (d >= SvPVX_const(sv)) {
	if (isDIGIT(*d)) {
	    if (++*d <= '9')
		return;
	    *(d--) = '0';
	}
	else {
#ifdef EBCDIC
	    /* MKS: The original code here died if letters weren't consecutive.
	     * at least it didn't have to worry about non-C locales.  The
	     * new code assumes that ('z'-'a')==('Z'-'A'), letters are
	     * arranged in order (although not consecutively) and that only
	     * [A-Za-z] are accepted by isALPHA in the C locale.
	     */
	    if (*d != 'z' && *d != 'Z') {
		do { ++*d; } while (!isALPHA(*d));
		return;
	    }
	    *(d--) -= 'z' - 'a';
#else
	    ++*d;
	    if (isALPHA(*d))
		return;
	    *(d--) -= 'z' - 'a' + 1;
#endif
	}
    }
    /* oh,oh, the number grew */
    SvGROW(sv, SvCUR(sv) + 2);
    SvCUR_set(sv, SvCUR(sv) + 1);
    for (d = SvPVX(sv) + SvCUR(sv); d > SvPVX_const(sv); d--)
	*d = d[-1];
    if (isDIGIT(d[1]))
	*d = '1';
    else
	*d = d[1];
}

/*
=for apidoc sv_dec

Auto-decrement of the value in the SV, doing string to numeric conversion
if necessary. Handles 'get' magic.

=cut
*/

void
Perl_sv_dec(pTHX_ register SV *sv)
{
    int flags;

    if (!sv)
	return;
    SvGETMAGIC(sv);
    if (SvTHINKFIRST(sv)) {
	if (SvREADONLY(sv) && SvFAKE(sv))
	    sv_force_normal(sv);
	if (SvREADONLY(sv)) {
	    if (IN_PERL_RUNTIME)
		Perl_croak(aTHX_ "%s", PL_no_modify);
	}
	if (SvROK(sv)) {
	    IV i;
	    if (SvAMAGIC(sv) && AMG_CALLun(sv,dec))
		return;
	    i = PTR2IV(SvRV(sv));
	    sv_unref(sv);
	    sv_setiv(sv, i);
	}
    }
    /* Unlike sv_inc we don't have to worry about string-never-numbers
       and keeping them magic. But we mustn't warn on punting */
    flags = SvFLAGS(sv);
    if ((flags & SVf_IOK) || ((flags & (SVp_IOK | SVp_NOK)) == SVp_IOK)) {
	/* It's publicly an integer, or privately an integer-not-float */
#ifdef PERL_PRESERVE_IVUV
      oops_its_int:
#endif
	if (SvIsUV(sv)) {
	    if (SvUVX(sv) == 0) {
		(void)SvIOK_only(sv);
		SvIV_set(sv, -1);
	    }
	    else {
		(void)SvIOK_only_UV(sv);
		SvUV_set(sv, SvUVX(sv) - 1);
	    }	
	} else {
	    if (SvIVX(sv) == IV_MIN)
		sv_setnv(sv, (NV)IV_MIN - 1.0);
	    else {
		(void)SvIOK_only(sv);
		SvIV_set(sv, SvIVX(sv) - 1);
	    }	
	}
	return;
    }
    if (flags & SVp_NOK) {
        SvNV_set(sv, SvNVX(sv) - 1.0);
	(void)SvNOK_only(sv);
	return;
    }
    if (!(flags & SVp_POK)) {
	if ((flags & SVTYPEMASK) < SVt_PVIV)
	    sv_upgrade(sv, ((flags & SVTYPEMASK) > SVt_IV) ? SVt_PVIV : SVt_IV);
	SvIV_set(sv, -1);
	(void)SvIOK_only(sv);
	return;
    }
#ifdef PERL_PRESERVE_IVUV
    {
	const int numtype = grok_number(SvPVX_const(sv), SvCUR(sv), NULL);
	if (numtype && !(numtype & IS_NUMBER_INFINITY)) {
	    /* Need to try really hard to see if it's an integer.
	       9.22337203685478e+18 is an integer.
	       but "9.22337203685478e+18" + 0 is UV=9223372036854779904
	       so $a="9.22337203685478e+18"; $a+0; $a--
	       needs to be the same as $a="9.22337203685478e+18"; $a--
	       or we go insane. */
	
	    (void) sv_2iv(sv);
	    if (SvIOK(sv))
		goto oops_its_int;

	    /* sv_2iv *should* have made this an NV */
	    if (flags & SVp_NOK) {
		(void)SvNOK_only(sv);
                SvNV_set(sv, SvNVX(sv) - 1.0);
		return;
	    }
	    /* I don't think we can get here. Maybe I should assert this
	       And if we do get here I suspect that sv_setnv will croak. NWC
	       Fall through. */
#if defined(USE_LONG_DOUBLE)
	    DEBUG_c(PerlIO_printf(Perl_debug_log,"sv_dec punt failed to convert '%s' to IOK or NOKp, UV=0x%"UVxf" NV=%"PERL_PRIgldbl"\n",
				  SvPVX_const(sv), SvIVX(sv), SvNVX(sv)));
#else
	    DEBUG_c(PerlIO_printf(Perl_debug_log,"sv_dec punt failed to convert '%s' to IOK or NOKp, UV=0x%"UVxf" NV=%"NVgf"\n",
				  SvPVX_const(sv), SvIVX(sv), SvNVX(sv)));
#endif
	}
    }
#endif /* PERL_PRESERVE_IVUV */
    sv_setnv(sv,Atof(SvPVX_const(sv)) - 1.0);	/* punt */
}

/*
=for apidoc sv_mortalcopy

Creates a new SV which is a copy of the original SV (using C<sv_setsv>).
The new SV is marked as mortal. It will be destroyed "soon", either by an
explicit call to FREETMPS, or by an implicit call at places such as
statement boundaries.  See also C<sv_newmortal> and C<sv_2mortal>.

=cut
*/

/* Make a string that will exist for the duration of the expression
 * evaluation.  Actually, it may have to last longer than that, but
 * hopefully we won't free it until it has been assigned to a
 * permanent location. */

SV *
Perl_sv_mortalcopy(pTHX_ SV *oldstr)
{
    register SV *sv;

    new_SV(sv);
    sv_setsv(sv,oldstr);
    EXTEND_MORTAL(1);
    PL_tmps_stack[++PL_tmps_ix] = sv;
    SvTEMP_on(sv);
    return sv;
}

/*
=for apidoc sv_newmortal

Creates a new null SV which is mortal.  The reference count of the SV is
set to 1. It will be destroyed "soon", either by an explicit call to
FREETMPS, or by an implicit call at places such as statement boundaries.
See also C<sv_mortalcopy> and C<sv_2mortal>.

=cut
*/

SV *
Perl_sv_newmortal(pTHX)
{
    register SV *sv;

    new_SV(sv);
    SvFLAGS(sv) = SVs_TEMP;
    EXTEND_MORTAL(1);
    PL_tmps_stack[++PL_tmps_ix] = sv;
    return sv;
}


/*
=for apidoc newSVpvn_flags

Creates a new SV and copies a string into it.  The reference count for the
SV is set to 1.  Note that if C<len> is zero, Perl will create a zero length
string.  You are responsible for ensuring that the source string is at least
C<len> bytes long.  If the C<s> argument is NULL the new SV will be undefined.
Currently the only flag bits accepted are C<SVf_UTF8> and C<SVs_TEMP>.
If C<SVs_TEMP> is set, then C<sv2mortal()> is called on the result before
returning. If C<SVf_UTF8> is set, then it will be set on the new SV.
C<newSVpvn_utf8()> is a convenience wrapper for this function, defined as

    #define newSVpvn_utf8(s, len, u)			\
	newSVpvn_flags((s), (len), (u) ? SVf_UTF8 : 0)

=cut
*/

SV *
Perl_newSVpvn_flags(pTHX_ const char *s, STRLEN len, U32 flags)
{
    register SV *sv;

    /* All the flags we don't support must be zero.
       And we're new code so I'm going to assert this from the start.  */
    assert(!(flags & ~(SVf_UTF8|SVs_TEMP)));
    new_SV(sv);
    sv_setpvn(sv,s,len);
    SvFLAGS(sv) |= (flags & SVf_UTF8);
    return (flags & SVs_TEMP) ? sv_2mortal(sv) : sv;
}

/*
=for apidoc sv_2mortal

Marks an existing SV as mortal.  The SV will be destroyed "soon", either
by an explicit call to FREETMPS, or by an implicit call at places such as
statement boundaries.  SvTEMP() is turned on which means that the SV's
string buffer can be "stolen" if this SV is copied. See also C<sv_newmortal>
and C<sv_mortalcopy>.

=cut
*/

SV *
Perl_sv_2mortal(pTHX_ register SV *sv)
{
    if (!sv)
	return NULL;
    if (SvREADONLY(sv) && SvIMMORTAL(sv))
	return sv;
    EXTEND_MORTAL(1);
    PL_tmps_stack[++PL_tmps_ix] = sv;
    SvTEMP_on(sv);
    return sv;
}

/*
=for apidoc newSVpv

Creates a new SV and copies a string into it.  The reference count for the
SV is set to 1.  If C<len> is zero, Perl will compute the length using
strlen().  For efficiency, consider using C<newSVpvn> instead.

=cut
*/

SV *
Perl_newSVpv(pTHX_ const char *s, STRLEN len)
{
    register SV *sv;

    new_SV(sv);
    sv_setpvn(sv, s, len || s == NULL ? len : strlen(s));
    return sv;
}

/*
=for apidoc newSVpvn

Creates a new SV and copies a string into it.  The reference count for the
SV is set to 1.  Note that if C<len> is zero, Perl will create a zero length
string.  You are responsible for ensuring that the source string is at least
C<len> bytes long.  If the C<s> argument is NULL the new SV will be undefined.

=cut
*/

SV *
Perl_newSVpvn(pTHX_ const char *s, STRLEN len)
{
    register SV *sv;

    new_SV(sv);
    sv_setpvn(sv,s,len);
    return sv;
}

/*
=for apidoc newSVhek

Creates a new SV from the hash key structure.  It will generate scalars that
point to the shared string table where possible. Returns a new (undefined)
SV if the hek is NULL.

=cut
*/

SV *
Perl_newSVhek(pTHX_ const HEK *hek)
{
    if (!hek) {
	SV *sv;

	new_SV(sv);
	return sv;
    }

    if (HEK_LEN(hek) == HEf_SVKEY) {
	return newSVsv(*(SV**)HEK_KEY(hek));
    } else {
	const int flags = HEK_FLAGS(hek);
	if (flags & HVhek_WASUTF8) {
	    /* Trouble :-)
	       Andreas would like keys he put in as utf8 to come back as utf8
	    */
	    STRLEN utf8_len = HEK_LEN(hek);
	    const U8 *as_utf8 = bytes_to_utf8 ((U8*)HEK_KEY(hek), &utf8_len);
	    SV * const sv = newSVpvn ((const char*)as_utf8, utf8_len);

	    SvUTF8_on (sv);
	    Safefree (as_utf8); /* bytes_to_utf8() allocates a new string */
	    return sv;
	} else if (flags & (HVhek_REHASH|HVhek_UNSHARED)) {
	    /* We don't have a pointer to the hv, so we have to replicate the
	       flag into every HEK. This hv is using custom a hasing
	       algorithm. Hence we can't return a shared string scalar, as
	       that would contain the (wrong) hash value, and might get passed
	       into an hv routine with a regular hash.
	       Similarly, a hash that isn't using shared hash keys has to have
	       the flag in every key so that we know not to try to call
	       share_hek_kek on it.  */

	    SV * const sv = newSVpvn (HEK_KEY(hek), HEK_LEN(hek));
	    if (HEK_UTF8(hek))
		SvUTF8_on (sv);
	    return sv;
	}
	/* This will be overwhelminly the most common case.  */
	return newSVpvn_share(HEK_KEY(hek),
			      (HEK_UTF8(hek) ? -HEK_LEN(hek) : HEK_LEN(hek)),
			      HEK_HASH(hek));
    }
}

/*
=for apidoc newSVpvn_share

Creates a new SV with its SvPVX_const pointing to a shared string in the string
table. If the string does not already exist in the table, it is created
first.  Turns on READONLY and FAKE. If the C<hash> parameter is non-zero, that
value is used; otherwise the hash is computed. The string's hash can be later
be retrieved from the SV with the C<SvSHARED_HASH()> macro. The idea here is
that as the string table is used for shared hash keys these strings will have
SvPVX_const == HeKEY and hash lookup will avoid string compare.

=cut
*/

SV *
Perl_newSVpvn_share(pTHX_ const char *src, I32 len, U32 hash)
{
    register SV *sv;
    bool is_utf8 = FALSE;
    const char *const orig_src = src;

    if (len < 0) {
	STRLEN tmplen = -len;
        is_utf8 = TRUE;
	/* See the note in hv.c:hv_fetch() --jhi */
	src = (char*)bytes_from_utf8((U8*)src, &tmplen, &is_utf8);
	len = tmplen;
    }
    if (!hash)
	PERL_HASH(hash, src, len);
    new_SV(sv);
    sv_upgrade(sv, SVt_PVIV);
    SvPV_set(sv, sharepvn(src, is_utf8?-len:len, hash));
    SvCUR_set(sv, len);
    SvUV_set(sv, hash);
    SvLEN_set(sv, 0);
    SvREADONLY_on(sv);
    SvFAKE_on(sv);
    SvPOK_on(sv);
    if (is_utf8)
        SvUTF8_on(sv);
    if (src != orig_src)
	Safefree(src);
    return sv;
}


#if defined(PERL_IMPLICIT_CONTEXT)

/* pTHX_ magic can't cope with varargs, so this is a no-context
 * version of the main function, (which may itself be aliased to us).
 * Don't access this version directly.
 */

SV *
Perl_newSVpvf_nocontext(const char* pat, ...)
{
    dTHX;
    register SV *sv;
    va_list args;
    va_start(args, pat);
    sv = vnewSVpvf(pat, &args);
    va_end(args);
    return sv;
}
#endif

/*
=for apidoc newSVpvf

Creates a new SV and initializes it with the string formatted like
C<sprintf>.

=cut
*/

SV *
Perl_newSVpvf(pTHX_ const char* pat, ...)
{
    register SV *sv;
    va_list args;
    va_start(args, pat);
    sv = vnewSVpvf(pat, &args);
    va_end(args);
    return sv;
}

/* backend for newSVpvf() and newSVpvf_nocontext() */

SV *
Perl_vnewSVpvf(pTHX_ const char* pat, va_list* args)
{
    register SV *sv;
    new_SV(sv);
    sv_vsetpvfn(sv, pat, strlen(pat), args, NULL, 0, NULL);
    return sv;
}

/*
=for apidoc newSVnv

Creates a new SV and copies a floating point value into it.
The reference count for the SV is set to 1.

=cut
*/

SV *
Perl_newSVnv(pTHX_ NV n)
{
    register SV *sv;

    new_SV(sv);
    sv_setnv(sv,n);
    return sv;
}

/*
=for apidoc newSViv

Creates a new SV and copies an integer into it.  The reference count for the
SV is set to 1.

=cut
*/

SV *
Perl_newSViv(pTHX_ IV i)
{
    register SV *sv;

    new_SV(sv);
    sv_setiv(sv,i);
    return sv;
}

/*
=for apidoc newSVuv

Creates a new SV and copies an unsigned integer into it.
The reference count for the SV is set to 1.

=cut
*/

SV *
Perl_newSVuv(pTHX_ UV u)
{
    register SV *sv;

    new_SV(sv);
    sv_setuv(sv,u);
    return sv;
}

/*
=for apidoc newSV_type

Creates a new SV, of the type specified.  The reference count for the new SV
is set to 1.

=cut
*/

SV *
Perl_newSV_type(pTHX_ svtype type)
{
    register SV *sv;

    new_SV(sv);
    sv_upgrade(sv, type);
    return sv;
}

/*
=for apidoc newRV_noinc

Creates an RV wrapper for an SV.  The reference count for the original
SV is B<not> incremented.

=cut
*/

SV *
Perl_newRV_noinc(pTHX_ SV *tmpRef)
{
    register SV *sv = newSV_type(SVt_RV);
    SvTEMP_off(tmpRef);
    SvRV_set(sv, tmpRef);
    SvROK_on(sv);
    return sv;
}

/* newRV_inc is the official function name to use now.
 * newRV_inc is in fact #defined to newRV in sv.h
 */

SV *
Perl_newRV(pTHX_ SV *sv)
{
    return newRV_noinc(SvREFCNT_inc_simple_NN(sv));
}

/*
=for apidoc newSVsv

Creates a new SV which is an exact duplicate of the original SV.
(Uses C<sv_setsv>).

=cut
*/

SV *
Perl_newSVsv(pTHX_ register SV *old)
{
    register SV *sv;

    if (!old)
	return NULL;
    if (SvTYPE(old) == SVTYPEMASK) {
        if (ckWARN_d(WARN_INTERNAL))
	    Perl_warner(aTHX_ packWARN(WARN_INTERNAL), "semi-panic: attempt to dup freed string");
	return NULL;
    }
    new_SV(sv);
    /* SV_GMAGIC is the default for sv_setv()
       SV_NOSTEAL prevents TEMP buffers being, well, stolen, and saves games
       with SvTEMP_off and SvTEMP_on round a call to sv_setsv.  */
    sv_setsv_flags(sv, old, SV_GMAGIC | SV_NOSTEAL);
    return sv;
}

/*
=for apidoc sv_reset

Underlying implementation for the C<reset> Perl function.
Note that the perl-level function is vaguely deprecated.

=cut
*/

void
Perl_sv_reset(pTHX_ register char *s, HV *stash)
{
    register PMOP *pm;
    char todo[PERL_UCHAR_MAX+1];

    if (!stash)
	return;

    if (!*s) {		/* reset ?? searches */
	for (pm = HvPMROOT(stash); pm; pm = pm->op_pmnext) {
	    pm->op_pmdynflags &= ~PMdf_USED;
	}
	return;
    }

    /* reset variables */

    if (!HvARRAY(stash))
	return;

    Zero(todo, 256, char);
    while (*s) {
	I32 max;
	I32 i = (unsigned char)*s;
	if (s[1] == '-') {
	    s += 2;
	}
	max = (unsigned char)*s++;
	for ( ; i <= max; i++) {
	    todo[i] = 1;
	}
	for (i = 0; i <= (I32) HvMAX(stash); i++) {
	    HE *entry;
	    for (entry = HvARRAY(stash)[i];
		 entry;
		 entry = HeNEXT(entry))
	    {
		register GV *gv;
		register SV *sv;

		if (!todo[(U8)*HeKEY(entry)])
		    continue;
		gv = (GV*)HeVAL(entry);
		sv = GvSV(gv);
		if (sv) {
		    if (SvTHINKFIRST(sv)) {
			if (!SvREADONLY(sv) && SvROK(sv))
			    sv_unref(sv);
			/* XXX Is this continue a bug? Why should THINKFIRST
			   exempt us from resetting arrays and hashes?  */
			continue;
		    }
		    SvOK_off(sv);
		    if (SvTYPE(sv) >= SVt_PV) {
			SvCUR_set(sv, 0);
			if (SvPVX_const(sv) != NULL)
			    *SvPVX(sv) = '\0';
			SvTAINT(sv);
		    }
		}
		if (GvAV(gv)) {
		    av_clear(GvAV(gv));
		}
		if (GvHV(gv) && !HvNAME_get(GvHV(gv))) {
#if defined(VMS)
		    Perl_die(aTHX_ "Can't reset %%ENV on this system");
#else /* ! VMS */
		    hv_clear(GvHV(gv));
#  if defined(USE_ENVIRON_ARRAY)
		    if (gv == PL_envgv)
		        my_clearenv();
#  endif /* USE_ENVIRON_ARRAY */
#endif /* VMS */
		}
	    }
	}
    }
}

/*
=for apidoc sv_2io

Using various gambits, try to get an IO from an SV: the IO slot if its a
GV; or the recursive result if we're an RV; or the IO slot of the symbol
named after the PV if we're a string.

=cut
*/

IO*
Perl_sv_2io(pTHX_ SV *sv)
{
    IO* io;
    GV* gv;

    switch (SvTYPE(sv)) {
    case SVt_PVIO:
	io = (IO*)sv;
	break;
    case SVt_PVGV:
	if (isGV_with_GP(sv)) {
	    gv = (GV*)sv;
	    io = GvIO(gv);
	    if (!io)
		Perl_croak(aTHX_ "Bad filehandle: %s", GvNAME(gv));
	    break;
	}
	/* FALL THROUGH */
    default:
	if (!SvOK(sv))
	    Perl_croak(aTHX_ PL_no_usym, "filehandle");
	if (SvROK(sv))
	    return sv_2io(SvRV(sv));
	gv = gv_fetchsv(sv, 0, SVt_PVIO);
	if (gv)
	    io = GvIO(gv);
	else
	    io = 0;
	if (!io)
	    Perl_croak(aTHX_ "Bad filehandle: %"SVf, (void*)sv);
	break;
    }
    return io;
}

/*
=for apidoc sv_2cv

Using various gambits, try to get a CV from an SV; in addition, try if
possible to set C<*st> and C<*gvp> to the stash and GV associated with it.
The flags in C<lref> are passed to sv_fetchsv.

=cut
*/

CV *
Perl_sv_2cv(pTHX_ SV *sv, HV **st, GV **gvp, I32 lref)
{
    GV *gv = NULL;
    CV *cv = Nullcv;

    if (!sv) {
	*st = NULL;
	*gvp = NULL;
	return NULL;
    }
    switch (SvTYPE(sv)) {
    case SVt_PVCV:
	*st = CvSTASH(sv);
	*gvp = NULL;
	return (CV*)sv;
    case SVt_PVHV:
    case SVt_PVAV:
	*st = NULL;
	*gvp = NULL;
	return Nullcv;
    case SVt_PVGV:
	if (isGV_with_GP(sv)) {
	    gv = (GV*)sv;
	    *gvp = gv;
	    *st = GvESTASH(gv);
	    goto fix_gv;
	}
	/* FALL THROUGH */

    default:
	if (SvROK(sv)) {
	    SV * const *sp = &sv;	/* Used in tryAMAGICunDEREF macro. */
	    SvGETMAGIC(sv);
	    tryAMAGICunDEREF(to_cv);

	    sv = SvRV(sv);
	    if (SvTYPE(sv) == SVt_PVCV) {
		cv = (CV*)sv;
		*gvp = NULL;
		*st = CvSTASH(cv);
		return cv;
	    }
	    else if(isGV_with_GP(sv))
		gv = (GV*)sv;
	    else
		Perl_croak(aTHX_ "Not a subroutine reference");
	}
	else if (isGV_with_GP(sv)) {
	    SvGETMAGIC(sv);
	    gv = (GV*)sv;
	}
	else
	    gv = gv_fetchsv(sv, lref, SVt_PVCV); /* Calls get magic */
	*gvp = gv;
	if (!gv) {
	    *st = NULL;
	    return Nullcv;
	}
	/* Some flags to gv_fetchsv mean don't really create the GV  */
	if (!isGV_with_GP(gv)) {
	    *st = NULL;
	    return NULL;
	}
	*st = GvESTASH(gv);
    fix_gv:
	if (lref && !GvCVu(gv)) {
	    SV *tmpsv;
	    ENTER;
	    tmpsv = newSV(0);
	    gv_efullname3(tmpsv, gv, NULL);
	    /* XXX this is probably not what they think they're getting.
	     * It has the same effect as "sub name;", i.e. just a forward
	     * declaration! */
	    newSUB(start_subparse(FALSE, 0),
		   newSVOP(OP_CONST, 0, tmpsv),
		   NULL, NULL);
	    LEAVE;
	    if (!GvCVu(gv))
		Perl_croak(aTHX_ "Unable to create sub named \"%"SVf"\"",
			   (void*)sv);
	}
	return GvCVu(gv);
    }
}

/*
=for apidoc sv_true

Returns true if the SV has a true value by Perl's rules.
Use the C<SvTRUE> macro instead, which may call C<sv_true()> or may
instead use an in-line version.

=cut
*/

I32
Perl_sv_true(pTHX_ register SV *sv)
{
    if (!sv)
	return 0;
    if (SvPOK(sv)) {
	register const XPV* const tXpv = (XPV*)SvANY(sv);
	if (tXpv &&
		(tXpv->xpv_cur > 1 ||
		(tXpv->xpv_cur && *tXpv->xpv_pv != '0')))
	    return 1;
	else
	    return 0;
    }
    else {
	if (SvIOK(sv))
	    return SvIVX(sv) != 0;
	else {
	    if (SvNOK(sv))
		return SvNVX(sv) != 0.0;
	    else
		return sv_2bool(sv);
	}
    }
}

/*
=for apidoc sv_pvn_force

Get a sensible string out of the SV somehow.
A private implementation of the C<SvPV_force> macro for compilers which
can't cope with complex macro expressions. Always use the macro instead.

=for apidoc sv_pvn_force_flags

Get a sensible string out of the SV somehow.
If C<flags> has C<SV_GMAGIC> bit set, will C<mg_get> on C<sv> if
appropriate, else not. C<sv_pvn_force> and C<sv_pvn_force_nomg> are
implemented in terms of this function.
You normally want to use the various wrapper macros instead: see
C<SvPV_force> and C<SvPV_force_nomg>

=cut
*/

char *
Perl_sv_pvn_force_flags(pTHX_ SV *sv, STRLEN *lp, I32 flags)
{

    if (SvTHINKFIRST(sv) && !SvROK(sv))
	sv_force_normal(sv);

    if (SvPOK(sv)) {
	if (lp)
	    *lp = SvCUR(sv);
    }
    else {
	char *s;
	STRLEN len;
 
	if (SvREADONLY(sv) && !(flags & SV_MUTABLE_RETURN)) {
	    const char * const ref = sv_reftype(sv,0);
	    if (PL_op)
		Perl_croak(aTHX_ "Can't coerce readonly %s to string in %s",
			   ref, OP_NAME(PL_op));
	    else
		Perl_croak(aTHX_ "Can't coerce readonly %s to string", ref);
	}
	if (SvTYPE(sv) > SVt_PVLV && SvTYPE(sv) != SVt_PVFM)
	    Perl_croak(aTHX_ "Can't coerce %s to string in %s", sv_reftype(sv,0),
		OP_NAME(PL_op));
	s = sv_2pv_flags(sv, &len, flags);
	if (lp)
	    *lp = len;

	if (s != SvPVX_const(sv)) {	/* Almost, but not quite, sv_setpvn() */
	    if (SvROK(sv))
		sv_unref(sv);
	    (void)SvUPGRADE(sv, SVt_PV);		/* Never FALSE */
	    SvGROW(sv, len + 1);
	    Move(s,SvPVX(sv),len,char);
	    SvCUR_set(sv, len);
	    SvPVX(sv)[len] = '\0';
	}
	if (!SvPOK(sv)) {
	    SvPOK_on(sv);		/* validate pointer */
	    SvTAINT(sv);
	    DEBUG_c(PerlIO_printf(Perl_debug_log, "0x%"UVxf" 2pv(%s)\n",
				  PTR2UV(sv),SvPVX_const(sv)));
	}
    }
    return SvPVX_mutable(sv);
}

/*
=for apidoc sv_pvbyten_force

The backend for the C<SvPVbytex_force> macro. Always use the macro instead.

=cut
*/

char *
Perl_sv_pvbyten_force(pTHX_ SV *sv, STRLEN *lp)
{
    sv_pvn_force(sv,lp);
    sv_utf8_downgrade(sv,0);
    *lp = SvCUR(sv);
    return SvPVX(sv);
}

/*
=for apidoc sv_pvutf8n_force

The backend for the C<SvPVutf8x_force> macro. Always use the macro instead.

=cut
*/

char *
Perl_sv_pvutf8n_force(pTHX_ SV *sv, STRLEN *lp)
{
    sv_pvn_force(sv,lp);
    sv_utf8_upgrade(sv);
    *lp = SvCUR(sv);
    return SvPVX(sv);
}

/*
=for apidoc sv_reftype

Returns a string describing what the SV is a reference to.

=cut
*/

char *
Perl_sv_reftype(pTHX_ SV *sv, int ob)
{
    /* The fact that I don't need to downcast to char * everywhere, only in ?:
       inside return suggests a const propagation bug in g++.  */
    if (ob && SvOBJECT(sv)) {
	char * const name = HvNAME_get(SvSTASH(sv));
	return name ? name : (char *) "__ANON__";
    }
    else {
	switch (SvTYPE(sv)) {
	case SVt_NULL:
	case SVt_IV:
	case SVt_NV:
	case SVt_RV:
	case SVt_PV:
	case SVt_PVIV:
	case SVt_PVNV:
	case SVt_PVMG:
	case SVt_PVBM:
				if (SvROK(sv))
				    return "REF";
				else
				    return "SCALAR";

	case SVt_PVLV:		return (char *)  (SvROK(sv) ? "REF"
				/* tied lvalues should appear to be
				 * scalars for backwards compatitbility */
				: (LvTYPE(sv) == 't' || LvTYPE(sv) == 'T')
				    ? "SCALAR" : "LVALUE");
	case SVt_PVAV:		return "ARRAY";
	case SVt_PVHV:		return "HASH";
	case SVt_PVCV:		return "CODE";
	case SVt_PVGV:		return (char *) (isGV_with_GP(sv)
				    ? "GLOB" : "SCALAR");
	case SVt_PVFM:		return "FORMAT";
	case SVt_PVIO:		return "IO";
	default:		return "UNKNOWN";
	}
    }
}

/*
=for apidoc sv_isobject

Returns a boolean indicating whether the SV is an RV pointing to a blessed
object.  If the SV is not an RV, or if the object is not blessed, then this
will return false.

=cut
*/

int
Perl_sv_isobject(pTHX_ SV *sv)
{
    if (!sv)
	return 0;
    SvGETMAGIC(sv);
    if (!SvROK(sv))
	return 0;
    sv = (SV*)SvRV(sv);
    if (!SvOBJECT(sv))
	return 0;
    return 1;
}

/*
=for apidoc sv_isa

Returns a boolean indicating whether the SV is blessed into the specified
class.  This does not check for subtypes; use C<sv_derived_from> to verify
an inheritance relationship.

=cut
*/

int
Perl_sv_isa(pTHX_ SV *sv, const char *name)
{
    const char *hvname;
    if (!sv)
	return 0;
    SvGETMAGIC(sv);
    if (!SvROK(sv))
	return 0;
    sv = (SV*)SvRV(sv);
    if (!SvOBJECT(sv))
	return 0;
    hvname = HvNAME_get(SvSTASH(sv));
    if (!hvname)
	return 0;

    return strEQ(hvname, name);
}

/*
=for apidoc newSVrv

Creates a new SV for the RV, C<rv>, to point to.  If C<rv> is not an RV then
it will be upgraded to one.  If C<classname> is non-null then the new SV will
be blessed in the specified package.  The new SV is returned and its
reference count is 1.

=cut
*/

SV*
Perl_newSVrv(pTHX_ SV *rv, const char *classname)
{
    SV *sv;

    new_SV(sv);

    SV_CHECK_THINKFIRST(rv);
    (void)SvAMAGIC_off(rv);

    if (SvTYPE(rv) >= SVt_PVMG) {
	const U32 refcnt = SvREFCNT(rv);
	SvREFCNT(rv) = 0;
	sv_clear(rv);
	SvFLAGS(rv) = 0;
	SvREFCNT(rv) = refcnt;

	sv_upgrade(rv, SVt_RV);
    } else if (SvROK(rv)) {
	SvREFCNT_dec(SvRV(rv));
    } else if (SvTYPE(rv) < SVt_RV)
	sv_upgrade(rv, SVt_RV);
    else if (SvTYPE(rv) > SVt_RV) {
	SvPV_free(rv);
	SvCUR_set(rv, 0);
	SvLEN_set(rv, 0);
    }

    SvOK_off(rv);
    SvRV_set(rv, sv);
    SvROK_on(rv);

    if (classname) {
	HV* const stash = gv_stashpv(classname, GV_ADD);
	(void)sv_bless(rv, stash);
    }
    return sv;
}

/*
=for apidoc sv_setref_pv

Copies a pointer into a new SV, optionally blessing the SV.  The C<rv>
argument will be upgraded to an RV.  That RV will be modified to point to
the new SV.  If the C<pv> argument is NULL then C<PL_sv_undef> will be placed
into the SV.  The C<classname> argument indicates the package for the
blessing.  Set C<classname> to C<NULL> to avoid the blessing.  The new SV
will have a reference count of 1, and the RV will be returned.

Do not use with other Perl types such as HV, AV, SV, CV, because those
objects will become corrupted by the pointer copy process.

Note that C<sv_setref_pvn> copies the string while this copies the pointer.

=cut
*/

SV*
Perl_sv_setref_pv(pTHX_ SV *rv, const char *classname, void *pv)
{
    if (!pv) {
	sv_setsv(rv, &PL_sv_undef);
	SvSETMAGIC(rv);
    }
    else
	sv_setiv(newSVrv(rv,classname), PTR2IV(pv));
    return rv;
}

/*
=for apidoc sv_setref_iv

Copies an integer into a new SV, optionally blessing the SV.  The C<rv>
argument will be upgraded to an RV.  That RV will be modified to point to
the new SV.  The C<classname> argument indicates the package for the
blessing.  Set C<classname> to C<NULL> to avoid the blessing.  The new SV
will have a reference count of 1, and the RV will be returned.

=cut
*/

SV*
Perl_sv_setref_iv(pTHX_ SV *rv, const char *classname, IV iv)
{
    sv_setiv(newSVrv(rv,classname), iv);
    return rv;
}

/*
=for apidoc sv_setref_uv

Copies an unsigned integer into a new SV, optionally blessing the SV.  The C<rv>
argument will be upgraded to an RV.  That RV will be modified to point to
the new SV.  The C<classname> argument indicates the package for the
blessing.  Set C<classname> to C<NULL> to avoid the blessing.  The new SV
will have a reference count of 1, and the RV will be returned.

=cut
*/

SV*
Perl_sv_setref_uv(pTHX_ SV *rv, const char *classname, UV uv)
{
    sv_setuv(newSVrv(rv,classname), uv);
    return rv;
}

/*
=for apidoc sv_setref_nv

Copies a double into a new SV, optionally blessing the SV.  The C<rv>
argument will be upgraded to an RV.  That RV will be modified to point to
the new SV.  The C<classname> argument indicates the package for the
blessing.  Set C<classname> to C<NULL> to avoid the blessing.  The new SV
will have a reference count of 1, and the RV will be returned.

=cut
*/

SV*
Perl_sv_setref_nv(pTHX_ SV *rv, const char *classname, NV nv)
{
    sv_setnv(newSVrv(rv,classname), nv);
    return rv;
}

/*
=for apidoc sv_setref_pvn

Copies a string into a new SV, optionally blessing the SV.  The length of the
string must be specified with C<n>.  The C<rv> argument will be upgraded to
an RV.  That RV will be modified to point to the new SV.  The C<classname>
argument indicates the package for the blessing.  Set C<classname> to
C<NULL> to avoid the blessing.  The new SV will have a reference count
of 1, and the RV will be returned.

Note that C<sv_setref_pv> copies the pointer while this copies the string.

=cut
*/

SV*
Perl_sv_setref_pvn(pTHX_ SV *rv, const char *classname, char *pv, STRLEN n)
{
    sv_setpvn(newSVrv(rv,classname), pv, n);
    return rv;
}

/* For this subroutine, for each level of recursion, check the pad for either
   direct pointers to the target object, or perl references to it.
   We assume that arrays and hashes (and deeper structures) in lexicals
   rarely point to objects.  */
static U32
S_process_sub(pTHX_ CV *const current_sub, U32 how_many_in_pad,
	      const SV *const target, SV *const rv, const bool on) {
    AV *const padlist = CvPADLIST(current_sub);
    long depth = CvDEPTH(current_sub);

    while (depth > 0) {
	AV *const curpad = (AV*) AvARRAY(padlist)[depth];
	SV ** const start = AvARRAY(curpad);
	SV ** end = start + AvFILLp(curpad);

	while (end >= start) {
	    SV *const sv = *end--;
	    if (sv == target) {
		if (--how_many_in_pad == 0) {
		    /* We have found them all.  */
		    return 0;
		}
	    } else if ((sv->sv_flags & SVf_ROK) == SVf_ROK
		       && SvRV(sv) == target
		       && sv != rv) {
		if (on)
		    SvAMAGIC_on(sv);
		else
		    SvAMAGIC_off(sv);
		if (--how_many_in_pad == 0) {
		    /* We have found them all.  */
		    return 0;
		}
	    }
	}
	--depth;
    };
    return how_many_in_pad;
}


/* This is a hack to cope with reblessing from class with overloading magic to
   one without (or the other way).  Search for every reference pointing to the
   object.  Can't use S_visit() because we would need to pass a parameter to
   our function.  */
static void
S_reset_amagic(pTHX_ SV *rv, const bool on) {
    /* It is assumed that you've already turned magic on/off on rv  */
    SV* sva;
    SV *const target = SvRV(rv);
    /* Less 1 for the reference we've already dealt with.  */
    U32 how_many = SvREFCNT(target) - 1;
    MAGIC *mg;

    if (SvMAGICAL(target) && (mg = mg_find(target, PERL_MAGIC_backref))) {
	/* Back referneces also need to be found, but aren't part of the
	   target's reference count.  */
	how_many += 1 + av_len((AV*)mg->mg_obj);
    }

    if (!how_many) {
	/* There was only 1 reference to this object.  */
	return;
    }

    /* References to objects may be via RVs, or anything else that can hold
       a reference count (AVs, HVs, GVs, and arbitrary C code)
       Object-ness can only be accessed via true RVs, including the overloading
       part of object-ness, so for that part it doesn't matter that the
       overloading flag (pre 5.10) is on the reference. But the overloading
       mechanism itself checks the referent, the object itself, hence they
       can get out of sync.

       We'll assume two common cases - either we got here through a real
       reference, and the referent is a value in the pad of the current
       subroutine (hence a reference count of 2 or more), during construction
       of the reference, or that there is a second (or more) reference to
       the object (but no arrays, hashes, pads, typeglobs or other things)
       pointing to it.

       Actually, need to extend that to any pad in the call chain, and any
       temporaries. Fortunately, we can do this in a way that doesn't involve
       visiting any location twice, so we don't need to keep track of what
       we've seen.

       The first case is likely to involve quite a small search.
       The second case is O(n) on the number of SVs, but we can make it
       terminate early if we find every reference is accounted for by an RV.
       [Terminating early is still O(n), but with a smaller constant.]
    */
    {
	/* So before trying the large O(n) linear search of all SVs, start by
	   seeing if we can find the other references as temporaries on the
	   stack or in the pads of the current subroutine call chain.

	   This avoids the big search for constructions such as
	   my $string = ...;
	   my $obj = bless \$string, $class;
	   which modules like URI use.  */

	U32 how_many_in_pad = how_many;

	{
	    /* Search the tmps stack */
	    I32 ix = PL_tmps_ix;

	    while (ix >= 0) {
		SV *const sv = PL_tmps_stack[ix];

		if (sv == target) {
		    if (--how_many_in_pad == 0) {
			/* We have found them all.  */
			return;
		    }
		} else if ((sv->sv_flags & SVf_ROK) == SVf_ROK
			   && SvRV(sv) == target
			   && sv != rv) {
		    if (on)
			SvAMAGIC_on(sv);
		    else
			SvAMAGIC_off(sv);
		    if (--how_many == 0) {
			/* We have found them all.  */
			return;
		    }
		}
		--ix;
	    }
	}

	{
	    /* This code is pilfered from Perl_find_runcv  */
	    PERL_SI	 *si;

	    for (si = PL_curstackinfo; si; si = si->si_prev) {
		I32 ix;
		for (ix = si->si_cxix; ix >= 0; ix--) {
		    const PERL_CONTEXT *cx = &(si->si_cxstack[ix]);
		    if (CxTYPE(cx) == CXt_SUB || CxTYPE(cx) == CXt_FORMAT) {
			CV * const cv = cx->blk_sub.cv;
			/* Process all levels of recursion the first time we
			   see a subroutine.  */
			if (cx->blk_sub.olddepth + 1 == CvDEPTH(cv)) {
			    how_many_in_pad = process_sub(cv, how_many_in_pad,
							  target, rv, on);
			    if (how_many_in_pad == 0) {
				/* We have found them all.  */
				return;
			    }
			}
		    }
		    else if (CxTYPE(cx) == CXt_EVAL && !CxTRYBLOCK(cx)) {
			how_many_in_pad
			    = process_sub(PL_compcv, how_many_in_pad, target,
					  rv, on);
			if (how_many_in_pad == 0) {
			    /* We have found them all.  */
			    return;
			}
		    }
		}
		how_many_in_pad
		    = process_sub(PL_main_cv, how_many_in_pad, target, rv, on);
		if (how_many_in_pad == 0) {
		    /* We have found them all.  */
		    return;
		}
	    }
	}
    }

    /* Right, didn't find all the other references were lexicals or temporaries
       in the pad, so need to do an exhaustive search to find all references.
       It doesn't matter if we've already set the AMAGIC flag to the correct
       value on some of the other references.
    */

    for (sva = PL_sv_arenaroot; sva; sva = (SV*)SvANY(sva)) {
	register const SV * const svend = &sva[SvREFCNT(sva)];
	register SV* sv;
	for (sv = sva + 1; sv < svend; ++sv) {
	    if (SvTYPE(sv) != SVTYPEMASK
		&& (sv->sv_flags & SVf_ROK) == SVf_ROK
		&& SvREFCNT(sv)
		&& SvRV(sv) == target
		&& sv != rv) {
		if (on)
		    SvAMAGIC_on(sv);
		else
		    SvAMAGIC_off(sv);
		if (--how_many == 0) {
		    /* We have found them all.  */
		    return;
		}
	    }
	}
    }

    /* Can get here if the object happens to be lexical somewhere else, a
       global, an element in an array or hash, etc. But we will have found all
       the references.  */
}

/*
=for apidoc sv_bless

Blesses an SV into a specified package.  The SV must be an RV.  The package
must be designated by its stash (see C<gv_stashpv()>).  The reference count
of the SV is unaffected.

=cut
*/

SV*
Perl_sv_bless(pTHX_ SV *sv, HV *stash)
{
    SV *tmpRef;
    if (!SvROK(sv))
        Perl_croak(aTHX_ "Can't bless non-reference value");
    tmpRef = SvRV(sv);
    if (SvFLAGS(tmpRef) & (SVs_OBJECT|SVf_READONLY)) {
	if (SvIsCOW(tmpRef))
	    sv_force_normal_flags(tmpRef, 0);
	if (SvREADONLY(tmpRef))
	    Perl_croak(aTHX_ "%s", PL_no_modify);
	if (SvOBJECT(tmpRef)) {
	    if (SvTYPE(tmpRef) != SVt_PVIO)
		--PL_sv_objcount;
	    SvREFCNT_dec(SvSTASH(tmpRef));
	}
    }
    SvOBJECT_on(tmpRef);
    if (SvTYPE(tmpRef) != SVt_PVIO)
	++PL_sv_objcount;
    (void)SvUPGRADE(tmpRef, SVt_PVMG);
    SvSTASH_set(tmpRef, (HV*)SvREFCNT_inc_simple(stash));

    if (Gv_AMG(stash)) {
	if (!SvAMAGIC(sv)) {
	    SvAMAGIC_on(sv);
	    S_reset_amagic(aTHX_ sv, TRUE);
	}
    } else {
	if (SvAMAGIC(sv)) {
	    (void)SvAMAGIC_off(sv);
	    S_reset_amagic(aTHX_ sv, FALSE);
	}
    }

    if(SvSMAGICAL(tmpRef))
        if(mg_find(tmpRef, PERL_MAGIC_ext) || mg_find(tmpRef, PERL_MAGIC_uvar))
            mg_set(tmpRef);



    return sv;
}

/* Downgrades a PVGV to a PVMG.
 */

STATIC void
S_sv_unglob(pTHX_ SV *sv)
{
    void *xpvmg;

    assert(SvTYPE(sv) == SVt_PVGV);
    SvFAKE_off(sv);
    if (GvGP(sv))
	gp_free((GV*)sv);
    if (GvSTASH(sv)) {
	SvREFCNT_dec(GvSTASH(sv));
	GvSTASH(sv) = NULL;
    }
    sv_unmagic(sv, PERL_MAGIC_glob);
    Safefree(GvNAME(sv));
    GvMULTI_off(sv);

    /* need to keep SvANY(sv) in the right arena */
    xpvmg = new_XPVMG();
    StructCopy(SvANY(sv), xpvmg, XPVMG);
    del_XPVGV(SvANY(sv));
    SvANY(sv) = xpvmg;

    SvFLAGS(sv) &= ~SVTYPEMASK;
    SvFLAGS(sv) |= SVt_PVMG;
}

/*
=for apidoc sv_unref_flags

Unsets the RV status of the SV, and decrements the reference count of
whatever was being referenced by the RV.  This can almost be thought of
as a reversal of C<newSVrv>.  The C<cflags> argument can contain
C<SV_IMMEDIATE_UNREF> to force the reference count to be decremented
(otherwise the decrementing is conditional on the reference count being
different from one or the reference being a readonly SV).
See C<SvROK_off>.

=cut
*/

void
Perl_sv_unref_flags(pTHX_ SV *sv, U32 flags)
{
    SV const * rv = SvRV(sv);

    if (SvWEAKREF(sv)) {
    	sv_del_backref(sv);
	SvWEAKREF_off(sv);
	SvRV_set(sv, NULL);
	return;
    }
    SvRV_set(sv, NULL);
    SvROK_off(sv);
    /* You can't have a || SvREADONLY(rv) here, as $a = $$a, where $a was
       assigned to as BEGIN {$a = \"Foo"} will fail.  */
    if (SvREFCNT(rv) != 1 || (flags & SV_IMMEDIATE_UNREF))
	SvREFCNT_dec(rv);
    else /* XXX Hack, but hard to make $a=$a->[1] work otherwise */
	sv_2mortal((SV *)rv);		/* Schedule for freeing later */
}

/*
=for apidoc sv_untaint

Untaint an SV. Use C<SvTAINTED_off> instead.
=cut
*/

void
Perl_sv_untaint(pTHX_ SV *sv)
{
    if (SvTYPE(sv) >= SVt_PVMG && SvMAGIC(sv)) {
	MAGIC * const mg = mg_find(sv, PERL_MAGIC_taint);
	if (mg)
	    mg->mg_len &= ~1;
    }
}

/*
=for apidoc sv_tainted

Test an SV for taintedness. Use C<SvTAINTED> instead.
=cut
*/

bool
Perl_sv_tainted(pTHX_ SV *sv)
{
    if (SvTYPE(sv) >= SVt_PVMG && SvMAGIC(sv)) {
	const MAGIC * const mg = mg_find(sv, PERL_MAGIC_taint);
	if (mg && (mg->mg_len & 1) )
	    return TRUE;
    }
    return FALSE;
}

/*
=for apidoc sv_setpviv

Copies an integer into the given SV, also updating its string value.
Does not handle 'set' magic.  See C<sv_setpviv_mg>.

=cut
*/

void
Perl_sv_setpviv(pTHX_ SV *sv, IV iv)
{
    char buf[TYPE_CHARS(UV)];
    char *ebuf;
    char * const ptr = uiv_2buf(buf, iv, 0, 0, &ebuf);

    sv_setpvn(sv, ptr, ebuf - ptr);
}

/*
=for apidoc sv_setpviv_mg

Like C<sv_setpviv>, but also handles 'set' magic.

=cut
*/

void
Perl_sv_setpviv_mg(pTHX_ SV *sv, IV iv)
{
    sv_setpviv(sv, iv);
    SvSETMAGIC(sv);
}

#if defined(PERL_IMPLICIT_CONTEXT)

/* pTHX_ magic can't cope with varargs, so this is a no-context
 * version of the main function, (which may itself be aliased to us).
 * Don't access this version directly.
 */

void
Perl_sv_setpvf_nocontext(SV *sv, const char* pat, ...)
{
    dTHX;
    va_list args;
    va_start(args, pat);
    sv_vsetpvf(sv, pat, &args);
    va_end(args);
}

/* pTHX_ magic can't cope with varargs, so this is a no-context
 * version of the main function, (which may itself be aliased to us).
 * Don't access this version directly.
 */

void
Perl_sv_setpvf_mg_nocontext(SV *sv, const char* pat, ...)
{
    dTHX;
    va_list args;
    va_start(args, pat);
    sv_vsetpvf_mg(sv, pat, &args);
    va_end(args);
}
#endif

/*
=for apidoc sv_setpvf

Works like C<sv_catpvf> but copies the text into the SV instead of
appending it.  Does not handle 'set' magic.  See C<sv_setpvf_mg>.

=cut
*/

void
Perl_sv_setpvf(pTHX_ SV *sv, const char* pat, ...)
{
    va_list args;
    va_start(args, pat);
    sv_vsetpvf(sv, pat, &args);
    va_end(args);
}

/*
=for apidoc sv_vsetpvf

Works like C<sv_vcatpvf> but copies the text into the SV instead of
appending it.  Does not handle 'set' magic.  See C<sv_vsetpvf_mg>.

Usually used via its frontend C<sv_setpvf>.

=cut
*/

void
Perl_sv_vsetpvf(pTHX_ SV *sv, const char* pat, va_list* args)
{
    sv_vsetpvfn(sv, pat, strlen(pat), args, NULL, 0, NULL);
}

/*
=for apidoc sv_setpvf_mg

Like C<sv_setpvf>, but also handles 'set' magic.

=cut
*/

void
Perl_sv_setpvf_mg(pTHX_ SV *sv, const char* pat, ...)
{
    va_list args;
    va_start(args, pat);
    sv_vsetpvf_mg(sv, pat, &args);
    va_end(args);
}

/*
=for apidoc sv_vsetpvf_mg

Like C<sv_vsetpvf>, but also handles 'set' magic.

Usually used via its frontend C<sv_setpvf_mg>.

=cut
*/

void
Perl_sv_vsetpvf_mg(pTHX_ SV *sv, const char* pat, va_list* args)
{
    sv_vsetpvfn(sv, pat, strlen(pat), args, NULL, 0, NULL);
    SvSETMAGIC(sv);
}

#if defined(PERL_IMPLICIT_CONTEXT)

/* pTHX_ magic can't cope with varargs, so this is a no-context
 * version of the main function, (which may itself be aliased to us).
 * Don't access this version directly.
 */

void
Perl_sv_catpvf_nocontext(SV *sv, const char* pat, ...)
{
    dTHX;
    va_list args;
    va_start(args, pat);
    sv_vcatpvf(sv, pat, &args);
    va_end(args);
}

/* pTHX_ magic can't cope with varargs, so this is a no-context
 * version of the main function, (which may itself be aliased to us).
 * Don't access this version directly.
 */

void
Perl_sv_catpvf_mg_nocontext(SV *sv, const char* pat, ...)
{
    dTHX;
    va_list args;
    va_start(args, pat);
    sv_vcatpvf_mg(sv, pat, &args);
    va_end(args);
}
#endif

/*
=for apidoc sv_catpvf

Processes its arguments like C<sprintf> and appends the formatted
output to an SV.  If the appended data contains "wide" characters
(including, but not limited to, SVs with a UTF-8 PV formatted with %s,
and characters >255 formatted with %c), the original SV might get
upgraded to UTF-8.  Handles 'get' magic, but not 'set' magic.  See
C<sv_catpvf_mg>. If the original SV was UTF-8, the pattern should be
valid UTF-8; if the original SV was bytes, the pattern should be too.

=cut */

void
Perl_sv_catpvf(pTHX_ SV *sv, const char* pat, ...)
{
    va_list args;
    va_start(args, pat);
    sv_vcatpvf(sv, pat, &args);
    va_end(args);
}

/*
=for apidoc sv_vcatpvf

Processes its arguments like C<vsprintf> and appends the formatted output
to an SV.  Does not handle 'set' magic.  See C<sv_vcatpvf_mg>.

Usually used via its frontend C<sv_catpvf>.

=cut
*/

void
Perl_sv_vcatpvf(pTHX_ SV *sv, const char* pat, va_list* args)
{
    sv_vcatpvfn(sv, pat, strlen(pat), args, NULL, 0, NULL);
}

/*
=for apidoc sv_catpvf_mg

Like C<sv_catpvf>, but also handles 'set' magic.

=cut
*/

void
Perl_sv_catpvf_mg(pTHX_ SV *sv, const char* pat, ...)
{
    va_list args;
    va_start(args, pat);
    sv_vcatpvf_mg(sv, pat, &args);
    va_end(args);
}

/*
=for apidoc sv_vcatpvf_mg

Like C<sv_vcatpvf>, but also handles 'set' magic.

Usually used via its frontend C<sv_catpvf_mg>.

=cut
*/

void
Perl_sv_vcatpvf_mg(pTHX_ SV *sv, const char* pat, va_list* args)
{
    sv_vcatpvfn(sv, pat, strlen(pat), args, NULL, 0, NULL);
    SvSETMAGIC(sv);
}

/*
=for apidoc sv_vsetpvfn

Works like C<sv_vcatpvfn> but copies the text into the SV instead of
appending it.

Usually used via one of its frontends C<sv_vsetpvf> and C<sv_vsetpvf_mg>.

=cut
*/

void
Perl_sv_vsetpvfn(pTHX_ SV *sv, const char *pat, STRLEN patlen, va_list *args, SV **svargs, I32 svmax, bool *maybe_tainted)
{
    sv_setpvn(sv, "", 0);
    sv_vcatpvfn(sv, pat, patlen, args, svargs, svmax, maybe_tainted);
}

STATIC I32
S_expect_number(pTHX_ char** pattern)
{
    I32 var = 0;
    switch (**pattern) {
    case '1': case '2': case '3':
    case '4': case '5': case '6':
    case '7': case '8': case '9':
	var = *(*pattern)++ - '0';
	while (isDIGIT(**pattern)) {
	    const I32 tmp = var * 10 + (*(*pattern)++ - '0');
	    if (tmp < var)
		Perl_croak(aTHX_ "Integer overflow in format string for %s", (PL_op ? OP_NAME(PL_op) : "sv_vcatpvfn"));
	    var = tmp;
	}
    }
    return var;
}

STATIC char *
S_F0convert(NV nv, char *endbuf, STRLEN *len)
{
    const int neg = nv < 0;
    UV uv;

    if (neg)
	nv = -nv;
    if (nv < UV_MAX) {
	char *p = endbuf;
	nv += 0.5;
	uv = (UV)nv;
	if (uv & 1 && uv == nv)
	    uv--;			/* Round to even */
	do {
	    const unsigned dig = uv % 10;
	    *--p = '0' + dig;
	} while (uv /= 10);
	if (neg)
	    *--p = '-';
	*len = endbuf - p;
	return p;
    }
    return NULL;
}


/*
=for apidoc sv_vcatpvfn

Processes its arguments like C<vsprintf> and appends the formatted output
to an SV.  Uses an array of SVs if the C style variable argument list is
missing (NULL).  When running with taint checks enabled, indicates via
C<maybe_tainted> if results are untrustworthy (often due to the use of
locales).

XXX Except that it maybe_tainted is never assigned to.

Usually used via one of its frontends C<sv_vcatpvf> and C<sv_vcatpvf_mg>.

=cut
*/

/* XXX maybe_tainted is never assigned to, so the doc above is lying. */

void
Perl_sv_vcatpvfn(pTHX_ SV *sv, const char *pat, STRLEN patlen, va_list *args, SV **svargs, I32 svmax, bool *maybe_tainted)
{
    char *p;
    char *q;
    const char *patend;
    STRLEN origlen;
    I32 svix = 0;
    static const char nullstr[] = "(null)";
    SV *argsv = NULL;
    bool has_utf8 = DO_UTF8(sv);    /* has the result utf8? */
    const bool pat_utf8 = has_utf8; /* the pattern is in utf8? */
    SV *nsv = NULL;
    /* Times 4: a decimal digit takes more than 3 binary digits.
     * NV_DIG: mantissa takes than many decimal digits.
     * Plus 32: Playing safe. */
    char ebuf[IV_DIG * 4 + NV_DIG + 32];
    /* large enough for "%#.#f" --chip */
    /* what about long double NVs? --jhi */

    PERL_UNUSED_ARG(maybe_tainted);

    /* no matter what, this is a string now */
    (void)SvPV_force(sv, origlen);

    /* special-case "", "%s", and "%_" */
    if (patlen == 0)
	return;
    if (patlen == 2 && pat[0] == '%') {
	switch (pat[1]) {
	case 's':
	if (args) {
	    const char * const s = va_arg(*args, char*);
	    sv_catpv(sv, s ? s : nullstr);
	}
	else if (svix < svmax) {
	    sv_catsv(sv, *svargs);
	}
	return;
	case '_':
	    if (args) {
		argsv = va_arg(*args, SV*);
		sv_catsv(sv, argsv);
		return;
	    }
	    /* See comment on '_' below */
	    break;
	}
    }

#ifndef USE_LONG_DOUBLE
    /* special-case "%.<number>[gf]" */
    if ( !args && patlen <= 5 && pat[0] == '%' && pat[1] == '.'
	 && (pat[patlen-1] == 'g' || pat[patlen-1] == 'f') ) {
	unsigned digits = 0;
	const char *pp;

	pp = pat + 2;
	while (*pp >= '0' && *pp <= '9')
	    digits = 10 * digits + (*pp++ - '0');
	if (pp - pat == (int)patlen - 1) {
	    NV nv;

	    if (svix < svmax)
		nv = SvNV(*svargs);
	    else
		return;
	    if (*pp == 'g') {
		/* Add check for digits != 0 because it seems that some
		   gconverts are buggy in this case, and we don't yet have
		   a Configure test for this.  */
		if (digits && digits < sizeof(ebuf) - NV_DIG - 10) {
		     /* 0, point, slack */
		    Gconvert(nv, (int)digits, 0, ebuf);
		    sv_catpv(sv, ebuf);
		    if (*ebuf)	/* May return an empty string for digits==0 */
			return;
		}
	    } else if (!digits) {
		STRLEN l;

		if ((p = F0convert(nv, ebuf + sizeof ebuf, &l))) {
		    sv_catpvn(sv, p, l);
		    return;
		}
	    }
	}
    }
#endif /* !USE_LONG_DOUBLE */

    if (!args && svix < svmax && DO_UTF8(*svargs))
	has_utf8 = TRUE;

    patend = (char*)pat + patlen;
    for (p = (char*)pat; p < patend; p = q) {
	bool alt = FALSE;
	bool left = FALSE;
	bool vectorize = FALSE;
	bool vectorarg = FALSE;
	bool vec_utf8 = FALSE;
	char fill = ' ';
	char plus = 0;
	char intsize = 0;
	STRLEN width = 0;
	STRLEN zeros = 0;
	bool has_precis = FALSE;
	STRLEN precis = 0;
	const I32 osvix = svix;
	bool is_utf8 = FALSE;  /* is this item utf8?   */
#ifdef HAS_LDBL_SPRINTF_BUG
	/* This is to try to fix a bug with irix/nonstop-ux/powerux and
	   with sfio - Allen <allens@cpan.org> */
	bool fix_ldbl_sprintf_bug = FALSE;
#endif

	char esignbuf[4];
	U8 utf8buf[UTF8_MAXBYTES+1];
	STRLEN esignlen = 0;

	const char *eptr = NULL;
	STRLEN elen = 0;
	SV *vecsv = NULL;
	const U8 *vecstr = NULL;
	STRLEN veclen = 0;
	char c = 0;
	int i;
	unsigned base = 0;
	IV iv = 0;
	UV uv = 0;
	/* we need a long double target in case HAS_LONG_DOUBLE but
	   not USE_LONG_DOUBLE
	*/
#if defined(HAS_LONG_DOUBLE) && LONG_DOUBLESIZE > DOUBLESIZE
	long double nv;
#else
	NV nv;
#endif
	STRLEN have;
	STRLEN need;
	STRLEN gap;
	const char *dotstr = ".";
	STRLEN dotstrlen = 1;
	I32 efix = 0; /* explicit format parameter index */
	I32 ewix = 0; /* explicit width index */
	I32 epix = 0; /* explicit precision index */
	I32 evix = 0; /* explicit vector index */
	bool asterisk = FALSE;

	/* echo everything up to the next format specification */
	for (q = p; q < patend && *q != '%'; ++q) ;
	if (q > p) {
	    if (has_utf8 && !pat_utf8)
		sv_catpvn_utf8_upgrade(sv, p, q - p, nsv);
	    else
		sv_catpvn(sv, p, q - p);
	    p = q;
	}
	if (q++ >= patend)
	    break;

/*
    We allow format specification elements in this order:
	\d+\$              explicit format parameter index
	[-+ 0#]+           flags
	v|\*(\d+\$)?v      vector with optional (optionally specified) arg
	0		   flag (as above): repeated to allow "v02" 	
	\d+|\*(\d+\$)?     width using optional (optionally specified) arg
	\.(\d*|\*(\d+\$)?) precision using optional (optionally specified) arg
	[hlqLV]            size
    [%bcdefginopsux_DFOUX] format (mandatory)
*/
	if ( (width = expect_number(&q)) ) {
	    if (*q == '$') {
		++q;
		efix = width;
	    } else {
		goto gotwidth;
	    }
	}

	/* FLAGS */

	while (*q) {
	    switch (*q) {
	    case ' ':
	    case '+':
		if (plus == '+' && *q == ' ') /* '+' over ' ' */
		    q++;
		else
		    plus = *q++;
		continue;

	    case '-':
		left = TRUE;
		q++;
		continue;

	    case '0':
		fill = *q++;
		continue;

	    case '#':
		alt = TRUE;
		q++;
		continue;

	    default:
		break;
	    }
	    break;
	}

      tryasterisk:
	if (*q == '*') {
	    q++;
	    if ( (ewix = expect_number(&q)) )
		if (*q++ != '$')
		    goto unknown;
	    asterisk = TRUE;
	}
	if (*q == 'v') {
	    q++;
	    if (vectorize)
		goto unknown;
	    if ((vectorarg = asterisk)) {
		evix = ewix;
		ewix = 0;
		asterisk = FALSE;
	    }
	    vectorize = TRUE;
	    goto tryasterisk;
	}

	if (!asterisk)
	{
	    if( *q == '0' ) 
		fill = *q++;
	    width = expect_number(&q);
	}

#ifdef CHECK_FORMAT
	if ((*q == 'p') && left) {
            vectorize = (width == 1);
	}
#endif
	if (vectorize) {
	    if (vectorarg) {
		if (args)
		    vecsv = va_arg(*args, SV*);
		else if (evix) {
		    vecsv = (evix > 0 && evix <= svmax)
			? svargs[evix-1] : &PL_sv_undef;
		} else {
		    vecsv = svix < svmax ? svargs[svix++] : &PL_sv_undef;
		}
		dotstr = SvPV_const(vecsv, dotstrlen);
		/* Keep the DO_UTF8 test *after* the SvPV call, else things go
		   bad with tied or overloaded values that return UTF8.  */
		if (DO_UTF8(vecsv))
		    is_utf8 = TRUE;
		else if (has_utf8) {
		    vecsv = sv_mortalcopy(vecsv);
		    sv_utf8_upgrade(vecsv);
		    dotstr = SvPV_const(vecsv, dotstrlen);
		    is_utf8 = TRUE;
		}		    
	    }
	    if (args) {
		vecsv = va_arg(*args, SV*);
		vecstr = (U8*)SvPV_const(vecsv,veclen);
		vec_utf8 = DO_UTF8(vecsv);
	    }
	    else if (efix ? (efix > 0 && efix <= svmax) : svix < svmax) {
		vecsv = svargs[efix ? efix-1 : svix++];
		vecstr = (U8*)SvPV_const(vecsv,veclen);
		vec_utf8 = DO_UTF8(vecsv);
	    }
	    else {
		vecsv = &PL_sv_undef;
		vecstr = (U8*)"";
		veclen = 0;
	    }
	}

	if (asterisk) {
	    if (args)
		i = va_arg(*args, int);
	    else
		i = (ewix ? ewix <= svmax : svix < svmax) ?
		    SvIVx(svargs[ewix ? ewix-1 : svix++]) : 0;
	    left |= (i < 0);
	    width = (i < 0) ? -i : i;
	}
      gotwidth:

	/* PRECISION */

	if (*q == '.') {
	    q++;
	    if (*q == '*') {
		q++;
		if ( ((epix = expect_number(&q))) && (*q++ != '$') )
		    goto unknown;
		/* XXX: todo, support specified precision parameter */
		if (epix)
		    goto unknown;
		if (args)
		    i = va_arg(*args, int);
		else
		    i = (ewix ? ewix <= svmax : svix < svmax)
			? SvIVx(svargs[ewix ? ewix-1 : svix++]) : 0;
		precis = i;
		has_precis = !(i < 0);
	    }
	    else {
		precis = 0;
		while (isDIGIT(*q))
		    precis = precis * 10 + (*q++ - '0');
		has_precis = TRUE;
	    }
	}

	/* SIZE */

	switch (*q) {
#ifdef WIN32
	case 'I':			/* Ix, I32x, and I64x */
#  ifdef WIN64
	    if (q[1] == '6' && q[2] == '4') {
		q += 3;
		intsize = 'q';
		break;
	    }
#  endif
	    if (q[1] == '3' && q[2] == '2') {
		q += 3;
		break;
	    }
#  ifdef WIN64
	    intsize = 'q';
#  endif
	    q++;
	    break;
#endif
#if defined(HAS_QUAD) || defined(HAS_LONG_DOUBLE)
	case 'L':			/* Ld */
	    /*FALLTHROUGH*/
#ifdef HAS_QUAD
	case 'q':			/* qd */
#endif
	    intsize = 'q';
	    q++;
	    break;
#endif
	case 'l':
#if defined(HAS_QUAD) || defined(HAS_LONG_DOUBLE)
	    if (*(q + 1) == 'l') {	/* lld, llf */
		intsize = 'q';
		q += 2;
		break;
	     }
#endif
	    /*FALLTHROUGH*/
	case 'h':
	    /*FALLTHROUGH*/
	case 'V':
	    intsize = *q++;
	    break;
	}

	/* CONVERSION */

	if (*q == '%') {
	    eptr = q++;
	    elen = 1;
	    if (vectorize) {
		c = '%';
		goto unknown;
	    }
	    goto string;
	}

	if (!vectorize && !args) {
	    if (efix) {
		const I32 i = efix-1;
		argsv = (i >= 0 && i < svmax) ? svargs[i] : &PL_sv_undef;
	    } else {
		argsv = (svix >= 0 && svix < svmax)
		    ? svargs[svix++] : &PL_sv_undef;
	    }
	}

	switch (c = *q++) {

	    /* STRINGS */

	case 'c':
	    if (vectorize)
		goto unknown;
	    uv = (args) ? va_arg(*args, int) : SvIV(argsv);
	    if ((uv > 255 ||
		 (!UNI_IS_INVARIANT(uv) && SvUTF8(sv)))
		&& !IN_BYTES) {
		eptr = (char*)utf8buf;
		elen = uvchr_to_utf8((U8*)eptr, uv) - utf8buf;
		is_utf8 = TRUE;
	    }
	    else {
		c = (char)uv;
		eptr = &c;
		elen = 1;
	    }
	    goto string;

	case 's':
	    if (vectorize)
		goto unknown;
	    if (args) {
		eptr = va_arg(*args, char*);
		if (eptr)
#ifdef MACOS_TRADITIONAL
		  /* On MacOS, %#s format is used for Pascal strings */
		  if (alt)
		    elen = *eptr++;
		  else
#endif
		    elen = strlen(eptr);
		else {
		    eptr = (char *)nullstr;
		    elen = sizeof nullstr - 1;
		}
	    }
	    else {
		eptr = SvPV_const(argsv, elen);
		if (DO_UTF8(argsv)) {
		    I32 old_precis = precis;
		    if (has_precis && precis < elen) {
			I32 p = precis;
			sv_pos_u2b(argsv, &p, 0); /* sticks at end */
			precis = p;
		    }
		    if (width) { /* fudge width (can't fudge elen) */
			if (has_precis && precis < elen)
			    width += precis - old_precis;
			else
			    width += elen - sv_len_utf8(argsv);
		    }
		    is_utf8 = TRUE;
		}
	    }
	    goto string;

	case '_':
#ifdef CHECK_FORMAT
	format_sv:
#endif
	    /*
	     * The "%_" hack might have to be changed someday,
	     * if ISO or ANSI decide to use '_' for something.
	     * So we keep it hidden from users' code.
	     */
	    if (!args || vectorize)
		goto unknown;
	    argsv = va_arg(*args, SV*);
	    eptr = SvPVx(argsv, elen);
	    if (DO_UTF8(argsv))
		is_utf8 = TRUE;

	string:
	    if (has_precis && elen > precis)
		elen = precis;
	    break;

	    /* INTEGERS */

	case 'p':
#ifdef CHECK_FORMAT
	    if (left) {
		left = FALSE;
	        if (!width)
		    goto format_sv;	/* %-p	-> %_	*/
		if (vectorize) {
		    width = 0;
		    goto format_vd;	/* %-1p	-> %vd  */      
		}
		precis = width;
		has_precis = TRUE;
		width = 0;
		goto format_sv;		/* %-Np	-> %.N_	*/	
	    }
#endif
	    if (alt || vectorize)
		goto unknown;
	    uv = PTR2UV(args ? va_arg(*args, void*) : argsv);
	    base = 16;
	    goto integer;

	case 'D':
#ifdef IV_IS_QUAD
	    intsize = 'q';
#else
	    intsize = 'l';
#endif
	    /*FALLTHROUGH*/
	case 'd':
	case 'i':
#ifdef CHECK_FORMAT
	format_vd:
#endif
	    if (vectorize) {
		STRLEN ulen;
		if (!veclen)
		    continue;
		if (vec_utf8)
		    uv = utf8n_to_uvchr((U8 *)vecstr, veclen, &ulen,
					UTF8_ALLOW_ANYUV);
		else {
		    uv = *vecstr;
		    ulen = 1;
		}
		vecstr += ulen;
		veclen -= ulen;
		if (plus)
		     esignbuf[esignlen++] = plus;
	    }
	    else if (args) {
		switch (intsize) {
		case 'h':	iv = (short)va_arg(*args, int); break;
		case 'l':	iv = va_arg(*args, long); break;
		case 'V':	iv = va_arg(*args, IV); break;
		default:	iv = va_arg(*args, int); break;
#ifdef HAS_QUAD
		case 'q':	iv = va_arg(*args, Quad_t); break;
#endif
		}
	    }
	    else {
		IV tiv = SvIV(argsv); /* work around GCC bug #13488 */
		switch (intsize) {
		case 'h':	iv = (short)tiv; break;
		case 'l':	iv = (long)tiv; break;
		case 'V':
		default:	iv = tiv; break;
#ifdef HAS_QUAD
		case 'q':	iv = (Quad_t)tiv; break;
#endif
		}
	    }
	    if ( !vectorize )	/* we already set uv above */
	    {
		if (iv >= 0) {
		    uv = iv;
		    if (plus)
			esignbuf[esignlen++] = plus;
		}
		else {
		    uv = -iv;
		    esignbuf[esignlen++] = '-';
		}
	    }
	    base = 10;
	    goto integer;

	case 'U':
#ifdef IV_IS_QUAD
	    intsize = 'q';
#else
	    intsize = 'l';
#endif
	    /*FALLTHROUGH*/
	case 'u':
	    base = 10;
	    goto uns_integer;

	case 'b':
	    base = 2;
	    goto uns_integer;

	case 'O':
#ifdef IV_IS_QUAD
	    intsize = 'q';
#else
	    intsize = 'l';
#endif
	    /*FALLTHROUGH*/
	case 'o':
	    base = 8;
	    goto uns_integer;

	case 'X':
	case 'x':
	    base = 16;

	uns_integer:
	    if (vectorize) {
		STRLEN ulen;
	vector:
		if (!veclen)
		    continue;
		if (vec_utf8)
		    uv = utf8n_to_uvchr((U8 *)vecstr, veclen, &ulen,
					UTF8_ALLOW_ANYUV);
		else {
		    uv = *vecstr;
		    ulen = 1;
		}
		vecstr += ulen;
		veclen -= ulen;
	    }
	    else if (args) {
		switch (intsize) {
		case 'h':  uv = (unsigned short)va_arg(*args, unsigned); break;
		case 'l':  uv = va_arg(*args, unsigned long); break;
		case 'V':  uv = va_arg(*args, UV); break;
		default:   uv = va_arg(*args, unsigned); break;
#ifdef HAS_QUAD
		case 'q':  uv = va_arg(*args, Uquad_t); break;
#endif
		}
	    }
	    else {
		UV tuv = SvUV(argsv); /* work around GCC bug #13488 */
		switch (intsize) {
		case 'h':	uv = (unsigned short)tuv; break;
		case 'l':	uv = (unsigned long)tuv; break;
		case 'V':
		default:	uv = tuv; break;
#ifdef HAS_QUAD
		case 'q':	uv = (Uquad_t)tuv; break;
#endif
		}
	    }

	integer:
	    {
		char *ptr = ebuf + sizeof ebuf;
		bool tempalt = uv ? alt : FALSE; /* Vectors can't change alt */
		zeros = 0;

		switch (base) {
		    unsigned dig;
		case 16:
		    p = (char *)((c == 'X') ? PL_hexdigit + 16 : PL_hexdigit);
		    do {
			dig = uv & 15;
			*--ptr = p[dig];
		    } while (uv >>= 4);
		    if (tempalt) {
			esignbuf[esignlen++] = '0';
			esignbuf[esignlen++] = c;  /* 'x' or 'X' */
		    }
		    break;
		case 8:
		    do {
			dig = uv & 7;
			*--ptr = '0' + dig;
		    } while (uv >>= 3);
		    if (alt && *ptr != '0')
			*--ptr = '0';
		    break;
		case 2:
		    do {
			dig = uv & 1;
			*--ptr = '0' + dig;
		    } while (uv >>= 1);
		    if (tempalt) {
			esignbuf[esignlen++] = '0';
			esignbuf[esignlen++] = 'b';
		    }
		    break;
		default:		/* it had better be ten or less */
#if defined(PERL_Y2KWARN)
		    if (ckWARN(WARN_Y2K)) {
			STRLEN n;
			const char *const s = SvPV_const(sv,n);
			if (n >= 2 && s[n-2] == '1' && s[n-1] == '9'
			    && (n == 2 || !isDIGIT(s[n-3])))
			    {
				Perl_warner(aTHX_ packWARN(WARN_Y2K),
					    "Possible Y2K bug: %%%c %s",
					    c, "format string following '19'");
			    }
		    }
#endif
		    do {
			dig = uv % base;
			*--ptr = '0' + dig;
		    } while (uv /= base);
		    break;
		}
		elen = (ebuf + sizeof ebuf) - ptr;
		eptr = ptr;
		if (has_precis) {
		    if (precis > elen)
			zeros = precis - elen;
		    else if (precis == 0 && elen == 1 && *eptr == '0'
			     && !(base == 8 && alt)) /* "%#.0o" prints "0" */
			elen = 0;

		/* a precision nullifies the 0 flag. */
		    if (fill == '0')
			fill = ' ';
		}
	    }
	    break;

	    /* FLOATING POINT */

	case 'F':
	    c = 'f';		/* maybe %F isn't supported here */
	    /*FALLTHROUGH*/
	case 'e': case 'E':
	case 'f':
	case 'g': case 'G':
	    if (vectorize)
		goto unknown;

	    /* This is evil, but floating point is even more evil */

	    /* for SV-style calling, we can only get NV
	       for C-style calling, we assume %f is double;
	       for simplicity we allow any of %Lf, %llf, %qf for long double
	    */
	    switch (intsize) {
	    case 'V':
#if defined(USE_LONG_DOUBLE)
		intsize = 'q';
#endif
		break;
/* [perl #20339] - we should accept and ignore %lf rather than die */
	    case 'l':
		/*FALLTHROUGH*/
	    default:
#if defined(USE_LONG_DOUBLE)
		intsize = args ? 0 : 'q';
#endif
		break;
	    case 'q':
#if defined(HAS_LONG_DOUBLE)
		break;
#else
		/*FALLTHROUGH*/
#endif
	    case 'h':
		goto unknown;
	    }

	    /* now we need (long double) if intsize == 'q', else (double) */
	    nv = (args) ?
#if LONG_DOUBLESIZE > DOUBLESIZE
		intsize == 'q' ?
		    va_arg(*args, long double) :
		    va_arg(*args, double)
#else
		    va_arg(*args, double)
#endif
		: SvNV(argsv);

	    need = 0;
	    /* nv * 0 will be NaN for NaN, +Inf and -Inf, and 0 for anything
	       else. frexp() has some unspecified behaviour for those three */
	    if (c != 'e' && c != 'E' && (nv * 0) == 0) {
		i = PERL_INT_MIN;
		/* FIXME: if HAS_LONG_DOUBLE but not USE_LONG_DOUBLE this
		   will cast our (long double) to (double) */
		(void)Perl_frexp(nv, &i);
		if (i == PERL_INT_MIN)
		    Perl_die(aTHX_ "panic: frexp");
		if (i > 0)
		    need = BIT_DIGITS(i);
	    }
	    need += has_precis ? precis : 6; /* known default */

	    if (need < width)
		need = width;

#ifdef HAS_LDBL_SPRINTF_BUG
	    /* This is to try to fix a bug with irix/nonstop-ux/powerux and
	       with sfio - Allen <allens@cpan.org> */

#  ifdef DBL_MAX
#    define MY_DBL_MAX DBL_MAX
#  else /* XXX guessing! HUGE_VAL may be defined as infinity, so not using */
#    if DOUBLESIZE >= 8
#      define MY_DBL_MAX 1.7976931348623157E+308L
#    else
#      define MY_DBL_MAX 3.40282347E+38L
#    endif
#  endif

#  ifdef HAS_LDBL_SPRINTF_BUG_LESS1 /* only between -1L & 1L - Allen */
#    define MY_DBL_MAX_BUG 1L
#  else
#    define MY_DBL_MAX_BUG MY_DBL_MAX
#  endif

#  ifdef DBL_MIN
#    define MY_DBL_MIN DBL_MIN
#  else  /* XXX guessing! -Allen */
#    if DOUBLESIZE >= 8
#      define MY_DBL_MIN 2.2250738585072014E-308L
#    else
#      define MY_DBL_MIN 1.17549435E-38L
#    endif
#  endif

	    if ((intsize == 'q') && (c == 'f') &&
		((nv < MY_DBL_MAX_BUG) && (nv > -MY_DBL_MAX_BUG)) &&
		(need < DBL_DIG)) {
		/* it's going to be short enough that
		 * long double precision is not needed */

		if ((nv <= 0L) && (nv >= -0L))
		    fix_ldbl_sprintf_bug = TRUE; /* 0 is 0 - easiest */
		else {
		    /* would use Perl_fp_class as a double-check but not
		     * functional on IRIX - see perl.h comments */

		    if ((nv >= MY_DBL_MIN) || (nv <= -MY_DBL_MIN)) {
			/* It's within the range that a double can represent */
#if defined(DBL_MAX) && !defined(DBL_MIN)
			if ((nv >= ((long double)1/DBL_MAX)) ||
			    (nv <= (-(long double)1/DBL_MAX)))
#endif
			fix_ldbl_sprintf_bug = TRUE;
		    }
		}
		if (fix_ldbl_sprintf_bug == TRUE) {
		    double temp;

		    intsize = 0;
		    temp = (double)nv;
		    nv = (NV)temp;
		}
	    }

#  undef MY_DBL_MAX
#  undef MY_DBL_MAX_BUG
#  undef MY_DBL_MIN

#endif /* HAS_LDBL_SPRINTF_BUG */

	    need += 20; /* fudge factor */
	    if (PL_efloatsize < need) {
		Safefree(PL_efloatbuf);
		PL_efloatsize = need + 20; /* more fudge */
		Newx(PL_efloatbuf, PL_efloatsize, char);
		PL_efloatbuf[0] = '\0';
	    }

	    if ( !(width || left || plus || alt) && fill != '0'
		 && has_precis && intsize != 'q' ) {	/* Shortcuts */
		/* See earlier comment about buggy Gconvert when digits,
		   aka precis is 0  */
		if ( c == 'g' && precis) {
		    Gconvert((NV)nv, (int)precis, 0, PL_efloatbuf);
		    /* May return an empty string for digits==0 */
		    if (*PL_efloatbuf) {
			elen = strlen(PL_efloatbuf);
			goto float_converted;
		    }
		} else if ( c == 'f' && !precis) {
		    if ((eptr = F0convert(nv, ebuf + sizeof ebuf, &elen)))
			break;
		}
	    }
	    {
		char *ptr = ebuf + sizeof ebuf;
		*--ptr = '\0';
		*--ptr = c;
		/* FIXME: what to do if HAS_LONG_DOUBLE but not PERL_PRIfldbl? */
#if defined(HAS_LONG_DOUBLE) && defined(PERL_PRIfldbl)
		if (intsize == 'q') {
		    /* Copy the one or more characters in a long double
		     * format before the 'base' ([efgEFG]) character to
		     * the format string. */
		    static char const prifldbl[] = PERL_PRIfldbl;
		    char const *p = prifldbl + sizeof(prifldbl) - 3;
		    while (p >= prifldbl) { *--ptr = *p--; }
		}
#endif
		if (has_precis) {
		    base = precis;
		    do { *--ptr = '0' + (base % 10); } while (base /= 10);
		    *--ptr = '.';
		}
		if (width) {
		    base = width;
		    do { *--ptr = '0' + (base % 10); } while (base /= 10);
		}
		if (fill == '0')
		    *--ptr = fill;
		if (left)
		    *--ptr = '-';
		if (plus)
		    *--ptr = plus;
		if (alt)
		    *--ptr = '#';
		*--ptr = '%';

		/* No taint.  Otherwise we are in the strange situation
		 * where printf() taints but print($float) doesn't.
		 * --jhi */
#if defined(HAS_LONG_DOUBLE)
		elen = ((intsize == 'q')
			? my_snprintf(PL_efloatbuf, PL_efloatsize, ptr, nv)
			: my_snprintf(PL_efloatbuf, PL_efloatsize, ptr, (double)nv));
#else
		elen = my_sprintf(PL_efloatbuf, ptr, nv);
#endif
	    }
	float_converted:
	    eptr = PL_efloatbuf;
	    break;

	    /* SPECIAL */

	case 'n':
	    if (vectorize)
		goto unknown;
	    i = SvCUR(sv) - origlen;
	    if (args) {
		switch (intsize) {
		case 'h':	*(va_arg(*args, short*)) = i; break;
		default:	*(va_arg(*args, int*)) = i; break;
		case 'l':	*(va_arg(*args, long*)) = i; break;
		case 'V':	*(va_arg(*args, IV*)) = i; break;
#ifdef HAS_QUAD
		case 'q':	*(va_arg(*args, Quad_t*)) = i; break;
#endif
		}
	    }
	    else
		sv_setuv_mg(argsv, (UV)i);
	    continue;	/* not "break" */

	    /* UNKNOWN */

	default:
      unknown:
	    if (!args
		&& (PL_op->op_type == OP_PRTF || PL_op->op_type == OP_SPRINTF)
		&& ckWARN(WARN_PRINTF))
	    {
		SV * const msg = sv_newmortal();
		Perl_sv_setpvf(aTHX_ msg, "Invalid conversion in %sprintf: ",
			  (PL_op->op_type == OP_PRTF) ? "" : "s");
		if (c) {
		    if (isPRINT(c))
			Perl_sv_catpvf(aTHX_ msg,
				       "\"%%%c\"", c & 0xFF);
		    else
			Perl_sv_catpvf(aTHX_ msg,
				       "\"%%\\%03"UVof"\"",
				       (UV)c & 0xFF);
		} else
		    sv_catpvs(msg, "end of string");
		Perl_warner(aTHX_ packWARN(WARN_PRINTF), "%"SVf, (void*)msg); /* yes, this is reentrant */
	    }

	    /* output mangled stuff ... */
	    if (c == '\0')
		--q;
	    eptr = p;
	    elen = q - p;

	    /* ... right here, because formatting flags should not apply */
	    SvGROW(sv, SvCUR(sv) + elen + 1);
	    p = SvEND(sv);
	    Copy(eptr, p, elen, char);
	    p += elen;
	    *p = '\0';
	    SvCUR_set(sv, p - SvPVX_const(sv));
	    svix = osvix;
	    continue;	/* not "break" */
	}

	if (is_utf8 != has_utf8) {
	    if (is_utf8) {
		if (SvCUR(sv))
		    sv_utf8_upgrade(sv);
	    }
	    else {
		const STRLEN old_elen = elen;
		SV * const nsv = newSVpvn_flags(eptr, elen, SVs_TEMP);
		sv_utf8_upgrade(nsv);
		eptr = SvPVX_const(nsv);
		elen = SvCUR(nsv);

		if (width) { /* fudge width (can't fudge elen) */
		    width += elen - old_elen;
		}
		is_utf8 = TRUE;
	    }
	}

	have = esignlen + zeros + elen;
	if (have < zeros)
	    Perl_croak_nocontext("%s", PL_memory_wrap);

	if (is_utf8 != has_utf8) {
	     if (is_utf8) {
		  if (SvCUR(sv))
		       sv_utf8_upgrade(sv);
	     }
	     else {
		  SV * const nsv = sv_2mortal(newSVpvn(eptr, elen));
		  sv_utf8_upgrade(nsv);
		  eptr = SvPVX_const(nsv);
		  elen = SvCUR(nsv);
	     }
	     SvGROW(sv, SvCUR(sv) + elen + 1);
	     p = SvEND(sv);
	     *p = '\0';
	}
	/* Use memchr() instead of strchr(), as eptr is not guaranteed */
	/* to point to a null-terminated string.                       */
	if (left && ckWARN(WARN_PRINTF) && memchr(eptr, '\n', elen) && 
	    (PL_op->op_type == OP_PRTF || PL_op->op_type == OP_SPRINTF)) 
	    Perl_warner(aTHX_ packWARN(WARN_PRINTF),
		"Newline in left-justified string for %sprintf",
			(PL_op->op_type == OP_PRTF) ? "" : "s");
	
	need = (have > width ? have : width);
	gap = need - have;

	if (need >= (((STRLEN)~0) - SvCUR(sv) - dotstrlen - 1))
	    Perl_croak_nocontext("%s", PL_memory_wrap);
	SvGROW(sv, SvCUR(sv) + need + dotstrlen + 1);
	p = SvEND(sv);
	if (esignlen && fill == '0') {
	    int i;
	    for (i = 0; i < (int)esignlen; i++)
		*p++ = esignbuf[i];
	}
	if (gap && !left) {
	    memset(p, fill, gap);
	    p += gap;
	}
	if (esignlen && fill != '0') {
	    int i;
	    for (i = 0; i < (int)esignlen; i++)
		*p++ = esignbuf[i];
	}
	if (zeros) {
	    int i;
	    for (i = zeros; i; i--)
		*p++ = '0';
	}
	if (elen) {
	    Copy(eptr, p, elen, char);
	    p += elen;
	}
	if (gap && left) {
	    memset(p, ' ', gap);
	    p += gap;
	}
	if (vectorize) {
	    if (veclen) {
		Copy(dotstr, p, dotstrlen, char);
		p += dotstrlen;
	    }
	    else
		vectorize = FALSE;		/* done iterating over vecstr */
	}
	if (is_utf8)
	    has_utf8 = TRUE;
	if (has_utf8)
	    SvUTF8_on(sv);
	*p = '\0';
	SvCUR_set(sv, p - SvPVX_const(sv));
	if (vectorize) {
	    esignlen = 0;
	    goto vector;
	}
    }
}

/* =========================================================================

=head1 Cloning an interpreter

All the macros and functions in this section are for the private use of
the main function, perl_clone().

The foo_dup() functions make an exact copy of an existing foo thingy.
During the course of a cloning, a hash table is used to map old addresses
to new addresses. The table is created and manipulated with the
ptr_table_* functions.

=cut

============================================================================*/


#if defined(USE_ITHREADS)

#if defined(USE_5005THREADS)
#  include "error: USE_5005THREADS and USE_ITHREADS are incompatible"
#endif

#ifndef GpREFCNT_inc
#  define GpREFCNT_inc(gp)	((gp) ? (++(gp)->gp_refcnt, (gp)) : (GP*)NULL)
#endif


/* Certain cases in Perl_ss_dup have been merged, by relying on the fact
   that currently av_dup, gv_dup and hv_dup are the same as sv_dup.
   If this changes, please unmerge ss_dup.  */
#define sv_dup_inc(s,t)	SvREFCNT_inc(sv_dup(s,t))
#define sv_dup_inc_NN(s,t)	SvREFCNT_inc_NN(sv_dup(s,t))
#define av_dup(s,t)	(AV*)sv_dup((SV*)s,t)
#define av_dup_inc(s,t)	(AV*)SvREFCNT_inc(sv_dup((SV*)s,t))
#define hv_dup(s,t)	(HV*)sv_dup((SV*)s,t)
#define hv_dup_inc(s,t)	(HV*)SvREFCNT_inc(sv_dup((SV*)s,t))
#define cv_dup(s,t)	(CV*)sv_dup((SV*)s,t)
#define cv_dup_inc(s,t)	(CV*)SvREFCNT_inc(sv_dup((SV*)s,t))
#define io_dup(s,t)	(IO*)sv_dup((SV*)s,t)
#define io_dup_inc(s,t)	(IO*)SvREFCNT_inc(sv_dup((SV*)s,t))
#define gv_dup(s,t)	(GV*)sv_dup((SV*)s,t)
#define gv_dup_inc(s,t)	(GV*)SvREFCNT_inc(sv_dup((SV*)s,t))
#define SAVEPV(p)	((p) ? savepv(p) : NULL)
#define SAVEPVN(p,n)	((p) ? savepvn(p,n) : NULL)


/* Duplicate a regexp. Required reading: pregcomp() and pregfree() in
   regcomp.c. AMS 20010712 */

REGEXP *
Perl_re_dup(pTHX_ REGEXP *r, CLONE_PARAMS *param)
{
    return CALLREGDUPE(aTHX_ r,param);
}

/* duplicate a file handle */

PerlIO *
Perl_fp_dup(pTHX_ PerlIO *fp, char type, CLONE_PARAMS *param)
{
    PerlIO *ret;

    PERL_UNUSED_ARG(type);

    if (!fp)
	return (PerlIO*)NULL;

    /* look for it in the table first */
    ret = (PerlIO*)ptr_table_fetch(PL_ptr_table, fp);
    if (ret)
	return ret;

    /* create anew and remember what it is */
    ret = PerlIO_fdupopen(aTHX_ fp, param, PERLIO_DUP_CLONE);
    ptr_table_store(PL_ptr_table, fp, ret);
    return ret;
}

/* duplicate a directory handle */

DIR *
Perl_dirp_dup(pTHX_ DIR *dp)
{
    PERL_UNUSED_CONTEXT;
    if (!dp)
	return (DIR*)NULL;
    /* XXX TODO */
    return dp;
}

/* duplicate a typeglob */

GP *
Perl_gp_dup(pTHX_ GP *gp, CLONE_PARAMS* param)
{
    GP *ret;

    if (!gp)
	return (GP*)NULL;
    /* look for it in the table first */
    ret = (GP*)ptr_table_fetch(PL_ptr_table, gp);
    if (ret)
	return ret;

    /* create anew and remember what it is */
    Newxz(ret, 1, GP);
    ptr_table_store(PL_ptr_table, gp, ret);

    /* clone */
    ret->gp_refcnt	= 0;			/* must be before any other dups! */
    ret->gp_sv		= sv_dup_inc(gp->gp_sv, param);
    ret->gp_io		= io_dup_inc(gp->gp_io, param);
    ret->gp_form	= cv_dup_inc(gp->gp_form, param);
    ret->gp_av		= av_dup_inc(gp->gp_av, param);
    ret->gp_hv		= hv_dup_inc(gp->gp_hv, param);
    ret->gp_egv	= gv_dup(gp->gp_egv, param);/* GvEGV is not refcounted */
    ret->gp_cv		= cv_dup_inc(gp->gp_cv, param);
    ret->gp_cvgen	= gp->gp_cvgen;
    ret->gp_flags	= gp->gp_flags;
    ret->gp_line	= gp->gp_line;
    ret->gp_file	= gp->gp_file;		/* points to COP.cop_file */
    return ret;
}

/* duplicate a chain of magic */

MAGIC *
Perl_mg_dup(pTHX_ MAGIC *mg, CLONE_PARAMS* param)
{
    MAGIC *mgprev = (MAGIC*)NULL;
    MAGIC *mgret;
    if (!mg)
	return (MAGIC*)NULL;
    /* look for it in the table first */
    mgret = (MAGIC*)ptr_table_fetch(PL_ptr_table, mg);
    if (mgret)
	return mgret;

    for (; mg; mg = mg->mg_moremagic) {
	MAGIC *nmg;
	Newxz(nmg, 1, MAGIC);
	if (mgprev)
	    mgprev->mg_moremagic = nmg;
	else
	    mgret = nmg;
	nmg->mg_virtual	= mg->mg_virtual;	/* XXX copy dynamic vtable? */
	nmg->mg_private	= mg->mg_private;
	nmg->mg_type	= mg->mg_type;
	nmg->mg_flags	= mg->mg_flags;
	if (mg->mg_type == PERL_MAGIC_qr) {
	    nmg->mg_obj	= (SV*)re_dup((REGEXP*)mg->mg_obj, param);
	}
	else if(mg->mg_type == PERL_MAGIC_backref) {
	    /* The backref AV has its reference count deliberately bumped by
	       1.  */
	    nmg->mg_obj = SvREFCNT_inc(av_dup_inc((AV*) mg->mg_obj, param));
	}
	else {
	    nmg->mg_obj	= (mg->mg_flags & MGf_REFCOUNTED)
			      ? sv_dup_inc(mg->mg_obj, param)
			      : sv_dup(mg->mg_obj, param);
	}
	nmg->mg_len	= mg->mg_len;
	nmg->mg_ptr	= mg->mg_ptr;	/* XXX random ptr? */
	if (mg->mg_ptr && mg->mg_type != PERL_MAGIC_regex_global) {
	    if (mg->mg_len > 0) {
		nmg->mg_ptr	= SAVEPVN(mg->mg_ptr, mg->mg_len);
		if (mg->mg_type == PERL_MAGIC_overload_table &&
			AMT_AMAGIC((AMT*)mg->mg_ptr))
		{
		    const AMT * const amtp = (AMT*)mg->mg_ptr;
		    AMT * const namtp = (AMT*)nmg->mg_ptr;
		    I32 i;
		    for (i = 1; i < NofAMmeth; i++) {
			namtp->table[i] = cv_dup_inc(amtp->table[i], param);
		    }
		}
	    }
	    else if (mg->mg_len == HEf_SVKEY)
		nmg->mg_ptr	= (char*)sv_dup_inc((SV*)mg->mg_ptr, param);
	}
	if ((mg->mg_flags & MGf_DUP) && mg->mg_virtual && mg->mg_virtual->svt_dup) {
	    CALL_FPTR(nmg->mg_virtual->svt_dup)(aTHX_ nmg, param);
	}
	mgprev = nmg;
    }
    return mgret;
}

#endif /* USE_ITHREADS */

/* create a new pointer-mapping table */

PTR_TBL_t *
Perl_ptr_table_new(pTHX)
{
    PTR_TBL_t *tbl;
    PERL_UNUSED_CONTEXT;

    Newxz(tbl, 1, PTR_TBL_t);
    tbl->tbl_max	= 511;
    tbl->tbl_items	= 0;
    Newxz(tbl->tbl_ary, tbl->tbl_max + 1, PTR_TBL_ENT_t*);
    return tbl;
}

#define PTR_TABLE_HASH(ptr) \
  ((PTR2UV(ptr) >> 3) ^ (PTR2UV(ptr) >> (3 + 7)) ^ (PTR2UV(ptr) >> (3 + 17)))

/* 
   we use the PTE_SVSLOT 'reservation' made above, both here (in the
   following define) and at call to new_body_inline made below in 
   Perl_ptr_table_store()
 */

#define del_pte(p)     del_body_type(p, PTE_SVSLOT)

/* map an existing pointer using a table */

STATIC PTR_TBL_ENT_t *
S_ptr_table_find(PTR_TBL_t *tbl, const void *sv) {
    PTR_TBL_ENT_t *tblent;
    const UV hash = PTR_TABLE_HASH(sv);
    assert(tbl);
    tblent = tbl->tbl_ary[hash & tbl->tbl_max];
    for (; tblent; tblent = tblent->next) {
	if (tblent->oldval == sv)
	    return tblent;
    }
    return NULL;
}

void *
Perl_ptr_table_fetch(pTHX_ PTR_TBL_t *tbl, void *sv)
{
    PTR_TBL_ENT_t const *const tblent = ptr_table_find(tbl, (const void *)sv);
    PERL_UNUSED_CONTEXT;
    return tblent ? tblent->newval : NULL;
}

/* add a new entry to a pointer-mapping table */

void
Perl_ptr_table_store(pTHX_ PTR_TBL_t *tbl, void *oldsv, void *newsv)
{
    PTR_TBL_ENT_t *tblent = ptr_table_find(tbl, (const void *)oldsv);
    PERL_UNUSED_CONTEXT;

    if (tblent) {
	tblent->newval = newsv;
    } else {
	const UV entry = PTR_TABLE_HASH(oldsv) & tbl->tbl_max;

	new_body_inline(tblent, PTE_SVSLOT);

	tblent->oldval = oldsv;
	tblent->newval = newsv;
	tblent->next = tbl->tbl_ary[entry];
	tbl->tbl_ary[entry] = tblent;
	tbl->tbl_items++;
	if (tblent->next && tbl->tbl_items > tbl->tbl_max)
	    ptr_table_split(tbl);
    }
}

/* double the hash bucket size of an existing ptr table */

void
Perl_ptr_table_split(pTHX_ PTR_TBL_t *tbl)
{
    PTR_TBL_ENT_t **ary = tbl->tbl_ary;
    const UV oldsize = tbl->tbl_max + 1;
    UV newsize = oldsize * 2;
    UV i;
    PERL_UNUSED_CONTEXT;

    Renew(ary, newsize, PTR_TBL_ENT_t*);
    Zero(&ary[oldsize], newsize-oldsize, PTR_TBL_ENT_t*);
    tbl->tbl_max = --newsize;
    tbl->tbl_ary = ary;
    for (i=0; i < oldsize; i++, ary++) {
	PTR_TBL_ENT_t **curentp, **entp, *ent;
	if (!*ary)
	    continue;
	curentp = ary + oldsize;
	for (entp = ary, ent = *ary; ent; ent = *entp) {
	    if ((newsize & PTR_TABLE_HASH(ent->oldval)) != i) {
		*entp = ent->next;
		ent->next = *curentp;
		*curentp = ent;
		continue;
	    }
	    else
		entp = &ent->next;
	}
    }
}

/* remove all the entries from a ptr table */

void
Perl_ptr_table_clear(pTHX_ PTR_TBL_t *tbl)
{
    if (tbl && tbl->tbl_items) {
	register PTR_TBL_ENT_t * const * const array = tbl->tbl_ary;
	UV riter = tbl->tbl_max;

	do {
	    PTR_TBL_ENT_t *entry = array[riter];

	    while (entry) {
		PTR_TBL_ENT_t * const oentry = entry;
		entry = entry->next;
		del_pte(oentry);
	    }
	} while (riter--);

	tbl->tbl_items = 0;
    }
}

/* clear and free a ptr table */

void
Perl_ptr_table_free(pTHX_ PTR_TBL_t *tbl)
{
    if (!tbl) {
        return;
    }
    ptr_table_clear(tbl);
    Safefree(tbl->tbl_ary);
    Safefree(tbl);
}

#if defined(USE_ITHREADS)

#ifdef DEBUGGING
char *PL_watch_pvx;
#endif

void
Perl_rvpv_dup(pTHX_ SV *dstr, SV *sstr, CLONE_PARAMS* param)
{
    if (SvROK(sstr)) {
	SvRV_set(dstr, SvWEAKREF(sstr)
		       ? sv_dup(SvRV(sstr), param)
		       : sv_dup_inc(SvRV(sstr), param));

    }
    else if (SvPVX_const(sstr)) {
	/* Has something there */
	if (SvLEN(sstr)) {
	    /* Normal PV - clone whole allocated space */
	    SvPV_set(dstr, SAVEPVN(SvPVX_const(sstr), SvLEN(sstr)-1));
	}
	else {
	    /* Special case - not normally malloced for some reason */
	    if (SvREADONLY(sstr) && SvFAKE(sstr)) {
		/* A "shared" PV - clone it as unshared string */
                if(SvPADTMP(sstr)) {
                    /* However, some of them live in the pad
                       and they should not have these flags
                       turned off */

                    SvPV_set(dstr, sharepvn(SvPVX_const(sstr), SvCUR(sstr),
                                           SvUVX(sstr)));
                    SvUV_set(dstr, SvUVX(sstr));
                } else {

                    SvPV_set(dstr, SAVEPVN(SvPVX_const(sstr), SvCUR(sstr)));
                    SvFAKE_off(dstr);
                    SvREADONLY_off(dstr);
                }
	    }
	    else {
		/* Some other special case - random pointer */
		SvPV_set(dstr, SvPVX(sstr));		
            }
	}
    }
    else {
	/* Copy the NULL */
	if (SvTYPE(dstr) == SVt_RV)
	    SvRV_set(dstr, NULL);
	else
	    SvPV_set(dstr, NULL);
    }
}

/* duplicate an SV of any type (including AV, HV etc) */

SV *
Perl_sv_dup(pTHX_ SV *sstr, CLONE_PARAMS* param)
{
    SV *dstr;

    if (!sstr || SvTYPE(sstr) == SVTYPEMASK)
	return NULL;
    /* look for it in the table first */
    dstr = (SV*)ptr_table_fetch(PL_ptr_table, sstr);
    if (dstr)
	return dstr;

    if(param->flags & CLONEf_JOIN_IN) {
        /** We are joining here so we don't want do clone
	    something that is bad **/
	if (SvTYPE(sstr) == SVt_PVHV) {
	    const char * const hvname = HvNAME_get(sstr);
	    if (hvname)
		/** don't clone stashes if they already exist **/
		return (SV*)gv_stashpv(hvname,0);
        }
    }

    /* create anew and remember what it is */
    new_SV(dstr);
    ptr_table_store(PL_ptr_table, sstr, dstr);

    /* clone */
    SvFLAGS(dstr)	= SvFLAGS(sstr);
    SvFLAGS(dstr)	&= ~SVf_OOK;		/* don't propagate OOK hack */
    SvREFCNT(dstr)	= 0;			/* must be before any other dups! */

#ifdef DEBUGGING
    if (SvANY(sstr) && PL_watch_pvx && SvPVX_const(sstr) == PL_watch_pvx)
	PerlIO_printf(Perl_debug_log, "watch at %p hit, found string \"%s\"\n",
		      PL_watch_pvx, SvPVX_const(sstr));
#endif

    /* don't clone objects whose class has asked us not to */
    if (SvOBJECT(sstr) && ! (SvFLAGS(SvSTASH(sstr)) & SVphv_CLONEABLE)) {
	SvFLAGS(dstr) = 0;
	return dstr;
    }

    switch (SvTYPE(sstr)) {
    case SVt_NULL:
	SvANY(dstr)	= NULL;
	break;
    case SVt_IV:
    case SVt_NV:
    case SVt_RV:
	{
	    /* These are all the types that need simple bodies allocating.  */
	    void *new_body;
	    const svtype sv_type = SvTYPE(sstr);
	    const struct body_details *const sv_type_details
		= bodies_by_type + sv_type;

	    assert(sv_type_details->body_size);
#ifndef PURIFY
	    assert(sv_type_details->arena);
	    new_body_inline(new_body, sv_type);
	    new_body = (void*)((char*)new_body - sv_type_details->offset);
#else
	    assert(!sv_type_details->arena);
	    new_body = new_NOARENA(sv_type_details);
#endif

	    assert(new_body);
	    SvANY(dstr) = new_body;

	    if (sv_type == SVt_RV) {
		Perl_rvpv_dup(aTHX_ dstr, sstr, param);
	    } else {
#ifndef PURIFY
		Copy(((char*)SvANY(sstr)) + sv_type_details->offset,
		     ((char*)SvANY(dstr)) + sv_type_details->offset,
		     sv_type_details->copy, char);
#else
		Copy(((char*)SvANY(sstr)),
		     ((char*)SvANY(dstr)),
		     sv_type_details->body_size + sv_type_details->offset, char);
#endif
	    }
	    break;
	}
    default:
	{
	    /* These are all the types that need complex bodies allocating.  */
	    void *new_body;
	    const svtype sv_type = SvTYPE(sstr);
	    const struct body_details *const sv_type_details
		= bodies_by_type + sv_type;

	    switch (sv_type) {
	    default:
		Perl_croak(aTHX_ "Bizarre SvTYPE [%" IVdf "]", (IV)SvTYPE(sstr));
		break;

	    case SVt_PVGV:
		if (GvUNIQUE((GV*)sstr)) {
		    NOOP;   /* Do sharing here, and fall through */
		}
	    case SVt_PVIO:
	    case SVt_PVFM:
	    case SVt_PVHV:
	    case SVt_PVAV:
	    case SVt_PVBM:
	    case SVt_PVCV:
	    case SVt_PVLV:
	    case SVt_PVMG:
	    case SVt_PVNV:
	    case SVt_PVIV:
	    case SVt_PV:
		assert(sv_type_details->body_size);
		if (sv_type_details->arena) {
		    new_body_inline(new_body, sv_type);
		    new_body
			= (void*)((char*)new_body - sv_type_details->offset);
		} else {
		    new_body = new_NOARENA(sv_type_details);
		}
	    }
	    assert(new_body);
	    SvANY(dstr) = new_body;

#ifndef PURIFY
	    Copy(((char*)SvANY(sstr)) + sv_type_details->offset,
		 ((char*)SvANY(dstr)) + sv_type_details->offset,
		 sv_type_details->copy, char);
#else
	    Copy(((char*)SvANY(sstr)),
		 ((char*)SvANY(dstr)),
		 sv_type_details->body_size + sv_type_details->offset, char);
#endif

	    if (sv_type != SVt_PVAV && sv_type != SVt_PVHV)
		Perl_rvpv_dup(aTHX_ dstr, sstr, param);

	    /* The Copy above means that all the source (unduplicated) pointers
	       are now in the destination.  We can check the flags and the
	       pointers in either, but it's possible that there's less cache
	       missing by always going for the destination.
	       FIXME - instrument and check that assumption  */
	    if (sv_type >= SVt_PVMG) {
		if (SvMAGIC(dstr))
		    SvMAGIC_set(dstr, mg_dup(SvMAGIC(dstr), param));
		if (SvSTASH(dstr))
		    SvSTASH_set(dstr, hv_dup_inc(SvSTASH(dstr), param));
	    }

	    /* The cast silences a GCC warning about unhandled types.  */
	    switch ((int)sv_type) {
	    case SVt_PV:
		break;
	    case SVt_PVIV:
		break;
	    case SVt_PVNV:
		break;
	    case SVt_PVMG:
		break;
	    case SVt_PVBM:
		break;
	    case SVt_PVLV:
		/* XXX LvTARGOFF sometimes holds PMOP* when DEBUGGING */
		if (LvTYPE(dstr) == 't') /* for tie: unrefcnted fake (SV**) */
		    LvTARG(dstr) = dstr;
		else if (LvTYPE(dstr) == 'T') /* for tie: fake HE */
		    LvTARG(dstr) = (SV*)he_dup((HE*)LvTARG(dstr), 0, param);
		else
		    LvTARG(dstr) = sv_dup_inc(LvTARG(dstr), param);
		break;
	    case SVt_PVGV:
		GvXPVGV(dstr)->xgv_name	= SAVEPVN(GvNAME(dstr), GvNAMELEN(dstr));

		GvSTASH(dstr)	= hv_dup_inc(GvSTASH(dstr), param);
		GvGP(dstr)	= gp_dup(GvGP(dstr), param);
		(void)GpREFCNT_inc(GvGP(dstr));
		break;
	    case SVt_PVIO:
		IoIFP(dstr)	= fp_dup(IoIFP(dstr), IoTYPE(dstr), param);
		if (IoOFP(dstr) == IoIFP(sstr))
		    IoOFP(dstr) = IoIFP(dstr);
		else
		    IoOFP(dstr)	= fp_dup(IoOFP(dstr), IoTYPE(dstr), param);
		/* PL_rsfp_filters entries have fake IoDIRP() */
		if(IoFLAGS(dstr) & IOf_FAKE_DIRP) {
		    /* I have no idea why fake dirp (rsfps)
		       should be treated differently but otherwise
		       we end up with leaks -- sky*/
		    IoTOP_GV(dstr)      = gv_dup_inc(IoTOP_GV(dstr), param);
		    IoFMT_GV(dstr)      = gv_dup_inc(IoFMT_GV(dstr), param);
		    IoBOTTOM_GV(dstr)   = gv_dup_inc(IoBOTTOM_GV(dstr), param);
		} else {
		    IoTOP_GV(dstr)      = gv_dup(IoTOP_GV(dstr), param);
		    IoFMT_GV(dstr)      = gv_dup(IoFMT_GV(dstr), param);
		    IoBOTTOM_GV(dstr)   = gv_dup(IoBOTTOM_GV(dstr), param);
		    if (IoDIRP(dstr)) {
			IoDIRP(dstr)	= dirp_dup(IoDIRP(dstr));
		    } else {
			NOOP;
			/* IoDIRP(dstr) is already a copy of IoDIRP(sstr)  */
		    }
		}
		IoTOP_NAME(dstr)	= SAVEPV(IoTOP_NAME(dstr));
		IoFMT_NAME(dstr)	= SAVEPV(IoFMT_NAME(dstr));
		IoBOTTOM_NAME(dstr)	= SAVEPV(IoBOTTOM_NAME(dstr));
		break;
	    case SVt_PVAV:
		if (AvARRAY((AV*)sstr)) {
		    SV **dst_ary, **src_ary;
		    SSize_t items = AvFILLp((AV*)sstr) + 1;

		    src_ary = AvARRAY((AV*)sstr);
		    Newz(0, dst_ary, AvMAX((AV*)sstr)+1, SV*);
		    ptr_table_store(PL_ptr_table, src_ary, dst_ary);
		    SvPV_set(dstr, (char*)dst_ary);
		    AvALLOC((AV*)dstr) = dst_ary;
		    if (AvREAL((AV*)sstr)) {
			while (items-- > 0)
			    *dst_ary++ = sv_dup_inc(*src_ary++, param);
		    }
		    else {
			while (items-- > 0)
			    *dst_ary++ = sv_dup(*src_ary++, param);
		    }
		    items = AvMAX((AV*)sstr) - AvFILLp((AV*)sstr);
		    while (items-- > 0) {
			*dst_ary++ = &PL_sv_undef;
		    }
		}
		else {
		    SvPV_set(dstr, NULL);
		    AvALLOC((AV*)dstr)	= (SV**)NULL;
		}
		AvARYLEN((AV*)dstr) = sv_dup_inc(AvARYLEN((AV*)sstr), param);
		break;
	    case SVt_PVHV:
		if (HvARRAY((HV*)sstr)) {
		    bool sharekeys = !!HvSHAREKEYS(sstr);
		    STRLEN i = 0;
		    XPVHV *dxhv = (XPVHV*)SvANY(dstr);
		    XPVHV *sxhv = (XPVHV*)SvANY(sstr);
		    Newx(dxhv->xhv_array,
			 PERL_HV_ARRAY_ALLOC_BYTES(dxhv->xhv_max+1), char);
		    while (i <= sxhv->xhv_max) {
			HE *source = HvARRAY(sstr)[i];
			HvARRAY(dstr)[i]
			    = source ? he_dup(source, sharekeys, param) : 0;
			++i;
		    }
		    dxhv->xhv_eiter = he_dup(sxhv->xhv_eiter,
					     (bool)!!HvSHAREKEYS(sstr), param);
		}
		else {
		    SvPV_set(dstr, NULL);
		    HvEITER_set((HV*)dstr, (HE*)NULL);
		}
		/* HvPMROOT is a plain assignment, not a clone. Bug?  */
		HvNAME((HV*)dstr)	= SAVEPV(HvNAME((HV*)sstr));
		/* Record stashes for possible cloning in Perl_clone(). */
		if(HvNAME((HV*)dstr))
		    av_push(param->stashes, dstr);
		break;
	    case SVt_PVFM:
	    case SVt_PVCV:
		/* NOTE: not refcounted */
		CvSTASH(dstr)	= hv_dup(CvSTASH(dstr), param);
		OP_REFCNT_LOCK;
		CvROOT(dstr)	= OpREFCNT_inc(CvROOT(dstr));
		OP_REFCNT_UNLOCK;
		if (CvCONST(dstr) && CvISXSUB(dstr)) {
		    CvXSUBANY(dstr).any_ptr = GvUNIQUE(CvGV(dstr)) ?
			SvREFCNT_inc(CvXSUBANY(dstr).any_ptr) :
			sv_dup_inc((SV *)CvXSUBANY(dstr).any_ptr, param);
		}
		/* don't dup if copying back - CvGV isn't refcounted, so the
		 * duped GV may never be freed. A bit of a hack! DAPM */
		CvGV(dstr)	= (param->flags & CLONEf_JOIN_IN) ?
		    NULL : gv_dup(CvGV(dstr), param) ;
		if (!(param->flags & CLONEf_COPY_STACKS)) {
		    CvDEPTH(dstr) = 0;
		}
		PAD_DUP(CvPADLIST(dstr), CvPADLIST(sstr), param);
		CvOUTSIDE(dstr)	=
		    CvWEAKOUTSIDE(sstr)
		    ? cv_dup(    CvOUTSIDE(dstr), param)
		    : cv_dup_inc(CvOUTSIDE(dstr), param);
		if (!CvISXSUB(dstr))
		    CvFILE(dstr) = SAVEPV(CvFILE(dstr));
		break;
	    }
	}
    }

    if (SvOBJECT(dstr) && SvTYPE(dstr) != SVt_PVIO)
	++PL_sv_objcount;

    return dstr;
 }

/* duplicate a context */

PERL_CONTEXT *
Perl_cx_dup(pTHX_ PERL_CONTEXT *cxs, I32 ix, I32 max, CLONE_PARAMS* param)
{
    PERL_CONTEXT *ncxs;

    if (!cxs)
	return (PERL_CONTEXT*)NULL;

    /* look for it in the table first */
    ncxs = (PERL_CONTEXT*)ptr_table_fetch(PL_ptr_table, cxs);
    if (ncxs)
	return ncxs;

    /* create anew and remember what it is */
    Newx(ncxs, max + 1, PERL_CONTEXT);
    ptr_table_store(PL_ptr_table, cxs, ncxs);
    Copy(cxs, ncxs, max + 1, PERL_CONTEXT);

    while (ix >= 0) {
	PERL_CONTEXT * const ncx = &ncxs[ix];
	if (CxTYPE(ncx) == CXt_SUBST) {
	    Perl_croak(aTHX_ "Cloning substitution context is unimplemented");
	}
	else {
	    switch (CxTYPE(ncx)) {
	    case CXt_SUB:
		ncx->blk_sub.cv		= (ncx->blk_sub.olddepth == 0
					   ? cv_dup_inc(ncx->blk_sub.cv, param)
					   : cv_dup(ncx->blk_sub.cv,param));
		ncx->blk_sub.argarray	= (CxHASARGS(ncx)
					   ? av_dup_inc(ncx->blk_sub.argarray,
							param)
					   : NULL);
		ncx->blk_sub.savearray	= av_dup_inc(ncx->blk_sub.savearray,
						     param);
		ncx->blk_sub.oldcomppad = (PAD*)ptr_table_fetch(PL_ptr_table,
					   ncx->blk_sub.oldcomppad);
		break;
	    case CXt_EVAL:
		ncx->blk_eval.old_namesv = sv_dup_inc(ncx->blk_eval.old_namesv,
						      param);
		ncx->blk_eval.cur_text	= sv_dup(ncx->blk_eval.cur_text, param);
		break;
	    case CXt_LOOP:
		ncx->blk_loop.iterdata	= (CxPADLOOP(ncx)
					   ? ncx->blk_loop.iterdata
					   : gv_dup((GV*)ncx->blk_loop.iterdata,
						    param));
		ncx->blk_loop.oldcomppad
		    = (PAD*)ptr_table_fetch(PL_ptr_table,
					    ncx->blk_loop.oldcomppad);
		ncx->blk_loop.iterlval	= sv_dup_inc(ncx->blk_loop.iterlval,
						     param);
		ncx->blk_loop.iterary	= av_dup_inc(ncx->blk_loop.iterary,
						     param);
		break;
	    case CXt_FORMAT:
		ncx->blk_sub.cv		= cv_dup(ncx->blk_sub.cv, param);
		ncx->blk_sub.gv		= gv_dup(ncx->blk_sub.gv, param);
		ncx->blk_sub.dfoutgv	= gv_dup_inc(ncx->blk_sub.dfoutgv,
						     param);
		break;
	    case CXt_BLOCK:
	    case CXt_NULL:
		break;
	    }
	}
	--ix;
    }
    return ncxs;
}

/* duplicate a stack info structure */

PERL_SI *
Perl_si_dup(pTHX_ PERL_SI *si, CLONE_PARAMS* param)
{
    PERL_SI *nsi;

    if (!si)
	return (PERL_SI*)NULL;

    /* look for it in the table first */
    nsi = (PERL_SI*)ptr_table_fetch(PL_ptr_table, si);
    if (nsi)
	return nsi;

    /* create anew and remember what it is */
    Newxz(nsi, 1, PERL_SI);
    ptr_table_store(PL_ptr_table, si, nsi);

    nsi->si_stack	= av_dup_inc(si->si_stack, param);
    nsi->si_cxix	= si->si_cxix;
    nsi->si_cxmax	= si->si_cxmax;
    nsi->si_cxstack	= cx_dup(si->si_cxstack, si->si_cxix, si->si_cxmax, param);
    nsi->si_type	= si->si_type;
    nsi->si_prev	= si_dup(si->si_prev, param);
    nsi->si_next	= si_dup(si->si_next, param);
    nsi->si_markoff	= si->si_markoff;

    return nsi;
}

#define POPINT(ss,ix)	((ss)[--(ix)].any_i32)
#define TOPINT(ss,ix)	((ss)[ix].any_i32)
#define POPLONG(ss,ix)	((ss)[--(ix)].any_long)
#define TOPLONG(ss,ix)	((ss)[ix].any_long)
#define POPIV(ss,ix)	((ss)[--(ix)].any_iv)
#define TOPIV(ss,ix)	((ss)[ix].any_iv)
#define POPBOOL(ss,ix)	((ss)[--(ix)].any_bool)
#define TOPBOOL(ss,ix)	((ss)[ix].any_bool)
#define POPPTR(ss,ix)	((ss)[--(ix)].any_ptr)
#define TOPPTR(ss,ix)	((ss)[ix].any_ptr)
#define POPDPTR(ss,ix)	((ss)[--(ix)].any_dptr)
#define TOPDPTR(ss,ix)	((ss)[ix].any_dptr)
#define POPDXPTR(ss,ix)	((ss)[--(ix)].any_dxptr)
#define TOPDXPTR(ss,ix)	((ss)[ix].any_dxptr)

/* XXXXX todo */
#define pv_dup_inc(p)	SAVEPV(p)
#define pv_dup(p)	SAVEPV(p)
#define svp_dup_inc(p,pp)	any_dup(p,pp)

/* map any object to the new equivent - either something in the
 * ptr table, or something in the interpreter structure
 */

void *
Perl_any_dup(pTHX_ void *v, PerlInterpreter *proto_perl)
{
    void *ret;

    if (!v)
	return (void*)NULL;

    /* look for it in the table first */
    ret = ptr_table_fetch(PL_ptr_table, v);
    if (ret)
	return ret;

    /* see if it is part of the interpreter structure */
    if (v >= (void*)proto_perl && v < (void*)(proto_perl+1))
	ret = (void*)(((char*)aTHX) + (((char*)v) - (char*)proto_perl));
    else {
	ret = v;
    }

    return ret;
}

/* duplicate the save stack */

ANY *
Perl_ss_dup(pTHX_ PerlInterpreter *proto_perl, CLONE_PARAMS* param)
{
    ANY * const ss	= proto_perl->Tsavestack;
    const I32 max	= proto_perl->Tsavestack_max;
    I32 ix		= proto_perl->Tsavestack_ix;
    ANY *nss;
    SV *sv;
    GV *gv;
    AV *av;
    HV *hv;
    void* ptr;
    int intval;
    long longval;
    GP *gp;
    IV iv;
    I32 i;
    char *c = NULL;
    void (*dptr) (void*);
    void (*dxptr) (pTHX_ void*);

    Newxz(nss, max, ANY);

    while (ix > 0) {
	const I32 type = POPINT(ss,ix);
	TOPINT(nss,ix) = type;
	switch (type) {
	case SAVEt_HELEM:		/* hash element */
	    sv = (SV*)POPPTR(ss,ix);
	    TOPPTR(nss,ix) = sv_dup_inc(sv, param);
	    /* fall through */
	case SAVEt_ITEM:			/* normal string */
        case SAVEt_SV:				/* scalar reference */
	    sv = (SV*)POPPTR(ss,ix);
	    TOPPTR(nss,ix) = sv_dup_inc(sv, param);
	    /* fall through */
	case SAVEt_FREESV:
	case SAVEt_MORTALIZESV:
	    sv = (SV*)POPPTR(ss,ix);
	    TOPPTR(nss,ix) = sv_dup_inc(sv, param);
	    break;
	case SAVEt_GENERIC_PVREF:		/* generic char* */
	    c = (char*)POPPTR(ss,ix);
	    TOPPTR(nss,ix) = pv_dup(c);
	    ptr = POPPTR(ss,ix);
	    TOPPTR(nss,ix) = any_dup(ptr, proto_perl);
	    break;
	case SAVEt_SHARED_PVREF:		/* char* in shared space */
	    c = (char*)POPPTR(ss,ix);
	    TOPPTR(nss,ix) = savesharedpv(c);
	    ptr = POPPTR(ss,ix);
	    TOPPTR(nss,ix) = any_dup(ptr, proto_perl);
	    break;
        case SAVEt_GENERIC_SVREF:		/* generic sv */
        case SAVEt_SVREF:			/* scalar reference */
	    sv = (SV*)POPPTR(ss,ix);
	    TOPPTR(nss,ix) = sv_dup_inc(sv, param);
	    ptr = POPPTR(ss,ix);
	    TOPPTR(nss,ix) = svp_dup_inc((SV**)ptr, proto_perl);/* XXXXX */
	    break;
        case SAVEt_HV:				/* hash reference */
        case SAVEt_AV:				/* array reference */
	    sv = (SV*) POPPTR(ss,ix);
	    TOPPTR(nss,ix) = sv_dup_inc(sv, param);
	    /* fall through */
	case SAVEt_COMPPAD:
	case SAVEt_NSTAB:
	    sv = (SV*) POPPTR(ss,ix);
	    TOPPTR(nss,ix) = sv_dup(sv, param);
	    break;
	case SAVEt_INT:				/* int reference */
	    ptr = POPPTR(ss,ix);
	    TOPPTR(nss,ix) = any_dup(ptr, proto_perl);
	    intval = (int)POPINT(ss,ix);
	    TOPINT(nss,ix) = intval;
	    break;
	case SAVEt_LONG:			/* long reference */
	    ptr = POPPTR(ss,ix);
	    TOPPTR(nss,ix) = any_dup(ptr, proto_perl);
	    /* fall through */
	case SAVEt_CLEARSV:
	    longval = (long)POPLONG(ss,ix);
	    TOPLONG(nss,ix) = longval;
	    break;
	case SAVEt_I32:				/* I32 reference */
	case SAVEt_I16:				/* I16 reference */
	case SAVEt_I8:				/* I8 reference */
	case SAVEt_COP_ARYBASE:			/* call CopARYBASE_set */
	    ptr = POPPTR(ss,ix);
	    TOPPTR(nss,ix) = any_dup(ptr, proto_perl);
	    i = POPINT(ss,ix);
	    TOPINT(nss,ix) = i;
	    break;
	case SAVEt_IV:				/* IV reference */
	    ptr = POPPTR(ss,ix);
	    TOPPTR(nss,ix) = any_dup(ptr, proto_perl);
	    iv = POPIV(ss,ix);
	    TOPIV(nss,ix) = iv;
	    break;
	case SAVEt_HPTR:			/* HV* reference */
	case SAVEt_APTR:			/* AV* reference */
	case SAVEt_SPTR:			/* SV* reference */
	    ptr = POPPTR(ss,ix);
	    TOPPTR(nss,ix) = any_dup(ptr, proto_perl);
	    sv = (SV*)POPPTR(ss,ix);
	    TOPPTR(nss,ix) = sv_dup(sv, param);
	    break;
	case SAVEt_VPTR:			/* random* reference */
	    ptr = POPPTR(ss,ix);
	    TOPPTR(nss,ix) = any_dup(ptr, proto_perl);
	    ptr = POPPTR(ss,ix);
	    TOPPTR(nss,ix) = any_dup(ptr, proto_perl);
	    break;
	case SAVEt_PPTR:			/* char* reference */
	    ptr = POPPTR(ss,ix);
	    TOPPTR(nss,ix) = any_dup(ptr, proto_perl);
	    c = (char*)POPPTR(ss,ix);
	    TOPPTR(nss,ix) = pv_dup(c);
	    break;
	case SAVEt_GP_OLD:			/* scalar reference */
	case SAVEt_GP_NEW:			/* scalar reference */
	    gp = (GP*)POPPTR(ss,ix);
	    TOPPTR(nss,ix) = gp = gp_dup(gp, param);
	    (void)GpREFCNT_inc(gp);
	    gv = (GV*)POPPTR(ss,ix);
	    TOPPTR(nss,ix) = gv_dup_inc(gv, param);
	    if (type == SAVEt_GP_OLD) {
		c = (char*)POPPTR(ss,ix);
		TOPPTR(nss,ix) = pv_dup(c);
		iv = POPIV(ss,ix);
		TOPIV(nss,ix) = iv;
		iv = POPIV(ss,ix);
		TOPIV(nss,ix) = iv;
	    }
            break;
	case SAVEt_FREEOP:
	    ptr = POPPTR(ss,ix);
	    if (ptr && (((OP*)ptr)->op_private & OPpREFCOUNTED)) {
		/* these are assumed to be refcounted properly */
		OP *o;
		switch (((OP*)ptr)->op_type) {
		case OP_LEAVESUB:
		case OP_LEAVESUBLV:
		case OP_LEAVEEVAL:
		case OP_LEAVE:
		case OP_SCOPE:
		case OP_LEAVEWRITE:
		    TOPPTR(nss,ix) = ptr;
		    o = (OP*)ptr;
		    OP_REFCNT_LOCK;
		    (void) OpREFCNT_inc(o);
		    OP_REFCNT_UNLOCK;
		    break;
		default:
		    TOPPTR(nss,ix) = NULL;
		    break;
		}
	    }
	    else
		TOPPTR(nss,ix) = NULL;
	    break;
	case SAVEt_FREEPV:
	    c = (char*)POPPTR(ss,ix);
	    TOPPTR(nss,ix) = pv_dup_inc(c);
	    break;
	case SAVEt_DELETE:
	    hv = (HV*)POPPTR(ss,ix);
	    TOPPTR(nss,ix) = hv_dup_inc(hv, param);
	    c = (char*)POPPTR(ss,ix);
	    TOPPTR(nss,ix) = pv_dup_inc(c);
	    /* fall through */
	case SAVEt_STACK_POS:		/* Position on Perl stack */
	    i = POPINT(ss,ix);
	    TOPINT(nss,ix) = i;
	    break;
	case SAVEt_DESTRUCTOR:
	    ptr = POPPTR(ss,ix);
	    TOPPTR(nss,ix) = any_dup(ptr, proto_perl);	/* XXX quite arbitrary */
	    dptr = POPDPTR(ss,ix);
	    TOPDPTR(nss,ix) = DPTR2FPTR(void (*)(void*),
					any_dup(FPTR2DPTR(void *, dptr),
						proto_perl));
	    break;
	case SAVEt_DESTRUCTOR_X:
	    ptr = POPPTR(ss,ix);
	    TOPPTR(nss,ix) = any_dup(ptr, proto_perl);	/* XXX quite arbitrary */
	    dxptr = POPDXPTR(ss,ix);
	    TOPDXPTR(nss,ix) = DPTR2FPTR(void (*)(pTHX_ void*),
					 any_dup(FPTR2DPTR(void *, dxptr),
						 proto_perl));
	    break;
	case SAVEt_REGCONTEXT:
	case SAVEt_ALLOC:
	    i = POPINT(ss,ix);
	    TOPINT(nss,ix) = i;
	    ix -= i;
	    break;
	case SAVEt_AELEM:		/* array element */
	    sv = (SV*)POPPTR(ss,ix);
	    TOPPTR(nss,ix) = sv_dup_inc(sv, param);
	    i = POPINT(ss,ix);
	    TOPINT(nss,ix) = i;
	    av = (AV*)POPPTR(ss,ix);
	    TOPPTR(nss,ix) = av_dup_inc(av, param);
	    break;
	case SAVEt_OP:
	    ptr = POPPTR(ss,ix);
	    TOPPTR(nss,ix) = ptr;
	    break;
	case SAVEt_HINTS:
	    i = POPINT(ss,ix);
	    TOPINT(nss,ix) = i;
	    break;
	case SAVEt_PADSV_AND_MORTALIZE:
	    longval = (long)POPLONG(ss,ix);
	    TOPLONG(nss,ix) = longval;
	    ptr = POPPTR(ss,ix);
	    TOPPTR(nss,ix) = any_dup(ptr, proto_perl);
	    sv = (SV*)POPPTR(ss,ix);
	    TOPPTR(nss,ix) = sv_dup_inc(sv, param);
	    break;
	case SAVEt_BOOL:
	    ptr = POPPTR(ss,ix);
	    TOPPTR(nss,ix) = any_dup(ptr, proto_perl);
	    longval = (long)POPBOOL(ss,ix);
	    TOPBOOL(nss,ix) = (bool)longval;
	    break;
	case SAVEt_RE_STATE:
	    {
		const struct re_save_state *const old_state
		    = (struct re_save_state *)
		    (ss + ix - SAVESTACK_ALLOC_FOR_RE_SAVE_STATE);
		struct re_save_state *const new_state
		    = (struct re_save_state *)
		    (nss + ix - SAVESTACK_ALLOC_FOR_RE_SAVE_STATE);

		Copy(old_state, new_state, 1, struct re_save_state);
		ix -= SAVESTACK_ALLOC_FOR_RE_SAVE_STATE;

		new_state->re_state_bostr
		    = pv_dup(old_state->re_state_bostr);
		new_state->re_state_reginput
		    = pv_dup(old_state->re_state_reginput);
		new_state->re_state_regbol
		    = pv_dup(old_state->re_state_regbol);
		new_state->re_state_regeol
		    = pv_dup(old_state->re_state_regeol);
		new_state->re_state_regstartp
		    = (I32*) any_dup(old_state->re_state_regstartp, proto_perl);
		new_state->re_state_regendp
		    = (I32*) any_dup(old_state->re_state_regendp, proto_perl);
		new_state->re_state_reglastparen
		    = (U32*) any_dup(old_state->re_state_reglastparen, 
			      proto_perl);
		new_state->re_state_reglastcloseparen
		    = (U32*)any_dup(old_state->re_state_reglastcloseparen,
			      proto_perl);
		new_state->re_state_regtill
		    = pv_dup(old_state->re_state_regtill);
		/* XXX This just has to be broken. The old save_re_context
		   code did SAVEGENERICPV(PL_reg_start_tmp);
		   PL_reg_start_tmp is char **.
		   Look above to what the dup code does for
		   SAVEt_GENERIC_PVREF
		   It can never have worked.
		   So this is merely a faithful copy of the exiting bug:  */
		new_state->re_state_reg_start_tmp
		    = (char **) pv_dup((char *)
				      old_state->re_state_reg_start_tmp);
		/* I assume that it only ever "worked" because no-one called
		   (pseudo)fork while the regexp engine had re-entered itself.
		*/
		new_state->re_state_reg_call_cc =
		    (struct re_cc_state *)
		    any_dup(old_state->re_state_reg_call_cc, proto_perl);
		new_state->re_state_reg_re =
		    (struct regexp *)
		    any_dup(old_state->re_state_reg_re, proto_perl);
		new_state->re_state_reg_ganch
		    = pv_dup(old_state->re_state_reg_ganch);
		new_state->re_state_reg_sv
		    = sv_dup(old_state->re_state_reg_sv, param);
#ifdef PERL_OLD_COPY_ON_WRITE
		new_state->re_state_nrs
		    = sv_dup(old_state->re_state_nrs, param);
#endif
		new_state->re_state_reg_magic
		    = (MAGIC*) any_dup(old_state->re_state_reg_magic, 
			       proto_perl);
		new_state->re_state_reg_oldcurpm
		    = (PMOP*) any_dup(old_state->re_state_reg_oldcurpm, 
			      proto_perl);
		new_state->re_state_reg_curpm
		    = (PMOP*)  any_dup(old_state->re_state_reg_curpm, 
			       proto_perl);
		new_state->re_state_reg_oldsaved
		    = pv_dup(old_state->re_state_reg_oldsaved);
		new_state->re_state_reg_poscache
		    = pv_dup(old_state->re_state_reg_poscache);
		new_state->re_state_reg_starttry
		    = pv_dup(old_state->re_state_reg_starttry);
		break;
	    }
	case SAVEt_PADSV:
	    /* Nothing should be using this any more, post the integration of
	       blead change 33080. But keep it, in case something out there is
	       generating these on the scope stack.  */
	    longval = (long)POPLONG(ss,ix);
	    TOPLONG(nss,ix) = longval;
	    ptr = POPPTR(ss,ix);
	    TOPPTR(nss,ix) = any_dup(ptr, proto_perl);
	    sv = (SV*)POPPTR(ss,ix);
	    TOPPTR(nss,ix) = sv_dup(sv, param);
	    break;
	default:
	    Perl_croak(aTHX_
		       "panic: ss_dup inconsistency (%"IVdf")", (IV) type);
	}
    }

    return nss;
}


/* if sv is a stash, call $class->CLONE_SKIP(), and set the SVphv_CLONEABLE
 * flag to the result. This is done for each stash before cloning starts,
 * so we know which stashes want their objects cloned */

static void
do_mark_cloneable_stash(pTHX_ SV *sv)
{
    const char *const hvname = HvNAME_get((HV*)sv);
    if (hvname) {
	GV* const cloner = gv_fetchmethod_autoload((HV*)sv, "CLONE_SKIP", 0);
	SvFLAGS(sv) |= SVphv_CLONEABLE; /* clone objects by default */
	if (cloner && GvCV(cloner)) {
	    dSP;
	    UV status;

	    ENTER;
	    SAVETMPS;
	    PUSHMARK(SP);
	    mXPUSHs(newSVpv(hvname, 0));
	    PUTBACK;
	    call_sv((SV*)GvCV(cloner), G_SCALAR);
	    SPAGAIN;
	    status = POPu;
	    PUTBACK;
	    FREETMPS;
	    LEAVE;
	    if (status)
		SvFLAGS(sv) &= ~SVphv_CLONEABLE;
	}
    }
}



/*
=for apidoc perl_clone

Create and return a new interpreter by cloning the current one.

perl_clone takes these flags as parameters:

CLONEf_COPY_STACKS - is used to, well, copy the stacks also, 
without it we only clone the data and zero the stacks, 
with it we copy the stacks and the new perl interpreter is 
ready to run at the exact same point as the previous one. 
The pseudo-fork code uses COPY_STACKS while the 
threads->create doesn't.

CLONEf_KEEP_PTR_TABLE
perl_clone keeps a ptr_table with the pointer of the old 
variable as a key and the new variable as a value, 
this allows it to check if something has been cloned and not 
clone it again but rather just use the value and increase the 
refcount. If KEEP_PTR_TABLE is not set then perl_clone will kill 
the ptr_table using the function 
C<ptr_table_free(PL_ptr_table); PL_ptr_table = NULL;>, 
reason to keep it around is if you want to dup some of your own 
variable who are outside the graph perl scans, example of this 
code is in threads.xs create

CLONEf_CLONE_HOST
This is a win32 thing, it is ignored on unix, it tells perls 
win32host code (which is c++) to clone itself, this is needed on 
win32 if you want to run two threads at the same time, 
if you just want to do some stuff in a separate perl interpreter 
and then throw it away and return to the original one, 
you don't need to do anything.

=cut
*/

/* XXX the above needs expanding by someone who actually understands it ! */
EXTERN_C PerlInterpreter *
perl_clone_host(PerlInterpreter* proto_perl, UV flags);

PerlInterpreter *
perl_clone(PerlInterpreter *proto_perl, UV flags)
{
#ifdef PERL_IMPLICIT_SYS

   /* perlhost.h so we need to call into it
   to clone the host, CPerlHost should have a c interface, sky */

   if (flags & CLONEf_CLONE_HOST) {
       return perl_clone_host(proto_perl,flags);
   }
   return perl_clone_using(proto_perl, flags,
			    proto_perl->IMem,
			    proto_perl->IMemShared,
			    proto_perl->IMemParse,
			    proto_perl->IEnv,
			    proto_perl->IStdIO,
			    proto_perl->ILIO,
			    proto_perl->IDir,
			    proto_perl->ISock,
			    proto_perl->IProc);
}

PerlInterpreter *
perl_clone_using(PerlInterpreter *proto_perl, UV flags,
		 struct IPerlMem* ipM, struct IPerlMem* ipMS,
		 struct IPerlMem* ipMP, struct IPerlEnv* ipE,
		 struct IPerlStdIO* ipStd, struct IPerlLIO* ipLIO,
		 struct IPerlDir* ipD, struct IPerlSock* ipS,
		 struct IPerlProc* ipP)
{
    /* XXX many of the string copies here can be optimized if they're
     * constants; they need to be allocated as common memory and just
     * their pointers copied. */

    IV i;
    CLONE_PARAMS clone_params;
    CLONE_PARAMS* const param = &clone_params;

    PerlInterpreter * const my_perl = (PerlInterpreter*)(*ipM->pMalloc)(ipM, sizeof(PerlInterpreter));
    /* for each stash, determine whether its objects should be cloned */
    S_visit(proto_perl, do_mark_cloneable_stash, SVt_PVHV, SVTYPEMASK);
    PERL_SET_THX(my_perl);

#  ifdef DEBUGGING
    Poison(my_perl, 1, PerlInterpreter);
    PL_op = NULL;
    PL_curcop = NULL;
    PL_markstack = 0;
    PL_scopestack = 0;
    PL_savestack = 0;
    PL_savestack_ix = 0;
    PL_savestack_max = -1;
    PL_retstack = 0;
    PL_sig_pending = 0;
    Zero(&PL_debug_pad, 1, struct perl_debug_pad);
#  else	/* !DEBUGGING */
    Zero(my_perl, 1, PerlInterpreter);
#  endif	/* DEBUGGING */

    /* host pointers */
    PL_Mem		= ipM;
    PL_MemShared	= ipMS;
    PL_MemParse		= ipMP;
    PL_Env		= ipE;
    PL_StdIO		= ipStd;
    PL_LIO		= ipLIO;
    PL_Dir		= ipD;
    PL_Sock		= ipS;
    PL_Proc		= ipP;
#else		/* !PERL_IMPLICIT_SYS */
    IV i;
    CLONE_PARAMS clone_params;
    CLONE_PARAMS* param = &clone_params;
    PerlInterpreter * const my_perl = (PerlInterpreter*)PerlMem_malloc(sizeof(PerlInterpreter));
    /* for each stash, determine whether its objects should be cloned */
    S_visit(proto_perl, do_mark_cloneable_stash, SVt_PVHV, SVTYPEMASK);
    PERL_SET_THX(my_perl);

#    ifdef DEBUGGING
    Poison(my_perl, 1, PerlInterpreter);
    PL_op = NULL;
    PL_curcop = NULL;
    PL_markstack = 0;
    PL_scopestack = 0;
    PL_savestack = 0;
    PL_savestack_ix = 0;
    PL_savestack_max = -1;
    PL_retstack = 0;
    PL_sig_pending = 0;
    Zero(&PL_debug_pad, 1, struct perl_debug_pad);
#    else	/* !DEBUGGING */
    Zero(my_perl, 1, PerlInterpreter);
#    endif	/* DEBUGGING */
#endif		/* PERL_IMPLICIT_SYS */
    param->flags = flags;
    param->proto_perl = proto_perl;

    INIT_TRACK_MEMPOOL(my_perl->Imemory_debug_header, my_perl);

    /* arena roots */
    PL_body_arenas = NULL;
    Zero(&PL_body_roots, 1, PL_body_roots);

    /* old arena roots */
    PL_xiv_arenaroot	= NULL;
    PL_xiv_root		= NULL;
    PL_xnv_arenaroot	= NULL;
    PL_xnv_root		= NULL;
    PL_xrv_arenaroot	= NULL;
    PL_xrv_root		= NULL;
    PL_xpv_arenaroot	= NULL;
    PL_xpv_root		= NULL;
    PL_xpviv_arenaroot	= NULL;
    PL_xpviv_root	= NULL;
    PL_xpvnv_arenaroot	= NULL;
    PL_xpvnv_root	= NULL;
    PL_xpvcv_arenaroot	= NULL;
    PL_xpvcv_root	= NULL;
    PL_xpvav_arenaroot	= NULL;
    PL_xpvav_root	= NULL;
    PL_xpvhv_arenaroot	= NULL;
    PL_xpvhv_root	= NULL;
    PL_xpvmg_arenaroot	= NULL;
    PL_xpvmg_root	= NULL;
    PL_xpvlv_arenaroot	= NULL;
    PL_xpvlv_root	= NULL;
    PL_xpvbm_arenaroot	= NULL;
    PL_xpvbm_root	= NULL;
    PL_nice_chunk	= NULL;
    PL_nice_chunk_size	= 0;
    PL_sv_count		= 0;
    PL_sv_objcount	= 0;
    PL_sv_root		= NULL;
    PL_sv_arenaroot	= NULL;

    PL_debug		= proto_perl->Idebug;

    PL_hash_seed	= proto_perl->Ihash_seed;
    PL_rehash_seed	= proto_perl->Irehash_seed;

#ifdef USE_REENTRANT_API
    /* XXX: things like -Dm will segfault here in perlio, but doing
     *  PERL_SET_CONTEXT(proto_perl);
     * breaks too many other things
     */
    Perl_reentrant_init(aTHX);
#endif

    /* create SV map for pointer relocation */
    PL_ptr_table = ptr_table_new();

    /* initialize these special pointers as early as possible */
    SvANY(&PL_sv_undef)		= NULL;
    SvREFCNT(&PL_sv_undef)	= (~(U32)0)/2;
    SvFLAGS(&PL_sv_undef)	= SVf_READONLY|SVt_NULL;
    ptr_table_store(PL_ptr_table, &proto_perl->Isv_undef, &PL_sv_undef);

    SvANY(&PL_sv_no)		= new_XPVNV();
    SvREFCNT(&PL_sv_no)		= (~(U32)0)/2;
    SvFLAGS(&PL_sv_no)		= SVp_IOK|SVf_IOK|SVp_NOK|SVf_NOK
				  |SVp_POK|SVf_POK|SVf_READONLY|SVt_PVNV;
    SvPV_set(&PL_sv_no, savepvn(PL_No, 0));
    SvCUR_set(&PL_sv_no, 0);
    SvLEN_set(&PL_sv_no, 1);
    SvIV_set(&PL_sv_no, 0);
    SvNV_set(&PL_sv_no, 0);
    ptr_table_store(PL_ptr_table, &proto_perl->Isv_no, &PL_sv_no);

    SvANY(&PL_sv_yes)		= new_XPVNV();
    SvREFCNT(&PL_sv_yes)	= (~(U32)0)/2;
    SvFLAGS(&PL_sv_yes)		= SVp_IOK|SVf_IOK|SVp_NOK|SVf_NOK
				  |SVp_POK|SVf_POK|SVf_READONLY|SVt_PVNV;
    SvPV_set(&PL_sv_yes, savepvn(PL_Yes, 1));
    SvCUR_set(&PL_sv_yes, 1);
    SvLEN_set(&PL_sv_yes, 2);
    SvIV_set(&PL_sv_yes, 1);
    SvNV_set(&PL_sv_yes, 1);
    ptr_table_store(PL_ptr_table, &proto_perl->Isv_yes, &PL_sv_yes);

    /* create (a non-shared!) shared string table */
    PL_strtab		= newHV();
    HvSHAREKEYS_off(PL_strtab);
    hv_ksplit(PL_strtab, HvTOTALKEYS(proto_perl->Istrtab));
    ptr_table_store(PL_ptr_table, proto_perl->Istrtab, PL_strtab);

    PL_compiling = proto_perl->Icompiling;

    /* RE engine - function pointers -- must initilize these before 
       re_dup() is called. dmq. */
    PL_regcompp		= proto_perl->Tregcompp;
    PL_regexecp		= proto_perl->Tregexecp;
    PL_regint_start	= proto_perl->Tregint_start;
    PL_regint_string	= proto_perl->Tregint_string;
    PL_regfree		= proto_perl->Tregfree;
    PL_regdupe		= proto_perl->Iregdupe;

    /* These two PVs will be free'd special way so must set them same way op.c does */
    PL_compiling.cop_stashpv = savesharedpv(PL_compiling.cop_stashpv);
    ptr_table_store(PL_ptr_table, proto_perl->Icompiling.cop_stashpv, PL_compiling.cop_stashpv);

    PL_compiling.cop_file    = savesharedpv(PL_compiling.cop_file);
    ptr_table_store(PL_ptr_table, proto_perl->Icompiling.cop_file, PL_compiling.cop_file);

    ptr_table_store(PL_ptr_table, &proto_perl->Icompiling, &PL_compiling);
    if (!specialWARN(PL_compiling.cop_warnings))
	PL_compiling.cop_warnings = sv_dup_inc(PL_compiling.cop_warnings, param);
    if (!specialCopIO(PL_compiling.cop_io))
	PL_compiling.cop_io = sv_dup_inc(PL_compiling.cop_io, param);
    PL_curcop		= (COP*)any_dup(proto_perl->Tcurcop, proto_perl);

    /* pseudo environmental stuff */
    PL_origargc		= proto_perl->Iorigargc;
    PL_origargv		= proto_perl->Iorigargv;

    param->stashes      = newAV();  /* Setup array of objects to call clone on */

#ifdef PERLIO_LAYERS
    /* Clone PerlIO tables as soon as we can handle general xx_dup() */
    PerlIO_clone(aTHX_ proto_perl, param);
#endif

    PL_envgv		= gv_dup(proto_perl->Ienvgv, param);
    PL_incgv		= gv_dup(proto_perl->Iincgv, param);
    PL_hintgv		= gv_dup(proto_perl->Ihintgv, param);
    PL_origfilename	= SAVEPV(proto_perl->Iorigfilename);
    PL_diehook		= sv_dup_inc(proto_perl->Idiehook, param);
    PL_warnhook		= sv_dup_inc(proto_perl->Iwarnhook, param);

    /* switches */
    PL_minus_c		= proto_perl->Iminus_c;
    PL_patchlevel	= sv_dup_inc(proto_perl->Ipatchlevel, param);
    PL_localpatches	= proto_perl->Ilocalpatches;
    PL_splitstr		= proto_perl->Isplitstr;
    PL_preprocess	= proto_perl->Ipreprocess;
    PL_minus_n		= proto_perl->Iminus_n;
    PL_minus_p		= proto_perl->Iminus_p;
    PL_minus_l		= proto_perl->Iminus_l;
    PL_minus_a		= proto_perl->Iminus_a;
    PL_minus_F		= proto_perl->Iminus_F;
    PL_doswitches	= proto_perl->Idoswitches;
    PL_dowarn		= proto_perl->Idowarn;
    PL_doextract	= proto_perl->Idoextract;
    PL_sawampersand	= proto_perl->Isawampersand;
    PL_unsafe		= proto_perl->Iunsafe;
    PL_inplace		= SAVEPV(proto_perl->Iinplace);
    PL_e_script		= sv_dup_inc(proto_perl->Ie_script, param);
    PL_perldb		= proto_perl->Iperldb;
    PL_perl_destruct_level = proto_perl->Iperl_destruct_level;
    PL_exit_flags       = proto_perl->Iexit_flags;

    /* magical thingies */
    /* XXX time(&PL_basetime) when asked for? */
    PL_basetime		= proto_perl->Ibasetime;
    PL_formfeed		= sv_dup(proto_perl->Iformfeed, param);

    PL_maxsysfd		= proto_perl->Imaxsysfd;
    PL_multiline	= proto_perl->Imultiline;
    PL_statusvalue	= proto_perl->Istatusvalue;
#ifdef VMS
    PL_statusvalue_vms	= proto_perl->Istatusvalue_vms;
#else
    PL_statusvalue_posix = proto_perl->Istatusvalue_posix;
#endif
    PL_encoding		= sv_dup(proto_perl->Iencoding, param);

    sv_setpvn(PERL_DEBUG_PAD(0), "", 0);	/* For regex debugging. */
    sv_setpvn(PERL_DEBUG_PAD(1), "", 0);	/* ext/re needs these */
    sv_setpvn(PERL_DEBUG_PAD(2), "", 0);	/* even without DEBUGGING. */

    PL_reginterp_cnt	= 0;
    PL_reg_starttry	= 0;
    
    /* Clone the regex array */
    PL_regex_padav = newAV();
    {
	const I32 len = av_len((AV*)proto_perl->Iregex_padav);
	SV* const * const regexen = AvARRAY((AV*)proto_perl->Iregex_padav);
	IV i;
	av_push(PL_regex_padav, sv_dup_inc_NN(regexen[0],param));
	for(i = 1; i <= len; i++) {
	    const SV * const regex = regexen[i];
	    SV * const sv =
		SvREPADTMP(regex)
		    ? sv_dup_inc((SV *)regex, param)
		    : SvREFCNT_inc(
			newSViv(PTR2IV(re_dup(
				INT2PTR(REGEXP *, SvIVX(regex)), param))))
		;
	    if (SvFLAGS(regex) & SVf_BREAK)
		SvFLAGS(sv) |= SVf_BREAK; /* unrefcnted PL_curpm */
	    av_push(PL_regex_padav, sv);
	}
    }
    PL_regex_pad = AvARRAY(PL_regex_padav);

    /* shortcuts to various I/O objects */
    PL_stdingv		= gv_dup(proto_perl->Istdingv, param);
    PL_stderrgv		= gv_dup(proto_perl->Istderrgv, param);
    PL_defgv		= gv_dup(proto_perl->Idefgv, param);
    PL_argvgv		= gv_dup(proto_perl->Iargvgv, param);
    PL_argvoutgv	= gv_dup(proto_perl->Iargvoutgv, param);
    PL_argvout_stack	= av_dup_inc(proto_perl->Iargvout_stack, param);

    /* shortcuts to regexp stuff */
    PL_replgv		= gv_dup(proto_perl->Ireplgv, param);

    /* shortcuts to misc objects */
    PL_errgv		= gv_dup(proto_perl->Ierrgv, param);

    /* shortcuts to debugging objects */
    PL_DBgv		= gv_dup(proto_perl->IDBgv, param);
    PL_DBline		= gv_dup(proto_perl->IDBline, param);
    PL_DBsub		= gv_dup(proto_perl->IDBsub, param);
    PL_DBsingle		= sv_dup(proto_perl->IDBsingle, param);
    PL_DBtrace		= sv_dup(proto_perl->IDBtrace, param);
    PL_DBsignal		= sv_dup(proto_perl->IDBsignal, param);
    PL_lineary		= av_dup(proto_perl->Ilineary, param);
    PL_dbargs		= av_dup(proto_perl->Idbargs, param);

    /* symbol tables */
    PL_defstash		= hv_dup_inc(proto_perl->Tdefstash, param);
    PL_curstash		= hv_dup(proto_perl->Tcurstash, param);
    PL_nullstash       = hv_dup(proto_perl->Inullstash, param);
    PL_debstash		= hv_dup(proto_perl->Idebstash, param);
    PL_globalstash	= hv_dup(proto_perl->Iglobalstash, param);
    PL_curstname	= sv_dup_inc(proto_perl->Icurstname, param);

    PL_beginav		= av_dup_inc(proto_perl->Ibeginav, param);
    PL_beginav_save	= av_dup_inc(proto_perl->Ibeginav_save, param);
    PL_checkav_save	= av_dup_inc(proto_perl->Icheckav_save, param);
    PL_endav		= av_dup_inc(proto_perl->Iendav, param);
    PL_checkav		= av_dup_inc(proto_perl->Icheckav, param);
    PL_initav		= av_dup_inc(proto_perl->Iinitav, param);

    PL_sub_generation	= proto_perl->Isub_generation;

    /* funky return mechanisms */
    PL_forkprocess	= proto_perl->Iforkprocess;

    /* subprocess state */
    PL_fdpid		= av_dup_inc(proto_perl->Ifdpid, param);

    /* internal state */
    PL_tainting		= proto_perl->Itainting;
    PL_taint_warn       = proto_perl->Itaint_warn;
    PL_maxo		= proto_perl->Imaxo;
    if (proto_perl->Iop_mask)
	PL_op_mask	= SAVEPVN(proto_perl->Iop_mask, PL_maxo);
    else
	PL_op_mask 	= NULL;

    /* current interpreter roots */
    PL_main_cv		= cv_dup_inc(proto_perl->Imain_cv, param);
    OP_REFCNT_LOCK;
    PL_main_root	= OpREFCNT_inc(proto_perl->Imain_root);
    OP_REFCNT_UNLOCK;
    PL_main_start	= proto_perl->Imain_start;
    PL_eval_root	= proto_perl->Ieval_root;
    PL_eval_start	= proto_perl->Ieval_start;

    /* runtime control stuff */
    PL_curcopdb		= (COP*)any_dup(proto_perl->Icurcopdb, proto_perl);
    PL_copline		= proto_perl->Icopline;

    PL_filemode		= proto_perl->Ifilemode;
    PL_lastfd		= proto_perl->Ilastfd;
    PL_oldname		= proto_perl->Ioldname;		/* XXX not quite right */
    PL_Argv		= NULL;
    PL_Cmd		= NULL;
    PL_gensym		= proto_perl->Igensym;
    PL_preambled	= proto_perl->Ipreambled;
    PL_preambleav	= av_dup_inc(proto_perl->Ipreambleav, param);
    PL_laststatval	= proto_perl->Ilaststatval;
    PL_laststype	= proto_perl->Ilaststype;
    PL_mess_sv		= NULL;

    PL_ors_sv		= sv_dup_inc(proto_perl->Iors_sv, param);
    PL_ofmt		= SAVEPV(proto_perl->Iofmt);

    /* interpreter atexit processing */
    PL_exitlistlen	= proto_perl->Iexitlistlen;
    if (PL_exitlistlen) {
	Newx(PL_exitlist, PL_exitlistlen, PerlExitListEntry);
	Copy(proto_perl->Iexitlist, PL_exitlist, PL_exitlistlen, PerlExitListEntry);
    }
    else
	PL_exitlist	= (PerlExitListEntry*)NULL;
    PL_modglobal	= hv_dup_inc(proto_perl->Imodglobal, param);
    PL_custom_op_names  = hv_dup_inc(proto_perl->Icustom_op_names,param);
    PL_custom_op_descs  = hv_dup_inc(proto_perl->Icustom_op_descs,param);

    PL_profiledata	= NULL;
    PL_rsfp		= fp_dup(proto_perl->Irsfp, '<', param);
    /* PL_rsfp_filters entries have fake IoDIRP() */
    PL_rsfp_filters	= av_dup_inc(proto_perl->Irsfp_filters, param);

    PL_compcv			= cv_dup(proto_perl->Icompcv, param);

    PAD_CLONE_VARS(proto_perl, param);

#ifdef HAVE_INTERP_INTERN
    sys_intern_dup(&proto_perl->Isys_intern, &PL_sys_intern);
#endif

    /* more statics moved here */
    PL_generation	= proto_perl->Igeneration;
    PL_DBcv		= cv_dup(proto_perl->IDBcv, param);

    PL_in_clean_objs	= proto_perl->Iin_clean_objs;
    PL_in_clean_all	= proto_perl->Iin_clean_all;

    PL_uid		= proto_perl->Iuid;
    PL_euid		= proto_perl->Ieuid;
    PL_gid		= proto_perl->Igid;
    PL_egid		= proto_perl->Iegid;
    PL_nomemok		= proto_perl->Inomemok;
    PL_an		= proto_perl->Ian;
    PL_op_seqmax	= proto_perl->Iop_seqmax;
    PL_evalseq		= proto_perl->Ievalseq;
    PL_origenviron	= proto_perl->Iorigenviron;	/* XXX not quite right */
    PL_origalen		= proto_perl->Iorigalen;
    PL_pidstatus	= newHV();			/* XXX flag for cloning? */
    PL_osname		= SAVEPV(proto_perl->Iosname);
    PL_sh_path_compat	= proto_perl->Ish_path_compat; /* XXX never deallocated */
    PL_sighandlerp	= proto_perl->Isighandlerp;


    PL_runops		= proto_perl->Irunops;

    Copy(proto_perl->Itokenbuf, PL_tokenbuf, 256, char);

#ifdef CSH
    PL_cshlen		= proto_perl->Icshlen;
    PL_cshname		= proto_perl->Icshname; /* XXX never deallocated */
#endif

    PL_lex_state	= proto_perl->Ilex_state;
    PL_lex_defer	= proto_perl->Ilex_defer;
    PL_lex_expect	= proto_perl->Ilex_expect;
    PL_lex_formbrack	= proto_perl->Ilex_formbrack;
    PL_lex_dojoin	= proto_perl->Ilex_dojoin;
    PL_lex_starts	= proto_perl->Ilex_starts;
    PL_lex_stuff	= sv_dup_inc(proto_perl->Ilex_stuff, param);
    PL_lex_repl		= sv_dup_inc(proto_perl->Ilex_repl, param);
    PL_lex_op		= proto_perl->Ilex_op;
    PL_lex_inpat	= proto_perl->Ilex_inpat;
    PL_lex_inwhat	= proto_perl->Ilex_inwhat;
    PL_lex_brackets	= proto_perl->Ilex_brackets;
    i = (PL_lex_brackets < 120 ? 120 : PL_lex_brackets);
    PL_lex_brackstack	= SAVEPVN(proto_perl->Ilex_brackstack,i);
    PL_lex_casemods	= proto_perl->Ilex_casemods;
    i = (PL_lex_casemods < 12 ? 12 : PL_lex_casemods);
    PL_lex_casestack	= SAVEPVN(proto_perl->Ilex_casestack,i);

    Copy(proto_perl->Inextval, PL_nextval, 5, YYSTYPE);
    Copy(proto_perl->Inexttype, PL_nexttype, 5,	I32);
    PL_nexttoke		= proto_perl->Inexttoke;

    PL_linestr		= sv_dup_inc(proto_perl->Ilinestr, param);
    i = proto_perl->Ibufptr - SvPVX_const(proto_perl->Ilinestr);
    PL_bufptr		= SvPVX(PL_linestr) + (i < 0 ? 0 : i);
    i = proto_perl->Ioldbufptr - SvPVX_const(proto_perl->Ilinestr);
    PL_oldbufptr	= SvPVX(PL_linestr) + (i < 0 ? 0 : i);
    i = proto_perl->Ioldoldbufptr - SvPVX_const(proto_perl->Ilinestr);
    PL_oldoldbufptr	= SvPVX(PL_linestr) + (i < 0 ? 0 : i);
    i = proto_perl->Ilinestart - SvPVX_const(proto_perl->Ilinestr);
    PL_linestart	= SvPVX(PL_linestr) + (i < 0 ? 0 : i);
    PL_bufend		= SvPVX(PL_linestr) + SvCUR(PL_linestr);
    PL_pending_ident	= proto_perl->Ipending_ident;
    PL_sublex_info	= proto_perl->Isublex_info;	/* XXX not quite right */

    PL_expect		= proto_perl->Iexpect;

    PL_multi_start	= proto_perl->Imulti_start;
    PL_multi_end	= proto_perl->Imulti_end;
    PL_multi_open	= proto_perl->Imulti_open;
    PL_multi_close	= proto_perl->Imulti_close;

    PL_error_count	= proto_perl->Ierror_count;
    PL_subline		= proto_perl->Isubline;
    PL_subname		= sv_dup_inc(proto_perl->Isubname, param);

    i = proto_perl->Ilast_uni - SvPVX_const(proto_perl->Ilinestr);
    PL_last_uni		= SvPVX(PL_linestr) + (i < 0 ? 0 : i);
    i = proto_perl->Ilast_lop - SvPVX_const(proto_perl->Ilinestr);
    PL_last_lop		= SvPVX(PL_linestr) + (i < 0 ? 0 : i);
    PL_last_lop_op	= proto_perl->Ilast_lop_op;
    PL_in_my		= proto_perl->Iin_my;
    PL_in_my_stash	= hv_dup(proto_perl->Iin_my_stash, param);
#ifdef FCRYPT
    PL_cryptseen	= proto_perl->Icryptseen;
#endif

    PL_hints		= proto_perl->Ihints;

    PL_amagic_generation	= proto_perl->Iamagic_generation;

#ifdef USE_LOCALE_COLLATE
    PL_collation_ix	= proto_perl->Icollation_ix;
    PL_collation_name	= SAVEPV(proto_perl->Icollation_name);
    PL_collation_standard	= proto_perl->Icollation_standard;
    PL_collxfrm_base	= proto_perl->Icollxfrm_base;
    PL_collxfrm_mult	= proto_perl->Icollxfrm_mult;
#endif /* USE_LOCALE_COLLATE */

#ifdef USE_LOCALE_NUMERIC
    PL_numeric_name	= SAVEPV(proto_perl->Inumeric_name);
    PL_numeric_standard	= proto_perl->Inumeric_standard;
    PL_numeric_local	= proto_perl->Inumeric_local;
    PL_numeric_radix_sv	= sv_dup_inc(proto_perl->Inumeric_radix_sv, param);
#endif /* !USE_LOCALE_NUMERIC */

    /* utf8 character classes */
    PL_utf8_alnum	= sv_dup_inc(proto_perl->Iutf8_alnum, param);
    PL_utf8_alnumc	= sv_dup_inc(proto_perl->Iutf8_alnumc, param);
    PL_utf8_ascii	= sv_dup_inc(proto_perl->Iutf8_ascii, param);
    PL_utf8_alpha	= sv_dup_inc(proto_perl->Iutf8_alpha, param);
    PL_utf8_space	= sv_dup_inc(proto_perl->Iutf8_space, param);
    PL_utf8_cntrl	= sv_dup_inc(proto_perl->Iutf8_cntrl, param);
    PL_utf8_graph	= sv_dup_inc(proto_perl->Iutf8_graph, param);
    PL_utf8_digit	= sv_dup_inc(proto_perl->Iutf8_digit, param);
    PL_utf8_upper	= sv_dup_inc(proto_perl->Iutf8_upper, param);
    PL_utf8_lower	= sv_dup_inc(proto_perl->Iutf8_lower, param);
    PL_utf8_print	= sv_dup_inc(proto_perl->Iutf8_print, param);
    PL_utf8_punct	= sv_dup_inc(proto_perl->Iutf8_punct, param);
    PL_utf8_xdigit	= sv_dup_inc(proto_perl->Iutf8_xdigit, param);
    PL_utf8_mark	= sv_dup_inc(proto_perl->Iutf8_mark, param);
    PL_utf8_toupper	= sv_dup_inc(proto_perl->Iutf8_toupper, param);
    PL_utf8_totitle	= sv_dup_inc(proto_perl->Iutf8_totitle, param);
    PL_utf8_tolower	= sv_dup_inc(proto_perl->Iutf8_tolower, param);
    PL_utf8_tofold	= sv_dup_inc(proto_perl->Iutf8_tofold, param);
    PL_utf8_idstart	= sv_dup_inc(proto_perl->Iutf8_idstart, param);
    PL_utf8_idcont	= sv_dup_inc(proto_perl->Iutf8_idcont, param);

    /* Did the locale setup indicate UTF-8? */
    PL_utf8locale	= proto_perl->Iutf8locale;
    /* Unicode features (see perlrun/-C) */
    PL_unicode		= proto_perl->Iunicode;

    /* Pre-5.8 signals control */
    PL_signals		= proto_perl->Isignals;

    /* times() ticks per second */
    PL_clocktick	= proto_perl->Iclocktick;

    /* Recursion stopper for PerlIO_find_layer */
    PL_in_load_module	= proto_perl->Iin_load_module;

    /* sort() routine */
    PL_sort_RealCmp	= proto_perl->Isort_RealCmp;

    /* Not really needed/useful since the reenrant_retint is "volatile",
     * but do it for consistency's sake. */
    PL_reentrant_retint	= proto_perl->Ireentrant_retint;

    /* Hooks to shared SVs and locks. */
    PL_sharehook	= proto_perl->Isharehook;
    PL_lockhook		= proto_perl->Ilockhook;
    PL_unlockhook	= proto_perl->Iunlockhook;
    PL_threadhook	= proto_perl->Ithreadhook;
    PL_destroyhook	= proto_perl->Idestroyhook;

    PL_runops_std	= proto_perl->Irunops_std;
    PL_runops_dbg	= proto_perl->Irunops_dbg;

#ifdef THREADS_HAVE_PIDS
    PL_ppid		= proto_perl->Ippid;
#endif

    /* swatch cache */
    PL_last_swash_hv	= NULL;	/* reinits on demand */
    PL_last_swash_klen	= 0;
    PL_last_swash_key[0]= '\0';
    PL_last_swash_tmps	= (U8*)NULL;
    PL_last_swash_slen	= 0;

    /* perly.c globals */
    PL_yydebug		= proto_perl->Iyydebug;
    PL_yynerrs		= proto_perl->Iyynerrs;
    PL_yyerrflag	= proto_perl->Iyyerrflag;
    PL_yychar		= proto_perl->Iyychar;
    PL_yyval		= proto_perl->Iyyval;
    PL_yylval		= proto_perl->Iyylval;

    PL_glob_index	= proto_perl->Iglob_index;
    PL_srand_called	= proto_perl->Isrand_called;
    PL_uudmap[(U32) 'M']	= 0;	/* reinits on demand */
    PL_bitcount		= NULL;	/* reinits on demand */

    if (proto_perl->Ipsig_pend) {
	Newxz(PL_psig_pend, SIG_SIZE, int);
    }
    else {
	PL_psig_pend	= (int*)NULL;
    }

    if (proto_perl->Ipsig_ptr) {
	Newxz(PL_psig_ptr,  SIG_SIZE, SV*);
	Newxz(PL_psig_name, SIG_SIZE, SV*);
	for (i = 1; i < SIG_SIZE; i++) {
	    PL_psig_ptr[i]  = sv_dup_inc(proto_perl->Ipsig_ptr[i], param);
	    PL_psig_name[i] = sv_dup_inc(proto_perl->Ipsig_name[i], param);
	}
    }
    else {
	PL_psig_ptr	= (SV**)NULL;
	PL_psig_name	= (SV**)NULL;
    }

    /* thrdvar.h stuff */

    if (flags & CLONEf_COPY_STACKS) {
	/* next allocation will be PL_tmps_stack[PL_tmps_ix+1] */
	PL_tmps_ix		= proto_perl->Ttmps_ix;
	PL_tmps_max		= proto_perl->Ttmps_max;
	PL_tmps_floor		= proto_perl->Ttmps_floor;
	Newxz(PL_tmps_stack, PL_tmps_max, SV*);
	i = 0;
	while (i <= PL_tmps_ix) {
	    PL_tmps_stack[i]	= sv_dup_inc(proto_perl->Ttmps_stack[i], param);
	    ++i;
	}

	/* next PUSHMARK() sets *(PL_markstack_ptr+1) */
	i = proto_perl->Tmarkstack_max - proto_perl->Tmarkstack;
	Newxz(PL_markstack, i, I32);
	PL_markstack_max	= PL_markstack + (proto_perl->Tmarkstack_max
						  - proto_perl->Tmarkstack);
	PL_markstack_ptr	= PL_markstack + (proto_perl->Tmarkstack_ptr
						  - proto_perl->Tmarkstack);
	Copy(proto_perl->Tmarkstack, PL_markstack,
	     PL_markstack_ptr - PL_markstack + 1, I32);

	/* next push_scope()/ENTER sets PL_scopestack[PL_scopestack_ix]
	 * NOTE: unlike the others! */
	PL_scopestack_ix	= proto_perl->Tscopestack_ix;
	PL_scopestack_max	= proto_perl->Tscopestack_max;
	Newxz(PL_scopestack, PL_scopestack_max, I32);
	Copy(proto_perl->Tscopestack, PL_scopestack, PL_scopestack_ix, I32);

	/* next push_return() sets PL_retstack[PL_retstack_ix]
	 * NOTE: unlike the others! */
	PL_retstack_ix		= proto_perl->Tretstack_ix;
	PL_retstack_max		= proto_perl->Tretstack_max;
	Newz(54, PL_retstack, PL_retstack_max, OP*);
	Copy(proto_perl->Tretstack, PL_retstack, PL_retstack_ix, OP*);

	/* NOTE: si_dup() looks at PL_markstack */
	PL_curstackinfo		= si_dup(proto_perl->Tcurstackinfo, param);

	/* PL_curstack		= PL_curstackinfo->si_stack; */
	PL_curstack		= av_dup(proto_perl->Tcurstack, param);
	PL_mainstack		= av_dup(proto_perl->Tmainstack, param);

	/* next PUSHs() etc. set *(PL_stack_sp+1) */
	PL_stack_base		= AvARRAY(PL_curstack);
	PL_stack_sp		= PL_stack_base + (proto_perl->Tstack_sp
						   - proto_perl->Tstack_base);
	PL_stack_max		= PL_stack_base + AvMAX(PL_curstack);

	/* next SSPUSHFOO() sets PL_savestack[PL_savestack_ix]
	 * NOTE: unlike the others! */
	PL_savestack_ix		= proto_perl->Tsavestack_ix;
	PL_savestack_max	= proto_perl->Tsavestack_max;
	/*Newxz(PL_savestack, PL_savestack_max, ANY);*/
	PL_savestack		= ss_dup(proto_perl, param);
    }
    else {
	init_stacks();
	ENTER;			/* perl_destruct() wants to LEAVE; */

	/* although we're not duplicating the tmps stack, we should still
	 * add entries for any SVs on the tmps stack that got cloned by a
	 * non-refcount means (eg a temp in @_); otherwise they will be
	 * orphaned
	 */
	for (i = 0; i<= proto_perl->Ttmps_ix; i++) {
	    SV * const nsv = (SV*)ptr_table_fetch(PL_ptr_table,
		    proto_perl->Ttmps_stack[i]);
	    if (nsv && !SvREFCNT(nsv)) {
		EXTEND_MORTAL(1);
		PL_tmps_stack[++PL_tmps_ix] = SvREFCNT_inc_simple(nsv);
	    }
	}
    }

    PL_start_env	= proto_perl->Tstart_env;	/* XXXXXX */
    PL_top_env		= &PL_start_env;

    PL_op		= proto_perl->Top;

    PL_Sv		= NULL;
    PL_Xpv		= (XPV*)NULL;
    PL_na		= proto_perl->Tna;

    PL_statbuf		= proto_perl->Tstatbuf;
    PL_statcache	= proto_perl->Tstatcache;
    PL_statgv		= gv_dup(proto_perl->Tstatgv, param);
    PL_statname		= sv_dup_inc(proto_perl->Tstatname, param);
#ifdef HAS_TIMES
    PL_timesbuf		= proto_perl->Ttimesbuf;
#endif

    PL_tainted		= proto_perl->Ttainted;
    PL_curpm		= proto_perl->Tcurpm;	/* XXX No PMOP ref count */
    PL_rs		= sv_dup_inc(proto_perl->Trs, param);
    PL_last_in_gv	= gv_dup(proto_perl->Tlast_in_gv, param);
    PL_ofs_sv		= sv_dup_inc(proto_perl->Tofs_sv, param);
    PL_defoutgv		= gv_dup_inc(proto_perl->Tdefoutgv, param);
    PL_chopset		= proto_perl->Tchopset;	/* XXX never deallocated */
    PL_toptarget	= sv_dup_inc(proto_perl->Ttoptarget, param);
    PL_bodytarget	= sv_dup_inc(proto_perl->Tbodytarget, param);
    PL_formtarget	= sv_dup(proto_perl->Tformtarget, param);

    PL_restartop	= proto_perl->Trestartop;
    PL_in_eval		= proto_perl->Tin_eval;
    PL_delaymagic	= proto_perl->Tdelaymagic;
    PL_dirty		= proto_perl->Tdirty;
    PL_localizing	= proto_perl->Tlocalizing;

#ifdef PERL_FLEXIBLE_EXCEPTIONS
    PL_protect		= proto_perl->Tprotect;
#endif
    PL_errors		= sv_dup_inc(proto_perl->Terrors, param);
    PL_hv_fetch_ent_mh	= NULL;
    PL_modcount		= proto_perl->Tmodcount;
    PL_lastgotoprobe	= NULL;
    PL_dumpindent	= proto_perl->Tdumpindent;

    PL_sortcop		= (OP*)any_dup(proto_perl->Tsortcop, proto_perl);
    PL_sortstash	= hv_dup(proto_perl->Tsortstash, param);
    PL_firstgv		= gv_dup(proto_perl->Tfirstgv, param);
    PL_secondgv		= gv_dup(proto_perl->Tsecondgv, param);
    PL_efloatbuf	= NULL;		/* reinits on demand */
    PL_efloatsize	= 0;			/* reinits on demand */

    /* regex stuff */

    PL_screamfirst	= NULL;
    PL_screamnext	= NULL;
    PL_maxscream	= -1;			/* reinits on demand */
    PL_lastscream	= NULL;

    PL_watchaddr	= NULL;
    PL_watchok		= NULL;

    PL_regdummy		= proto_perl->Tregdummy;
    PL_regcomp_parse	= Nullch;
    PL_regxend		= Nullch;
    PL_regcode		= (regnode*)NULL;
    PL_regnaughty	= 0;
    PL_regsawback	= 0;
    PL_regprecomp	= NULL;
    PL_regnpar		= 0;
    PL_regsize		= 0;
    PL_regflags		= 0;
    PL_regseen		= 0;
    PL_seen_zerolen	= 0;
    PL_seen_evals	= 0;
    PL_regcomp_rx	= (regexp*)NULL;
    PL_extralen		= 0;
    PL_colorset		= 0;		/* reinits PL_colors[] */
    /*PL_colors[6]	= {0,0,0,0,0,0};*/
    PL_reg_whilem_seen	= 0;
    PL_reginput		= NULL;
    PL_regbol		= NULL;
    PL_regeol		= NULL;
    PL_regstartp	= (I32*)NULL;
    PL_regendp		= (I32*)NULL;
    PL_reglastparen	= (U32*)NULL;
    PL_reglastcloseparen	= (U32*)NULL;
    PL_regtill		= NULL;
    PL_reg_start_tmp	= (char**)NULL;
    PL_reg_start_tmpl	= 0;
    PL_regdata		= (struct reg_data*)NULL;
    PL_bostr		= NULL;
    PL_reg_flags	= 0;
    PL_reg_eval_set	= 0;
    PL_regnarrate	= 0;
    PL_regprogram	= (regnode*)NULL;
    PL_regindent	= 0;
    PL_regcc		= (CURCUR*)NULL;
    PL_reg_call_cc	= (struct re_cc_state*)NULL;
    PL_reg_re		= (regexp*)NULL;
    PL_reg_ganch	= NULL;
    PL_reg_sv		= NULL;
    PL_reg_match_utf8	= FALSE;
    PL_reg_magic	= (MAGIC*)NULL;
    PL_reg_oldpos	= 0;
    PL_reg_oldcurpm	= (PMOP*)NULL;
    PL_reg_curpm	= (PMOP*)NULL;
    PL_reg_oldsaved	= NULL;
    PL_reg_oldsavedlen	= 0;
    PL_reg_maxiter	= 0;
    PL_reg_leftiter	= 0;
    PL_reg_poscache	= NULL;
    PL_reg_poscache_size= 0;

    /* Pluggable optimizer */
    PL_peepp		= proto_perl->Tpeepp;

    PL_stashcache       = newHV();

    if (!(flags & CLONEf_KEEP_PTR_TABLE)) {
        ptr_table_free(PL_ptr_table);
        PL_ptr_table = NULL;
    }

    /* Call the ->CLONE method, if it exists, for each of the stashes
       identified by sv_dup() above.
    */
    while(av_len(param->stashes) != -1) {
	HV* const stash = (HV*) av_shift(param->stashes);
	GV* const cloner = gv_fetchmethod_autoload(stash, "CLONE", 0);
	if (cloner && GvCV(cloner)) {
	    dSP;
	    ENTER;
	    SAVETMPS;
	    PUSHMARK(SP);
	    mXPUSHs(newSVpv(HvNAME_get(stash), 0));
	    PUTBACK;
	    call_sv((SV*)GvCV(cloner), G_DISCARD);
	    FREETMPS;
	    LEAVE;
	}
    }

    SvREFCNT_dec(param->stashes);

    /* orphaned? eg threads->new inside BEGIN or use */
    if (PL_compcv && ! SvREFCNT(PL_compcv)) {
	SvREFCNT_inc_simple_void(PL_compcv);
	SAVEFREESV(PL_compcv);
    }

    return my_perl;
}

#endif /* USE_ITHREADS */

/*
=head1 Unicode Support

=for apidoc sv_recode_to_utf8

The encoding is assumed to be an Encode object, on entry the PV
of the sv is assumed to be octets in that encoding, and the sv
will be converted into Unicode (and UTF-8).

If the sv already is UTF-8 (or if it is not POK), or if the encoding
is not a reference, nothing is done to the sv.  If the encoding is not
an C<Encode::XS> Encoding object, bad things will happen.
(See F<lib/encoding.pm> and L<Encode>).

The PV of the sv is returned.

=cut */

char *
Perl_sv_recode_to_utf8(pTHX_ SV *sv, SV *encoding)
{
    if (SvPOK(sv) && !SvUTF8(sv) && !IN_BYTES && SvROK(encoding)) {
	SV *uni;
	STRLEN len;
	const char *s;
	dSP;
	ENTER;
	SAVETMPS;
	save_re_context();
	PUSHMARK(sp);
	EXTEND(SP, 3);
	XPUSHs(encoding);
	XPUSHs(sv);
/* 
  NI-S 2002/07/09
  Passing sv_yes is wrong - it needs to be or'ed set of constants
  for Encode::XS, while UTf-8 decode (currently) assumes a true value means 
  remove converted chars from source.

  Both will default the value - let them.
  
	XPUSHs(&PL_sv_yes);
*/
	PUTBACK;
	call_method("decode", G_SCALAR);
	SPAGAIN;
	uni = POPs;
	PUTBACK;
	s = SvPV_const(uni, len);
	if (s != SvPVX_const(sv)) {
	    SvGROW(sv, len + 1);
	    Move(s, SvPVX(sv), len + 1, char);
	    SvCUR_set(sv, len);
	}
	FREETMPS;
	LEAVE;
	SvUTF8_on(sv);
	return SvPVX(sv);
    }
    return SvPOKp(sv) ? SvPVX(sv) : NULL;
}

/*
=for apidoc sv_cat_decode

The encoding is assumed to be an Encode object, the PV of the ssv is
assumed to be octets in that encoding and decoding the input starts
from the position which (PV + *offset) pointed to.  The dsv will be
concatenated the decoded UTF-8 string from ssv.  Decoding will terminate
when the string tstr appears in decoding output or the input ends on
the PV of the ssv. The value which the offset points will be modified
to the last input position on the ssv.

Returns TRUE if the terminator was found, else returns FALSE.

=cut */

bool
Perl_sv_cat_decode(pTHX_ SV *dsv, SV *encoding,
		   SV *ssv, int *offset, char *tstr, int tlen)
{
    bool ret = FALSE;
    if (SvPOK(ssv) && SvPOK(dsv) && SvROK(encoding) && offset) {
	SV *offsv;
	dSP;
	ENTER;
	SAVETMPS;
	save_re_context();
	PUSHMARK(sp);
	EXTEND(SP, 6);
	XPUSHs(encoding);
	XPUSHs(dsv);
	XPUSHs(ssv);
	offsv = newSViv(*offset);
	mXPUSHs(offsv);
	mXPUSHp(tstr, tlen);
	PUTBACK;
	call_method("cat_decode", G_SCALAR);
	SPAGAIN;
	ret = SvTRUE(TOPs);
	*offset = SvIV(offsv);
	PUTBACK;
	FREETMPS;
	LEAVE;
    }
    else
        Perl_croak(aTHX_ "Invalid argument to sv_cat_decode");
    return ret;
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
