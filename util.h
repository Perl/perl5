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

#ifdef PERL_RNG_TINYMT32
/* see copyright in util.c */

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

#elif defined(PERL_RNG_WELLRNG512A)
/* see copyright in util.c */
#define WELLRNG_W 32
#define WELLRNG_R 16
#define WELLRNG_P 0
#define WELLRNG_M1 13
#define WELLRNG_M2 9
#define WELLRNG_M3 5

#define WELLRNG_K1 15
#define WELLRNG_K2 14

#define WELLRNG_MAT0POS(t,v)   ( v ^ ( v >> t ) )
#define WELLRNG_MAT0NEG(t,v)   ( v ^ ( v << ( -(t) ) ) )
#define WELLRNG_MAT3NEG(t,v)   ( v << ( -(t) ) )
#define WELLRNG_MAT4NEG(t,b,v) ( v ^ ( ( v << ( -(t) ) ) & b ) )

#define WELLRNG_V0            PL_random_state.STATE[ PL_random_state.state_i                             ]
#define WELLRNG_VM1           PL_random_state.STATE[(PL_random_state.state_i + WELLRNG_M1) & 0x0000000fU ]
#define WELLRNG_VM2           PL_random_state.STATE[(PL_random_state.state_i + WELLRNG_M2) & 0x0000000fU ]
#define WELLRNG_VM3           PL_random_state.STATE[(PL_random_state.state_i + WELLRNG_M3) & 0x0000000fU ]
#define WELLRNG_VRm1          PL_random_state.STATE[(PL_random_state.state_i + WELLRNG_K1) & 0x0000000fU ]
#define WELLRNG_VRm2          PL_random_state.STATE[(PL_random_state.state_i + WELLRNG_K2) & 0x0000000fU ]
#define WELLRNG_newV0         PL_random_state.STATE[(PL_random_state.state_i + WELLRNG_K1) & 0x0000000fU ]
#define WELLRNG_newV1         PL_random_state.STATE[ PL_random_state.state_i                             ]
#define WELLRNG_newVRm1       PL_random_state.STATE[(PL_random_state.state_i + WELLRNG_K2) & 0x0000000fU ]

#define WELLRNG_FACT 2.32830643653869628906e-10

struct WELLRNG512A_T {
    U32 state_i;
    U32 STATE[WELLRNG_R];
};
typedef struct WELLRNG512A_T wellring512a_t;

#define PL_RANDOM_STATE_TYPE wellring512a_t
#define _SEED_RAND(x) wellrng512a_init((U32)x)
#define RAND01() wellrng512a_generate_double()

#elif defined(PERL_RNG_FREEBSD_DRAND48)
/* see copyright in util.c */
#include <math.h>
#include <stdlib.h>

#define FREEBSD_DRAND48_SEED_0   (0x330e)
#define FREEBSD_DRAND48_SEED_1   (0xabcd)
#define FREEBSD_DRAND48_SEED_2   (0x1234)
#define FREEBSD_DRAND48_MULT_0   (0xe66d)
#define FREEBSD_DRAND48_MULT_1   (0xdeec)
#define FREEBSD_DRAND48_MULT_2   (0x0005)
#define FREEBSD_DRAND48_ADD      (0x000b)

struct FREEBSD_DRAND48_T {
    U16 seed[3];
};

typedef struct FREEBSD_DRAND48_T freebsd_drand48_t;

#define PL_RANDOM_STATE_TYPE freebsd_drand48_t
#define _SEED_RAND(x) freebsd_drand48_init((U32)x)
#define RAND01() freebsd_drand48_generate_double()

#else /* dont use tinymt32 or wellrng512a */

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
