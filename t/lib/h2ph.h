/* 
 * Test header file for h2ph
 * 
 * Try to test as many constructs as possible
 * For example, the multi-line comment :)
 */

/* And here's a single line comment :) */

/* Test #define with no indenting, over multiple lines */
#define SQUARE(x) \
((x)*(x))

/* Test #ifndef and parameter interpretation*/
#ifndef ERROR
#define ERROR(x) fprintf(stderr, "%s\n", x[2][3][0])
#endif /* ERROR */

#ifndef _H2PH_H_
#define _H2PH_H_

/* #ident - doesn't really do anything, but I think it always gets included anyway */
#ident "$Revision h2ph.h,v 1.0 98/05/04 20:42:14 billy $"

/* Test #undef */
#undef MAX
#define MAX(a,b) ((a) > (b) ? (a) : (b))

/* Test #undef'ining an existing constant function */
#define NOTTRUE 0
#undef NOTTRUE

/* Test #ifdef */
#ifdef __SOME_UNIMPORTANT_PROPERTY
#define MIN(a,b) ((a) < (b) ? (a) : (b))
#endif /* __SOME_UNIMPORTANT_PROPERTY */

/* 
 * Test #if, #elif, #else, #endif, #warn and #error, and '!'
 * Also test whitespace between the '#' and the command
 */
#if !(defined __SOMETHING_MORE_IMPORTANT)
#    warn Be careful...
#elif !(defined __SOMETHING_REALLY_REALLY_IMPORTANT)
#    error "Nup, can't go on" /* ' /* stupid font-lock-mode */
#else /* defined __SOMETHING_MORE_IMPORTANT && defined __SOMETHING_REALLY_REALLY_IMPORTANT */
#    define EVERYTHING_IS_OK
#endif

/* Test && and || */
#undef WHATEVER
#if (!((defined __SOMETHING_TRIVIAL && defined __SOMETHING_LESS_SO)) \
     || defined __SOMETHING_OVERPOWERING)
#    define WHATEVER 6
#elif !(defined __SOMETHING_TRIVIAL) /* defined __SOMETHING_LESS_SO */
#    define WHATEVER 7
#elif !(defined __SOMETHING_LESS_SO) /* defined __SOMETHING_TRIVIAL */
#    define WHATEVER 8
#else /* defined __SOMETHING_TRIVIAL && defined __SOMETHING_LESS_SO */
#    define WHATEVER 1000
#endif

/* Test passing through the alien constructs (perlbug #34493) */
#ifdef __LANGUAGE_PASCAL__
function Tru64_Pascal(n: Integer): Integer;
#endif

/* 
 * Test #include, #import and #include_next
 * #include_next is difficult to test, it really depends on the actual
 *  circumstances - for example, '#include_next <limits.h>' on a Linux system
 *  with 'use lib qw(/opt/perl5/lib/site_perl/i586-linux/linux);' or whatever
 *  your equivalent is...
 */
#if 0
#include <sys/socket.h>
#import "sys/ioctl.h"
#include_next <sys/fcntl.h>
#endif

/* typedefs should be ignored */
typedef struct a_struct {
  int typedefs_should;
  char be_ignored;
  long as_well;
} a_typedef;

/* 
 * however, typedefs of enums and just plain enums should end up being treated
 * like a bunch of #defines...
 */

typedef enum _days_of_week { sun, mon, tue, wed, thu, fri, sat, Sun=0, Mon,
                             Tue, Wed, Thu, Fri, Sat } days_of_week;

/* 
 * Some moderate flexing of tri-graph pre substitution.
 */
??=ifndef _SOMETHING_TRIGRAPHIC
??=define _SOMETHING_TRIGRAPHIC
??= define SOMETHING_ELSE_TRIGRAPHIC_0 "??!"          /* | ??!|  || */
 ??=define SOMETHING_ELSE_TRIGRAPHIC_1 "??'"          /* | ??'|  ^| */
??= define SOMETHING_ELSE_TRIGRAPHIC_2 "??("          /* | ??(|  [| */
 ??= define SOMETHING_ELSE_TRIGRAPHIC_3 "??)"         /* | ??)|  ]| */
??=define SOMETHING_ELSE_TRIGRAPHIC_4  "??-0"         /* | ??-|  ~| */
        ??= define SOMETHING_ELSE_TRIGRAPHIC_5 "??/ " /* | ??/|  \| */
??= define SOMETHING_ELSE_TRIGRAPHIC_6 "??<"          /* | ??<|  {| */
??=define SOMETHING_ELSE_TRIGRAPHIC_7  "??="          /* | ??=|  #| */
??= define SOMETHING_ELSE_TRIGRAPHIC_8 "??>"          /* | ??>|  }| */
        ??=endif

// test C++-style comment

#if 1
typdef struct empty_struct {
} // trailing C++-style comment should not force continuation
#endif

/* comments (that look like string) inside enums... */

enum {
   /* foo;
     can't
   */                        
 };

enum flimflam {
  flim,
   /* foo;
     can't
   */
  flam                      
 } flamflim;

static __inline__ int blli_in_use(struct atm_blli blli)
{
  return blli.l2_proto || blli.l3_proto;
}

/* Handle multi-line quoted strings: */
__asm__ __volatile__("
    this
    produces
    no
    output
");

#define multiline "multiline
string"

#endif /* _H2PH_H_ */
