/* $RCSfile: arg.h,v $$Revision: 4.1 $$Date: 92/08/07 17:18:16 $
 *
 *    Copyright (c) 1993, Larry Wall
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 * $Log:	arg.h,v $
 */

struct mgvtbl {
    int		(*svt_get)	P((SV *sv, MAGIC* mg));
    int		(*svt_set)	P((SV *sv, MAGIC* mg));
    U32		(*svt_len)	P((SV *sv, MAGIC* mg));
    int		(*svt_clear)	P((SV *sv, MAGIC* mg));
    int		(*svt_free)	P((SV *sv, MAGIC* mg));
};

struct magic {
    MAGIC*	mg_moremagic;
    MGVTBL*	mg_virtual;	/* pointer to magic functions */
    U16		mg_private;
    char	mg_type;
    U8		mg_flags;
    SV*		mg_obj;
    char*	mg_ptr;
    I32		mg_len;
};

#define MGf_TAINTEDDIR 1
#define MGf_REFCOUNTED 2
#define MgTAINTEDDIR(mg) (mg->mg_flags & MGf_TAINTEDDIR)
#define MgTAINTEDDIR_on(mg) (mg->mg_flags |= MGf_TAINTEDDIR)
