/* $RCSfile: dolist.c,v $$Revision: 4.1 $$Date: 92/08/07 17:19:51 $
 *
 *    Copyright (c) 1991, Larry Wall
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 * $Log:	dolist.c,v $
 * Revision 4.1  92/08/07  17:19:51  lwall
 * Stage 6 Snapshot
 * 
 * Revision 4.0.1.5  92/06/08  13:13:27  lwall
 * patch20: g pattern modifer sometimes returned extra values
 * patch20: m/$pattern/g didn't work
 * patch20: pattern modifiers i and o didn't interact right
 * patch20: @ in unpack failed too often
 * patch20: Perl now distinguishes overlapped copies from non-overlapped
 * patch20: slice on null list in scalar context returned random value
 * patch20: splice with negative offset didn't work with $[ = 1
 * patch20: fixed some memory leaks in splice
 * patch20: scalar keys %array now counts keys for you
 * 
 * Revision 4.0.1.4  91/11/11  16:33:19  lwall
 * patch19: added little-endian pack/unpack options
 * patch19: sort $subname was busted by changes in 4.018
 * 
 * Revision 4.0.1.3  91/11/05  17:07:02  lwall
 * patch11: prepared for ctype implementations that don't define isascii()
 * patch11: /$foo/o optimizer could access deallocated data
 * patch11: certain optimizations of //g in array context returned too many values
 * patch11: regexp with no parens in array context returned wacky $`, $& and $'
 * patch11: $' not set right on some //g
 * patch11: added some support for 64-bit integers
 * patch11: grep of a split lost its values
 * patch11: added sort {} LIST
 * patch11: multiple reallocations now avoided in 1 .. 100000
 * 
 * Revision 4.0.1.2  91/06/10  01:22:15  lwall
 * patch10: //g only worked first time through
 * 
 * Revision 4.0.1.1  91/06/07  10:58:28  lwall
 * patch4: new copyright notice
 * patch4: added global modifier for pattern matches
 * patch4: // wouldn't use previous pattern if it started with a null character
 * patch4: //o and s///o now optimize themselves fully at runtime
 * patch4: $` was busted inside s///
 * patch4: caller($arg) didn't work except under debugger
 * 
 * Revision 4.0  91/03/20  01:08:03  lwall
 * 4.0 baseline.
 * 
 */

#include "EXTERN.h"
#include "perl.h"

#ifdef BUGGY_MSC
 #pragma function(memcmp)
#endif /* BUGGY_MSC */

#ifdef BUGGY_MSC
 #pragma intrinsic(memcmp)
#endif /* BUGGY_MSC */

OP *
do_kv(ARGS)
dARGS
{
    dSP;
    HV *hash = (HV*)POPs;
    register AV *ary = stack;
    I32 i;
    register HE *entry;
    char *tmps;
    SV *tmpstr;
    I32 dokeys =   (op->op_type == OP_KEYS   || op->op_type == OP_RV2HV);
    I32 dovalues = (op->op_type == OP_VALUES || op->op_type == OP_RV2HV);

    if (!hash)
	RETURN;
    if (GIMME != G_ARRAY) {
	dTARGET;

	i = 0;
	(void)hv_iterinit(hash);
	/*SUPPRESS 560*/
	while (entry = hv_iternext(hash)) {
	    i++;
	}
	PUSHn( (double)i );
	RETURN;
    }
    /* Guess how much room we need.  hv_max may be a few too many.  Oh well. */
    EXTEND(sp, HvMAX(hash) * (dokeys + dovalues));
    (void)hv_iterinit(hash);
    /*SUPPRESS 560*/
    while (entry = hv_iternext(hash)) {
	if (dokeys) {
	    tmps = hv_iterkey(entry,&i);
	    if (!i)
		tmps = "";
	    XPUSHs(sv_2mortal(newSVpv(tmps,i)));
	}
	if (dovalues) {
	    tmpstr = NEWSV(45,0);
	    sv_setsv(tmpstr,hv_iterval(hash,entry));
	    DEBUG_H( {
		sprintf(buf,"%d%%%d=%d\n",entry->hent_hash,
		    HvMAX(hash)+1,entry->hent_hash & HvMAX(hash));
		sv_setpv(tmpstr,buf);
	    } )
	    XPUSHs(sv_2mortal(tmpstr));
	}
    }
    RETURN;
}

