/* $Header: handy.h,v 3.0 89/10/18 15:18:24 lwall Locked $
 *
 *    Copyright (c) 1989, Larry Wall
 *
 *    You may distribute under the terms of the GNU General Public License
 *    as specified in the README file that comes with the perl 3.0 kit.
 *
 * $Log:	handy.h,v $
 * Revision 3.0  89/10/18  15:18:24  lwall
 * 3.0 baseline
 * 
 */

#ifdef NULL
#undef NULL
#endif
#ifndef I286
#  define NULL 0
#else
#  define NULL 0L
#endif
#define Null(type) ((type)NULL)
#define Nullch Null(char*)
#define Nullfp Null(FILE*)

#ifdef UTS
#define bool int
#else
#define bool char
#endif
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

#ifndef lint
#ifndef LEAKTEST
char *safemalloc();
char *saferealloc();
void safefree();
#define New(x,v,n,t)  (v = (t*)safemalloc((MEM_SIZE)((n) * sizeof(t))))
#define Newc(x,v,n,t,c)  (v = (c*)safemalloc((MEM_SIZE)((n) * sizeof(t))))
#define Newz(x,v,n,t) (v = (t*)safemalloc((MEM_SIZE)((n) * sizeof(t)))), \
    bzero((char*)(v), (n) * sizeof(t))
#define Renew(v,n,t) (v = (t*)saferealloc((char*)(v),(MEM_SIZE)((n)*sizeof(t))))
#define Renewc(v,n,t,c) (v = (c*)saferealloc((char*)(v),(MEM_SIZE)((n)*sizeof(t))))
#define Safefree(d) safefree((char*)d)
#define Str_new(x,len) str_new(len)
#else /* LEAKTEST */
char *safexmalloc();
char *safexrealloc();
void safexfree();
#define New(x,v,n,t)  (v = (t*)safexmalloc(x,(MEM_SIZE)((n) * sizeof(t))))
#define Newc(x,v,n,t,c)  (v = (c*)safexmalloc(x,(MEM_SIZE)((n) * sizeof(t))))
#define Newz(x,v,n,t) (v = (t*)safexmalloc(x,(MEM_SIZE)((n) * sizeof(t)))), \
    bzero((char*)(v), (n) * sizeof(t))
#define Renew(v,n,t) (v = (t*)safexrealloc((char*)(v),(MEM_SIZE)((n)*sizeof(t))))
#define Renewc(v,n,t,c) (v = (c*)safexrealloc((char*)(v),(MEM_SIZE)((n)*sizeof(t))))
#define Safefree(d) safexfree((char*)d)
#define Str_new(x,len) str_new(x,len)
#define MAXXCOUNT 1200
long xcount[MAXXCOUNT];
long lastxcount[MAXXCOUNT];
#endif /* LEAKTEST */
#define Copy(s,d,n,t) (void)bcopy((char*)(s),(char*)(d), (n) * sizeof(t))
#define Zero(d,n,t) (void)bzero((char*)(d), (n) * sizeof(t))
#else /* lint */
#define New(x,v,n,s) (v = Null(s *))
#define Newc(x,v,n,s,c) (v = Null(s *))
#define Newz(x,v,n,s) (v = Null(s *))
#define Renew(v,n,s) (v = Null(s *))
#define Copy(s,d,n,t)
#define Zero(d,n,t)
#define Safefree(d) d = d
#endif /* lint */
