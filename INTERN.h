/* $Header: INTERN.h,v 3.0 89/10/18 15:06:25 lwall Locked $
 *
 *    Copyright (c) 1989, Larry Wall
 *
 *    You may distribute under the terms of the GNU General Public License
 *    as specified in the README file that comes with the perl 3.0 kit.
 *
 * $Log:	INTERN.h,v $
 * Revision 3.0  89/10/18  15:06:25  lwall
 * 3.0 baseline
 * 
 */

#undef EXT
#define EXT

#undef INIT
#define INIT(x) = x

#define DOINIT
