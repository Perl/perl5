/* $RCSfile: op.c,v $$Revision: 4.1 $$Date: 92/08/07 17:19:16 $
 *
 *    Copyright (c) 1991, Larry Wall
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 * $Log:	op.c,v $
 * Revision 4.1  92/08/07  17:19:16  lwall
 * Stage 6 Snapshot
 * 
 * Revision 4.0.1.5  92/06/08  12:00:39  lwall
 * patch20: the switch optimizer didn't do anything in subroutines
 * patch20: removed implicit int declarations on funcions
 * 
 * Revision 4.0.1.4  91/11/11  16:29:33  lwall
 * patch19: do {$foo ne "bar";} returned wrong value
 * patch19: some earlier patches weren't propagated to alternate 286 code
 * 
 * Revision 4.0.1.3  91/11/05  16:07:43  lwall
 * patch11: random cleanup
 * patch11: "foo\0" eq "foo" was sometimes optimized to true
 * patch11: foreach on null list could spring memory leak
 * 
 * Revision 4.0.1.2  91/06/07  10:26:45  lwall
 * patch4: new copyright notice
 * patch4: made some allowances for "semi-standard" C
 * 
 * Revision 4.0.1.1  91/04/11  17:36:16  lwall
 * patch1: you may now use "die" and "caller" in a signal handler
 * 
 * Revision 4.0  91/03/20  01:04:18  lwall
 * 4.0 baseline.
 * 
 */

#include "EXTERN.h"
#include "perl.h"

#ifdef I_VARARGS
#  include <varargs.h>
#endif

void deb_growlevel();

#  ifndef I_VARARGS
/*VARARGS1*/
void deb(pat,a1,a2,a3,a4,a5,a6,a7,a8)
char *pat;
{
    register I32 i;

    fprintf(stderr,"%-4ld",(long)curop->cop_line);
    for (i=0; i<dlevel; i++)
	fprintf(stderr,"%c%c ",debname[i],debdelim[i]);
    fprintf(stderr,pat,a1,a2,a3,a4,a5,a6,a7,a8);
}
#  else
/*VARARGS1*/
#ifdef __STDC__
void deb(char *pat,...)
#else
void deb(va_alist)
va_dcl
#endif
{
    va_list args;
    char *pat;
    register I32 i;

    va_start(args);
    fprintf(stderr,"%-4ld",(long)curcop->cop_line);
    for (i=0; i<dlevel; i++)
	fprintf(stderr,"%c%c ",debname[i],debdelim[i]);

    pat = va_arg(args, char *);
    (void) vfprintf(stderr,pat,args);
    va_end( args );
}
#  endif

void
deb_growlevel()
{
    dlmax += 128;
    Renew(debname, dlmax, char);
    Renew(debdelim, dlmax, char);
}

I32
debstackptrs()
{
    fprintf(stderr, "%8lx %8lx %8ld %8ld %8ld\n",
	stack, stack_base, *markstack_ptr, stack_sp-stack_base, stack_max-stack_base);
    fprintf(stderr, "%8lx %8lx %8ld %l8d %8ld\n",
	mainstack, AvARRAY(stack), mainstack, AvFILL(stack), AvMAX(stack));
    return 0;
}

I32
debstack()
{
    register I32 i;
    I32 markoff = markstack_ptr > markstack ? *markstack_ptr : -1;

    fprintf(stderr, "     =>");
    if (stack_base[0] || stack_sp < stack_base)
	fprintf(stderr, " [STACK UNDERFLOW!!!]\n");
    for (i = 1; i <= 30; i++) {
	if (stack_sp >= &stack_base[i])
	{
	    fprintf(stderr, "\t%-4s%s%s", SvPEEK(stack_base[i]),
		markoff == i ? " [" : "",
		stack_sp == &stack_base[i] ?
			(markoff == i ? "]" : " ]") : "");
	}
    }
    fprintf(stderr, "\n");
    return 0;
}
