/*	ccop.c
 *
 *	Copyright (c) 1996 Malcolm Beattie
 *
 *	You may distribute under the terms of either the GNU General Public
 *	License or the Artistic License, as specified in the README file.
 *
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ccop.h"

static char *opclassnames[] = {
    "B::NULL",
    "B::OP",
    "B::UNOP",
    "B::BINOP",
    "B::LOGOP",
    "B::CONDOP",
    "B::LISTOP",
    "B::PMOP",
    "B::SVOP",
    "B::GVOP",
    "B::PVOP",
    "B::CVOP",
    "B::LOOP",
    "B::COP"	
};

static opclass
cc_baseop(o)
OP *o;
{
    return OPc_BASEOP;
}

static opclass
cc_unop(o)
OP *o;
{
    return OPc_UNOP;
}

static opclass
cc_binop(o)
OP *o;
{
    return OPc_BINOP;
}

static opclass
cc_logop(o)
OP *o;
{
    return OPc_LOGOP;
}

static opclass
cc_condop(o)
OP *o;
{
    return OPc_CONDOP;
}

static opclass
cc_listop(o)
OP *o;
{
    return OPc_LISTOP;
}

static opclass
cc_pmop(o)
OP *o;
{
    return OPc_PMOP;
}

static opclass
cc_svop(o)
OP *o;
{
    return OPc_SVOP;
}

static opclass
cc_gvop(o)
OP *o;
{
    return OPc_GVOP;
}

static opclass
cc_pvop(o)
OP *o;
{
    return OPc_PVOP;
}

static opclass
cc_cvop(o)
OP *o;
{
    return OPc_CVOP;
}

static opclass
cc_loop(o)
OP *o;
{
    return OPc_LOOP;
}

static opclass
cc_cop(o)
OP *o;
{
    return OPc_COP;
}

/* Nullified ops with children still need to be able to find o->op_first */
static opclass
cc_nullop(o)
OP *o;
{
    return ((o->op_flags & OPf_KIDS) ? OPc_UNOP : OPc_BASEOP);
}

static opclass
cc_stub(o)
OP *o;
{
    warn("compiler stub for %s, assuming BASEOP\n", ppnames[o->op_type]);
    return OPc_BASEOP;		/* XXX lie */
}

/*
 * UNI(OP_foo) in toke.c returns token UNI or FUNC1 depending on whether
 * bare parens were seen. perly.y uses OPf_SPECIAL to signal whether an
 * OP or an UNOP was chosen.
 * Frederic.Chauveau@pasteur.fr says we need to check for OPf_KIDS too.
 */
static opclass
cc_baseop_or_unop(o)
OP *o;
{
    return ((o->op_flags & OPf_SPECIAL) ? OPc_BASEOP :
	    (o->op_flags & OPf_KIDS) ? OPc_UNOP : OPc_BASEOP);
}

/*
 * The file stat OPs are created via UNI(OP_foo) in toke.c but use
 * the OPf_REF flag to distinguish between OP types instead of the
 * usual OPf_SPECIAL flag. As usual, if OPf_KIDS is set, then we
 * return OPc_UNOP so that walkoptree can find our children. If
 * OPf_KIDS is not set then we check OPf_REF. Without OPf_REF set
 * (no argument to the operator) it's an OP; with OPf_REF set it's
 * a GVOP (and op_gv is the GV for the filehandle argument).
 */
static opclass
cc_filestatop(o)
OP *o;
{
    return ((o->op_flags & OPf_KIDS) ? OPc_UNOP :
	    (o->op_flags & OPf_REF) ? OPc_GVOP : OPc_BASEOP);
}

/*
 * next, last, redo, dump and goto use OPf_SPECIAL to indicate that a
 * label was omitted (in which case it's a BASEOP) or else a term was
 * seen. In this last case, all except goto are definitely PVOP but goto
 * is either a PVOP (with an ordinary constant label), an UNOP with
 * OPf_STACKED (with a non-constant non-sub) or an UNOP for OP_REFGEN
 * (with goto &sub) in which case OPf_STACKED also seems to get set.
 */

static opclass
cc_loopexop(o)
OP *o;
{
    if (o->op_flags & OPf_STACKED)
	return OPc_UNOP;
    else if (o->op_flags & OPf_SPECIAL)
	return OPc_BASEOP;
    else
	return OPc_PVOP;
}

static opclass
cc_sassign(o)
OP *o;
{
    return ((o->op_private & OPpASSIGN_BACKWARDS) ? OPc_UNOP : OPc_BINOP);
}

static opclass (*ccopaddr[])_((OP *o)) = {
	cc_nullop,		/* null */
	cc_baseop,		/* stub */
	cc_baseop_or_unop,	/* scalar */
	cc_baseop,		/* pushmark */
	cc_baseop,		/* wantarray */
	cc_svop,		/* const */
	cc_gvop,		/* gvsv */
	cc_gvop,		/* gv */
	cc_binop,		/* gelem */
	cc_baseop,		/* padsv */
	cc_baseop,		/* padav */
	cc_baseop,		/* padhv */
	cc_baseop,		/* padany */
	cc_pmop,		/* pushre */
	cc_unop,		/* rv2gv */
	cc_unop,		/* rv2sv */
	cc_unop,		/* av2arylen */
	cc_unop,		/* rv2cv */
	cc_svop,		/* anoncode */
	cc_baseop_or_unop,	/* prototype */
	cc_unop,		/* refgen */
	cc_unop,		/* srefgen */
	cc_baseop_or_unop,	/* ref */
	cc_listop,		/* bless */
	cc_baseop_or_unop,	/* backtick */
	cc_listop,		/* glob */
	cc_baseop_or_unop,	/* readline */
	cc_stub,		/* rcatline */
	cc_unop,		/* regcmaybe */
	cc_logop,		/* regcomp */
	cc_pmop,		/* match */
	cc_pmop,		/* subst */
	cc_logop,		/* substcont */
	cc_pvop,		/* trans */
	cc_sassign,		/* sassign */
	cc_binop,		/* aassign */
	cc_baseop_or_unop,	/* chop */
	cc_baseop_or_unop,	/* schop */
	cc_baseop_or_unop,	/* chomp */
	cc_baseop_or_unop,	/* schomp */
	cc_baseop_or_unop,	/* defined */
	cc_baseop_or_unop,	/* undef */
	cc_baseop_or_unop,	/* study */
	cc_baseop_or_unop,	/* pos */
	cc_unop,		/* preinc */
	cc_unop,		/* i_preinc */
	cc_unop, 		/* predec */
	cc_unop,		/* i_predec */
	cc_unop,		/* postinc */
	cc_unop,		/* i_postinc */
	cc_unop,		/* postdec */
	cc_unop,		/* i_postdec */
	cc_binop,		/* pow */
	cc_binop,		/* multiply */
	cc_binop,		/* i_multiply */
	cc_binop,		/* divide */
	cc_binop,		/* i_divide */
	cc_binop,		/* modulo */
	cc_binop,		/* i_modulo */
	cc_binop,		/* repeat */
	cc_binop,		/* add */
	cc_binop,		/* i_add */
	cc_binop,		/* subtract */
	cc_binop,		/* i_subtract */
	cc_binop,		/* concat */
	cc_listop,		/* stringify */
	cc_binop,		/* left_shift */
	cc_binop,		/* right_shift */
	cc_binop,		/* lt */
	cc_binop,		/* i_lt */
	cc_binop,		/* gt */
	cc_binop,		/* i_gt */
	cc_binop,		/* le */
	cc_binop,		/* i_le */
	cc_binop,		/* ge */
	cc_binop,		/* i_ge */
	cc_binop,		/* eq */
	cc_binop,		/* i_eq */
	cc_binop,		/* ne */
	cc_binop,		/* i_ne */
	cc_binop,		/* ncmp */
	cc_binop,		/* i_ncmp */
	cc_binop,		/* slt */
	cc_binop,		/* sgt */
	cc_binop,		/* sle */
	cc_binop,		/* sge */
	cc_binop,		/* seq */
	cc_binop,		/* sne */
	cc_binop,		/* scmp */
	cc_binop,		/* bit_and */
	cc_binop,		/* bit_xor */
	cc_binop,		/* bit_or */
	cc_unop,    		/* negate */
	cc_unop,		/* i_negate */
	cc_unop,		/* not */
	cc_unop,		/* complement */
	cc_listop,		/* atan2 */
	cc_baseop_or_unop,	/* sin */
	cc_baseop_or_unop,	/* cos */
	cc_baseop_or_unop,	/* rand */
	cc_baseop_or_unop,	/* srand */
	cc_baseop_or_unop,	/* exp */
	cc_baseop_or_unop,	/* log */
	cc_baseop_or_unop,	/* sqrt */
	cc_baseop_or_unop,	/* int */
	cc_baseop_or_unop,	/* hex */
	cc_baseop_or_unop,	/* oct */
	cc_baseop_or_unop,	/* abs */
	cc_baseop_or_unop,	/* length */
	cc_listop,		/* substr */
	cc_listop,		/* vec */
	cc_listop,		/* index */
	cc_listop,		/* rindex */
	cc_listop,		/* sprintf */
	cc_listop,		/* formline */
	cc_baseop_or_unop,	/* ord */
	cc_baseop_or_unop,	/* chr */
	cc_listop,		/* crypt */
	cc_baseop_or_unop,	/* ucfirst */
	cc_baseop_or_unop,	/* lcfirst */
	cc_baseop_or_unop,	/* uc */
	cc_baseop_or_unop,	/* lc */
	cc_baseop_or_unop,	/* quotemeta */
	cc_unop,		/* rv2av */
	cc_gvop,		/* aelemfast */
	cc_binop,         	/* aelem */
	cc_listop,		/* aslice */
	cc_baseop_or_unop,	/* each */
	cc_baseop_or_unop,	/* values */
	cc_baseop_or_unop,	/* keys */
	cc_baseop_or_unop,	/* delete */
	cc_baseop_or_unop,	/* exists */
	cc_unop,		/* rv2hv */
	cc_binop,		/* helem */
	cc_listop,		/* hslice */
	cc_listop,		/* unpack */
	cc_listop,		/* pack */
	cc_listop,		/* split */
	cc_listop,		/* join */
	cc_listop,		/* list */
	cc_binop,		/* lslice */
	cc_listop,		/* anonlist */
	cc_listop,		/* anonhash */
	cc_listop,		/* splice */
	cc_listop,		/* push */
	cc_baseop_or_unop,	/* pop */
	cc_baseop_or_unop,	/* shift */
	cc_listop,		/* unshift */
	cc_listop,		/* sort */
	cc_listop,		/* reverse */
	cc_listop,		/* grepstart */
	cc_logop,		/* grepwhile */
	cc_listop,		/* mapstart */
	cc_logop,		/* mapwhile */
	cc_condop,		/* range */
	cc_unop,		/* flip */
	cc_unop,		/* flop */
	cc_logop,		/* and */
	cc_logop,		/* or */
	cc_logop,		/* xor */
	cc_condop,		/* cond_expr */
	cc_logop,		/* andassign */
	cc_logop,		/* orassign */
	cc_unop,		/* method */
	cc_unop,		/* entersub */
	cc_unop,		/* leavesub */
	cc_baseop_or_unop,	/* caller */
	cc_listop,		/* warn */
	cc_listop,		/* die */
	cc_baseop_or_unop,	/* reset */
	cc_listop,		/* lineseq */
	cc_cop,			/* nextstate */
	cc_cop,			/* dbstate */
	cc_baseop,		/* unstack */
	cc_baseop,		/* enter */
	cc_listop,		/* leave */
	cc_listop,		/* scope */
	cc_loop,		/* enteriter */
	cc_baseop,		/* iter */
	cc_loop,		/* enterloop */
	cc_binop,		/* leaveloop */
	cc_listop,		/* return */
	cc_loopexop,		/* last */
	cc_loopexop,		/* next */
	cc_loopexop,		/* redo */
	cc_loopexop,		/* dump */
	cc_loopexop,		/* goto */
	cc_baseop_or_unop,	/* exit */
	cc_listop,		/* open */
	cc_baseop_or_unop,	/* close */
	cc_listop,		/* pipe_op */
	cc_baseop_or_unop,	/* fileno */
	cc_baseop_or_unop,	/* umask */
	cc_baseop_or_unop,	/* binmode */
	cc_listop,		/* tie */
	cc_baseop_or_unop,	/* untie */
	cc_baseop_or_unop,	/* tied */
	cc_listop,		/* dbmopen */
	cc_baseop_or_unop,	/* dbmclose */
	cc_listop,		/* sselect */
	cc_listop,		/* select */
	cc_baseop_or_unop,	/* getc */
	cc_listop,		/* read */
	cc_baseop_or_unop,	/* enterwrite */
	cc_unop,		/* leavewrite */
	cc_listop,		/* prtf */
	cc_listop,		/* print */
	cc_listop,		/* sysopen */
#if PATCHLEVEL > 3
	cc_listop,		/* sysseek */
#endif
	cc_listop,		/* sysread */
	cc_listop,		/* syswrite */
	cc_listop,		/* send */
	cc_listop,		/* recv */
	cc_baseop_or_unop,	/* eof */
	cc_baseop_or_unop,	/* tell */
	cc_listop,		/* seek */
	cc_listop,		/* truncate */
	cc_listop,		/* fcntl */
	cc_listop,		/* ioctl */
	cc_listop,		/* flock */
	cc_listop,		/* socket */
	cc_listop,		/* sockpair */
	cc_listop,		/* bind */
	cc_listop,		/* connect */
	cc_listop,		/* listen */
	cc_listop,		/* accept */
	cc_listop,		/* shutdown */
	cc_listop,		/* gsockopt */
	cc_listop,		/* ssockopt */
	cc_baseop_or_unop,	/* getsockname */
	cc_baseop_or_unop,	/* getpeername */
	cc_filestatop,		/* lstat */
	cc_filestatop,		/* stat */
	cc_filestatop,		/* ftrread */
	cc_filestatop,		/* ftrwrite */
	cc_filestatop,		/* ftrexec */
	cc_filestatop,		/* fteread */
	cc_filestatop,		/* ftewrite */
	cc_filestatop,		/* fteexec */
	cc_filestatop,		/* ftis */
	cc_filestatop,		/* fteowned */
	cc_filestatop,		/* ftrowned */
	cc_filestatop,		/* ftzero */
	cc_filestatop,		/* ftsize */
	cc_filestatop,		/* ftmtime */
	cc_filestatop,		/* ftatime */
	cc_filestatop,		/* ftctime */
	cc_filestatop,		/* ftsock */
	cc_filestatop,		/* ftchr */
	cc_filestatop,		/* ftblk */
	cc_filestatop,		/* ftfile */
	cc_filestatop,		/* ftdir */
	cc_filestatop,		/* ftpipe */
	cc_filestatop,		/* ftlink */
	cc_filestatop,		/* ftsuid */
	cc_filestatop,		/* ftsgid */
	cc_filestatop,		/* ftsvtx */
	cc_filestatop,		/* fttty */
	cc_filestatop,		/* fttext */
	cc_filestatop,		/* ftbinary */
	cc_baseop_or_unop,	/* chdir */
	cc_listop,		/* chown */
	cc_baseop_or_unop,	/* chroot */
	cc_listop,		/* unlink */
	cc_listop,		/* chmod */
	cc_listop,		/* utime */
	cc_listop,		/* rename */
	cc_listop,		/* link */
	cc_listop,		/* symlink */
	cc_baseop_or_unop,	/* readlink */
	cc_listop,		/* mkdir */
	cc_baseop_or_unop,	/* rmdir */
	cc_listop,		/* open_dir */
	cc_baseop_or_unop,	/* readdir */
	cc_baseop_or_unop,	/* telldir */
	cc_listop,		/* seekdir */
	cc_baseop_or_unop,	/* rewinddir */
	cc_baseop_or_unop,	/* closedir */
	cc_baseop,		/* fork */
	cc_baseop,		/* wait */
	cc_listop,		/* waitpid */
	cc_listop,		/* system */
	cc_listop,		/* exec */
	cc_listop,		/* kill */
	cc_baseop,		/* getppid */
	cc_baseop_or_unop,	/* getpgrp */
	cc_listop,		/* setpgrp */
	cc_listop,		/* getpriority */
	cc_listop,		/* setpriority */
	cc_baseop,		/* time */
	cc_baseop,		/* tms */
	cc_baseop_or_unop,	/* localtime */
	cc_baseop_or_unop,	/* gmtime */
	cc_baseop_or_unop,	/* alarm */
	cc_baseop_or_unop,	/* sleep */
	cc_listop,		/* shmget */
	cc_listop,		/* shmctl */
	cc_listop,		/* shmread */
	cc_listop,		/* shmwrite */
	cc_listop,		/* msgget */
	cc_listop,		/* msgctl */
	cc_listop,		/* msgsnd */
	cc_listop,		/* msgrcv */
	cc_listop,		/* semget */
	cc_listop,		/* semctl */
	cc_listop,		/* semop */
	cc_baseop_or_unop,	/* require */
	cc_unop,		/* dofile */
	cc_baseop_or_unop,	/* entereval */
	cc_unop,		/* leaveeval */
	cc_logop,		/* entertry */
	cc_listop,		/* leavetry */
	cc_baseop_or_unop,	/* ghbyname */
	cc_listop,		/* ghbyaddr */
	cc_baseop,		/* ghostent */
	cc_baseop_or_unop,	/* gnbyname */
	cc_listop,		/* gnbyaddr */
	cc_baseop,		/* gnetent */
	cc_baseop_or_unop,	/* gpbyname */
	cc_listop,		/* gpbynumber */
	cc_baseop,		/* gprotoent */
	cc_listop,		/* gsbyname */
	cc_listop,		/* gsbyport */
	cc_baseop,		/* gservent */
	cc_baseop_or_unop,	/* shostent */
	cc_baseop_or_unop,	/* snetent */
	cc_baseop_or_unop,	/* sprotoent */
	cc_baseop_or_unop,	/* sservent */
	cc_baseop,		/* ehostent */
	cc_baseop,		/* enetent */
	cc_baseop,		/* eprotoent */
	cc_baseop,		/* eservent */
	cc_baseop_or_unop,	/* gpwnam */
	cc_baseop_or_unop,	/* gpwuid */
	cc_baseop,		/* gpwent */
	cc_baseop,		/* spwent */
	cc_baseop,		/* epwent */
	cc_baseop_or_unop,	/* ggrnam */
	cc_baseop_or_unop,	/* ggrgid */
	cc_baseop,		/* ggrent */
	cc_baseop,		/* sgrent */
	cc_baseop,		/* egrent */
	cc_baseop,		/* getlogin */
	cc_listop,		/* syscall */
#if PATCHLEVEL > 4 || (PATCHLEVEL == 4 && SUBVERSION > 50)
	cc_baseop_or_unop,	/* lock */
#endif
};

opclass
cc_opclass(o)
OP *	o;
{
    return o ? (*ccopaddr[o->op_type])(o) : OPc_NULL;
}

char *
cc_opclassname(o)
OP *	o;
{
    return opclassnames[o ? (*ccopaddr[o->op_type])(o) : OPc_NULL];
}

