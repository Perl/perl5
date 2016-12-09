/* hash a key
 *--------------------------------------------------------------------------------------
 * The "hash seed" feature was added in Perl 5.8.1 to perturb the results
 * to avoid "algorithmic complexity attacks".
 *
 * If USE_HASH_SEED is defined, hash randomisation is done by default
 * If USE_HASH_SEED_EXPLICIT is defined, hash randomisation is done
 * only if the environment variable PERL_HASH_SEED is set.
 * (see also perl.c:perl_parse() and S_init_tls_and_interp() and util.c:get_hash_seed())
 */

#ifndef PERL_SEEN_HV_FUNC_H /* compile once */
#define PERL_SEEN_HV_FUNC_H

#if !( 0 \
        || defined(PERL_HASH_FUNC_SIPHASH) \
        || defined(PERL_HASH_FUNC_SIPHASH13) \
        || defined(PERL_HASH_FUNC_HYBRID_OAATHU_SIPHASH13) \
        || defined(PERL_HASH_FUNC_ONE_AT_A_TIME_HARD) \
    )
#if IVSIZE == 8
#define PERL_HASH_FUNC_HYBRID_OAATHU_SIPHASH13
#else
#define PERL_HASH_FUNC_ONE_AT_A_TIME_HARD
#endif
#endif

#if defined(PERL_HASH_FUNC_SIPHASH)
#   define PERL_HASH_FUNC "SIPHASH_2_4"
#   define PERL_HASH_SEED_BYTES 16
#   define PERL_HASH_WITH_SEED(seed,hash,str,len) (hash)= S_perl_hash_siphash_2_4((seed),(U8*)(str),(len))
#elif defined(PERL_HASH_FUNC_SIPHASH13)
#   define PERL_HASH_FUNC "SIPHASH_1_3"
#   define PERL_HASH_SEED_BYTES 16
#   define PERL_HASH_WITH_SEED(seed,hash,str,len) (hash)= S_perl_hash_siphash_1_3((seed),(U8*)(str),(len))
#elif defined(PERL_HASH_FUNC_HYBRID_OAATHU_SIPHASH13)
#   define PERL_HASH_FUNC "HYBRID_OAATHU_SIPHASH_1_3"
#   define PERL_HASH_SEED_BYTES 24
#   define PERL_HASH_WITH_SEED(seed,hash,str,len) (hash)= S_perl_hash_oaathu_siphash_1_3((seed),(U8*)(str),(len))
#elif defined(PERL_HASH_FUNC_ONE_AT_A_TIME_HARD)
#   define PERL_HASH_FUNC "ONE_AT_A_TIME_HARD"
#   define PERL_HASH_SEED_BYTES 8
#   define PERL_HASH_WITH_SEED(seed,hash,str,len) (hash)= S_perl_hash_one_at_a_time_hard((seed),(U8*)(str),(len))
#endif

#ifndef PERL_HASH_WITH_SEED
#error "No hash function defined!"
#endif
#ifndef PERL_HASH_SEED_BYTES
#error "PERL_HASH_SEED_BYTES not defined"
#endif
#ifndef PERL_HASH_FUNC
#error "PERL_HASH_FUNC not defined"
#endif

#ifndef PERL_HASH_SEED
#   if defined(USE_HASH_SEED) || defined(USE_HASH_SEED_EXPLICIT)
#       define PERL_HASH_SEED PL_hash_seed
#   elif PERL_HASH_SEED_BYTES == 4
#       define PERL_HASH_SEED ((const U8 *)"PeRl")
#   elif PERL_HASH_SEED_BYTES == 8
#       define PERL_HASH_SEED ((const U8 *)"PeRlHaSh")
#   elif PERL_HASH_SEED_BYTES == 16
#       define PERL_HASH_SEED ((const U8 *)"PeRlHaShhAcKpErl")
#   else
#       error "No PERL_HASH_SEED definition for " PERL_HASH_FUNC
#   endif
#endif

#define PERL_HASH(hash,str,len) PERL_HASH_WITH_SEED(PERL_HASH_SEED,hash,str,len)

/* legacy - only mod_perl should be doing this.  */
#ifdef PERL_HASH_INTERNAL_ACCESS
#define PERL_HASH_INTERNAL(hash,str,len) PERL_HASH(hash,str,len)
#endif

/*-----------------------------------------------------------------------------
 * Endianess, misalignment capabilities and util macros
 *
 * The following 3 macros are defined in this section. The other macros defined
 * are only needed to help derive these 3.
 *
 * U8TO32_LE(x)   Read a little endian unsigned 32-bit int
 * UNALIGNED_SAFE   Defined if unaligned access is safe
 * ROTL32(x,r)      Rotate x left by r bits
 */

#if (defined(__GNUC__) && defined(__i386__)) || defined(__WATCOMC__) \
  || defined(_MSC_VER) || defined (__TURBOC__)
#define U8TO16_LE(d) (*((const U16 *) (d)))
#endif

#if !defined (U8TO16_LE)
#define U8TO16_LE(d) ((((const U8 *)(d))[1] << 8)\
                      +((const U8 *)(d))[0])
#endif

#if (BYTEORDER == 0x1234 || BYTEORDER == 0x12345678) && U32SIZE == 4
  /* CPU endian matches murmurhash algorithm, so read 32-bit word directly */
  #define U8TO32_LE(ptr)   (*((const U32*)(ptr)))
#elif BYTEORDER == 0x4321 || BYTEORDER == 0x87654321
  /* TODO: Add additional cases below where a compiler provided bswap32 is available */
  #if defined(__GNUC__) && (__GNUC__>4 || (__GNUC__==4 && __GNUC_MINOR__>=3))
    #define U8TO32_LE(ptr)   (__builtin_bswap32(*((U32*)(ptr))))
  #else
    /* Without a known fast bswap32 we're just as well off doing this */
    #define U8TO32_LE(ptr)   (ptr[0]|ptr[1]<<8|ptr[2]<<16|ptr[3]<<24)
    #define UNALIGNED_SAFE
  #endif
#else
  /* Unknown endianess so last resort is to read individual bytes */
  #define U8TO32_LE(ptr)   (ptr[0]|ptr[1]<<8|ptr[2]<<16|ptr[3]<<24)
  /* Since we're not doing word-reads we can skip the messing about with realignment */
  #define UNALIGNED_SAFE
#endif

#ifdef HAS_QUAD
#ifndef U64TYPE
/* This probably isn't going to work, but failing with a compiler error due to
   lack of uint64_t is no worse than failing right now with an #error.  */
#define U64 uint64_t
#endif
#endif

/* Find best way to ROTL32/ROTL64 */
#if defined(_MSC_VER)
  #include <stdlib.h>  /* Microsoft put _rotl declaration in here */
  #define ROTL32(x,r)  _rotl(x,r)
  #ifdef HAS_QUAD
    #define ROTL64(x,r)  _rotl64(x,r)
  #endif
#else
  /* gcc recognises this code and generates a rotate instruction for CPUs with one */
  #define ROTL32(x,r)  (((U32)x << r) | ((U32)x >> (32 - r)))
  #ifdef HAS_QUAD
    #define ROTL64(x,r)  (((U64)x << r) | ((U64)x >> (64 - r)))
  #endif
#endif


#ifdef UV_IS_QUAD
#define ROTL_UV(x,r) ROTL64(x,r)
#else
#define ROTL_UV(x,r) ROTL32(x,r)
#endif

/* This is SipHash by Jean-Philippe Aumasson and Daniel J. Bernstein.
 * The authors claim it is relatively secure compared to the alternatives
 * and that performance wise it is a suitable hash for languages like Perl.
 * See:
 *
 * https://www.131002.net/siphash/
 *
 * This implementation seems to perform slightly slower than one-at-a-time for
 * short keys, but degrades slower for longer keys. Murmur Hash outperforms it
 * regardless of keys size.
 *
 * It is 64 bit only.
 */

#ifdef HAS_QUAD

#define U8TO64_LE(p) \
  (((U64)((p)[0])      ) | \
   ((U64)((p)[1]) <<  8) | \
   ((U64)((p)[2]) << 16) | \
   ((U64)((p)[3]) << 24) | \
   ((U64)((p)[4]) << 32) | \
   ((U64)((p)[5]) << 40) | \
   ((U64)((p)[6]) << 48) | \
   ((U64)((p)[7]) << 56))

#define SIPROUND            \
  STMT_START {              \
    v0 += v1; v1=ROTL64(v1,13); v1 ^= v0; v0=ROTL64(v0,32); \
    v2 += v3; v3=ROTL64(v3,16); v3 ^= v2;     \
    v0 += v3; v3=ROTL64(v3,21); v3 ^= v0;     \
    v2 += v1; v1=ROTL64(v1,17); v1 ^= v2; v2=ROTL64(v2,32); \
  } STMT_END

/* SipHash-2-4 */


#define PERL_SIPHASH_FNC(FNC,SIP_ROUNDS,SIP_FINAL_ROUNDS) \
PERL_STATIC_INLINE U32 \
FNC(const unsigned char * const seed, const unsigned char *in, const STRLEN inlen) { \
  /* "somepseudorandomlygeneratedbytes" */  \
  U64 v0 = UINT64_C(0x736f6d6570736575);    \
  U64 v1 = UINT64_C(0x646f72616e646f6d);    \
  U64 v2 = UINT64_C(0x6c7967656e657261);    \
  U64 v3 = UINT64_C(0x7465646279746573);    \
                                            \
  U64 b;                                    \
  U64 k0 = ((const U64*)seed)[0];           \
  U64 k1 = ((const U64*)seed)[1];           \
  U64 m;                                    \
  const int left = inlen & 7;               \
  const U8 *end = in + inlen - left;        \
                                            \
  b = ( ( U64 )(inlen) ) << 56;             \
  v3 ^= k1;                                 \
  v2 ^= k0;                                 \
  v1 ^= k1;                                 \
  v0 ^= k0;                                 \
                                            \
  for ( ; in != end; in += 8 )              \
  {                                         \
    m = U8TO64_LE( in );                    \
    v3 ^= m;                                \
                                            \
    SIP_ROUNDS;                             \
                                            \
    v0 ^= m;                                \
  }                                         \
                                            \
  switch( left )                            \
  {                                         \
  case 7: b |= ( ( U64 )in[ 6] )  << 48;    \
  case 6: b |= ( ( U64 )in[ 5] )  << 40;    \
  case 5: b |= ( ( U64 )in[ 4] )  << 32;    \
  case 4: b |= ( ( U64 )in[ 3] )  << 24;    \
  case 3: b |= ( ( U64 )in[ 2] )  << 16;    \
  case 2: b |= ( ( U64 )in[ 1] )  <<  8;    \
  case 1: b |= ( ( U64 )in[ 0] ); break;    \
  case 0: break;                            \
  }                                         \
                                            \
  v3 ^= b;                                  \
                                            \
  SIP_ROUNDS;                               \
                                            \
  v0 ^= b;                                  \
                                            \
  v2 ^= 0xff;                               \
                                            \
  SIP_FINAL_ROUNDS                          \
                                            \
  b = v0 ^ v1 ^ v2  ^ v3;                   \
  return (U32)(b & U32_MAX);                \
}

PERL_SIPHASH_FNC(
    S_perl_hash_siphash_1_3
    ,SIPROUND;
    ,SIPROUND;SIPROUND;SIPROUND;
)

PERL_SIPHASH_FNC(
    S_perl_hash_siphash_2_4
    ,SIPROUND;SIPROUND;
    ,SIPROUND;SIPROUND;SIPROUND;SIPROUND;
)

#endif /* defined(HAS_QUAD) */

/* - ONE_AT_A_TIME_HARD is the 5.17+ recommend ONE_AT_A_TIME variant */

/* This is derived from the "One-at-a-Time" algorithm by Bob Jenkins
 * from requirements by Colin Plumb.
 * (http://burtleburtle.net/bob/hash/doobs.html)
 * Modified by Yves Orton to increase security for Perl 5.17 and later.
 */
PERL_STATIC_INLINE U32
S_perl_hash_one_at_a_time_hard(const unsigned char * const seed, const unsigned char *str, const STRLEN len) {
    const unsigned char * const end = (const unsigned char *)str + len;
    U32 hash = *((const U32*)seed) + (U32)len;
    
    while (str < end) {
        hash += (hash << 10);
        hash ^= (hash >> 6);
        hash += *str++;
    }
    
    hash += (hash << 10);
    hash ^= (hash >> 6);
    hash += seed[4];
    
    hash += (hash << 10);
    hash ^= (hash >> 6);
    hash += seed[5];
    
    hash += (hash << 10);
    hash ^= (hash >> 6);
    hash += seed[6];
    
    hash += (hash << 10);
    hash ^= (hash >> 6);
    hash += seed[7];
    
    hash += (hash << 10);
    hash ^= (hash >> 6);

    hash += (hash << 3);
    hash ^= (hash >> 11);
    return (hash + (hash << 15));
}

#ifdef HAS_QUAD

/* Hybrid hash function
 *
 * For short strings, 16 bytes or shorter, we use an optimised variant
 * of One At A Time Hard, and for longer strings, we use siphash_1_3.
 *
 * The optimisation of One At A Time Hard means we read the key in
 * reverse from normal, but by doing so we avoid the loop overhead.
 */
PERL_STATIC_INLINE U32
S_perl_hash_oaathu_siphash_1_3(const unsigned char * const seed, const unsigned char *str, const STRLEN len) {
    U32 hash = *((const U32*)seed) + (U32)len;
    switch (len) {
        case 16:
            hash += (hash << 10);
            hash ^= (hash >> 6);
            hash += str[15];
        case 15:
            hash += (hash << 10);
            hash ^= (hash >> 6);
            hash += str[14];
        case 14:
            hash += (hash << 10);
            hash ^= (hash >> 6);
            hash += str[13];
        case 13:
            hash += (hash << 10);
            hash ^= (hash >> 6);
            hash += str[12];
        case 12:
            hash += (hash << 10);
            hash ^= (hash >> 6);
            hash += str[11];
        case 11:
            hash += (hash << 10);
            hash ^= (hash >> 6);
            hash += str[10];
        case 10:
            hash += (hash << 10);
            hash ^= (hash >> 6);
            hash += str[9];
        case 9:
            hash += (hash << 10);
            hash ^= (hash >> 6);
            hash += str[8];
        case 8:
            hash += (hash << 10);
            hash ^= (hash >> 6);
            hash += str[7];
        case 7:
            hash += (hash << 10);
            hash ^= (hash >> 6);
            hash += str[6];
        case 6:
            hash += (hash << 10);
            hash ^= (hash >> 6);
            hash += str[5];
        case 5:
            hash += (hash << 10);
            hash ^= (hash >> 6);
            hash += str[4];
        case 4:
            hash += (hash << 10);
            hash ^= (hash >> 6);
            hash += str[3];
        case 3:
            hash += (hash << 10);
            hash ^= (hash >> 6);
            hash += str[2];
        case 2:
            hash += (hash << 10);
            hash ^= (hash >> 6);
            hash += str[1];
        case 1:
            hash += (hash << 10);
            hash ^= (hash >> 6);
            hash += str[0];
        case 0:
            hash += (hash << 10);
            hash ^= (hash >> 6);
            hash += seed[4];
            hash += (hash << 10);
            hash ^= (hash >> 6);
            hash += seed[5];
            hash += (hash << 10);
            hash ^= (hash >> 6);
            hash += seed[6];
            hash += (hash << 10);
            hash ^= (hash >> 6);
            hash += seed[7];
            hash += (hash << 10);
            hash ^= (hash >> 6);

            hash += (hash << 3);
            hash ^= (hash >> 11);
            return (hash + (hash << 15));
    }
    return S_perl_hash_siphash_1_3(seed+8, str, len);
}
#endif /* defined(HAS_QUAD) */


#endif /*compile once*/

/*
 * ex: set ts=8 sts=4 sw=4 et:
 */
