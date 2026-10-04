#if defined(__clang__) && defined(__clang_major__) && __clang_major__ > 11
#  pragma clang diagnostic ignored "-Wcompound-token-split-by-macro"
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <fcntl.h>
#include <time.h>

/* Older threaded cores export Perl_ck_warner_d() but do not define the bare
 * ck_warner_d() wrapper.  Keep the default-warning semantics by supplying
 * that wrapper when the core headers did not. */
#ifndef ck_warner_d
#  define ck_warner_d(category, message) \
    Perl_ck_warner_d(aTHX_ (category), (message))
#endif

#ifdef I_SYS_RANDOM
#  include <sys/random.h>
#endif

#ifdef VMS
#  include <starlet.h>
#endif
#ifdef WIN32
/* RtlGenRandom is exported from advapi32.dll as SystemFunction036.  This is
 * the Windows operating-system entropy source used by Perl's core fallback. */
BOOLEAN NTAPI SystemFunction036(PVOID RandomBuffer, ULONG RandomBufferLength);
#endif

/* The same 48-bit linear-congruential generator used by Perl's default
 * drand48 implementation.  Keeping the state in a scalar reference makes
 * this provider obey the same object-level protocol as the other bundled
 * providers while allowing its native U01 callback to be benchmarked. */
typedef struct {
    U64 state;
} rng_drand48_data;

#define DRAND48_MULT UINT64_C(0x5deece66d)
#define DRAND48_ADD  UINT64_C(0xb)
#define DRAND48_MASK UINT64_C(0xffffffffffff)
#define DRAND48_SEED_0 UINT64_C(0x330e)

static const char drand48_zero_state[sizeof(rng_drand48_data)] = { 0 };
static const U8 drand48_seed_key[] = "Perl srand 48 v1";

static void rng_expand_seed(const U8 *label, STRLEN label_length,
                            const U8 *input, STRLEN input_length, U8 *output,
                            STRLEN output_length);

PERL_STATIC_INLINE NV
rng_U64_to_NV_U01(U64 value)
{
    return (NV)value / ((NV)UINT64_C(0xffffffffffffffff) + 1.0);
}

PERL_STATIC_INLINE NV
rng_U48_to_NV_U01(U64 value)
{
    return ldexp((NV)value, -48);
}

/* Drand48 string seeds use a fixed-key SipHash-1-3 calculation.  Perl has
 * supplied U8TO64_LE and SIPROUND since 5.24; this wrapper retains the
 * full 64-bit result which the older generated helper did not expose. */
static U64
rng_drand48_string_seed(const U8 *input, STRLEN input_length)
{
    const U8 *in = input;
    const U8 *end = in + input_length - (input_length & 7);
    U64 b = (U64)input_length << 56;
    U64 v0 = U8TO64_LE(drand48_seed_key)
             ^ UINT64_C(0x736f6d6570736575);
    U64 v1 = U8TO64_LE(drand48_seed_key + 8)
             ^ UINT64_C(0x646f72616e646f6d);
    U64 v2 = U8TO64_LE(drand48_seed_key)
             ^ UINT64_C(0x6c7967656e657261);
    U64 v3 = U8TO64_LE(drand48_seed_key + 8)
             ^ UINT64_C(0x7465646279746573);

    for (; in != end; in += 8) {
        U64 value = U8TO64_LE(in);
        v3 ^= value;
        SIPROUND;
        v0 ^= value;
    }
    switch (input_length & 7) {
    case 7: b |= (U64)in[6] << 48; /* FALLTHROUGH */
    case 6: b |= (U64)in[5] << 40; /* FALLTHROUGH */
    case 5: b |= (U64)in[4] << 32; /* FALLTHROUGH */
    case 4: b |= (U64)in[3] << 24; /* FALLTHROUGH */
    case 3: b |= (U64)in[2] << 16; /* FALLTHROUGH */
    case 2: b |= (U64)in[1] << 8;  /* FALLTHROUGH */
    case 1: b |= (U64)in[0];
    case 0: break;
    }
    v3 ^= b;
    SIPROUND;
    v0 ^= b;
    v2 ^= UINT64_C(0xff);
    SIPROUND;
    SIPROUND;
    SIPROUND;
    return v0 ^ v1 ^ v2 ^ v3;
}

/* Newer cores provide this interface.  The fallback below mirrors
 * Perl_get_entropy_portable() in util.c so that RNG can build against its
 * supported older Perls without changing the weak and strong entropy contract. */
#if !defined(PERL_GET_WEAK_ENTROPY) || !defined(PERL_GET_STRONG_ENTROPY)
#  define RNG_NEEDS_ENTROPY_COMPAT 1
static void rng_get_entropy_portable(pTHX_ U8 *output, STRLEN length,
                                     const char *failure);
#endif

#ifndef PERL_GET_WEAK_ENTROPY
#  define PERL_GET_WEAK_ENTROPY(output, length) \
    rng_get_entropy_portable(aTHX_ (output), (length), NULL)
#endif

#ifndef PERL_GET_STRONG_ENTROPY
#  define PERL_GET_STRONG_ENTROPY(output, length, failure) \
    rng_get_entropy_portable(aTHX_ (output), (length), (failure))
#endif

/* Return a private copy so it remains live after the Perl call frame goes
 * away.  Both raw-seed operations use this one call path. */
static SV *
rng_seed_method(pTHX_ SV *seed, const char *method)
{
    dSP;
    I32 count;
    SV *result;

    ENTER;
    SAVETMPS;
    PUSHMARK(SP);
    XPUSHs(sv_2mortal(SvREFCNT_inc_simple_NN(seed)));
    PUTBACK;
    count = call_method(method, G_SCALAR);
    SPAGAIN;
    if (count != 1)
        croak("RNG::SeedBase method did not return exactly one value");
    result = newSVsv(POPs);
    PUTBACK;
    FREETMPS;
    LEAVE;

    return result;
}

/* Raw material belongs to the SeedBase interface, not to RNG::Seed's
 * representation.  This also permits applications to provide their own
 * SeedBase subclasses. */
static bool
rng_raw_seed(pTHX_ SV *seed, SV **material, const U8 **bytes, STRLEN *length)
{
    SV *redacted;

    if (!seed || !sv_isobject(seed)
        || !sv_derived_from(seed, "RNG::SeedBase"))
        return FALSE;

    redacted = rng_seed_method(aTHX_ seed, "is_redacted");
    if (SvTRUE(redacted)) {
        SvREFCNT_dec_NN(redacted);
        croak("Cannot use a redacted RNG seed");
    }
    SvREFCNT_dec_NN(redacted);

    *material = rng_seed_method(aTHX_ seed, "bytes");

    if (!SvPOK(*material)) {
        SvREFCNT_dec_NN(*material);
        croak("RNG::SeedBase::bytes() did not return seed octets");
    }
    *bytes = (const U8 *)SvPVbyte(*material, *length);
    return TRUE;
}

static void
rng_require_raw_seed_length(SV *material, STRLEN length, STRLEN expected,
                            const char *provider)
{
    if (length != expected) {
        SvREFCNT_dec_NN(material);
        croak("RNG::Seed for %s must contain exactly %" UVuf " octets",
              provider, (UV)expected);
    }
}

static bool
rng_drand48_decimal_seed(const char *bytes, STRLEN length, U64 *value)
{
    const U8 *cursor = (const U8 *)bytes;
    const U8 * const end = cursor + length;
    U64 result = 0;
    bool saw_digit = FALSE;

    /* This duplicates the old srand numeric conversion for decimal seeds:
     * ignore an optional sign and fractional component.  We cannot use
     * grok_number(), because it produces a UV.  RNG::Drand48 must recognize
     * a decimal seed at its full 48-bit width on every supported Perl.
     * Exponent notation, other non-decimal text, and a value beyond U64 are
     * string seeds. */
    while (cursor < end && isSPACE(*cursor))
        cursor++;
    if (cursor < end && (*cursor == '+' || *cursor == '-'))
        cursor++;
    while (cursor < end && isDIGIT(*cursor)) {
        const U64 digit = *cursor++ - '0';

        saw_digit = TRUE;
        if (result > (UINT64_C(0xffffffffffffffff) - digit) / 10)
            return FALSE;
        result = result * 10 + digit;
    }
    if (cursor < end && *cursor == '.') {
        cursor++;
        while (cursor < end && isDIGIT(*cursor)) {
            saw_digit = TRUE;
            cursor++;
        }
    }
    if (!saw_digit)
        return FALSE;
    while (cursor < end && isSPACE(*cursor))
        cursor++;
    if (cursor != end)
        return FALSE;
    *value = result;
    return TRUE;
}

static SV *
rng_drand48_numeric_seed(U64 value)
{
    char decimal[TYPE_CHARS(U64)];

    /* A 32-bit UV cannot hold the full 48-bit state.  Return a decimal
     * string in that case so srand() can replay the state exactly. */

    if (value <= UV_MAX)
        return newSVuv((UV)value);

    /* sv_catpvf() does not accept every C U64 length modifier on the older
     * Perls supported by this distribution.  U64uf is Configure's native C
     * printf conversion, so format the value before constructing the SV. */
    return newSVpvn(decimal,
                    my_snprintf(decimal, sizeof(decimal), "%" U64uf, value));
}

static U64
rng_drand48_seed(pTHX_ SV *seed, bool is_builtin)
{
    const U64 mask = is_builtin ? U32_MAX : DRAND48_MASK;
    const STRLEN raw_length = is_builtin ? 4 : 6;
    const char * const seed_name = is_builtin ? "built-in Drand48"
                                               : "RNG::Drand48";
    STRLEN length;
    const char *bytes;
    const U8 *raw_bytes;
    SV *raw_material;
    U64 numeric;
    STRLEN index;

    if (!seed || !SvOK(seed)) {
        U64 entropy;

        PERL_GET_WEAK_ENTROPY((U8 *)&entropy, sizeof(entropy));
        return entropy & mask;
    }

    if (rng_raw_seed(aTHX_ seed, &raw_material, &raw_bytes, &length)) {
        rng_require_raw_seed_length(raw_material, length, raw_length, seed_name);
        numeric = 0;
        for (index = 0; index < raw_length; index++)
            numeric |= (U64)raw_bytes[index] << (index * 8);
        SvREFCNT_dec_NN(raw_material);
        return numeric;
    }
    bytes = SvPVutf8(seed, length);
    if (rng_drand48_decimal_seed(bytes, length, &numeric)) {
        if (numeric > mask)
            ck_warner_d(packWARN(WARN_OVERFLOW),
                        is_builtin
                        ? "Integer overflow in srand(): only using the low 32 bits"
                        : "Integer overflow in srand(): only using the low 48 bits");
        return numeric & mask;
    }
    /* String seeds retain the shared 32-bit fallback so built-in Drand48
     * and RNG::Drand48 produce the same legacy sequence. */
    return (U32)rng_drand48_string_seed((const U8 *)bytes, length);
}

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
drand48_seed(rng_drand48_data *value, U64 seed)
{
    value->state = seed <= U32_MAX
                 ? DRAND48_SEED_0 + (seed << 16)
                 : seed & DRAND48_MASK;
}

static U32
drand48_next_u32(rng_drand48_data *state)
{
    /* The low bits of this LCG have shorter periods, so emit the high 32
     * bits. */
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

static NV
drand48_U01_fast(pTHX_ void *state)
{
    rng_drand48_data * const value = (rng_drand48_data *)state;
    return rng_U48_to_NV_U01(drand48_next(value));
}

/*
 * This implements the extended generator construction in section 7.1 of
 * "PCG: A Family of Simple Fast Space-Efficient Statistically Good
 * Algorithms".  The base PCG-XSH-RR 64/32 output is XORed with an element
 * from the extension array selected by the state.  Two 32-bit extension
 * values give this generator 128 bits of state without 128-bit arithmetic.
 */
typedef struct {
    U64 state;
    U32 extension[2];
    U64 initial;
} pcg_data;

#define PCG_MULTIPLIER UINT64_C(0x5851f42d4c957f2d)
#define PCG_INCREMENT  UINT64_C(0x14057b7ef767814f)

static const U8 pcg_seed_key[] = "Perl RNG::PCG seed v1";

static const U8 *
rng_seed_bytes(pTHX_ SV *seed, U8 *automatic_seed,
               STRLEN automatic_seed_length, STRLEN *length)
{
    if (seed && SvOK(seed)) {
        const char *bytes = SvPVutf8(seed, *length);
        return (const U8 *)bytes;
    }

    PERL_GET_WEAK_ENTROPY(automatic_seed, automatic_seed_length);
    *length = automatic_seed_length;
    return automatic_seed;
}

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

static NV
pcg_rng_U01_fast(pTHX_ void *state)
{
    return rng_U64_to_NV_U01(pcg_next_u64((pcg_data *)state));
}

static void
pcg_load_raw_seed(pcg_data *value, const U8 *seed_bytes)
{
    value->state = U8TO64_LE(seed_bytes);
    value->extension[0] = U8TO32_LE(seed_bytes + 8);
    value->extension[1] = U8TO32_LE(seed_bytes + 12);
    value->initial = value->state;
}

static void
pcg_seed(pTHX_ pcg_data *value, SV *seed)
{
    U8 automatic_seed[16];
    U8 material[16];
    const U8 *seed_bytes;
    STRLEN seed_len;
    SV *raw_material;

    if (rng_raw_seed(aTHX_ seed, &raw_material, &seed_bytes, &seed_len)) {
        rng_require_raw_seed_length(raw_material, seed_len, sizeof(material),
                                    "RNG::PCG");
        pcg_load_raw_seed(value, seed_bytes);
        SvREFCNT_dec_NN(raw_material);
        return;
    }
    seed_bytes = rng_seed_bytes(aTHX_ seed, automatic_seed,
                                sizeof(automatic_seed), &seed_len);
    rng_expand_seed(pcg_seed_key, sizeof(pcg_seed_key) - 1, seed_bytes,
                    seed_len, material, sizeof(material));
    pcg_load_raw_seed(value, material);
}

/* wyrand is a small, fast 64-bit generator.  Its constants and state update
 * follow the wyhash_final4 reference implementation.  Keep the multiply
 * portable:
 * this distribution must not require a compiler-specific 128-bit integer
 * type merely to provide a native U01 callback. */
typedef struct {
    U64 state;
} wyrand_data;

#define WYRAND_INCREMENT UINT64_C(0xa0761d6478bd642f)
#define WYRAND_MIX       UINT64_C(0xe7037ed1a0b428db)

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
wyrand_load_raw_seed(wyrand_data *value, const U8 *seed_bytes)
{
    value->state = U8TO64_LE(seed_bytes);
}

static void
wyrand_seed(pTHX_ wyrand_data *value, SV *seed)
{
    U8 automatic_seed[sizeof(U64)];
    U8 material[sizeof(U64)];
    const U8 *seed_bytes;
    STRLEN seed_len;
    SV *raw_material;

    if (rng_raw_seed(aTHX_ seed, &raw_material, &seed_bytes, &seed_len)) {
        rng_require_raw_seed_length(raw_material, seed_len, sizeof(material),
                                    "RNG::Wyrand");
        wyrand_load_raw_seed(value, seed_bytes);
        SvREFCNT_dec_NN(raw_material);
        return;
    }
    seed_bytes = rng_seed_bytes(aTHX_ seed, automatic_seed,
                                sizeof(automatic_seed), &seed_len);
    rng_expand_seed(wyrand_seed_key, sizeof(wyrand_seed_key) - 1, seed_bytes,
                    seed_len, material, sizeof(material));
    wyrand_load_raw_seed(value, material);
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

static NV
wyrand_U01_fast(pTHX_ void *state)
{
    return rng_U64_to_NV_U01(wyrand_next((wyrand_data *)state));
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

static void
xoshiro_load_raw_seed(xoshiro_data *value, const U8 *seed_bytes)
{
    unsigned int i;

    for (i = 0; i < 4; i++)
        value->state[i] = U8TO64_LE(seed_bytes + i * 8);
    if (!(value->state[0] | value->state[1] | value->state[2] | value->state[3]))
        value->state[0] = 1;
}

static void
xoshiro_seed(pTHX_ xoshiro_data *value, SV *seed)
{
    U8 automatic_seed[32];
    U8 material[32];
    const U8 *seed_bytes;
    STRLEN seed_len;
    SV *raw_material;

    if (rng_raw_seed(aTHX_ seed, &raw_material, &seed_bytes, &seed_len)) {
        rng_require_raw_seed_length(raw_material, seed_len, sizeof(material),
                                    "RNG::Xoshiro");
        xoshiro_load_raw_seed(value, seed_bytes);
        SvREFCNT_dec_NN(raw_material);
        return;
    }
    seed_bytes = rng_seed_bytes(aTHX_ seed, automatic_seed,
                                sizeof(automatic_seed), &seed_len);
    rng_expand_seed(xoshiro_seed_key, sizeof(xoshiro_seed_key) - 1,
                    seed_bytes, seed_len, material, sizeof(material));
    xoshiro_load_raw_seed(value, material);
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

static NV
xoshiro_U01_fast(pTHX_ void *state)
{
    return rng_U64_to_NV_U01(xoshiro_next((xoshiro_data *)state));
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

/* This uses the distribution's SHA-256 implementation instead of a private
 * core hash helper.  That keeps string-seed derivation stable when RNG is
 * built against a supported older Perl. */
static void
rng_seed_digest(const U8 *label, STRLEN label_length,
                const U8 *input, STRLEN input_length, U32 counter,
                U8 output[32])
{
    hmac_sha256_ctx context;
    U8 suffix[4];

    suffix[0] = (U8)(counter >> 24);
    suffix[1] = (U8)(counter >> 16);
    suffix[2] = (U8)(counter >> 8);
    suffix[3] = (U8)counter;
    hmac_sha256_init(&context);
    hmac_sha256_update(&context, label, label_length);
    hmac_sha256_update(&context, input, input_length);
    hmac_sha256_update(&context, suffix, sizeof(suffix));
    hmac_sha256_final(&context, output);
}

static void
rng_expand_seed(const U8 *label, STRLEN label_length,
                const U8 *input, STRLEN input_length, U8 *output,
                STRLEN output_length)
{
    U8 digest[32];
    STRLEN offset = 0;
    U32 counter = 0;

    while (offset < output_length) {
        STRLEN copied = output_length - offset;

        if (copied > sizeof(digest))
            copied = sizeof(digest);
        rng_seed_digest(label, label_length, input, input_length,
                        counter++, digest);
        Copy(digest, output + offset, copied, U8);
        offset += copied;
    }
}

#ifdef RNG_NEEDS_ENTROPY_COMPAT
#  ifndef PERL_NO_DEV_RANDOM
#    ifndef PERL_RANDOM_DEVICE
#      ifdef __amigaos4__
#        define PERL_RANDOM_DEVICE "RANDOM:"
#      else
#        define PERL_RANDOM_DEVICE "/dev/urandom"
#      endif
#    endif
#  endif

static U64
rng_splitmix64(U64 *state)
{
    U64 value = (*state += UINT64_C(0x9e3779b97f4a7c15));

    value = (value ^ (value >> 30)) * UINT64_C(0xbf58476d1ce4e5b9);
    value = (value ^ (value >> 27)) * UINT64_C(0x94d049bb133111eb);
    return value ^ (value >> 31);
}

static void
rng_fill_fallback_entropy(pTHX_ U8 *buffer, STRLEN length)
{
#  ifdef HAS_GETTIMEOFDAY
    struct timeval when;
    U64 epoch;

    PerlProc_gettimeofday(&when, NULL);
    epoch = ((U64)when.tv_sec * 1000000) + when.tv_usec;
#  else
    Time_t when;
    U64 epoch;

    (void)time(&when);
    epoch = when;
#  endif
    {
        U64 state = ROTL64(PTR2UV(&when), 16)
                  ^ ROTL32(PerlProc_getpid(), 8)
                  ^ epoch ^ PTR2UV(PL_stack_sp);

        while (length) {
            const U64 word = rng_splitmix64(&state);
            const STRLEN chunk = length > sizeof(word) ? sizeof(word) : length;

            Copy(&word, buffer, chunk, U8);
            buffer += chunk;
            length -= chunk;
        }
    }
}

static void
rng_get_entropy_portable(pTHX_ U8 *buffer, STRLEN length, const char *failure)
{
    if (!length)
        return;

#  ifdef HAS_GETENTROPY
    /* getentropy() is limited to 256 octets per call.  This mirrors the
     * core wrapper before trying the portable OS fallbacks below. */
    while (length) {
        const STRLEN chunk = length > 256 ? 256 : length;

        if (getentropy(buffer, chunk) != 0)
            break;
        buffer += chunk;
        length -= chunk;
    }
    if (!length)
        return;
#  endif

#  ifndef PERL_NO_DEV_RANDOM
    {
        /* Older Perls do not provide a close-on-exec PerlLIO helper.  This
         * compatibility path keeps the descriptor lifetime short and closes
         * it promptly rather than requiring an unavailable API. */
        int fd = -1;

#    ifdef O_NONBLOCK
        fd = PerlLIO_open(PERL_RANDOM_DEVICE, O_RDONLY | O_NONBLOCK);
#    else
        /* Weak entropy must not deliberately block.  A caller which requires
         * strong entropy may use the configured device normally on this
         * unusual platform, accepting that the request can block. */
        if (failure)
            fd = PerlLIO_open(PERL_RANDOM_DEVICE, O_RDONLY);
#    endif

        if (fd != -1) {
            STRLEN offset = 0;

            while (offset < length) {
                const SSize_t got = PerlLIO_read(fd, buffer + offset,
                                                 length - offset);
                if (got <= 0)
                    break;
                offset += got;
            }
            PerlLIO_close(fd);
            if (offset == length)
                return;
        }
    }
#  endif

#  ifdef WIN32
    while (length) {
        const ULONG chunk = length > (STRLEN)ULONG_MAX ? ULONG_MAX : (ULONG)length;

        if (!SystemFunction036((PVOID)buffer, chunk))
            break;
        buffer += chunk;
        length -= chunk;
    }
    if (!length)
        return;
#  endif

    if (failure)
        croak("%s", failure);

    rng_fill_fallback_entropy(aTHX_ buffer, length);
}
#endif

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
#define HMAC_DRBG_STATE_SEED_LENGTH 64
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
    if (entropy_length)
        Copy(entropy, material, entropy_length, U8);
    if (nonce_length)
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

static SV *
hmac_drbg_state_seed(pTHX_ const hmac_drbg_data *state)
{
    SV *seed = newSVpvn((const char *)state->key, sizeof(state->key));

    sv_catpvn(seed, (const char *)state->value, sizeof(state->value));
    return seed;
}

static void
hmac_drbg_load_state_seed(hmac_drbg_data *state, const U8 *seed)
{
    Copy(seed, state->key, sizeof(state->key), U8);
    Copy(seed + sizeof(state->key), state->value, sizeof(state->value), U8);
    state->reseed_counter = 1;
    state->reseed_interval = HMAC_DRBG_RESEED_INTERVAL;
    state->pid = PerlProc_getpid();
    state->secure = FALSE;
    state->prediction_resistance = FALSE;
}

/* This constructor-level interface is deliberately octet-oriented: these
 * values are the separate HMAC_DRBG inputs from SP 800-90A, not ordinary
 * Perl seed strings. */
static const U8 *
hmac_drbg_input_octets(pTHX_ SV *input, STRLEN *length, const char *name)
{
    if (!input || !SvOK(input)) {
        *length = 0;
        return NULL;
    }
    if (SvUTF8(input))
        croak("RNG::HMAC_DRBG %s must be an octet string", name);
    return (const U8 *)SvPVbyte(input, *length);
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

    PERL_GET_STRONG_ENTROPY(entropy, sizeof(entropy),
                            "RNG::HMAC_DRBG could not obtain operating-system entropy");
    hmac_drbg_reseed_state(state, entropy, sizeof(entropy),
                           additional, additional_length);
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

static NV
hmac_drbg_U01_fast(pTHX_ void *raw_state)
{
    hmac_drbg_data *state = (hmac_drbg_data *)raw_state;
    U8 output[8];
    hmac_drbg_prepare(aTHX_ state);
    hmac_drbg_generate(state, output, sizeof(output), NULL, 0);
    return rng_U64_to_NV_U01(U8TO64_LE(output));
}

static U32
rng_legacy_automatic_seed(pTHX)
{
    U8 raw[4];
    U32 seed;

    PERL_GET_WEAK_ENTROPY(raw, sizeof(raw));
    seed = U8TO32_LE(raw);
    return seed;
}

MODULE = RNG         PACKAGE = RNG::Drand48

UV
get_rand_U01_XS_func_addr(self)
    SV *self
CODE:
    PERL_UNUSED_ARG(self);
    RETVAL = PTR2UV(drand48_U01_fast);
OUTPUT:
    RETVAL

UV
get_rand_U01_XS_state_addr(self)
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
    drand48_seed((rng_drand48_data *)SvPVX(state),
                 rng_drand48_seed(aTHX_ seed, FALSE));
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
rand_U01(self)
    SV *self
CODE:
    RETVAL = drand48_U01_fast(aTHX_ drand48_state(aTHX_ self));
OUTPUT:
    RETVAL

NV
rand(self, limit = NULL)
    SV *self
    SV *limit
PREINIT:
    NV value;
CODE:
    value = (items < 2 || !SvOK(limit)) ? 1.0 : SvNV(limit);
    if (value == 0.0)
        value = 1.0;
    RETVAL = value * drand48_U01_fast(aTHX_ drand48_state(aTHX_ self));
OUTPUT:
    RETVAL

SV *
_srand(self, seed = NULL)
    SV *self
    SV *seed
PREINIT:
    U64 value;
CODE:
    value = rng_drand48_seed(aTHX_ seed, FALSE);
    drand48_seed(drand48_state(aTHX_ self), value);
    RETVAL = rng_drand48_numeric_seed(value);
OUTPUT:
    RETVAL

MODULE = RNG         PACKAGE = RNG

SV *
_legacy_rand_bytes(length)
    UV length
PREINIT:
    SV *output;
    STRLEN offset;
CODE:
    if (!PL_srand_called) {
        seedDrand01(rng_legacy_automatic_seed(aTHX));
        PL_srand_called = TRUE;
    }
    output = newSV(length);
    SvPOK_on(output);
    SvCUR_set(output, length);
    for (offset = 0; offset < length; offset++)
        ((U8 *)SvPVX(output))[offset] = (U8)(Drand01() * 256.0);
    ((U8 *)SvPVX(output))[length] = '\0';
    RETVAL = output;
OUTPUT:
    RETVAL

SV *
_legacy_srand(seed = NULL)
    SV *seed
PREINIT:
    U32 value;
CODE:
    /* The built-in branch masks the initializer to 32 bits, so it is always
     * safe to store the returned seed in a UV.  seedDrand01() takes that
     * historical U32 seed, not the Drand48 state it creates. */
    value = (U32)rng_drand48_seed(aTHX_ seed, TRUE);
    seedDrand01(value);
    PL_srand_called = TRUE;
    RETVAL = newSVuv(value);
OUTPUT:
    RETVAL

MODULE = RNG         PACKAGE = RNG::PCG

UV
get_rand_U01_XS_func_addr(self)
    SV *self
CODE:
    PERL_UNUSED_ARG(self);
    RETVAL = PTR2UV(pcg_rng_U01_fast);
OUTPUT:
    RETVAL

UV
get_rand_U01_XS_state_addr(self)
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
rand_U01(self)
    SV *self
CODE:
    RETVAL = pcg_rng_U01_fast(aTHX_ pcg_state(aTHX_ self));
OUTPUT:
    RETVAL

NV
rand(self, limit = NULL)
    SV *self
    SV *limit
PREINIT:
    NV value;
CODE:
    value = (items < 2 || !SvOK(limit)) ? 1.0 : SvNV(limit);
    if (value == 0.0)
        value = 1.0;
    RETVAL = value * pcg_rng_U01_fast(aTHX_ pcg_state(aTHX_ self));
OUTPUT:
    RETVAL

SV *
_srand(self, seed = NULL)
    SV *self
    SV *seed
PREINIT:
    U8 automatic_seed[16];
CODE:
    if (items < 2 || !SvOK(seed)) {
        SV *raw;
        PERL_GET_WEAK_ENTROPY(automatic_seed, sizeof(automatic_seed));
        raw = newSVpvn((const char *)automatic_seed, sizeof(automatic_seed));
        pcg_load_raw_seed(pcg_state(aTHX_ self), automatic_seed);
        RETVAL = raw;
    }
    else {
        pcg_seed(aTHX_ pcg_state(aTHX_ self), seed);
        RETVAL = newSVsv(seed);
    }
OUTPUT:
    RETVAL

MODULE = RNG         PACKAGE = RNG::HMAC_DRBG

UV
get_rand_U01_XS_func_addr(self)
    SV *self
CODE:
    PERL_UNUSED_ARG(self);
    RETVAL = PTR2UV(hmac_drbg_U01_fast);
OUTPUT:
    RETVAL

UV
get_rand_U01_XS_state_addr(self)
    SV *self
CODE:
    RETVAL = PTR2UV(hmac_drbg_state_fast(self));
OUTPUT:
    RETVAL

int
is_secure(self)
    SV *self
CODE:
    RETVAL = hmac_drbg_state(aTHX_ self)->secure;
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
    const U8 *raw_seed_bytes = NULL;
    STRLEN raw_seed_length = 0;
    SV *raw_material;
CODE:
    state = newSVpvn(hmac_drbg_zero_state, sizeof(hmac_drbg_zero_state));
    RETVAL = newRV_noinc(state);
    sv_bless(RETVAL, gv_stashpv(class_name, GV_ADD));
    if (seed && SvOK(seed)
        && rng_raw_seed(aTHX_ seed, &raw_material, &raw_seed_bytes, &raw_seed_length)) {
        rng_require_raw_seed_length(raw_material, raw_seed_length,
                                    HMAC_DRBG_STATE_SEED_LENGTH,
                                    "RNG::HMAC_DRBG");
        hmac_drbg_load_state_seed(hmac_drbg_state(aTHX_ RETVAL), raw_seed_bytes);
        SvREFCNT_dec_NN(raw_material);
    }
    else {
        seed_bytes = seed && SvOK(seed)
            ? (const U8 *)SvPVutf8(seed, seed_length)
            : (const U8 *)"";
        hmac_sha256_hash(hmac_drbg_seed_label,
                         sizeof(hmac_drbg_seed_label) - 1,
                         seed_bytes, seed_length, entropy);
        hmac_sha256_hash(hmac_drbg_nonce_label,
                         sizeof(hmac_drbg_nonce_label) - 1,
                         seed_bytes, seed_length, nonce_digest);
        hmac_drbg_instantiate(hmac_drbg_state(aTHX_ RETVAL),
                              entropy, sizeof(entropy), nonce_digest, 16,
                              NULL, 0, FALSE);
    }
OUTPUT:
    RETVAL

SV *
_seed_from_entropy(class_name, entropy, nonce = NULL, personalization = NULL)
    const char *class_name
    SV *entropy
    SV *nonce
    SV *personalization
PREINIT:
    hmac_drbg_data state;
    STRLEN entropy_length;
    STRLEN nonce_length;
    STRLEN personalization_length;
    const U8 *entropy_bytes;
    const U8 *nonce_bytes;
    const U8 *personalization_bytes;
CODE:
    entropy_bytes = hmac_drbg_input_octets(aTHX_ entropy, &entropy_length,
                                            "entropy input");
    if (!entropy_bytes || !entropy_length)
        croak("RNG::HMAC_DRBG entropy input must not be empty");
    nonce_bytes = hmac_drbg_input_octets(aTHX_ nonce, &nonce_length,
                                          "nonce");
    personalization_bytes = hmac_drbg_input_octets(aTHX_ personalization,
                                                    &personalization_length,
                                                    "personalization string");
    PERL_UNUSED_ARG(class_name);
    hmac_drbg_instantiate(&state,
                          entropy_bytes, entropy_length,
                          nonce_bytes, nonce_length,
                          personalization_bytes, personalization_length,
                          FALSE);
    RETVAL = hmac_drbg_state_seed(aTHX_ &state);
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
    PERL_GET_STRONG_ENTROPY(entropy, sizeof(entropy),
                            "RNG::HMAC_DRBG could not obtain operating-system entropy");
    PERL_GET_STRONG_ENTROPY(nonce, sizeof(nonce),
                            "RNG::HMAC_DRBG could not obtain operating-system entropy");
    if (personalization && SvOK(personalization))
        personalization_bytes = (const U8 *)SvPVutf8(personalization,
                                                       personalization_length);
    state = newSVpvn(hmac_drbg_zero_state, sizeof(hmac_drbg_zero_state));
    RETVAL = newRV_noinc(state);
    sv_bless(RETVAL, gv_stashpv(class_name, GV_ADD));
    hmac_drbg_instantiate(hmac_drbg_state(aTHX_ RETVAL),
                          entropy, sizeof(entropy), nonce, sizeof(nonce),
                          personalization_bytes, personalization_length, TRUE);
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
rand_U01(self)
    SV *self
CODE:
    RETVAL = hmac_drbg_U01_fast(aTHX_ hmac_drbg_state(aTHX_ self));
OUTPUT:
    RETVAL

NV
rand(self, limit = NULL)
    SV *self
    SV *limit
PREINIT:
    NV value;
CODE:
    value = (items < 2 || !SvOK(limit)) ? 1.0 : SvNV(limit);
    if (value == 0.0)
        value = 1.0;
    RETVAL = value * hmac_drbg_U01_fast(aTHX_ hmac_drbg_state(aTHX_ self));
OUTPUT:
    RETVAL

SV *
_srand(self, seed = NULL)
    SV *self
    SV *seed
PREINIT:
    U8 automatic_seed[32];
    U8 digest[32];
    U8 nonce_digest[32];
    STRLEN seed_length = 0;
    const U8 *seed_bytes = NULL;
    const U8 *raw_bytes = NULL;
    STRLEN raw_length = 0;
    SV *raw_material = NULL;
    hmac_drbg_data *state;
    bool automatic = FALSE;
    bool raw_seed = FALSE;
CODE:
    if (seed && SvOK(seed)
        && (raw_seed = rng_raw_seed(aTHX_ seed, &raw_material, &raw_bytes, &raw_length))) {
        rng_require_raw_seed_length(raw_material, raw_length,
                                    HMAC_DRBG_STATE_SEED_LENGTH,
                                    "RNG::HMAC_DRBG");
        seed_bytes = raw_bytes;
        seed_length = raw_length;
    }
    else if (seed && SvOK(seed))
        seed_bytes = (const U8 *)SvPVutf8(seed, seed_length);
    state = hmac_drbg_state(aTHX_ self);
    if (state->secure && (items < 2 || !SvOK(seed))) {
        hmac_drbg_reseed_secure(aTHX_ state, NULL, 0);
    }
    else {
        if (!seed_bytes) {
            PERL_GET_WEAK_ENTROPY(automatic_seed, sizeof(automatic_seed));
            seed_bytes = automatic_seed;
            seed_length = sizeof(automatic_seed);
            automatic = TRUE;
        }
        if (raw_seed)
            hmac_drbg_load_state_seed(state, seed_bytes);
        else {
            hmac_sha256_hash(hmac_drbg_seed_label,
                             sizeof(hmac_drbg_seed_label) - 1,
                             seed_bytes, seed_length, digest);
            hmac_sha256_hash(hmac_drbg_nonce_label,
                             sizeof(hmac_drbg_nonce_label) - 1,
                             seed_bytes, seed_length, nonce_digest);
            hmac_drbg_instantiate(state, digest, sizeof(digest),
                                  nonce_digest, 16, NULL, 0, FALSE);
        }
    }
    if (raw_material)
        SvREFCNT_dec_NN(raw_material);
    RETVAL = automatic ? hmac_drbg_state_seed(aTHX_ state)
                        : newSVuv((items < 2 || !SvOK(seed)
                                   || (SvPOKp(seed) && !SvIOKp(seed)
                                                    && !SvNOKp(seed)))
                                  ? 0 : SvUV(seed));
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
get_rand_U01_XS_func_addr(self)
    SV *self
CODE:
    PERL_UNUSED_ARG(self);
    RETVAL = PTR2UV(wyrand_U01_fast);
OUTPUT:
    RETVAL

UV
get_rand_U01_XS_state_addr(self)
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
rand_U01(self)
    SV *self
CODE:
    RETVAL = wyrand_U01_fast(aTHX_ wyrand_state(aTHX_ self));
OUTPUT:
    RETVAL

NV
rand(self, limit = NULL)
    SV *self
    SV *limit
PREINIT:
    NV value;
CODE:
    value = (items < 2 || !SvOK(limit)) ? 1.0 : SvNV(limit);
    if (value == 0.0)
        value = 1.0;
    RETVAL = value * wyrand_U01_fast(aTHX_ wyrand_state(aTHX_ self));
OUTPUT:
    RETVAL

SV *
_srand(self, seed = NULL)
    SV *self
    SV *seed
PREINIT:
    U8 automatic_seed[8];
CODE:
    if (items < 2 || !SvOK(seed)) {
        SV *raw;
        PERL_GET_WEAK_ENTROPY(automatic_seed, sizeof(automatic_seed));
        raw = newSVpvn((const char *)automatic_seed, sizeof(automatic_seed));
        wyrand_load_raw_seed(wyrand_state(aTHX_ self), automatic_seed);
        RETVAL = raw;
    }
    else {
        wyrand_seed(aTHX_ wyrand_state(aTHX_ self), seed);
        RETVAL = newSVsv(seed);
    }
OUTPUT:
    RETVAL

MODULE = RNG         PACKAGE = RNG::Xoshiro

UV
get_rand_U01_XS_func_addr(self)
    SV *self
CODE:
    PERL_UNUSED_ARG(self);
    RETVAL = PTR2UV(xoshiro_U01_fast);
OUTPUT:
    RETVAL

UV
get_rand_U01_XS_state_addr(self)
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
rand_U01(self)
    SV *self
CODE:
    RETVAL = xoshiro_U01_fast(aTHX_ xoshiro_state(aTHX_ self));
OUTPUT:
    RETVAL

NV
rand(self, limit = NULL)
    SV *self
    SV *limit
PREINIT:
    NV value;
CODE:
    value = (items < 2 || !SvOK(limit)) ? 1.0 : SvNV(limit);
    if (value == 0.0)
        value = 1.0;
    RETVAL = value * xoshiro_U01_fast(aTHX_ xoshiro_state(aTHX_ self));
OUTPUT:
    RETVAL

SV *
_srand(self, seed = NULL)
    SV *self
    SV *seed
PREINIT:
    U8 automatic_seed[32];
CODE:
    if (items < 2 || !SvOK(seed)) {
        SV *raw;
        PERL_GET_WEAK_ENTROPY(automatic_seed, sizeof(automatic_seed));
        raw = newSVpvn((const char *)automatic_seed, sizeof(automatic_seed));
        xoshiro_load_raw_seed(xoshiro_state(aTHX_ self), automatic_seed);
        RETVAL = raw;
    }
    else {
        xoshiro_seed(aTHX_ xoshiro_state(aTHX_ self), seed);
        RETVAL = newSVsv(seed);
    }
OUTPUT:
    RETVAL
