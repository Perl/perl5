/*********************************************************************
Project	:	MacPerl			-	Real Perl Application
File		:	MPExtension.r	-	Common definitions for extensions
Authors	:	Matthias Neeracher & Tim Endres
Language	:	MPW C

$Log: MPExtension.r,v $
Revision 1.1  2000/11/30 08:37:29  neeri
Sources & Resources

Revision 1.1  1997/06/23 17:10:43  neeri
Checked into CVS

*********************************************************************/

#define SERsrcBase	32700

#ifndef MPEXT_VERSION
#define MPEXT_VERSION '0100'
#endif

type 'McPp' {
	literal 	longint = MPEXT_VERSION;
	literal 	longint;										/* Extension ID						*/
	literal 	longint;										/* Type of created file				*/
	literal 	longint;										/* Creator of created file			*/
	boolean 	noBundle, 		wantsBundle;
	boolean 	noCustomIcon, 	hasCustomIcon;
	fill 		bit[30];
};

type 'McPs' {
	wide array {
		literal longint;										/* Resource type in extension		*/
		literal longint;										/* Resource type in created file	*/
		integer;													/* Original resource ID				*/
		integer;													/* New resource ID					*/							
	};
};
