/* $Header: /cvsroot/macperl/perl/macos/ext/Mac/Events/Events.xs,v 1.3 2001/04/16 04:45:15 neeri Exp $
 *
 *    Copyright (c) 1996 Matthias Neeracher
 *
 *    You may distribute under the terms of the Perl Artistic License,
 *    as specified in the README file.
 *
 * $Log: Events.xs,v $
 * Revision 1.3  2001/04/16 04:45:15  neeri
 * Switch from atexit() to Perl_call_atexit (MacPerl bug #232158)
 *
 * Revision 1.2  2000/09/09 22:18:26  neeri
 * Dynamic libraries compile under 5.6
 *
 * Revision 1.1  2000/08/14 03:39:29  neeri
 * Checked into Sourceforge
 *
 * Revision 1.2  1997/11/18 00:52:17  neeri
 * MacPerl 5.1.5
 *
 * Revision 1.1  1997/04/07 20:49:28  neeri
 * Synchronized with MacPerl 5.1.4a1
 *
 */

#define MAC_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <Types.h>
#include <Memory.h>
#include <Events.h>

typedef EventRecord	* ToolboxEvent;

static void WipeFilter(pTHX_ void * p)
{
	gMacPerl_FilterEvent= nil;
	gMacPerl_FilterMenu	= nil;
}

static void FilterEvent(ToolboxEvent ev)
{
	AV *  events = perl_get_av("Mac::Events::Event", 2);
	SV ** handler= av_fetch(events, ev->what, 0);
	
	if (handler && SvTRUE(*handler)) {
		int count ;
		SV *result;
      	dSP ;
 
        ENTER ;
        SAVETMPS;

        PUSHMARK(sp) ;
        XPUSHs(sv_setref_pv(sv_newmortal(), "ToolboxEvent", (void*)ev));
        PUTBACK ;

        count = perl_call_pv("Mac::Events::DispatchEvent", G_SCALAR);

        SPAGAIN ;

		result = POPs;
        if (SvTRUE(result))
            ev->what = nullEvent;

        PUTBACK ;
        FREETMPS ;
        LEAVE ;
	}
}

MODULE = Mac::Events	PACKAGE = ToolboxEvent

BOOT:
gMacPerl_FilterEvent= FilterEvent;
Perl_call_atexit(aTHX_ WipeFilter, NULL);

=head2 Structures

=over 4

=item ToolboxEvent

This type represents an Event record with the following fields:

=over 4

=item what
	
Event type.

=item message

Event message.

=item when

Event time.

=item where

Mouse position in global coordinates.

=item modifiers

Global flags.

=back

Additionally, a few read only accessors are provided to conveniently access the 
event specific meaning of the C<message> field:

=over 4

=item window

The affected window for activate and update events.

=item character

The character code for C<keyDown>, C<keyUp>, and C<autoKey> events.

=item key

The key code for C<keyDown>, C<keyUp>, and C<autoKey> events.

=item osMessage

The subevent for suspend, resume, and mouse-moved events.

=back

=back

=cut
STRUCT * ToolboxEvent
	short			what;
	U32				message;
	U32				when;
	Point			where;
	U16				modifiers;
	GrafPtr			window;
		READ_ONLY
		OUTPUT:
		XS_OUTPUT(GrafPtr, (GrafPtr)STRUCT->message, $arg);
	U8				character;
		READ_ONLY
		OUTPUT:
		XS_OUTPUT(U8, STRUCT->message & 0xFF, $arg);
	U8				key;
		READ_ONLY
		OUTPUT:
		XS_OUTPUT(U8, (STRUCT->message>>8) & 0xFF, $arg);
	U8				osMessage;
		READ_ONLY
		OUTPUT:
		XS_OUTPUT(U8, (STRUCT->message>>24) & 0xFF, $arg);

MODULE = Mac::Events	PACKAGE = Mac::Events

=head2 Functions

=over 4

=item GetCaretTime()

Returns interval for caret blinking.

=cut
long
GetCaretTime()

=item GetDblTime()

Returns double-click interval.

=cut
long
GetDblTime()
	
=item GetMouse()

Returns the current mouse position.

=cut
Point
GetMouse()
	CODE:
	GetMouse(&RETVAL);
	OUTPUT:
	RETVAL

=item Button()

Returns the current state of the mouse button.

=cut
Boolean
Button()

=item DOWN = StillDown()

Returns whether the button is still down after the last C<mouseDown> event 
processed.

=cut
Boolean
StillDown()
		
=item UP = WaitMouseUp()

Wait until the mouse button is released.

=cut
Boolean
WaitMouseUp()
		
=item TICKS = TickCount()

Returns the current time in 60th of a second since startup.

=cut
long
TickCount()
		
=item FlushEvents WHICHMASK, STOPMASK

Discard events matching WHICHMASK until an event matching STOPMASK is found.

=cut
void
FlushEvents(whichMask, stopMask)
	short 	whichMask
	short 	stopMask

=item WaitNextEvent [SLEEP [, RGN] ]

Waits for the next event but doesn't return anything. Event processing is purely
implicit.

=cut
void
WaitNextEvent(sleep=-1, rgn=nil)
	long		sleep
	RgnHandle	rgn
	CODE:
	(*gMacPerl_WaitEvent)(false, sleep, rgn);
