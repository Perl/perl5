#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef I_SYS_RANDOM
#  include <sys/random.h>
#endif

#ifdef MSWIN32
#  include <windows.h>
#  include <bcrypt.h>
#endif

/* The same 48-bit linear-congruential generator used by Perl's default
 * drand48 implementation.  Keeping the state in a scalar reference makes
 * this provider obey the same object-level protocol as the other bundled
 * providers while allowing its native-word callback to be benchmarked. */
typedef struct {
    U64 state;
} rng_drand48_data;

#define DRAND48_MULT UINT64_C(0x5deece66d)
#define DRAND48_ADD  UINT64_C(0xb)
#define DRAND48_MASK UINT64_C(0xffffffffffff)
#define DRAND48_SEED_0 UINT64_C(0x330e)

static const char drand48_zero_state[sizeof(rng_drand48_data)] = { 0 };

static rng_drand48_data *
drand48_state(pTHX_ SV *self)
{
    SV *state;

    if (!SvROK(self) || !SvPOK(state = SvRV(self)))
        croak("RNG::Drand48 object does not contain a valid state");
    if (SvCUR(state) != sizeof(rng_drand48_data))
        croak("RNG::Drand48 object does not contain a valid state");
    return (rng_drand48_data *)SvPVX(state);
}

static rng_drand48_data *
drand48_state_fast(SV *self)
{
    return (rng_drand48_data *)SvPVX(SvRV(self));
}

static U64
drand48_next(rng_drand48_data *value)
{
    value->state = (value->state * DRAND48_MULT + DRAND48_ADD)
                 & DRAND48_MASK;
    return value->state;
}

static void
drand48_seed(rng_drand48_data *value, SV *seed)
{
    const U64 numeric = seed && SvOK(seed) ? (U64)SvUV(seed) : 0;
    value->state = DRAND48_SEED_0 + (numeric << 16);
}

static U32
drand48_next_u32(rng_drand48_data *state)
{
    return (U32)(drand48_next(state) >> 16);
}

static void
drand48_fill_bytes(rng_drand48_data *state, STRLEN length, U8 *bytes)
{
    U32 word;
    STRLEN offset;
    unsigned int i;

    for (offset = 0; offset < length; ) {
        word = drand48_next_u32(state);
        for (i = 0; i < 4 && offset < length; i++)
            bytes[offset++] = (U8)(word >> (24 - 8 * i));
    }
}

static U64
drand48_u64_fast(pTHX_ void *state)
{
    rng_drand48_data * const value = (rng_drand48_data *)state;
    return ((U64)drand48_next_u32(value) << 32) | drand48_next_u32(value);
}

/*
 * This is the two-dimensional PCG-XSH-RR construction.  The base
 * generator has 64 bits of state and produces 32-bit values.  Two extra
 * 32-bit values form the extension array, giving the complete generator
 * 128 bits of state without requiring 128-bit arithmetic.
 */
typedef struct {
    U64 state;
    U32 extension[2];
    U64 initial;
} pcg_data;

#define PCG_MULTIPLIER UINT64_C(0x5851f42d4c957f2d)
#define PCG_INCREMENT  UINT64_C(0x14057b7ef767814f)

/* SvPVbyte_force() was added after the oldest Perl versions supported by
 * this bundled distribution.  Older Perls do not have UTF-8 scalar flags, so
 * SvPV_force() is the equivalent operation there. */
#ifndef SvPVbyte_force
#  define SvPVbyte_force(sv, len) SvPV_force(sv, len)
#endif

static const U8 pcg_seed_key_13[] = "Perl PCG seed 13";
static const U8 pcg_seed_key_24[] = "Perl PCG seed 24";

static const char pcg_zero_state[sizeof(pcg_data)] = { 0 };

static pcg_data *
pcg_state(pTHX_ SV *self)
{
    SV *state;

    if (!SvROK(self) || !SvPOK(state = SvRV(self)))
        croak("RNG::PCG object does not contain a valid state");
    if (SvCUR(state) != sizeof(pcg_data))
        croak("RNG::PCG object does not contain a valid state");

    /* The PV is the live state object.  It is deliberately accessed in place
     * rather than copied into a temporary pcg_data on every draw. */
    return (pcg_data *)SvPVX(state);
}

static pcg_data *
pcg_state_fast(SV *self)
{
    return (pcg_data *)SvPVX(SvRV(self));
}

static U32
pcg_next_data(pcg_data *value)
{
    const U64 oldstate = value->state;
    const U32 xorshifted = (U32)(((oldstate >> 18) ^ oldstate) >> 27);
    const unsigned int rot = (unsigned int)(oldstate >> 59);
    U32 result = (xorshifted >> rot)
               | (xorshifted << ((-rot) & 31));

    value->state = oldstate * PCG_MULTIPLIER + PCG_INCREMENT;
    result ^= value->extension[oldstate & 1];

    if (value->state == value->initial) {
        if (++value->extension[0] == 0)
            ++value->extension[1];
    }

    return result;
}

static U64
pcg_next_u64(pcg_data *value)
{
    return ((U64)pcg_next_data(value) << 32) | pcg_next_data(value);
}

static void
pcg_fill_bytes(pcg_data *state, STRLEN length, U8 *bytes)
{
    U64 word;
    STRLEN offset;
    unsigned int i;

    for (offset = 0; offset < length; ) {
        word = pcg_next_u64(state);
        for (i = 0; i < 8 && offset < length; i++)
            bytes[offset++] = (U8)(word >> (56 - 8 * i));
    }
}

static bool
pcg_rng_bytes(pTHX_ SV *self, STRLEN length, U8 *bytes)
{
    pcg_fill_bytes(pcg_state(aTHX_ self), length, bytes);
    return TRUE;
}

static U64
pcg_rng_u64_fast(pTHX_ void *state)
{
    return pcg_next_u64((pcg_data *)state);
}

static void
pcg_seed(pTHX_ pcg_data *value, SV *seed)
{
    U8 numeric_seed[sizeof(U64)];
    const U8 *seed_bytes;
    STRLEN seed_len;
    unsigned int i;

    if (seed && SvOK(seed) && SvPOKp(seed)
        && !SvIOKp(seed) && !SvNOKp(seed)) {
        seed_bytes = (const U8 *)(SvUTF8(seed)
            ? SvPVutf8(seed, seed_len) : SvPVbyte(seed, seed_len));
    }
    else {
        const U64 numeric = seed && SvOK(seed) ? (U64)SvUV(seed) : 0;
        for (i = 0; i < sizeof(numeric_seed); i++)
            numeric_seed[i] = (U8)(numeric >> (i * 8));
        seed_bytes = numeric_seed;
        seed_len = sizeof(numeric_seed);
    }

    value->state = S_perl_hash_siphash_1_3_64(
        pcg_seed_key_13, seed_bytes, seed_len);
    value->initial = value->state;
    {
        const U64 extension = S_perl_hash_siphash_2_4_64(
            pcg_seed_key_24, seed_bytes, seed_len);
        value->extension[0] = (U32)extension;
        value->extension[1] = (U32)(extension >> 32);
    }
}

/* wyrand is a small, fast 64-bit generator.  Keep the multiply portable:
 * this distribution must not require a compiler-specific 128-bit integer
 * type merely to provide a U64 callback. */
typedef struct {
    U64 state;
} wyrand_data;

#define WYRAND_INCREMENT UINT64_C(0xa0761d6478bd642f)
#define WYRAND_MIX       UINT64_C(0xe7037ed1a0b428d)

static const char wyrand_zero_state[sizeof(wyrand_data)] = { 0 };
static const U8 wyrand_seed_key[] = "Perl wyrand seed";

static U64
wyrand_mum(U64 left, U64 right)
{
    const U64 left_hi = left >> 32;
    const U64 left_lo = (U32)left;
    const U64 right_hi = right >> 32;
    const U64 right_lo = (U32)right;
    U64 product = left_lo * right_lo;
    const U64 low_word = (U32)product;
    U64 carry = product >> 32;
    U64 middle = left_hi * right_lo + carry;
    U64 high = middle >> 32;
    const U64 middle_word = (U32)middle;

    middle = left_lo * right_hi + middle_word;
    carry = middle >> 32;
    high += left_hi * right_hi + carry;
    product = (middle << 32) + low_word;
    /* The addition cannot overflow here: the low word occupies the lower
     * half and the shifted product occupies the upper half. */
    return high ^ product;
}

static wyrand_data *
wyrand_state(pTHX_ SV *self)
{
    SV *state;

    if (!SvROK(self) || !SvPOK(state = SvRV(self)))
        croak("RNG::Wyrand object does not contain a valid state");
    if (SvCUR(state) != sizeof(wyrand_data))
        croak("RNG::Wyrand object does not contain a valid state");
    return (wyrand_data *)SvPVX(state);
}

static wyrand_data *
wyrand_state_fast(SV *self)
{
    return (wyrand_data *)SvPVX(SvRV(self));
}

static U64
wyrand_next(wyrand_data *value)
{
    value->state += WYRAND_INCREMENT;
    return wyrand_mum(value->state ^ WYRAND_MIX, value->state);
}

static void
wyrand_seed(pTHX_ wyrand_data *value, SV *seed)
{
    U8 numeric_seed[sizeof(U64)];
    const U8 *seed_bytes;
    STRLEN seed_len;
    unsigned int i;

    if (seed && SvOK(seed) && SvPOKp(seed)
        && !SvIOKp(seed) && !SvNOKp(seed)) {
        seed_bytes = (const U8 *)(SvUTF8(seed)
            ? SvPVutf8(seed, seed_len) : SvPVbyte(seed, seed_len));
    }
    else {
        const U64 numeric = seed && SvOK(seed) ? (U64)SvUV(seed) : 0;
        for (i = 0; i < sizeof(numeric_seed); i++)
            numeric_seed[i] = (U8)(numeric >> (i * 8));
        seed_bytes = numeric_seed;
        seed_len = sizeof(numeric_seed);
    }

    value->state = S_perl_hash_siphash_1_3_64(
        wyrand_seed_key, seed_bytes, seed_len);
}

static void
wyrand_fill_bytes(wyrand_data *state, STRLEN length, U8 *bytes)
{
    U64 word;
    STRLEN offset;
    unsigned int i;

    for (offset = 0; offset < length; ) {
        word = wyrand_next(state);
        for (i = 0; i < 8 && offset < length; i++)
            bytes[offset++] = (U8)(word >> (56 - 8 * i));
    }
}

static U64
wyrand_u64_fast(pTHX_ void *state)
{
    return wyrand_next((wyrand_data *)state);
}

typedef struct {
    U64 state[4];
} xoshiro_data;

static const char xoshiro_zero_state[sizeof(xoshiro_data)] = { 0 };
static const U8 xoshiro_seed_key[] = "Perl xoshiro seed";

static xoshiro_data *
xoshiro_state(pTHX_ SV *self)
{
    SV *state;

    if (!SvROK(self) || !SvPOK(state = SvRV(self)))
        croak("RNG::Xoshiro object does not contain a valid state");
    if (SvCUR(state) != sizeof(xoshiro_data))
        croak("RNG::Xoshiro object does not contain a valid state");
    return (xoshiro_data *)SvPVX(state);
}

static xoshiro_data *
xoshiro_state_fast(SV *self)
{
    return (xoshiro_data *)SvPVX(SvRV(self));
}

static U64
xoshiro_rotl(U64 value, unsigned int shift)
{
    return (value << shift) | (value >> (64 - shift));
}

static U64
xoshiro_next(xoshiro_data *value)
{
    const U64 result = xoshiro_rotl(value->state[1] * 5, 7) * 9;
    const U64 temporary = value->state[1] << 17;

    value->state[2] ^= value->state[0];
    value->state[3] ^= value->state[1];
    value->state[1] ^= value->state[2];
    value->state[0] ^= value->state[3];
    value->state[2] ^= temporary;
    value->state[3] = xoshiro_rotl(value->state[3], 45);
    return result;
}

static U64
xoshiro_splitmix_next(U64 *state)
{
    U64 value = (*state += UINT64_C(0x9e3779b97f4a7c15));
    value = (value ^ (value >> 30)) * UINT64_C(0xbf58476d1ce4e5b9);
    value = (value ^ (value >> 27)) * UINT64_C(0x94d049bb133111eb);
    return value ^ (value >> 31);
}

static void
xoshiro_seed(pTHX_ xoshiro_data *value, SV *seed)
{
    U8 numeric_seed[sizeof(U64)];
    const U8 *seed_bytes;
    STRLEN seed_len;
    U64 splitmix_state;
    unsigned int i;

    if (seed && SvOK(seed) && SvPOKp(seed)
        && !SvIOKp(seed) && !SvNOKp(seed)) {
        seed_bytes = (const U8 *)(SvUTF8(seed)
            ? SvPVutf8(seed, seed_len) : SvPVbyte(seed, seed_len));
    }
    else {
        const U64 numeric = seed && SvOK(seed) ? (U64)SvUV(seed) : 0;
        for (i = 0; i < sizeof(numeric_seed); i++)
            numeric_seed[i] = (U8)(numeric >> (i * 8));
        seed_bytes = numeric_seed;
        seed_len = sizeof(numeric_seed);
    }

    splitmix_state = S_perl_hash_siphash_1_3_64(
        xoshiro_seed_key, seed_bytes, seed_len);
    for (i = 0; i < 4; i++)
        value->state[i] = xoshiro_splitmix_next(&splitmix_state);
}

static void
xoshiro_fill_bytes(xoshiro_data *state, STRLEN length, U8 *bytes)
{
    U64 word;
    STRLEN offset;
    unsigned int i;

    for (offset = 0; offset < length; ) {
        word = xoshiro_next(state);
        for (i = 0; i < 8 && offset < length; i++)
            bytes[offset++] = (U8)(word >> (56 - 8 * i));
    }
}

static U64
xoshiro_u64_fast(pTHX_ void *state)
{
    return xoshiro_next((xoshiro_data *)state);
}

/* A compact SHA-256 implementation used only by RNG::HMAC_DRBG.  The
 * compression function, constants, padding, and byte ordering follow NIST
 * FIPS 180-4, Secure Hash Standard.  This is an in-tree implementation, not
 * copied from a third-party source.  Keeping it here makes the secure provider
 * independent of a separately installed Perl module or crypto library. */
typedef struct {
    U32 hash[8];
    U64 bits;
    U8 buffer[64];
    STRLEN used;
} hmac_sha256_ctx;

static const U32 hmac_sha256_round_constants[64] = {
    0x428a2f98U, 0x71374491U, 0xb5c0fbcfU, 0xe9b5dba5U,
    0x3956c25bU, 0x59f111f1U, 0x923f82a4U, 0xab1c5ed5U,
    0xd807aa98U, 0x12835b01U, 0x243185beU, 0x550c7dc3U,
    0x72be5d74U, 0x80deb1feU, 0x9bdc06a7U, 0xc19bf174U,
    0xe49b69c1U, 0xefbe4786U, 0x0fc19dc6U, 0x240ca1ccU,
    0x2de92c6fU, 0x4a7484aaU, 0x5cb0a9dcU, 0x76f988daU,
    0x983e5152U, 0xa831c66dU, 0xb00327c8U, 0xbf597fc7U,
    0xc6e00bf3U, 0xd5a79147U, 0x06ca6351U, 0x14292967U,
    0x27b70a85U, 0x2e1b2138U, 0x4d2c6dfcU, 0x53380d13U,
    0x650a7354U, 0x766a0abbU, 0x81c2c92eU, 0x92722c85U,
    0xa2bfe8a1U, 0xa81a664bU, 0xc24b8b70U, 0xc76c51a3U,
    0xd192e819U, 0xd6990624U, 0xf40e3585U, 0x106aa070U,
    0x19a4c116U, 0x1e376c08U, 0x2748774cU, 0x34b0bcb5U,
    0x391c0cb3U, 0x4ed8aa4aU, 0x5b9cca4fU, 0x682e6ff3U,
    0x748f82eeU, 0x78a5636fU, 0x84c87814U, 0x8cc70208U,
    0x90befffaU, 0xa4506cebU, 0xbef9a3f7U, 0xc67178f2U
};

static U32
hmac_rotr32(U32 value, unsigned int shift)
{
    return (value >> shift) | (value << (32 - shift));
}

static void
hmac_sha256_transform(hmac_sha256_ctx *context, const U8 *block)
{
    U32 words[64];
    U32 a, b, c, d, e, f, g, h;
    unsigned int i;

    for (i = 0; i < 16; i++)
        words[i] = ((U32)block[i * 4] << 24)
                 | ((U32)block[i * 4 + 1] << 16)
                 | ((U32)block[i * 4 + 2] << 8)
                 | (U32)block[i * 4 + 3];
    for (i = 16; i < 64; i++) {
        const U32 x = words[i - 15];
        const U32 y = words[i - 2];
        const U32 sigma0 = hmac_rotr32(x, 7) ^ hmac_rotr32(x, 18) ^ (x >> 3);
        const U32 sigma1 = hmac_rotr32(y, 17) ^ hmac_rotr32(y, 19) ^ (y >> 10);
        words[i] = words[i - 16] + sigma0 + words[i - 7] + sigma1;
    }

    a = context->hash[0]; b = context->hash[1];
    c = context->hash[2]; d = context->hash[3];
    e = context->hash[4]; f = context->hash[5];
    g = context->hash[6]; h = context->hash[7];
    for (i = 0; i < 64; i++) {
        const U32 sigma1 = hmac_rotr32(e, 6) ^ hmac_rotr32(e, 11)
                         ^ hmac_rotr32(e, 25);
        const U32 choice = (e & f) ^ (~e & g);
        const U32 temporary1 = h + sigma1 + choice
                             + hmac_sha256_round_constants[i] + words[i];
        const U32 sigma0 = hmac_rotr32(a, 2) ^ hmac_rotr32(a, 13)
                         ^ hmac_rotr32(a, 22);
        const U32 majority = (a & b) ^ (a & c) ^ (b & c);
        const U32 temporary2 = sigma0 + majority;
        h = g; g = f; f = e; e = d + temporary1;
        d = c; c = b; b = a; a = temporary1 + temporary2;
    }

    context->hash[0] += a; context->hash[1] += b;
    context->hash[2] += c; context->hash[3] += d;
    context->hash[4] += e; context->hash[5] += f;
    context->hash[6] += g; context->hash[7] += h;
}

static void
hmac_sha256_init(hmac_sha256_ctx *context)
{
    context->hash[0] = 0x6a09e667U; context->hash[1] = 0xbb67ae85U;
    context->hash[2] = 0x3c6ef372U; context->hash[3] = 0xa54ff53aU;
    context->hash[4] = 0x510e527fU; context->hash[5] = 0x9b05688cU;
    context->hash[6] = 0x1f83d9abU; context->hash[7] = 0x5be0cd19U;
    context->bits = 0;
    context->used = 0;
}

static void
hmac_sha256_update(hmac_sha256_ctx *context, const U8 *data, STRLEN length)
{
    STRLEN copied;

    context->bits += (U64)length * 8;
    while (length > 0) {
        copied = 64 - context->used;
        if (copied > length)
            copied = length;
        Copy(data, context->buffer + context->used, copied, U8);
        context->used += copied;
        data += copied;
        length -= copied;
        if (context->used == 64) {
            hmac_sha256_transform(context, context->buffer);
            context->used = 0;
        }
    }
}

static void
hmac_sha256_final(hmac_sha256_ctx *context, U8 output[32])
{
    U8 padding[64] = { 0x80 };
    U8 length[8];
    unsigned int i;

    for (i = 0; i < 8; i++)
        length[7 - i] = (U8)(context->bits >> (i * 8));
    hmac_sha256_update(context, padding, 1);
    while (context->used != 56)
        hmac_sha256_update(context, (const U8 *)"\0", 1);
    hmac_sha256_update(context, length, sizeof(length));
    for (i = 0; i < 8; i++) {
        output[i * 4] = (U8)(context->hash[i] >> 24);
        output[i * 4 + 1] = (U8)(context->hash[i] >> 16);
        output[i * 4 + 2] = (U8)(context->hash[i] >> 8);
        output[i * 4 + 3] = (U8)context->hash[i];
    }
}

static void
hmac_sha256(const U8 *key, STRLEN key_length,
            const U8 *first, STRLEN first_length,
            const U8 *second, STRLEN second_length,
            const U8 *third, STRLEN third_length,
            U8 output[32])
{
    hmac_sha256_ctx context;
    U8 ipad[64], opad[64], inner[32];
    unsigned int i;

    Zero(ipad, sizeof(ipad), U8);
    Zero(opad, sizeof(opad), U8);
    if (key_length > 64)
        key_length = 64;
    Copy(key, ipad, key_length, U8);
    Copy(key, opad, key_length, U8);
    for (i = 0; i < 64; i++) {
        ipad[i] ^= 0x36;
        opad[i] ^= 0x5c;
    }

    hmac_sha256_init(&context);
    hmac_sha256_update(&context, ipad, sizeof(ipad));
    hmac_sha256_update(&context, first, first_length);
    if (second && second_length)
        hmac_sha256_update(&context, second, second_length);
    if (third && third_length)
        hmac_sha256_update(&context, third, third_length);
    hmac_sha256_final(&context, inner);

    hmac_sha256_init(&context);
    hmac_sha256_update(&context, opad, sizeof(opad));
    hmac_sha256_update(&context, inner, sizeof(inner));
    hmac_sha256_final(&context, output);
}

static void
hmac_sha256_hash(const U8 *first, STRLEN first_length,
                 const U8 *second, STRLEN second_length,
                 U8 output[32])
{
    hmac_sha256_ctx context;

    hmac_sha256_init(&context);
    hmac_sha256_update(&context, first, first_length);
    if (second && second_length)
        hmac_sha256_update(&context, second, second_length);
    hmac_sha256_final(&context, output);
}

typedef struct {
    U8 key[32];
    U8 value[32];
    U64 reseed_counter;
    U64 reseed_interval;
    UV pid;
    bool secure;
    bool prediction_resistance;
} hmac_drbg_data;

#define HMAC_DRBG_RESEED_INTERVAL UINT64_C(1000000)
static const char hmac_drbg_zero_state[sizeof(hmac_drbg_data)] = { 0 };
static const U8 hmac_drbg_seed_label[] = "Perl HMAC_DRBG deterministic seed";
static const U8 hmac_drbg_nonce_label[] = "Perl HMAC_DRBG deterministic nonce";

static hmac_drbg_data *
hmac_drbg_state(pTHX_ SV *self)
{
    SV *state;

    if (!SvROK(self) || !SvPOK(state = SvRV(self)))
        croak("RNG::HMAC_DRBG object does not contain a valid state");
    if (SvCUR(state) != sizeof(hmac_drbg_data))
        croak("RNG::HMAC_DRBG object does not contain a valid state");
    return (hmac_drbg_data *)SvPVX(state);
}

static hmac_drbg_data *
hmac_drbg_state_fast(SV *self)
{
    return (hmac_drbg_data *)SvPVX(SvRV(self));
}

static void
hmac_drbg_update(hmac_drbg_data *state, const U8 *provided, STRLEN length)
{
    U8 separator;

    separator = 0;
    hmac_sha256(state->key, sizeof(state->key), state->value,
                sizeof(state->value), &separator, 1, provided, length,
                state->key);
    hmac_sha256(state->key, sizeof(state->key), state->value,
                sizeof(state->value), NULL, 0, NULL, 0, state->value);
    if (provided && length) {
        separator = 1;
        hmac_sha256(state->key, sizeof(state->key), state->value,
                    sizeof(state->value), &separator, 1, provided, length,
                    state->key);
        hmac_sha256(state->key, sizeof(state->key), state->value,
                    sizeof(state->value), NULL, 0, NULL, 0, state->value);
    }
}

static bool
hmac_drbg_os_entropy(U8 *bytes, STRLEN length)
{
#ifdef MSWIN32
    while (length > 0) {
        const ULONG chunk = length > (STRLEN)((ULONG)-1)
                          ? (ULONG)-1 : (ULONG)length;
        if (BCryptGenRandom(NULL, bytes, chunk,
                            BCRYPT_USE_SYSTEM_PREFERRED_RNG) != 0)
            return FALSE;
        bytes += chunk;
        length -= chunk;
    }
    return TRUE;
#elif defined(HAS_GETENTROPY)
    while (length > 0) {
        const STRLEN chunk = length > 256 ? 256 : length;
        if (getentropy(bytes, chunk) != 0)
            return FALSE;
        bytes += chunk;
        length -= chunk;
    }
    return TRUE;
#elif !defined(MSWIN32) && !defined(MSDOS) && !defined(__amigaos4__)
    int fd = PerlLIO_open_cloexec("/dev/urandom", O_RDONLY);
    if (fd < 0)
        return FALSE;
    while (length) {
        const SSize_t got = PerlLIO_read(fd, bytes, length);
        if (got <= 0) {
            PerlLIO_close(fd);
            return FALSE;
        }
        bytes += got;
        length -= (STRLEN)got;
    }
    PerlLIO_close(fd);
    return TRUE;
#else
    PERL_UNUSED_ARG(bytes);
    PERL_UNUSED_ARG(length);
    return FALSE;
#endif
}

static void
hmac_drbg_instantiate(hmac_drbg_data *state,
                      const U8 *entropy, STRLEN entropy_length,
                      const U8 *nonce, STRLEN nonce_length,
                      const U8 *personalization, STRLEN personalization_length,
                      bool secure)
{
    U8 *material;
    STRLEN length = entropy_length + nonce_length + personalization_length;

    if (length < entropy_length || length < nonce_length)
        croak("RNG::HMAC_DRBG seed material is too large");
    Newx(material, length, U8);
    Copy(entropy, material, entropy_length, U8);
    Copy(nonce, material + entropy_length, nonce_length, U8);
    if (personalization_length)
        Copy(personalization, material + entropy_length + nonce_length,
             personalization_length, U8);

    Zero(state->key, sizeof(state->key), U8);
    memset(state->value, 0x01, sizeof(state->value));
    hmac_drbg_update(state, material, length);
    Safefree(material);
    state->reseed_counter = 1;
    state->reseed_interval = HMAC_DRBG_RESEED_INTERVAL;
    state->pid = PerlProc_getpid();
    state->secure = secure;
    state->prediction_resistance = FALSE;
}

static void
hmac_drbg_reseed_state(hmac_drbg_data *state,
                       const U8 *entropy, STRLEN entropy_length,
                       const U8 *additional, STRLEN additional_length)
{
    U8 *material;
    STRLEN length = entropy_length + additional_length;

    if (length < entropy_length)
        croak("RNG::HMAC_DRBG reseed material is too large");
    Newx(material, length, U8);
    Copy(entropy, material, entropy_length, U8);
    if (additional_length)
        Copy(additional, material + entropy_length, additional_length, U8);
    hmac_drbg_update(state, material, length);
    Safefree(material);
    state->reseed_counter = 1;
    state->pid = PerlProc_getpid();
}

static void
hmac_drbg_reseed_secure(pTHX_ hmac_drbg_data *state,
                        const U8 *additional, STRLEN additional_length)
{
    U8 entropy[48];

    if (!hmac_drbg_os_entropy(entropy, sizeof(entropy)))
        croak("RNG::HMAC_DRBG could not obtain operating-system entropy");
    hmac_drbg_reseed_state(state, entropy, sizeof(entropy),
                           additional, additional_length);
    Zero(entropy, sizeof(entropy), U8);
}

static void
hmac_drbg_prepare(pTHX_ hmac_drbg_data *state)
{
    const UV pid = PerlProc_getpid();

    if (!state->secure)
        return;
    if (state->pid != pid || state->prediction_resistance
        || state->reseed_counter > state->reseed_interval)
        hmac_drbg_reseed_secure(aTHX_ state, NULL, 0);
}

static void
hmac_drbg_generate(hmac_drbg_data *state, U8 *output, STRLEN length,
                   const U8 *additional, STRLEN additional_length)
{
    STRLEN offset = 0;

    if (additional && additional_length)
        hmac_drbg_update(state, additional, additional_length);
    while (offset < length) {
        STRLEN copy_length;
        hmac_sha256(state->key, sizeof(state->key), state->value,
                    sizeof(state->value), NULL, 0, NULL, 0, state->value);
        copy_length = length - offset;
        if (copy_length > sizeof(state->value))
            copy_length = sizeof(state->value);
        Copy(state->value, output + offset, copy_length, U8);
        offset += copy_length;
    }
    hmac_drbg_update(state, additional, additional_length);
    ++state->reseed_counter;
}

static U64
hmac_drbg_u64_fast(pTHX_ void *raw_state)
{
    hmac_drbg_data *state = (hmac_drbg_data *)raw_state;
    U8 output[8];
    U64 value = 0;
    unsigned int i;

    hmac_drbg_prepare(aTHX_ state);
    hmac_drbg_generate(state, output, sizeof(output), NULL, 0);
    for (i = 0; i < sizeof(output); i++)
        value = (value << 8) | output[i];
    return value;
}

MODULE = RNG         PACKAGE = RNG::Drand48

UV
get_rand_u64_XS_func_addr(self)
    SV *self
CODE:
    PERL_UNUSED_ARG(self);
    RETVAL = PTR2UV(drand48_u64_fast);
OUTPUT:
    RETVAL

UV
get_rand_u64_XS_state_addr(self)
    SV *self
CODE:
    RETVAL = PTR2UV(drand48_state_fast(self));
OUTPUT:
    RETVAL

SV *
new(class_name, seed = 0)
    const char *class_name
    SV *seed
PREINIT:
    SV *state;
CODE:
    state = newSVpvn(drand48_zero_state, sizeof(drand48_zero_state));
    RETVAL = newRV_noinc(state);
    sv_bless(RETVAL, gv_stashpv(class_name, GV_ADD));
    drand48_seed((rng_drand48_data *)SvPVX(state), seed);
OUTPUT:
    RETVAL

SV *
rand_bytes(self, length)
    SV *self
    UV length
CODE:
    RETVAL = newSVpvn("", 0);
    SvGROW(RETVAL, length + 1);
    drand48_fill_bytes(drand48_state(aTHX_ self), length,
                       (U8 *)SvPVX(RETVAL));
    ((U8 *)SvPVX(RETVAL))[length] = '\0';
    SvCUR_set(RETVAL, length);
    SvPOK_on(RETVAL);
OUTPUT:
    RETVAL

NV
rand01(self)
    SV *self
PREINIT:
    U64 random;
CODE:
    random = drand48_u64_fast(aTHX_ drand48_state(aTHX_ self));
    RETVAL = (NV)random / ((NV)UINT64_C(0xffffffffffffffff) + 1.0);
OUTPUT:
    RETVAL

NV
rand(self, limit = NULL)
    SV *self
    SV *limit
PREINIT:
    NV value;
    U64 random;
CODE:
    value = (items < 2 || !SvOK(limit)) ? 1.0 : SvNV(limit);
    if (value == 0.0)
        value = 1.0;
    random = drand48_u64_fast(aTHX_ drand48_state(aTHX_ self));
    RETVAL = value * ((NV)random
                      / ((NV)UINT64_C(0xffffffffffffffff) + 1.0));
OUTPUT:
    RETVAL

UV
srand(self, seed = NULL)
    SV *self
    SV *seed
PREINIT:
    UV value;
CODE:
    value = (items < 2 || !SvOK(seed)
          || (SvPOKp(seed) && !SvIOKp(seed) && !SvNOKp(seed)))
          ? 0 : SvUV(seed);
    drand48_seed(drand48_state(aTHX_ self), seed);
    RETVAL = value;
OUTPUT:
    RETVAL

MODULE = RNG         PACKAGE = RNG::PCG

UV
get_rand_u64_XS_func_addr(self)
    SV *self
CODE:
    PERL_UNUSED_ARG(self);
    RETVAL = PTR2UV(pcg_rng_u64_fast);
OUTPUT:
    RETVAL

UV
get_rand_u64_XS_state_addr(self)
    SV *self
CODE:
    RETVAL = PTR2UV(pcg_state_fast(self));
OUTPUT:
    RETVAL

SV *
new(class_name, seed = 0)
    const char *class_name
    SV *seed
PREINIT:
    SV *state;
CODE:
    state = newSVpvn(pcg_zero_state, sizeof(pcg_zero_state));
    RETVAL = newRV_noinc(state);
    sv_bless(RETVAL, gv_stashpv(class_name, GV_ADD));
    pcg_seed(aTHX_ pcg_state(aTHX_ RETVAL), seed);
OUTPUT:
    RETVAL

SV *
rand_bytes(self, length)
    SV *self
    UV length
CODE:
    RETVAL = newSVpvn("", 0);
    SvGROW(RETVAL, length + 1);
    pcg_rng_bytes(aTHX_ self, length, (U8 *)SvPVX(RETVAL));
    ((U8 *)SvPVX(RETVAL))[length] = '\0';
    SvCUR_set(RETVAL, length);
    SvPOK_on(RETVAL);
OUTPUT:
    RETVAL

NV
rand01(self)
    SV *self
PREINIT:
    pcg_data *state;
    U64 random;
CODE:
    state = pcg_state(aTHX_ self);
    random = pcg_next_u64(state);
    RETVAL = (NV)random / ((NV)UINT64_C(0xffffffffffffffff) + 1.0);
OUTPUT:
    RETVAL

NV
rand(self, limit = NULL)
    SV *self
    SV *limit
PREINIT:
    NV value;
    U64 random;
    pcg_data *state;
CODE:
    value = (items < 2 || !SvOK(limit)) ? 1.0 : SvNV(limit);
    if (value == 0.0)
        value = 1.0;
    state = pcg_state(aTHX_ self);
    random = pcg_next_u64(state);
    RETVAL = value * ((NV)random
                      / ((NV)UINT64_C(0xffffffffffffffff) + 1.0));
OUTPUT:
    RETVAL

UV
srand(self, seed = NULL)
    SV *self
    SV *seed
PREINIT:
    UV value;
CODE:
    value = (items < 2 || !SvOK(seed)
          || (SvPOKp(seed) && !SvIOKp(seed) && !SvNOKp(seed)))
          ? 0 : SvUV(seed);
    pcg_seed(aTHX_ pcg_state(aTHX_ self), seed);
    RETVAL = value;
OUTPUT:
    RETVAL

MODULE = RNG         PACKAGE = RNG::HMAC_DRBG

UV
get_rand_u64_XS_func_addr(self)
    SV *self
CODE:
    PERL_UNUSED_ARG(self);
    RETVAL = PTR2UV(hmac_drbg_u64_fast);
OUTPUT:
    RETVAL

UV
get_rand_u64_XS_state_addr(self)
    SV *self
CODE:
    RETVAL = PTR2UV(hmac_drbg_state_fast(self));
OUTPUT:
    RETVAL

SV *
new(class_name, seed = 0)
    const char *class_name
    SV *seed
PREINIT:
    SV *state;
    U8 entropy[32];
    U8 nonce_digest[32];
    STRLEN seed_length = 0;
    const U8 *seed_bytes = NULL;
CODE:
    state = newSVpvn(hmac_drbg_zero_state, sizeof(hmac_drbg_zero_state));
    RETVAL = newRV_noinc(state);
    sv_bless(RETVAL, gv_stashpv(class_name, GV_ADD));
    seed_bytes = seed && SvOK(seed)
        ? (const U8 *)(SvUTF8(seed) ? SvPVutf8(seed, seed_length)
                                    : SvPVbyte(seed, seed_length))
        : (const U8 *)"";
    hmac_sha256_hash(hmac_drbg_seed_label, sizeof(hmac_drbg_seed_label) - 1,
                     seed_bytes, seed_length, entropy);
    hmac_sha256_hash(hmac_drbg_nonce_label, sizeof(hmac_drbg_nonce_label) - 1,
                     seed_bytes, seed_length, nonce_digest);
    hmac_drbg_instantiate(hmac_drbg_state(aTHX_ RETVAL),
                          entropy, sizeof(entropy), nonce_digest, 16,
                          NULL, 0, FALSE);
    Zero(entropy, sizeof(entropy), U8);
    Zero(nonce_digest, sizeof(nonce_digest), U8);
OUTPUT:
    RETVAL

SV *
new_secure(class_name, personalization = NULL)
    const char *class_name
    SV *personalization
PREINIT:
    SV *state;
    U8 entropy[32];
    U8 nonce[16];
    STRLEN personalization_length = 0;
    const U8 *personalization_bytes = NULL;
CODE:
    if (!hmac_drbg_os_entropy(entropy, sizeof(entropy))
        || !hmac_drbg_os_entropy(nonce, sizeof(nonce)))
        croak("RNG::HMAC_DRBG could not obtain operating-system entropy");
    if (personalization && SvOK(personalization))
        personalization_bytes = (const U8 *)(SvUTF8(personalization)
            ? SvPVutf8(personalization, personalization_length)
            : SvPVbyte(personalization, personalization_length));
    state = newSVpvn(hmac_drbg_zero_state, sizeof(hmac_drbg_zero_state));
    RETVAL = newRV_noinc(state);
    sv_bless(RETVAL, gv_stashpv(class_name, GV_ADD));
    hmac_drbg_instantiate(hmac_drbg_state(aTHX_ RETVAL),
                          entropy, sizeof(entropy), nonce, sizeof(nonce),
                          personalization_bytes, personalization_length, TRUE);
    Zero(entropy, sizeof(entropy), U8);
    Zero(nonce, sizeof(nonce), U8);
OUTPUT:
    RETVAL

SV *
rand_bytes(self, length)
    SV *self
    UV length
PREINIT:
    hmac_drbg_data *state;
CODE:
    state = hmac_drbg_state(aTHX_ self);
    hmac_drbg_prepare(aTHX_ state);
    RETVAL = newSVpvn("", 0);
    SvGROW(RETVAL, length + 1);
    hmac_drbg_generate(state, (U8 *)SvPVX(RETVAL), length, NULL, 0);
    ((U8 *)SvPVX(RETVAL))[length] = '\0';
    SvCUR_set(RETVAL, length);
    SvPOK_on(RETVAL);
OUTPUT:
    RETVAL

NV
rand01(self)
    SV *self
PREINIT:
    U64 random;
CODE:
    random = hmac_drbg_u64_fast(aTHX_ hmac_drbg_state(aTHX_ self));
    RETVAL = (NV)random / ((NV)UINT64_C(0xffffffffffffffff) + 1.0);
OUTPUT:
    RETVAL

NV
rand(self, limit = NULL)
    SV *self
    SV *limit
PREINIT:
    NV value;
    U64 random;
CODE:
    value = (items < 2 || !SvOK(limit)) ? 1.0 : SvNV(limit);
    if (value == 0.0)
        value = 1.0;
    random = hmac_drbg_u64_fast(aTHX_ hmac_drbg_state(aTHX_ self));
    RETVAL = value * ((NV)random
                      / ((NV)UINT64_C(0xffffffffffffffff) + 1.0));
OUTPUT:
    RETVAL

UV
srand(self, seed = NULL)
    SV *self
    SV *seed
PREINIT:
    U8 digest[32];
    U8 nonce_digest[32];
    STRLEN seed_length = 0;
    const U8 *seed_bytes = NULL;
    hmac_drbg_data *state;
CODE:
    if (items < 2) {
        seed_bytes = (const U8 *)"0";
        seed_length = 1;
    }
    else if (seed && SvOK(seed))
        seed_bytes = (const U8 *)(SvUTF8(seed)
            ? SvPVutf8(seed, seed_length) : SvPVbyte(seed, seed_length));
    state = hmac_drbg_state(aTHX_ self);
    if (state->secure && (items < 2 || !SvOK(seed))) {
        hmac_drbg_reseed_secure(aTHX_ state, NULL, 0);
    }
    else {
        hmac_sha256_hash(hmac_drbg_seed_label, sizeof(hmac_drbg_seed_label) - 1,
                         seed_bytes, seed_length, digest);
        hmac_sha256_hash(hmac_drbg_nonce_label, sizeof(hmac_drbg_nonce_label) - 1,
                         seed_bytes, seed_length, nonce_digest);
        hmac_drbg_instantiate(state, digest, sizeof(digest),
                              nonce_digest, 16, NULL, 0, FALSE);
    }
    Zero(digest, sizeof(digest), U8);
    Zero(nonce_digest, sizeof(nonce_digest), U8);
    RETVAL = (items < 2 || !SvOK(seed)
          || (SvPOKp(seed) && !SvIOKp(seed) && !SvNOKp(seed)))
          ? 0 : SvUV(seed);
OUTPUT:
    RETVAL

void
reseed(self, additional = NULL)
    SV *self
    SV *additional
PREINIT:
    STRLEN length = 0;
    const U8 *bytes = NULL;
    hmac_drbg_data *state;
PPCODE:
    state = hmac_drbg_state(aTHX_ self);
    if (additional && SvOK(additional))
        bytes = (const U8 *)(SvUTF8(additional)
            ? SvPVutf8(additional, length) : SvPVbyte(additional, length));
    if (state->secure)
        hmac_drbg_reseed_secure(aTHX_ state, bytes, length);
    else if (bytes) {
        hmac_drbg_update(state, bytes, length);
        state->reseed_counter = 1;
    }
    else
        croak("deterministic RNG::HMAC_DRBG requires reseed input");
    state->pid = PerlProc_getpid();
    XSRETURN_EMPTY;

UV
reseed_interval(self, value = NULL)
    SV *self
    SV *value
PREINIT:
    hmac_drbg_data *state;
CODE:
    state = hmac_drbg_state(aTHX_ self);
    if (items > 1) {
        if (!value || !SvOK(value) || SvUV(value) == 0)
            croak("RNG::HMAC_DRBG reseed interval must be positive");
        state->reseed_interval = SvUV(value);
    }
    RETVAL = (UV)state->reseed_interval;
OUTPUT:
    RETVAL

bool
prediction_resistance(self, value = NULL)
    SV *self
    SV *value
PREINIT:
    hmac_drbg_data *state;
CODE:
    state = hmac_drbg_state(aTHX_ self);
    if (items > 1) {
        if (value && SvTRUE(value) && !state->secure)
            croak("prediction resistance requires a secure HMAC_DRBG");
        state->prediction_resistance = value && SvTRUE(value);
    }
    RETVAL = state->prediction_resistance;
OUTPUT:
    RETVAL

MODULE = RNG         PACKAGE = RNG::Wyrand

UV
get_rand_u64_XS_func_addr(self)
    SV *self
CODE:
    PERL_UNUSED_ARG(self);
    RETVAL = PTR2UV(wyrand_u64_fast);
OUTPUT:
    RETVAL

UV
get_rand_u64_XS_state_addr(self)
    SV *self
CODE:
    RETVAL = PTR2UV(wyrand_state_fast(self));
OUTPUT:
    RETVAL

SV *
new(class_name, seed = 0)
    const char *class_name
    SV *seed
PREINIT:
    SV *state;
CODE:
    state = newSVpvn(wyrand_zero_state, sizeof(wyrand_zero_state));
    RETVAL = newRV_noinc(state);
    sv_bless(RETVAL, gv_stashpv(class_name, GV_ADD));
    wyrand_seed(aTHX_ wyrand_state(aTHX_ RETVAL), seed);
OUTPUT:
    RETVAL

SV *
rand_bytes(self, length)
    SV *self
    UV length
CODE:
    RETVAL = newSVpvn("", 0);
    SvGROW(RETVAL, length + 1);
    wyrand_fill_bytes(wyrand_state(aTHX_ self), length, (U8 *)SvPVX(RETVAL));
    ((U8 *)SvPVX(RETVAL))[length] = '\0';
    SvCUR_set(RETVAL, length);
    SvPOK_on(RETVAL);
OUTPUT:
    RETVAL

NV
rand01(self)
    SV *self
PREINIT:
    U64 random;
CODE:
    random = wyrand_next(wyrand_state(aTHX_ self));
    RETVAL = (NV)random / ((NV)UINT64_C(0xffffffffffffffff) + 1.0);
OUTPUT:
    RETVAL

NV
rand(self, limit = NULL)
    SV *self
    SV *limit
PREINIT:
    NV value;
    U64 random;
CODE:
    value = (items < 2 || !SvOK(limit)) ? 1.0 : SvNV(limit);
    if (value == 0.0)
        value = 1.0;
    random = wyrand_next(wyrand_state(aTHX_ self));
    RETVAL = value * ((NV)random
                      / ((NV)UINT64_C(0xffffffffffffffff) + 1.0));
OUTPUT:
    RETVAL

UV
srand(self, seed = NULL)
    SV *self
    SV *seed
PREINIT:
    UV value;
CODE:
    value = (items < 2 || !SvOK(seed)
          || (SvPOKp(seed) && !SvIOKp(seed) && !SvNOKp(seed)))
          ? 0 : SvUV(seed);
    wyrand_seed(aTHX_ wyrand_state(aTHX_ self), seed);
    RETVAL = value;
OUTPUT:
    RETVAL

MODULE = RNG         PACKAGE = RNG::Xoshiro

UV
get_rand_u64_XS_func_addr(self)
    SV *self
CODE:
    PERL_UNUSED_ARG(self);
    RETVAL = PTR2UV(xoshiro_u64_fast);
OUTPUT:
    RETVAL

UV
get_rand_u64_XS_state_addr(self)
    SV *self
CODE:
    RETVAL = PTR2UV(xoshiro_state_fast(self));
OUTPUT:
    RETVAL

SV *
new(class_name, seed = 0)
    const char *class_name
    SV *seed
PREINIT:
    SV *state;
CODE:
    state = newSVpvn(xoshiro_zero_state, sizeof(xoshiro_zero_state));
    RETVAL = newRV_noinc(state);
    sv_bless(RETVAL, gv_stashpv(class_name, GV_ADD));
    xoshiro_seed(aTHX_ xoshiro_state(aTHX_ RETVAL), seed);
OUTPUT:
    RETVAL

SV *
rand_bytes(self, length)
    SV *self
    UV length
CODE:
    RETVAL = newSVpvn("", 0);
    SvGROW(RETVAL, length + 1);
    xoshiro_fill_bytes(xoshiro_state(aTHX_ self), length, (U8 *)SvPVX(RETVAL));
    ((U8 *)SvPVX(RETVAL))[length] = '\0';
    SvCUR_set(RETVAL, length);
    SvPOK_on(RETVAL);
OUTPUT:
    RETVAL

NV
rand01(self)
    SV *self
PREINIT:
    U64 random;
CODE:
    random = xoshiro_next(xoshiro_state(aTHX_ self));
    RETVAL = (NV)random / ((NV)UINT64_C(0xffffffffffffffff) + 1.0);
OUTPUT:
    RETVAL

NV
rand(self, limit = NULL)
    SV *self
    SV *limit
PREINIT:
    NV value;
    U64 random;
CODE:
    value = (items < 2 || !SvOK(limit)) ? 1.0 : SvNV(limit);
    if (value == 0.0)
        value = 1.0;
    random = xoshiro_next(xoshiro_state(aTHX_ self));
    RETVAL = value * ((NV)random
                      / ((NV)UINT64_C(0xffffffffffffffff) + 1.0));
OUTPUT:
    RETVAL

UV
srand(self, seed = NULL)
    SV *self
    SV *seed
PREINIT:
    UV value;
CODE:
    value = (items < 2 || !SvOK(seed)
          || (SvPOKp(seed) && !SvIOKp(seed) && !SvNOKp(seed)))
          ? 0 : SvUV(seed);
    xoshiro_seed(aTHX_ xoshiro_state(aTHX_ self), seed);
    RETVAL = value;
OUTPUT:
    RETVAL
