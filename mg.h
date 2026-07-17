/*    mg.h
 *
 *    Copyright (C) 1991, 1992, 1993, 1994, 1995, 1996, 1997, 1999,
 *    2000, 2002, 2005, 2006, 2007, 2008 by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

struct mgvtbl {
    int		(*svt_get)	(pTHX_ SV *sv, MAGIC* mg);
    int		(*svt_set)	(pTHX_ SV *sv, MAGIC* mg);
    U32		(*svt_len)	(pTHX_ SV *sv, MAGIC* mg);
    int		(*svt_clear)    (pTHX_ SV *sv, MAGIC* mg);
    int		(*svt_free)	(pTHX_ SV *sv, MAGIC* mg);
    int		(*svt_copy)	(pTHX_ SV *sv, MAGIC* mg,
                                        SV *nsv, const char *name, I32 namlen);
    int		(*svt_dup)	(pTHX_ MAGIC *mg, CLONE_PARAMS *param);
    int		(*svt_local)(pTHX_ SV *nsv, MAGIC *mg);
};

struct magic {
    MAGIC*	mg_moremagic;
    MGVTBL*	mg_virtual;	/* pointer to magic functions */
    U16		mg_private;
    char	mg_type;
    U8		mg_flags;
    SSize_t	mg_len;
    SV*		mg_obj;
    char*	mg_ptr;
};

/* Flag bit for mg_flags and MgFLAGS */
#define MGf_MGv2    0x80        /* mg_virtual points at a Magic v2 structure */

/* If MGf_MGv2 is not set, this is a MAGIC v1 structure */
#define MGf_TAINTEDDIR 1        /* PERL_MAGIC_envelem only */
#define MGf_MINMATCH   1        /* PERL_MAGIC_regex_global only */
#define MGf_REQUIRE_GV 1        /* PERL_MAGIC_checkcall only */
#define MGf_REFCOUNTED 2
#define MGf_GSKIP      4	/* skip further GETs until after next SET */
#define MGf_COPY       8	/* has an svt_copy  MGVTBL entry */
#define MGf_DUP     0x10 	/* has an svt_dup   MGVTBL entry */
#define MGf_LOCAL   0x20	/* has an svt_local MGVTBL entry */
#define MGf_BYTES   0x40        /* PERL_MAGIC_regex_global only */

#define MgTAINTEDDIR(mg)	(mg->mg_flags & MGf_TAINTEDDIR)
#define MgTAINTEDDIR_on(mg)	(mg->mg_flags |= MGf_TAINTEDDIR)
#define MgTAINTEDDIR_off(mg)	(mg->mg_flags &= ~MGf_TAINTEDDIR)

/* Extracts the SV stored in mg, or NULL. */
#define MgSV(mg)		(((int)((mg)->mg_len) == HEf_SVKEY) ?   \
                                 MUTABLE_SV((mg)->mg_ptr) :	\
                                 NULL)

/* If mg contains an SV, these extract the PV stored in that SV;
   otherwise, these extract the mg's mg_ptr/mg_len.
   These do NOT account for the SV's UTF8 flag, so handle with care.
*/
#define MgPV(mg,lp)		((((int)(lp = (mg)->mg_len)) == HEf_SVKEY) ?   \
                                 SvPV(MUTABLE_SV((mg)->mg_ptr),lp) :	\
                                 (mg)->mg_ptr)
#define MgPV_const(mg,lp)	((((int)(lp = (mg)->mg_len)) == HEf_SVKEY) ? \
                                 SvPV_const(MUTABLE_SV((mg)->mg_ptr),lp) :   \
                                 (const char*)(mg)->mg_ptr)
#define MgPV_nolen_const(mg)	(((((int)(mg)->mg_len)) == HEf_SVKEY) ?	\
                                 SvPV_nolen_const(MUTABLE_SV((mg)->mg_ptr)) : \
                                 (const char*)(mg)->mg_ptr)

#define SvTIED_mg(sv,how) (SvRMAGICAL(sv) ? mg_find((sv),(how)) : NULL)
#define SvTIED_obj(sv,mg) \
    ((mg)->mg_obj ? (mg)->mg_obj : sv_2mortal(newRV(sv)))

#if defined(PERL_CORE) || defined(PERL_EXT)
# define MgBYTEPOS(mg,sv,pv,len) S_MgBYTEPOS(aTHX_ mg,sv,pv,len)
/* assumes get-magic and stringification have already occurred */
# define MgBYTEPOS_set(mg,sv,pv,off) (			 \
    assert_((mg)->mg_type == PERL_MAGIC_regex_global)	  \
    SvPOK(sv) && (!SvGMAGICAL(sv) || sv_only_taint_gmagic(sv))  \
        ? (mg)->mg_len = (off), (mg)->mg_flags |= MGf_BYTES \
        : ((mg)->mg_len = DO_UTF8(sv)			     \
            ? (SSize_t)utf8_length((U8 *)(pv), (U8 *)(pv)+(off)) \
            : (SSize_t)(off),					  \
           (mg)->mg_flags &= ~MGf_BYTES))
#endif

#define whichsig(pv) whichsig_pv(pv)

/* Magic v2
 * Was called "hooks" during development; there may still be remnants of that
 * name, or various prefixes like "HK..." or "Hk..." hanging around in code.
 */

/*
=for apidoc_section $magic

=for apidoc Am|bool|MgIsV2|MAGIC *mg
Returns true if the given magic structure is using Magic v2. This is the only
macro defined as part of Magic v2 that is safe to call on any magic structure.
All other macros must only be used on structures known to be Magic v2.

=cut
*/

#define MgIsV2(mg)  (mg->mg_flags & MGf_MGv2)

/* Flag constants used by MgFLAGS() */
#define MGv2f_REFCOUNTED_AUXSV  (1<<1)   /* must match MGf_REFCOUNTED */
#define MGv2f_WITH_MASK         (3<<3)   /* aligned with MGf_COPY|MGf_DUP */
#define   MGv2f_WITH_KEYIV      (1<<3)
#define   MGv2f_WITH_KEYHEK     (2<<3)   /* unimplemented */
#define   MGv2f_WITH_KEYSV      (3<<3)

enum MagicShape {
    MGv2s_BASE,
    MGv2s_SCALARVAR,
    MGv2s_ARRAYVAR,
    MGv2s_HASHVAR,
};

/* Flag constants stored in MagicFunctions flags field. Defined so they don't
 * overlap with the set above. */
#define MGv2f_ALWAYS_WEAK_AUXSV (1<<17)

/*
=for apidoc Am|U8|MgFLAGS|MAGIC *mg
Returns the flags bitfield from the given Magic v2 instance. This must only be
called on known Magic v2 structures; those for which L</MgIsV2> is true.

=cut
*/

#define MgFLAGS(mg)  *(assert(MgIsV2(mg)), &(mg)->mg_flags)

/*
=for apidoc Am|const struct MagicFunctions *|MgFUNCS|MAGIC *mg
Returns a pointer to the magic functions structure of the given Magic v2
instance. This must only be called on known Magic v2 structures; those for
which L</MgIsV2> is true.

=cut
*/
#define MgFUNCS(mg)  (assert(MgIsV2(mg)), \
    (const struct MagicFunctions *)((mg)->mg_virtual))

#define MGv2_ASSERT_AND_CAST_FUNCS_(mg, want_shape, type) \
    (assert(MgFUNCS(mg)->shape == want_shape),           \
      ((const type *)MgFUNCS(mg)))

/* common to all magic v2 function structs */

/* We'd love to name the free function simply `free`, but because
 * win32/win32iop.h has a line `#define free win32_free`, we can't do that
 * or all sorts of breakage happens :(
 */
#define _PERL_MAGICFUNCTIONS_COMMON_FIELDS  \
    MGVTBL _v1_vtbl; /* reserve space */   \
    U32 ver;                               \
    enum MagicShape shape;                 \
    U32 flags;                             \
    const char *debug_name;                \
    size_t user_size;                      \
    void (*free_mg) (pTHX_ SV *sv, MAGIC *mg); \
    void (*clone_mg)(pTHX_ SV *nsv, MAGIC *nmg, SV *osv, MAGIC *omg, CLONE_PARAMS *params)

struct MagicFunctions {
    _PERL_MAGICFUNCTIONS_COMMON_FIELDS;
};

struct ScalarVarMagicFunctions {
    _PERL_MAGICFUNCTIONS_COMMON_FIELDS;

    MAGIC *(*localize_mg)(pTHX_ SV *nsv, SV *osv, MAGIC *omg);
    void (*pre_get) (pTHX_ SV *sv, MAGIC *mg);
    void (*post_set)(pTHX_ SV *sv, MAGIC *mg);
};

#define MgSCALARVARFUNCS(mg)  MGv2_ASSERT_AND_CAST_FUNCS_(mg, MGv2s_SCALARVAR, struct ScalarVarMagicFunctions)

struct ArrayVarMagicFunctions {
    _PERL_MAGICFUNCTIONS_COMMON_FIELDS;

    MAGIC *(*localize_mg)(pTHX_ SV *nsv, SV *osv, MAGIC *omg);
    void (*clear)(pTHX_ SV *sv, MAGIC *mg);
};

#define MgARRAYVARFUNCS(mg)  MGv2_ASSERT_AND_CAST_FUNCS_(mg, MGv2s_ARRAYVAR, struct ArrayVarMagicFunctions)

struct HashVarMagicFunctions {
    _PERL_MAGICFUNCTIONS_COMMON_FIELDS;

    MAGIC *(*localize_mg)(pTHX_ SV *nsv, SV *osv, MAGIC *omg);
    void (*clear)(pTHX_ SV *sv, MAGIC *mg);
};

#define MgHASHVARFUNCS(mg)  MGv2_ASSERT_AND_CAST_FUNCS_(mg, MGv2s_HASHVAR, struct HashVarMagicFunctions)

typedef struct {
    MAGIC  _magic;
    IV     keyiv;
} MAGICWithKeyIV;

typedef struct {
    MAGIC  _magic;
    SV    *keysv;
} MAGICWithKeySV;

#define MGv2_SIZEOF_FLAGS_(flags)  \
    (((flags) & MGv2f_WITH_MASK) == MGv2f_WITH_KEYIV ? sizeof(MAGICWithKeyIV) : \
     ((flags) & MGv2f_WITH_MASK) == MGv2f_WITH_KEYSV ? sizeof(MAGICWithKeySV) : \
                                                       sizeof(MAGIC))
#define MgSIZEOF(mg)  MGv2_SIZEOF_FLAGS_(MgFLAGS(mg))

/*
=for apidoc Am|U16|MgPRIV|MAGIC *mg
Wraps a U16 field in the Magic v2 structure that is otherwise unused by the
magic system itself. It is provided for specific instances of Magic v2 to use
for their own purposes; typically storing a small enumeration or set of flags
bits.

This macro may be used as an lvalue.

=cut
*/
#define MgPRIV(mg)   ((mg)->mg_private)

/*
=for apidoc Am|SV *|MgAUXSV|MAGIC *mg
Returns the value of the stored auxilliary SV pointer from the Magic v2
structure. This macro should not be used as an lvalue; to set a new value see
L</MgAUXSV_set>.

=cut
*/
#define MgAUXSV(mg)  ((mg)->mg_obj)

/*
=for apidoc Am|bool|MgWEAK_AUXSV|MAGIC *mg
Returns true if the L</MgAUXSV> field should be considered as a weak pointer.
If so, it will not have its reference count decremented when the structure is
destroyed or a new value is set.

=for apidoc      Am|void|MgWEAK_AUXSV_on|MAGIC *mg
=for apidoc_item   |void|MgWEAK_AUXSV_off|MAGIC *mg
Mutator macros to turn on or off the L</MgWEAK_AUXSV> flag.

=cut
*/
// WEAK_AUXSV is really !MGv2f_REFCOUNTED_AUXSV
#define MgWEAK_AUXSV(mg)      (!(MgFLAGS(mg) & MGv2f_REFCOUNTED_AUXSV))
#define MgWEAK_AUXSV_on(mg)   (MgFLAGS(mg) &= ~MGv2f_REFCOUNTED_AUXSV)
#define MgWEAK_AUXSV_off(mg)  (MgFLAGS(mg) |=  MGv2f_REFCOUNTED_AUXSV)

/*
=for apidoc Am|void|MgAUXSV_set|MAGIC *mg|SV *auxsv
Sets a new value of the stored auxilliary SV pointer in the Magic v2
structure. This does I<not> increment the reference count of the new value.
It will decrement the count from the old value, if the L</MgWEAK_AUXSV> flag is
not set.

=cut
*/
#define MgAUXSV_set(mg, sv) \
    STMT_START { \
        MAGIC *mg_ = mg; \
        if(MgAUXSV(mg_) && !MgWEAK_AUXSV(mg_)) SvREFCNT_dec(MgAUXSV(mg_)); \
        (mg_)->mg_obj = sv; \
    } STMT_END

/*
=for apidoc      Am|void *|MgPTR|MAGIC *mg
=for apidoc_item   |STRLEN|MgPTRLEN|MAGIC *mg

The L</MgPTR> macro gives access to a pointer value stored by a Magic v2
structure, and L</MgPTRLEN> gives an associated length for it. 

If L</MgPTR> is C<NULL>, the magic code may use L</MgPTRLEN> for its own
purposes. The value will be copied on C<local> operations, thread cloning,
and similar, but will not otherwise be used.

If L</MgPTRLEN> is zero, the magic code may use L</MgPTR> for its own purposes.
The value will be copied on C<local> operations, thread cloning and similar,
but will not otherwise be used.

When used together, these macros create a storage area where the magic code
can store arbitrary bytes. If L</MgPTR> is non-C<NULL> and L</MgPTRLEN> is
non-zero when the magic is copied onto a new SV (because of C<local>
operations, thread cloning, or similar) a new buffer is allocated of the
given size, whose contents are initialised by taking a copy of the original.
A buffer allocated in this manner will be automatically released when the
magic structure is destroyed.

=for apidoc      Am|void|MgPTR_set|MAGIC *mg|void *ptr
=for apidoc_item   |void|MgPTRLEN_set|MAGIC *mg|STRLEN len

These macros set new values for the L</MgPTR> and L</MgPTRLEN> values stored
in the magic structure. If both the pointer and length values are being used
to create an allocated buffer, it is better to use the L</mg_ptr_store>
function to allocate a new buffer and update the storage.

=cut
*/
// PTR just steals magic's mg_ptr field. Though we pretend it's a void *
#define MgPTR(mg)           ((void *)(mg)->mg_ptr)
#define MgPTR_set(mg, ptr)  ((mg)->mg_ptr = (char *)(ptr))

// PTRLEN just steals magic's mg_len field.
// TODO: SSize_t vs STRLEN 
#define MgPTRLEN(mg)           ((mg)->mg_len)
#define MgPTRLEN_set(mg, len)  ((mg)->mg_len = (len))

/*
=for apidoc      Am|bool|MgHasKEYIV|MAGIC *mg
=for apidoc_item   |bool|MgHasKEYSV|MAGIC *mg

Returns true if the Magic v2 structure is declared as using either a key IV
or key SV. If this is the case, then the structure will be allocated with
enough extra storage for the field accessor macros to be used.

At most one of these macros will be true at any one time; no magic structure
is able to use both at once.

=for apidoc Am|IV|MgKEYIV|MAGIC *mg

If L</MgHasKEYIV> is true, then this macro may be used as either an rvalue or
lvalue to access the key IV in the structure. If not, then this macro must not
be called. On debugging builds, an assertion is generated if the macro is
called on a structure without the flag.

Typically this field is used to store an array index or pad offset value.

=for apidoc Am|void|MgKEYIV_set|MAGIC *mg|IV iv

If L</MgHasKEYIV> is true, then this macro may be used to set the value of the
key IV in the structure. It behaves the same as assigning directly into the
L</MgKEYIV> macro when used as an lvalue, it is just provided for
completeness.

=for apidoc Am|SV|MgKEYSV|MAGIC *mg

If L</MgHasKEYSV> is true, then this macro may be used as either an rvalue or
lvalue to access the key SV in the structure. If not, then this macro must not
be called. On debugging builds, an assertion is generated if the macro is
called on a structure without the flag.

Typically this field is used to store a hash key value. If a value is set then
it is cloned during thread cloning, and its reference count is automatically
adjusted as part of localisation and destruction operations.

=for apidoc Am|void|MgKEYSV_set|MAGIC *mg|SV *sv

If L</MgHasKEYSV> is true, then this macro may be used to set the value of
the key SV in the structure. In addition to assigning the new pointer value
into the structure, it will also call L</SvREFCNT_dec> on a previous value
if present.

=cut
*/
#define MgHasKEYIV(mg)  ((MgFLAGS(mg) & MGv2f_WITH_MASK) == MGv2f_WITH_KEYIV)
#define MgHasKEYSV(mg)  ((MgFLAGS(mg) & MGv2f_WITH_MASK) == MGv2f_WITH_KEYSV)

// These macros need to be usable as lvalues
#define MgKEYIV(mg)     (*(assert(MgHasKEYIV(mg)), &((MAGICWithKeyIV *)mg)->keyiv))
#define MgKEYSV(mg)     (*(assert(MgHasKEYSV(mg)), &((MAGICWithKeySV *)mg)->keysv))

#define MgKEYIV_set(mg, iv)                   \
    STMT_START {                              \
        assert(MgHasKEYIV(mg));               \
        ((MAGICWithKeyIV *)mg)->keyiv = (iv); \
    } STMT_END

#define MgKEYSV_set(mg, sv)                   \
    STMT_START {                              \
        assert(MgHasKEYSV(mg));               \
        if(MgKEYSV(mg))                       \
            SvREFCNT_dec(MgKEYSV(mg));        \
        ((MAGICWithKeySV *)mg)->keysv = (sv); \
    } STMT_END

/*
=for apidoc Am|type|MgUSERSTRUCT|MAGIC *mg|type

Returns a pointer to the "user structure" storage area of the given Magic v2
structure. This is extra memory allocated within the structure itself, to the
size given by the C<user_size> field in the magic functions structure. This
pointer is cast to the given type.

Typically this would be used by magic functions that have more complex data
storage requirements than can be satisfied by use of the L</MgAUXSV>, L</MgPTR>,
L</MgKEYIV> or L</MgKEYSV> fields, and wish to manage their own storage.

=cut
*/
#define MgUSERSTRUCT(mg, type)  ((type)(((char *)mg) + MgSIZEOF(mg)))

/*
 * ex: set ts=8 sts=4 sw=4 et:
 */
