/*    INTERN.h
 *
 *    Copyright (C) 1991, 1992, 1993, 1995, 1996, 1998, 2000, 2001,
 *    by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

/*

=for apidoc  CmU||EXT
=for apidoc_item  EXTCONST
=for apidoc_item  dEXT
=for apidoc_item  dEXTCONST

These each designate a global variable.  The C<CONST> forms indicate that it is
constant.

Use them like this:

 Include either EXTERN.h or INTERN.h, but not both
 ...
 #include "perl.h"
 ...
 EXT char PL_WARN_ALL  INIT(0);
 EXTCONST U8 PL_revision  INIT(PERL_REVISION);

This will handle everything for you regarding whether they are to actually be
defined and initialized or just declared C<extern>.

If the initialization is complex, you may have to use C<L</DOINIT>>.

If some constants you wish to reference will not become defined by #including
F<perl.h>, instead use C<dEXT> and C<dEXTCONST> for them and include whatever
files you need to to get them.  This is currently very rare, and should be
avoided.

=cut
 */

#undef EXT
#undef dEXT
#undef EXTCONST
#undef dEXTCONST

#  if (defined(WIN32) && defined(__MINGW32__) && ! defined(PERL_IS_MINIPERL))
#    ifdef __cplusplus
#      define EXT	__declspec(dllexport)
#      define dEXT
#      define EXTCONST	__declspec(dllexport) extern const
#      define dEXTCONST	const
#    else
#      define EXT	__declspec(dllexport)
#      define dEXT
#      define EXTCONST	__declspec(dllexport) const
#      define dEXTCONST	const
#    endif
#  else
#    ifdef __cplusplus
#      define EXT
#      define dEXT
#      define EXTCONST EXTERN_C const
#      define dEXTCONST const
#    else
#      define EXT
#      define dEXT
#      define EXTCONST const
#      define dEXTCONST const
#    endif
#  endif

/*
=for apidoc Cm||INIT|const_expr

Macro to initialize something, used like so:

 EXTCONST char PL_memory_wrap[]  INIT("panic: memory wrap");

It expands to nothing in F<EXTERN.h>.

=cut
*/
#undef INIT
#define INIT(...) = __VA_ARGS__

/*
=for apidoc C#||DOINIT

This is defined in F<INTERN.h>, undefined in F<EXTERN.h>

Most of the time you can use C<L</INIT>> to initialize your data structures.
But not always.  In such cases, you can do the following:

 #ifdef DOINIT
    ... do the declaration and definition ...
 #else
    declaration only
 #endif

A typical reason for needing this is when the definition includes #ifdef's.
You can't put that portably in a call to C<INIT>, as a macro generally can't
itself contain preprocessor directives.

=cut
*/
#define DOINIT
