/* $Header: /cvsroot/macperl/perl/macos/ext/Mac/Types/Types.xs,v 1.2 2000/09/09 22:18:29 neeri Exp $
 *
 *    Copyright (c) 1996 Matthias Neeracher
 *
 *    You may distribute under the terms of the Perl Artistic License,
 *    as specified in the README file.
 *
 * $Log: Types.xs,v $
 * Revision 1.2  2000/09/09 22:18:29  neeri
 * Dynamic libraries compile under 5.6
 *
 * Revision 1.1  2000/08/14 03:39:34  neeri
 * Checked into Sourceforge
 *
 * Revision 1.2  1997/11/18 00:53:26  neeri
 * MacPerl 5.1.5
 *
 * Revision 1.1  1997/04/07 20:50:56  neeri
 * Synchronized with MacPerl 5.1.4a1
 *
 */

#define MAC_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <Types.h>

MODULE = Mac::Types	PACKAGE = Mac::Types

=head2 Functions

=over 4

=item Debugger [ MSG ]

Break into MacsBug. Don't use this if you don't know what MacsBug is.

=cut
void
Debugger(msg=NULL)
	SV *	msg
	CODE:
	if (msg) {
		Str255 message;
		MacPerl_CopyC2P(SvPV_nolen(msg), message);
		DebugStr(message);
	} else
		Debugger();

=back

=cut

