/*    thdrvar.h
 *
 *    Copyright (C) 1999, 2000, 2001, 2002, 2003, 2004, 2005, 2006, 2007
 *    by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

/*
=head1 Global Variables
*/

/***********************************************/
/* Global only to current thread               */
/***********************************************/

/* Don't forget to re-run embed.pl to propagate changes! */

/* The 'T' prefix is only needed for vars that need appropriate #defines
 * generated when built with or without USE_5005THREADS.  It is also used
 * to generate the appropriate export list for win32.
 *
 * When building without USE_5005THREADS, these variables will be truly global.
 * When building without USE_5005THREADS but with MULTIPLICITY, these variables
 * will be global per-interpreter. */

/* Important ones in the first cache line (if alignment is done right) */

PERLVAR(Tstack_sp,	SV **)		/* top of the stack */
#ifdef OP_IN_REGISTER
PERLVAR(Topsave,	OP *)
#else
PERLVAR(Top,		OP *)		/* currently executing op */
#endif
PERLVAR(Tcurpad,	SV **)		/* active pad (lexicals+tmps) */

PERLVAR(Tstack_base,	SV **)
PERLVAR(Tstack_max,	SV **)

PERLVAR(Tscopestack,	I32 *)		/* scopes we've ENTERed */
PERLVAR(Tscopestack_ix,	I32)
PERLVAR(Tscopestack_max,I32)

PERLVAR(Tsavestack,	ANY *)		/* items that need to be restored
					   when LEAVEing scopes we've ENTERed */
PERLVAR(Tsavestack_ix,	I32)
PERLVAR(Tsavestack_max,	I32)

PERLVAR(Ttmps_stack,	SV **)		/* mortals we've made */
PERLVARI(Ttmps_ix,	I32,	-1)
PERLVARI(Ttmps_floor,	I32,	-1)
PERLVAR(Ttmps_max,	I32)
PERLVAR(Tmodcount,	I32)		/* how much mod()ification in assignment? */

PERLVAR(Tmarkstack,	I32 *)		/* stack_sp locations we're remembering */
PERLVAR(Tmarkstack_ptr,	I32 *)
PERLVAR(Tmarkstack_max,	I32 *)

PERLVAR(TSv,		SV *)		/* used to hold temporary values */
PERLVAR(TXpv,		XPV *)		/* used to hold temporary values */

/*
=for apidoc Amn|STRLEN|PL_na

A convenience variable which is typically used with C<SvPV> when one
doesn't care about the length of the string.  It is usually more efficient
to either declare a local variable and use that instead or to use the
C<SvPV_nolen> macro.

=cut
*/

PERLVAR(Tna,		STRLEN)		/* for use in SvPV when length is
					   Not Applicable */

/* stat stuff */
PERLVAR(Tstatbuf,	Stat_t)
PERLVAR(Tstatcache,	Stat_t)		/* _ */
PERLVAR(Tstatgv,	GV *)
PERLVARI(Tstatname,	SV *,	NULL)

#ifdef HAS_TIMES
PERLVAR(Ttimesbuf,	struct tms)
#endif

/* Fields used by magic variables such as $@, $/ and so on */
PERLVAR(Tcurpm,		PMOP *)		/* what to do \ interps in REs from */

/*
=for apidoc mn|SV*|PL_rs

The input record separator - C<$/> in Perl space.

=for apidoc mn|GV*|PL_last_in_gv

The GV which was last used for a filehandle input operation. (C<< <FH> >>)

=for apidoc mn|SV*|PL_ofs_sv

The output field separator - C<$,> in Perl space.

=cut
*/

PERLVAR(Trs,		SV *)		/* input record separator $/ */
PERLVAR(Tlast_in_gv,	GV *)		/* GV used in last <FH> */
PERLVAR(Tofs_sv,	SV *)		/* output field separator $, */
PERLVAR(Tdefoutgv,	GV *)		/* default FH for output */
PERLVARI(Tchopset,	const char *,	" \n-")	/* $: */
PERLVAR(Tformtarget,	SV *)
PERLVAR(Tbodytarget,	SV *)
PERLVAR(Ttoptarget,	SV *)

/* Stashes */
PERLVAR(Tdefstash,	HV *)		/* main symbol table */
PERLVAR(Tcurstash,	HV *)		/* symbol table for current package */

PERLVAR(Trestartop,	OP *)		/* propagating an error from croak? */
PERLVARI(Tcurcop,	COP * VOL,	&PL_compiling)
PERLVAR(Tcurstack,	AV *)		/* THE STACK */
PERLVAR(Tcurstackinfo,	PERL_SI *)	/* current stack + context */
PERLVAR(Tmainstack,	AV *)		/* the stack when nothing funny is happening */

PERLVAR(Ttop_env,	JMPENV *)	/* ptr. to current sigjmp() environment */
PERLVAR(Tstart_env,	JMPENV)		/* empty startup sigjmp() environment */
PERLVARI(Terrors,	SV *, NULL)	/* outstanding queued errors */

/* statics "owned" by various functions */
PERLVAR(Tav_fetch_sv,	SV *)		/* unused as of change #19268 */
PERLVAR(Thv_fetch_sv,	SV *)		/* unused as of change #19268 */
PERLVAR(Thv_fetch_ent_mh, HE*)		/* owned by hv_fetch_ent() */


PERLVAR(Tlastgotoprobe,	OP*)		/* from pp_ctl.c */

/* sort stuff */
PERLVAR(Tsortcop,	OP *)		/* user defined sort routine */
PERLVAR(Tsortstash,	HV *)		/* which is in some package or other */
PERLVAR(Tfirstgv,	GV *)		/* $a */
PERLVAR(Tsecondgv,	GV *)		/* $b */

/* float buffer */
PERLVAR(Tefloatbuf,	char*)
PERLVAR(Tefloatsize,	STRLEN)

/* regex stuff */

PERLVAR(Tscreamfirst,	I32 *)
PERLVAR(Tscreamnext,	I32 *)
PERLVAR(Tlastscream,	SV *)

PERLVAR(Treg_state,	struct re_save_state)

PERLVAR(Tregdummy,	regnode)	/* from regcomp.c */

PERLVARI(Tdumpindent,	U16, 4)		/* # of blanks per dump indentation level */
/* Space for U16 here without increasing the structure size */

PERLVARA(Tcolors,6,	char *)		/* from regcomp.c */

PERLVARI(Tpeepp,	peep_t, MEMBER_TO_FPTR(Perl_peep))
					/* Pointer to peephole optimizer */

PERLVARI(Tmaxscream,	I32,	-1)
PERLVARI(Treginterp_cnt,I32,	    0)	/* Whether "Regexp" was interpolated. */
PERLVARI(Twatchaddr,	char **,    0)
PERLVAR(Twatchok,	char *)

/* Note that the variables below are all explicitly referenced in the code
 * as thr->whatever and therefore don't need the 'T' prefix. */

/* the currently active slab in a chain of slabs of regmatch states,
 * and the currently active state within that slab */

PERLVARI(Tregmatch_slab,	regmatch_slab *, NULL)
PERLVAR(Tregmatch_state,	regmatch_state *)

PERLVARI(Tdelayedisa,	HV*, NULL)      /* stash for PL_delaymagic for magic_setisa */

/* Put anything new that is pointer aligned here. */

PERLVAR(Tdelaymagic,	U16)		/* ($<,$>) = ... */
PERLVAR(Tlocalizing,	U8)		/* are we processing a local() list? */
PERLVAR(Tcolorset,	bool)		/* from regcomp.c */
PERLVARI(Tdirty,	bool, FALSE)	/* in the middle of tearing things down? */
PERLVAR(Tin_eval,	VOL U8)	/* trap "fatal" errors? */
PERLVAR(Ttainted,	bool)		/* using variables controlled by $< */

/* Put new things UP THERE ^^^  */

/* For historical reasons this file is followed by intrpvar.h in the
   interpreter struct. As this file currently ends with 7 bytes of variables,
   intrpvar.h starts with one single U8, to avoid structure padding space
   wastage.  */
