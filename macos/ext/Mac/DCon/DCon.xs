/* $Header: /home/neeri/MacCVS/MacPerl/perl/ext/Mac/ExtUtils/MakeToolboxModule,v 1.2 1997/11/18 00:52:19 neeri Exp 
 *    Copyright (c) 1997 Matthias Neeracher
 *
 * $Log: MakeToolboxModule,v  Revision 1.2  1997/11/18 00:52:19  neeri
 */

#define MAC_CONTEXT

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <Types.h>
#include <DCon.h>

MODULE = Mac::DCon	PACKAGE = Mac::DCon

=head2 Functions

=over 4

=item dopen STREAM

=cut
void
dopen(stream)
	char * stream

void
_dfprint(stream, data)
	char * stream
	char * data
	CODE:
	dfprintf(stream && *stream ? stream : 0, "%s", data);

void
_dfprintmem(stream, addr, len)
	char * 	stream
	Ptr		addr
	long	len
	CODE:
	dfprintmem(stream && *stream ? stream : 0, addr, len);
