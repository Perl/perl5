/*    handy.h
 *
 *    Copyright (c) 1991-1999, Larry Wall
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

#if !defined(__STDC__)
#ifdef NULL
#undef NULL
#endif
#ifndef I286
#  define NULL 0
#else
#  define NULL 0L
#endif
#endif

#define Null(type) ((type)NULL)
#define Nullch Null(char*)
#define Nullfp Null(PerlIO*)
#define Nullsv Null(SV*)

#ifdef TRUE
#undef TRUE
#endif
#ifdef FALSE
#undef FALSE
#endif
#define TRUE (1)
#define FALSE (0)


/* XXX Configure ought to have a test for a boolean type, if I can
   just figure out all the headers such a test needs.
   Andy Dougherty	August 1996
*/
/* bool is built-in for g++-2.6.3, which might be used for an extension.
   If the extension includes <_G_config.h> before this file then
   _G_HAVE_BOOL will be properly set.  If, however, the extension includes
   this file first, then you will have to manually set -DHAS_BOOL in 
   your command line to avoid a conflict.
*/
#ifdef _G_HAVE_BOOL
# if _G_HAVE_BOOL
#  ifndef HAS_BOOL
#   define HAS_BOOL 1
#  endif
# endif
#endif

/* The NeXT dynamic loader headers will not build with the bool macro
   So declare them now to clear confusion.
*/
#if defined(NeXT) || defined(__NeXT__)
# undef FALSE
# undef TRUE
  typedef enum bool { FALSE = 0, TRUE = 1 } bool;
# define ENUM_BOOL 1
# ifndef HAS_BOOL
#  define HAS_BOOL 1
# endif /* !HAS_BOOL */
#endif /* NeXT || __NeXT__ */

#ifndef HAS_BOOL
# if defined(UTS) || defined(VMS)
#  define bool int
# else
#  define bool char
# endif
#endif

/* XXX A note on the perl source internal type system.  The
   original intent was that I32 be *exactly* 32 bits.

   Currently, we only guarantee that I32 is *at least* 32 bits.
   Specifically, if int is 64 bits, then so is I32.  (This is the case
   for the Cray.)  This has the advantage of meshing nicely with
   standard library calls (where we pass an I32 and the library is
   expecting an int), but the disadvantage that an I32 is not 32 bits.
   Andy Dougherty	August 1996

   There is no guarantee that there is *any* integral type with
   exactly 32 bits.  It is perfectly legal for a system to have
   sizeof(short) == sizeof(int) == sizeof(long) == 8.

   Similarly, there is no guarantee that I16 and U16 have exactly 16
   bits.

   For dealing with issues that may arise from various 32/64-bit 
   systems, we will ask Configure to check out 
   	SHORTSIZE == sizeof(short)
   	INTSIZE == sizeof(int)
   	LONGSIZE == sizeof(long)
	LONGLONGSIZE == sizeof(long long) (if HAS_LONG_LONG)
   	PTRSIZE == sizeof(void *)
	DOUBLESIZE == sizeof(double)
	LONG_DOUBLESIZE == sizeof(long double) (if HAS_LONG_DOUBLE).
    Most of these are currently unused, but they are mentioned here so
    metaconfig will include the appropriate tests in Configure and
    we can then start to consider how best to deal with long long
    variables.
   Andy Dougherty	April 1998
*/

#if defined(UINT8_MAX) && defined(INT16_MAX) && defined(INT32_MAX)

typedef int8_t		I8;
typedef uint8_t		U8;
/* I8_MAX and I8_MIN constants are not defined, as I8 is an ambiguous type.
   Please search CHAR_MAX in perl.h for further details. */
#define U8_MAX UINT8_MAX
#define U8_MIN UINT8_MIN

typedef int16_t         I16;
typedef uint16_t        U16;
#define I16_MAX INT16_MAX
#define I16_MIN INT16_MIN
#define U16_MAX UINT16_MAX
#define U16_MIN UINT16_MIN

typedef int32_t         I32;
typedef uint32_t        U32;
#define I32_MAX INT32_MAX
#define I32_MIN INT32_MIN
#define U32_MAX UINT32_MAX
#define U32_MIN UINT32_MIN

#else

typedef char		I8;
typedef unsigned char	U8;
/* I8_MAX and I8_MIN constants are not defined, as I8 is an ambiguous type.
   Please search CHAR_MAX in perl.h for further details. */
#define U8_MAX PERL_UCHAR_MAX
#define U8_MIN PERL_UCHAR_MIN

/* Beware.  SHORTSIZE > 2 in Cray C90ties. */
typedef short		I16;
typedef unsigned short	U16;
#define I16_MAX PERL_SHORT_MAX
#define I16_MIN PERL_SHORT_MIN
#define U16_MAX PERL_USHORT_MAX
#define U16_MIN PERL_USHORT_MIN

#if LONGSIZE > 4
  typedef int		I32;
  typedef unsigned int	U32;
# define I32_MAX PERL_INT_MAX
# define I32_MIN PERL_INT_MIN
# define U32_MAX PERL_UINT_MAX
# define U32_MIN PERL_UINT_MIN
#else
  typedef long		I32;
  typedef unsigned long	U32;
# define I32_MAX PERL_LONG_MAX
# define I32_MIN PERL_LONG_MIN
# define U32_MAX PERL_ULONG_MAX
# define U32_MIN PERL_ULONG_MIN
#endif

#endif

#define BIT_DIGITS(N)   (((N)*146)/485 + 1)  /* log2(10) =~ 146/485 */
#define TYPE_DIGITS(T)  BIT_DIGITS(sizeof(T) * 8)
#define TYPE_CHARS(T)   (TYPE_DIGITS(T) + 2) /* sign, NUL */

#define Ctl(ch) ((ch) & 037)

#define strNE(s1,s2) (strcmp(s1,s2))
#define strEQ(s1,s2) (!strcmp(s1,s2))
#define strLT(s1,s2) (strcmp(s1,s2) < 0)
#define strLE(s1,s2) (strcmp(s1,s2) <= 0)
#define strGT(s1,s2) (strcmp(s1,s2) > 0)
#define strGE(s1,s2) (strcmp(s1,s2) >= 0)
#define strnNE(s1,s2,l) (strncmp(s1,s2,l))
#define strnEQ(s1,s2,l) (!strncmp(s1,s2,l))

#ifdef HAS_MEMCMP
#  define memNE(s1,s2,l) (memcmp(s1,s2,l))
#  define memEQ(s1,s2,l) (!memcmp(s1,s2,l))
#else
#  define memNE(s1,s2,l) (bcmp(s1,s2,l))
#  define memEQ(s1,s2,l) (!bcmp(s1,s2,l))
#endif

/*
 * Character classes.
 *
 * Unfortunately, the introduction of locales means that we
 * can't trust isupper(), etc. to tell the truth.  And when
 * it comes to /\w+/ with tainting enabled, we *must* be able
 * to trust our character classes.
 *
 * Therefore, the default tests in the text of Perl will be
 * independent of locale.  Any code that wants to depend on
 * the current locale will use the tests that begin with "lc".
 */

#ifdef HAS_SETLOCALE  /* XXX Is there a better test for this? */
#  ifndef CTYPE256
#    define CTYPE256
#  endif
#endif

#define isALNUM(c)	(isALPHA(c) || isDIGIT(c) || (c) == '_')
#define isIDFIRST(c)	(isALPHA(c) || (c) == '_')
#define isALPHA(c)	(isUPPER(c) || isLOWER(c))
#define isSPACE(c) \
	((c) == ' ' || (c) == '\t' || (c) == '\n' || (c) =='\r' || (c) == '\f')
#define isDIGIT(c)	((c) >= '0' && (c) <= '9')
#ifdef EBCDIC
    /* In EBCDIC we do not do locales: therefore() isupper() is fine. */
#   define isUPPER(c)	isupper(c)
#   define isLOWER(c)	islower(c)
#   define isALNUMC(c)	isalnum(c)
#   define isASCII(c)	isascii(c)
#   define isCNTRL(c)	iscntrl(c)
#   define isGRAPH(c)	isgraph(c)
#   define isPRINT(c)	isprint(c)
#   define isPUNCT(c)	ispunct(c)
#   define isXDIGIT(c)	isxdigit(c)
#   define toUPPER(c)	toupper(c)
#   define toLOWER(c)	tolower(c)
#else
#   define isUPPER(c)	((c) >= 'A' && (c) <= 'Z')
#   define isLOWER(c)	((c) >= 'a' && (c) <= 'z')
#   define isALNUMC(c)	(isALPHA(c) || isDIGIT(c))
#   define isASCII(c)	((c) <= 127)
#   define isCNTRL(c)	((c) < ' ')
#   define isGRAPH(c)	(isALNUM(c) || isPUNCT(c))
#   define isPRINT(c)	(((c) > 32 && (c) < 127) || isSPACE(c))
#   define isPUNCT(c)	(((c) >= 33 && (c) <= 47) || ((c) >= 58 && (c) <= 64)  || ((c) >= 91 && (c) <= 96) || ((c) >= 123 && (c) <= 126))
#   define isXDIGIT(c)  (isdigit(c) || ((c) >= 'a' && (c) <= 'f') || ((c) >= 'A' && (c) <= 'F'))
#   define toUPPER(c)	(isLOWER(c) ? (c) - ('a' - 'A') : (c))
#   define toLOWER(c)	(isUPPER(c) ? (c) + ('a' - 'A') : (c))
#endif

#ifdef USE_NEXT_CTYPE

#  define isALNUM_LC(c) \
	(NXIsAlnum((unsigned int)(c)) || (char)(c) == '_')
#  define isIDFIRST_LC(c) \
	(NXIsAlpha((unsigned int)(c)) || (char)(c) == '_')
#  define isALPHA_LC(c)		NXIsAlpha((unsigned int)(c))
#  define isSPACE_LC(c)		NXIsSpace((unsigned int)(c))
#  define isDIGIT_LC(c)		NXIsDigit((unsigned int)(c))
#  define isUPPER_LC(c)		NXIsUpper((unsigned int)(c))
#  define isLOWER_LC(c)		NXIsLower((unsigned int)(c))
#  define isALNUMC_LC(c)	NXIsAlnum((unsigned int)(c))
#  define isCNTRL_LC(c)		NXIsCntrl((unsigned int)(c))
#  define isGRAPH_LC(c)		NXIsGraph((unsigned int)(c))
#  define isPRINT_LC(c)		NXIsPrint((unsigned int)(c))
#  define isPUNCT_LC(c)		NXIsPunct((unsigned int)(c))
#  define toUPPER_LC(c)		NXToUpper((unsigned int)(c))
#  define toLOWER_LC(c)		NXToLower((unsigned int)(c))

#else /* !USE_NEXT_CTYPE */

#  if defined(CTYPE256) || (!defined(isascii) && !defined(HAS_ISASCII))

#    define isALNUM_LC(c)   (isalnum((unsigned char)(c)) || (char)(c) == '_')
#    define isIDFIRST_LC(c) (isalpha((unsigned char)(c)) || (char)(c) == '_')
#    define isALPHA_LC(c)	isalpha((unsigned char)(c))
#    define isSPACE_LC(c)	isspace((unsigned char)(c))
#    define isDIGIT_LC(c)	isdigit((unsigned char)(c))
#    define isUPPER_LC(c)	isupper((unsigned char)(c))
#    define isLOWER_LC(c)	islower((unsigned char)(c))
#    define isALNUMC_LC(c)	isalnum((unsigned char)(c))
#    define isCNTRL_LC(c)	iscntrl((unsigned char)(c))
#    define isGRAPH_LC(c)	isgraph((unsigned char)(c))
#    define isPRINT_LC(c)	isprint((unsigned char)(c))
#    define isPUNCT_LC(c)	ispunct((unsigned char)(c))
#    define toUPPER_LC(c)	toupper((unsigned char)(c))
#    define toLOWER_LC(c)	tolower((unsigned char)(c))

#  else

#    define isALNUM_LC(c) 	(isascii(c) && (isalnum(c) || (c) == '_'))
#    define isIDFIRST_LC(c)	(isascii(c) && (isalpha(c) || (c) == '_'))
#    define isALPHA_LC(c)	(isascii(c) && isalpha(c))
#    define isSPACE_LC(c)	(isascii(c) && isspace(c))
#    define isDIGIT_LC(c)	(isascii(c) && isdigit(c))
#    define isUPPER_LC(c)	(isascii(c) && isupper(c))
#    define isLOWER_LC(c)	(isascii(c) && islower(c))
#    define isALNUMC_LC(c)	(isascii(c) && isalnum(c))
#    define isCNTRL_LC(c)	(isascii(c) && iscntrl(c))
#    define isGRAPH_LC(c)	(isascii(c) && isgraph(c))
#    define isPRINT_LC(c)	(isascii(c) && isprint(c))
#    define isPUNCT_LC(c)	(isascii(c) && ispunct(c))
#    define toUPPER_LC(c)	toupper(c)
#    define toLOWER_LC(c)	tolower(c)

#  endif
#endif /* USE_NEXT_CTYPE */

#define isALNUM_uni(c)		is_uni_alnum(c)
#define isIDFIRST_uni(c)	is_uni_idfirst(c)
#define isALPHA_uni(c)		is_uni_alpha(c)
#define isSPACE_uni(c)		is_uni_space(c)
#define isDIGIT_uni(c)		is_uni_digit(c)
#define isUPPER_uni(c)		is_uni_upper(c)
#define isLOWER_uni(c)		is_uni_lower(c)
#define isALNUMC_uni(c)		is_uni_alnumc(c)
#define isASCII_uni(c)		is_uni_ascii(c)
#define isCNTRL_uni(c)		is_uni_cntrl(c)
#define isGRAPH_uni(c)		is_uni_graph(c)
#define isPRINT_uni(c)		is_uni_print(c)
#define isPUNCT_uni(c)		is_uni_punct(c)
#define isXDIGIT_uni(c)		is_uni_xdigit(c)
#define toUPPER_uni(c)		to_uni_upper(c)
#define toTITLE_uni(c)		to_uni_title(c)
#define toLOWER_uni(c)		to_uni_lower(c)

#define isALNUM_LC_uni(c)	(c < 256 ? isALNUM_LC(c) : is_uni_alnum_lc(c))
#define isIDFIRST_LC_uni(c)	(c < 256 ? isIDFIRST_LC(c) : is_uni_idfirst_lc(c))
#define isALPHA_LC_uni(c)	(c < 256 ? isALPHA_LC(c) : is_uni_alpha_lc(c))
#define isSPACE_LC_uni(c)	(c < 256 ? isSPACE_LC(c) : is_uni_space_lc(c))
#define isDIGIT_LC_uni(c)	(c < 256 ? isDIGIT_LC(c) : is_uni_digit_lc(c))
#define isUPPER_LC_uni(c)	(c < 256 ? isUPPER_LC(c) : is_uni_upper_lc(c))
#define isLOWER_LC_uni(c)	(c < 256 ? isLOWER_LC(c) : is_uni_lower_lc(c))
#define isALNUMC_LC_uni(c)	(c < 256 ? isALNUMC_LC(c) : is_uni_alnumc_lc(c))
#define isCNTRL_LC_uni(c)	(c < 256 ? isCNTRL_LC(c) : is_uni_cntrl_lc(c))
#define isGRAPH_LC_uni(c)	(c < 256 ? isGRAPH_LC(c) : is_uni_graph_lc(c))
#define isPRINT_LC_uni(c)	(c < 256 ? isPRINT_LC(c) : is_uni_print_lc(c))
#define isPUNCT_LC_uni(c)	(c < 256 ? isPUNCT_LC(c) : is_uni_punct_lc(c))
#define toUPPER_LC_uni(c)	(c < 256 ? toUPPER_LC(c) : to_uni_upper_lc(c))
#define toTITLE_LC_uni(c)	(c < 256 ? toUPPER_LC(c) : to_uni_title_lc(c))
#define toLOWER_LC_uni(c)	(c < 256 ? toLOWER_LC(c) : to_uni_lower_lc(c))

#define isALNUM_utf8(p)		is_utf8_alnum(p)
#define isIDFIRST_utf8(p)	is_utf8_idfirst(p)
#define isALPHA_utf8(p)		is_utf8_alpha(p)
#define isSPACE_utf8(p)		is_utf8_space(p)
#define isDIGIT_utf8(p)		is_utf8_digit(p)
#define isUPPER_utf8(p)		is_utf8_upper(p)
#define isLOWER_utf8(p)		is_utf8_lower(p)
#define isALNUMC_utf8(p)	is_utf8_alnumc(p)
#define isASCII_utf8(p)		is_utf8_ascii(p)
#define isCNTRL_utf8(p)		is_utf8_cntrl(p)
#define isGRAPH_utf8(p)		is_utf8_graph(p)
#define isPRINT_utf8(p)		is_utf8_print(p)
#define isPUNCT_utf8(p)		is_utf8_punct(p)
#define isXDIGIT_utf8(p)	is_utf8_xdigit(p)
#define toUPPER_utf8(p)		to_utf8_upper(p)
#define toTITLE_utf8(p)		to_utf8_title(p)
#define toLOWER_utf8(p)		to_utf8_lower(p)

#define isALNUM_LC_utf8(p)	isALNUM_LC_uni(utf8_to_uv(p, 0))
#define isIDFIRST_LC_utf8(p)	isIDFIRST_LC_uni(utf8_to_uv(p, 0))
#define isALPHA_LC_utf8(p)	isALPHA_LC_uni(utf8_to_uv(p, 0))
#define isSPACE_LC_utf8(p)	isSPACE_LC_uni(utf8_to_uv(p, 0))
#define isDIGIT_LC_utf8(p)	isDIGIT_LC_uni(utf8_to_uv(p, 0))
#define isUPPER_LC_utf8(p)	isUPPER_LC_uni(utf8_to_uv(p, 0))
#define isLOWER_LC_utf8(p)	isLOWER_LC_uni(utf8_to_uv(p, 0))
#define isALNUMC_LC_utf8(p)	isALNUMC_LC_uni(utf8_to_uv(p, 0))
#define isCNTRL_LC_utf8(p)	isCNTRL_LC_uni(utf8_to_uv(p, 0))
#define isGRAPH_LC_utf8(p)	isGRAPH_LC_uni(utf8_to_uv(p, 0))
#define isPRINT_LC_utf8(p)	isPRINT_LC_uni(utf8_to_uv(p, 0))
#define isPUNCT_LC_utf8(p)	isPUNCT_LC_uni(utf8_to_uv(p, 0))
#define toUPPER_LC_utf8(p)	toUPPER_LC_uni(utf8_to_uv(p, 0))
#define toTITLE_LC_utf8(p)	toTITLE_LC_uni(utf8_to_uv(p, 0))
#define toLOWER_LC_utf8(p)	toLOWER_LC_uni(utf8_to_uv(p, 0))

#ifdef EBCDIC
EXT int ebcdic_control (int);
#  define toCTRL(c)	ebcdic_control(c)
#else
  /* This conversion works both ways, strangely enough. */
#  define toCTRL(c)    (toUPPER(c) ^ 64)
#endif

/* Line numbers are unsigned, 16 bits. */
typedef U16 line_t;
#ifdef lint
#define NOLINE ((line_t)0)
#else
#define NOLINE ((line_t) 65535)
#endif


/* This looks obsolete (IZ):

   XXX LEAKTEST doesn't really work in perl5.  There are direct calls to
   safemalloc() in the source, so LEAKTEST won't pick them up.
   Further, if you try LEAKTEST, you'll also end up calling
   Safefree, which might call safexfree() on some things that weren't
   malloced with safexmalloc.  The correct "fix" to this, if anyone
   is interested, is to ensure that all calls go through the New and
   Renew macros.
	--Andy Dougherty		August 1996
*/

#ifndef lint

#define NEWSV(x,len)	newSV(len)

#ifndef LEAKTEST

#define New(x,v,n,t)	(v = (t*)safemalloc((MEM_SIZE)((n)*sizeof(t))))
#define Newc(x,v,n,t,c)	(v = (c*)safemalloc((MEM_SIZE)((n)*sizeof(t))))
#define Newz(x,v,n,t)	(v = (t*)safemalloc((MEM_SIZE)((n)*sizeof(t)))), \
			memzero((char*)(v), (n)*sizeof(t))
#define Renew(v,n,t) \
	  (v = (t*)saferealloc((Malloc_t)(v),(MEM_SIZE)((n)*sizeof(t))))
#define Renewc(v,n,t,c) \
	  (v = (c*)saferealloc((Malloc_t)(v),(MEM_SIZE)((n)*sizeof(t))))
#define Safefree(d)	safefree((Malloc_t)(d))

#else /* LEAKTEST */

#define New(x,v,n,t)	(v = (t*)safexmalloc((x),(MEM_SIZE)((n)*sizeof(t))))
#define Newc(x,v,n,t,c)	(v = (c*)safexmalloc((x),(MEM_SIZE)((n)*sizeof(t))))
#define Newz(x,v,n,t)	(v = (t*)safexmalloc((x),(MEM_SIZE)((n)*sizeof(t)))), \
			 memzero((char*)(v), (n)*sizeof(t))
#define Renew(v,n,t) \
	  (v = (t*)safexrealloc((Malloc_t)(v),(MEM_SIZE)((n)*sizeof(t))))
#define Renewc(v,n,t,c) \
	  (v = (c*)safexrealloc((Malloc_t)(v),(MEM_SIZE)((n)*sizeof(t))))
#define Safefree(d)	safexfree((Malloc_t)(d))

#define MAXXCOUNT 1400
#define MAXY_SIZE 80
#define MAXYCOUNT 16			/* (MAXY_SIZE/4 + 1) */
extern long xcount[MAXXCOUNT];
extern long lastxcount[MAXXCOUNT];
extern long xycount[MAXXCOUNT][MAXYCOUNT];
extern long lastxycount[MAXXCOUNT][MAXYCOUNT];

#endif /* LEAKTEST */

#define Move(s,d,n,t)	(void)memmove((char*)(d),(char*)(s), (n) * sizeof(t))
#define Copy(s,d,n,t)	(void)memcpy((char*)(d),(char*)(s), (n) * sizeof(t))
#define Zero(d,n,t)	(void)memzero((char*)(d), (n) * sizeof(t))

#else /* lint */

#define New(x,v,n,s)	(v = Null(s *))
#define Newc(x,v,n,s,c)	(v = Null(s *))
#define Newz(x,v,n,s)	(v = Null(s *))
#define Renew(v,n,s)	(v = Null(s *))
#define Move(s,d,n,t)
#define Copy(s,d,n,t)
#define Zero(d,n,t)
#define Safefree(d)	(d) = (d)

#endif /* lint */

#ifdef USE_STRUCT_COPY
#define StructCopy(s,d,t) (*((t*)(d)) = *((t*)(s)))
#else
#define StructCopy(s,d,t) Copy(s,d,1,t)
#endif
