#ifndef PATCHLEVEL
#include "patchlevel.h"
#endif

typedef enum {
    OPc_NULL,	/* 0 */
    OPc_BASEOP,	/* 1 */
    OPc_UNOP,	/* 2 */
    OPc_BINOP,	/* 3 */
    OPc_LOGOP,	/* 4 */
    OPc_CONDOP,	/* 5 */
    OPc_LISTOP,	/* 6 */
    OPc_PMOP,	/* 7 */
    OPc_SVOP,	/* 8 */
    OPc_GVOP,	/* 9 */
    OPc_PVOP,	/* 10 */
    OPc_CVOP,	/* 11 */
    OPc_LOOP,	/* 12 */
    OPc_COP	/* 13 */
} opclass;

opclass	cc_opclass _((OP *o));
char *	cc_opclassname _((OP *o));		
