/*********************************************************************
Project	:	MacPerl			-	Real Perl Application
File		:	MPHelp.h			-	Various helpful functions
Author	:	Matthias Neeracher
Language	:	MPW C

$Log: MPHelp.h,v $
Revision 1.1  2000/11/30 08:37:29  neeri
Sources & Resources

Revision 1.1  1997/06/23 17:10:50  neeri
Checked into CVS

Revision 1.1  1994/02/27  23:03:39  neeri
Initial revision

Revision 0.1  1993/09/16  00:00:00  neeri
Runtime doesn't support Ballons

*********************************************************************/

#ifndef __MPHELP__
#define __MPHELP__

#include <Memory.h>
#include <QuickDraw.h>
#include <Types.h>

#include "MPGlobals.h"

void InitHelp();

void Explain(DPtr doc);

void LaunchHelpURL(char * urlPtr, int urlLen);

void DoHelp(short menu, short item);

void EndHelp();

#endif