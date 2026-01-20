////////////////////////////////////////////////////////////////////////////////
// Steps to add a new PRNG
//
// 1. Add a Perl_{name}_seed() and a Perl_{name}_random_double() function below
// 2. Add lines to embed.fnc with prototype information for these functions:
//      TXop    |double |{name}_random_double
//      TXop    |void   |{name}_seed|U64 seed1
// 3. Update Configure, win32/config.gc, win32/config.vc to use the newly
//    added PRNG:
//      randfunc=Perl_{name}_random_double
//      drand01="Perl_{name}_random_double()"
//      seedfunc="Perl_{name}_seed"
//      randseedtype=U64
// 4. Compile: /bin/bash ./Configure -DDEBUGGING -des && make -j8
////////////////////////////////////////////////////////////////////////////////

// Notes:
// https://zephyrtronium.github.io/articles/randomness.html
// https://docs.oracle.com/en/java/javase/21/core/choosing-prng-algorithm.html
// https://github.com/alvoskov/SmokeRand

#include <math.h>
#include <stdint.h>

// Splitmix64 is defined in util.c
U64 splitmix64(U64 *state);

typedef struct { uint64_t state;  uint64_t inc; } pcg64_random_t;
// Global PRNG object
pcg64_random_t prng;

// https://prng.di.unimi.it/#remarks
double
uint64_to_double(U64 num)
{
	// A standard 64bit double floating-point number in IEEE floating point
	// format has 52 bits of significand. Thus, the representation can actually
	// store numbers with 53 significant binary digits.
	double ret   = ldexp(num >> 11, -53);

	/*DEBUG_U(PerlIO_printf(Perl_error_log, "PRNG U2D: %lu => %0.15f\n", num, ret));*/

	return ret;
}

//////////////////////////////////////////////////////////////
// PCG64 functions
//////////////////////////////////////////////////////////////

// Perl can only send one seed, so we have to deterministically
// create the other seeds needed for our PRNG
void
Perl_pcg64_seed(U64 seed)
{
	U64 seed1 = splitmix64(&seed);
	U64 seed2 = splitmix64(&seed1);

	prng.state = seed1;
	prng.inc   = seed2;

	/*DEBUG_U(PerlIO_printf(Perl_error_log, "PCG64 INIT: %lu => %lu / %lu\n", seed, prng.state, prng.inc));*/
}

U64
pcg64_rand64()
{
    const uint64_t word = ((prng.state >> ((prng.state >> 59) + 5)) ^ prng.state) * 12605985483714917081ull;
    prng.state = prng.state * 6364136223846793005ull + prng.inc;
    return (word >> 43) ^ word;
}

double
Perl_pcg64_random_double()
{
	U64 num    = pcg64_rand64();
	double ret = uint64_to_double(num);

	/*DEBUG_U(PerlIO_printf(Perl_error_log, "PCG Double: %0.15f\n", ret));*/

	return ret;
}
