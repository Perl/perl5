/*********************************************************************
Project	:	MacPerl			-	Real Perl Application
File		:	MPMain.h			-	The main event loop
Author	:	Matthias Neeracher

A lot of this code is borrowed from 7Edit written by
Apple Developer Support UK

Language	:	MPW C

$Log: MPMain.h,v $
Revision 1.1  2000/11/30 08:37:29  neeri
Sources & Resources

Revision 1.1  1997/06/23 17:10:53  neeri
Checked into CVS

Revision 1.1  1994/02/27  23:03:48  neeri
Initial revision

Revision 0.3  1993/11/27  00:00:00  neeri
busy

Revision 0.2  1993/05/30  00:00:00  neeri
Support Console Windows

Revision 0.1  1993/05/29  00:00:00  neeri
Compiles correctly

*********************************************************************/

void MainEvent(Boolean busy, long sleep, RgnHandle rgn);

void HandleEvent(EventRecord * myEvent);