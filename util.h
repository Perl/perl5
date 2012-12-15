/*    util.h
 *
 *    Copyright (C) 1991, 1992, 1993, 1999, 2001, 2002, 2003, 2004, 2005,
 *    2007, by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 */

#ifdef VMS
#  define PERL_FILE_IS_ABSOLUTE(f) \
	(*(f) == '/'							\
	 || (strchr(f,':')						\
	     || ((*(f) == '[' || *(f) == '<')				\
		 && (isALNUM((f)[1]) || strchr("$-_]>",(f)[1])))))

#else		/* !VMS */
#  if defined(WIN32) || defined(__CYGWIN__)
#    define PERL_FILE_IS_ABSOLUTE(f) \
	(*(f) == '/' || *(f) == '\\'		/* UNC/rooted path */	\
	 || ((f)[0] && (f)[1] == ':'))		/* drive name */
#  else		/* !WIN32 */
#  ifdef NETWARE
#    define PERL_FILE_IS_ABSOLUTE(f) \
	(((f)[0] && (f)[1] == ':')		/* drive name */	\
	 || ((f)[0] == '\\' && (f)[1] == '\\')	/* UNC path */	\
	 ||	((f)[3] == ':'))				/* volume name, currently only sys */
#  else		/* !NETWARE */
#    if defined(DOSISH) || defined(__SYMBIAN32__)
#      define PERL_FILE_IS_ABSOLUTE(f) \
	(*(f) == '/'							\
	 || ((f)[0] && (f)[1] == ':'))		/* drive name */
#    else	/* NEITHER DOSISH NOR SYMBIANISH */
#      define PERL_FILE_IS_ABSOLUTE(f)	(*(f) == '/')
#    endif	/* DOSISH */
#   endif	/* NETWARE */
#  endif	/* WIN32 */
#endif		/* VMS */

/*
=for apidoc ibcmp

This is a synonym for (! foldEQ())

=for apidoc ibcmp_locale

This is a synonym for (! foldEQ_locale())

=cut
*/
#define ibcmp(s1, s2, len)         cBOOL(! foldEQ(s1, s2, len))
#define ibcmp_locale(s1, s2, len)  cBOOL(! foldEQ_locale(s1, s2, len))

#ifdef TINYMT32

#define TINYMT32_MEXP 127
#define TINYMT32_SH0 1
#define TINYMT32_SH1 10
#define TINYMT32_SH8 8
#define TINYMT32_MASK 0x7fffffffUL
#define TINYMT32_MUL (1.0f / 4294967296.0f)
#define TINYMT32_MIN_LOOP 8
#define TINYMT32_PRE_LOOP 8

/**
 * tinymt32 internal state vector and parameters
 */
struct TINYMT32_T {
    U32 status[4];
    U32 mat1;
    U32 mat2;
    U32 tmat;
};

typedef struct TINYMT32_T tinymt32_t;

#define PL_RANDOM_STATE_TYPE tinymt32_t

#define _SEED_RAND(x) tinymt32_init((U32)x)
#define RAND01() tinymt32_generate_double()

#else /* dont use tinymt32 */

#define _SEED_RAND(x) (void)seedDrand01((Rand_seed_t)x)
#define RAND01() Drand01()
/* PL_RANDOM_STATE_TYPE not defined here as it is not used in this configuration */

#endif

#define SEED_RAND(x) STMT_START { \
    _SEED_RAND(x); \
    PL_srand_called = TRUE; \
} STMT_END

/*
 * Local variables:
 * c-indentation-style: bsd
 * c-basic-offset: 4
 * indent-tabs-mode: nil
 * End:
 *
 * ex: set ts=8 sts=4 sw=4 et:
 */
