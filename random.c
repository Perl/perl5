/*    random.c
 *
 *    Copyright (C) 1991-2026 by Larry Wall and others
 *
 *    You may distribute under the terms of either the GNU General Public
 *    License or the Artistic License, as specified in the README file.
 *
 *    Implementation for the random number generator.
 *
 */

#include "EXTERN.h"
#define PERL_IN_RANDOM_C
#include "perl.h"

/* For get_entropy() on non-Linux systems (MacOS, Android) we need sys/random.h */
#ifdef HAS_SYSRANDOM
#include <sys/random.h>
#endif

// https://prng.di.unimi.it/#remarks
static NV
uint64_to_NV(U64 num)
{
    /* NV can be have different significant bits depending on how perl
       is configured, so just let the appropriate ldexp do the work
    */
    NV ret   = Perl_ldexp((NV)num, -64);

    /*DEBUG_U(PerlIO_printf(Perl_error_log, "PRNG U2D: %lu => %0.15f\n", num, ret));*/

    return ret;
}

/* Splitmix64 is a simple PRNG and integer hashing function. It was
 * introduced in 2015: https://gee.cs.oswego.edu/dl/papers/oopsla14.pdf
 * Examples: https://rosettacode.org/wiki/Pseudo-random_numbers/Splitmix64
 */
static U64
splitmix64(U64 *state)
{
    U64 z = (*state += 0x9e3779b97f4a7c15);
    z     = (z ^ (z >> 30)) * 0xbf58476d1ce4e5b9;
    z     = (z ^ (z >> 27)) * 0x94d049bb133111eb;

    return z ^ (z >> 31);
}

//////////////////////////////////////////////////////////////
// PCG64 functions
//////////////////////////////////////////////////////////////

// Perl can only send one seed, so we have to deterministically
// create the other seeds needed for our PRNG
void
Perl_pcg64_seed_r(pcg64_random_t *state, U64 seed)
{
    PERL_ARGS_ASSERT_PCG64_SEED_R;
    U64 seed1 = splitmix64(&seed);
    U64 seed2 = splitmix64(&seed1);

    state->state = seed1;
    state->inc   = seed2;

    /*DEBUG_U(PerlIO_printf(Perl_error_log, "PCG64 INIT: %lu => %lu / %lu\n", seed, prng.state, prng.inc));*/
}

static U64
pcg64_rand64_r(pcg64_random_t *state)
{
    const uint64_t word = ((state->state >> ((state->state >> 59) + 5)) ^ state->state) * 12605985483714917081ull;
    state->state = state->state * 6364136223846793005ull + state->inc;
    return (word >> 43) ^ word;
}

NV
Perl_pcg64_random_double_r(pcg64_random_t *state)
{
    PERL_ARGS_ASSERT_PCG64_RANDOM_DOUBLE_R;

    U64 num    = pcg64_rand64_r(state);
    NV ret = uint64_to_NV(num);

    /*DEBUG_U(PerlIO_printf(Perl_error_log, "PCG Double: %0.15" NVff "\n", ret));*/

    return ret;
}

U64
Perl_seed(pTHX)
{
   /*
    * Attempt to read from /dev/urandom to generate a pseudo-random number.
    * If that does not work, or it is unavailable, we fall back to gathering
    * several state variables and hashing them into a seed value.
    */

/* This test is an escape hatch, this symbol isn't set by Configure. */
#ifndef PERL_NO_DEV_RANDOM
#ifndef PERL_RANDOM_DEVICE
   /* /dev/random isn't used by default because reads from it will block
    * if there isn't enough entropy available.  You can compile with
    * PERL_RANDOM_DEVICE to it if you'd prefer Perl to block until there
    * is enough real entropy to fill the seed. */
#  ifdef __amigaos4__
   /* https://wiki.amigaos.net/wiki/AmigaOS_Manual%3A_AmigaDOS_Additional_Amiga_Directories#Random-Handler_(RANDOM:) */
#    define PERL_RANDOM_DEVICE "RANDOM:"
#  else
#    define PERL_RANDOM_DEVICE "/dev/urandom"
#  endif
#endif
    U64 seed;

#ifdef HAS_GETENTROPY
    U8 ok = (getentropy(&seed, sizeof(seed)) == 0);
    /* PerlIO_printf(Perl_debug_log, "Entropy: OK:%i Seed:%lu\n", ok, seed); */
    if (ok) {
        return seed;
    }
#endif

    int fd = PerlLIO_open_cloexec(PERL_RANDOM_DEVICE, 0);
    if (fd != -1) {
        if (PerlLIO_read(fd, (void*)&seed, sizeof seed) != sizeof seed) {
            seed = 0;
        }

        PerlLIO_close(fd);

        if (seed) {
            return seed;
        }
    }
#endif

    /* We only get this far if /dev/urandom is not available or the read fails.
     * Grab several state variables and hash those for randomness instead. */

#ifdef HAS_GETTIMEOFDAY
    struct timeval when;

    PerlProc_gettimeofday(&when,NULL);
    /* Milliseconds */
    U64 epoch = ((U64)when.tv_sec * 1000000) + when.tv_usec;
#else
    Time_t when;

    (void)time(&when);
    /* Seconds */
    U64 epoch = when;
#endif

    UV pid      = PerlProc_getpid();
    UV time_ptr = PTR2UV(&when);

    /* epoch in microseconds is ~52 bits, PIDs are ~22 bits, PTRs are ~48 bits.
     * We mix the bits for all three together to get a good spread of entropy */
    U64 tmp = (time_ptr << 16) | (pid << 8) | (epoch);
    U64 ret = splitmix64(&tmp);

    /* PerlIO_printf(Perl_debug_log, "XXXX: TIME:%lu PID:%lu PTR:%lu\n", epoch, pid, time_ptr); */
    /* PerlIO_printf(Perl_debug_log, "SEED: %lu\n", ret); */

    return ret;
}

