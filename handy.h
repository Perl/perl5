/* $Header: handy.h,v 2.0 88/06/05 00:09:03 root Exp $
 *
 * $Log:	handy.h,v $
 * Revision 2.0  88/06/05  00:09:03  root
 * Baseline version 2.0.
 * 
 */

#ifdef NULL
#undef NULL
#endif
#define NULL 0
#define Null(type) ((type)NULL)
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

#define MEM_SIZE unsigned int

/* Line numbers are unsigned, 16 bits. */
typedef unsigned short line_t;
#ifdef lint
#define NOLINE ((line_t)0)
#else
#define NOLINE ((line_t) 65535)
#endif

