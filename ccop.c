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

opclass
cc_opclass(o)
OP *	o;
{
    if (!o)
	return OPc_NULL;

    if (o->op_type == 0)
	return (o->op_flags & OPf_KIDS) ? OPc_UNOP : OPc_BASEOP;

    if (o->op_type == OP_SASSIGN)
	return ((o->op_private & OPpASSIGN_BACKWARDS) ? OPc_UNOP : OPc_BINOP);

    switch (opargs[o->op_type] & OA_CLASS_MASK) {
    case OA_BASEOP:
	return OPc_BASEOP;

    case OA_UNOP:
	return OPc_UNOP;

    case OA_BINOP:
	return OPc_BINOP;

    case OA_LOGOP:
	return OPc_LOGOP;

    case OA_CONDOP:
	return OPc_CONDOP;

    case OA_LISTOP:
	return OPc_LISTOP;

    case OA_PMOP:
	return OPc_PMOP;

    case OA_SVOP:
	return OPc_SVOP;

    case OA_GVOP:
	return OPc_GVOP;

    case OA_PVOP:
	return OPc_PVOP;

    case OA_LOOP:
	return OPc_LOOP;

    case OA_COP:
	return OPc_COP;

    case OA_BASEOP_OR_UNOP:
	/*
	 * UNI(OP_foo) in toke.c returns token UNI or FUNC1 depending on
	 * whether bare parens were seen. perly.y uses OPf_SPECIAL to
	 * signal whether an OP or an UNOP was chosen.
	 * Frederic.Chauveau@pasteur.fr says we need to check for OPf_KIDS too.
	 */
	return ((o->op_flags & OPf_SPECIAL) ? OPc_BASEOP :
		(o->op_flags & OPf_KIDS) ? OPc_UNOP : OPc_BASEOP);

    case OA_FILESTATOP:
	/*
	 * The file stat OPs are created via UNI(OP_foo) in toke.c but use
	 * the OPf_REF flag to distinguish between OP types instead of the
	 * usual OPf_SPECIAL flag. As usual, if OPf_KIDS is set, then we
	 * return OPc_UNOP so that walkoptree can find our children. If
	 * OPf_KIDS is not set then we check OPf_REF. Without OPf_REF set
	 * (no argument to the operator) it's an OP; with OPf_REF set it's
	 * a GVOP (and op_gv is the GV for the filehandle argument).
	 */
	return ((o->op_flags & OPf_KIDS) ? OPc_UNOP :
		(o->op_flags & OPf_REF) ? OPc_GVOP : OPc_BASEOP);

    case OA_LOOPEXOP:
	/*
	 * next, last, redo, dump and goto use OPf_SPECIAL to indicate that a
	 * label was omitted (in which case it's a BASEOP) or else a term was
	 * seen. In this last case, all except goto are definitely PVOP but
	 * goto is either a PVOP (with an ordinary constant label), an UNOP
	 * with OPf_STACKED (with a non-constant non-sub) or an UNOP for
	 * OP_REFGEN (with goto &sub) in which case OPf_STACKED also seems to
	 * get set.
	 */
	if (o->op_flags & OPf_STACKED)
	    return OPc_UNOP;
	else if (o->op_flags & OPf_SPECIAL)
	    return OPc_BASEOP;
	else
	    return OPc_PVOP;
    }
    warn("can't determine class of operator %s, assuming BASEOP\n",
	 ppnames[o->op_type]);
    return OPc_BASEOP;
}

char *
cc_opclassname(o)
OP *	o;
{
    return opclassnames[cc_opclass(o)];
}

