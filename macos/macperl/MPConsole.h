/*********************************************************************
Project	:	MacPerl			-	Standalone Perl
File		:	MPConsole.cp	-	Console interface for GUSI
Author	:	Matthias Neeracher
Language	:	MPW C/C++

$Log: MPConsole.h,v $
Revision 1.1  2000/11/30 08:37:29  neeri
Sources & Resources

Revision 1.2  1997/11/18 00:53:51  neeri
MacPerl 5.1.5

Revision 1.1  1997/06/23 17:10:37  neeri
Checked into CVS

Revision 1.1  1994/02/27  23:02:58  neeri
Initial revision

Revision 0.1  1993/08/14  00:00:00  neeri
WIOSELECT

*********************************************************************/

#include <Memory.h>

#ifdef __cplusplus
extern "C" {
#endif

#define WIOSELECT (('w'<<8)|0x00)	/* Put window to front */

void InitConsole();
void CloseConsole(Ptr cookie);
void ResetConsole();
Boolean DoRawConsole(Ptr cookie, char theChar);

#ifdef __cplusplus
}
#endif
