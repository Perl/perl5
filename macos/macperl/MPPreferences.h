/*********************************************************************
Project	:	MacPerl				-	Real Perl Application
File		:	MPPreferences.h	-	Handle Preference Settings
Author	:	Matthias Neeracher

A lot of this code is borrowed from 7Edit written by
Apple Developer Support UK

Language	:	MPW C

$Log: MPPreferences.h,v $
Revision 1.1  2000/11/30 08:37:29  neeri
Sources & Resources

Revision 1.2  1997/08/08 16:58:03  neeri
MacPerl 5.1.4b1

Revision 1.1  1997/06/23 17:10:55  neeri
Checked into CVS

Revision 1.1  1994/02/27  23:03:58  neeri
Initial revision

*********************************************************************/

#ifndef __MPPREFERENCES__
#define __MPPREFERENCES__

#include <Types.h>
#include <QuickDraw.h>
#include <Packages.h>
#include <Gestalt.h>
#include <Printing.h>

#ifndef __MPGLOBALS__
#include "MPGlobals.h"
#endif

pascal void OpenPreferenceFile(FSSpec * spec);

pascal void OpenPreferences();

pascal void DoPrefDialog();

pascal Boolean DoFormatDialog(DocFormat * format, Boolean * defaultFormat);

#endif
