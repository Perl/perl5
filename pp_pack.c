/*    pp_pack.c
 *
 *    Copyright (C) 1991, 1992, 1993, 1994, 1995, 1996, 1997, 1998, 1999,
 *    2000, 2001, 2002, 2003, 2004, 2005, by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

/*
 * He still hopefully carried some of his gear in his pack: a small tinder-box,
 * two small shallow pans, the smaller fitting into the larger; inside them a
 * wooden spoon, a short two-pronged fork and some skewers were stowed; and
 * hidden at the bottom of the pack in a flat wooden box a dwindling treasure,
 * some salt.
 */

/* This file contains pp ("push/pop") functions that
 * execute the opcodes that make up a perl program. A typical pp function
 * expects to find its arguments on the stack, and usually pushes its
 * results onto the stack, hence the 'pp' terminology. Each OP structure
 * contains a pointer to the relevant pp_foo() function.
 *
 * This particular file just contains pp_pack() and pp_unpack(). See the
 * other pp*.c files for the rest of the pp_ functions.
 */


#include "EXTERN.h"
#define PERL_IN_PP_PACK_C
#include "perl.h"

#if PERL_VERSION >= 9
#define PERL_PACK_CAN_BYTEORDER
#define PERL_PACK_CAN_SHRIEKSIGN
#endif

/*
 * Offset for integer pack/unpack.
 *
 * On architectures where I16 and I32 aren't really 16 and 32 bits,
 * which for now are all Crays, pack and unpack have to play games.
 */

/*
 * These values are required for portability of pack() output.
 * If they're not right on your machine, then pack() and unpack()
 * wouldn't work right anyway; you'll need to apply the Cray hack.
 * (I'd like to check them with #if, but you can't use sizeof() in
 * the preprocessor.)  --???
 */
/*
    The appropriate SHORTSIZE, INTSIZE, LONGSIZE, and LONGLONGSIZE
    defines are now in config.h.  --Andy Dougherty  April 1998
 */
#define SIZE16 2
#define SIZE32 4

/* CROSSCOMPILE and MULTIARCH are going to affect pp_pack() and pp_unpack().
   --jhi Feb 1999 */

#if U16SIZE > SIZE16 || U32SIZE > SIZE32
#  if BYTEORDER == 0x1234 || BYTEORDER == 0x12345678    /* little-endian */
#    define OFF16(p)	((char*)(p))
#    define OFF32(p)	((char*)(p))
#  else
#    if BYTEORDER == 0x4321 || BYTEORDER == 0x87654321  /* big-endian */
#      define OFF16(p)	((char*)(p) + (sizeof(U16) - SIZE16))
#      define OFF32(p)	((char*)(p) + (sizeof(U32) - SIZE32))
#    else
       ++++ bad cray byte order
#    endif
#  endif
#else
#  define OFF16(p)     ((char *) (p))
#  define OFF32(p)     ((char *) (p))
#endif

#define COPY16(s,p)  Copy(s, OFF16(p), SIZE16, char)
#define COPY32(s,p)  Copy(s, OFF32(p), SIZE32, char)
#define CAT16(sv,p)  sv_catpvn(sv, OFF16(p), SIZE16)
#define CAT32(sv,p)  sv_catpvn(sv, OFF32(p), SIZE32)

/* Only to be used inside a loop (see the break) */
#define COPYVAR(s,strend,utf8,var,format)		\
STMT_START {						\
    if (utf8) {						\
        if (!next_uni_bytes(aTHX_ &s, strend,		\
            (char *) &var, sizeof(var))) break;		\
    } else {						\
        Copy(s, (char *) &var, sizeof(var), char);	\
        s += sizeof(var);				\
    }							\
    DO_BO_UNPACK(var, format);				\
} STMT_END

/* Avoid stack overflow due to pathological templates. 100 should be plenty. */
#define MAX_SUB_TEMPLATE_LEVEL 100

/* flags (note that type modifiers can also be used as flags!) */
#define FLAG_UNPACK_WAS_UTF8    0x40	/* original had FLAG_UNPACK_DO_UTF8 */
#define FLAG_UNPACK_PARSE_UTF8  0x20	/* Parse as utf8 */
#define FLAG_UNPACK_ONLY_ONE  0x10
#define FLAG_UNPACK_DO_UTF8     0x08	/* The underlying string is utf8 */
#define FLAG_SLASH            0x04
#define FLAG_COMMA            0x02
#define FLAG_PACK             0x01

STATIC SV *
S_mul128(pTHX_ SV *sv, U8 m)
{
  STRLEN          len;
  char           *s = SvPV(sv, len);
  char           *t;
  U32             i = 0;

  if (!strnEQ(s, "0000", 4)) {  /* need to grow sv */
    SV             *tmpNew = newSVpvn("0000000000", 10);

    sv_catsv(tmpNew, sv);
    SvREFCNT_dec(sv);		/* free old sv */
    sv = tmpNew;
    s = SvPV(sv, len);
  }
  t = s + len - 1;
  while (!*t)                   /* trailing '\0'? */
    t--;
  while (t > s) {
    i = ((*t - '0') << 7) + m;
    *(t--) = '0' + (char)(i % 10);
    m = (char)(i / 10);
  }
  return (sv);
}

/* Explosives and implosives. */

#if 'I' == 73 && 'J' == 74
/* On an ASCII/ISO kind of system */
#define ISUUCHAR(ch)    ((ch) >= ' ' && (ch) < 'a')
#else
/*
  Some other sort of character set - use memchr() so we don't match
  the null byte.
 */
#define ISUUCHAR(ch)    (memchr(PL_uuemap, (ch), sizeof(PL_uuemap)-1) || (ch) == ' ')
#endif

/* type modifiers */
#define TYPE_IS_SHRIEKING	0x100
#define TYPE_IS_BIG_ENDIAN	0x200
#define TYPE_IS_LITTLE_ENDIAN	0x400
#define TYPE_ENDIANNESS_MASK	(TYPE_IS_BIG_ENDIAN|TYPE_IS_LITTLE_ENDIAN)
#define TYPE_MODIFIERS(t)	((t) & ~0xFF)
#define TYPE_NO_MODIFIERS(t)	((t) & 0xFF)

#ifdef PERL_PACK_CAN_SHRIEKSIGN
#define SHRIEKING_ALLOWED_TYPES "sSiIlLxXnNvV"
#else
#define SHRIEKING_ALLOWED_TYPES "sSiIlLxX"
#endif

#ifndef PERL_PACK_CAN_BYTEORDER
/* Put "can't" first because it is shorter  */
# define TYPE_ENDIANNESS(t)	0
# define TYPE_NO_ENDIANNESS(t)	(t)

# define ENDIANNESS_ALLOWED_TYPES   ""

# define DO_BO_UNPACK(var, type)
# define DO_BO_PACK(var, type)
# define DO_BO_UNPACK_PTR(var, type, pre_cast)
# define DO_BO_PACK_PTR(var, type, pre_cast)
# define DO_BO_UNPACK_N(var, type)
# define DO_BO_PACK_N(var, type)
# define DO_BO_UNPACK_P(var)
# define DO_BO_PACK_P(var)

#else

# define TYPE_ENDIANNESS(t)	((t) & TYPE_ENDIANNESS_MASK)
# define TYPE_NO_ENDIANNESS(t)	((t) & ~TYPE_ENDIANNESS_MASK)

# define ENDIANNESS_ALLOWED_TYPES   "sSiIlLqQjJfFdDpP("

# define DO_BO_UNPACK(var, type)                                              \
        STMT_START {                                                          \
          switch (TYPE_ENDIANNESS(datumtype)) {                               \
            case TYPE_IS_BIG_ENDIAN:    var = my_betoh ## type (var); break;  \
            case TYPE_IS_LITTLE_ENDIAN: var = my_letoh ## type (var); break;  \
            default: break;                                                   \
          }                                                                   \
        } STMT_END

# define DO_BO_PACK(var, type)                                                \
        STMT_START {                                                          \
          switch (TYPE_ENDIANNESS(datumtype)) {                               \
            case TYPE_IS_BIG_ENDIAN:    var = my_htobe ## type (var); break;  \
            case TYPE_IS_LITTLE_ENDIAN: var = my_htole ## type (var); break;  \
            default: break;                                                   \
          }                                                                   \
        } STMT_END

# define DO_BO_UNPACK_PTR(var, type, pre_cast)                                \
        STMT_START {                                                          \
          switch (TYPE_ENDIANNESS(datumtype)) {                               \
            case TYPE_IS_BIG_ENDIAN:                                          \
              var = (void *) my_betoh ## type ((pre_cast) var);               \
              break;                                                          \
            case TYPE_IS_LITTLE_ENDIAN:                                       \
              var = (void *) my_letoh ## type ((pre_cast) var);               \
              break;                                                          \
            default:                                                          \
              break;                                                          \
          }                                                                   \
        } STMT_END

# define DO_BO_PACK_PTR(var, type, pre_cast)                                  \
        STMT_START {                                                          \
          switch (TYPE_ENDIANNESS(datumtype)) {                               \
            case TYPE_IS_BIG_ENDIAN:                                          \
              var = (void *) my_htobe ## type ((pre_cast) var);               \
              break;                                                          \
            case TYPE_IS_LITTLE_ENDIAN:                                       \
              var = (void *) my_htole ## type ((pre_cast) var);               \
              break;                                                          \
            default:                                                          \
              break;                                                          \
          }                                                                   \
        } STMT_END

# define BO_CANT_DOIT(action, type)                                           \
        STMT_START {                                                          \
          switch (TYPE_ENDIANNESS(datumtype)) {                               \
             case TYPE_IS_BIG_ENDIAN:                                         \
               Perl_croak(aTHX_ "Can't %s big-endian %ss on this "            \
                                "platform", #action, #type);                  \
               break;                                                         \
             case TYPE_IS_LITTLE_ENDIAN:                                      \
               Perl_croak(aTHX_ "Can't %s little-endian %ss on this "         \
                                "platform", #action, #type);                  \
               break;                                                         \
             default:                                                         \
               break;                                                         \
           }                                                                  \
         } STMT_END

# if PTRSIZE == INTSIZE
#  define DO_BO_UNPACK_P(var)	DO_BO_UNPACK_PTR(var, i, int)
#  define DO_BO_PACK_P(var)	DO_BO_PACK_PTR(var, i, int)
# elif PTRSIZE == LONGSIZE
#  define DO_BO_UNPACK_P(var)	DO_BO_UNPACK_PTR(var, l, long)
#  define DO_BO_PACK_P(var)	DO_BO_PACK_PTR(var, l, long)
# else
#  define DO_BO_UNPACK_P(var)	BO_CANT_DOIT(unpack, pointer)
#  define DO_BO_PACK_P(var)	BO_CANT_DOIT(pack, pointer)
# endif

# if defined(my_htolen) && defined(my_letohn) && \
    defined(my_htoben) && defined(my_betohn)
#  define DO_BO_UNPACK_N(var, type)                                           \
         STMT_START {                                                         \
           switch (TYPE_ENDIANNESS(datumtype)) {                              \
             case TYPE_IS_BIG_ENDIAN:    my_betohn(&var, sizeof(type)); break;\
             case TYPE_IS_LITTLE_ENDIAN: my_letohn(&var, sizeof(type)); break;\
             default: break;                                                  \
           }                                                                  \
         } STMT_END

#  define DO_BO_PACK_N(var, type)                                             \
         STMT_START {                                                         \
           switch (TYPE_ENDIANNESS(datumtype)) {                              \
             case TYPE_IS_BIG_ENDIAN:    my_htoben(&var, sizeof(type)); break;\
             case TYPE_IS_LITTLE_ENDIAN: my_htolen(&var, sizeof(type)); break;\
             default: break;                                                  \
           }                                                                  \
         } STMT_END
# else
#  define DO_BO_UNPACK_N(var, type)	BO_CANT_DOIT(unpack, type)
#  define DO_BO_PACK_N(var, type)	BO_CANT_DOIT(pack, type)
# endif

#endif

#define PACK_SIZE_CANNOT_CSUM		0x80
#define PACK_SIZE_SPARE			0x40
#define PACK_SIZE_MASK			0x3F


struct packsize_t {
    const unsigned char *array;
    int first;
    int size;
};

#define PACK_SIZE_NORMAL 0
#define PACK_SIZE_SHRIEKING 1

/* These tables are regenerated by genpacksizetables.pl (and then hand pasted
   in).  You're unlikely ever to need to regenerate them.  */
#if 'J'-'I' == 1
/* ASCII */
unsigned char size_normal[53] = {
  /* C */ sizeof(unsigned char),
#if defined(HAS_LONG_DOUBLE) && defined(USE_LONG_DOUBLE)
  /* D */ LONG_DOUBLESIZE,
#else
  0,
#endif
  0,
  /* F */ NVSIZE,
  0, 0,
  /* I */ sizeof(unsigned int),
  /* J */ UVSIZE,
  0,
  /* L */ SIZE32,
  0,
  /* N */ SIZE32,
  0, 0,
#if defined(HAS_QUAD)
  /* Q */ sizeof(Uquad_t),
#else
  0,
#endif
  0,
  /* S */ SIZE16,
  0,
  /* U */ sizeof(char),
  /* V */ SIZE32,
  /* W */ sizeof(unsigned char),
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  /* c */ sizeof(char),
  /* d */ sizeof(double),
  0,
  /* f */ sizeof(float),
  0, 0,
  /* i */ sizeof(int),
  /* j */ IVSIZE,
  0,
  /* l */ SIZE32,
  0,
  /* n */ SIZE16,
  0,
  /* p */ sizeof(char *) | PACK_SIZE_CANNOT_CSUM,
#if defined(HAS_QUAD)
  /* q */ sizeof(Quad_t),
#else
  0,
#endif
  0,
  /* s */ SIZE16,
  0, 0,
  /* v */ SIZE16,
  /* w */ sizeof(char) | PACK_SIZE_CANNOT_CSUM,
};
unsigned char size_shrieking[46] = {
  /* I */ sizeof(unsigned int),
  0, 0,
  /* L */ sizeof(unsigned long),
  0,
#if defined(PERL_PACK_CAN_SHRIEKSIGN)
  /* N */ SIZE32,
#else
  0,
#endif
  0, 0, 0, 0,
  /* S */ sizeof(unsigned short),
  0, 0,
#if defined(PERL_PACK_CAN_SHRIEKSIGN)
  /* V */ SIZE32,
#else
  0,
#endif
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  /* i */ sizeof(int),
  0, 0,
  /* l */ sizeof(long),
  0,
#if defined(PERL_PACK_CAN_SHRIEKSIGN)
  /* n */ SIZE16,
#else
  0,
#endif
  0, 0, 0, 0,
  /* s */ sizeof(short),
  0, 0,
#if defined(PERL_PACK_CAN_SHRIEKSIGN)
  /* v */ SIZE16
#else
  0
#endif
};
struct packsize_t packsize[2] = {
  {size_normal, 67, 53},
  {size_shrieking, 73, 46}
};
#else
/* EBCDIC (or bust) */
unsigned char size_normal[100] = {
  /* c */ sizeof(char),
  /* d */ sizeof(double),
  0,
  /* f */ sizeof(float),
  0, 0,
  /* i */ sizeof(int),
  0, 0, 0, 0, 0, 0, 0,
  /* j */ IVSIZE,
  0,
  /* l */ SIZE32,
  0,
  /* n */ SIZE16,
  0,
  /* p */ sizeof(char *) | PACK_SIZE_CANNOT_CSUM,
#if defined(HAS_QUAD)
  /* q */ sizeof(Quad_t),
#else
  0,
#endif
  0, 0, 0, 0, 0, 0, 0, 0, 0,
  /* s */ SIZE16,
  0, 0,
  /* v */ SIZE16,
  /* w */ sizeof(char) | PACK_SIZE_CANNOT_CSUM,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0,
  /* C */ sizeof(unsigned char),
#if defined(HAS_LONG_DOUBLE) && defined(USE_LONG_DOUBLE)
  /* D */ LONG_DOUBLESIZE,
#else
  0,
#endif
  0,
  /* F */ NVSIZE,
  0, 0,
  /* I */ sizeof(unsigned int),
  0, 0, 0, 0, 0, 0, 0,
  /* J */ UVSIZE,
  0,
  /* L */ SIZE32,
  0,
  /* N */ SIZE32,
  0, 0,
#if defined(HAS_QUAD)
  /* Q */ sizeof(Uquad_t),
#else
  0,
#endif
  0, 0, 0, 0, 0, 0, 0, 0, 0,
  /* S */ SIZE16,
  0,
  /* U */ sizeof(char),
  /* V */ SIZE32,
  /* W */ sizeof(unsigned char),
};
unsigned char size_shrieking[93] = {
  /* i */ sizeof(int),
  0, 0, 0, 0, 0, 0, 0, 0, 0,
  /* l */ sizeof(long),
  0,
#if defined(PERL_PACK_CAN_SHRIEKSIGN)
  /* n */ SIZE16,
#else
  0,
#endif
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  /* s */ sizeof(short),
  0, 0,
#if defined(PERL_PACK_CAN_SHRIEKSIGN)
  /* v */ SIZE16,
#else
  0,
#endif
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0,
  /* I */ sizeof(unsigned int),
  0, 0, 0, 0, 0, 0, 0, 0, 0,
  /* L */ sizeof(unsigned long),
  0,
#if defined(PERL_PACK_CAN_SHRIEKSIGN)
  /* N */ SIZE32,
#else
  0,
#endif
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  /* S */ sizeof(unsigned short),
  0, 0,
#if defined(PERL_PACK_CAN_SHRIEKSIGN)
  /* V */ SIZE32
#else
  0
#endif
};
struct packsize_t packsize[2] = {
  {size_normal, 131, 100},
  {size_shrieking, 137, 93}
};
#endif

STATIC U8
next_uni_byte(pTHX_ char **s, const char *end, I32 datumtype)
{
    UV val;
    STRLEN retlen;
    val =
	UNI_TO_NATIVE(utf8n_to_uvuni((U8*)*s, end-*s, &retlen,
				     ckWARN(WARN_UTF8) ? 0 : UTF8_ALLOW_ANY));
    /* We try to process malformed UTF-8 as much as possible (preferrably with
       warnings), but these two mean we make no progress in the string and
       might enter an infinite loop */
    if (retlen == (STRLEN) -1 || retlen == 0)
	Perl_croak(aTHX_ "Malformed UTF-8 string in unpack");
    if (val >= 0x100) {
	Perl_warner(aTHX_ packWARN(WARN_UNPACK),
		    "Character in '%c' format wrapped in unpack",
		    (int) datumtype);
	val &= 0xff;
    }
    *s += retlen;
    return val;
}

#define NEXT_BYTE(utf8, s, strend, datumtype) ((utf8) ? \
	next_uni_byte(aTHX_ &(s), (strend), (datumtype)) : \
	*(U8 *)(s)++)

STATIC bool
next_uni_bytes(pTHX_ char **s, char *end, char *buf, int buf_len)
{
    UV val;
    STRLEN retlen;
    char *from = *s;
    int bad = 0;
    U32 flags = ckWARN(WARN_UTF8) ?
	UTF8_CHECK_ONLY : (UTF8_CHECK_ONLY | UTF8_ALLOW_ANY);
    for (;buf_len > 0; buf_len--) {
	if (from >= end) return FALSE;
	val = UNI_TO_NATIVE(utf8n_to_uvuni((U8*)from, end-from, &retlen, flags));
	if (retlen == (STRLEN) -1 || retlen == 0) {
	    from += UTF8SKIP(from);
	    bad |= 1;
	} else from += retlen;
	if (val >= 0x100) {
	    bad |= 2;
	    val &= 0xff;
	}
	*(U8 *)buf++ = val;
    }
    /* We have enough characters for the buffer. Did we have problems ? */
    if (bad) {
	if (bad & 1) {
	    /* Rewalk the string fragment while warning */
	    char *ptr;
	    flags = ckWARN(WARN_UTF8) ? 0 : UTF8_ALLOW_ANY;
	    for (ptr = *s; ptr < from; ptr += UTF8SKIP(ptr)) {
		if (ptr >= end) break;
		utf8n_to_uvuni((U8*)ptr, end-ptr, &retlen, flags);
	    }
	    if (from > end) from = end;
	}
	if ((bad & 2) && ckWARN(WARN_UNPACK))
	    Perl_warner(aTHX_ packWARN(WARN_UNPACK),
			"Character(s) wrapped in unpack");
    }
    *s = from;
    return TRUE;
}

STATIC bool
next_uni_uu(pTHX_ char **s, const char *end, I32 *out)
{
    UV val;
    STRLEN retlen;
    char *from = *s;
    val = UNI_TO_NATIVE(utf8n_to_uvuni((U8*)*s, end-*s, &retlen, UTF8_CHECK_ONLY));
    if (val >= 0x100 || !ISUUCHAR(val) ||
	retlen == (STRLEN) -1 || retlen == 0) {
	*out = 0;
	return FALSE;
    }
    *out = PL_uudmap[val] & 077;
    *s = from;
    return TRUE;
}

/* Returns the sizeof() struct described by pat */
STATIC I32
S_measure_struct(pTHX_ register tempsym_t* symptr)
{
    register I32 len = 0;
    register I32 total = 0;
    int star;

    register int size;

    while (next_symbol(symptr)) {
	int which = (symptr->code & TYPE_IS_SHRIEKING)
	    ? PACK_SIZE_SHRIEKING : PACK_SIZE_NORMAL;
	int offset
	    = TYPE_NO_MODIFIERS(symptr->code) - packsize[which].first;

        switch( symptr->howlen ){
        case e_no_len:
	case e_number:
	    len = symptr->length;
	    break;
        case e_star:
   	    Perl_croak(aTHX_ "Within []-length '*' not allowed in %s",
                       symptr->flags & FLAG_PACK ? "pack" : "unpack" );
            break;
        }

	if ((offset >= 0) && (offset < packsize[which].size))
	    size = packsize[which].array[offset] & PACK_SIZE_MASK;
	else
	    size = 0;

	if (!size) {
	    /* endianness doesn't influence the size of a type */
	    switch(TYPE_NO_ENDIANNESS(symptr->code)) {
	    default:
		Perl_croak(aTHX_ "Invalid type '%c' in %s",
			   (int)TYPE_NO_MODIFIERS(symptr->code),
			   symptr->flags & FLAG_PACK ? "pack" : "unpack" );
	    case '@':
	    case '/':
	    case 'U':			/* XXXX Is it correct? */
	    case 'w':
	    case 'u':
		Perl_croak(aTHX_ "Within []-length '%c' not allowed in %s",
			   (int)symptr->code,
			   symptr->flags & FLAG_PACK ? "pack" : "unpack" );
	    case '%':
		size = 0;
		break;
	    case '(':
		{
		    tempsym_t savsym = *symptr;
		    symptr->patptr = savsym.grpbeg;
		    symptr->patend = savsym.grpend;
		    /* XXXX Theoretically, we need to measure many times at
		       different positions, since the subexpression may contain
		       alignment commands, but be not of aligned length.
		       Need to detect this and croak().  */
		    size = measure_struct(symptr);
		    *symptr = savsym;
		    break;
		}
	    case 'X' | TYPE_IS_SHRIEKING:
		/* XXXX Is this useful?  Then need to treat MEASURE_BACKWARDS.
		 */
		if (!len)		/* Avoid division by 0 */
		    len = 1;
		len = total % len;	/* Assumed: the start is aligned. */
		/* FALL THROUGH */
	    case 'X':
		size = -1;
		if (total < len)
		    Perl_croak(aTHX_ "'X' outside of string in %s",
			       symptr->flags & FLAG_PACK ? "pack" : "unpack" );
		break;
	    case 'x' | TYPE_IS_SHRIEKING:
		if (!len)		/* Avoid division by 0 */
		    len = 1;
		star = total % len;	/* Assumed: the start is aligned. */
		if (star)		/* Other portable ways? */
		    len = len - star;
		else
		    len = 0;
		/* FALL THROUGH */
	    case 'x':
	    case 'A':
	    case 'Z':
	    case 'a':
		size = 1;
		break;
	    case 'B':
	    case 'b':
		len = (len + 7)/8;
		size = 1;
		break;
	    case 'H':
	    case 'h':
		len = (len + 1)/2;
		size = 1;
		break;

	    case 'P':
		len = 1;
		size = sizeof(char*);
		break;
	    }
	}
	total += len * size;
    }
    return total;
}


/* locate matching closing parenthesis or bracket
 * returns char pointer to char after match, or NULL
 */
STATIC char *
S_group_end(pTHX_ register char *patptr, register char *patend, char ender)
{
    while (patptr < patend) {
	char c = *patptr++;

	if (isSPACE(c))
	    continue;
	else if (c == ender)
	    return patptr-1;
	else if (c == '#') {
	    while (patptr < patend && *patptr != '\n')
		patptr++;
	    continue;
	} else if (c == '(')
	    patptr = group_end(patptr, patend, ')') + 1;
	else if (c == '[')
	    patptr = group_end(patptr, patend, ']') + 1;
    }
    Perl_croak(aTHX_ "No group ending character '%c' found in template",
               ender);
    return 0;
}


/* Convert unsigned decimal number to binary.
 * Expects a pointer to the first digit and address of length variable
 * Advances char pointer to 1st non-digit char and returns number
 */ 
STATIC char *
S_get_num(pTHX_ register char *patptr, I32 *lenptr )
{
  I32 len = *patptr++ - '0';
  while (isDIGIT(*patptr)) {
    if (len >= 0x7FFFFFFF/10)
      Perl_croak(aTHX_ "pack/unpack repeat count overflow");
    len = (len * 10) + (*patptr++ - '0');
  }
  *lenptr = len;
  return patptr;
}

/* The marvellous template parsing routine: Using state stored in *symptr,
 * locates next template code and count
 */
STATIC bool
S_next_symbol(pTHX_ register tempsym_t* symptr )
{
  register char* patptr = symptr->patptr; 
  register char* patend = symptr->patend; 

  symptr->flags &= ~FLAG_SLASH;

  while (patptr < patend) {
    if (isSPACE(*patptr))
      patptr++;
    else if (*patptr == '#') {
      patptr++;
      while (patptr < patend && *patptr != '\n')
	patptr++;
      if (patptr < patend)
	patptr++;
    } else {
      /* We should have found a template code */ 
      I32 code = *patptr++ & 0xFF;
      U32 inherited_modifiers = 0;

      if (code == ','){ /* grandfather in commas but with a warning */
	if (((symptr->flags & FLAG_COMMA) == 0) && ckWARN(WARN_UNPACK)){
          symptr->flags |= FLAG_COMMA;
	  Perl_warner(aTHX_ packWARN(WARN_UNPACK),
	 	      "Invalid type ',' in %s",
                      symptr->flags & FLAG_PACK ? "pack" : "unpack" );
        }
	continue;
      }
      
      /* for '(', skip to ')' */
      if (code == '(') {  
        if( isDIGIT(*patptr) || *patptr == '*' || *patptr == '[' )
          Perl_croak(aTHX_ "()-group starts with a count in %s",
                     symptr->flags & FLAG_PACK ? "pack" : "unpack" );
        symptr->grpbeg = patptr;
        patptr = 1 + ( symptr->grpend = group_end(patptr, patend, ')') );
        if( symptr->level >= MAX_SUB_TEMPLATE_LEVEL )
	  Perl_croak(aTHX_ "Too deeply nested ()-groups in %s",
                     symptr->flags & FLAG_PACK ? "pack" : "unpack" );
      }

      /* look for group modifiers to inherit */
      if (TYPE_ENDIANNESS(symptr->flags)) {
        if (strchr(ENDIANNESS_ALLOWED_TYPES, TYPE_NO_MODIFIERS(code)))
          inherited_modifiers |= TYPE_ENDIANNESS(symptr->flags);
      }

      /* look for modifiers */
      while (patptr < patend) {
        const char *allowed;
        I32 modifier = 0;
        switch (*patptr) {
          case '!':
            modifier = TYPE_IS_SHRIEKING;
            allowed = SHRIEKING_ALLOWED_TYPES;
            break;
#ifdef PERL_PACK_CAN_BYTEORDER
          case '>':
            modifier = TYPE_IS_BIG_ENDIAN;
            allowed = ENDIANNESS_ALLOWED_TYPES;
            break;
          case '<':
            modifier = TYPE_IS_LITTLE_ENDIAN;
            allowed = ENDIANNESS_ALLOWED_TYPES;
            break;
#endif
          default:
            break;
        }

        if (modifier == 0)
          break;

        if (!strchr(allowed, TYPE_NO_MODIFIERS(code)))
          Perl_croak(aTHX_ "'%c' allowed only after types %s in %s", *patptr,
                     allowed, symptr->flags & FLAG_PACK ? "pack" : "unpack" );

        if (TYPE_ENDIANNESS(code | modifier) == TYPE_ENDIANNESS_MASK)
          Perl_croak(aTHX_ "Can't use both '<' and '>' after type '%c' in %s",
                     (int) TYPE_NO_MODIFIERS(code),
                     symptr->flags & FLAG_PACK ? "pack" : "unpack" );
        else if (TYPE_ENDIANNESS(code | modifier | inherited_modifiers) ==
                 TYPE_ENDIANNESS_MASK)
          Perl_croak(aTHX_ "Can't use '%c' in a group with different byte-order in %s",
                     *patptr, symptr->flags & FLAG_PACK ? "pack" : "unpack" );

        if (ckWARN(WARN_UNPACK)) {
          if (code & modifier)
	    Perl_warner(aTHX_ packWARN(WARN_UNPACK),
                        "Duplicate modifier '%c' after '%c' in %s",
                        *patptr, (int) TYPE_NO_MODIFIERS(code),
                        symptr->flags & FLAG_PACK ? "pack" : "unpack" );
        }

        code |= modifier;
        patptr++;
      }

      /* inherit modifiers */
      code |= inherited_modifiers;

      /* look for count and/or / */ 
      if (patptr < patend) {
	if (isDIGIT(*patptr)) {
 	  patptr = get_num( patptr, &symptr->length );
          symptr->howlen = e_number;

        } else if (*patptr == '*') {
          patptr++;
          symptr->howlen = e_star;

        } else if (*patptr == '[') {
          char* lenptr = ++patptr;            
          symptr->howlen = e_number;
          patptr = group_end( patptr, patend, ']' ) + 1;
          /* what kind of [] is it? */
          if (isDIGIT(*lenptr)) {
            lenptr = get_num( lenptr, &symptr->length );
            if( *lenptr != ']' )
              Perl_croak(aTHX_ "Malformed integer in [] in %s",
                         symptr->flags & FLAG_PACK ? "pack" : "unpack");
          } else {
            tempsym_t savsym = *symptr;
            symptr->patend = patptr-1;
            symptr->patptr = lenptr;
            savsym.length = measure_struct(symptr);
            *symptr = savsym;
          }
        } else {
          symptr->howlen = e_no_len;
          symptr->length = 1;
        }

        /* try to find / */
        while (patptr < patend) {
          if (isSPACE(*patptr))
            patptr++;
          else if (*patptr == '#') {
            patptr++;
            while (patptr < patend && *patptr != '\n')
	      patptr++;
            if (patptr < patend)
	      patptr++;
          } else {
            if (*patptr == '/') {
              symptr->flags |= FLAG_SLASH;
              patptr++;
              if (patptr < patend &&
                  (isDIGIT(*patptr) || *patptr == '*' || *patptr == '['))
                Perl_croak(aTHX_ "'/' does not take a repeat count in %s",
                           symptr->flags & FLAG_PACK ? "pack" : "unpack" );
            }
            break;
	  }
	}
      } else {
        /* at end - no count, no / */
        symptr->howlen = e_no_len;
        symptr->length = 1;
      }

      symptr->code = code;
      symptr->patptr = patptr; 
      return TRUE;
    }
  }
  symptr->patptr = patptr; 
  return FALSE;
}

/*
   There is no way to cleanly handle the case where we should process the 
   string per byte in its upgraded form while it's really in downgraded form
   (e.g. estimates like strend-s as an upper bound for the number of 
   characters left wouldn't work). So if we foresee the need of this 
   (pattern starts with U or contains U0), we want to work on the encoded 
   version of the string. Users are advised to upgrade their pack string 
   themselves if they need to do a lot of unpacks like this on it
*/
STATIC bool 
need_utf8(const char *pat, const char *patend)
{
    bool first = TRUE;
    while (pat < patend) {
	if (pat[0] == '#') {
	    pat++;
	    pat = memchr(pat, '\n', patend-pat);
	    if (!pat) return FALSE;
	} else if (pat[0] == 'U') {
	    if (first || pat[1] == '0') return TRUE;
	} else first = FALSE;
	pat++;
    }
    return FALSE;
}

STATIC char
first_symbol(const char *pat, const char *patend) {
    while (pat < patend) {
	if (pat[0] != '#') return pat[0];
	pat++;
	pat = memchr(pat, '\n', patend-pat);
	if (!pat) return 0;
	pat++;
    }
    return 0;
}

/*
=for apidoc unpack_str

The engine implementing unpack() Perl function. Note: parameters strbeg, new_s
and ocnt are not used. This call should not be used, use unpackstring instead.

=cut */

I32
Perl_unpack_str(pTHX_ char *pat, register char *patend, register char *s, char *strbeg, char *strend, char **new_s, I32 ocnt, U32 flags)
{
    tempsym_t sym = { 0 };

    if (flags & FLAG_UNPACK_DO_UTF8) flags |= FLAG_UNPACK_WAS_UTF8;
    else if (need_utf8(pat, patend)) {
	/* We probably should try to avoid this in case a scalar context call
	   wouldn't get to the "U0" */
	STRLEN len = strend - s;
	s = (char*)bytes_to_utf8((U8*)s, &len);
	SAVEFREEPV(s);
	strend = s + len;
	flags |= FLAG_UNPACK_DO_UTF8;
    }

    if (first_symbol(pat, patend) != 'U' && (flags & FLAG_UNPACK_DO_UTF8))
	flags |= FLAG_UNPACK_PARSE_UTF8;

    sym.patptr = pat;
    sym.patend = patend;
    sym.flags  = flags;

    return unpack_rec(&sym, s, s, strend, NULL );
}

/*
=for apidoc unpackstring

The engine implementing unpack() Perl function. C<unpackstring> puts the
extracted list items on the stack and returns the number of elements.
Issue C<PUTBACK> before and C<SPAGAIN> after the call to this function.

=cut */

I32
Perl_unpackstring(pTHX_ char *pat, register char *patend, register char *s, char *strend, U32 flags)
{
    tempsym_t sym = { 0 };

    if (flags & FLAG_UNPACK_DO_UTF8) flags |= FLAG_UNPACK_WAS_UTF8;
    else if (need_utf8(pat, patend)) {
	/* We probably should try to avoid this in case a scalar context call
	   wouldn't get to the "U0" */
	STRLEN len = strend - s;
	s = (char*)bytes_to_utf8((U8*)s, &len);
	SAVEFREEPV(s);
	strend = s + len;
	flags |= FLAG_UNPACK_DO_UTF8;
    }

    if (first_symbol(pat, patend) != 'U' && (flags & FLAG_UNPACK_DO_UTF8))
	flags |= FLAG_UNPACK_PARSE_UTF8;

    sym.patptr = pat;
    sym.patend = patend;
    sym.flags  = flags;

    return unpack_rec(&sym, s, s, strend, NULL );
}

STATIC
I32
S_unpack_rec(pTHX_ tempsym_t* symptr, char *s, char *strbeg, char *strend, char **new_s )
{
    dSP;
    I32 datumtype, ai32;
    I32 len = 0;
    SV *sv;
    I32 start_sp_offset = SP - PL_stack_base;
    howlen_t howlen;

    I32 checksum = 0;
    UV cuv = 0;
    NV cdouble = 0.0;
    const int bits_in_uv = 8 * sizeof(cuv);
    char* strrelbeg = s;
    bool beyond = FALSE;
    bool explicit_length;
    bool unpack_only_one = (symptr->flags & FLAG_UNPACK_ONLY_ONE) != 0;
    bool utf8 = (symptr->flags & FLAG_UNPACK_PARSE_UTF8) ? 1 : 0;

    while (next_symbol(symptr)) {
        datumtype = symptr->code;
	/* do first one only unless in list context
	   / is implemented by unpacking the count, then popping it from the
	   stack, so must check that we're not in the middle of a /  */
        if ( unpack_only_one
	     && (SP - PL_stack_base == start_sp_offset + 1)
	     && (datumtype != '/') )   /* XXX can this be omitted */
            break;

        switch( howlen = symptr->howlen ){
        case e_no_len:
	case e_number:
	    len = symptr->length;
	    break;
        case e_star:
	    len = strend - strbeg;	/* long enough */          
	    break;
        }

        explicit_length = TRUE;
      redo_switch:
        beyond = s >= strend;
	{
	    int which = (symptr->code & TYPE_IS_SHRIEKING)
		? PACK_SIZE_SHRIEKING : PACK_SIZE_NORMAL;
	    const int rawtype = TYPE_NO_MODIFIERS(datumtype);
	    int offset = rawtype - packsize[which].first;

	    if (offset >= 0 && offset < packsize[which].size) {
		/* Data about this template letter  */
		unsigned char data = packsize[which].array[offset];

		if (data) {
		    /* data nonzero means we can process this letter.  */
		    long size = data & PACK_SIZE_MASK;
		    long howmany = (strend - s) / size;
		    if (len > howmany)
			len = howmany;

		    if (!checksum || (data & PACK_SIZE_CANNOT_CSUM)) {
			if (len && unpack_only_one) len = 1;
			EXTEND(SP, len);
			EXTEND_MORTAL(len);
		    }
		}
	    }
	}
	switch(TYPE_NO_ENDIANNESS(datumtype)) {
	default:
	    Perl_croak(aTHX_ "Invalid type '%c' in unpack", (int)TYPE_NO_MODIFIERS(datumtype) );

	case '%':
	    if (howlen == e_no_len)
		len = 16;		/* len is not specified */
	    checksum = len;
	    cuv = 0;
	    cdouble = 0;
	    continue;
	    break;
	case '(':
	{
            tempsym_t savsym = *symptr;
	    U32 group_modifiers = TYPE_MODIFIERS(datumtype & ~symptr->flags);
	    symptr->flags |= group_modifiers;
            symptr->patend = savsym.grpend;
            symptr->level++;
	    PUTBACK;
	    while (len--) {
  	        symptr->patptr = savsym.grpbeg;
		if (utf8) symptr->flags |=  FLAG_UNPACK_PARSE_UTF8;
		else      symptr->flags &= ~FLAG_UNPACK_PARSE_UTF8;
 	        unpack_rec(symptr, s, strbeg, strend, &s);
                if (s == strend && savsym.howlen == e_star)
		    break; /* No way to continue */
	    }
	    SPAGAIN;
	    symptr->flags &= ~group_modifiers;
            savsym.flags = symptr->flags;
            *symptr = savsym;
	    break;
	}
	case '@':
	    if (utf8) {
		s = strrelbeg;
		while (len > 0) {
		    if (s >= strend)
			Perl_croak(aTHX_ "'@' outside of string in unpack");
		    s += UTF8SKIP(s);
		    len--;
		}
		if (s > strend)
		    Perl_croak(aTHX_ "'@' outside of string with malformed UTF-8 in unpack");
	    } else {
	    if (len > strend - strrelbeg)
		Perl_croak(aTHX_ "'@' outside of string in unpack");
	    s = strrelbeg + len;
	    }
	    break;
 	case 'X' | TYPE_IS_SHRIEKING:
 	    if (!len)			/* Avoid division by 0 */
 		len = 1;
	    if (utf8) {
		char *hop, *last;
		I32 l;
		for (l=len, hop = strbeg; hop < s; l++, hop += UTF8SKIP(hop))
		    if (l == len) {
			last = hop;
			l = 0;
		    }
		s = last;
		break;
	    } else len = (s - strbeg) % len;
 	    /* FALL THROUGH */
	case 'X':
	    if (utf8) {
		while (len > 0) {
		    if (s <= strbeg)
			Perl_croak(aTHX_ "'X' outside of string in unpack");
		    while (UTF8_IS_CONTINUATION(*--s)) {
			if (s <= strbeg)
			    Perl_croak(aTHX_ "'X' outside of string in unpack");
		    }
		    len--;
		}
	    } else {
	    if (len > s - strbeg)
		Perl_croak(aTHX_ "'X' outside of string in unpack" );
	    s -= len;
	    }
	    break;
 	case 'x' | TYPE_IS_SHRIEKING:
 	    if (!len)			/* Avoid division by 0 */
 		len = 1;
	    if (utf8) {
		char *hop = strbeg;
		I32 l = 0;
		for (hop = strbeg; hop < s; hop += UTF8SKIP(hop)) l++;
		if (s != hop)
		    Perl_croak(aTHX_ "Malformed UTF-8 string in unpack");
		ai32 = l % len;
	    } else ai32 = (s - strbeg) % len;
	    if (ai32 == 0) break;
	    len -= ai32;
 	    /* FALL THROUGH */
	case 'x':
	    if (utf8) {
		while (len>0) {
		    if (s >= strend)
			Perl_croak(aTHX_ "'x' outside of string in unpack");
		    s += UTF8SKIP(s);
		    len--;
		}
	    } else {
	    if (len > strend - s)
		Perl_croak(aTHX_ "'x' outside of string in unpack");
	    s += len;
	    };
	    break;
	case '/':
	    Perl_croak(aTHX_ "'/' must follow a numeric type in unpack");
            break;
	case 'A':
	case 'Z':
	case 'a':
	    if (checksum) {
		/* Preliminary length estimate is assumed done in 'W' */
		if (len > strend - s) len = strend - s;
		goto W_checksum;
	    }
	    if (utf8) {
		I32 l;
		char *hop;
		for (l=len, hop=s; l>0; l--, hop += UTF8SKIP(hop)) {
		    if (hop >= strend) {
			if (hop > strend)
			    Perl_croak(aTHX_ "Malformed UTF-8 string in unpack");
			break;
		}
		}
		if (hop > strend)
		    Perl_croak(aTHX_ "Malformed UTF-8 string in unpack");
		len = hop - s;
	    } else if (len > strend - s)
		len = strend - s;

	    if (datumtype == 'Z') {
		/* 'Z' strips stuff after first null */
		char *ptr;
		for (ptr = s; ptr < strend; ptr++) if (*ptr == 0) break;
		sv = newSVpvn(s, ptr-s);
		if (howlen == e_star) /* exact for 'Z*' */
		    len = ptr-s + (ptr != strend ? 1 : 0);
	    } else if (datumtype == 'A') {
		/* 'A' strips both nulls and spaces */
		char *ptr;
		for (ptr = s+len-1; ptr >= s; ptr--)
		    if (*ptr != 0 && !isSPACE(*ptr)) break;
		ptr++;
		sv = newSVpvn(s, ptr-s);
	    } else sv = newSVpvn(s, len);

	    if (utf8) {
		SvUTF8_on(sv);
		/* Undo any upgrade done due to need_utf8() */
		if (!(symptr->flags & FLAG_UNPACK_WAS_UTF8))
		    sv_utf8_downgrade(sv, 0);
	    }
	    XPUSHs(sv_2mortal(sv));
	    s += len;
	    break;
	case 'B':
	case 'b': {
	    char *str;
	    if (howlen == e_star || len > (strend - s) * 8)
		len = (strend - s) * 8;
	    if (checksum) {
		if (!PL_bitcount) {
		    int bits;
		    Newz(601, PL_bitcount, 256, char);
		    for (bits = 1; bits < 256; bits++) {
			if (bits & 1)	PL_bitcount[bits]++;
			if (bits & 2)	PL_bitcount[bits]++;
			if (bits & 4)	PL_bitcount[bits]++;
			if (bits & 8)	PL_bitcount[bits]++;
			if (bits & 16)	PL_bitcount[bits]++;
			if (bits & 32)	PL_bitcount[bits]++;
			if (bits & 64)	PL_bitcount[bits]++;
			if (bits & 128)	PL_bitcount[bits]++;
		    }
		}
		if (utf8) {
		    while (len >= 8 && s < strend) {
			cuv += PL_bitcount[next_uni_byte(aTHX_ &s, strend, datumtype)];
			len -= 8;
		    }
		} else {
		while (len >= 8) {
			cuv += PL_bitcount[*(U8 *)s++];
		    len -= 8;
		}
		}
		if (len && s < strend) {
		    U8 bits;
		    bits = NEXT_BYTE(utf8, s, strend, datumtype);
		    if (datumtype == 'b') {
			while (len-- > 0) {
			    if (bits & 1) cuv++;
			    bits >>= 1;
			}
		    } else {
			while (len-- > 0) {
			    if (bits & 0x80) cuv++;
			    bits <<= 1;
			}
		    }
		}
		break;
	    }

	    sv = sv_2mortal(NEWSV(35, len ? len : 1));
	    SvPOK_on(sv);
	    str = SvPVX(sv);
	    if (datumtype == 'b') {
		U8 bits;
		ai32 = len;
		for (len = 0; len < ai32; len++) {
		    if (len & 7) bits >>= 1;
		    else if (utf8) {
			if (s >= strend) break;
			bits = next_uni_byte(aTHX_ &s, strend, datumtype);
		    } else bits = *(U8 *) s++;
		    *str++ = bits & 1 ? '1' : '0';
		}
	    } else {
		U8 bits;
		ai32 = len;
		for (len = 0; len < ai32; len++) {
		    if (len & 7) bits <<= 1;
		    else if (utf8) {
			if (s >= strend) break;
			bits = next_uni_byte(aTHX_ &s, strend, datumtype);
		    } else bits = *(U8 *) s++;
		    *str++ = bits & 0x80 ? '1' : '0';
		}
	    }
	    *str = '\0';
	    SvCUR_set(sv, str - SvPVX(sv));
	    XPUSHs(sv);
	    break;
	}
	case 'H':
	case 'h': {
	    char *str;
	      /* Preliminary length estimate, acceptable for utf8 too */
	    if (howlen == e_star || len > (strend - s) * 2)
		len = (strend - s) * 2;
	      sv = sv_2mortal(NEWSV(35, len ? len : 1));
	    SvPOK_on(sv);
	    str = SvPVX(sv);
	    if (datumtype == 'h') {
		  U8 bits;
		  ai32 = len;
		  for (len = 0; len < ai32; len++) {
		      if (len & 1) bits >>= 4;
		      else if (utf8) {
			  if (s >= strend) break;
			  bits = next_uni_byte(aTHX_ &s, strend, datumtype);
		      } else bits = * (U8 *) s++;
		    *str++ = PL_hexdigit[bits & 15];
		}
	    } else {
		U8 bits;
		ai32 = len;
		for (len = 0; len < ai32; len++) {
		    if (len & 1) bits <<= 4;
		    else if (utf8) {
			if (s >= strend) break;
			bits = next_uni_byte(aTHX_ &s, strend, datumtype);
		    } else bits = *(U8 *) s++;
		    *str++ = PL_hexdigit[(bits >> 4) & 15];
		}
	    }
	    *str = '\0';
	    SvCUR_set(sv, str - SvPVX(sv));
	    XPUSHs(sv);
	    break;
	}
	case 'c':
	    while (len-- > 0) {
		int aint = NEXT_BYTE(utf8, s, strend, datumtype);
		if (aint >= 128)	/* fake up signed chars */
		    aint -= 256;
		if (!checksum)
		    PUSHs(sv_2mortal(newSViv((IV)aint)));
		else if (checksum > bits_in_uv)
		    cdouble += (NV)aint;
		else
		    cuv += aint;
	    }
	    break;
	case 'C':
	case 'W':
	  W_checksum:
            if (len == 0) {
                if (explicit_length && datumtype == 'C') 
		    /* Switch to "character" mode */
		    utf8 = (symptr->flags & FLAG_UNPACK_DO_UTF8) ? 1 : 0;
		break;
	    }
	    if (datumtype == 'C' ? 
		 (symptr->flags & FLAG_UNPACK_DO_UTF8) && 
		!(symptr->flags & FLAG_UNPACK_WAS_UTF8) : utf8) {
		while (len-- > 0 && s < strend) {
		    UV val;
		    STRLEN retlen;
		    val =
			UNI_TO_NATIVE(utf8n_to_uvuni((U8*)s, strend-s, &retlen,
						     ckWARN(WARN_UTF8) ? 0 : UTF8_ALLOW_ANY));
		    if (retlen == (STRLEN) -1 || retlen == 0)
			Perl_croak(aTHX_ "Malformed UTF-8 string in unpack");
		    s += retlen;
		    if (!checksum)
			PUSHs(sv_2mortal(newSVuv((UV) val)));
		    else if (checksum > bits_in_uv)
			cdouble += (NV) val;
		    else
			cuv += val;
	    }
	    } else if (!checksum)
		while (len-- > 0) {
		    U8 ch = *(U8 *) s++;
		    PUSHs(sv_2mortal(newSVuv((UV) ch)));
	    }
	    else if (checksum > bits_in_uv)
		while (len-- > 0) cdouble += (NV) *(U8 *) s++;
	    else
		while (len-- > 0) cuv += *(U8 *) s++;
	    break;
	case 'U':
	    if (len == 0) {
                if (explicit_length) {
		    /* Switch to "bytes in UTF-8" mode */
		    if (symptr->flags & FLAG_UNPACK_DO_UTF8) utf8 = 0;
		    else
			/* Should be impossible due to the need_utf8() test */
			Perl_croak(aTHX_ "U0 mode on a byte string");
		}
		break;
	    }
	    if (len > strend - s) len = strend - s;
		if (!checksum) {
		if (len && unpack_only_one) len = 1;
		EXTEND(SP, len);
		EXTEND_MORTAL(len);
		}
	    while (len-- > 0 && s < strend) {
		STRLEN retlen;
		UV auv;
		if (utf8) {
		    U8 result[UTF8_MAXLEN];
		    char *ptr;
		    STRLEN len;
		    ptr = s;
		    /* Bug: warns about bad utf8 even if we are short on bytes
		       and will break out of the loop */
		    if (!next_uni_bytes(aTHX_ &ptr, strend, (char*)result, 1))
			break;
		    len = UTF8SKIP(result);
		    if (!next_uni_bytes(aTHX_ &ptr, strend, (char*)&result[1], len-1))
			break;
		    auv = utf8n_to_uvuni(result, len, &retlen, ckWARN(WARN_UTF8) ? 0 : UTF8_ALLOW_ANYUV);
		    s = ptr;
		} else {
		    auv = utf8n_to_uvuni((U8*)s, strend - s, &retlen, ckWARN(WARN_UTF8) ? 0 : UTF8_ALLOW_ANYUV);
		    if (retlen == (STRLEN) -1 || retlen == 0)
			Perl_croak(aTHX_ "Malformed UTF-8 string in unpack");
		    s += retlen;
		}
		if (!checksum)
		    PUSHs(sv_2mortal(newSVuv((UV) auv)));
		else if (checksum > bits_in_uv)
		    cdouble += (NV) auv;
		else
		    cuv += auv;
	    }
	    break;
	case 's' | TYPE_IS_SHRIEKING:
#if SHORTSIZE != SIZE16
	    while (len-- > 0) {
		short ashort;
		COPYVAR(s, strend, utf8, ashort, s);
		if (!checksum)
		    PUSHs(sv_2mortal(newSViv((IV)ashort)));
		else if (checksum > bits_in_uv)
		    cdouble += (NV)ashort;
		else
		    cuv += ashort;
	    }
	    break;
#else
	    /* Fallthrough! */
#endif
	case 's':
	    while (len-- > 0) {
		I16 ai16;

#if U16SIZE > SIZE16
		ai16 = 0;
#endif
		if (utf8) {
		    if (!next_uni_bytes(aTHX_ &s, strend, 
					OFF16(&ai16), SIZE16)) break;
		} else {
		COPY16(s, &ai16);
		    s += SIZE16;
		}
		DO_BO_UNPACK(ai16, 16);
#if U16SIZE > SIZE16
		if (ai16 > 32767)
		    ai16 -= 65536;
#endif
		if (!checksum)
		    PUSHs(sv_2mortal(newSViv((IV)ai16)));
		else if (checksum > bits_in_uv)
		    cdouble += (NV)ai16;
		else
		    cuv += ai16;
	    }
	    break;
	case 'S' | TYPE_IS_SHRIEKING:
#if SHORTSIZE != SIZE16
	    while (len-- > 0) {
		unsigned short aushort;
		COPYVAR(s, strend, utf8, aushort, s);
		if (!checksum)
		    PUSHs(sv_2mortal(newSVuv((UV) aushort)));
		else if (checksum > bits_in_uv)
		    cdouble += (NV)aushort;
		else
		    cuv += aushort;
	    }
	    break;
#else
            /* Fallhrough! */
#endif
	case 'v':
	case 'n':
	case 'S':
	    while (len-- > 0) {
		U16 au16;
#if U16SIZE > SIZE16
		au16 = 0;
#endif
		if (utf8) {
		    if (!next_uni_bytes(aTHX_ &s, strend, 
					OFF16(&au16), SIZE16)) break;
		} else {
		COPY16(s, &au16);
		s += SIZE16;
		}
		DO_BO_UNPACK(au16, 16);
#ifdef HAS_NTOHS
		if (datumtype == 'n')
		    au16 = PerlSock_ntohs(au16);
#endif
#ifdef HAS_VTOHS
		if (datumtype == 'v')
		    au16 = vtohs(au16);
#endif
		if (!checksum)
		    PUSHs(sv_2mortal(newSVuv((UV)au16)));
		else if (checksum > bits_in_uv)
		    cdouble += (NV)au16;
		else
		    cuv += au16;
	    }
	    break;
#ifdef PERL_PACK_CAN_SHRIEKSIGN
	case 'v' | TYPE_IS_SHRIEKING:
	case 'n' | TYPE_IS_SHRIEKING:
	    while (len-- > 0) {
		I16 ai16;
# if U16SIZE > SIZE16
		ai16 = 0;
# endif
		if (utf8) {
		    if (!next_uni_bytes(aTHX_ &s, strend,
					(char *) &ai16, sizeof(ai16))) break;
		} else {
		COPY16(s, &ai16);
		s += SIZE16;
		}
# ifdef HAS_NTOHS
		if (datumtype == ('n' | TYPE_IS_SHRIEKING))
		    ai16 = (I16) PerlSock_ntohs((U16) ai16);
# endif /* HAS_NTOHS */
# ifdef HAS_VTOHS
		if (datumtype == ('v' | TYPE_IS_SHRIEKING))
		    ai16 = (I16) vtohs((U16) ai16);
# endif /* HAS_VTOHS */
		if (!checksum)
		    PUSHs(sv_2mortal(newSViv((IV)ai16)));
		else if (checksum > bits_in_uv)
		    cdouble += (NV) ai16;
		else
		    cuv += ai16;
	    }
	    break;
#endif /* PERL_PACK_CAN_SHRIEKSIGN */
	case 'i':
	case 'i' | TYPE_IS_SHRIEKING:
	    while (len-- > 0) {
		int aint;
		COPYVAR(s, strend, utf8, aint, i);
		if (!checksum)
		    PUSHs(sv_2mortal(newSViv((IV)aint)));
		else if (checksum > bits_in_uv)
		    cdouble += (NV)aint;
		else
		    cuv += aint;
	    }
	    break;
	case 'I':
	case 'I' | TYPE_IS_SHRIEKING:
	    while (len-- > 0) {
		unsigned int auint;
		COPYVAR(s, strend, utf8, auint, i);
		if (!checksum)
		    PUSHs(sv_2mortal(newSVuv((UV)auint)));
		else if (checksum > bits_in_uv)
		    cdouble += (NV)auint;
		else
		    cuv += auint;
	    }
	    break;
	case 'j':
	    while (len-- > 0) {
		IV aiv;
#if IVSIZE == INTSIZE
		COPYVAR(s, strend, utf8, aiv, i);
#elif IVSIZE == LONGSIZE
		COPYVAR(s, strend, utf8, aiv, l);
#elif defined(HAS_QUAD) && IVSIZE == U64SIZE
		COPYVAR(s, strend, utf8, aiv, 64);
#else
		Perl_croak(aTHX_ "'j' not supported on this platform");
#endif
		if (!checksum)
		    PUSHs(sv_2mortal(newSViv(aiv)));
		else if (checksum > bits_in_uv)
		    cdouble += (NV)aiv;
		else
		    cuv += aiv;
	    }
	    break;
	case 'J':
	    while (len-- > 0) {
		UV auv;
#if IVSIZE == INTSIZE
		COPYVAR(s, strend, utf8, auv, i);
#elif IVSIZE == LONGSIZE
		COPYVAR(s, strend, utf8, auv, l);
#elif defined(HAS_QUAD) && IVSIZE == U64SIZE
		COPYVAR(s, strend, utf8, auv, 64);
#else
		Perl_croak(aTHX_ "'J' not supported on this platform");
#endif
		if (!checksum)
		    PUSHs(sv_2mortal(newSVuv(auv)));
		else if (checksum > bits_in_uv)
		    cdouble += (NV)auv;
		else
		    cuv += auv;
	    }
	    break;
	case 'l' | TYPE_IS_SHRIEKING:
#if LONGSIZE != SIZE32
	    while (len-- > 0) {
		long along;
		COPYVAR(s, strend, utf8, along, l);
		if (!checksum)
		    PUSHs(sv_2mortal(newSViv((IV)along)));
		else if (checksum > bits_in_uv)
		    cdouble += (NV)along;
		else
		    cuv += along;
	    }
	    break;
#else
	    /* Fallthrough! */
#endif
	case 'l':
	    while (len-- > 0) {
		I32 ai32;
#if U32SIZE > SIZE32
		ai32 = 0;
#endif
		if (utf8) {
		    if (!next_uni_bytes(aTHX_ &s, strend,
					OFF32(&ai32), SIZE32)) break;
		} else {
		COPY32(s, &ai32);
		    s += SIZE32;
		}
		DO_BO_UNPACK(ai32, 32);
#if U32SIZE > SIZE32
		if (ai32 > 2147483647) ai32 -= 4294967296;
#endif
		if (!checksum)
		    PUSHs(sv_2mortal(newSViv((IV)ai32)));
		else if (checksum > bits_in_uv)
		    cdouble += (NV)ai32;
		else
		    cuv += ai32;
	    }
	    break;
	case 'L' | TYPE_IS_SHRIEKING:
#if LONGSIZE != SIZE32
	    while (len-- > 0) {
		unsigned long aulong;
		COPYVAR(s, strend, utf8, aulong, l);
		if (!checksum)
		    PUSHs(sv_2mortal(newSVuv((UV)aulong)));
		else if (checksum > bits_in_uv)
		    cdouble += (NV)aulong;
		else
		    cuv += aulong;
	    }
	    break;
#else
            /* Fall through! */
#endif
	case 'V':
	case 'N':
	case 'L':
	    while (len-- > 0) {
		U32 au32;
#if U32SIZE > SIZE32
		au32 = 0;
#endif
		if (utf8) {
		    if (!next_uni_bytes(aTHX_ &s, strend,
					OFF32(&au32), SIZE32)) break;
		} else {
		COPY32(s, &au32);
		s += SIZE32;
		}
		DO_BO_UNPACK(au32, 32);
#ifdef HAS_NTOHL
		if (datumtype == 'N')
		    au32 = PerlSock_ntohl(au32);
#endif
#ifdef HAS_VTOHL
		if (datumtype == 'V')
		    au32 = vtohl(au32);
#endif
		if (!checksum)
		     PUSHs(sv_2mortal(newSVuv((UV)au32)));
		 else if (checksum > bits_in_uv)
		     cdouble += (NV)au32;
		 else
		     cuv += au32;
	    }
	    break;
#ifdef PERL_PACK_CAN_SHRIEKSIGN
	case 'V' | TYPE_IS_SHRIEKING:
	case 'N' | TYPE_IS_SHRIEKING:
	    while (len-- > 0) {
		I32 ai32;
# if U32SIZE > SIZE32
		ai32 = 0;
# endif
		if (utf8) {
		    if (!next_uni_bytes(aTHX_ &s, strend,
					OFF32(&ai32), SIZE32)) break;
		} else {
		COPY32(s, &ai32);
		s += SIZE32;
		}
# ifdef HAS_NTOHL
		if (datumtype == ('N' | TYPE_IS_SHRIEKING))
		    ai32 = (I32)PerlSock_ntohl((U32)ai32);
# endif
# ifdef HAS_VTOHL
		if (datumtype == ('V' | TYPE_IS_SHRIEKING))
		    ai32 = (I32)vtohl((U32)ai32);
# endif
		if (!checksum)
		    PUSHs(sv_2mortal(newSViv((IV)ai32)));
		else if (checksum > bits_in_uv)
		    cdouble += (NV)ai32;
		else
		    cuv += ai32;
	    }
	    break;
#endif /* PERL_PACK_CAN_SHRIEKSIGN */
	case 'p':
	    while (len-- > 0) {
		char *aptr;
		if (utf8) {
		    if (!next_uni_bytes(aTHX_ &s, strend,
					(char *) &aptr, sizeof(aptr))) break;
		} else {
		Copy(s, &aptr, 1, char*);
		    s += sizeof(aptr);
		}
		DO_BO_UNPACK_P(aptr);
		/* newSVpv generates undef if aptr is NULL */
		PUSHs(sv_2mortal(newSVpv(aptr, 0)));
	    }
	    break;
	case 'w':
	    {
		UV auv = 0;
		U32 bytes = 0;
		
		while (len > 0 && s < strend) {
		    U8 ch;
		    ch = NEXT_BYTE(utf8, s, strend, 'w');
		    auv = (auv << 7) | (ch & 0x7f);
		    /* UTF8_IS_XXXXX not right here - using constant 0x80 */
		    if (ch < 0x80) {
			bytes = 0;
			PUSHs(sv_2mortal(newSVuv(auv)));
			len--;
			auv = 0;
			continue;
		    }
		    if (++bytes >= sizeof(UV)) {	/* promote to string */
			char *t;
			STRLEN n_a;

			sv = Perl_newSVpvf(aTHX_ "%.*"UVf, (int)TYPE_DIGITS(UV), auv);
			while (s < strend) {
			    ch = NEXT_BYTE(utf8, s, strend, 'w');
			    sv = mul128(sv, (U8)(ch & 0x7f));
			    if (!(ch & 0x80)) {
				bytes = 0;
				break;
			    }
			}
			t = SvPV(sv, n_a);
			while (*t == '0')
			    t++;
			sv_chop(sv, t);
			PUSHs(sv_2mortal(sv));
			len--;
			auv = 0;
		    }
		}
		if ((s >= strend) && bytes)
		    Perl_croak(aTHX_ "Unterminated compressed integer in unpack");
	    }
	    break;
	case 'P':
	    if (symptr->howlen == e_star)
	        Perl_croak(aTHX_ "'P' must have an explicit size in unpack");
	    EXTEND(SP, 1);
	    if (sizeof(char*) <= strend - s) {
		char *aptr;
		if (utf8) {
		    if (!next_uni_bytes(aTHX_ &s, strend, (char *) &aptr,
					sizeof(aptr))) break;
		} else {
		Copy(s, &aptr, 1, char*);
		    s += sizeof(aptr);
	    }
		DO_BO_UNPACK_P(aptr);
	    /* newSVpvn generates undef if aptr is NULL */
	    PUSHs(sv_2mortal(newSVpvn(aptr, len)));
	    }
	    break;
#ifdef HAS_QUAD
	case 'q':
	    while (len-- > 0) {
		Quad_t aquad;
		COPYVAR(s, strend, utf8, aquad, 64);
		if (!checksum)
                    PUSHs(sv_2mortal(aquad >= IV_MIN && aquad <= IV_MAX ?
				     newSViv((IV)aquad) : newSVnv((NV)aquad)));
		else if (checksum > bits_in_uv)
		    cdouble += (NV)aquad;
		else
		    cuv += aquad;
	    }
	    break;
	case 'Q':
	    while (len-- > 0) {
		Uquad_t auquad;
		COPYVAR(s, strend, utf8, auquad, 64);
		if (!checksum)
		    PUSHs(sv_2mortal(auquad <= UV_MAX ?
				     newSVuv((UV)auquad):newSVnv((NV)auquad)));
		else if (checksum > bits_in_uv)
		    cdouble += (NV)auquad;
		else
		    cuv += auquad;
	    }
	    break;
#endif /* HAS_QUAD */
	/* float and double added gnb@melba.bby.oz.au 22/11/89 */
	case 'f':
	    while (len-- > 0) {
		float afloat;
		if (utf8) {
		    if (!next_uni_bytes(aTHX_ &s, strend, (char *) &afloat,
					sizeof(afloat))) break;
		} else {
		Copy(s, &afloat, 1, float);
		s += sizeof(float);
		}
		DO_BO_UNPACK_N(afloat, float);
		if (!checksum)
		    PUSHs(sv_2mortal(newSVnv((NV)afloat)));
		else
		    cdouble += afloat;
		}
	    break;
	case 'd':
	    while (len-- > 0) {
		double adouble;
		if (utf8) {
		    if (!next_uni_bytes(aTHX_ &s, strend, (char *) &adouble,
					sizeof(adouble))) break;
		} else {
		Copy(s, &adouble, 1, double);
		s += sizeof(double);
		}
		DO_BO_UNPACK_N(adouble, double);
		if (!checksum)
		    PUSHs(sv_2mortal(newSVnv((NV)adouble)));
		else
		    cdouble += adouble;
		}
	    break;
	case 'F':
	    while (len-- > 0) {
		NV anv;
		if (utf8) {
		    if (!next_uni_bytes(aTHX_ &s, strend,
					(char *) &anv, sizeof(anv))) break;
		} else {
		Copy(s, &anv, 1, NV);
		s += NVSIZE;
		}
		DO_BO_UNPACK_N(anv, NV);
		if (!checksum)
		    PUSHs(sv_2mortal(newSVnv(anv)));
		else
		    cdouble += anv;
		}
	    break;
#if defined(HAS_LONG_DOUBLE) && defined(USE_LONG_DOUBLE)
	case 'D':
	    while (len-- > 0) {
		long double aldouble;
		if (utf8) {
		    if (!next_uni_bytes(aTHX_ &s, strend, (char *) &aldouble,
					sizeof(aldouble))) break;
		} else {
		Copy(s, &aldouble, 1, long double);
		s += LONG_DOUBLESIZE;
		}
		DO_BO_UNPACK_N(aldouble, long double);
		if (!checksum)
		    PUSHs(sv_2mortal(newSVnv((NV)aldouble)));
		else
		    cdouble += aldouble;
	    }
	    break;
#endif
	case 'u':
	    /* MKS:
	     * Initialise the decode mapping.  By using a table driven
             * algorithm, the code will be character-set independent
             * (and just as fast as doing character arithmetic)
             */
            if (PL_uudmap['M'] == 0) {
                int i;

                for (i = 0; i < sizeof(PL_uuemap); i += 1)
                    PL_uudmap[(U8)PL_uuemap[i]] = i;
                /*
                 * Because ' ' and '`' map to the same value,
                 * we need to decode them both the same.
                 */
                PL_uudmap[' '] = 0;
            }
	    {
		STRLEN l = (STRLEN) (strend - s) * 3 / 4;
		sv = sv_2mortal(NEWSV(42, l));
		if (l) SvPOK_on(sv);
	    }
	    if (utf8) {
		while (next_uni_uu(aTHX_ &s, strend, &len)) {
		    I32 a, b, c, d;
		    char hunk[4];

		    hunk[3] = '\0';
		    while (len > 0) {
			next_uni_uu(aTHX_ &s, strend, &a);
			next_uni_uu(aTHX_ &s, strend, &b);
			next_uni_uu(aTHX_ &s, strend, &c);
			next_uni_uu(aTHX_ &s, strend, &d);
			hunk[0] = (char)((a << 2) | (b >> 4));
			hunk[1] = (char)((b << 4) | (c >> 2));
			hunk[2] = (char)((c << 6) | d);
			sv_catpvn(sv, hunk, (len > 3) ? 3 : len);
			len -= 3;
		    }
		    if (s < strend) {
			if (*s == '\n') s++;
			else {
			    /* possible checksum byte */
			    char *skip = s+UTF8SKIP(s);
			    if (skip < strend && *skip == '\n') s = skip+1;
			}
		    }
		}
	    } else {
	    while (s < strend && *s > ' ' && ISUUCHAR(*s)) {
		I32 a, b, c, d;
		char hunk[4];

		hunk[3] = '\0';
		len = PL_uudmap[*(U8*)s++] & 077;
		while (len > 0) {
		    if (s < strend && ISUUCHAR(*s))
			a = PL_uudmap[*(U8*)s++] & 077;
 		    else
 			a = 0;
		    if (s < strend && ISUUCHAR(*s))
			b = PL_uudmap[*(U8*)s++] & 077;
 		    else
 			b = 0;
		    if (s < strend && ISUUCHAR(*s))
			c = PL_uudmap[*(U8*)s++] & 077;
 		    else
 			c = 0;
		    if (s < strend && ISUUCHAR(*s))
			d = PL_uudmap[*(U8*)s++] & 077;
		    else
			d = 0;
		    hunk[0] = (char)((a << 2) | (b >> 4));
		    hunk[1] = (char)((b << 4) | (c >> 2));
		    hunk[2] = (char)((c << 6) | d);
		    sv_catpvn(sv, hunk, (len > 3) ? 3 : len);
		    len -= 3;
		}
		if (*s == '\n')
		    s++;
		else	/* possible checksum byte */
		    if (s + 1 < strend && s[1] == '\n')
		        s += 2;
	    }
	    }
	    XPUSHs(sv);
	    break;
	}

	if (checksum) {
	    if (strchr("fFdD", TYPE_NO_MODIFIERS(datumtype)) ||
	      (checksum > bits_in_uv &&
	       strchr("cCsSiIlLnNUWvVqQjJ", TYPE_NO_MODIFIERS(datumtype))) ) {
		NV trouble, anv;

                anv = (NV) (1 << (checksum & 15));
		while (checksum >= 16) {
		    checksum -= 16;
		    anv *= 65536.0;
		}
		while (cdouble < 0.0)
		    cdouble += anv;
		cdouble = Perl_modf(cdouble / anv, &trouble) * anv;
		sv = newSVnv(cdouble);
	    }
	    else {
		if (checksum < bits_in_uv) {
		    UV mask = ((UV)1 << checksum) - 1;
		    cuv &= mask;
		}
		sv = newSVuv(cuv);
	    }
	    XPUSHs(sv_2mortal(sv));
	    checksum = 0;
	}
    
        if (symptr->flags & FLAG_SLASH){
            if (SP - PL_stack_base - start_sp_offset <= 0)
                Perl_croak(aTHX_ "'/' must follow a numeric type in unpack");
            if( next_symbol(symptr) ){
              if( symptr->howlen == e_number )
		Perl_croak(aTHX_ "Count after length/code in unpack" );
              if( beyond ){
         	/* ...end of char buffer then no decent length available */
		Perl_croak(aTHX_ "length/code after end of string in unpack" );
              } else {
         	/* take top of stack (hope it's numeric) */
                len = POPi;
                if( len < 0 )
                    Perl_croak(aTHX_ "Negative '/' count in unpack" );
              }
            } else {
		Perl_croak(aTHX_ "Code missing after '/' in unpack" );
            }
            datumtype = symptr->code;
            explicit_length = FALSE;
	    goto redo_switch;
        }
    }

    if (new_s)
	*new_s = s;
    PUTBACK;
    return SP - PL_stack_base - start_sp_offset;
}

PP(pp_unpack)
{
    dSP;
    dPOPPOPssrl;
    I32 gimme = GIMME_V;
    STRLEN llen;
    STRLEN rlen;
    char *pat = SvPV(left,  llen);
    char *s   = SvPV(right, rlen);
    char *strend = s + rlen;
    char *patend = pat + llen;
    I32 cnt;

    PUTBACK;
    cnt = unpackstring(pat, patend, s, strend,
		     ((gimme == G_SCALAR) ? FLAG_UNPACK_ONLY_ONE : 0)
		     | (DO_UTF8(right) ? FLAG_UNPACK_DO_UTF8 : 0));

    SPAGAIN;
    if ( !cnt && gimme == G_SCALAR )
       PUSHs(&PL_sv_undef);
    RETURN;
}

STATIC void
S_doencodes(pTHX_ register SV *sv, register char *s, register I32 len)
{
    char hunk[5];

    *hunk = PL_uuemap[len];
    sv_catpvn(sv, hunk, 1);
    hunk[4] = '\0';
    while (len > 2) {
	hunk[0] = PL_uuemap[(077 & (*s >> 2))];
	hunk[1] = PL_uuemap[(077 & (((*s << 4) & 060) | ((s[1] >> 4) & 017)))];
	hunk[2] = PL_uuemap[(077 & (((s[1] << 2) & 074) | ((s[2] >> 6) & 03)))];
	hunk[3] = PL_uuemap[(077 & (s[2] & 077))];
	sv_catpvn(sv, hunk, 4);
	s += 3;
	len -= 3;
    }
    if (len > 0) {
	char r = (len > 1 ? s[1] : '\0');
	hunk[0] = PL_uuemap[(077 & (*s >> 2))];
	hunk[1] = PL_uuemap[(077 & (((*s << 4) & 060) | ((r >> 4) & 017)))];
	hunk[2] = PL_uuemap[(077 & ((r << 2) & 074))];
	hunk[3] = PL_uuemap[0];
	sv_catpvn(sv, hunk, 4);
    }
    sv_catpvn(sv, "\n", 1);
}

STATIC SV *
S_is_an_int(pTHX_ char *s, STRLEN l)
{
  STRLEN	 n_a;
  SV             *result = newSVpvn(s, l);
  char           *result_c = SvPV(result, n_a);	/* convenience */
  char           *out = result_c;
  bool            skip = 1;
  bool            ignore = 0;

  while (*s) {
    switch (*s) {
    case ' ':
      break;
    case '+':
      if (!skip) {
	SvREFCNT_dec(result);
	return (NULL);
      }
      break;
    case '0':
    case '1':
    case '2':
    case '3':
    case '4':
    case '5':
    case '6':
    case '7':
    case '8':
    case '9':
      skip = 0;
      if (!ignore) {
	*(out++) = *s;
      }
      break;
    case '.':
      ignore = 1;
      break;
    default:
      SvREFCNT_dec(result);
      return (NULL);
    }
    s++;
  }
  *(out++) = '\0';
  SvCUR_set(result, out - result_c);
  return (result);
}

/* pnum must be '\0' terminated */
STATIC int
S_div128(pTHX_ SV *pnum, bool *done)
{
  STRLEN          len;
  char           *s = SvPV(pnum, len);
  int             m = 0;
  int             r = 0;
  char           *t = s;

  *done = 1;
  while (*t) {
    int             i;

    i = m * 10 + (*t - '0');
    m = i & 0x7F;
    r = (i >> 7);		/* r < 10 */
    if (r) {
      *done = 0;
    }
    *(t++) = '0' + r;
  }
  *(t++) = '\0';
  SvCUR_set(pnum, (STRLEN) (t - s));
  return (m);
}



/*
=for apidoc pack_cat

The engine implementing pack() Perl function. Note: parameters next_in_list and
flags are not used. This call should not be used; use packlist instead.

=cut */


void
Perl_pack_cat(pTHX_ SV *cat, char *pat, register char *patend, register SV **beglist, SV **endlist, SV ***next_in_list, U32 flags)
{
    tempsym_t sym = { 0 };
    sym.patptr = pat;
    sym.patend = patend;
    sym.flags  = FLAG_PACK;

    (void)pack_rec( cat, &sym, beglist, endlist );
}


/*
=for apidoc packlist

The engine implementing pack() Perl function.

=cut */


void
Perl_packlist(pTHX_ SV *cat, char *pat, register char *patend, register SV **beglist, SV **endlist )
{
    tempsym_t sym = { 0 };
    sym.patptr = pat;
    sym.patend = patend;
    sym.flags  = FLAG_PACK;

    (void)pack_rec( cat, &sym, beglist, endlist );
}


STATIC
SV **
S_pack_rec(pTHX_ SV *cat, register tempsym_t* symptr, register SV **beglist, SV **endlist )
{
    register I32 items;
    STRLEN fromlen;
    register I32 len = 0;
    SV *fromstr;
    /*SUPPRESS 442*/
    static char null10[] = {0,0,0,0,0,0,0,0,0,0};
    static char *space10 = "          ";
    bool found;

    /* These must not be in registers: */
    char achar;
    I16 ai16;
    U16 au16;
    I32 ai32;
    U32 au32;
#ifdef HAS_QUAD
    Quad_t aquad;
    Uquad_t auquad;
#endif
#if SHORTSIZE != SIZE16
    short ashort;
    unsigned short aushort;
#endif
    int aint;
    unsigned int auint;
#if LONGSIZE != SIZE32
    long along;
    unsigned long aulong;
#endif
    char *aptr;
    float afloat;
    double adouble;
#if defined(HAS_LONG_DOUBLE) && defined(USE_LONG_DOUBLE)
    long double aldouble;
#endif
    IV aiv;
    UV auv;
    NV anv;

    int strrelbeg = SvCUR(cat);
    tempsym_t lookahead;

    items = endlist - beglist;
    found = next_symbol( symptr );

#ifndef PACKED_IS_OCTETS
    if (symptr->level == 0 && found && symptr->code == 'U' ){
	SvUTF8_on(cat);
    }
#endif

    while (found) {
	SV *lengthcode = Nullsv;
#define NEXTFROM ( lengthcode ? lengthcode : items-- > 0 ? *beglist++ : &PL_sv_no)

        I32 datumtype = symptr->code;
        howlen_t howlen;

        switch( howlen = symptr->howlen ){
        case e_no_len:
	case e_number:
	    len = symptr->length;
	    break;
        case e_star:
	    len = strchr("@Xxu", TYPE_NO_MODIFIERS(datumtype)) ? 0 : items; 
	    break;
        }

        /* Look ahead for next symbol. Do we have code/code? */
        lookahead = *symptr;
        found = next_symbol(&lookahead);
	if ( symptr->flags & FLAG_SLASH ) {
	    if (found){
 	        if ( 0 == strchr( "aAZ", lookahead.code ) ||
                     e_star != lookahead.howlen )
 		    Perl_croak(aTHX_ "'/' must be followed by 'a*', 'A*' or 'Z*' in pack");
	        lengthcode = sv_2mortal(newSViv(sv_len(items > 0
						   ? *beglist : &PL_sv_no)
                                           + (lookahead.code == 'Z' ? 1 : 0)));
	    } else {
 		Perl_croak(aTHX_ "Code missing after '/' in pack");
            }
	}

	switch(TYPE_NO_ENDIANNESS(datumtype)) {
	default:
	    Perl_croak(aTHX_ "Invalid type '%c' in pack", (int)TYPE_NO_MODIFIERS(datumtype));
	case '%':
	    Perl_croak(aTHX_ "'%%' may not be used in pack");
	case '@':
	    len += strrelbeg - SvCUR(cat);
	    if (len > 0)
		goto grow;
	    len = -len;
	    if (len > 0)
		goto shrink;
	    break;
	case '(':
	{
            tempsym_t savsym = *symptr;
	    U32 group_modifiers = TYPE_MODIFIERS(datumtype & ~symptr->flags);
	    symptr->flags |= group_modifiers;
            symptr->patend = savsym.grpend;
            symptr->level++;
	    while (len--) {
  	        symptr->patptr = savsym.grpbeg;
		beglist = pack_rec(cat, symptr, beglist, endlist );
		if (savsym.howlen == e_star && beglist == endlist)
		    break;		/* No way to continue */
	    }
	    symptr->flags &= ~group_modifiers;
            lookahead.flags = symptr->flags;
            *symptr = savsym;
	    break;
	}
	case 'X' | TYPE_IS_SHRIEKING:
	    if (!len)			/* Avoid division by 0 */
		len = 1;
	    len = (SvCUR(cat)) % len;
	    /* FALL THROUGH */
	case 'X':
	  shrink:
	    if ((I32)SvCUR(cat) < len)
		Perl_croak(aTHX_ "'X' outside of string in pack");
	    SvCUR(cat) -= len;
	    *SvEND(cat) = '\0';
	    break;
	case 'x' | TYPE_IS_SHRIEKING:
	    if (!len)			/* Avoid division by 0 */
		len = 1;
	    aint = (SvCUR(cat)) % len;
	    if (aint)			/* Other portable ways? */
		len = len - aint;
	    else
		len = 0;
	    /* FALL THROUGH */

	case 'x':
	  grow:
	    while (len >= 10) {
		sv_catpvn(cat, null10, 10);
		len -= 10;
	    }
	    sv_catpvn(cat, null10, len);
	    break;
	case 'A':
	case 'Z':
	case 'a':
	    fromstr = NEXTFROM;
	    aptr = SvPV(fromstr, fromlen);
	    if (howlen == e_star) {   
		len = fromlen;
		if (datumtype == 'Z')
		    ++len;
	    }
	    if ((I32)fromlen >= len) {
		sv_catpvn(cat, aptr, len);
		if (datumtype == 'Z' && len > 0)
		    *(SvEND(cat)-1) = '\0';
	    }
	    else {
		sv_catpvn(cat, aptr, fromlen);
		len -= fromlen;
		if (datumtype == 'A') {
		    while (len >= 10) {
			sv_catpvn(cat, space10, 10);
			len -= 10;
		    }
		    sv_catpvn(cat, space10, len);
		}
		else {
		    while (len >= 10) {
			sv_catpvn(cat, null10, 10);
			len -= 10;
		    }
		    sv_catpvn(cat, null10, len);
		}
	    }
	    break;
	case 'B':
	case 'b':
	    {
		register char *str;
		I32 saveitems;

		fromstr = NEXTFROM;
		saveitems = items;
		str = SvPV(fromstr, fromlen);
		if (howlen == e_star)
		    len = fromlen;
		aint = SvCUR(cat);
		SvCUR(cat) += (len+7)/8;
		SvGROW(cat, SvCUR(cat) + 1);
		aptr = SvPVX(cat) + aint;
		if (len > (I32)fromlen)
		    len = fromlen;
		aint = len;
		items = 0;
		if (datumtype == 'B') {
		    for (len = 0; len++ < aint;) {
			items |= *str++ & 1;
			if (len & 7)
			    items <<= 1;
			else {
			    *aptr++ = items & 0xff;
			    items = 0;
			}
		    }
		}
		else {
		    for (len = 0; len++ < aint;) {
			if (*str++ & 1)
			    items |= 128;
			if (len & 7)
			    items >>= 1;
			else {
			    *aptr++ = items & 0xff;
			    items = 0;
			}
		    }
		}
		if (aint & 7) {
		    if (datumtype == 'B')
			items <<= 7 - (aint & 7);
		    else
			items >>= 7 - (aint & 7);
		    *aptr++ = items & 0xff;
		}
		str = SvPVX(cat) + SvCUR(cat);
		while (aptr <= str)
		    *aptr++ = '\0';

		items = saveitems;
	    }
	    break;
	case 'H':
	case 'h':
	    {
		register char *str;
		I32 saveitems;

		fromstr = NEXTFROM;
		saveitems = items;
		str = SvPV(fromstr, fromlen);
		if (howlen == e_star)
		    len = fromlen;
		aint = SvCUR(cat);
		SvCUR(cat) += (len+1)/2;
		SvGROW(cat, SvCUR(cat) + 1);
		aptr = SvPVX(cat) + aint;
		if (len > (I32)fromlen)
		    len = fromlen;
		aint = len;
		items = 0;
		if (datumtype == 'H') {
		    for (len = 0; len++ < aint;) {
			if (isALPHA(*str))
			    items |= ((*str++ & 15) + 9) & 15;
			else
			    items |= *str++ & 15;
			if (len & 1)
			    items <<= 4;
			else {
			    *aptr++ = items & 0xff;
			    items = 0;
			}
		    }
		}
		else {
		    for (len = 0; len++ < aint;) {
			if (isALPHA(*str))
			    items |= (((*str++ & 15) + 9) & 15) << 4;
			else
			    items |= (*str++ & 15) << 4;
			if (len & 1)
			    items >>= 4;
			else {
			    *aptr++ = items & 0xff;
			    items = 0;
			}
		    }
		}
		if (aint & 1)
		    *aptr++ = items & 0xff;
		str = SvPVX(cat) + SvCUR(cat);
		while (aptr <= str)
		    *aptr++ = '\0';

		items = saveitems;
	    }
	    break;
	case 'C':
	case 'c':
	    while (len-- > 0) {
		fromstr = NEXTFROM;
		switch (TYPE_NO_MODIFIERS(datumtype)) {
		case 'C':
		    aint = SvIV(fromstr);
		    if ((aint < 0 || aint > 255) &&
			ckWARN(WARN_PACK))
		        Perl_warner(aTHX_ packWARN(WARN_PACK),
				    "Character in 'C' format wrapped in pack");
		    achar = aint & 255;
		    sv_catpvn(cat, &achar, sizeof(char));
		    break;
		case 'c':
		    aint = SvIV(fromstr);
		    if ((aint < -128 || aint > 127) &&
			ckWARN(WARN_PACK))
		        Perl_warner(aTHX_ packWARN(WARN_PACK),
				    "Character in 'c' format wrapped in pack" );
		    achar = aint & 255;
		    sv_catpvn(cat, &achar, sizeof(char));
		    break;
		}
	    }
	    break;
	case 'U':
	    while (len-- > 0) {
		fromstr = NEXTFROM;
		auint = UNI_TO_NATIVE(SvUV(fromstr));
		SvGROW(cat, SvCUR(cat) + UTF8_MAXBYTES + 1);
		SvCUR_set(cat,
			  (char*)uvchr_to_utf8_flags((U8*)SvEND(cat),
						     auint,
						     ckWARN(WARN_UTF8) ?
						     0 : UNICODE_ALLOW_ANY)
			  - SvPVX(cat));
	    }
	    *SvEND(cat) = '\0';
	    break;
	/* Float and double added by gnb@melba.bby.oz.au  22/11/89 */
	case 'f':
	    while (len-- > 0) {
		fromstr = NEXTFROM;
#ifdef __VOS__
/* VOS does not automatically map a floating-point overflow
   during conversion from double to float into infinity, so we
   do it by hand.  This code should either be generalized for
   any OS that needs it, or removed if and when VOS implements
   posix-976 (suggestion to support mapping to infinity).
   Paul.Green@stratus.com 02-04-02.  */
		if (SvNV(fromstr) > FLT_MAX)
		     afloat = _float_constants[0];   /* single prec. inf. */
		else if (SvNV(fromstr) < -FLT_MAX)
		     afloat = _float_constants[0];   /* single prec. inf. */
		else afloat = (float)SvNV(fromstr);
#else
# if defined(VMS) && !defined(__IEEE_FP)
/* IEEE fp overflow shenanigans are unavailable on VAX and optional
 * on Alpha; fake it if we don't have them.
 */
		if (SvNV(fromstr) > FLT_MAX)
		     afloat = FLT_MAX;
		else if (SvNV(fromstr) < -FLT_MAX)
		     afloat = -FLT_MAX;
		else afloat = (float)SvNV(fromstr);
# else
		afloat = (float)SvNV(fromstr);
# endif
#endif
		DO_BO_PACK_N(afloat, float);
		sv_catpvn(cat, (char *)&afloat, sizeof (float));
	    }
	    break;
	case 'd':
	    while (len-- > 0) {
		fromstr = NEXTFROM;
#ifdef __VOS__
/* VOS does not automatically map a floating-point overflow
   during conversion from long double to double into infinity,
   so we do it by hand.  This code should either be generalized
   for any OS that needs it, or removed if and when VOS
   implements posix-976 (suggestion to support mapping to
   infinity).  Paul.Green@stratus.com 02-04-02.  */
		if (SvNV(fromstr) > DBL_MAX)
		     adouble = _double_constants[0];   /* double prec. inf. */
		else if (SvNV(fromstr) < -DBL_MAX)
		     adouble = _double_constants[0];   /* double prec. inf. */
		else adouble = (double)SvNV(fromstr);
#else
# if defined(VMS) && !defined(__IEEE_FP)
/* IEEE fp overflow shenanigans are unavailable on VAX and optional
 * on Alpha; fake it if we don't have them.
 */
		if (SvNV(fromstr) > DBL_MAX)
		     adouble = DBL_MAX;
		else if (SvNV(fromstr) < -DBL_MAX)
		     adouble = -DBL_MAX;
		else adouble = (double)SvNV(fromstr);
# else
		adouble = (double)SvNV(fromstr);
# endif
#endif
		DO_BO_PACK_N(adouble, double);
		sv_catpvn(cat, (char *)&adouble, sizeof (double));
	    }
	    break;
	case 'F':
	    Zero(&anv, 1, NV); /* can be long double with unused bits */
	    while (len-- > 0) {
		fromstr = NEXTFROM;
		anv = SvNV(fromstr);
		DO_BO_PACK_N(anv, NV);
		sv_catpvn(cat, (char *)&anv, NVSIZE);
	    }
	    break;
#if defined(HAS_LONG_DOUBLE) && defined(USE_LONG_DOUBLE)
	case 'D':
	    /* long doubles can have unused bits, which may be nonzero */
	    Zero(&aldouble, 1, long double);
	    while (len-- > 0) {
		fromstr = NEXTFROM;
		aldouble = (long double)SvNV(fromstr);
		DO_BO_PACK_N(aldouble, long double);
		sv_catpvn(cat, (char *)&aldouble, LONG_DOUBLESIZE);
	    }
	    break;
#endif
#ifdef PERL_PACK_CAN_SHRIEKSIGN
	case 'n' | TYPE_IS_SHRIEKING:
#endif
	case 'n':
	    while (len-- > 0) {
		fromstr = NEXTFROM;
		ai16 = (I16)SvIV(fromstr);
#ifdef HAS_HTONS
		ai16 = PerlSock_htons(ai16);
#endif
		CAT16(cat, &ai16);
	    }
	    break;
#ifdef PERL_PACK_CAN_SHRIEKSIGN
	case 'v' | TYPE_IS_SHRIEKING:
#endif
	case 'v':
	    while (len-- > 0) {
		fromstr = NEXTFROM;
		ai16 = (I16)SvIV(fromstr);
#ifdef HAS_HTOVS
		ai16 = htovs(ai16);
#endif
		CAT16(cat, &ai16);
	    }
	    break;
        case 'S' | TYPE_IS_SHRIEKING:
#if SHORTSIZE != SIZE16
	    {
		while (len-- > 0) {
		    fromstr = NEXTFROM;
		    aushort = SvUV(fromstr);
		    DO_BO_PACK(aushort, s);
		    sv_catpvn(cat, (char *)&aushort, sizeof(unsigned short));
		}
            }
            break;
#else
            /* Fall through! */
#endif
	case 'S':
            {
		while (len-- > 0) {
		    fromstr = NEXTFROM;
		    au16 = (U16)SvUV(fromstr);
		    DO_BO_PACK(au16, 16);
		    CAT16(cat, &au16);
		}

	    }
	    break;
	case 's' | TYPE_IS_SHRIEKING:
#if SHORTSIZE != SIZE16
	    {
		while (len-- > 0) {
		    fromstr = NEXTFROM;
		    ashort = SvIV(fromstr);
		    DO_BO_PACK(ashort, s);
		    sv_catpvn(cat, (char *)&ashort, sizeof(short));
		}
	    }
            break;
#else
            /* Fall through! */
#endif
	case 's':
	    while (len-- > 0) {
		fromstr = NEXTFROM;
		ai16 = (I16)SvIV(fromstr);
		DO_BO_PACK(ai16, 16);
		CAT16(cat, &ai16);
	    }
	    break;
	case 'I':
	case 'I' | TYPE_IS_SHRIEKING:
	    while (len-- > 0) {
		fromstr = NEXTFROM;
		auint = SvUV(fromstr);
		DO_BO_PACK(auint, i);
		sv_catpvn(cat, (char*)&auint, sizeof(unsigned int));
	    }
	    break;
	case 'j':
	    while (len-- > 0) {
		fromstr = NEXTFROM;
		aiv = SvIV(fromstr);
#if IVSIZE == INTSIZE
		DO_BO_PACK(aiv, i);
#elif IVSIZE == LONGSIZE
		DO_BO_PACK(aiv, l);
#elif defined(HAS_QUAD) && IVSIZE == U64SIZE
		DO_BO_PACK(aiv, 64);
#endif
		sv_catpvn(cat, (char*)&aiv, IVSIZE);
	    }
	    break;
	case 'J':
	    while (len-- > 0) {
		fromstr = NEXTFROM;
		auv = SvUV(fromstr);
#if UVSIZE == INTSIZE
		DO_BO_PACK(auv, i);
#elif UVSIZE == LONGSIZE
		DO_BO_PACK(auv, l);
#elif defined(HAS_QUAD) && UVSIZE == U64SIZE
		DO_BO_PACK(auv, 64);
#endif
		sv_catpvn(cat, (char*)&auv, UVSIZE);
	    }
	    break;
	case 'w':
            while (len-- > 0) {
		fromstr = NEXTFROM;
		anv = SvNV(fromstr);

		if (anv < 0)
		    Perl_croak(aTHX_ "Cannot compress negative numbers in pack");

                /* 0xFFFFFFFFFFFFFFFF may cast to 18446744073709551616.0,
                   which is == UV_MAX_P1. IOK is fine (instead of UV_only), as
                   any negative IVs will have already been got by the croak()
                   above. IOK is untrue for fractions, so we test them
                   against UV_MAX_P1.  */
		if (SvIOK(fromstr) || anv < UV_MAX_P1)
		{
		    char   buf[(sizeof(UV)*8)/7+1];
		    char  *in = buf + sizeof(buf);
		    UV     auv = SvUV(fromstr);

		    do {
			*--in = (char)((auv & 0x7f) | 0x80);
			auv >>= 7;
		    } while (auv);
		    buf[sizeof(buf) - 1] &= 0x7f; /* clear continue bit */
		    sv_catpvn(cat, in, (buf + sizeof(buf)) - in);
		}
		else if (SvPOKp(fromstr)) {  /* decimal string arithmetics */
		    char           *from, *result, *in;
		    SV             *norm;
		    STRLEN          len;
		    bool            done;

		    /* Copy string and check for compliance */
		    from = SvPV(fromstr, len);
		    if ((norm = is_an_int(from, len)) == NULL)
			Perl_croak(aTHX_ "Can only compress unsigned integers in pack");

		    New('w', result, len, char);
		    in = result + len;
		    done = FALSE;
		    while (!done)
			*--in = div128(norm, &done) | 0x80;
		    result[len - 1] &= 0x7F; /* clear continue bit */
		    sv_catpvn(cat, in, (result + len) - in);
		    Safefree(result);
		    SvREFCNT_dec(norm);	/* free norm */
                }
		else if (SvNOKp(fromstr)) {
		    /* 10**NV_MAX_10_EXP is the largest power of 10
		       so 10**(NV_MAX_10_EXP+1) is definately unrepresentable
		       given 10**(NV_MAX_10_EXP+1) == 128 ** x solve for x:
		       x = (NV_MAX_10_EXP+1) * log (10) / log (128)
		       And with that many bytes only Inf can overflow.
		       Some C compilers are strict about integral constant
		       expressions so we conservatively divide by a slightly
		       smaller integer instead of multiplying by the exact
		       floating-point value.
		    */
#ifdef NV_MAX_10_EXP
/*		    char   buf[1 + (int)((NV_MAX_10_EXP + 1) * 0.47456)]; -- invalid C */
		    char   buf[1 + (int)((NV_MAX_10_EXP + 1) / 2)]; /* valid C */
#else
/*		    char   buf[1 + (int)((308 + 1) * 0.47456)]; -- invalid C */
		    char   buf[1 + (int)((308 + 1) / 2)]; /* valid C */
#endif
		    char  *in = buf + sizeof(buf);

                    anv = Perl_floor(anv);
		    do {
			NV next = Perl_floor(anv / 128);
			if (in <= buf)  /* this cannot happen ;-) */
			    Perl_croak(aTHX_ "Cannot compress integer in pack");
			*--in = (unsigned char)(anv - (next * 128)) | 0x80;
			anv = next;
		    } while (anv > 0);
		    buf[sizeof(buf) - 1] &= 0x7f; /* clear continue bit */
		    sv_catpvn(cat, in, (buf + sizeof(buf)) - in);
		}
		else {
		    char           *from, *result, *in;
		    SV             *norm;
		    STRLEN          len;
		    bool            done;

		    /* Copy string and check for compliance */
		    from = SvPV(fromstr, len);
		    if ((norm = is_an_int(from, len)) == NULL)
			Perl_croak(aTHX_ "Can only compress unsigned integers in pack");

		    New('w', result, len, char);
		    in = result + len;
		    done = FALSE;
		    while (!done)
			*--in = div128(norm, &done) | 0x80;
		    result[len - 1] &= 0x7F; /* clear continue bit */
		    sv_catpvn(cat, in, (result + len) - in);
		    Safefree(result);
		    SvREFCNT_dec(norm);	/* free norm */
               }
	    }
            break;
	case 'i':
	case 'i' | TYPE_IS_SHRIEKING:
	    while (len-- > 0) {
		fromstr = NEXTFROM;
		aint = SvIV(fromstr);
		DO_BO_PACK(aint, i);
		sv_catpvn(cat, (char*)&aint, sizeof(int));
	    }
	    break;
#ifdef PERL_PACK_CAN_SHRIEKSIGN
	case 'N' | TYPE_IS_SHRIEKING:
#endif
	case 'N':
	    while (len-- > 0) {
		fromstr = NEXTFROM;
		au32 = SvUV(fromstr);
#ifdef HAS_HTONL
		au32 = PerlSock_htonl(au32);
#endif
		CAT32(cat, &au32);
	    }
	    break;
#ifdef PERL_PACK_CAN_SHRIEKSIGN
	case 'V' | TYPE_IS_SHRIEKING:
#endif
	case 'V':
	    while (len-- > 0) {
		fromstr = NEXTFROM;
		au32 = SvUV(fromstr);
#ifdef HAS_HTOVL
		au32 = htovl(au32);
#endif
		CAT32(cat, &au32);
	    }
	    break;
	case 'L' | TYPE_IS_SHRIEKING:
#if LONGSIZE != SIZE32
	    {
		while (len-- > 0) {
		    fromstr = NEXTFROM;
		    aulong = SvUV(fromstr);
		    DO_BO_PACK(aulong, l);
		    sv_catpvn(cat, (char *)&aulong, sizeof(unsigned long));
		}
	    }
	    break;
#else
            /* Fall though! */
#endif
	case 'L':
            {
		while (len-- > 0) {
		    fromstr = NEXTFROM;
		    au32 = SvUV(fromstr);
		    DO_BO_PACK(au32, 32);
		    CAT32(cat, &au32);
		}
	    }
	    break;
	case 'l' | TYPE_IS_SHRIEKING:
#if LONGSIZE != SIZE32
	    {
		while (len-- > 0) {
		    fromstr = NEXTFROM;
		    along = SvIV(fromstr);
		    DO_BO_PACK(along, l);
		    sv_catpvn(cat, (char *)&along, sizeof(long));
		}
	    }
	    break;
#else
            /* Fall though! */
#endif
	case 'l':
            while (len-- > 0) {
		fromstr = NEXTFROM;
		ai32 = SvIV(fromstr);
		DO_BO_PACK(ai32, 32);
		CAT32(cat, &ai32);
	    }
	    break;
#ifdef HAS_QUAD
	case 'Q':
	    while (len-- > 0) {
		fromstr = NEXTFROM;
		auquad = (Uquad_t)SvUV(fromstr);
		DO_BO_PACK(auquad, 64);
		sv_catpvn(cat, (char*)&auquad, sizeof(Uquad_t));
	    }
	    break;
	case 'q':
	    while (len-- > 0) {
		fromstr = NEXTFROM;
		aquad = (Quad_t)SvIV(fromstr);
		DO_BO_PACK(aquad, 64);
		sv_catpvn(cat, (char*)&aquad, sizeof(Quad_t));
	    }
	    break;
#endif
	case 'P':
	    len = 1;		/* assume SV is correct length */
	    /* Fall through! */
	case 'p':
	    while (len-- > 0) {
		fromstr = NEXTFROM;
		SvGETMAGIC(fromstr);
		if (!SvOK(fromstr)) aptr = NULL;
		else {
		    STRLEN n_a;
		    /* XXX better yet, could spirit away the string to
		     * a safe spot and hang on to it until the result
		     * of pack() (and all copies of the result) are
		     * gone.
		     */
		    if (ckWARN(WARN_PACK) && (SvTEMP(fromstr)
						|| (SvPADTMP(fromstr)
						    && !SvREADONLY(fromstr))))
		    {
			Perl_warner(aTHX_ packWARN(WARN_PACK),
				"Attempt to pack pointer to temporary value");
		    }
		    if (SvPOK(fromstr) || SvNIOK(fromstr))
			aptr = SvPV_flags(fromstr, n_a, 0);
		    else
			aptr = SvPV_force_flags(fromstr, n_a, 0);
		}
		DO_BO_PACK_P(aptr);
		sv_catpvn(cat, (char*)&aptr, sizeof(char*));
	    }
	    break;
	case 'u':
	    fromstr = NEXTFROM;
	    aptr = SvPV(fromstr, fromlen);
	    SvGROW(cat, fromlen * 4 / 3);
	    if (len <= 2)
		len = 45;
	    else
		len = len / 3 * 3;
	    while (fromlen > 0) {
		I32 todo;

		if ((I32)fromlen > len)
		    todo = len;
		else
		    todo = fromlen;
		doencodes(cat, aptr, todo);
		fromlen -= todo;
		aptr += todo;
	    }
	    break;
	}
	*symptr = lookahead;
    }
    return beglist;
}
#undef NEXTFROM


PP(pp_pack)
{
    dSP; dMARK; dORIGMARK; dTARGET;
    register SV *cat = TARG;
    STRLEN fromlen;
    register char *pat = SvPVx(*++MARK, fromlen);
    register char *patend = pat + fromlen;

    MARK++;
    sv_setpvn(cat, "", 0);

    packlist(cat, pat, patend, MARK, SP + 1);

    SvSETMAGIC(cat);
    SP = ORIGMARK;
    PUSHs(cat);
    RETURN;
}

/*
 * Local variables:
 * c-indentation-style: bsd
 * c-basic-offset: 4
 * indent-tabs-mode: t
 * End:
 *
 * vim: shiftwidth=4:
*/
