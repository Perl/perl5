/*********************************************************************
Project	:	MacPerl			-	Standalone Perl
File		:	MemoryStream.h	-	Console interface for Perl handle based streams
Author	:	Matthias Neeracher
Language	:	MPW C/C++

$Log: MemoryStream.h,v $
Revision 1.1  2000/11/30 08:37:29  neeri
Sources & Resources

Revision 1.1  1997/06/23 17:11:15  neeri
Checked into CVS

*********************************************************************/


#ifdef __cplusplus
extern "C" {
#endif

void InstallMemConsole(Handle stdin, Handle stdout, Handle stderr);

#ifdef __cplusplus
}
#endif
