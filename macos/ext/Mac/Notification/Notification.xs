/* $Header: /home/neeri/MacCVS/MacPerl/perl/ext/Mac/ExtUtils/MakeToolboxModule,v 1.2 1997/11/18 00:52:19 neeri Exp 
 *    Copyright (c) 1997 Matthias Neeracher
 *
 *    You may distribute under the terms of the Perl Artistic License,
 *    as specified in the README file.
 *
 * $Log: MakeToolboxModule,v  Revision 1.2  1997/11/18 00:52:19  neeri
 * MacPerl 5.1.5
 * 
 * Revision 1.1  1997/04/07 20:49:35  neeri
 * Synchronized with MacPerl 5.1.4a1
 * 
 */

#define MAC_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <Types.h>
#include <Notification.h>
#include <QuickDraw.h>
#include <Resources.h>
#include <Icons.h>

typedef struct {
	NMRec	nm;
	int		posted;
	Str255	text;
} PerlNMRec, *PerlNMPtr;

#define NMRec	NMRecPtr

static Handle GetOurIcon()
{
	Handle	 icon;

 	return GetIconSuite(&icon, 128, kSelectorAllSmallData) ? nil : icon;
}

MODULE = Mac::Notification	PACKAGE = Mac::Notification

=head2 Types

=over 4

=item NMRec

The notification record. Fields are:

	short 		nmMark;						/* item to mark in Apple menu*/
	Handle 		nmIcon;						/* handle to small icon*/
	Handle 		nmSound;					/* handle to sound record*/
	Str255	 	nmStr;						/* string to appear in alert*/
	long 		nmRefCon;					/* for application use*/

=cut
STRUCT * NMRec
	short 		nmMark;						/* item to mark in Apple menu*/
	Handle 		nmIcon;						/* handle to small icon*/
	Handle 		nmSound;					/* handle to sound record*/
	Str255	 	nmStr;						/* string to appear in alert*/
		ALIAS ((PerlNMPtr)STRUCT)->text
	long 		nmRefCon;					/* for application use*/

=over 4

=item new NMRec (KEY => VALUE...)

Create a new notification record and fill it in.

=cut
MODULE = Mac::Notification	PACKAGE = NMRec

NMRec
_new(package)
	char * package
	CODE:
	RETVAL = (NMRec)NewPtr(sizeof(PerlNMRec));
	RETVAL->qType	= nmType;
	RETVAL->nmMark	= 1;
	RETVAL->nmIcon  = GetOurIcon();
	RETVAL->nmSound = (Handle)-1;
	RETVAL->nmStr   = nil;
	RETVAL->nmResp  = (NMUPP)nil;
	RETVAL->nmRefCon= 0;
	((PerlNMPtr)RETVAL)->posted = false;
	((PerlNMPtr)RETVAL)->text[0]= 0;
	OUTPUT:
	RETVAL

void
DESTROY(rec)
	NMRec	rec
	CODE:
	if (((PerlNMPtr)rec)->posted)
		NMRemove(rec);
	DisposePtr((Ptr)rec);
	
MODULE = Mac::Notification	PACKAGE = Mac::Notification

=back

=back

=head2 Functions

=over 4

=item NMInstall REQUEST

Install a notification.

=cut
MacOSRet
NMInstall(nmRequest)
	NMRec nmRequest
	CODE:
	((PerlNMPtr)nmRequest)->posted = true;
	if (((PerlNMPtr)nmRequest)->text[0])
		nmRequest->nmStr = ((PerlNMPtr)nmRequest)->text;
	else
		nmRequest->nmStr = nil;
	RETVAL = NMInstall(nmRequest);
	OUTPUT:
	RETVAL

=item NMRemove REQUEST

Remove a notification.

=cut
MacOSRet
NMRemove(nmRequest)
	NMRec nmRequest
	CODE:
	((PerlNMPtr)nmRequest)->posted = false;
	RETVAL = NMRemove(nmRequest);
	OUTPUT:
	RETVAL

=back

=cut
