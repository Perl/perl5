/*    pad.h
 *
 *    Copyright (c) 2002, Larry Wall
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 * This file defines the types and macros associated with the API for
 * manipulating scratchpads, which are used by perl to store lexical
 * variables, op targets and constants.
 */




/* a padlist is currently just an AV; but that might change,
 * so hide the type. Ditto a pad.  */

typedef AV PADLIST;
typedef SV** PAD;


/* offsets within a pad */

#if PTRSIZE == 4
typedef U32TYPE PADOFFSET;
#else
#   if PTRSIZE == 8
typedef U64TYPE PADOFFSET;
#   endif
#endif
#define NOT_IN_PAD ((PADOFFSET) -1)
 

/* flags for the pad_new() function */

typedef enum {
	padnew_CLONE	= 1,	/* this pad is for a cloned CV */
	padnew_SAVE	= 2,	/* save old globals */
	padnew_SAVESUB	= 4	/* also save extra stuff for start of sub */
} padnew_flags;

/* values for the pad_tidy() function */

typedef enum {
	padtidy_SUB,		/* tidy up a pad for a sub, */
	padtidy_SUBCLONE,	/* a cloned sub, */
	padtidy_FORMAT		/* or a format */
} padtidy_type;


/* Note: the following four macros are actually defined in scope.h, but
 * they are documented here for completeness, since they directly or
 * indirectly affect pads.

=for apidoc m|void|SAVEPADSV	|PADOFFSET po
Save a pad slot (used to restore after an iteration)

=for apidoc m|void|SAVECLEARSV	|SV **svp
Clear the pointed to pad value on scope exit. (ie the runtime action of 'my')

=for apidoc m|void|SAVECOMPPAD
save PL_comppad and PL_curpad

=for apidoc m|void|SAVEFREEOP	|OP *o
Free the op on scope exit. At the same time, reset PL_curpad




=for apidoc m|SV *|PAD_SETSV	|PADOFFSET po|SV* sv
Set the slot at offset C<po> in the current pad to C<sv>

=for apidoc m|void|PAD_SV	|PADOFFSET po
Get the value at offset C<po> in the current pad

=for apidoc m|SV *|PAD_SVl	|PADOFFSET po
Lightweight and lvalue version of C<PAD_SV>.
Get or set the value at offset C<po> in the current pad.
Unlike C<PAD_SV>, does not print diagnostics with -DX.
For internal use only.

=for apidoc m|SV *|PAD_BASE_SV	|PADLIST padlist|PADOFFSET po
Get the value from slot C<po> in the base (DEPTH=1) pad of a padlist

=for apidoc m|void|PAD_SET_CUR	|PADLIST padlist|I32 n
Set the current pad to be pad C<n> in the padlist, saving
the previous current pad.

=for apidoc m|void|PAD_SAVE_SETNULLPAD
Save the current pad then set it to null.

=for apidoc m|void|PAD_UPDATE_CURPAD
Set PL_curpad from the value of PL_comppad.

=cut
*/

#ifdef DEBUGGING
#  define PAD_SV(po)	   pad_sv(po)
#  define PAD_SETSV(po,sv) pad_setsv(po,sv)
#else
#  define PAD_SV(po)       (PL_curpad[po])
#  define PAD_SETSV(po,sv) PL_curpad[po] = (sv)
#endif

#define PAD_SVl(po)       (PL_curpad[po])

#define PAD_BASE_SV(padlist, po) \
	(AvARRAY(padlist)[1]) 	\
	    ? AvARRAY((AV*)(AvARRAY(padlist)[1]))[po] : Nullsv;
    

#define PAD_SET_CUR(padlist,n) \
	SAVEVPTR(PL_curpad);   \
	PL_curpad = AvARRAY((AV*)*av_fetch((padlist),(n),FALSE))

#define PAD_SAVE_SETNULLPAD	SAVEVPTR(PL_curpad); PL_curpad = 0;

#define PAD_UPDATE_CURPAD \
    PL_curpad = PL_comppad ? AvARRAY(PL_comppad) : Null(PAD)


/*
=for apidoc m|void|CX_CURPAD_SAVE|struct context
Save the current pad in the given context block structure.

=for apidoc m|PAD *|CX_CURPAD_SV|struct context|PADOFFSET po
Access the SV at offset po in the saved current pad in the given
context block structure (can be used as an lvalue).

=cut
*/

#define CX_CURPAD_SAVE(block)  (block).oldcurpad = PL_curpad
#define CX_CURPAD_SV(block,po) ((block).oldcurpad[po])


/*
=for apidoc m|U32|PAD_COMPNAME_FLAGS|PADOFFSET po
Return the flags for the current compiling pad name
at offset C<po>. Assumes a valid slot entry.

=for apidoc m|char *|PAD_COMPNAME_PV|PADOFFSET po
Return the name of the current compiling pad name
at offset C<po>. Assumes a valid slot entry.

=for apidoc m|HV *|PAD_COMPNAME_TYPE|PADOFFSET po
Return the type (stash) of the current compiling pad name at offset
C<po>. Must be a valid name. Returns null if not typed.

=for apidoc m|HV *|PAD_COMPNAME_OURSTASH|PADOFFSET po
Return the stash associated with an C<our> variable.
Assumes the slot entry is a valid C<our> lexical.

=for apidoc m|STRLEN|PAD_COMPNAME_GEN|PADOFFSET po
The generation number of the name at offset C<po> in the current
compiling pad (lvalue). Note that C<SvCUR> is hijacked for this purpose.

=cut
*/

#define PAD_COMPNAME_FLAGS(po) SvFLAGS(*av_fetch(PL_comppad_name, (po), FALSE))
#define PAD_COMPNAME_PV(po) SvPV_nolen(*av_fetch(PL_comppad_name, (po), FALSE))

/* XXX DAPM yuk - using av_fetch twice. Is there a better way? */
#define PAD_COMPNAME_TYPE(po) \
    ((SvFLAGS(*av_fetch(PL_comppad_name, (po), FALSE)) & SVpad_TYPED) \
    ? (SvSTASH(*av_fetch(PL_comppad_name, (po), FALSE))) :  Nullhv)

#define PAD_COMPNAME_OURSTASH(po) \
    (GvSTASH(*av_fetch(PL_comppad_name, (po), FALSE)))

#define PAD_COMPNAME_GEN(po) SvCUR(AvARRAY(PL_comppad_name)[po])




/*
=for apidoc m|void|PAD_DUP|PADLIST dstpad|PADLIST srcpad|CLONE_PARAMS* param
Clone a padlist.

=for apidoc m|void|PAD_CLONE_VARS|PerlInterpreter *proto_perl \
|CLONE_PARAMS* param
Clone the state variables associated with running and compiling pads.

=cut
*/


#define PAD_DUP(dstpad, srcpad, param)				\
    if ((srcpad) && !AvREAL(srcpad)) {				\
	/* XXX padlists are real, but pretend to be not */ 	\
	AvREAL_on(srcpad);					\
	(dstpad) = av_dup_inc((srcpad), param);			\
	AvREAL_off(srcpad);					\
	AvREAL_off(dstpad);					\
    }								\
    else							\
	(dstpad) = av_dup_inc((srcpad), param);			

#define PAD_CLONE_VARS(proto_perl, param)				\
    PL_comppad			= av_dup(proto_perl->Icomppad, param);	\
    PL_comppad_name		= av_dup(proto_perl->Icomppad_name, param); \
    PL_comppad_name_fill	= proto_perl->Icomppad_name_fill;	\
    PL_comppad_name_floor	= proto_perl->Icomppad_name_floor;	\
    PL_curpad			= (SV**)ptr_table_fetch(PL_ptr_table,	\
						proto_perl->Tcurpad);	\
    PL_min_intro_pending	= proto_perl->Imin_intro_pending;	\
    PL_max_intro_pending	= proto_perl->Imax_intro_pending;	\
    PL_padix			= proto_perl->Ipadix;			\
    PL_padix_floor		= proto_perl->Ipadix_floor;		\
    PL_pad_reset_pending	= proto_perl->Ipad_reset_pending;	\
    PL_cop_seqmax		= proto_perl->Icop_seqmax;
