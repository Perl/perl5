/* $Header: handy.h,v 3.0 89/10/18 15:34:44 lwall Locked $
 *
 *    Copyright (c) 1989, Larry Wall
 *
 *    You may distribute under the terms of the GNU General Public License
 *    as specified in the README file that comes with the perl 3.0 kit.
 *
 * $Log:	handy.h,v $
 * Revision 3.0  89/10/18  15:34:44  lwall
 * 3.0 baseline
 * 
 */

#define Null(type) ((type)0)
#define Nullch Null(char*)
#define Nullfp Null(FILE*)

#define bool char
#define TRUE (1)
#define FALSE (0)

#define Ctl(ch) (ch & 037)

#define strNE(s1,s2) (strcmp(s1,s2))
#define strEQ(s1,s2) (!strcmp(s1,s2))
#define strLT(s1,s2) (strcmp(s1,s2) < 0)
#define strLE(s1,s2) (strcmp(s1,s2) <= 0)
#define strGT(s1,s2) (strcmp(s1,s2) > 0)
#define strGE(s1,s2) (strcmp(s1,s2) >= 0)
#define strnNE(s1,s2,l) (strncmp(s1,s2,l))
#define strnEQ(s1,s2,l) (!strncmp(s1,s2,l))
