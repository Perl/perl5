#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

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

static SV *
pcg_state(pTHX_ SV *self)
{
    SV *state;

    if (!SvROK(self) || !SvPOK(state = SvRV(self)))
        croak("RNG::PCG object does not contain a valid state");
    return state;
}

static pcg_data
pcg_load(pTHX_ SV *state)
{
    pcg_data value;
    STRLEN len;
    const char *bytes = SvPVbyte_force(state, len);

    if (len != sizeof(value))
        croak("RNG::PCG object does not contain a valid state");
    Copy(bytes, &value, sizeof(value), char);
    return value;
}

static void
pcg_store(SV *state, const pcg_data *value)
{
    STRLEN len;
    char *bytes = SvPV_force(state, len);

    if (len != sizeof(*value))
        croak("RNG::PCG object does not contain a valid state");
    Copy(value, bytes, sizeof(*value), char);
    SvUTF8_off(state);
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
pcg_seed(pTHX_ SV *state, SV *seed)
{
    pcg_data value;
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

    value.state = S_perl_hash_siphash_1_3_64(
        pcg_seed_key_13, seed_bytes, seed_len);
    value.initial = value.state;
    {
        const U64 extension = S_perl_hash_siphash_2_4_64(
            pcg_seed_key_24, seed_bytes, seed_len);
        value.extension[0] = (U32)extension;
        value.extension[1] = (U32)(extension >> 32);
    }
    pcg_store(state, &value);
}

MODULE = RNG         PACKAGE = RNG::PCG

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
    pcg_seed(aTHX_ state, seed);
OUTPUT:
    RETVAL

SV *
rand_bytes(self, length)
    SV *self
    UV length
PREINIT:
    pcg_data state;
    U8 *bytes;
    U64 word;
    UV offset;
    unsigned int i;
CODE:
    state = pcg_load(aTHX_ pcg_state(aTHX_ self));
    RETVAL = newSVpvn("", 0);
    SvGROW(RETVAL, length + 1);
    bytes = (U8 *)SvPVX(RETVAL);
    for (offset = 0; offset < length; ) {
        word = pcg_next_u64(&state);
        for (i = 0; i < 8 && offset < length; i++)
            bytes[offset++] = (U8)(word >> (56 - 8 * i));
    }
    bytes[length] = '\0';
    SvCUR_set(RETVAL, length);
    SvPOK_on(RETVAL);
    pcg_store(pcg_state(aTHX_ self), &state);
OUTPUT:
    RETVAL

NV
rand01(self)
    SV *self
PREINIT:
    pcg_data state;
    U64 random;
CODE:
    state = pcg_load(aTHX_ pcg_state(aTHX_ self));
    random = pcg_next_u64(&state);
    pcg_store(pcg_state(aTHX_ self), &state);
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
    pcg_data state;
CODE:
    value = (items < 2 || !SvOK(limit)) ? 1.0 : SvNV(limit);
    if (value == 0.0)
        value = 1.0;
    state = pcg_load(aTHX_ pcg_state(aTHX_ self));
    random = pcg_next_u64(&state);
    pcg_store(pcg_state(aTHX_ self), &state);
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
