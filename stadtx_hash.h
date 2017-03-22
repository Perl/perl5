#ifndef STADTX_HASH_H
#define STADTX_HASH_H

#ifndef DEBUG_STADTX_HASH
#define DEBUG_STADTX_HASH 0
#endif


#ifndef ROTL64
#define _ROTL_SIZED(x,r,s) ( ((x) << (r)) | ((x) >> ((s) - (r))) )
#define _ROTR_SIZED(x,r,s) ( ((x) << ((s) - (r))) | ((x) >> (r)) )
#define ROTL64(x,r) _ROTL_SIZED(x,r,64)
#define ROTR64(x,r) _ROTR_SIZED(x,r,64)
#endif

#ifndef PERL_SEEN_HV_FUNC_H

#if !defined(U64)
    #include <stdint.h>
    #define U64 uint64_t
#endif

#if !defined(U32)
  #define U32 uint32_t
#endif

#if !defined(U8)
    #define U8 unsigned char
#endif

#if !defined(U16)
    #define U16 uint16_t
#endif

#ifndef STRLEN
#define STRLEN int
#endif
#endif

#ifndef STADTX_STATIC_INLINE
#ifdef PERL_STATIC_INLINE
#define STADTX_STATIC_INLINE PERL_STATIC_INLINE
#else
#define STADTX_STATIC_INLINE static inline
#endif
#endif

#ifndef STMT_START
#define STMT_START do
#define STMT_END while(0)
#endif

#ifndef STADTX_UNALIGNED_AND_LITTLE_ENDIAN
#define STADTX_UNALIGNED_AND_LITTLE_ENDIAN 1
#endif

#if STADTX_ALLOW_UNALIGNED_AND_LITTLE_ENDIAN
  #ifndef U8TO64_LE
    #define U8TO64_LE(ptr)  (*((const U64 *)(ptr)))
  #endif
  #ifndef U8TO32_LE
    #define U8TO32_LE(ptr)  (*((const U32 *)(ptr)))
  #endif
  #ifndef U8TO16_LE
    #define U8TO16_LE(ptr)  (*((const U16 *)(ptr)))
  #endif
#else
  #ifndef U8TO64_LE
    #define U8TO64_LE(ptr)  (\
        (U64)(ptr)[7] << 56 | \
        (U64)(ptr)[6] << 48 | \
        (U64)(ptr)[5] << 40 | \
        (U64)(ptr)[4] << 32 | \
        (U64)(ptr)[3] << 24 | \
        (U64)(ptr)[2] << 16 | \
        (U64)(ptr)[1] << 8  | \
        (U64)(ptr)[0]         \
    )
  #endif
  #ifndef U8TO32_LE
    #define U8TO32_LE(ptr)  (\
        (U32)(ptr)[3] << 24 | \
        (U32)(ptr)[2] << 16 | \
        (U32)(ptr)[1] << 8  | \
        (U32)(ptr)[0]         \
    )
  #endif
  #ifndef U8TO16_LE
    #define U8TO16_LE(ptr)  (\
        (U16)(ptr)[1] << 8  | \
        (U16)(ptr)[0]         \
    )
  #endif
#endif

/* do a marsaglia xor-shift permutation followed by a
 * multiply by a prime (presumably large) and another
 * marsaglia xor-shift permutation.
 * One of these thoroughly changes the bits of the input.
 * Two of these with different primes passes the Strict Avalanche Criteria
 * in all the tests I did.
 *
 * Note that v cannot end up zero after a scramble64 unless it
 * was zero in the first place.
 */
#define STADTX_SCRAMBLE64(v,prime) STMT_START {    \
    v ^= (v >> 13);                         \
    v ^= (v << 35);                         \
    v ^= (v >> 30);                         \
    v *= prime;                             \
    v ^= (v >> 19);                         \
    v ^= (v << 15);                         \
    v ^= (v >> 46);                         \
} STMT_END


STADTX_STATIC_INLINE void stadtx_seed_state (
    const U8 *seed_ch,
    U8 *state_ch
) {
    U64 *seed= (U64 *)seed_ch;
    U64 *state= (U64 *)state_ch;
    /* first we apply two masks to each word of the seed, this means that
     * a) at least one of state[0] and state[2] is nonzero,
     * b) at least one of state[1] and state[3] is nonzero
     * c) that state[0] and state[2] are different
     * d) that state[1] and state[3] are different
     * e) that the replacement value for any zero's is a totally different from the seed value.
     *    (iow, if seed[0] is 0x43f6a8885a308d31UL then state[0] becomes 0, which is the replaced
     *    with 1, which is totally different.). */
    /* hex expansion of pi, skipping first two digits. pi= 3.2[43f6...]*/
    /* pi value in hex from here:
     * http://turner.faculty.swau.edu/mathematics/materialslibrary/pi/pibases.html*/
    state[0]= seed[0] ^ 0x43f6a8885a308d31UL;
    state[1]= seed[1] ^ 0x3198a2e03707344aUL;
    state[2]= seed[0] ^ 0x4093822299f31d00UL;
    state[3]= seed[1] ^ 0x82efa98ec4e6c894UL;
    if (!state[0]) state[0]=1;
    if (!state[1]) state[1]=2;
    if (!state[2]) state[2]=4;
    if (!state[3]) state[3]=8;
    /* and now for good measure we double scramble all four -
     * a double scramble guarantees a complete avalanche of all the
     * bits in the seed - IOW, by the time we are hashing the
     * four state vectors should be completely different and utterly
     * uncognizable from the input seed bits */
    STADTX_SCRAMBLE64(state[0],0x801178846e899d17UL);
    STADTX_SCRAMBLE64(state[0],0xdd51e5d1c9a5a151UL);
    STADTX_SCRAMBLE64(state[1],0x93a7d6c8c62e4835UL);
    STADTX_SCRAMBLE64(state[1],0x803340f36895c2b5UL);
    STADTX_SCRAMBLE64(state[2],0xbea9344eb7565eebUL);
    STADTX_SCRAMBLE64(state[2],0xcd95d1e509b995cdUL);
    STADTX_SCRAMBLE64(state[3],0x9999791977e30c13UL);
    STADTX_SCRAMBLE64(state[3],0xaab8b6b05abfc6cdUL);
}

#define STADTX_K0_U64 0xb89b0f8e1655514fUL
#define STADTX_K1_U64 0x8c6f736011bd5127UL
#define STADTX_K2_U64 0x8f29bd94edce7b39UL
#define STADTX_K3_U64 0x9c1b8e1e9628323fUL

#define STADTX_K2_U32 0x802910e3
#define STADTX_K3_U32 0x819b13af
#define STADTX_K4_U32 0x91cb27e5
#define STADTX_K5_U32 0xc1a269c1

STADTX_STATIC_INLINE U64 stadtx_hash_with_state(
    const U8 *state_ch,
    const U8 *key,
    const STRLEN key_len
) {
    U64 *state= (U64 *)state_ch;
    U64 len = key_len;
    U64 v0= state[0] ^ ((key_len+1) * STADTX_K0_U64);
    U64 v1= state[1] ^ ((key_len+2) * STADTX_K1_U64);
    if (len < 32) {
        switch(len >> 3) {
            case 3:
            v0 += U8TO64_LE(key) * STADTX_K3_U64;
            v0= ROTR64(v0, 17) ^ v1;
            v1= ROTR64(v1, 53) + v0;
            key += 8;
            case 2:
            v0 += U8TO64_LE(key) * STADTX_K3_U64;
            v0= ROTR64(v0, 17) ^ v1;
            v1= ROTR64(v1, 53) + v0;
            key += 8;
            case 1:
            v0 += U8TO64_LE(key) * STADTX_K3_U64;
            v0= ROTR64(v0, 17) ^ v1;
            v1= ROTR64(v1, 53) + v0;
            key += 8;
            case 0:
            default: break;
        }
        switch ( len & 0x7 ) {
            case 7: v0 += (U64)key[6] << 32;
            case 6: v1 += (U64)key[5] << 48;
            case 5: v0 += (U64)key[4] << 16;
            case 4: v1 += (U64)U8TO32_LE(key);
                    break;
            case 3: v0 += (U64)key[2] << 48;
            case 2: v1 += (U64)U8TO16_LE(key);
                    break;
            case 1: v0 += (U64)key[0];
            case 0: v1 = ROTL64(v1, 32) ^ 0xFF;
                    break;
        }
        v1 ^= v0;
        v0 = ROTR64(v0,33) + v1;
        v1 = ROTL64(v1,17) ^ v0;
        v0 = ROTL64(v0,43) + v1;
        v1 = ROTL64(v1,31) - v0;
        v0 = ROTL64(v0,13) ^ v1;
        v1 -= v0;
        v0 = ROTL64(v0,41) + v1;
        v1 = ROTL64(v1,37) ^ v0;
        v0 = ROTR64(v0,39) + v1;
        v1 = ROTR64(v1,15) + v0;
        v0 = ROTL64(v0,15) ^ v1;
        v1 = ROTR64(v1, 5);
        return v0 ^ v1;
    } else {
        U64 v2= state[2] ^ ((key_len+3) * STADTX_K2_U64);
        U64 v3= state[3] ^ ((key_len+4) * STADTX_K3_U64);

        do {
            v0 += (U64)U8TO64_LE(key+ 0) * STADTX_K2_U32; v0= ROTL64(v0,57) ^ v3;
            v1 += (U64)U8TO64_LE(key+ 8) * STADTX_K3_U32; v1= ROTL64(v1,63) ^ v2;
            v2 += (U64)U8TO64_LE(key+16) * STADTX_K4_U32; v2= ROTR64(v2,47) + v0;
            v3 += (U64)U8TO64_LE(key+24) * STADTX_K5_U32; v3= ROTR64(v3,11) - v1;
            key += 32;
            len -= 32;
        } while ( len >= 32 );

        switch ( len >> 3 ) {
            case 3: v0 += ((U64)U8TO64_LE(key) * STADTX_K2_U32); key += 8; v0= ROTL64(v0,57) ^ v3;
            case 2: v1 += ((U64)U8TO64_LE(key) * STADTX_K3_U32); key += 8; v1= ROTL64(v1,63) ^ v2;
            case 1: v2 += ((U64)U8TO64_LE(key) * STADTX_K4_U32); key += 8; v2= ROTR64(v2,47) + v0;
            case 0: v3 = ROTR64(v3,11) - v1;
        }
        v0 ^= (len+1) * STADTX_K3_U64;
        switch ( len & 0x7 ) {
            case 7: v1 += (U64)key[6];
            case 6: v2 += (U64)U8TO16_LE(key+4);
                    v3 += (U64)U8TO32_LE(key);
                    break;
            case 5: v1 += (U64)key[4];
            case 4: v2 += (U64)U8TO32_LE(key);
                    break;
            case 3: v3 += (U64)key[2];
            case 2: v1 += (U64)U8TO16_LE(key);
                    break;
            case 1: v2 += (U64)key[0];
            case 0: v3 = ROTL64(v3, 32) ^ 0xFF;
                    break;
        }

        v1 -= v2;
        v0 = ROTR64(v0,19);
        v1 -= v0;
        v1 = ROTR64(v1,53);
        v3 ^= v1;
        v0 -= v3;
        v3 = ROTL64(v3,43);
        v0 += v3;
        v0 = ROTR64(v0, 3);
        v3 -= v0;
        v2 = ROTR64(v2,43) - v3;
        v2 = ROTL64(v2,55) ^ v0;
        v1 -= v2;
        v3 = ROTR64(v3, 7) - v2;
        v2 = ROTR64(v2,31);
        v3 += v2;
        v2 -= v1;
        v3 = ROTR64(v3,39);
        v2 ^= v3;
        v3 = ROTR64(v3,17) ^ v2;
        v1 += v3;
        v1 = ROTR64(v1, 9);
        v2 ^= v1;
        v2 = ROTL64(v2,24);
        v3 ^= v2;
        v3 = ROTR64(v3,59);
        v0 = ROTR64(v0, 1) - v1;

        return v0 ^ v1 ^ v2 ^ v3;
    }
}

STADTX_STATIC_INLINE U64 stadtx_hash(
    const U8 *seed_ch,
    const U8 *key,
    const STRLEN key_len
) {
    U64 state[4];
    stadtx_seed_state(seed_ch,(U8*)state);
    return stadtx_hash_with_state((U8*)state,key,key_len);
}

#endif
